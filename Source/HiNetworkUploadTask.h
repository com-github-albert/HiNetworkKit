//
//  HiNetworkUploadTask.h
//  HiNetworkKit
//
//  Created by Jett on 24/04/2018.
//  Copyright © 2018 mutating. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HiNetworkUploadItem : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSURL *location;
@property (nonatomic, strong) NSData *content;
@property (nonatomic, strong) NSString *contentType;

@end

@interface HiNetworkUploadTask : NSObject


+ (NSURLSessionDataTask *)upload:(NSString *)url
                      parameters:(id)parameters
                         headers:(id)headers
                     updateItems:(NSArray<HiNetworkUploadItem *> *)updateItems
                        boundary:(NSString *)boundary
                         success:(void (^)(NSURLSessionDataTask * _Nullable task, NSData * _Nullable responseObject))success
                         failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nullable error))failure;

@end

NS_ASSUME_NONNULL_END
