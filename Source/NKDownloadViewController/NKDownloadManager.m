//
//  NKDownloadManager.m
//  NetworkKit
//
//  Created by Jett on 2018/10/24.
//  Copyright © 2018 mutating. All rights reserved.
//

#import "NKDownloadManager.h"
#import "NKFileManager.h"

@implementation NKDownloadManager

@synthesize unzipPath = _unzipPath;

+ (NKDownloadManager *)defaultManager {
    static NKDownloadManager *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSString *)downloadPath {
    return NKFileManager.defaultManager.downloadPath;
}

- (NSString *)unzipPath {
    return NKFileManager.defaultManager.rootPath;
}

- (BOOL)hasDownloaded {
    if ( ! [self _directoryIsExistsAtPath:NKFileManager.defaultManager.assetsPath]) {
        return NO;
    }
    return YES;
}

- (BOOL)_directoryIsExistsAtPath:(NSString *)path {
    BOOL isExist, isDirectory;
    isExist = [NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory];
    if ( ! isExist || ! isDirectory) {
        return NO;
    }
    return YES;
}

+ (BOOL)flushDownload {
    return
    [NKFileManager removeDirectoryAtPath:NKFileManager.defaultManager.downloadPath] &&
    [NKFileManager createDirectoryAtPath:NKFileManager.defaultManager.downloadPath];
}

+ (BOOL)flushAssets {
    return
    [NKFileManager removeDirectoryAtPath:NKFileManager.defaultManager.assetsPath];
}

@end
