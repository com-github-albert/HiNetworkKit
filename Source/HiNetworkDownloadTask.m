//
//  HiNetworkDownloadTask.m
//  HiNetworkKit
//
//  Created by Jett on 02/04/2018.
//  Copyright © 2018 mutating. All rights reserved.
//

#import "HiNetworkDownloadTask.h"
#import <UIKit/UIKit.h>

#import <objc/runtime.h>

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#ifdef DEBUG
#define NSLog(...) NSLog(__VA_ARGS__)
#define NSLogMethod() NSLog(@"%s", __func__)
#else
#define NSLog(...)
#define NSLogMethod()
#endif

#pragma mark - Hook Background Handler

typedef void(*NK_VIMP)(id, SEL, UIApplication *application, NSString *identifier, void (^completionHandel)(void));

static void (^ NKBackgroundURLSessionHandler)(void) = nil;

static void nk_hookHandlerEventsForBackground() {
    Class class = UIApplication.sharedApplication.delegate.class;
    SEL selector = @selector(application:handleEventsForBackgroundURLSession:completionHandler:);
    Method methods = class_getInstanceMethod(class, selector);
    if (methods) {
        NK_VIMP vimp = (NK_VIMP)class_getMethodImplementation(class, selector);
        id impBlock = ^(id target, UIApplication *application, NSString *identifier, void (^completionHandel)(void)) {
            vimp(target, selector, application, identifier, completionHandel);
            NKBackgroundURLSessionHandler = completionHandel;
            NSLog(@"download task for background identifier %@", identifier);
        };
        IMP imp = imp_implementationWithBlock(impBlock);
        class_replaceMethod(class, selector, imp, method_getTypeEncoding(methods));
    } else {
        [NSException raise:NSInvalidArgumentException
                    format:@"-[%s %s] unrecognized selector send to instance.", class_getName(class), sel_getName(selector)];
    }
}

#pragma mark - Data Persistence

static NSString *kNKUserDefaultsDidDownloadContentLengthKey = @"kNKUserDefaultsDidDownloadContentLengthKey";

static NSString * const kNKUserDefaultsDidDownloadContentLengthKeyName = @"kNKUserDefaultsDidDownloadContentLengthKeyName";

static void nk_saveDidDownloadContentLength(unsigned long long contentLength) {
    if ( ! kNKUserDefaultsDidDownloadContentLengthKey) return;
    NSString *keyName = [NSUserDefaults.standardUserDefaults objectForKey:kNKUserDefaultsDidDownloadContentLengthKeyName];
    if ( ! [keyName isEqualToString:kNKUserDefaultsDidDownloadContentLengthKey]) {
        [NSUserDefaults.standardUserDefaults setObject:keyName
                                                forKey:kNKUserDefaultsDidDownloadContentLengthKeyName];
    }
    [NSUserDefaults.standardUserDefaults setObject:[NSNumber numberWithUnsignedLongLong:contentLength]
                                            forKey:kNKUserDefaultsDidDownloadContentLengthKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

static unsigned long long nk_fetchDidDownloadContentLength() {
    if ( ! kNKUserDefaultsDidDownloadContentLengthKey) return 0;
    NSString *keyName = [NSUserDefaults.standardUserDefaults objectForKey:kNKUserDefaultsDidDownloadContentLengthKeyName];
    if ( ! [keyName isEqualToString:kNKUserDefaultsDidDownloadContentLengthKey]) {
        [NSUserDefaults.standardUserDefaults setObject:kNKUserDefaultsDidDownloadContentLengthKey
                                                forKey:kNKUserDefaultsDidDownloadContentLengthKeyName];
        [NSUserDefaults.standardUserDefaults removeObjectForKey:kNKUserDefaultsDidDownloadContentLengthKey];
        [NSUserDefaults.standardUserDefaults synchronize];
        return 0;
    } else {
        NSNumber *contentLength = [NSUserDefaults.standardUserDefaults objectForKey:kNKUserDefaultsDidDownloadContentLengthKey];
        if (contentLength == NULL) {
            return 0;
        }
        return contentLength.unsignedLongLongValue;
    }
}

static void nk_flushDidDownloadContentLengthAndKeyName() {
    if ( ! kNKUserDefaultsDidDownloadContentLengthKey) return;
    [NSUserDefaults.standardUserDefaults removeObjectForKey:kNKUserDefaultsDidDownloadContentLengthKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:kNKUserDefaultsDidDownloadContentLengthKeyName];
    [NSUserDefaults.standardUserDefaults synchronize];
}

#pragma mark - MD5

@interface NSString (HiNetworkKit)

- (NSString *)nk_md5;

@end

@implementation NSString (HiNetworkKit)

- (NSString *)nk_md5 {
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

@end

#pragma mark - NetworkKit

typedef enum : NSInteger {
    NKResponseStatusCodeSuccess = 200,
    NKResponseStatusCodePartialContents = 206,
    NKResponseStatusCodeSatisfiable = 416
} NKResponseStatusCode;


@implementation HiNetworkDownloadItem

- (instancetype)initWithURL:(NSURL *)url  {
    self = [super init];
    if ( ! url) return nil;
    _url = url;
    _urlExtension = url.pathExtension;
    _urlMD5 = url.absoluteString.nk_md5;
    if (_urlExtension) {
        _name = [_urlMD5 stringByAppendingFormat:@".%@", _urlExtension];
    } else {
        _name = _urlMD5;
    }
    _state = HiNetworkDownloadItemStateNone;
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSURL *url = [coder decodeObjectForKey:@"NKURL"];
    if ( ! url) return nil;
    
    HiNetworkDownloadItem *item = [self initWithURL:url];
    item.location = [coder decodeObjectForKey:@"NKLocation"];
    item.state = [coder decodeIntegerForKey:@"NKState"];
    
    item.dataTask = [coder decodeObjectForKey:@"NKDataTask"];
    item.downloadTask = [coder decodeObjectForKey:@"HiNetworkDownloadTask"];
    item.resumeData = [coder decodeObjectForKey:@"NKResumeData"];
    
    item.contentType = [coder decodeObjectForKey:@"NKContentType"];
    item.requestOffset = [coder decodeIntegerForKey:@"NKRequestOffset"];
    item.downloadedLength = [coder decodeIntegerForKey:@"NKDownloadedLength"];
    item.contentLength = [coder decodeIntegerForKey:@"NKContentLength"];
    item.expectedContentLength = [coder decodeIntegerForKey:@"NKExpectedContentLength"];
    
    item.progress = [coder decodeFloatForKey:@"NKProgress"];
    item.speed = [coder decodeFloatForKey:@"NKSpeed"];
    
    return item;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    if ( ! self.url) return;
    
    [aCoder encodeObject:self.url forKey:@"NKURL"];
    [aCoder encodeObject:self.location forKey:@"NKLocation"];
    [aCoder encodeInteger:self.state forKey:@"NKState"];
    
    [aCoder encodeObject:self.dataTask forKey:@"NKDataTask"];
    [aCoder encodeObject:self.downloadTask forKey:@"HiNetworkDownloadTask"];
    [aCoder encodeObject:self.resumeData forKey:@"NKResumeData"];
    
    [aCoder encodeObject:self.contentType forKey:@"NKContentType"];
    [aCoder encodeInteger:(NSInteger)self.requestOffset forKey:@"NKRequestOffset"];
    [aCoder encodeInteger:(NSInteger)self.downloadedLength forKey:@"NKDownloadedLength"];
    [aCoder encodeInteger:(NSInteger)self.contentLength forKey:@"NKContentLength"];
    [aCoder encodeInteger:(NSInteger)self.expectedContentLength forKey:@"NKExpectedContentLength"];
    
    [aCoder encodeFloat:self.progress forKey:@"NKProgress"];
    [aCoder encodeFloat:self.speed forKey:@"NKSpeed"];
}

@end

@interface HiNetworkDownloadTask () <NSURLSessionDelegate, NSURLSessionDataDelegate>
@end

@implementation HiNetworkDownloadTask {
    NSFileHandle *_fileHandle;
    HiNetworkDownloadItem *_currentItem;
}

static HiNetworkDownloadTask *_instance = nil;
static dispatch_once_t _onceToken = 0;

+ (HiNetworkDownloadTask *)backgroundTask {
    dispatch_once(&_onceToken, ^{
        _instance = [[self alloc] init];
        nk_hookHandlerEventsForBackground();
    });
    return _instance;
}

+ (HiNetworkDownloadTask *)defaultTask {
    return [[self alloc] init];
}

- (void)dealloc {
    NSLogMethod();
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _resumeFromBreakPoint = YES;
    }
    return self;
}

#pragma mark - Public

- (void)resume:(NSURL *)url {
    if (url == nil) return;
    if (_currentItem == nil) {
        _currentItem = [[HiNetworkDownloadItem alloc] initWithURL:url];
        kNKUserDefaultsDidDownloadContentLengthKey = _currentItem.name;
        NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:_currentItem.name];
        _currentItem.location = [NSURL fileURLWithPath:cachePath isDirectory:NO];
        
        BOOL isExist = [NSFileManager.defaultManager fileExistsAtPath:cachePath];
        if (isExist) {
            unsigned long long downloadContentLength = nk_fetchDidDownloadContentLength();
            if (_resumeFromBreakPoint && downloadContentLength > 0) {
                _currentItem.contentLength = downloadContentLength;
                NSDictionary *fileInfo = [NSFileManager.defaultManager attributesOfItemAtPath:cachePath error:nil];
                if (fileInfo) {
                    _currentItem.downloadedLength = fileInfo.fileSize;
                }
            } else {
                [NSFileManager.defaultManager removeItemAtPath:cachePath error:nil];
                [NSFileManager.defaultManager createFileAtPath:cachePath contents:nil attributes:nil];
            }
        } else {
            [NSFileManager.defaultManager createFileAtPath:cachePath contents:nil attributes:nil];
        }

        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:cachePath];
    }
    
    switch (_currentItem.state) {
        case HiNetworkDownloadItemStateFinished: {
            _currentItem.progress = 1.f;
            if (self.delegate && [self.delegate respondsToSelector:@selector(download:didCompleteWithError:)]) {
                [self.delegate download:_currentItem didCompleteWithError:nil];
            }
        } break;
        case HiNetworkDownloadItemStateDownloading: {
        } break;
        default: {
            _currentItem.state = HiNetworkDownloadItemStateDownloading;
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            request.timeoutInterval = 30;
            NSString *range = [NSString stringWithFormat:@"bytes=%llu-", _currentItem.downloadedLength];
            if (_currentItem.contentLength > 0) {
                range = [range stringByAppendingFormat:@"%llu", _currentItem.contentLength];
            }
            [request setValue:range forHTTPHeaderField:@"Range"];
            
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
            _currentItem.dataTask = [session dataTaskWithRequest:request];
            [_currentItem.dataTask resume];
            [session finishTasksAndInvalidate];
        } break;
    }
}

- (void)cancel {
    if (_currentItem && _currentItem.state == HiNetworkDownloadItemStateDownloading) {
        _currentItem.state = HiNetworkDownloadItemStatePaused;
        [_currentItem.dataTask cancel];
    }
}

- (void)cancelAndClean {
    [_currentItem.dataTask cancel];
    _currentItem = nil;
}

- (void)invalidateAndCancel {
    [_currentItem.dataTask cancel];
    NKBackgroundURLSessionHandler = nil;
    _instance = nil;
    _onceToken = 0;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    /*
     NSURLSessionResponseCancel         = 0, default
     NSURLSessionResponseAllow          = 1,
     NSURLSessionResponseBecomeDownload = 2,
     NSURLSessionResponseBecomeStream   = 3,
     */
    completionHandler(NSURLSessionResponseAllow);
    
    if (_currentItem == nil) return;
    if (_currentItem.state == HiNetworkDownloadItemStateFinished) return;
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSDictionary *headers = httpResponse.allHeaderFields;
    long long length = [[headers valueForKey:@"Content-Length"] longLongValue];
    NSString *type = [headers valueForKey:@"Content-Type"];
    
    _currentItem.contentType = type;
    if (_currentItem.contentLength == 0) {
        _currentItem.expectedContentLength = length ?: httpResponse.expectedContentLength;
        _currentItem.contentLength = _currentItem.downloadedLength + _currentItem.expectedContentLength;
        if (_resumeFromBreakPoint) {
            nk_saveDidDownloadContentLength(_currentItem.contentLength);
        }
    } else {
        if (_currentItem.downloadedLength >= _currentItem.contentLength) {
            [self cancel];
            _currentItem.progress = 1.f;
            _currentItem.state = HiNetworkDownloadItemStateFinished;
            if (self.delegate && [self.delegate respondsToSelector:@selector(download:didCompleteWithError:)]) {
                [self.delegate download:_currentItem didCompleteWithError:nil];
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    if (_currentItem == nil) return;
    if (_currentItem.state == HiNetworkDownloadItemStateFinished) return;
    
    [_fileHandle seekToEndOfFile];
    [_fileHandle writeData:data];
    
    _currentItem.downloadedLength += data.length;
    _currentItem.progress = _currentItem.downloadedLength * 1.f / _currentItem.contentLength;
    if (self.delegate && [self.delegate respondsToSelector:@selector(download:didReceiveData:)]) {
        [self.delegate download:_currentItem didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (_currentItem == nil) return;
    if (_currentItem.state != HiNetworkDownloadItemStateDownloading) return;
    _currentItem.state = error ? HiNetworkDownloadItemStatePaused : HiNetworkDownloadItemStateFinished;
    
    if (_resumeFromBreakPoint) {
        nk_flushDidDownloadContentLengthAndKeyName();
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(download:didCompleteWithError:)]) {
        [self.delegate download:_currentItem didCompleteWithError:error];
    }
    [self invalidateAndCancel];
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        NSURLCredential *credntial = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credntial);
    }
}

- (void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(NSError *)error {
    if (_currentItem == nil) return;
    if (_currentItem.state != HiNetworkDownloadItemStateDownloading) return;
    _currentItem.state = HiNetworkDownloadItemStatePaused;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(download:didCompleteWithError:)]) {
        [self.delegate download:_currentItem didCompleteWithError:error];
    }
    NKBackgroundURLSessionHandler = nil;
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"download task finished for background session is in main thread %d", (int)NSThread.isMainThread);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"download task finished for background session");
        if (self->_currentItem.state == HiNetworkDownloadItemStateFinished) return;
        self->_currentItem.state = HiNetworkDownloadItemStateFinished;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(download:didCompleteWithError:)]) {
            [self.delegate downloadDidFinishedForBackground:self->_currentItem];
        }
        if (NKBackgroundURLSessionHandler) {
            void (^completionHandler)(void) = NKBackgroundURLSessionHandler;
            NKBackgroundURLSessionHandler = nil;
            [self invalidateAndCancel];
            completionHandler();
        }
    });
}

- (BOOL)isAvalidUrlLastPathComponent:(NSString *)lastPathComponent {
    return (lastPathComponent.length > 0) && (![lastPathComponent isEqualToString:@"/"]);
}

@end

/**
 kCFURLErrorBackgroundSessionInUseByAnotherProcess = -996,
 kCFURLErrorBackgroundSessionWasDisconnected = -997,
 kCFURLErrorUnknown = -998,
 kCFURLErrorCancelled = -999,
 kCFURLErrorBadURL = -1000,
 kCFURLErrorTimedOut = -1001,
 kCFURLErrorUnsupportedURL = -1002,
 kCFURLErrorCannotFindHost = -1003,
 kCFURLErrorCannotConnectToHost = -1004,
 kCFURLErrorNetworkConnectionLost = -1005,
 kCFURLErrorDNSLookupFailed = -1006,
 kCFURLErrorHTTPTooManyRedirects = -1007,
 kCFURLErrorResourceUnavailable = -1008,
 kCFURLErrorNotConnectedToInternet = -1009,
 kCFURLErrorRedirectToNonExistentLocation = -1010,
 kCFURLErrorBadServerResponse = -1011,
 kCFURLErrorUserCancelledAuthentication = -1012,
 kCFURLErrorUserAuthenticationRequired = -1013,
 kCFURLErrorZeroByteResource = -1014,
 kCFURLErrorCannotDecodeRawData = -1015,
 kCFURLErrorCannotDecodeContentData = -1016,
 kCFURLErrorCannotParseResponse = -1017,
 kCFURLErrorInternationalRoamingOff = -1018,
 kCFURLErrorCallIsActive = -1019,
 kCFURLErrorDataNotAllowed = -1020,
 kCFURLErrorRequestBodyStreamExhausted = -1021,
 kCFURLErrorAppTransportSecurityRequiresSecureConnection = -1022,
 kCFURLErrorFileDoesNotExist = -1100,
 kCFURLErrorFileIsDirectory = -1101,
 kCFURLErrorNoPermissionsToReadFile = -1102,
 kCFURLErrorDataLengthExceedsMaximum = -1103,
 kCFURLErrorFileOutsideSafeArea = -1104,
 */
