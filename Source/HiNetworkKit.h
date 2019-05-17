//
//  HiNetworkKit.h
//  HiNetworkKit
//
//  Created by JT Ma on 2019/3/26.
//  Copyright © 2019 mutating. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for HiNetworkKit.
FOUNDATION_EXPORT double HiNetworkKitVersionNumber;

//! Project version string for HiNetworkKit.
FOUNDATION_EXPORT const unsigned char HiNetworkKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <HiNetworkKit/PublicHeader.h>


#if __has_include(<HiNetworkKit/HiNetworkKit.h>)

#import <Foundation/Foundation.h>

//! Project version number for HiNetworkKit.
FOUNDATION_EXPORT double HiNetworkKitVersionNumber;

//! Project version string for HiNetworkKit.
FOUNDATION_EXPORT const unsigned char HiNetworkKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <HiNetworkKit/PublicHeader.h>
#import <HiNetworkKit/HiNetworkHTTPTask.h>
#import <HiNetworkKit/HiNetworkDownloadTask.h>
#import <HiNetworkKit/HiNetworkUploadTask.h>
#import <HiNetworkKit/HiNetworkReachabilityManager.h>
#import <HiNetworkKit/NKCache.h>
#else
#import "HiNetworkHTTPTask.h"
#import "HiNetworkDownloadTask.h"
#import "HiNetworkUploadTask.h"
#import "HiNetworkReachabilityManager.h"
#import "NKCache.h"
#endif
