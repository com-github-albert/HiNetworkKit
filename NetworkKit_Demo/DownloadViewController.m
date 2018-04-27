//
//  DownloadViewController.m
//  NetworkKit_Demo
//
//  Created by Jett on 30/03/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "DownloadViewController.h"
#import "NKDownloadTask.h"

@interface DownloadViewController () <NKDownloadTaskDelegate>

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (nonatomic, strong) NKDownloadTask *downloadTask;
@property (nonatomic, strong) NSURL *downloadURL;
@property (nonatomic, strong) NSString *cacheDirectory;
@property (nonatomic, getter=isDownloadInBackground) BOOL downloadInBackground;

@end

@implementation DownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *downloadUrlStrings = @[
                                    @"https://images.apple.com/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4",
                                    @"https://res.hiar.io/group1/M00/6E/F1/CgBkg1plXpaABWz_AM8uhEhe7Wc281.mp4"
                                    ];
    self.downloadURL = [NSURL URLWithString:downloadUrlStrings[1]];
    
    [self createCache:self.cacheDirectory];
    self.downloadTask = NKDownloadTask.backgroundTask;
    self.downloadTask.cacheDirectory = self.cacheDirectory;
    self.downloadTask.delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (!self.isDownloadInBackground) {
        [self.downloadTask invalidate];
    }
}

- (IBAction)downloader:(UISegmentedControl *)sender {
    self.downloadInBackground = NO;
    switch (sender.selectedSegmentIndex) {
        case 0: {
            [self.downloadTask resume:self.downloadURL fromBreakPoint:YES];
            break;
        }
        case 1: {
            [self.downloadTask cancel];
            break;
        }
        case 2: {
            self.downloadInBackground = YES;
            [self.downloadTask resume:self.downloadURL fromBreakPoint:YES];
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
    }
}

- (IBAction)clear:(id)sender {
    [self flushCache:self.cacheDirectory];
}

#pragma mark - NKDownloadSessionDelegate

- (void)download:(NKDownloadItem *)item didReceiveData:(NSData *)data {
    NSLog(@"progress %f", item.progress);
    NSLog(@"downloaded length: %llu", item.downloadedLength);
    self.progressView.progress = item.progress;
}

- (void)download:(NKDownloadItem *)item didCompleteWithError:(NSError *)error {
    self.downloadInBackground = NO;
    if (error) {
        NSLog(@"error: %@", error);
    } else {
        NSLog(@"finished: %@", item.location.path);
        self.progressView.progress = item.progress;
    }
}

- (void)downloadDidFinishedForBackground:(NKDownloadItem *)item {
    self.downloadInBackground = NO;
    NSLog(@"finished for background: %@", item.location.path);
}

#pragma mark - FileManager

- (NSString *)cacheDirectory {
    if (!_cacheDirectory) {
        NSString *libraryCachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        _cacheDirectory = [libraryCachePath stringByAppendingPathComponent:@"DownloadSession"];
    }
    return _cacheDirectory;
}

- (void)flushCache:(NSString *)cachePath {
    NSFileManager *fm = NSFileManager.defaultManager;
    BOOL isDirectory;
    BOOL isExists = [fm fileExistsAtPath:cachePath isDirectory:&isDirectory];
    if (isExists && isDirectory) {
        [fm removeItemAtPath:cachePath error:nil];
    }
    [fm createDirectoryAtPath:cachePath
  withIntermediateDirectories:YES
                   attributes:nil
                        error:nil];
}

- (void)createCache:(NSString *)cachePath {
    NSFileManager *fm = NSFileManager.defaultManager;
    BOOL isDirectory;
    BOOL isExists = [fm fileExistsAtPath:cachePath isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [fm createDirectoryAtPath:cachePath
      withIntermediateDirectories:YES
                       attributes:nil
                            error:nil];
    }
}

@end
