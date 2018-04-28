//
//  KKVideoPlayer.h
//  PoPo
//
//  Created by 聚智在线 on 2018/3/1.
//  Copyright © 2018年 JZZX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol KKVideoPlayerDelegate <NSObject>

@end


@interface KKVideoPlayer : NSObject

-(void)setupPlayerWithPlayView:(UIView*)playView delegate:(id<KKVideoPlayerDelegate>)delegate url:(NSURL*)url;

-(void)pause;

@end
