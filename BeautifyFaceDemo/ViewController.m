//
//  ViewController.m
//  BeautifyFaceDemo
//
//  Created by guikz on 16/4/27.
//  Copyright © 2016年 guikz. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage/GPUImage.h>
#import "GPUImageBeautifyFilter.h"
#import <Masonry/Masonry.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "BFCameraViewController.h"

@interface ViewController ()<BFCameraViewControllerDelegate>
{
    GPUImageMovieWriter * movieWriter;
    
//    GPUImageVideoCamera * videoCamera;
    
    NSMutableDictionary * videoSettings;
    
    NSDictionary * audioSettings;
    
    NSString * pathToMovie;
    
    NSURL *movieURL;
}

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) UIButton *photoButton;
@property (nonatomic, strong) UIButton *recordButton;

@property (nonatomic, strong)GPUImageBeautifyFilter *beautifyFilter;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //init Video Setting
    /*
    videoSettings = [[NSMutableDictionary alloc] init];;
    [videoSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [videoSettings setObject:[NSNumber numberWithInteger:480] forKey:AVVideoWidthKey];
    [videoSettings setObject:[NSNumber numberWithInteger:640] forKey:AVVideoHeightKey];

    //init audio setting
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                     [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                     [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
                     [ NSNumber numberWithFloat: 16000.0 ], AVSampleRateKey,
                     [ NSData dataWithBytes:&channelLayout length: sizeof( AudioChannelLayout ) ], AVChannelLayoutKey,
                     [ NSNumber numberWithInt: 32000 ], AVEncoderBitRateKey,
                     nil];
    
    //init Movie path
    pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    movieURL = [NSURL fileURLWithPath:pathToMovie];

    //init movieWriter
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0) fileType:AVFileTypeMPEG4 outputSettings:videoSettings];
    [movieWriter setHasAudioTrack:YES audioSettings:audioSettings];
    movieWriter.encodingLiveVideo = YES;
    movieWriter.assetWriter.movieFragmentInterval = kCMTimeInvalid;
    
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    [self.videoCamera addAudioInputsAndOutputs];
    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.filterView.center = self.view.center;
    [self.view addSubview:self.filterView];
//    [self.videoCamera addTarget:self.filterView];
    
    
    self.videoCamera.audioEncodingTarget = movieWriter;
//    [self.videoCamera removeAllTargets];
    self.beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    [self.videoCamera addTarget:self.beautifyFilter];
    [self.beautifyFilter addTarget:movieWriter];
    [self.beautifyFilter addTarget:self.filterView];
    
    [self.videoCamera startCameraCapture];
    */
    self.photoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.photoButton.backgroundColor = [UIColor whiteColor];
    [self.photoButton setTitle:@"拍照" forState:UIControlStateNormal];
//    [self.photoButton setTitle:@"关闭" forState:UIControlStateSelected];
    [self.photoButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.photoButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.photoButton];
    [self.photoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-20);
        make.width.equalTo(@100);
        make.height.equalTo(@40);
//        make.rightMargin.equalTo(@55);
        make.centerX.equalTo(self.view);
    }];
    /*
    self.recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.recordButton.backgroundColor = [UIColor whiteColor];
    [self.recordButton setTitle:@"录制" forState:UIControlStateNormal];
    [self.recordButton setTitle:@"停止录制" forState:UIControlStateSelected];
    [self.recordButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.recordButton addTarget:self action:@selector(record:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.recordButton];
    [self.recordButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-20);
        make.width.equalTo(@100);
        make.height.equalTo(@40);
        make.leftMargin.equalTo(@25);
//        make.centerX.equalTo(self.view);
    }];
*/
}

-(void)record:(UIButton*)bt{
    bt.selected = !bt.selected;
    if (bt.selected) {
        [movieWriter startRecording];
    }else{
        [self.beautifyFilter removeTarget:movieWriter];
        
        [movieWriter finishRecordingWithCompletionHandler:^{
            NSLog(@"原视频大小 %f MB",[self fileSize:[NSURL fileURLWithPath:pathToMovie]]);
            NSString* ysFilePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie_ys.m4v"];
            unlink([ysFilePath UTF8String]);
            //压缩
            AVURLAsset *avAsset = [[AVURLAsset alloc] initWithURL:movieURL options:nil];
            NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
            if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
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
                   
                    if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
//                        [self saveVideo:[NSURL fileURLWithPath:ysFilePath]];
                        NSLog(@"压缩完毕,压缩后大小 %f MB",[self fileSize:[NSURL fileURLWithPath:ysFilePath]]);
                    }else{
                        NSLog(@"当前压缩进度:%f",exportSession.progress);
                    }
                    NSLog(@"%@",exportSession.error);
                    
                }];
            }
        }];

    }
}

- (CGFloat)fileSize:(NSURL *)path
{
    return [[NSData dataWithContentsOfURL:path] length]/1024.00 /1024.00;
}
- (void)takePhoto {
    BFCameraViewController* ccVc = [[BFCameraViewController alloc] initWithMediaType:BFMediaType_Default delegate:self videoSessionType:VSType_HalfScreen];
    ccVc.videoMaximumDuration = 10;
    ccVc.videoMinimumDuration = 5;
    [self presentViewController:ccVc animated:YES completion:nil];
}

-(void)cameraViewGetImage:(UIImage*)image videoPath:(NSURL*)videoPath length:(NSString*)length error:(NSError*)error{
    //
}

@end
