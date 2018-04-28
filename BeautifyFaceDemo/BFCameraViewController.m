//
//  BFCameraViewController.m
//  BeautifyFaceDemo
//
//  Created by 聚智在线 on 2018/3/8.
//  Copyright © 2018年 guikz. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "BFCameraViewController.h"


#define kDevice_Is_iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

#define LocalizedImageNamed(x) [UIImage imageNamed:(NSLocalizedString((x),nil))]

#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width

@interface BFCameraViewController ()
{
    NSTimer* _tickTimer;
    NSInteger _tickNumber;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightLayout;
@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet UIView *flagView;


@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UIView *bottomView;

@property (weak, nonatomic) IBOutlet UIButton *cancelBt;
@property (weak, nonatomic) IBOutlet UIButton *switchBt;

@property (weak, nonatomic) IBOutlet UIButton *startBt;

@property(nonatomic,strong)BFCamera* camera;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;

@property(nonatomic,assign)BFMediaType mediaType;

@property(nonatomic,assign)BFMediaType curMediaType;

@property(nonatomic,weak)id<BFCameraViewControllerDelegate> delegate;

@property(nonatomic,strong)UILabel* photoLabel;
@property(nonatomic,strong)UILabel* videoLabel;

@property (nonatomic,assign)BFVideoSessionType sessionType;

@end

@implementation BFCameraViewController

-(instancetype)initWithMediaType:(BFMediaType)mediaType delegate:(id<BFCameraViewControllerDelegate>)delegate videoSessionType:(BFVideoSessionType)type{
    self = [super init];
    if (self) {
        self.sessionType = type;
        self.mediaType = mediaType;
        self.delegate = delegate;
        if (mediaType != BFMediaType_Default) {
            self.flagView.hidden = YES;
            self.curMediaType = mediaType;
        }else{
            self.curMediaType = BFMediaType_Photo;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.cancelBt setTitle:NSLocalizedString(@"取消", nil) forState:UIControlStateNormal];
    if (kDevice_Is_iPhoneX) {
        CGRect rectStatus = [[UIApplication sharedApplication] statusBarFrame];
        self.heightLayout.constant = 40 + CGRectGetHeight(rectStatus);
    }
    
    self.topView.hidden = YES;
    
    self.camera = [[BFCamera alloc] initWithContainerView:self.view frame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-(self.sessionType == VSType_FullScreen ?0:120)) videoSessionType:self.sessionType];
    if (self.videoMaximumDuration) {
        [self updateTimerLabel:0];
    }
    
    if (self.mediaType == BFMediaType_Default) {
        self.photoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 20)];
        self.photoLabel.font = [UIFont systemFontOfSize:12];
        self.photoLabel.text = NSLocalizedString(@"照片", nil);
        [self.flagView addSubview:self.photoLabel];
        self.photoLabel.center = CGPointMake(SCREEN_WIDTH*0.5, 10.f);
        self.photoLabel.textColor = [UIColor whiteColor];
        self.photoLabel.textAlignment = NSTextAlignmentCenter;
        
        self.videoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 20)];
        self.videoLabel.font = [UIFont systemFontOfSize:12];
        self.videoLabel.text = NSLocalizedString(@"视频", nil);
        [self.flagView addSubview:self.videoLabel];
        self.videoLabel.center = CGPointMake(SCREEN_WIDTH*3.f/4.f, 10.f);
        self.videoLabel.textColor = [UIColor lightGrayColor];
        self.videoLabel.textAlignment = NSTextAlignmentCenter;
        
        UISwipeGestureRecognizer*rightRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
        [rightRecognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
        [self.view addGestureRecognizer:rightRecognizer];
        
        UISwipeGestureRecognizer* leftRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
        [leftRecognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
        [self.view addGestureRecognizer:leftRecognizer];
        
    }
}
- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer{
    [self swipeTo:recognizer.direction == UISwipeGestureRecognizerDirectionRight];
    if(recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        NSLog(@"swipe left");
    }
    if(recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        NSLog(@"swipe right");
    }
}
-(void)swipeTo:(BOOL)right{
    if (right && (self.photoLabel.center.x >= (SCREEN_WIDTH*0.5-1))) {
        return;
    }else if (!right && (self.videoLabel.center.x <= (SCREEN_WIDTH*0.5+1))){
        return;
    }
    float photoCenterX = right?SCREEN_WIDTH*0.5:SCREEN_WIDTH*1.f/4.f;
    float videoCenterX = right?SCREEN_WIDTH*3.f/4.f:SCREEN_WIDTH*0.5;
    [UIView animateWithDuration:0.3 animations:^{
        self.photoLabel.center = CGPointMake(photoCenterX, 10.f);
        self.videoLabel.center = CGPointMake(videoCenterX, 10.f);
    }];
    self.photoLabel.textColor = right?[UIColor whiteColor]:[UIColor lightGrayColor];
    self.videoLabel.textColor = right?[UIColor lightGrayColor]:[UIColor whiteColor];
    self.curMediaType = right?BFMediaType_Photo:BFMediaType_Video;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    [self.camera startCameraCapture];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.camera startCameraCapture];
}

- (IBAction)cancelBtClicked:(UIButton*)sender {
    self.delegate = nil;
     [self.camera stopCameraCapture];
    if (_tickTimer) {
        [_tickTimer invalidate];
        _tickTimer = nil;
    }
    sender.enabled = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)switchBtClicked:(UIButton*)sender {
    [self.camera switchCamera];
}

- (IBAction)startBtClicked:(UIButton*)sender {
    self.flagView.hidden = YES;
    sender.enabled = NO;
    if (self.mediaType == BFMediaType_Photo || (self.mediaType == BFMediaType_Default && self.curMediaType == BFMediaType_Photo)) {
        [self.camera takePhotoWithCompletionHandler:^(UIImage * _Nullable image) {
            [self.camera stopCameraCapture];
            [self dismissViewControllerAnimated:YES completion:^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(cameraViewGetImage:videoPath:length:error:)]) {
                    [self.delegate cameraViewGetImage:image videoPath:nil length:nil error:nil];
                }
            }];
        }];
    }else{
        self.topView.hidden = NO;
        if (_tickTimer) {
            [self stopRecordAndDismiss];
        }else{
            
            //        [self.imagePicker startVideoCapture];
            [self.camera startRecording];
            _tickNumber = 0;
            _tickTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
            [self updateTimerLabel:_tickNumber];
            if (self.videoMinimumDuration > 1) {
                if(self.sessionType == VSType_FullScreen){
                    [UIView animateWithDuration:0.3 animations:^{
                        self.bottomView.alpha = 0.f;
                        self.flagView.alpha = 0.f;
                    } completion:^(BOOL finished) {
                        self.bottomView.hidden = YES;
                        self.startBt.enabled = YES;
                        self.cancelBt.hidden = YES;
                        self.switchBt.hidden = YES;
                        [self.startBt setImage:LocalizedImageNamed(@"Video_停止按钮") forState:UIControlStateNormal];
                    }];
                }else{
                    self.startBt.enabled = NO;
                }
            }else{
                self.cancelBt.hidden = YES;
                self.switchBt.hidden = YES;
                self.startBt.enabled = YES;
                [self.startBt setImage:LocalizedImageNamed(@"Video_停止按钮") forState:UIControlStateNormal];
            }
        }
        
    }
    //
}

-(void)stopRecordAndDismiss{
    self.startBt.enabled = NO;
    [self.startBt setImage:LocalizedImageNamed(@"Video_录制按钮") forState:UIControlStateNormal];
    self.bottomView.userInteractionEnabled = NO;
    [_tickTimer invalidate];
    _tickTimer = nil;
    //        [self.imagePicker stopVideoCapture];
    [self.activityView startAnimating];
    [self.camera finishRecordingWithCompletionHandler:^(NSURL * _Nullable videoUrl, NSError * _Nullable error) {
        [self.activityView stopAnimating];
        [self.camera stopCameraCapture];
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraViewGetImage:videoPath:length:error:)]) {
                NSString* length = [NSString stringWithFormat:@"%.0f", [self getVideoDuration:videoUrl]];
                [self.delegate cameraViewGetImage:nil videoPath:videoUrl length:length error:error];
            }
        }];
    }];
}

-(void)tick:(NSTimer*)timer{
    _tickNumber ++;
    [self updateTimerLabel:_tickNumber];
    if (self.videoMaximumDuration > 0 && _tickNumber > self.videoMaximumDuration) {
        [self stopRecordAndDismiss];
    }else if (_tickNumber > self.videoMinimumDuration) {
        if (self.bottomView.hidden) {
            self.bottomView.hidden = NO;
            [UIView animateWithDuration:0.3 animations:^{
                self.bottomView.alpha = 1.f;
                self.flagView.alpha = 1.f;
            }];
        }
        self.startBt.enabled = YES;
    }
}
-(void)updateTimerLabel:(NSInteger)sec{
    NSInteger leftSec = sec;
    if (self.videoMaximumDuration > 0) {
        leftSec = self.videoMaximumDuration - sec;
    }
    if (leftSec <= 0) {
        self.timeLabel.text = @"00:00";
    }else{
        self.timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld",(long)(leftSec/60),(long)(leftSec%60)];
    }
}
- (BOOL)prefersStatusBarHidden{
    return YES;
}

//获取视频时间
- (CGFloat) getVideoDuration:(NSURL*) URL
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:URL options:opts];
    float second = 0;
    second = urlAsset.duration.value/urlAsset.duration.timescale;
    return second;
}

@end
