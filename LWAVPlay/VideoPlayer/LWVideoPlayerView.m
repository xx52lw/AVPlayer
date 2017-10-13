//
//  XLVideoPlayer.m
//  XLVideoPlayer
//
//  Created by LW on 16/3/23.
//  Copyright © 2017年 GreatGate. All rights reserved.
//

#import "LWVideoPlayerView.h"
#import <AVFoundation/AVFoundation.h>

static CGFloat const barAnimateSpeed = 0.5f;
static CGFloat const barShowDuration = 5.0f;
static CGFloat const opacity = 0.7f;
static CGFloat const bottomBaHeight = 40.0f;
static CGFloat const playBtnSideLength = 60.0f;
// ====================================================================================================================================
#pragma mark 自定义视屏播放视图
@interface LWVideoPlayerView ()

/** 父视图 */
@property (nonatomic, strong) UIView *playSuprView;
/** 底部功能条 */
@property (nonatomic, strong) UIView *bottomBar;
/** 暂停或者播放按钮 */
@property (nonatomic, strong) UIButton *playOrPauseBtn;
/** 播放总时间标签 */
@property (nonatomic, strong) UILabel *totalDurationLabel;
/** 播放进度时间标签 */
@property (nonatomic, strong) UILabel *progressLabel;
/** 视图窗口 */
@property (nonatomic, strong) UIWindow *keyWindow;
/** 加载视图 */
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
/** 播放的原始尺寸 */
@property (nonatomic, assign) CGRect playerOriginalFrame;
/** 缩放按钮 */
@property (nonatomic, strong) UIButton *zoomScreenBtn;
/** 播放项 */
@property (nonatomic, strong) AVPlayerItem *playerItem;
/** 播放图层 */
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
/** 播放层 */
@property (nonatomic,strong) AVPlayer *player;
/** 播放总时间 */
@property (nonatomic, assign) CGFloat totalDuration;
/** 播放进度时间 */
@property (nonatomic, assign) CGFloat current;
@property (nonatomic, strong) UITableView *bindTableView;
@property (nonatomic, assign) CGRect currentPlayCellRect;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;

/** 是否原始尺寸 */
@property (nonatomic, assign) BOOL isOriginalFrame;
/** 是否全屏 */
@property (nonatomic, assign) BOOL isFullScreen;
/** 是否隐藏底部工具条 */
@property (nonatomic, assign) BOOL barHiden;
/** 是否操作 */
@property (nonatomic, assign) BOOL inOperation;
/** 是否最小屏播放 */
@property (nonatomic, assign) BOOL smallWinPlaying;

@end
// ====================================================================================================================================
#pragma mark 自定义视屏播放视图
@implementation LWVideoPlayerView

#pragma mark - public method

- (UIWindow *)keyWindow {
    return [UIApplication sharedApplication].keyWindow;
}

- (instancetype)init {
    if (self = [super init]) {
        
        self.backgroundColor = [UIColor blackColor];
        
        // 添加点击手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrHidenBar)];
        [self addGestureRecognizer:tap];
        
        // 注册通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appwillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        self.barHiden = YES;
    }
    return self;
}

- (void)setVideoUrl:(NSString *)videoUrl {
    _videoUrl = videoUrl;
    [self.layer addSublayer:self.playerLayer];
    [self insertSubview:self.activityIndicatorView belowSubview:self.playOrPauseBtn];
    [self.activityIndicatorView startAnimating];
    [self playOrPause:self.playOrPauseBtn];
    [self addSubview:self.bottomBar];
    [self insertSubview:self.playOrPauseBtn aboveSubview:self.activityIndicatorView];
    
}

- (void)playPause {
    [self playOrPause:self.playOrPauseBtn];
}

- (void)destroyPlayer {
    [self.player pause];
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    [self.slider removeFromSuperview];
    self.slider = nil;
    [self removeFromSuperview];
}

- (void)playerBindTableView:(UITableView *)bindTableView currentIndexPath:(NSIndexPath *)currentIndexPath {
    self.bindTableView = bindTableView;
    self.currentIndexPath = currentIndexPath;
}

- (void)playerScrollIsSupportSmallWindowPlay:(BOOL)support {
    
    NSAssert(self.bindTableView != nil, @"必须绑定对应的tableview！！！");
    
    self.currentPlayCellRect = [self.bindTableView rectForRowAtIndexPath:self.currentIndexPath];
    self.currentIndexPath = self.currentIndexPath;
    
    CGFloat cellBottom = self.currentPlayCellRect.origin.y + self.currentPlayCellRect.size.height;
    CGFloat cellUp = self.currentPlayCellRect.origin.y;
    
    if (self.bindTableView.contentOffset.y > cellBottom) {
        if (!support) {
            [self destroyPlayer];
            return;
        }
        [self smallWindowPlay];
        return;
    }
    
    if (cellUp > self.bindTableView.contentOffset.y + self.bindTableView.frame.size.height) {
        if (!support) {
            [self destroyPlayer];
            return;
        }
        [self smallWindowPlay];
        return;
    }
    
    if (self.bindTableView.contentOffset.y < cellBottom){
        if (!support) return;
        [self returnToOriginView];
        return;
    }
    
    if (cellUp < self.bindTableView.contentOffset.y + self.bindTableView.frame.size.height){
        if (!support) return;
        [self returnToOriginView];
        return;
    }
}

#pragma mark - 重写layoutSubviews

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
    if (!self.isOriginalFrame) {
        self.playerOriginalFrame = self.frame;
        self.playSuprView = self.superview;
        self.bottomBar.frame = CGRectMake(0, self.playerOriginalFrame.size.height - bottomBaHeight, self.self.playerOriginalFrame.size.width, bottomBaHeight);
        self.playOrPauseBtn.frame = CGRectMake((self.playerOriginalFrame.size.width - playBtnSideLength) / 2, (self.playerOriginalFrame.size.height - playBtnSideLength) / 2, playBtnSideLength, playBtnSideLength);
        self.activityIndicatorView.center = CGPointMake(self.playerOriginalFrame.size.width / 2, self.playerOriginalFrame.size.height / 2);
        self.isOriginalFrame = YES;
    }
}
#pragma mark - dealloc
- (void)dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    NSLog(@"video player - dealloc");
}
#pragma mark 设置状态条隐藏
- (void)setStatusBarHidden:(BOOL)hidden {
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    statusBar.hidden = hidden;
}

#pragma mark 全屏按钮点击
- (void)actionFullScreen {
    if (!self.isFullScreen) {
        [self orientationFullScreen];
    }else {
        [self smallScreen];
    }
}
#pragma mark 全屏
- (void)orientationFullScreen {
    self.isFullScreen = YES;
    self.zoomScreenBtn.selected = YES;
    [self.keyWindow addSubview:self];
    
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationLandscapeLeft] forKey:@"orientation"];
    [self updateConstraintsIfNeeded];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.transform = CGAffineTransformMakeRotation(M_PI / 2);
        self.frame = self.keyWindow.bounds;
        self.bottomBar.frame = CGRectMake(0, self.keyWindow.bounds.size.width - bottomBaHeight, self.keyWindow.bounds.size.height, bottomBaHeight);
        self.playOrPauseBtn.frame = CGRectMake((self.keyWindow.bounds.size.height - playBtnSideLength) / 2, (self.keyWindow.bounds.size.width - playBtnSideLength) / 2, playBtnSideLength, playBtnSideLength);
        self.activityIndicatorView.center = CGPointMake(self.keyWindow.bounds.size.height / 2, self.keyWindow.bounds.size.width / 2);
    }];
    
    [self setStatusBarHidden:YES];
}
#pragma mark 小屏
- (void)smallScreen {
    self.isFullScreen = NO;
    self.zoomScreenBtn.selected = NO;
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
   
    if (self.bindTableView) {
        UITableViewCell *cell = [self.bindTableView cellForRowAtIndexPath:self.currentIndexPath];
        [cell.contentView addSubview:self];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.transform = CGAffineTransformMakeRotation(0);
        self.frame = self.playerOriginalFrame;
        self.bottomBar.frame = CGRectMake(0, self.playerOriginalFrame.size.height - bottomBaHeight, self.self.playerOriginalFrame.size.width, bottomBaHeight);
        self.playOrPauseBtn.frame = CGRectMake((self.playerOriginalFrame.size.width - playBtnSideLength) / 2, (self.playerOriginalFrame.size.height - playBtnSideLength) / 2, playBtnSideLength, playBtnSideLength);
        self.activityIndicatorView.center = CGPointMake(self.playerOriginalFrame.size.width / 2, self.playerOriginalFrame.size.height / 2);
        [self updateConstraintsIfNeeded];
    }];
    [self setStatusBarHidden:NO];
}
#pragma mark 进入后台的通知
- (void)appDidEnterBackground:(NSNotification*)note {
    
    NSLog(@"appDidEnterBackground");
}
#pragma mark 进入前台的通知
- (void)appWillEnterForeground:(NSNotification*)note {
    NSLog(@"appWillEnterForeground");
}
#pragma mark 进入挂起的通知
- (void)appwillResignActive:(NSNotification *)note {
    NSLog(@"appwillResignActive");
    [self playOrPause:self.playOrPauseBtn];
}
#pragma mark 进入活跃的通知
- (void)appBecomeActive:(NSNotification *)note {
    [self playOrPause:self.playOrPauseBtn];
}
#pragma mark 播放或者暂停
- (void)playOrPause:(UIButton *)btn {
    if(self.player.rate == 0.0){      // 暂停
        btn.selected = YES;
        [self.player play];
    }else if(self.player.rate == 1.0f){    // 播放
        [self.player pause];
        btn.selected = NO;
    }
}

- (void)showOrHidenBar {
    if (self.barHiden) {
        [self show];
    }else {
        [self hiden];
    }
}

- (void)show {
    [UIView animateWithDuration:barAnimateSpeed animations:^{
        self.bottomBar.layer.opacity = opacity;
        self.playOrPauseBtn.layer.opacity = opacity;
    } completion:^(BOOL finished) {
        if (finished) {
            self.barHiden = !self.barHiden;
            [self performBlock:^{
                if (!self.barHiden && !self.inOperation) {
                    [self hiden];
                }
            } afterDelay:barShowDuration];
        }
    }];
}

- (void)hiden {
    self.inOperation = NO;
    [UIView animateWithDuration:barAnimateSpeed animations:^{
        self.bottomBar.layer.opacity = 0.0f;
        self.playOrPauseBtn.layer.opacity = 0.0f;
    } completion:^(BOOL finished){
        if (finished) {
            self.barHiden = !self.barHiden;
        }
    }];
}

#pragma mark 监听滑尺滑动
- (void)sliderValueChange:(LWSlider *)slider {
    self.progressLabel.text = [self timeFormatted:slider.value * self.totalDuration];
}
#pragma mark 滑尺滑完
- (void)finishChange {
    self.inOperation = NO;
    [self performBlock:^{
        if (!self.barHiden && !self.inOperation) {
            [self hiden];
        }
    } afterDelay:barShowDuration];
    
    [self.player pause];
    
    CMTime currentCMTime = CMTimeMake(self.slider.value * self.totalDuration, 1);
    if (self.slider.middleValue) {
        [self.player seekToTime:currentCMTime completionHandler:^(BOOL finished) {
            [self.player play];
            self.playOrPauseBtn.selected = YES;
        }];
    }
}

#pragma mark 拖拽滑尺
- (void)dragSlider {
    self.inOperation = YES;
    [self.player pause];
}
// 执行延后
- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay {
    [self performSelector:@selector(callBlockAfterDelay:) withObject:block afterDelay:delay];
}

- (void)callBlockAfterDelay:(void (^)(void))block {
    block();
}
#pragma mark 添加播放进度监听
-(void)addProgressObserver{

    AVPlayerItem *playerItem = self.player.currentItem;
    __weak typeof(self) weakSelf = self;

    [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1f, NSEC_PER_SEC)  queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        float current = CMTimeGetSeconds(time); // 播放进度
        weakSelf.current = current;
        float total = CMTimeGetSeconds([playerItem duration]); // 总时间
        weakSelf.progressLabel.text = [weakSelf timeFormatted:current];
        if (current) {
            if (!weakSelf.inOperation) {
                 weakSelf.slider.value = current / total;
            }
            if (weakSelf.slider.value == 1.0f) {      // 播放完成
                if (weakSelf.completedPlayingBlock) {
                    [weakSelf setStatusBarHidden:NO];
                    if ( weakSelf.completedPlayingBlock) {
                        weakSelf.completedPlayingBlock(weakSelf);
                    }
                    weakSelf.completedPlayingBlock = nil;
                }else {       //finish and loop playback
                    weakSelf.playOrPauseBtn.selected = NO;
                    [weakSelf showOrHidenBar];
                    CMTime currentCMTime = CMTimeMake(0, 1);
                    [weakSelf.player seekToTime:currentCMTime completionHandler:^(BOOL finished) {
                        weakSelf.slider.value = 0.0f;
                    }];
                }
            }
        }
    }];
}

#pragma mark 播放项添加监听
-(void)addObserverToPlayerItem:(AVPlayerItem *)playerItem{
    
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // 网络加载进度
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark 通过KVO监控播放器状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        if(status == AVPlayerStatusReadyToPlay){
            self.totalDuration = CMTimeGetSeconds(playerItem.duration);
            self.totalDurationLabel.text = [self timeFormatted:self.totalDuration];
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        self.slider.middleValue = totalBuffer / CMTimeGetSeconds(playerItem.duration);
        if (self.slider.middleValue  <= self.slider.value || (totalBuffer - 1.0) < self.current) {
            NSLog(@"正在缓冲...");
            self.activityIndicatorView.hidden = NO;
            [self.activityIndicatorView startAnimating];
        }else {
            self.activityIndicatorView.hidden = YES;
            if (self.playOrPauseBtn.selected) {
                [self.player play];
            }
        }
    }
}
#pragma mark 格式化时间
- (NSString *)timeFormatted:(int)totalSeconds {
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
}

#pragma mark - animation smallWindowPlay

- (void)smallWindowPlay {
    if ([self.superview isKindOfClass:[UIWindow class]]) return;
    self.smallWinPlaying = YES;
    self.playOrPauseBtn.hidden = YES;
    self.bottomBar.hidden = YES;
    
    CGRect tableViewframe = [self.bindTableView convertRect:self.bindTableView.bounds toView:self.keyWindow];
    self.frame = [self convertRect:self.frame toView:self.keyWindow];
    [self.keyWindow addSubview:self];
    
    [UIView animateWithDuration:0.3 animations:^{
        
        CGFloat w = self.playerOriginalFrame.size.width * 0.5;
        CGFloat h = self.playerOriginalFrame.size.height * 0.5;
        CGRect smallFrame = CGRectMake(tableViewframe.origin.x + tableViewframe.size.width - w, tableViewframe.origin.y + tableViewframe.size.height - h, w, h);
        self.frame = smallFrame;
        self.playerLayer.frame = self.bounds;
        self.activityIndicatorView.center = CGPointMake(w / 2.0, h / 2.0);
    }];
}

- (void)returnToOriginView {
    if (![self.superview isKindOfClass:[UIWindow class]]) return;
    self.smallWinPlaying = NO;
    self.playOrPauseBtn.hidden = NO;
    self.bottomBar.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        
        self.frame = CGRectMake(self.currentPlayCellRect.origin.x, self.currentPlayCellRect.origin.y, self.playerOriginalFrame.size.width, self.playerOriginalFrame.size.height);
        self.playerLayer.frame = self.bounds;
        self.activityIndicatorView.center = CGPointMake(self.playerOriginalFrame.size.width / 2, self.playerOriginalFrame.size.height / 2);
    } completion:^(BOOL finished) {
        self.frame = self.playerOriginalFrame;
        UITableViewCell *cell = [self.bindTableView cellForRowAtIndexPath:self.currentIndexPath];
        [cell.contentView addSubview:self];
    }];
}

#pragma mark - lazy loading

- (AVPlayerLayer *)playerLayer {
    if (!_playerLayer) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        _playerLayer.backgroundColor = [UIColor blackColor].CGColor;
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;//视频填充模式
    }
    return _playerLayer;
}

- (AVPlayer *)player{
    if (!_player) {
        AVPlayerItem *playerItem = [self getAVPlayItem];
        self.playerItem = playerItem;
        _player = [AVPlayer playerWithPlayerItem:playerItem];
        
        [self addProgressObserver];
        
        [self addObserverToPlayerItem:playerItem];
        
        // 解决8.1系统播放无声音问题，8.0、9.0以上未发现此问题
        AVAudioSession * session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        [session setActive:YES error:nil];
    }
    return _player;
}

//initialize AVPlayerItem
- (AVPlayerItem *)getAVPlayItem{
    
    if ([self.videoUrl rangeOfString:@"http"].location != NSNotFound) {
        AVPlayerItem *playerItem=[AVPlayerItem playerItemWithURL:[NSURL URLWithString:[self.videoUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        return playerItem;
    }else{
        AVAsset *movieAsset  = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:self.videoUrl] options:nil];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        return playerItem;
    }
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self insertSubview:_activityIndicatorView aboveSubview:self.playOrPauseBtn];

    }
    return _activityIndicatorView;
}

- (UIView *)bottomBar {
    if (!_bottomBar) {
        _bottomBar = [[UIView alloc] init];
        _bottomBar.backgroundColor = [UIColor blackColor];
        _bottomBar.layer.opacity = 0.0f;
        
        UILabel *label1 = [[UILabel alloc] init];
        label1.translatesAutoresizingMaskIntoConstraints = NO;
        label1.textAlignment = NSTextAlignmentCenter;
        label1.text = @"00:00:00";
        label1.font = [UIFont systemFontOfSize:12.0f];
        label1.textColor = [UIColor whiteColor];
        [_bottomBar addSubview:label1];
        self.progressLabel = label1;
        
        NSLayoutConstraint *label1Left = [NSLayoutConstraint constraintWithItem:label1 attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_bottomBar attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0];
        NSLayoutConstraint *label1Top = [NSLayoutConstraint constraintWithItem:label1 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_bottomBar attribute:NSLayoutAttributeTop multiplier:1.0f constant:0];
        NSLayoutConstraint *label1Bottom = [NSLayoutConstraint constraintWithItem:label1 attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_bottomBar attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0];
        NSLayoutConstraint *label1Width = [NSLayoutConstraint constraintWithItem:label1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0f constant:65.0f];
        [_bottomBar addConstraints:@[label1Left, label1Top, label1Bottom, label1Width]];
        
        
        UIButton *fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        fullScreenBtn.translatesAutoresizingMaskIntoConstraints = NO;
        fullScreenBtn.contentMode = UIViewContentModeCenter;
        [fullScreenBtn setImage:[UIImage imageNamed:@"ImageResources.bundle/btn_zoom_out"] forState:UIControlStateNormal];
        [fullScreenBtn setImage:[UIImage imageNamed:@"ImageResources.bundle/btn_zoom_in"] forState:UIControlStateSelected];
        [fullScreenBtn addTarget:self action:@selector(actionFullScreen) forControlEvents:UIControlEventTouchDown];
        [_bottomBar addSubview:fullScreenBtn];
        self.zoomScreenBtn = fullScreenBtn;
        
        NSLayoutConstraint *btnWidth = [NSLayoutConstraint constraintWithItem:fullScreenBtn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0f constant:40.0f];
        NSLayoutConstraint *btnHeight = [NSLayoutConstraint constraintWithItem:fullScreenBtn attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0f constant:40.0f];
        NSLayoutConstraint *btnRight = [NSLayoutConstraint constraintWithItem:fullScreenBtn attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_bottomBar attribute:NSLayoutAttributeRight multiplier:1.0f constant:0];
        NSLayoutConstraint *btnCenterY = [NSLayoutConstraint constraintWithItem:fullScreenBtn attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_bottomBar attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0];
        [_bottomBar addConstraints:@[btnWidth, btnHeight, btnRight, btnCenterY]];
        
        
        UILabel *label2 = [[UILabel alloc] init];
        label2.translatesAutoresizingMaskIntoConstraints = NO;
        label2.textAlignment = NSTextAlignmentCenter;
        label2.text = @"00:00:00";
        label2.font = [UIFont systemFontOfSize:12.0f];
        label2.textColor = [UIColor whiteColor];
        [_bottomBar addSubview:label2];
        self.totalDurationLabel = label2;
        
        NSLayoutConstraint *label2Right = [NSLayoutConstraint constraintWithItem:label2 attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:fullScreenBtn attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0];
        NSLayoutConstraint *label2Top = [NSLayoutConstraint constraintWithItem:label2 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_bottomBar attribute:NSLayoutAttributeTop multiplier:1.0f constant:0];
        NSLayoutConstraint *label2Bottom = [NSLayoutConstraint constraintWithItem:label2 attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_bottomBar attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0];
        NSLayoutConstraint *label2Width = [NSLayoutConstraint constraintWithItem:label2 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0f constant:65.0f];
        [_bottomBar addConstraints:@[label2Right, label2Top, label2Bottom, label2Width]];
        
        LWSlider *slider = [[LWSlider alloc] init];
        slider.value = 0.0f;
        slider.middleValue = 0.0f;
        slider.translatesAutoresizingMaskIntoConstraints = NO;
        [_bottomBar addSubview:slider];
        self.slider = slider;
        __weak typeof(self) weakSelf = self;
        slider.valueChangeBlock = ^(LWSlider *slider){
            [weakSelf sliderValueChange:slider];
        };
        slider.finishChangeBlock = ^(LWSlider *slider){
            [weakSelf finishChange];
        };
        slider.draggingSliderBlock = ^(LWSlider *slider){
            [weakSelf dragSlider];
        };
        
        NSLayoutConstraint *sliderLeft = [NSLayoutConstraint constraintWithItem:slider attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:label1 attribute:NSLayoutAttributeRight multiplier:1.0f constant:0];
        sliderLeft.priority = UILayoutPriorityDefaultLow;
        NSLayoutConstraint *sliderRight = [NSLayoutConstraint constraintWithItem:slider attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:label2 attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0];
        NSLayoutConstraint *sliderTop = [NSLayoutConstraint constraintWithItem:slider attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_bottomBar attribute:NSLayoutAttributeTop multiplier:1.0f constant:0];
        NSLayoutConstraint *sliderBottom = [NSLayoutConstraint constraintWithItem:slider attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_bottomBar attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0];
        [_bottomBar addConstraints:@[sliderLeft, sliderRight, sliderTop, sliderBottom]];
        
        [self updateConstraintsIfNeeded];
    }
    return _bottomBar;
}

- (UIButton *)playOrPauseBtn {
    if (!_playOrPauseBtn) {
        _playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playOrPauseBtn.layer.opacity = 0.0f;
        _playOrPauseBtn.contentMode = UIViewContentModeCenter;
        [_playOrPauseBtn setBackgroundImage:[UIImage imageNamed:@"ImageResources.bundle/play"] forState:UIControlStateNormal];
        [_playOrPauseBtn setBackgroundImage:[UIImage imageNamed:@"ImageResources.bundle/pause"] forState:UIControlStateSelected];
        [_playOrPauseBtn addTarget:self action:@selector(playOrPause:) forControlEvents:UIControlEventTouchDown];
    }
    return _playOrPauseBtn;
}



@end
// ====================================================================================================================================
