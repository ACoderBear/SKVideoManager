//
//  HomeViewController.m
//  SKVideoManager
//
//  Created by WangYu on 16/5/10.
//  Copyright © 2016年 PoloStoneK. All rights reserved.
//

#import "HomeViewController.h"
#import "CaptureViewController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    UILabel *label = [UILabel new];
    label.text = @"点击进入拍摄页面";
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.frame = self.view.bounds;
    [self.view addSubview:label];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CaptureViewController *vc = [CaptureViewController new];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
