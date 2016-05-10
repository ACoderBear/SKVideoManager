//
//  SKVideoPlayer.h
//  SKVideoManager
//
//  Created by WangYu on 16/4/18.
//  Copyright © 2016年 PoloStoneK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface SKVideoPlayer : NSObject

/**
 *  工厂方法
 *
 *  @param aView       播放视频的view
 *  @param videoUrlStr 视频URL地址
 *
 *  @return 播放器实例
 */
+ (instancetype)videoPlayerWithView:(UIView *)aView videoURL:(NSString *)videoUrlStr;

/**
 *  构造方法
 *
 *  @param aView       播放视频的view
 *  @param videoUrlStr 视频URL地址
 *
 *  @return 播放器实例
 */
- (instancetype)initWithView:(UIView *)aView videoURL:(NSString *)videoUrlStr;

/**
 *  播放器播放处理时机
 *
 *  @param ready             是否准备好播放：loadVideoSucceed：YES准备就绪，duration：视频总时长，durationFormatStr：时间字符串，如3:15表示三分十五秒五秒
 *  @param play              播放
 *  @param pause             暂停
 *  @param bufferEmpty       缓冲为空：可以在此时给播放器view添加加载动画
 *  @param keepUp            缓冲准备就绪，可以继续播放：可以在此时去掉缓冲动画继续播放视频
 *  @param bufferingProgress 缓冲进度：totoalBuffer总缓冲长度
 *  @param playProgress      播放进度：currentTime当前播放的时间，duration总时长
 *  @param playDidEnd        播放结束
 */
- (void)videoPlayerDidReadyToPlay:(void(^)(BOOL loadVideoSucceed, float duration, NSString *durationFormatStr))ready
                             play:(void(^)())play
                            pause:(void(^)())pause
              playbackBufferEmpty:(void(^)())bufferEmpty
           playbackLikelyToKeepUp:(void(^)())keepUp
                bufferingProgress:(void(^)(float totoalBuffer))bufferingProgress
                     playProgress:(void(^)(float currentTime, float duration))playProgress
                       playDidEnd:(void(^)())playDidEnd;
/** 播放/暂停 */
- (void)playPause;
/** 停止播放 */
- (void)stop;
/** 快进：传入快进秒数 */
- (void)fastForward:(CGFloat)seconds;
/** 快退：传入快退秒数 */
- (void)rewind:(CGFloat)seconds;
/** 提高播放速度：速度区间1.0~2.0，每次提高0.1 --> 当调用 playSlowForward 时会从1.0正常速度降低到1.0以下 */
- (void)playFastForward;
/** 提高播放速度：速度区间1.0~0.0，每次降低0.1 --> 当调用 playFastForward 时会从1.0正常速度提高到1.0以上 */
- (void)playSlowForward;
/** 正常速度播放 */
- (void)returnToNormalPlaySpeed;
/** 摧毁播放器：在摧毁控制器时调用，不然会导致无法释放播放器而内存泄露 */
- (void)destroy;

@end
