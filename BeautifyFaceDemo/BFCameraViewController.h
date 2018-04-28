//
//  BFCameraViewController.h
//  BeautifyFaceDemo
//
//  Created by 聚智在线 on 2018/3/8.
//  Copyright © 2018年 guikz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFCamera.h"

typedef NS_ENUM(NSInteger, BFMediaType) {
    BFMediaType_Default           = 0,//图片和视频
    BFMediaType_Video             = 1,
    BFMediaType_Photo             = 2
};

@protocol BFCameraViewControllerDelegate <NSObject>

-(void)cameraViewGetImage:(UIImage*)image videoPath:(NSURL*)videoPath length:(NSString*)length error:(NSError*)error;

@end

@interface BFCameraViewController : UIViewController

- (instancetype)init NS_UNAVAILABLE;

-(instancetype)initWithMediaType:(BFMediaType)type delegate:(id<BFCameraViewControllerDelegate>)delegate videoSessionType:(BFVideoSessionType)type;

@property(assign,nonatomic) NSInteger videoMaximumDuration;

@property(assign,nonatomic) NSInteger videoMinimumDuration;

@end
