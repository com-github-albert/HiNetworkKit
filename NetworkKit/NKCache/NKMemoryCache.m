//
//  NKMemoryCache.m
//  NetworkKit
//
//  Created by Jett on 26/04/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "NKMemoryCache.h"
#import <pthread.h>

#define Lock() pthread_mutex_lock(&_lock);
#define Unlock() pthread_mutex_unlock(&_lock);

@implementation NKMemoryCache {
    NSMutableDictionary *_memory;
    pthread_mutex_t _lock;
}

#pragma mark - public

- (instancetype)init {
    self = [super init];
    _memory = [NSMutableDictionary dictionary];
    pthread_mutex_init(&_lock, NULL);
    return self;
}

- (void)dealloc {
    [_memory removeAllObjects];
    pthread_mutex_destroy(&_lock);
}

- (BOOL)containsObjectForKey:(NSString *)key {
    if (!key) return NO;
    Lock();
    BOOL contains = [_memory.allKeys containsObject:key];
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
    [_memory setObject:object forKey:key];
    Unlock();
}

- (id<NSCoding>)objectForKey:(NSString *)key {
    if (!key) return nil;
    Lock();
    id object = [_memory objectForKey:key];
    Unlock();
    return object;
}

- (void)removeObjectForKey:(NSString *)key {
    if (!key) return;
    Lock();
    [_memory removeObjectForKey:key];
    Unlock();
}

- (void)removeAllObject {
    Lock();
    [_memory removeAllObjects];
    Unlock();
}

@end
