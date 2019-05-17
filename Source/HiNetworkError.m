//
//  HiNetworkError.m
//  HiNetworkKit
//
//  Created by Jett on 2019/2/25.
//  Copyright © 2019 mutating. All rights reserved.
//

#import "HiNetworkError.h"

NSErrorDomain const HiNetworkErrorDomain = @"HiNetworkErrorDomain";

@implementation HiNetworkError

+ (NSError *)errorWithHTTPStatusCode:(NSInteger)statusCode {
    if (![HiNetworkError isErrorOfHTTPStatusCode:statusCode]) {
        return nil;
    }
    NSString *description = [self errorDescriptionWithHTTPStatusCode:statusCode];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
                                                         forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:HiNetworkErrorDomain
                                         code:statusCode
                                     userInfo:userInfo];
    return error;
}

+ (BOOL)isErrorOfHTTPStatusCode:(NSInteger)statusCode {
    return statusCode >= HiNetworkHTTPStatusCodeBadRequest;
}

+ (NSString *)errorDescriptionWithHTTPStatusCode:(HiNetworkHTTPStatusCode)statusCode {
    NSString *description = @"Unkown Error";
    if (statusCode >= HiNetworkHTTPStatusCodeInternalServerError) {
        description = @"Server Error";
        description = [NSString stringWithFormat:@"%@ - Status Code is %d", description, (int)statusCode];
    } else if (statusCode >= HiNetworkHTTPStatusCodeBadRequest) {
        description = @"Client Error";
        description = [NSString stringWithFormat:@"%@ - Status Code is %d", description, (int)statusCode];
    }
    return description;
}

@end
