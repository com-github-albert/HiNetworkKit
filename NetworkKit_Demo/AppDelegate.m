//
//  AppDelegate.m
//  NetworkKit_Demo
//
//  Created by Jett on 30/03/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}


- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    /*
     Store the completion handler. The completion handler is invoked by the view controller's checkForAllDownloadsHavingCompleted method (if all the download tasks have been completed).
     */
    self.backgroundSessionCompletionHandler = completionHandler;
}


@end
