//
//  ViewController.m
//  LWAVPlay
//
//  Created by liwei on 202017
//  Copyright © 2017年 LW. All rights reserved.
//

#import "ViewController.h"
#import "LWVideoPlayerView.h"
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) LWVideoPlayerView * player;

@property (nonatomic,strong) UITableView * tableView;


@end

@implementation ViewController

- (LWVideoPlayerView *)player {
    if (!_player) {
        [_player destroyPlayer];
        _player = [[LWVideoPlayerView alloc] init];
        _player.frame = CGRectMake(0, 104, self.view.frame.size.width, 250);
        [self.view addSubview:_player];
    }
    return _player;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    [self.player destroyPlayer];
//    self.player = nil;
//    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
//    tableView.delegate = self;
//    tableView.dataSource = self;
//    [self.view addSubview:tableView];
//    self.tableView = tableView;
    self.player.videoUrl = @"http://flv3.bn.netease.com/videolib3/1710/12/POEXp7302/SD/POEXp7302-mobile.mp4";
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(100, 400, 100, 50);
    btn.backgroundColor = [UIColor redColor];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}
- (void)btnClick {
    [self.player destroyPlayer];
    self.player = nil;
    self.player.videoUrl = @"http://recordcdn.quklive.com/broadcast/activity/1469002576632934/20160729150422-20160729155013.m3u8";
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}


@end
