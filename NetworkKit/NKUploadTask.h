//
//  NKUploadTask.h
//  NetworkKit
//
//  Created by Jett on 24/04/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NKUploadItem : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSURL *location;
@property (nonatomic, strong) NSString *contentType;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithLocatin:(NSURL *)location
                     updateData:(NSData *)data NS_DESIGNATED_INITIALIZER;

@end

@interface NKUploadTask : NSObject


+ (NSURLSessionDataTask *)upload:(NSString *)url
                      parameters:(id)parameters
                         headers:(id)headers
                     updateItems:(NSArray<NKUploadItem *> *)updateItems
                        boundary:(NSString *)boundary
                         success:(void (^)(NSURLSessionDataTask *task, NSData *responseObject))success
                         failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

@end
