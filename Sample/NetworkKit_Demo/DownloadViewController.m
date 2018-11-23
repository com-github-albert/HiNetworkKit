//
//  DownloadViewController.m
//  NetworkKit_Demo
//
//  Created by Jett on 30/03/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "DownloadViewController.h"
#import "NKDownloadTask.h"
#import "AppDelegate.h"

@import AVKit;


#pragma mark - file

static NSString *_cacheDirectoryPath;

static void _createCacheDirectoryPath() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *libraryCachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *cacheDirectory = [libraryCachePath stringByAppendingPathComponent:@"DownloadTask"];
        _cacheDirectoryPath = cacheDirectory;
    });
}

static void _createDirectoryArPath(NSString *cachePath) {
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

static void _removeDirectoryAtPath(NSString *cachePath) {
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


@interface DownloadViewController () <NKDownloadTaskDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *downloadSegment;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *downloadCompleteButton;

@property (nonatomic, strong) NKDownloadTask *downloadTask;
@property (nonatomic, getter=isDownloadInBackground) BOOL downloadInBackground;

@end

@implementation DownloadViewController {
    NSURL *_downloadURL;
    NSURL *_locationURL;
    BOOL _downloadInBackground;
}

- (void)dealloc {
    NSLog(@"dealloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _createCacheDirectoryPath();
    _createDirectoryArPath(_cacheDirectoryPath);
    
    NSArray *downloadUrlStrings = @[
                                    @"https://images.apple.com/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4",
                                    @"https://res.hiar.io/group1/M00/6E/F1/CgBkg1plXpaABWz_AM8uhEhe7Wc281.mp4"
                                    ];
    _downloadURL = [NSURL URLWithString:downloadUrlStrings[1]];
    self.downloadCompleteButton.hidden = YES;
    
    self.downloadTask = NKDownloadTask.defaultTask;
    self.downloadTask.cacheDirectory = _cacheDirectoryPath;
    self.downloadTask.delegate = self;
    
    NSLog(@"is downloading %d", (int)(self.downloadTask.currentItem.state == NKDownloadItemStateDownloading));
    if (self.downloadTask.currentItem.state != NKDownloadItemStateDownloading) {
        [self downloader:self.downloadSegment];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (!self.downloadInBackground) {
        [self.downloadTask invalidateAndCancel];
    }
}

- (IBAction)downloader:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0: {
            self.downloadInBackground = NO;
            [self.downloadTask resume:_downloadURL fromBreakPoint:YES];
            break;
        }
        case 1: {
            self.downloadInBackground = NO;
            [self.downloadTask pause];
            break;
        }
        case 2: {
            self.downloadInBackground = YES;
            [self.downloadTask resume:_downloadURL fromBreakPoint:YES];
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
    }
}

- (IBAction)flushDownloadedFile:(id)sender {
    _locationURL = nil;
    self.downloadCompleteButton.hidden = YES;
    self.progressView.progress = 0;
    self.downloadSegment.selectedSegmentIndex = 1;
    [self.downloadTask reset];
    _removeDirectoryAtPath(_cacheDirectoryPath);
}

- (IBAction)downloadComplete:(UIButton *)sender {
    [self presentPlayerViewControllerFromURL:_locationURL];
}

#pragma mark - NKDownloadSessionDelegate

- (void)download:(NKDownloadItem *)item didReceiveData:(NSData *)data {
    NSLog(@"progress %f", item.progress);
    NSLog(@"downloaded length: %llu", item.downloadedLength);
    self.progressView.progress = item.progress;
}

- (void)download:(NKDownloadItem *)item didCompleteWithError:(NSError *)error {
    self.downloadInBackground = NO;
    self.downloadSegment.selectedSegmentIndex = 1;
    if (error) {
        NSLog(@"error: %@", error);
    } else {
        NSLog(@"finished: %@", item.location.path);
        self.progressView.progress = item.progress;
        _locationURL = item.location;
        self.downloadCompleteButton.hidden = NO;
    }
}

- (void)downloadDidFinishedForBackground:(NKDownloadItem *)item {
    NSLog(@"finished for background: %@", item.location.path);
    self.downloadInBackground = NO;
}

#pragma mark - Private

- (void)presentPlayerViewControllerFromURL:(NSURL *)url {
    if (url) {
        AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
        AVPlayer *player = [AVPlayer playerWithURL:url];
        playerViewController.player = player;
        [playerViewController.player play];
        [self presentViewController:playerViewController animated:YES completion:nil];
    }
}

@end
