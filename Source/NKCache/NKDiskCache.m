//
//  NKDiskCache.m
//  HiNetworkKit
//
//  Created by Jett on 26/04/2018.
//  Copyright © 2018 mutating. All rights reserved.
//

#import "NKDiskCache.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

static NSString *const kDataDirectoryName = @"data";

@interface NSString (NKDiskCache)

- (NSString *)md5;

@end

@implementation NSString (NKDiskCache)

- (NSString *)md5 {
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

@end

@implementation NKDiskCache {
    dispatch_semaphore_t _lock;
    NSString *_path;
    NSString *_dataPath;
}

#pragma mark - public

- (instancetype)init {
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    _path = cacheDirectory;
    return [self initWithPath:_path];
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    _path = [path mutableCopy];
    _dataPath = [_path stringByAppendingPathComponent:kDataDirectoryName];
    if (![self _fileCreateWithPath:_dataPath]) {
        NSLog(@"NKDiskCache init failure");
        return nil;
    }
    
    _lock = dispatch_semaphore_create(1);
    return self;
}

- (BOOL)containsObjectForKey:(NSString *)key {
    if (!key) return NO;
    Lock();
    BOOL contains = [self _fileExistsWithPath:[self _pathForKey:key]];
    Unlock();
    return contains;
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key {
    if (!key) return;
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }
    Lock();
    [NSKeyedArchiver archiveRootObject:object toFile:[self _pathForKey:key]];
    Unlock();
}

- (id<NSCoding>)objectForKey:(NSString *)key {
    if (!key) return nil;
    Lock();
    id<NSCoding> object = [NSKeyedUnarchiver unarchiveObjectWithFile:[self _pathForKey:key]];
    Unlock();
    return object;
}

- (void)removeObjectForKey:(NSString *)key {
    if (!key) return;
    Lock();
    [self _fileRemoveWithPath:[self _pathForKey:key]];
    Unlock();
}

- (void)removeAllObject {
    Lock();
    [self _fileRemoveWithPath:_dataPath];
    [self _fileCreateWithPath:_dataPath];
    Unlock();
}

#pragma mark - file

- (NSString *)_pathForKey:(NSString *)key {
    return [_dataPath stringByAppendingPathComponent:key.md5];
}

- (BOOL)_fileExistsWithPath:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (BOOL)_fileCreateWithPath:(NSString *)path {
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:path
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error]) {
        NSLog(@"NKDiskCache create file error:%@", error);
        return NO;
    }
    return YES;
}

- (BOOL)_fileRemoveWithPath:(NSString *)path {
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:path
                                                    error:&error]) {
        NSLog(@"NKDiskCache remove file error:%@", error);
        return NO;
    }
    return YES;
}

@end
