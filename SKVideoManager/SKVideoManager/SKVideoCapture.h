//
//  SKVideoCapture.h
//  SKVideoManager
//
//  Created by WangYu on 16/4/18.
//  Copyright © 2016年 PoloStoneK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface SKVideoCapture : NSObject

/** 工厂方法传入预览视频的aView创建实例 */
+ (instancetype)videoCaptureWithPreviewLayerView:(UIView *)aView videoGravity:(NSString *)videoGravity;
/** 构造方法传入预览视频的aView创建实例 */
- (instancetype)initWithPreviewLayerView:(UIView *)aView videoGravity:(NSString *)videoGravity;


/** 后置摄像头可用 */
@property (assign, nonatomic, readonly) BOOL backCameraAvailable;
/** 前置摄像头可用 */
@property (assign, nonatomic, readonly) BOOL frontCameraAvailable;


/**
 *  录制视频流时机，可在对应的时机处理事件：如开始计时录制时间等
 *
 *  @param start   录制开始
 *  @param succeed 录制结束且视频压缩完成
 *  @param failed  录制失败
 */
- (void)videoCaptureDidStartRecording:(void(^)())start finishRecording:(void(^)())succeed recordingFailed:(void(^)())failed;
/**
 *  开始摄制视频流
 *
 *  @param filePath 视频流输出路径：注意，输出格式为MP4
 *  @param write    是否输出到相册
 */
- (void)startRecordingToOutputFileUrl:(NSString *)filePath writeVideoToPhotoLibrary:(BOOL)write;
/** 停止摄制视频流 */
- (void)stopRecording;
/** 获取 前/后 摄像头 */
- (AVCaptureDevice *)cameraWithBackPosition:(BOOL)isBack;
/** 传入对焦点：点击视频view上的点 */
- (void)focusInPoint:(CGPoint)point;
/** 切换摄像头 */
- (void)switchCamera;
/** 打开/关闭 手电筒 */
- (void)openTorch:(BOOL)isOpen;
/** 切换闪光灯 */
- (void)switchFlash;
/** 摧毁视频摄制器：在摧毁控制器时调用，不然会导致无法释放而内存泄露 */
- (void)destroy;

@end
