//
//  NKUploadTask.m
//  NetworkKit
//
//  Created by Jett on 24/04/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "NKUploadTask.h"

@implementation NKUploadItem

- (instancetype)initWithLocatin:(NSURL *)location
                     updateData:(NSData *)data {
    self = [super init];
    if (self) {
        self.location = location;
        self.name = location.lastPathComponent;
        self.data = data;
    }
    return self;
}

@end

@implementation NKUploadTask

+ (NSURLSessionDataTask *)upload:(NSString *)url
                      parameters:(id)parameters
                         headers:(id)headers
                     updateItems:(NSArray<NKUploadItem *> *)updateItems
                        boundary:(NSString *)boundary
                         success:(void (^)(NSURLSessionDataTask *task, NSData *responseObject))success
                         failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    NSMutableString *urlString = [NSMutableString stringWithString:url];
    
    NSURL *requestURL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:requestURL];
    mutableRequest.HTTPMethod = @"POST";
    
    __block NSMutableData *body = [NSMutableData data];
    
    if (parameters) {
        [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"%@\r\n", value] dataUsingEncoding:NSUTF8StringEncoding]];
        }];
    }
    
    if (updateItems) {
        for (NKUploadItem *item in updateItems) {
            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", item.name, item.location.lastPathComponent] dataUsingEncoding:NSUTF8StringEncoding]];
            if (item.contentType) {
                [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", item.contentType] dataUsingEncoding:NSUTF8StringEncoding]];
            }
            [body appendData:item.data];
            [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [mutableRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    mutableRequest.HTTPBody = body;
    
    NSString *bodyLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
    [mutableRequest setValue:bodyLength forHTTPHeaderField:@"Content-Length"];
    
    if (headers) {
        [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            [mutableRequest setValue:value forHTTPHeaderField:key];
        }];
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [NSURLSession.sharedSession dataTaskWithRequest:mutableRequest
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

@end
