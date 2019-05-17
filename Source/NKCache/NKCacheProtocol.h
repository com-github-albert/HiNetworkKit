//
//  NKCacheProtocol.h
//  HiNetworkKit
//
//  Created by Jett on 26/04/2018.
//  Copyright © 2018 mutating. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NKCacheProtocol <NSObject>

@required
- (BOOL)containsObjectForKey:(NSString *)key;
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key;
- (id<NSCoding>)objectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObject;

@optional
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key intoDisk:(BOOL)isSave;

@end
