//
//  HiNetworKSession.h
//  HiNetworKKit
//
//  Created by JT Ma on 2019/1/8.
//  Copyright © 2019 mutating. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HiNetworkReachabilityManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface HiNetworKSession : NSObject

@property (class, nonatomic, readonly) HiNetworKSession *defaultSession;
@property (class, nonatomic, readonly) HiNetworKSession *reachabilitySession;
@property (class, nonatomic, readonly) HiNetworKSession *commonSession;

@property (readonly, nonatomic, assign) HiNetworkReachabilityStatus networkReachabilityStatus;

@property (nonatomic, copy, nullable) void (^networkReachabilityStatusCallback)(HiNetworkReachabilityStatus status);

- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
