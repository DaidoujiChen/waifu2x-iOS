//
//  MainViewController.m
//  waifu2x-iOS
//
//  Created by DaidoujiChen on 2015/7/7.
//  Copyright (c) 2015年 DaidoujiChen. All rights reserved.
//

#import "MainViewController.h"
#import "UIImage+waifu2x.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *upperImageView;
@property (weak, nonatomic) IBOutlet UIImageView *bottomImageView;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *image = [UIImage imageNamed:@"200x200.jpeg"];
    self.upperImageView.image = image;
    
    __weak MainViewController *weakSelf = self;
    [image waifu2xCompletion: ^(waifu2xStatus status, UIImage *waifu2xImage) {
        if (status == waifu2xStatusSuccess) {
            weakSelf.bottomImageView.image = waifu2xImage;
        }
        else {
            NSLog(@"出錯");
        }
    }];
}

@end
