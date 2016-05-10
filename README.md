# SKVideoManager
自定义的一个以AVFoundation框架类为基础的视频管理者

A video manager with SKVideoCapture and SKVideoPlayer.
The 2 tools just support APIs, UI is not supported.
>包含一个拍摄和一个播放的工具，工具只提供API处理视频的各类事件，不提供UI，使用者可以自由的定制UI。此工具提供了Block回调，一次性提供所有需要的时机，只需要在Block中处理逻辑即可。



##Demo Screen shoot
Demo截图

![图片1](http://img.blog.csdn.net/20160510175656951) ![图片2](http://img.blog.csdn.net/20160510175722756) ![图片3](http://img.blog.csdn.net/20160510175746764)

##SKVideoCapture
摄录工具默认抓去960x540尺寸的视频，相当于拍摄的视频宽度不变，高度以16:9的比例截取中间部分得到的视频。

capture a video with default size 960x540.

###USE 使用

``` obj-c
#import "SKVideoCapture.h"

capture = [SKVideoCapture videoCaptureWithPreviewLayerView:recordView videoGravity:AVLayerVideoGravityResizeAspect];

[capture videoCaptureDidStartRecording:^{
        NSLog(@"——————startRecording");
    } finishRecording:^{
        NSLog(@"——————endRecording");
    } recordingFailed:^{
        NSLog(@"——————recordingFailed");
    }];
    
    // destory
    [capture destroy];
    capture = nil;
    
```
更多细节请查看.m文件，APIs请查看.h了解

more details check SKVideoCapture.h/.m file

##SKVideoPlayer
视频播放工具

a video player

###USE

``` obj-c

#import "SKVideoPlayer.h"

player = [SKVideoPlayer videoPlayerWithView:recordView videoURL:outputURL];

[player videoPlayerDidReadyToPlay:^(BOOL loadVideoSucceed, float duration, NSString *durationFormatStr) {
        NSLog(@"----loadVideoSucceed:%d----duration:%.2f---Str:%@", loadVideoSucceed, duration, durationFormatStr);
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
    
    // destory
    [player destroy];
    player = nil;
    
```
更多细节请查看.m文件，APIs请查看.h了解

more details check SKVideoCapture.h/.m file

##issue
如发现BUG或者有新需求，请告知我，谢谢！

Any bugs please issue me !
3KS !