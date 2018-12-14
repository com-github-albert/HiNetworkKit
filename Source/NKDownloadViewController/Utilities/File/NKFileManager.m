//
//  NKFileManager.m
//  File
//
//  Created by Jett on 2018/10/30.
//  Copyright © 2018 mutating. All rights reserved.
//

#import "NKFileManager.h"

/**
 * Sandbox
 *
 * /Labrary/Caches/NKAssets
 *                         /Assets
 *                         /Download
 */

static NSString * kNKRootName = @"NKAssets";

@implementation NKFileManager

@synthesize
rootPath = _rootPath,
downloadPath = _downloadPath,
assetsPath = _assetsPath;

+ (NKFileManager *)defaultManager {
    static NKFileManager *manager = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    _usingLocalAssets = NO;
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    _rootPath = [cacheDirectory stringByAppendingPathComponent:kNKRootName];
    if ( ! [self.class createDirectoryAtPath:_rootPath]) {
        return nil;
    }
    
    return self;
}

#pragma mark - Property

- (NSString *)downloadPath {
    if ( ! _downloadPath) {
        _downloadPath = [self.rootPath stringByAppendingPathComponent:@"Download"];
        [self.class createDirectoryAtPath:_downloadPath];
    }
    return _downloadPath;
}

- (NSString *)assetsPath {
    if (self.usingLocalAssets) {
        NSString *path = NSBundle.mainBundle.resourcePath;
        _assetsPath = [path stringByAppendingPathComponent:@"Assets"];
    } else {
        _assetsPath = [self.rootPath stringByAppendingPathComponent:@"Assets"];
    }
    return _assetsPath;
}

#pragma mark - Action

+ (BOOL)createDirectoryAtPath:(NSString *)path {
    NSFileManager *fm = NSFileManager.defaultManager;
    BOOL isDirectory;
    BOOL isExists = [fm fileExistsAtPath:path isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        NSError *err;
        if ( ! [fm createDirectoryAtPath:path
             withIntermediateDirectories:YES
                              attributes:nil
                                   error:&err]) {
            NSLog(@"fail to create file in path: \n%@\n with error:, \n%@", path, err.localizedDescription);
            return NO;
        }
    }
    return YES;
}

+ (BOOL)removeDirectoryAtPath:(NSString *)path {
    NSFileManager *fm = NSFileManager.defaultManager;
    BOOL isDirectory;
    BOOL isExists = [fm fileExistsAtPath:path isDirectory:&isDirectory];
    if (isExists && isDirectory) {
        NSError *err;
        if ( ! [fm removeItemAtPath:path error:&err]) {
            NSLog(@"fail to remove file in path: \n%@\n with error:, \n%@", path, err.localizedDescription);
            return NO;
        }
    }
    return YES;
}

+ (BOOL)copyFileAtPath:(NSString *)fromPath toPath:(NSString *)toPath {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSError *err;
    if ( ! [fm copyItemAtPath:fromPath toPath:toPath error:&err]) {
        NSLog(@"fail to copy file from path: %@ to path: \n%@\n with error:, \n%@", fromPath, toPath, err.localizedDescription);
        return NO;
    }
    return YES;
}

+ (NSUInteger)getSubfileCountAtPath:(NSString *)path {
    NSDirectoryEnumerator *enumerator = [NSFileManager.defaultManager enumeratorAtPath:path];
    NSUInteger count = enumerator.allObjects.count;
    return count;
}

+ (NSArray *)getSubfilePathAtPath:(NSString *)path withExtension:(NSString *)extension withCount:(NSUInteger)count {
    NSMutableArray *filePaths = [NSMutableArray new];
    NSDirectoryEnumerator *enumerator = [NSFileManager.defaultManager enumeratorAtPath:path];
    NSString *file;
    NSUInteger idx = 0;
    BOOL isEqual = NO;
    while (file = [enumerator nextObject]) {
        if (extension != nil && extension.length != 0) {
            if ([file.pathExtension isEqualToString:extension]) {
                isEqual = YES;
            }
        } else {
            isEqual = YES;
        }
        
        if (isEqual) {
            isEqual = NO;
            idx++;
            NSString *abslotionPath = [path stringByAppendingPathComponent:file];
            [filePaths addObject:abslotionPath];
            
            if (count > 0 && idx >= count) {
                break;
            }
        }
    }
    return filePaths;
}

@end
