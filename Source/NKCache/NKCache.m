//
//  NKCache.m
//  NetworkKit
//
//  Created by Jett on 26/04/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "NKCache.h"
#import "NKMemoryCache.h"
#import "NKDiskCache.h"

@implementation NKCache

#pragma mark - public

- (instancetype)initWithPath:(NSString *)path {
    if (path.length == 0) return nil;

    self = [super init];
    _memoryCache = [[NKMemoryCache alloc] init];
    _diskCache = [[NKDiskCache alloc] initWithPath:path];
    return self;
}

- (BOOL)containsObjectForKey:(NSString *)key {
    return [_memoryCache containsObjectForKey:key] || [_diskCache containsObjectForKey:key];
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key {
    [_memoryCache setObject:object forKey:key];
    [_diskCache setObject:object forKey:key];
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key intoDisk:(BOOL)isSave {
    [_memoryCache setObject:object forKey:key];
    if (isSave) {
        [_diskCache setObject:object forKey:key];
    }
}

- (id<NSCoding>)objectForKey:(NSString *)key {
    id<NSCoding> object = [_memoryCache objectForKey:key];
    if (object == nil) {
        object = [_diskCache objectForKey:key];
        if (object) {
            [_memoryCache setObject:object forKey:key];
        }
    }
    return object;
}

- (void)removeObjectForKey:(NSString *)key {
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key];
}

- (void)removeAllObject {
    [_memoryCache removeAllObject];
    [_diskCache removeAllObject];
}

@end
