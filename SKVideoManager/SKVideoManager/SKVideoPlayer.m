//
//  SKVideoPlayer.m
//  SKVideoManager
//
//  Created by WangYu on 16/4/18.
//  Copyright © 2016年 PoloStoneK. All rights reserved.
//

#import "SKVideoPlayer.h"

@interface SKVideoPlayer ()
/** 播放器 */
@property (strong, nonatomic) AVPlayer     *videoPlayer;
/** 播放管理 */
@property (strong, nonatomic) AVPlayerItem *playerItem;
/** 当前播放时间(秒) */
@property (assign, nonatomic) CGFloat      currentPlaySeconds;
/** 播放状态 */
@property (assign, nonatomic) float        playerRate;
/** 播放进度观察者 */
@property (strong, nonatomic) id           timeObserver;

/** 转义时机block，见头文件方法内block说明 */
@property (copy, nonatomic) void(^readyToPlay)(BOOL loadVideoSucceed, float duration, NSString *durationFormatStr);
@property (copy, nonatomic) void(^play)();
@property (copy, nonatomic) void(^pause)();
@property (copy, nonatomic) void(^playbackBufferEmpty)();
@property (copy, nonatomic) void(^playbackLikelyToKeepUp)();
@property (copy, nonatomic) void(^bufferingProgress)(float totoalBuffer);
@property (copy, nonatomic) void(^playProgress)(float currentTime, float duration);
@property (copy, nonatomic) void(^playDidEnd)();
@end

@implementation SKVideoPlayer

+ (instancetype)videoPlayerWithView:(UIView *)aView videoURL:(NSString *)videoUrlStr {
    return [[self alloc] initWithView:aView videoURL:videoUrlStr];
}

- (instancetype)initWithView:(UIView *)aView videoURL:(NSString *)videoUrlStr {
    self = [super init];
    if (!self) return nil;
    
    AVPlayerItem *playerItem;
    videoUrlStr = [videoUrlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *videoUrl;
    // 网络资源
    if ([videoUrlStr containsString:@"http"]) {
        videoUrl = [NSURL URLWithString:videoUrlStr];
        playerItem = [AVPlayerItem playerItemWithURL:videoUrl];
    }else { // 本地资源
        videoUrl = [NSURL fileURLWithPath:videoUrlStr];
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
        playerItem = [AVPlayerItem playerItemWithAsset:asset];
    }
    _playerItem = playerItem;
    
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    _videoPlayer = player;
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    playerLayer.frame = aView.bounds;
    playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    [aView.layer addSublayer:playerLayer];
    
    // AVPlayer播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    // 监听播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // 监听loadedTimeRanges属性，获取缓存进度的范围
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    // 缓存进度为空
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    // 缓存准备就绪，可以继续播放
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    // 监听播放进度
    [self addPeriodicTimeObserver:playerItem];
    
    _playerRate = 1.0;
    return self;
}

/** 播放/暂停 */
- (void)playPause {
    if (_videoPlayer.rate == 0.0) { // 0.0: stopped
        [_videoPlayer play];
        self.play();
    }else if (_videoPlayer.rate == 1.0) { // 1.0: play at the natural rate of the current item
        [_videoPlayer pause];
        self.pause();
    }
}

/**
 *  播放完了
 *
 *  @param notification 通知
 */
- (void)moviePlayDidEnd:(NSNotification *)notification {
    _playerRate = 1.0;
    [self seekToTime:0];
    self.playDidEnd();
}

// 让视频加载到某个时间点
- (void)seekToTime:(CGFloat)seconds {
    [_videoPlayer pause];
    CMTime currentCMTime = CMTimeMake(seconds, 1);
    [_videoPlayer seekToTime:currentCMTime completionHandler:^(BOOL finished) {
        if (seconds != 0) {
            [_videoPlayer play];
        }
    }];
}

/** 快进seconds秒 */
- (void)fastForward:(CGFloat)seconds {
    seconds += _currentPlaySeconds;
    [self seekToTime:seconds];
}

/** 加速播放 */
- (void)playFastForward {
    
    _playerRate += 0.1;
    if (_playerRate > 2.0) return;
    if (!self.videoPlayer.currentItem.canPlayFastForward) return;
    self.videoPlayer.rate = _playerRate; // 快速播放
    NSLog(@"rate ---------- %f", _playerRate);
}

/** 减速播放 */
- (void)playSlowForward {
    _playerRate -= 0.1;
    if (_playerRate < 0.1) return;
    if (!self.videoPlayer.currentItem.canPlaySlowForward) return;
    self.videoPlayer.rate = _playerRate; // 慢速播放
    NSLog(@"rate ---------- %f", _playerRate);
}

/** 回到正常播放速度 */
- (void)returnToNormalPlaySpeed {
    self.videoPlayer.rate = 1.0;
}

/** 后退seconds秒 */
- (void)rewind:(CGFloat)seconds {
    seconds = _currentPlaySeconds - seconds;
    if (seconds < 0) {
        seconds = 1;
    }
    [self seekToTime:seconds];
}

/** 停止 */
- (void)stop {
    
    _playerRate = 1.0;
    [self seekToTime:0.0];
}

/** 播放进度监听 */
-(void)addPeriodicTimeObserver:(AVPlayerItem *)currentItem {
    
    [_videoPlayer removeTimeObserver:_timeObserver];
    NSLog(@"********************");
    __weak typeof(self) weakSelf = self;
    _timeObserver = [_videoPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        float currentTime = CMTimeGetSeconds(time);
        _currentPlaySeconds = currentTime;
        float totalDuration = CMTimeGetSeconds([currentItem duration]);
        if (currentTime) {
            CGFloat progress = currentTime / totalDuration;
            NSLog(@"currentTime:%.2f, progress:%.2f, totalDuration:%.2f", currentTime, progress, totalDuration);
            weakSelf.playProgress(currentTime, totalDuration);
        }
    }];
}

/** KVO监听 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    __weak typeof(self) weakSelf = self;
    
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] integerValue];
        if(status == AVPlayerStatusReadyToPlay){
            float duration = CMTimeGetSeconds(playerItem.duration);
            NSString *timeFormat = [self timeFormatted:duration];
            NSLog(@"ready to play video");
            weakSelf.readyToPlay(YES, duration, timeFormat);
        }else {
            NSLog(@"failed to load video");
            weakSelf.readyToPlay(NO, -1, nil);
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        float totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        NSLog(@"load progress:%.2f", totalBuffer);
        weakSelf.bufferingProgress(totalBuffer);
        
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        
        // 当缓冲是空的时候
        if (self.playerItem.playbackBufferEmpty) {
            weakSelf.playbackBufferEmpty();
        }
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        
        // 当缓冲好的时候
        if (self.playerItem.playbackLikelyToKeepUp){
            weakSelf.playbackLikelyToKeepUp();
        }
    }
}

/** 转换秒为时分秒格式 */
- (NSString *)timeFormatted:(int)totalSeconds {
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
}

// 见头文件
- (void)videoPlayerDidReadyToPlay:(void(^)(BOOL loadVideoSucceed, float duration, NSString *durationFormatStr))ready
                             play:(void(^)())play
                            pause:(void(^)())pause
              playbackBufferEmpty:(void(^)())bufferEmpty
           playbackLikelyToKeepUp:(void(^)())keepUp
                bufferingProgress:(void(^)(float totoalBuffer))bufferingProgress
                     playProgress:(void(^)(float currentTime, float duration))playProgress
                       playDidEnd:(void(^)())playDidEnd {
    _readyToPlay = ready;
    _play = play;
    _pause = pause;
    _playbackBufferEmpty = bufferEmpty;
    _playbackLikelyToKeepUp = keepUp;
    _bufferingProgress = bufferingProgress;
    _playProgress = playProgress;
    _playDidEnd = playDidEnd;
}

- (void)destroy {
    [_videoPlayer pause];
    [_videoPlayer removeTimeObserver:_timeObserver];
    _timeObserver = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_videoPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    [_videoPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_videoPlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_videoPlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [_videoPlayer replaceCurrentItemWithPlayerItem:nil];
    _playerItem = nil;
    _videoPlayer = nil;
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
    
}

@end
