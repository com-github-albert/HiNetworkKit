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

@interface NKDownloadItem : NSObject

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, strong) NSURL *location;
@property (nonatomic) NKDownloadItemState state;

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, strong) NSData *resumeData;

@property (nonatomic, strong) NSString *contentType;
@property (nonatomic) unsigned long long requestOffset;
@property (nonatomic) unsigned long long downloadedLength;
@property (nonatomic) unsigned long long contentLength;
@property (nonatomic) unsigned long long expectedContentLength;
@property (nonatomic) float progress;
@property (nonatomic) float speed;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;

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
