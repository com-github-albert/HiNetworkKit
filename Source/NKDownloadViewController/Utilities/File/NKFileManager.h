//
//  NKFileManager.h
//  File
//
//  Created by Jett on 2018/10/30.
//  Copyright © 2018 mutating. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NKFileManager : NSObject

@property (class, nonatomic, strong, readonly) NKFileManager *defaultManager;

@property (nonatomic, assign) BOOL usingLocalAssets;

@property (nonatomic, strong, readonly) NSString *rootPath;
@property (nonatomic, strong, readonly) NSString *downloadPath;
@property (nonatomic, strong, readonly) NSString *assetsPath;

+ (BOOL)createDirectoryAtPath:(NSString *)path;
+ (BOOL)removeDirectoryAtPath:(NSString *)path;
+ (BOOL)copyFileAtPath:(NSString *)fromPath toPath:(NSString *)toPath;

+ (NSUInteger)getSubfileCountAtPath:(NSString *)path;
+ (NSArray *)getSubfilePathAtPath:(NSString *)path withExtension:(nullable NSString *)extension withCount:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
