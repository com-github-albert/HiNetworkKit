//
//  HiNetworKSession.m
//  HiNetworKKit
//
//  Created by JT Ma on 2019/1/8.
//  Copyright © 2019 mutating. All rights reserved.
//

#import "HiNetworKSession.h"
#import "HiNetworkKit.h"

@implementation HiNetworKSession

static HiNetworKSession *_instance = nil;
static dispatch_once_t _onceToken;

+ (HiNetworKSession *)defaultSession {
    dispatch_once(&_onceToken, ^{
        _instance = [HiNetworKSession new];
    });
    return _instance;
}

+ (HiNetworKSession *)reachabilitySession {
    dispatch_once(&_onceToken, ^{
        _instance = [HiNetworKSession new];
        [_instance startReachability];
    });
    return _instance;
}

+ (HiNetworKSession *)commonSession {
    dispatch_once(&_onceToken, ^{
        _instance = [HiNetworKSession new];
        [_instance startReachability];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)invalidate {
    [self stopReachability];
    _instance = nil;
    _onceToken = 0;
    self.networkReachabilityStatusCallback = nil;
}

- (void)startReachability {
    [HiNetworkReachabilityManager.sharedManager startMonitoring];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didChangeReachability:) name:HiNetworkReachabilityDidChangeNotification object:nil];
}

- (void)stopReachability {
    [HiNetworkReachabilityManager.sharedManager stopMonitoring];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)didChangeReachability:(NSNotification *)notification {
    NSNumber *item = notification.userInfo[HiNetworkReachabilityNotificationStatusItem];
    if ( ! item) return;
    _networkReachabilityStatus = item.intValue;
    if (self.networkReachabilityStatusCallback) {
        self.networkReachabilityStatusCallback(_networkReachabilityStatus);
    }
}

@end
