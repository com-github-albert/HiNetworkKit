//
//  NKDownloadViewController.h
//  NetworkKit
//
//  Created by Jett on 2018/10/17.
//  Copyright © 2018 mutating. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NKDownloadViewController : UIViewController

@property (class, nonatomic, strong, readonly) NKDownloadViewController *viewController;

/**
 The URL will be used for download.
 */
@property (nonatomic, copy) NSURL *downloadURL;

/**
 Only do flush the assets by the session used. This operation is performed asynchronous.
 Does not flush the download cache file, you can call the asyncFlushDownloadCache: method do it.
 @param completion completion handler. The callback is in the main thread.
 */
+ (void)asyncFlushAssets:(void (^)(void))completion;

/**
 Only do flush the download cache file. This operation is performed asynchronous.
 Does not flush the asstes file, you can call the asyncFlushAssets: method do it.
 @param completion completion handler. The callback is in the main thread.
 */
+ (void)asyncFlushDownloadCache:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
