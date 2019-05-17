//
//  HiNetworkDownloadTask.h
//  HiNetworkKit
//
//  Created by Jett on 02/04/2018.
//  Copyright © 2018 mutating. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    HiNetworkDownloadItemStateNone,
    HiNetworkDownloadItemStateDownloading,
    HiNetworkDownloadItemStatePaused,
    HiNetworkDownloadItemStateFinished,
} HiNetworkDownloadItemState;

NS_ASSUME_NONNULL_BEGIN

@interface HiNetworkDownloadItem : NSObject <NSCoding>

@property (atomic, strong, readonly) NSURL *url;
@property (atomic, strong, readonly) NSString *urlMD5;
@property (atomic, strong, readonly) NSString *urlExtension;
@property (atomic, strong, readonly) NSString *name;
@property (atomic, strong) NSURL *location;
@property (atomic) HiNetworkDownloadItemState state;

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

@protocol HiNetworkDownloadTaskDelegate <NSObject>

@optional
- (void)download:(HiNetworkDownloadItem *)item didReceiveData:(NSData *)data;
- (void)download:(HiNetworkDownloadItem *)item didCompleteWithError:(nullable NSError *)error;
- (void)downloadDidFinishedForBackground:(HiNetworkDownloadItem *)item;

@end

@interface HiNetworkDownloadTask : NSObject

@property (class, nonatomic, readonly) HiNetworkDownloadTask *backgroundTask;
@property (class, nonatomic, readonly) HiNetworkDownloadTask *defaultTask;

@property (nonatomic, weak) id<HiNetworkDownloadTaskDelegate> delegate;
@property (nonatomic, strong, readonly) HiNetworkDownloadItem *currentItem;
@property (nonatomic, strong) NSString *cacheDirectory;
@property (nonatomic, assign) BOOL resumeFromBreakPoint; /// Default value is YES.

- (void)resume:(NSURL *)url;
- (void)cancel;
- (void)cancelAndClean;
- (void)invalidateAndCancel;

@end

NS_ASSUME_NONNULL_END
