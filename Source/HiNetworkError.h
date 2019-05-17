//
//  HiNetworkError.h
//  HiNetworkKit
//
//  Created by Jett Ma on 2019/2/25.
//  Copyright © 2019 mutating. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HiNetworkHTTPStatusCode.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSErrorDomain const HiNetworkErrorDomain;

@interface HiNetworkError : NSObject

+ (nullable NSError *)errorWithHTTPStatusCode:(NSInteger)statusCode;

@end

NS_ASSUME_NONNULL_END
