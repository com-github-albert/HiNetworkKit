//
//  ViewController.m
//  Sample
//
//  Created by Jett on 2018/12/14.
//  Copyright © 2018 mutating. All rights reserved.
//

#import "ViewController.h"
#import "NKDownloadViewController.h"

@interface ViewController () {
    NSURL *_downloadURL;
}

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *events;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *downloadUrlStrings = @[
                                    @"https://images.apple.com/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4",
                                    @"https://res.hiar.io/group1/M00/6E/F1/CgBkg1plXpaABWz_AM8uhEhe7Wc281.mp4",
                                    @"http://pjo6gnl9h.bkt.clouddn.com/20181213/Assets.zip"     // me
                                    ];
    _downloadURL = [NSURL URLWithString:downloadUrlStrings[1]];}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NKDownloadViewController * vc = NKDownloadViewController.viewController;
    vc.downloadURL = _downloadURL;
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)presentAR:(UIButton *)sender {
    NKDownloadViewController * vc = NKDownloadViewController.viewController;
    vc.downloadURL = _downloadURL;
    [self presentViewController:vc animated:YES completion:nil];
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

- (IBAction)exit:(UIStoryboardSegue *)unwindSegue {
    NSLog(@"%s", __func__);
}

@end
