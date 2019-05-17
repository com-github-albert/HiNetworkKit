//
//  CacheViewController.m
//  Sample
//
//  Created by Jett on 2019/2/28.
//  Copyright © 2019 Mutating. All rights reserved.
//

#import "CacheViewController.h"

@import HiNetworkKit;

@interface CacheViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation CacheViewController {
    NSURL *_url;
    NSString *_urlString;
    NKCache *_cache;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _urlString = @"https://github.com/mutating/NetworkKit/blob/master/NetworkKit.png?raw=true";
    _url = [NSURL URLWithString:_urlString];
    _cache = [[NKCache alloc] init];
}

- (IBAction)loadImage:(UIButton *)sender {
    if (![_cache containsObjectForKey:_urlString]) {
        self.textView.text = [@"Load image from url " stringByAppendingFormat:@"%@.", _urlString];
        self.textView.text = [self.textView.text stringByAppendingFormat:@"\nLoading......"];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:self->_url];
            UIImage *image = [UIImage imageWithData:imageData];
            if (image) {
                [self->_cache setObject:image forKey:self->_urlString];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image = image;
                    self.textView.text = [self.textView.text stringByAppendingFormat:@"\nSave image to cache."];
                });
            }
        });
    } else {
        UIImage *image = (UIImage *)[_cache objectForKey:_urlString];
        self.imageView.image = image;
        self.textView.text = @"Load image from cache.";
    }
}

- (IBAction)eraseImage:(UIButton *)sender {
    [_cache removeObjectForKey:_urlString];
    self.imageView.image = nil;
    self.textView.text = @"Remove image from cache.";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
