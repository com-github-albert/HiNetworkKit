//
//  NKDiskCache.h
//  HiNetworkKit
//
//  Created by Jett on 26/04/2018.
//  Copyright © 2018 mutating. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NKCacheProtocol.h"

@interface NKDiskCache : NSObject <NKCacheProtocol>

- (instancetype)initWithPath:(NSString *)path;

@end
