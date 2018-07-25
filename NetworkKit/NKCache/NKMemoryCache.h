//
//  NKMemoryCache.h
//  NetworkKit
//
//  Created by Jett on 26/04/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NKCacheProtocol.h"

@interface NKMemoryCache : NSObject <NKCacheProtocol>

- (instancetype)init;

@end
