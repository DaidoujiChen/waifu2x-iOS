//
//  UIImage+waifu2x.m
//  waifu2x-iOS
//
//  Created by DaidoujiChen on 2015/7/7.
//  Copyright (c) 2015年 DaidoujiChen. All rights reserved.
//

#import "UIImage+waifu2x.h"
#import <objc/runtime.h>
#import "opencv2/opencv.hpp"
#import "convertRoutine.hpp"
#import "modelHandler.hpp"
#import "UIImage+OpenCV.h"

#define numberOfJobs 4

@implementation UIImage (waifu2x)

#pragma mark - instance method

- (void)waifu2xCompletion:(void (^)(waifu2xStatus status, UIImage *waifu2xImage))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        waifu2xStatus status = waifu2xStatusSuccess;
        
        // load image file
        cv::Mat cvImage = self.CVMat;
        cvImage.convertTo(cvImage, CV_32F, 1.0 / 255.0);
        cv::cvtColor(cvImage, cvImage, cv::COLOR_RGB2YUV);
        
        // set number of jobs for processing models
        w2xc::modelUtility::getInstance().setNumberOfJobs(numberOfJobs);
        
        // noise reduction
        status = [self noiseReductionImage:cvImage];
        
        // scaling
        if (status == waifu2xStatusSuccess) {
            status = [self scalingImage:cvImage];
        }
        
        if (status == waifu2xStatusSuccess) {
            cv::cvtColor(cvImage, cvImage, cv::COLOR_YUV2RGB);
            cvImage.convertTo(cvImage, CV_8U, 255.0);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(status, (status == waifu2xStatusSuccess) ? [UIImage imageWithCVMat:cvImage] : nil);
        });
    });
}

#pragma mark - private instance method

- (waifu2xStatus)noiseReductionImage:(cv::Mat)cvImage {
    std::vector <std::unique_ptr <w2xc::Model>> models;
    if (!w2xc::modelUtility::generateModelFromJSON([UIImage waifu2x_noiseReductionFilePath], models)) {
        return waifu2xStatusJsonLoadFail;
    }
    
    std::vector <cv::Mat> imageSplit;
    cv::Mat imageY;
    cv::split(cvImage, imageSplit);
    imageSplit[0].copyTo(imageY);
    w2xc::convertWithModels(imageY, imageSplit[0], models);
    cv::merge(imageSplit, cvImage);
    
    return waifu2xStatusSuccess;
}

- (waifu2xStatus)scalingImage:(cv::Mat)cvImage {
    std::vector <std::unique_ptr <w2xc::Model>> models;
    if (!w2xc::modelUtility::generateModelFromJSON([UIImage waifu2x_scalingFilePath], models)) {
        return waifu2xStatusJsonLoadFail;
    }
    
    CGFloat scaleRatio = 2.0f;
    
    // calculate iteration times of 2x scaling and shrink ratio which will use at last
    NSInteger iterTimesTwiceScaling = ceil(log2(scaleRatio));
    CGFloat shrinkRatio = 0.0;
    CGFloat powIterTimesTwiceScaling = pow(2, iterTimesTwiceScaling);
    if (scaleRatio != powIterTimesTwiceScaling) {
        shrinkRatio = scaleRatio / powIterTimesTwiceScaling;
    }
    
    NSLog(@"start scaling");
    
    // 2x scaling
    for (NSInteger nIteration = 0; nIteration < iterTimesTwiceScaling; nIteration++) {
        NSLog(@"#%td 2x scaling...", nIteration + 1);
        
        cv::Size imageSize = cvImage.size();
        imageSize.width *= 2;
        imageSize.height *= 2;
        cv::Mat image2xNearest;
        cv::resize(cvImage, image2xNearest, imageSize, 0, 0, cv::INTER_NEAREST);
        std::vector <cv::Mat> imageSplit;
        cv::Mat imageY;
        cv::split(image2xNearest, imageSplit);
        imageSplit[0].copyTo(imageY);
        
        // generate bicubic scaled image and split
        imageSplit.clear();
        cv::Mat image2xBicubic;
        cv::resize(cvImage, image2xBicubic, imageSize, 0, 0, cv::INTER_CUBIC);
        cv::split(image2xBicubic, imageSplit);
        
        if (!w2xc::convertWithModels(imageY, imageSplit[0], models)) {
            NSLog(@"w2xc::convertWithModels : something error has occured.\nstop.");
            return waifu2xStatusFail;
        }
        
        cv::merge(imageSplit, cvImage);
    } // 2x scaling : end
    
    if (shrinkRatio != 0.0) {
        cv::Size lastImageSize = cvImage.size();
        lastImageSize.width = static_cast <int>(static_cast <double>(lastImageSize.width * shrinkRatio));
        lastImageSize.height = static_cast <int>(static_cast <double>(lastImageSize.height * shrinkRatio));
        cv::resize(cvImage, cvImage, lastImageSize, 0, 0, cv::INTER_LINEAR);
    }
    
    return waifu2xStatusSuccess;
}

+ (std::string)waifu2x_noiseReductionFilePath {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [NSString stringWithFormat:@"%@/noise2_model.json", [[NSBundle mainBundle] bundlePath]];
        objc_setAssociatedObject(self, _cmd, path, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
    std::string noiseReductionFilePath([objc_getAssociatedObject(self, _cmd) UTF8String]);
    return noiseReductionFilePath;
}

+ (std::string)waifu2x_scalingFilePath {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [NSString stringWithFormat:@"%@/scale2.0x_model.json", [[NSBundle mainBundle] bundlePath]];
        objc_setAssociatedObject(self, _cmd, path, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
    std::string scalingFilePath([objc_getAssociatedObject(self, _cmd) UTF8String]);
    return scalingFilePath;
}

@end
