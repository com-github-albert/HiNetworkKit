//
//  HiNetworkHTTPTask.h
//  HiNetworkKit
//
//  Created by Jett on 03/04/2018.
//  Copyright © 2018 mutating. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HiNetworkHTTPTask : NSObject

+ (NSURLSessionDataTask *)request:(NSString *)url
                       httpMethod:(NSString *)method
                       parameters:(id)parameters
                          headers:(id)headers
                          success:(void (^)(NSURLSessionDataTask * _Nullable task, NSData * _Nullable responseObject))success
                          failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nullable error))failure;

+ (NSURLSessionDownloadTask *)download:(NSString *)url
                            httpMethod:(NSString *)method
                            parameters:(id)parameters
                               headers:(id)headers
                               success:(void (^)(NSURLSessionDownloadTask * _Nullable task, NSURL * _Nullable location))success
                               failure:(void (^)(NSURLSessionDownloadTask * _Nullable task, NSError * _Nullable error))failure;

@end

NS_ASSUME_NONNULL_END
