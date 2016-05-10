//
//  PlayerViewController.m
//  SKVideoManager
//
//  Created by WangYu on 16/4/19.
//  Copyright © 2016年 PoloStoneK. All rights reserved.
//

#import "PlayerViewController.h"
#import "SKVideoPlayer.h"

@interface PlayerViewController ()
@property (strong, nonatomic) SKVideoPlayer *player;
@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    [self addInteractiveButtons];
    
    // 创建播放view
    UIView *recordView = [UIView new];
    recordView.frame = CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.width - 30 - 44);
    [self.view addSubview:recordView];
    
    // 创建播放器
    NSString *outputURL = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"record.mp4"];
    SKVideoPlayer *player = [SKVideoPlayer videoPlayerWithView:recordView videoURL:outputURL];
    _player = player;
    // 回调播放时机
    [player videoPlayerDidReadyToPlay:^(BOOL loadVideoSucceed, float duration, NSString *durationFormatStr) {
        NSLog(@"----loadVideoSucceed:%d----duration:%.2f---Str:%@", loadVideoSucceed, duration, durationFormatStr);
        if (loadVideoSucceed) {
            [_player play];
        }
    } play:^{
        NSLog(@"----play----");
    } pause:^{
        NSLog(@"----pause----");
    } playbackBufferEmpty:^{
        NSLog(@"----playbackBufferEmpty----");
    } playbackLikelyToKeepUp:^{
        NSLog(@"----playbackLikelyToKeepUp----");
    } bufferingProgress:^(float totoalBuffer) {
        NSLog(@"----bufferingProgress----totalBuffer:%.2f", totoalBuffer);
    } playProgress:^(float currentTime, float duration) {
        NSLog(@"----playProgress----currentTime:%.2f----duration:%.2f", currentTime, duration);
    } playDidEnd:^{
        NSLog(@"----playDidEnd----");
    }];
}

// 交互按钮事件
- (void)interactiveBtnClick:(UIButton *)sender {
    switch (sender.tag) {
        case 0:
            [_player play];
            break;
        case 1:
            [_player pause];
            break;
        case 2:
            [_player stop];
            break;
        case 3:
            [_player fastForward:3];
            break;
        case 4:
            [_player rewind:3];
            break;
        case 5:
            [_player playFastForward];
            break;
        case 6:
            [_player playSlowForward];
            break;
        case 7:
            [_player returnToNormalPlaySpeed];
            break;
    }
}

// 创建交互按钮
- (void)addInteractiveButtons {
    UIButton *didmissBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    didmissBtn.frame = CGRectMake(0, self.view.frame.size.height - 50, self.view.frame.size.width, 50);
    [didmissBtn setTitle:@"退出播放" forState:UIControlStateNormal];
    didmissBtn.backgroundColor = [UIColor orangeColor];
    [didmissBtn addTarget:self action:@selector(dismissVc:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:didmissBtn];
    
    NSArray *titlesArr = @[@"播", @"暂", @"停", @"进3s", @"退3s", @"速+", @"速-", @"正"];
    CGFloat w = self.view.frame.size.width / titlesArr.count;
    for (NSInteger i = 0; i < titlesArr.count; i++) {
        UIButton *btn = [UIButton new];
        btn.frame = CGRectMake(i * w, self.view.frame.size.height - 30 - 20 - 40, w, 40);
        [btn setTitle:titlesArr[i] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor colorWithRed:(arc4random() % 200) / 255.0 green:(arc4random() % 200) / 255.0 blue:(arc4random() % 200) / 255.0 alpha:1];
        btn.tag = i;
        [btn addTarget:self action:@selector(interactiveBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
}

// 退出
- (void)dismissVc:(UIButton *)sender {
    [_player destroy];
    _player = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

@end
