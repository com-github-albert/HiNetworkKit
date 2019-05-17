//
//  NKUnZipHelper.m
//  Zip
//
//  Created by Jett on 30/10/2017.
//  Copyright © 2017 mutating. All rights reserved.
//

#import "NKUnZipHelper.h"

#if __has_include(<ZipArchive/ZipArchive.h>)
#import <ZipArchive/ZipArchive.h>
#else
#import "ZipArchive.h"
#endif

@implementation NKUnZipHelper

+ (BOOL)syncUnzipFromPath:(NSString *)fromPath
                   toPath:(NSString *)toPath {
    @synchronized (self) {
        NSString *from = [fromPath copy];
        NSString *to = [toPath copy];
        NSError* error;
        BOOL success = [SSZipArchive unzipFileAtPath:from
                                       toDestination:to
                                           overwrite:YES
                                            password:nil
                                               error:&error];
        if (success) {
            NSLog(@"unzip success");
            return YES;
        } else {
            NSLog(@"unzip failure: %@", error.description);
        }
        return NO;
    }
}

+ (void)asyncUnzipFromPath:(NSString *)fromPath
                    toPath:(NSString *)toPath
                completion:(void (^)(BOOL success, NSError *error))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *from = [fromPath copy];
        NSString *to = [toPath copy];
        NSError *error;
        BOOL success = [SSZipArchive unzipFileAtPath:from
                                       toDestination:to
                                           overwrite:YES
                                            password:nil
                                               error:&error];
        if (success) {
            completion(YES, error);
        } else {
            completion(NO, error);
        }
    });
}

@end
