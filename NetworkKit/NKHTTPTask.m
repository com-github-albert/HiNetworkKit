//
//  NKHTTPTask.m
//  NetworkKit
//
//  Created by Jett on 03/04/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "NKHTTPTask.h"

@implementation NKHTTPTask

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
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [NSURLSession.sharedSession dataTaskWithRequest:request
                                             completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                 if (error) {
                                                     if (failure) {
                                                         failure(dataTask, error);
                                                     }
                                                 } else {
                                                     if (success) {
                                                         success(dataTask, data);
                                                     }
                                                 }
                                             }];
    return dataTask;
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
    __block NSURLSessionDownloadTask *task = nil;
    task = [NSURLSession.sharedSession downloadTaskWithRequest:request
                                             completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                 if (error) {
                                                     if (failure) {
                                                         failure(task, error);
                                                     }
                                                 } else {
                                                     if (success) {
                                                         success(task, location);
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
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:requestURL];
    mutableRequest.HTTPMethod = method;
    
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
