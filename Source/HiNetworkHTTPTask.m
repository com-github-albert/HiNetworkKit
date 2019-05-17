//
//  HiNetworkHTTPTask.m
//  HiNetworkKit
//
//  Created by Jett on 03/04/2018.
//  Copyright © 2018 mutating. All rights reserved.
//

#import "HiNetworkHTTPTask.h"
#import "HiNetworkError.h"

static NSTimeInterval const hi_nk_http_urlRequestTimeoutInterval = 30;

@implementation HiNetworkHTTPTask

#pragma mark - Request

+ (NSURLSessionDataTask *)request:(NSString *)url
                       httpMethod:(NSString *)method
                       parameters:(id)parameters
                          headers:(id)headers
                          success:(void (^)(NSURLSessionDataTask *task, NSData *responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    NSURLRequest *request = [self _serializationRequest:url
                                            httpMethod:method
                                            parameters:parameters
                                               headers:headers];
    if (!request) return nil;
    
    __block NSURLSessionDataTask *task = nil;
    task = [NSURLSession.sharedSession dataTaskWithRequest:request
                                             completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                 if (error) {
                                                     if (failure) {
                                                         failure(task, error);
                                                     }
                                                 } else {
                                                     NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                     NSInteger statusCode = httpResponse.statusCode;
                                                     NSError *e = [HiNetworkError errorWithHTTPStatusCode:statusCode];
                                                     if (!e) {
                                                         if (success) {
                                                             success(task, data);
                                                         }
                                                     } else {
                                                         if (failure) {
                                                             failure(task, [HiNetworkError errorWithHTTPStatusCode:statusCode]);
                                                         }
                                                     }
                                                 }
                                             }];
    return task;
}

#pragma mark - Download

+ (NSURLSessionDownloadTask *)download:(NSString *)url
                            httpMethod:(NSString *)method
                            parameters:(id)parameters
                               headers:(id)headers
                               success:(void (^)(NSURLSessionDownloadTask *task, NSURL *location))success
                               failure:(void (^)(NSURLSessionDownloadTask *task, NSError *error))failure {
    NSURLRequest *request = [self _serializationRequest:url
                                            httpMethod:method
                                            parameters:parameters
                                               headers:headers];
    if (!request) return nil;
    
    __block NSURLSessionDownloadTask *task = nil;
    task = [NSURLSession.sharedSession downloadTaskWithRequest:request
                                             completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                 if (error) {
                                                     if (failure) {
                                                         failure(task, error);
                                                     }
                                                 } else {
                                                     NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                     NSInteger statusCode = httpResponse.statusCode;
                                                     NSError *e = [HiNetworkError errorWithHTTPStatusCode:statusCode];
                                                     if (!e) {
                                                         if (success) {
                                                             success(task, location);
                                                         }
                                                     } else {
                                                         if (failure) {
                                                             failure(task, e);
                                                         }
                                                     }
                                                 }
                                             }];
    return task;
}

#pragma mark - Private

+ (NSURLRequest *)_serializationRequest:(NSString *)url
                            httpMethod:(NSString *)method
                            parameters:(id)parameters
                               headers:(id)headers {
    NSMutableString *urlString = [NSMutableString stringWithString:url];
    
    if ([method isEqualToString:@"GET"]) {
        if (parameters) {
            [urlString appendString:@"?"];
            [urlString appendString:[self _buildParams:parameters]];
        }
    }
    
    NSURL *requestURL = [NSURL URLWithString:urlString];
    if (!requestURL) return nil;
    
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:requestURL];
    mutableRequest.HTTPMethod = method;
    mutableRequest.timeoutInterval = hi_nk_http_urlRequestTimeoutInterval;
    
    if ([method isEqualToString:@"POST"]) {
        if (parameters) {
            mutableRequest.HTTPBody = [[self _buildParams:parameters] dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    
    if (headers) {
        [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            [mutableRequest setValue:value forHTTPHeaderField:key];
        }];
    }
    
    return mutableRequest;
}

+ (NSString *)_buildParams:(NSDictionary *)params {
    __block NSMutableString *output = nil;
    [params enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        if (output) {
            [output appendString:@"&"];
        } else {
            output = [NSMutableString string];
        }
        NSString *p = [NSString stringWithFormat:@"%@=%@", key, value];
        [output appendString:p];
    }];
    return output;
}

@end
