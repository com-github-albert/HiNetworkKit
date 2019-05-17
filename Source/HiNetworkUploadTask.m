//
//  HiNetworkUploadTask.m
//  HiNetworkKit
//
//  Created by Jett on 24/04/2018.
//  Copyright © 2018 mutating. All rights reserved.
//

#import "HiNetworkUploadTask.h"
#import "HiNetworkError.h"

@implementation HiNetworkUploadItem

- (void)setLocation:(NSURL *)location {
    _location = location;
    if ( ! _name) {
        _name = _location.lastPathComponent;
    }
}

@end

@implementation HiNetworkUploadTask

+ (NSURLSessionDataTask *)upload:(NSString *)url
                      parameters:(id)parameters
                         headers:(id)headers
                     updateItems:(NSArray<HiNetworkUploadItem *> *)updateItems
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
        for (HiNetworkUploadItem *item in updateItems) {
            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", item.name, item.location.lastPathComponent] dataUsingEncoding:NSUTF8StringEncoding]];
            if (item.contentType) {
                [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", item.contentType] dataUsingEncoding:NSUTF8StringEncoding]];
            }
            [body appendData:item.content];
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
    
    __block NSURLSessionDataTask *task = nil;
    task = [NSURLSession.sharedSession dataTaskWithRequest:mutableRequest
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
                                                             failure(task, e);
                                                         }
                                                     }
                                                 }
                                             }];
    return task;
}

@end
