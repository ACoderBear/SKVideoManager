# SKVideoManager
A video manager with videoCapture and videoPlayer.
The 2 tools just support APIs, UI is not supported.

##Screen shoot

![图片1](http://img.blog.csdn.net/20160510175656951)
![图片2](http://img.blog.csdn.net/20160510175722756)
![图片3](http://img.blog.csdn.net/20160510175746764)

##SKVideoCapture
capture a video with default size 960x540.

###USE

``` obj-c
#import "SKVideoCapture.h"

capture = [SKVideoCapture videoCaptureWithPreviewLayerView:recordView videoGravity:AVLayerVideoGravityResizeAspect];

[capture videoCaptureDidStartRecording:^{
        NSLog(@"——————开始录制");
    } finishRecording:^{
        NSLog(@"——————结束录制");
    } recordingFailed:^{
        NSLog(@"——————录制失败");
    }];
    
    // destory
    [capture destroy];
    capture = nil;
    
```
more details check .m file

##SKVideoPlayer
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
more details check .m file

##issue
Any bugs please issue me !
3KS !
