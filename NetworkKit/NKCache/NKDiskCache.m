//
//  NKDiskCache.m
//  NetworkKit
//
//  Created by Jett on 26/04/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
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
    NSMutableArray<NSString *> *_containsObjecKeys;
}

#pragma mark - public

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    _path = [path mutableCopy];
    _dataPath = [_path stringByAppendingPathComponent:kDataDirectoryName];
    if ([self _fileExistsWithPath:_path]) {
        if (![self _fileCreateWithPath:_path] ||
            ![self _fileCreateWithPath:_dataPath]) {
            [self _fileRemoveWithPath:_path];
            NSLog(@"NKDiskCache init failure");
            return nil;
        }
    }
    NSArray *keys = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_dataPath error:nil];
    _containsObjecKeys = [NSMutableArray arrayWithArray:keys];
    
    _lock = dispatch_semaphore_create(1);
    return self;
}

- (BOOL)containsObjectForKey:(NSString *)key {
    if (!key) return NO;
    Lock();
    BOOL contains = [_containsObjecKeys containsObject:key.md5];
    Unlock();
    return contains;
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key {
    if (!key) return;
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }
    NSString *file = [_dataPath stringByAppendingPathComponent:key.md5];
    Lock();
    if ([NSKeyedArchiver archiveRootObject:object toFile:file]) {
        [_containsObjecKeys addObject:key.md5];
    }
    Unlock();
}

- (id<NSCoding>)objectForKey:(NSString *)key {
    if (!key) return nil;
    if ([self containsObjectForKey:key]) {
        Lock();
        NSString *file = [_dataPath stringByAppendingPathComponent:key.md5];
        return [NSKeyedUnarchiver unarchiveObjectWithFile:file];
        Unlock();
    }
    return nil;
}

- (void)removeObjectForKey:(NSString *)key {
    if (!key) return;
    if ([self containsObjectForKey:key]) {
        Lock();
        NSString *file = [_dataPath stringByAppendingPathComponent:key.md5];
        if ([self _fileRemoveWithPath:file]) {
            [_containsObjecKeys removeObject:key.md5];
        }
        Unlock();
    }
}

- (void)removeAllObject {
    Lock();
    [self _fileRemoveWithPath:_dataPath];
    [self _fileCreateWithPath:_dataPath];
    Unlock();
}

#pragma mark - file

- (BOOL)_fileExistsWithPath:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (BOOL)_fileCreateWithPath:(NSString *)path {
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:path
                                   withIntermediateDirectories:NO
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
