//
//  NKDownloadTask.h
//  NetworkKit
//
//  Created by Jett on 02/04/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    NKDownloadItemStateNone,
    NKDownloadItemStateDownloading,
    NKDownloadItemStatePaused,
    NKDownloadItemStateFinished,
} NKDownloadItemState;

@interface NKDownloadItem : NSObject <NSCoding>

@property (atomic, strong, readonly) NSURL *url;
@property (atomic, strong) NSURL *location;
@property (atomic) NKDownloadItemState state;

@property (atomic, strong) NSURLSessionDataTask *dataTask;
@property (atomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (atomic, strong) NSData *resumeData;

@property (atomic, strong) NSString *contentType;
@property (atomic) unsigned long long requestOffset;
@property (atomic) unsigned long long downloadedLength;
@property (atomic) unsigned long long contentLength;
@property (atomic) unsigned long long expectedContentLength;
@property (atomic) float progress;
@property (atomic) float speed;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;

@end

@protocol NKDownloadTaskDelegate <NSObject>

@optional
- (void)download:(NKDownloadItem *)item didReceiveData:(NSData *)data;
- (void)download:(NKDownloadItem *)item didCompleteWithError:(NSError *)error;
- (void)downloadDidFinishedForBackground:(NKDownloadItem *)item;

@end

@interface NKDownloadTask : NSObject

@property (class, nonatomic, readonly) NKDownloadTask *backgroundTask;
@property (class, nonatomic, readonly) NKDownloadTask *defaultTask;

@property (nonatomic, strong) NSString *cacheDirectory;
@property (nonatomic, weak) id<NKDownloadTaskDelegate> delegate;
@property (nonatomic, strong, readonly) NKDownloadItem *currentItem;

- (void)resume:(NSURL *)url fromBreakPoint:(BOOL)allow;
- (void)pause;
- (void)reset;
- (void)invalidateAndCancel;

@end
