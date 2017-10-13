//
//  LWVideoPlayer.h
//  LWVideoPlayer
//
//  Created by LW on 16/3/23.
//  Copyright © 2017年 GreatGate. All rights reserved.
//  

#import <UIKit/UIKit.h>
#import "LWSlider.h"
@class LWVideoPlayerView;
// ====================================================================================================================================
#pragma mark 自定义block属性
typedef void (^VideoCompletedPlayingBlock) (LWVideoPlayerView *videoPlayer);
// ====================================================================================================================================
#pragma mark 自定义视屏播放视图
@interface LWVideoPlayerView : UIView

/** 滑尺 */
@property (nonatomic, strong) LWSlider *slider;
/** 播放完成的block */
@property (nonatomic, copy) VideoCompletedPlayingBlock completedPlayingBlock;
/** 播放视屏的url */
@property (nonatomic, strong) NSString *videoUrl;
/** 视屏暂停播放 */
- (void)playPause;
/** 销毁 */
- (void)destroyPlayer;

/** 在cell上播放必须绑定TableView、当前播放cell的IndexPath */
- (void)playerBindTableView:(UITableView *)bindTableView currentIndexPath:(NSIndexPath *)currentIndexPath;

/**
 *  在scrollview的scrollViewDidScroll代理中调用
 *
 *  @param support        是否支持右下角小窗悬停播放
 */
- (void)playerScrollIsSupportSmallWindowPlay:(BOOL)support;

@end
// ====================================================================================================================================
