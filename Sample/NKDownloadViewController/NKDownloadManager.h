//
//  NKDownloadManager.h
//  NetworkKit
//
//  Created by Jett on 2018/10/24.
//  Copyright © 2018 mutating. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NKDownloadManager : NSObject

@property (class, nonatomic, strong, readonly) NKDownloadManager *defaultManager;

@property (nonatomic, strong, readonly) NSString *downloadPath;
@property (nonatomic, strong, readonly) NSString *unzipPath;

@property (nonatomic, readonly) BOOL hasDownloaded;

+ (BOOL)flushDownload;
+ (BOOL)flushAssets;

@end

NS_ASSUME_NONNULL_END
