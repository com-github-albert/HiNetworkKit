//
//  NKHTTPTask.h
//  NetworkKit
//
//  Created by Jett on 03/04/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NKHTTPTask : NSObject

+ (NSURLSessionDataTask *)request:(NSString *)url
                       httpMethod:(NSString *)method
                       parameters:(id)parameters
                          headers:(id)headers
                          success:(void (^)(NSURLSessionDataTask *task, NSData *responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

+ (NSURLSessionDownloadTask *)download:(NSString *)url
                            httpMethod:(NSString *)method
                            parameters:(id)parameters
                               headers:(id)headers
                               success:(void (^)(NSURLSessionDownloadTask *task, NSURL *location))success
                               failure:(void (^)(NSURLSessionDownloadTask *task, NSError *error))failure;


@end

NS_ASSUME_NONNULL_END
