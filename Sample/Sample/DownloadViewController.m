//
//  ViewController.m
//  Sample
//
//  Created by Jett on 2018/12/14.
//  Copyright © 2018 mutating. All rights reserved.
//

#import "DownloadViewController.h"
#import "NKDownloadViewController.h"

@interface DownloadViewController () {
    NSURL *_downloadURL;
}

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *events;

@end

@implementation DownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *downloadUrlStrings = @[
                                    @"https://images.apple.com/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4"
                                    ];
    _downloadURL = [NSURL URLWithString:downloadUrlStrings.firstObject];
}

- (IBAction)presentAR:(UIButton *)sender {
    [self _enableEvent:NO];
    NKDownloadViewController * vc = NKDownloadViewController.viewController;
    vc.downloadURL = _downloadURL;
    [self presentViewController:vc animated:YES completion:^{
        [self _enableEvent:YES];
    }];
}

- (IBAction)flushAssets:(UIButton *)sender {
    [self _enableEvent:NO];
    [NKDownloadViewController asyncFlushAssets:^{
        NSLog(@"flush cache completion.");
        [self _enableEvent:YES];
    }];
}

- (IBAction)flushDownloadCache:(UIButton *)sender {
    [self _enableEvent:NO];
    [NKDownloadViewController asyncFlushDownloadCache:^{
        NSLog(@"flush cache completion.");
        [self _enableEvent:YES];
    }];
}

- (void)_enableEvent:(BOOL)enable {
    for (UIButton *ev in self.events) {
        ev.enabled = enable;
    }
}

@end

