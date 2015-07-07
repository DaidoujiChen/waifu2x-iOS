//
//  UIImage+waifu2x.h
//  waifu2x-iOS
//
//  Created by DaidoujiChen on 2015/7/7.
//  Copyright (c) 2015年 DaidoujiChen. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    waifu2xStatusJsonLoadFail,
    waifu2xStatusFail,
    waifu2xStatusSuccess
} waifu2xStatus;

@interface UIImage (waifu2x)

- (void)waifu2xCompletion:(void (^)(waifu2xStatus status, UIImage *waifu2xImage))completion;

@end
