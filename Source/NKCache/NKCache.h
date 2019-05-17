//
//  NKCache.h
//  HiNetworkKit
//
//  Created by Jett on 26/04/2018.
//  Copyright © 2018 mutating. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NKCacheProtocol.h"

@interface NKCache : NSObject <NKCacheProtocol>

@property (strong, readonly) id<NKCacheProtocol> memoryCache;
@property (strong, readonly) id<NKCacheProtocol> diskCache;

- (instancetype)initWithPath:(NSString *)path;

@end
