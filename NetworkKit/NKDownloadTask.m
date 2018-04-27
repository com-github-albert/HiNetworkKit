//
//  NKDownloadTask.m
//  NetworkKit
//
//  Created by Jett on 02/04/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "NKDownloadTask.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define BLog(formatString, ...) NSLog((@"%s " formatString), __PRETTY_FUNCTION__, ##__VA_ARGS__);

typedef void(*NK_VIMP)(id, SEL, UIApplication *application, NSString *identifier, void (^completionHandel)(void));

static void (^ NKBackgroundURLSessionHandler)(void) = nil;

static void _NKHookEventsForBackground() {
    Class class = [[UIApplication sharedApplication].delegate class];
    SEL selector = @selector(application:handleEventsForBackgroundURLSession:completionHandler:);
    Method methods = class_getInstanceMethod(class, selector);
    if (methods) {
        NK_VIMP vimp = (NK_VIMP)class_getMethodImplementation(class, selector);
        id impBlock = ^(id target, UIApplication *application, NSString *identifier, void (^completionHandel)(void)) {
            vimp(target, selector, application, identifier, completionHandel);
            NKBackgroundURLSessionHandler = completionHandel;
        };
        IMP imp = imp_implementationWithBlock(impBlock);
        class_replaceMethod(class, selector, imp, method_getTypeEncoding(methods));
    } else {
        [NSException raise:NSInvalidArgumentException
                    format:@"-[%s %s] unrecognized selector send to instance.", class_getName(class), sel_getName(selector)];
    }
}

typedef enum : NSInteger {
    NKResponseStatusCodeSuccess = 200,
    NKResponseStatusCodePartialContents = 206,
    NKResponseStatusCodeSatisfiable = 416
} NKResponseStatusCode;

@implementation NKDownloadItem

- (instancetype)initWithURL:(NSURL *)url  {
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

@end

@interface NKDownloadTask () <NSURLSessionDelegate, NSURLSessionDataDelegate>
@end

@implementation NKDownloadTask {
    NSFileHandle *_fileHandle;
    NKDownloadItem *_item;
}

static NKDownloadTask *_instance = nil;
static dispatch_once_t _onceToken = 0;

+ (NKDownloadTask *)backgroundTask {
    dispatch_once(&_onceToken, ^{
        _instance = [[self alloc] init];
        _NKHookEventsForBackground();
    });
    return _instance;
}

+ (NKDownloadTask *)defaultTask {
    return [[self alloc] init];
}

- (void)dealloc {
    [_item.dataTask cancel];
    _item = nil;
}

- (void)invalidate {
    NKBackgroundURLSessionHandler = nil;
    _instance = nil;
    _onceToken = 0;
}

- (void)resume:(NSURL *)url fromBreakPoint:(BOOL)allow {
    if (_item == nil) {
        _item = [[NKDownloadItem alloc] initWithURL:url];
        NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:url.lastPathComponent];
        _item.location = [NSURL fileURLWithPath:cachePath isDirectory:NO];
        BOOL isExist = [NSFileManager.defaultManager fileExistsAtPath:cachePath];
        if (isExist) {
            NSDictionary *fileInfo = [NSFileManager.defaultManager attributesOfItemAtPath:cachePath error:nil];
            if (allow && fileInfo) {
                _item.downloadedLength = fileInfo.fileSize;
            } else {
                [NSFileManager.defaultManager removeItemAtPath:cachePath error:nil];
                [NSFileManager.defaultManager createFileAtPath:cachePath contents:nil attributes:nil];
            }
        } else {
            [NSFileManager.defaultManager createFileAtPath:cachePath contents:nil attributes:nil];
        }
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:cachePath];
    }
    
    if (_item.isDownloading == NO) {
        _item.downloading = YES;
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        NSString *range = [NSString stringWithFormat:@"bytes=%llu-", _item.downloadedLength];
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        _item.dataTask = [session dataTaskWithRequest:request];
        [_item.dataTask resume];
        [session finishTasksAndInvalidate];
    }
}

- (void)cancel {
    if (_item && _item.isDownloading) {
        _item.downloading = NO;
        [_item.dataTask cancel];
    }
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
    
    if (_item == nil) return;
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSInteger status = httpResponse.statusCode;
    NSDictionary *headers = httpResponse.allHeaderFields;
    long long length = [[headers valueForKey:@"Content-Length"] longLongValue];
    NSString *type = [headers valueForKey:@"Content-Type"];

    switch (status) {
        case NKResponseStatusCodePartialContents: {
            _item.expectedContentLength = length ?: httpResponse.expectedContentLength;
            if (_item.contentLength == 0) {
                _item.contentLength = _item.downloadedLength + _item.expectedContentLength;
            }
            _item.contentType = type;
        }
            break;
        default: {
            if (_item.downloadedLength >= length) {
                [self cancel];
                _item.progress = 1.f;
                if (self.delegate && [self.delegate respondsToSelector:@selector(download:didCompleteWithError:)]) {
                    [self.delegate download:_item didCompleteWithError:nil];
                }
                _item = nil;
            }
        }
            break;
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    if (_item == nil) return;
    
    [_fileHandle seekToEndOfFile];
    [_fileHandle writeData:data];
    
    _item.downloadedLength += data.length;
    _item.progress = _item.downloadedLength * 1.f / _item.contentLength;
    if (self.delegate && [self.delegate respondsToSelector:@selector(download:didReceiveData:)]) {
        [self.delegate download:_item didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (_item == nil) return;
    if (self.delegate && [self.delegate respondsToSelector:@selector(download:didCompleteWithError:)]) {
        [self.delegate download:_item didCompleteWithError:error];
    }
    _item = nil;
    [self invalidate];
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
    if (_item == nil) return;
    if (self.delegate && [self.delegate respondsToSelector:@selector(download:didCompleteWithError:)]) {
        [self.delegate download:_item didCompleteWithError:error];
    }
    _item = nil;
    [self invalidate];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(download:didCompleteWithError:)]) {
            [self.delegate downloadDidFinishedForBackground:self->_item];
        }
        self->_item = nil;
        if (NKBackgroundURLSessionHandler) {
            void (^completionHandler)(void) = NKBackgroundURLSessionHandler;
            [self invalidate];
            completionHandler();
        }
    });
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
