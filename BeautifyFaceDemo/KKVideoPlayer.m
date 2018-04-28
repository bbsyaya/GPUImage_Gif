//
//  KKVideoPlayer.m
//  PoPo
//
//  Created by 聚智在线 on 2018/3/1.
//  Copyright © 2018年 JZZX. All rights reserved.
//

#import "KKVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
//#import "UIImageView+WebCache.h"
//#import "KKAppraiseView.h"

@interface KKVideoPlayer()

@property(nonatomic,weak)UIView* playView;

@property(nonatomic,weak)id<KKVideoPlayerDelegate> delegate;

@property (nonatomic ,strong) AVPlayerItem *item;

@property (nonatomic ,strong) AVPlayerLayer *playerLayer;

@property (nonatomic ,strong) AVPlayer *player;

@property (strong, nonatomic) UIActivityIndicatorView *activityView;

@property (strong, nonatomic) UIButton *playBt;

@property (copy, nonatomic) NSURL *url;

/** 播放器观察者 */
@property (nonatomic ,strong)  id timeObser;

@end

@implementation KKVideoPlayer

-(void)setupPlayerWithPlayView:(UIView*)playView delegate:(id<KKVideoPlayerDelegate>)delegate url:(NSURL*)url{
    self.playView = playView;
    self.delegate = delegate;
    self.url = url;
    [self prepareToPlay];
}

-(void)prepareToPlay{
    
    self.playBt = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    [self.playView addSubview:self.playBt];
    self.playBt.center = CGPointMake(CGRectGetWidth(self.playView.frame)*0.5, CGRectGetHeight(self.playView.frame)*0.5);
    self.playBt.hidden = YES;
    [self.playBt setImage:[UIImage imageNamed:@"播放按钮(大)"] forState:(UIControlStateNormal)];
    [self.playBt addTarget:self action:@selector(playBtClicked:) forControlEvents:(UIControlEventTouchUpInside)];
    self.playBt.hidden = YES;
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleWhiteLarge)];
    [self.playView addSubview:self.activityView];
    self.activityView.center = CGPointMake(CGRectGetWidth(self.playView.frame)*0.5, CGRectGetHeight(self.playView.frame)*0.5);
    self.activityView.hidesWhenStopped = YES;
    [self.activityView startAnimating];


    //本地视频
    //NSURL *rul = [NSURL fileURLWithPath:_playerUrl];
//    NSString* _playerUrl = self.url;//@"http://121.42.144.2:8094/friend/video/201711/10/14/24/1510295057411A769FCD.MOV";
    self.url = [NSURL URLWithString:@"http://imagetw.ilove.ren/videoEn_apollo/call_video/call_1516536423477AEF6D7A.mp4"];
    NSURL *url = self.url;//[NSURL URLWithString:_playerUrl];
    //    NSLog(@"%@",url);
    //
    _item = [[AVPlayerItem alloc] initWithURL:url];
    _player = [AVPlayer playerWithPlayerItem:_item];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    _playerLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.playView.frame), CGRectGetHeight(self.playView.frame));//self.view.bounds;
    [self.playView.layer insertSublayer:_playerLayer atIndex:0];
    
    
    [self addVideoKVO];
    [self addVideoNotic];
    [self addPlayerObserver];
}

-(void)playBtClicked:(UIButton*)sender{
    //    [self setUpPlayer];
    if (!self.player) {
        return;
    }
//    [self.item seekToTime:kCMTimeZero];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];//修复声音
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
             withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                   error:nil];
    
    [self.player play];
    self.playBt.hidden = YES;
    [self.activityView startAnimating];
}
-(void)pause{
    if (self.player.rate != 0.0) {
        [self.player pause];
        self.playBt.hidden = YES;
    }
}
#pragma mark - KVO
- (void)addVideoKVO
{
    //KVO
    [_item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
}
- (void)removeVideoKVO {
    [_item removeObserver:self forKeyPath:@"status"];
    [_item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
}
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString*, id> *)change context:(nullable void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        
        AVPlayerItemStatus status = _item.status;
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
            {
                NSLog(@"AVPlayerItemStatusReadyToPlay");
                //                [_player play];
                //                self.imageView.hidden = YES;
                [self.activityView stopAnimating];
                self.playBt.hidden = NO;
            }
                break;
            case AVPlayerItemStatusUnknown:
            {
                NSLog(@"AVPlayerItemStatusUnknown");
            }
                break;
            case AVPlayerItemStatusFailed:
            {
                NSLog(@"AVPlayerItemStatusFailed");
                NSLog(@"%@",_item.error);
                [self clearPlayer];
            }
                break;
                
            default:
                break;
        }
    }/* else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
      
      }*/ else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
          //        [self.activityView startAnimating];
      }
}

#pragma mark - 添加 监控
/** 给player 添加 time observer */
- (void)addPlayerObserver
{
    __weak typeof(self)weakSelf = self;
    _timeObser = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        AVPlayerItem *playerItem = weakSelf.player.currentItem;
        
        float current = CMTimeGetSeconds(time);
        
        float total = CMTimeGetSeconds([playerItem duration]);
        
        NSLog(@"当前播放进度 %.2f/%.2f.",current,total);
        if (weakSelf.activityView.isAnimating && total>0.1) {
            [weakSelf.activityView stopAnimating];
        }
        
    }];
}
/** 移除 time observer */
- (void)removePlayerObserver
{
    if (_player) {
        [_player removeTimeObserver:_timeObser];
    }
}

#pragma mark - Notic
- (void)addVideoNotic {
    
    //Notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backGroundPauseMoive) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
}
- (void)removeVideoNotic {
    //
    //    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemTimeJumpedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)movieToEnd:(NSNotification *)notic {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    //    [self clearPlayer];
    self.playBt.hidden = NO;
}
- (void)becomeActive:(NSNotification *)notic {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    if (self.player) {
        [self.player play];
    }
}

- (void)backGroundPauseMoive {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    if (self.player) {
        [self.player pause];
    }
}


-(void)clearPlayer{
    
    self.playBt.hidden = NO;

    [self.activityView stopAnimating];
    
    [self removeVideoNotic];
    if (self.item) {
        [self removeVideoKVO];
    }
    self.item = nil;
    [self removePlayerObserver];
    self.player = nil;
    if (self.playerLayer) {
        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;
    }
    //    self.imageView.hidden = NO;
}

-(void)dealloc{
    [self clearPlayer];
    NSLog(@"%s",__func__);
}
@end
