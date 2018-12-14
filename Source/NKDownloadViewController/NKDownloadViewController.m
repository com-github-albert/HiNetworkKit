//
//  NKDownloadViewController.m
//  NetworkKit
//
//  Created by Jett on 2018/10/17.
//  Copyright © 2018 mutating. All rights reserved.
//

#import "NKDownloadViewController.h"
#import "NKDownloadManager.h"

#import "NetworkKit.h"
// Utilities
#import "NKUnZipHelper.h"
#import "NKFileManager.h"

#define LOCK(...) dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(self->_lock);

static float kNKDownloadDegreesMaxValue = M_PI * 2 * 4;
float kNKDownloadProgressMaxValue = 442.0;
float kNKDownloadStateMaxPercent = 1;

static NSNumberFormatter* pm_percentFormmat(void) {
    static NSNumberFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterPercentStyle];
    });
    return formatter;
}

static NSString* pm_percentString(CGFloat percent) {
    return [pm_percentFormmat() stringFromNumber:[NSNumber numberWithFloat:percent]];
}

typedef enum : NSUInteger {
    NKDownloadErrorCodeUnkown = 0,
    NKDownloadErrorCodeNotReachable,
    NKDownloadErrorCodeReachableViaWWAN,
    NKDownloadErrorCodeCannotUnzip,
} NKDownloadErrorCode;

typedef enum : NSUInteger {
    NKDownloadStatusNone = 0,
    NKDownloadStatusDownloading,
    NKDownloadStatusDownloadStopped,
    NKDownloadStatusUnzipping,
    NKDownloadStatusDidUnzipped,
    NKDownloadStatusFinshed
} NKDownloadStatus;

@interface NKDownloadViewController () <NKDownloadTaskDelegate> {
    NKDownloadTask *_downloadTask;
    NSURL *_locationURL;
    NSURL *_downloadURL;
    
    UIBackgroundTaskIdentifier _runningTask;
    BOOL _isInBackground;
    
    NKDownloadStatus _status;
    dispatch_semaphore_t _lock;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progress;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIImageView *progressTyre;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *alertLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadIndicator;

@end

@implementation NKDownloadViewController

+ (NKDownloadViewController *)viewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([NKDownloadViewController class]) bundle:[NSBundle bundleForClass:[NKDownloadViewController class]]];
    NKDownloadViewController *vc = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([NKDownloadViewController class])];
    return vc;
}

+ (void)asyncFlushAssets:(void (^)(void))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NKDownloadManager flushAssets];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
    });
}

+ (void)asyncFlushDownloadCache:(void (^)(void))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NKDownloadManager flushDownload];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
    });
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _status = NKDownloadStatusNone;
    _runningTask = UIBackgroundTaskInvalid;
    _lock = dispatch_semaphore_create(1);
    
    self.loadIndicator.hidden = YES;
    
    [self addNotification];
    [NKReachabilityManager.sharedManager startMonitoring];
    
    _downloadTask = NKDownloadTask.defaultTask;
    _downloadTask.cacheDirectory = NKDownloadManager.defaultManager.downloadPath;
    _downloadTask.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self startDownload];
}

- (void)free {
    [self stopDownload];
    [self removeNotification];
}

- (IBAction)back:(UIButton *)sender {
    [self free];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Notification

- (void)addNotification {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didChangeReachability:) name:NKReachabilityDidChangeNotification object:nil];
}

- (void)removeNotification {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)didBecomeActive {
    _isInBackground = NO;
    if (_status == NKDownloadStatusDidUnzipped) return;
    [self startDownload];
}

- (void)willResignActive {
    _isInBackground = YES;
    if (_status == NKDownloadStatusDidUnzipped) return;
    [self stopDownload];
}

- (void)didChangeReachability:(NSNotification *)notification {
    NSNumber *item = notification.userInfo[NKReachabilityNotificationStatusItem];
    if ( ! item) return;
    NKReachabilityStatus status = item.intValue;
    switch (status) {
        case NKReachabilityStatusReachableViaWWAN: {
            [self stopDownload];
            [self _handleError:NKDownloadErrorCodeReachableViaWWAN];
        } break;
        case NKReachabilityStatusReachableViaWiFi: {
            [self startDownload];
        } break;
        default:
            break;
    }
}

#pragma mark - Action

- (void)willRunning {
    if (_runningTask == UIBackgroundTaskInvalid) {
        _runningTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            NSLog( @"downlaod background task expired" );
        }];
    }
}

- (void)didFinishedRunning {
    if (_runningTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_runningTask];
        _runningTask = UIBackgroundTaskInvalid;
    }
}

- (void)startDownload {
    if ( ! _downloadURL) return;
    
    if ([self _downloadSuccess]) {
        [self _nextScene];
        return;
    }
    
    if (_downloadTask.currentItem.state != NKDownloadItemStateDownloading &&
        _downloadTask.currentItem.state != NKDownloadItemStateFinished) {
        [self willRunning];
        [_downloadTask resume:_downloadURL];
    }
    
    [self updateStatus:NKDownloadStatusDownloading];
}

- (void)stopDownload {    
    [_downloadTask cancelAndClean];
    [self didFinishedRunning];
    
    [self updateStatus:NKDownloadStatusDownloadStopped];
}

- (void)resetDownload {
    [self willRunning];
    
    [_downloadTask cancelAndClean];
    [_downloadTask resume:_downloadURL];
}

- (void)updateStatus:(NKDownloadStatus)status {
    LOCK
    (
     if (_status != status) {
         _status = status;
         switch (status) {
             case NKDownloadStatusDownloading: {
                 self.alertLabel.text = @"资源文件正在下载，请耐心等待";
             } break;
             case NKDownloadStatusUnzipping: {
                 self.backButton.hidden = YES;
                 self.alertLabel.text = @"资源文件下载完成，正在解压，此过程不消耗流量";
                 self.loadIndicator.hidden = NO;
                 [self.loadIndicator startAnimating];
             } break;
             case NKDownloadStatusDidUnzipped: {
                 self.backButton.hidden = NO;
                 self.alertLabel.text = @"资源文件解压完成";
                 self.loadIndicator.hidden = YES;
                 [self.loadIndicator stopAnimating];
             } break;
             case NKDownloadStatusFinshed: {
                 self.alertLabel.text = @"下载完成";
                 [self _updateProcess:kNKDownloadStateMaxPercent];
             } break;
             default:
                 break;
         }
     }
    )
}

#pragma mark - NKDownloadSessionDelegate

- (void)download:(NKDownloadItem *)item didReceiveData:(NSData *)data {
    [self _updateProcess:item.progress * kNKDownloadStateMaxPercent];
}

- (void)download:(NKDownloadItem *)item didCompleteWithError:(NSError *)error {
    if (error) {
        if (error.code != kCFURLErrorTimedOut ||
            error.code != kCFURLErrorCancelled) {
            [self _handleError:NKDownloadErrorCodeNotReachable];
        }
        [self didFinishedRunning];
    } else {
        NSLog(@"finished: %@", item.location.path);
        [self _updateProcess:kNKDownloadStateMaxPercent];
        _locationURL = item.location;
        if ([self _needUnzip]) {
            [self _unzip];
        } else {
            [NKFileManager removeDirectoryAtPath:NKFileManager.defaultManager.assetsPath];
            [NKFileManager createDirectoryAtPath:NKFileManager.defaultManager.assetsPath];
            [NKFileManager copyFileAtPath:_locationURL.path toPath:[NKFileManager.defaultManager.assetsPath stringByAppendingPathComponent:_locationURL.lastPathComponent]];
            [NKDownloadManager flushDownload];
            [self _nextScene];
        }
    }
}

#pragma mark - Unzip

- (BOOL)_needUnzip {
    NSString *extensio = _locationURL.path.pathExtension;
    if ([extensio isEqualToString:@"zip"]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)_unzip {
    [self updateStatus:NKDownloadStatusUnzipping];
    [NKUnZipHelper asyncUnzipFromPath:_locationURL.path
                             toPath:NKDownloadManager.defaultManager.unzipPath
                         completion:^(BOOL success, NSError *error) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 BOOL downloadSuccesss = [self _downloadSuccess];
                                 if (success && downloadSuccesss) {
                                     [NKDownloadManager flushDownload];
                                 }
                                 [self updateStatus:NKDownloadStatusDidUnzipped];
                                 [self didFinishedRunning];
                                 if (self->_isInBackground) {
                                     NSLog(@"in background");
                                     return;
                                 }
                                 if ( ! success || ! downloadSuccesss) {
                                     [self _handleError:NKDownloadErrorCodeCannotUnzip];
                                     return;
                                 }
                                 [self performSelector:@selector(_nextScene) withObject:nil afterDelay:0];
                             });
                         }];
}

- (BOOL)_downloadSuccess {
    return NKDownloadManager.defaultManager.hasDownloaded;
}

- (void)_nextScene {
    if (self->_isInBackground) {
        NSLog(@"in background");
        return;
    }
    [self stopDownload];
    [NKReachabilityManager.sharedManager stopMonitoring];
    [self removeNotification];
    [self updateStatus:NKDownloadStatusFinshed];
}

#pragma mark - Private

- (void)_updateProcess:(CGFloat)process {
    process = MIN(1, MAX(0, process));
    self.progress.constant = (1 - process) * kNKDownloadProgressMaxValue;
    self.progressLabel.text = pm_percentString(process);
    self.progressTyre.transform = CGAffineTransformMakeRotation(process * kNKDownloadDegreesMaxValue);
}

- (void)_handleError:(NKDownloadErrorCode)errorCode {
    switch (errorCode) {
        case NKDownloadErrorCodeNotReachable: {
            [self _alert:@"提示"
                 message:@"网络异常，请查看是否链接网络"
              cancelName:@"取消"
             confirmName:@"继续下载"
           confirmAction:^(UIAlertAction *action) {
               [self resetDownload];
           }];
        } break;
        case NKDownloadErrorCodeReachableViaWWAN: {
            [self _alert:@"提示"
                 message:@"非WIFI环境下会消耗流量，是否继续下载"
              cancelName:@"取消"
             confirmName:@"继续下载"
           confirmAction:^(UIAlertAction *action) {
               [self startDownload];
           }];
        } break;
        case NKDownloadErrorCodeCannotUnzip: {
            [NKDownloadManager flushDownload];
            [self _alert:@"提示"
                 message:@"解压文件失败，请重新下载"
              cancelName:@"取消"
             confirmName:@"重新下载"
           confirmAction:^(UIAlertAction *action) {
               [NKDownloadManager flushAssets];
               self.alertLabel.hidden = YES;
               self.backButton.hidden = NO;
               [self resetDownload];
           }];
        } break;
        default: break;
    }
}

- (void)_alert:(NSString *)title
       message:(NSString *)message
    cancelName:(NSString *)cancelName
   confirmName:(NSString *)confirmName
 confirmAction:(void (^ )(UIAlertAction *action))action {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    if (cancelName != nil) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelName style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
    }
    if (confirmName != nil) {
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:confirmName style:UIAlertActionStyleDefault handler:action];
        [alertController addAction:confirmAction];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Orientation

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(deviceOrientation)) {
        return (UIInterfaceOrientation)deviceOrientation;
    }
    return UIInterfaceOrientationLandscapeRight;
}

@end
