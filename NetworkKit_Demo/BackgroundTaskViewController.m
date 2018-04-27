//
//  BackgroundTaskViewController.m
//  NetworkKit_Demo
//
//  Created by Jett on 26/04/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "BackgroundTaskViewController.h"

static UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
static NSString *_backgroundTaskName = @"HiARackgroundTaskTask";
static bool _backgroundTaskIsFinished = false;
static void _endBackgroundTask() {
    if (UIBackgroundTaskInvalid == _backgroundTaskIdentifier) return;
    [UIApplication.sharedApplication endBackgroundTask:_backgroundTaskIdentifier];
    _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
}
static void _beginBackgroundTask() {
    if (true == _backgroundTaskIsFinished) return;
    _backgroundTaskIdentifier = [UIApplication.sharedApplication beginBackgroundTaskWithName:_backgroundTaskName
                                                                               expirationHandler:^{
                                                                                   _endBackgroundTask();
                                                                               }];
}

@interface BackgroundTaskViewController ()

@end

@implementation BackgroundTaskViewController {
    NSTimer *_timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    [self addNotification];
    [self addTimer];
}

- (void)dealloc {
    [self removeTimer];
    [self removeNotification];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addTimer {
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.f
                                    repeats:YES
                                      block:^(NSTimer * _Nonnull timer) {
                                          NSLog(@"update timer");
                                      }];
}

- (void)removeTimer {
    [_timer invalidate];
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
}

- (void)willResignActive {
    _beginBackgroundTask();
}

- (void)didBecomeActive {
    _endBackgroundTask();
}

@end
