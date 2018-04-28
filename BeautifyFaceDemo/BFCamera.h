//
//  BFCamera.h
//  BeautifyFaceDemo
//
//  Created by 聚智在线 on 2018/3/8.
//  Copyright © 2018年 guikz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BFVideoSessionType) {
    VSType_FullScreen           = 0,//全屏 960x540 (x 不做特殊处理)、 半屏 640x480
    VSType_HalfScreen           = 1,
};

@interface BFCamera : NSObject

- (instancetype _Nullable )init NS_UNAVAILABLE;

-(instancetype _Nullable )initWithContainerView:(nonnull UIView*)container frame:(CGRect)frame videoSessionType:(BFVideoSessionType)type;

-(void)startCameraCapture;
-(void)switchCamera;

-(void)stopCameraCapture;

-(void)startRecording;
-(void)finishRecordingWithCompletionHandler:(void (^_Nullable)(NSURL* _Nullable videoUrl,NSError* _Nullable error))handler;


-(void)takePhotoWithCompletionHandler:(void (^_Nullable)(UIImage* _Nullable image))handler;

@end
