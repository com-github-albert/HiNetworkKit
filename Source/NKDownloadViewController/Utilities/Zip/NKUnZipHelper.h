//
//  NKUnZipHelper.h
//  Zip
//
//  Created by Jett on 30/10/2017.
//  Copyright © 2017 mutating. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NKUnZipHelper : NSObject

+ (BOOL)syncUnzipFromPath:(NSString *)fromPath
                   toPath:(NSString *)toPath;

+ (void)asyncUnzipFromPath:(NSString *)fromPath
                    toPath:(NSString *)toPath
                completion:(void (^)(BOOL success, NSError *error))completion;

@end
