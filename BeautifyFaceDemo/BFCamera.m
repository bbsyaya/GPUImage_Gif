//
//  BFCamera.m
//  BeautifyFaceDemo
//
//  Created by 聚智在线 on 2018/3/8.
//  Copyright © 2018年 guikz. All rights reserved.
//

#import "BFCamera.h"
#import <GPUImage/GPUImage.h>
#import "BFUImageTextureInput.h"
#import "GPUImageBeautifyFilter.h"
#import <Masonry/Masonry.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface BFCamera ()
{
    GPUImageMovieWriter * movieWriter;
    CGRect _filterFrame;
    BFUImageTextureInput* _textureOutput;
}

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong)GPUImageBeautifyFilter *beautifyFilter;

@property (nonatomic,weak)UIView* containerView;

@property (nonatomic,strong)NSURL* movieURL;

@property (nonatomic,assign)BOOL recording;

@property (nonatomic,assign)BFVideoSessionType sessionType;
           
@end

@implementation BFCamera

-(instancetype _Nullable )initWithContainerView:(nonnull UIView*)container frame:(CGRect)frame videoSessionType:(BFVideoSessionType)type{
    self = [super init];
    if (self) {
        self.recording = NO;
        self.sessionType = type;
        self.containerView = container;
        _filterFrame = frame;
        NSString* videoPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
        unlink([videoPath UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
        self.movieURL = [NSURL fileURLWithPath:videoPath];
        [self setupCamera];
    }
    return self;
}

-(void)setupCamera{
    NSMutableDictionary * videoSettings = [[NSMutableDictionary alloc] init];;
    [videoSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [videoSettings setObject:[NSNumber numberWithInteger:self.sessionType == VSType_FullScreen?540:480] forKey:AVVideoWidthKey];
    [videoSettings setObject:[NSNumber numberWithInteger:self.sessionType == VSType_FullScreen?960:640] forKey:AVVideoHeightKey];
    
    //init audio setting
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    NSDictionary * audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                     [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                     [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
                     [ NSNumber numberWithFloat: 16000.0 ], AVSampleRateKey,
                     [ NSData dataWithBytes:&channelLayout length: sizeof( AudioChannelLayout ) ], AVChannelLayoutKey,
                     [ NSNumber numberWithInt: 32000 ], AVEncoderBitRateKey,
                     nil];
    
    //init Movie path
    //init movieWriter
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.movieURL size:CGSizeMake(self.sessionType == VSType_FullScreen?540:480, self.sessionType == VSType_FullScreen?960:640) fileType:AVFileTypeMPEG4 outputSettings:videoSettings];
    [movieWriter setHasAudioTrack:YES audioSettings:audioSettings];
    movieWriter.encodingLiveVideo = YES;
    movieWriter.assetWriter.movieFragmentInterval = kCMTimeInvalid;
    
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:self.sessionType == VSType_FullScreen?AVCaptureSessionPresetiFrame960x540:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    [self.videoCamera addAudioInputsAndOutputs];
    self.filterView = [[GPUImageView alloc] initWithFrame:_filterFrame];
    self.filterView.center = CGPointMake(_filterFrame.size.width*0.5, _filterFrame.size.height*0.5 + _filterFrame.origin.y);//self.containerView.center;
    [self.containerView insertSubview:self.filterView atIndex:0];
    
    self.videoCamera.audioEncodingTarget = movieWriter;
    
    self.beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    [self.videoCamera addTarget:self.beautifyFilter];
    [self.beautifyFilter addTarget:self.filterView];
    
    _textureOutput = [[BFUImageTextureInput alloc] init];
//    textureOutput.delegate = self;
}

//- (void)newFrameReadyFromTextureOutput:(GPUImageTextureOutput *)callbackTextureOutput{
////    NSLog(@"## newFrameReadyFromTextureOutput");
//    GPUImageFramebuffer* framebuffer = callbackTextureOutput.firstInputFramebuffer;
//    CGImageRef image = [framebuffer newCGImageFromFramebufferContents];
//}
//
-(void)stopCameraCapture{
    if (self.recording) {
        [self finishRecordingWithCompletionHandler:nil];
    }
    [self.videoCamera stopCameraCapture];
}

-(void)startCameraCapture{
    [self.videoCamera startCameraCapture];
}

-(void)switchCamera{
    [self.videoCamera stopCameraCapture];
    if (_videoCamera.cameraPosition == AVCaptureDevicePositionFront) {
        _videoCamera = [_videoCamera initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
    }
    else if(_videoCamera.cameraPosition == AVCaptureDevicePositionBack)
    {
        _videoCamera = [_videoCamera initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionFront];
    }
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    [self.videoCamera addTarget:self.beautifyFilter];
    if (self.recording) {
        [self.beautifyFilter addTarget:movieWriter];
    }
    
    [self.videoCamera startCameraCapture];
}

-(void)startRecording{
    self.recording = YES;
    [self.beautifyFilter addTarget:movieWriter];
    [self.beautifyFilter addTarget:_textureOutput];
    [movieWriter startRecording];
}

-(void)finishRecordingWithCompletionHandler:(void (^_Nullable)(NSURL* _Nullable videoUrl,NSError* _Nullable error))handler{
    self.recording = NO;
    [self.beautifyFilter removeTarget:movieWriter];
    [self.beautifyFilter removeTarget:_textureOutput];
    
    [movieWriter finishRecordingWithCompletionHandler:^{
        [_textureOutput creatGif];
        dispatch_async(dispatch_get_main_queue(), ^(){
        if (handler) {
            handler(self.movieURL,nil);
            /*
            NSLog(@"原视频大小 %f MB",[self fileSize:self.movieURL]);
            NSString* ysFilePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie_ys.m4v"];
            unlink([ysFilePath UTF8String]);
            //压缩
            AVURLAsset *avAsset = [[AVURLAsset alloc] initWithURL:self.movieURL options:nil];
            //        NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
            //        if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
            AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
            //输出URL
            exportSession.outputURL = [NSURL fileURLWithPath:ysFilePath];
            //优化网络
            exportSession.shouldOptimizeForNetworkUse = true;
            //转换后的格式
            exportSession.outputFileType = AVFileTypeMPEG4;
            //异步导出
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                // 如果导出的状态为完成
                //                if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                                    NSLog(@"压缩完毕,压缩后大小 %f MB",[self fileSize:[NSURL fileURLWithPath:ysFilePath]]);
                //                }
                //                NSLog(@"%@",exportSession.error);
                
                handler(exportSession.outputURL,exportSession.error);
                
            }];*/
            //        }
        }
            });
    }];
}
-(void)takePhotoWithCompletionHandler:(void (^_Nullable)(UIImage* _Nullable image))handler{
    if (handler) {
        [self.beautifyFilter useNextFrameForImageCapture];
        UIImage *img = [self.beautifyFilter imageFromCurrentFramebuffer];
        handler(img);
    }
}
- (CGFloat)fileSize:(NSURL *)path{
    return [[NSData dataWithContentsOfURL:path] length]/1024.00 /1024.00;
}
@end
