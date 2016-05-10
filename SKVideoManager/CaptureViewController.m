//
//  CaptureViewController.m
//  SKVideoManager
//
//  Created by WangYu on 16/4/20.
//  Copyright © 2016年 PoloStoneK. All rights reserved.
//

#import "CaptureViewController.h"
#import "PlayerViewController.h"
#import "SKVideoCapture.h"

#define degreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )

@interface CaptureViewController ()
@property (strong, nonatomic) SKVideoCapture *capture;
@end

@implementation CaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];
    
    // 创建交互按钮
    [self addInteractiveButtons];
    
    // 添加 摄制视频流 的view
    UIView *recordView = [UIView new];
    recordView.frame = CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.width - 30 - 44);
    [self.view addSubview:recordView];
    
    // 创建视频摄制对象：这里使用适应全屏录制，方面播放时查看裁剪效果
    SKVideoCapture *capture = [SKVideoCapture videoCaptureWithPreviewLayerView:recordView videoGravity:AVLayerVideoGravityResizeAspect];
    _capture = capture;
    
    // 回调摄制时机
    [capture videoCaptureDidStartRecording:^{
        NSLog(@"——————开始录制");
    } finishRecording:^{
        NSLog(@"——————结束录制");
    } recordingFailed:^{
        NSLog(@"——————录制失败");
    }];
}

// 按钮事件
- (void)interactiveBtnClick:(UIButton *)sender {
    static BOOL openTorch;
    openTorch = !openTorch;
    switch (sender.tag) {
        case 0: // 开始录制
            [_capture startRecordingToOutputFileUrl:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"record.mp4"] writeVideoToPhotoLibrary:YES];
            break;
        case 1: // 停止录制
            [_capture stopRecording];
            break;
        case 2: // 手电筒
            [_capture openTorch:openTorch];
            break;
        case 3: // 切换摄像头
            [_capture switchCamera];
            break;
    }
}

// 创建交互按钮
- (void)addInteractiveButtons {
    UIButton *presentBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    presentBtn.frame = CGRectMake(0, self.view.frame.size.height - 50, self.view.frame.size.width, 50);
    [presentBtn setTitle:@"播放视频" forState:UIControlStateNormal];
    presentBtn.backgroundColor = [UIColor orangeColor];
    [presentBtn addTarget:self action:@selector(gotoPlayerVc:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:presentBtn];
    
    NSArray *titlesArr = @[@"开始录制", @"停止录制", @"手电筒", @"摄像头"];
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
    
    UIButton *dismissBtn = [UIButton new];
    dismissBtn.frame = CGRectMake(0, presentBtn.frame.origin.y - 40 - 50, self.view.frame.size.width, 50);
    [dismissBtn setTitle:@"退出" forState:UIControlStateNormal];
    dismissBtn.backgroundColor = [UIColor orangeColor];
    [dismissBtn addTarget:self action:@selector(dismissVc) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dismissBtn];
}

- (void)dismissVc {
    [_capture destroy];
    _capture = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 播放视频(务必在视频录制完毕时机回调完毕后跳转页面)
- (void)gotoPlayerVc:(UIButton *)sender {
    PlayerViewController *playerVc = [[PlayerViewController alloc] init];
    [self presentViewController:playerVc animated:YES completion:nil];
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

@end