//
//  SKVideoCapture.m
//  SKVideoManager
//
//  Created by WangYu on 16/4/18.
//  Copyright © 2016年 PoloStoneK. All rights reserved.
//

#define degreesToRadians(degrees) ((degrees) / 180.0 * M_PI)

#import "SKVideoCapture.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface SKVideoCapture () <AVCaptureFileOutputRecordingDelegate>
/** 拍摄视频流的View */
@property (strong, nonatomic) UIView                     *view;
/** 视频流对话 */
@property (strong, nonatomic) AVCaptureSession           *session;
/** 视频流预览层 */
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
/** 当前视频输入源 */
@property (strong, nonatomic) AVCaptureDeviceInput       *currentVideoInput;
/** 视频输出源 */
@property (strong, nonatomic) AVCaptureMovieFileOutput   *videoOutput;
/** 是否写入相册 */
@property (assign, nonatomic) BOOL                       writeToPhotoLibrary;


/** 视频处理时机Block回调 */
@property (copy, nonatomic) void(^startBlock)();
@property (copy, nonatomic) void(^succeedBlock)();
@property (copy, nonatomic) void(^failedBlock)();
@end

@implementation SKVideoCapture

+ (instancetype)videoCaptureWithPreviewLayerView:(UIView *)aView videoGravity:(NSString *)videoGravity {
    return [[self alloc] initWithPreviewLayerView:aView videoGravity:videoGravity];
}

- (instancetype)initWithPreviewLayerView:(UIView *)aView videoGravity:(NSString *)videoGravity {
    self = [super init];
    if (!self) return nil;
    _view = aView;
    
    // ① 初始化session对象
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    _session = session;
    // 设置拍摄画质
    if ([session canSetSessionPreset:AVCaptureSessionPresetiFrame1280x720]) {
        session.sessionPreset = AVCaptureSessionPresetiFrame1280x720;
    }
    
    // ② 添加输入设备：backCamera --> 摄像头(视频)；microphoneDevice --> 声音(麦克风)
    AVCaptureDevice *backCamera = [self cameraWithBackPosition:YES];
    AVCaptureDevice *microphoneDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    if (!backCamera) return nil;
    if (!microphoneDevice) return nil;
    
    // 初始化输入设备
    AVCaptureDeviceInput *backCameraInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:nil];
    _currentVideoInput = backCameraInput;
    AVCaptureDeviceInput *microphoneInput = [AVCaptureDeviceInput deviceInputWithDevice:microphoneDevice error:nil];
    
    // 添加输入设备
    if ([session canAddInput:backCameraInput]) [session addInput:backCameraInput];
    if ([session canAddInput:microphoneInput]) [session addInput:microphoneInput];
    
    // ③ 添加输出设备
    AVCaptureMovieFileOutput *movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    _videoOutput = movieOutput;
    if ([session canAddOutput:movieOutput]) [session addOutput:movieOutput];
    
    // ④ 初始化视频预览层
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    _videoPreviewLayer = videoPreviewLayer;
    videoPreviewLayer.videoGravity = [self availableVideoGravity:videoGravity];
    videoPreviewLayer.frame = aView.bounds;
    videoPreviewLayer.backgroundColor = [UIColor blackColor].CGColor;
    [aView.layer addSublayer:videoPreviewLayer];
    
    // ⑤ 开始拍摄
    [session startRunning];
    
    return self;
}

/**
 *  可用的视频预览模式：主要是判断构造方法传入的参数是否可用
 *
 *  @param videoGravity 构造方法传入的参数
 *
 *  @return 可用的预览模式
 */
- (NSString *)availableVideoGravity:(NSString *)videoGravity {
    if ([videoGravity isEqualToString:AVLayerVideoGravityResize] ||
        [videoGravity isEqualToString:AVLayerVideoGravityResizeAspect] ||
        [videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        return videoGravity;
    }
    return AVLayerVideoGravityResizeAspect;
}

/** 获取 前/后 摄像头 */
- (AVCaptureDevice *)cameraWithBackPosition:(BOOL)isBack {
    
    AVCaptureDevice *frontCamera;
    
    AVCaptureDevice *backCamera;
    
    NSArray *allCameraDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *camera in allCameraDevices) {
        
        switch (camera.position) {
            case AVCaptureDevicePositionUnspecified: {
                
                break;
            }
            case AVCaptureDevicePositionBack: {
                backCamera = camera;
                if (camera) _backCameraAvailable = YES;
                break;
            }
            case AVCaptureDevicePositionFront: {
                frontCamera = camera;
                if (camera) _frontCameraAvailable = YES;
                break;
            }
        }
    }
    return isBack ? backCamera : frontCamera;
}


/** 打开/关闭 手电筒 */
- (void)openTorch:(BOOL)isOpen {
    
    AVCaptureDevice *camera = _currentVideoInput.device;
    
    if (!camera.hasTorch || !camera.isTorchAvailable) return;
    
    AVCaptureTorchMode torchMode = isOpen ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
    if (camera.hasTorch && camera.isTorchAvailable) {
        if ([camera isTorchModeSupported:torchMode]) {
            [camera lockForConfiguration:nil];
            [camera setTorchMode:torchMode];
            [camera unlockForConfiguration];
        }
    }
}

/** 切换摄像头 */
- (void)switchCamera {
    
    if (_videoOutput.isRecording) {
        NSLog(@"Can't switch camera while recording !!！");
        return;
    }
    
    // 判断前后摄像头是否可用，当前是否有视频输入源
    if (!_backCameraAvailable || !_frontCameraAvailable || !_currentVideoInput) return;
    // 关闭手电筒
    [self openTorch:NO];
    
    
    // 开始配置session
    [_session beginConfiguration];
    
    // ① 移除当前输入源
    [_session removeInput:_currentVideoInput];
    
    // ② 获取要切换的输入源
    AVCaptureDevice *camera = [self cameraWithBackPosition:YES]; // 获取后置摄像头
    if (_currentVideoInput.device.position == AVCaptureDevicePositionBack) camera = [self cameraWithBackPosition:NO]; // 当前是后置的话获取前置摄像头
    
    // ③ 配置摄像头的曝光为持续自动曝光
    [camera lockForConfiguration:nil];
    if (![camera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) return;
    [camera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    [camera unlockForConfiguration];
    
    // ④ 添加输入源
    _currentVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:nil];
    if ([_session canAddInput:_currentVideoInput]) [_session addInput:_currentVideoInput];
    
    
    // 结束配置
    [_session commitConfiguration];
}

/** 切换闪光灯 */
- (void)switchFlash {
    
    AVCaptureDevice *camera = _currentVideoInput.device;
    
    if (!camera.hasFlash || !camera.isFlashAvailable) return;
    
    NSInteger currentFlashMode = camera.flashMode;
    
    AVCaptureFlashMode flashMode = ++currentFlashMode % 3;
    
    if (![camera isFlashModeSupported:flashMode]) return;
    
    [camera lockForConfiguration:nil];
    
    [camera setFlashMode:flashMode];
    
    [camera unlockForConfiguration];
}

/**
 *  对焦
 *
 *  @param point 点击的对焦点
 */
- (void)focusInPoint:(CGPoint)point {
    
    if (!CGRectContainsPoint(_view.frame, point)) return;
    
    AVCaptureDevice *camera = _currentVideoInput.device;
    if (![camera isFocusPointOfInterestSupported]) return;
    if (![camera lockForConfiguration:nil]) return;
    CGPoint focusPointOfInterest = [_videoPreviewLayer captureDevicePointOfInterestForPoint:point];
    if ([camera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) [camera setFocusMode:AVCaptureFocusModeAutoFocus];
    if (camera.focusPointOfInterestSupported) [camera setFocusPointOfInterest:focusPointOfInterest];
    if ([camera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) [camera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    [camera setSubjectAreaChangeMonitoringEnabled:YES];
    [camera unlockForConfiguration];
}

/**
 *  压缩摄制的视频流
 *
 *  @param url 摄制的视频流保存路径
 */
- (void)compressVideoWithURL:(NSURL *)url {
    
    if (!url) return;
    
    // ① 创建asset对象
    AVAsset *asset = [AVAsset assetWithURL:url];
    
    // ② 得到音/视频轨
    AVAssetTrack *assetVideoTrack;
    AVAssetTrack *assetAudioTrack;
    
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    }
    if ([asset tracksWithMediaType:AVMediaTypeAudio].count) {
        assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    }
    
    
    // ③ 将音/视频轨添加到Composition中
    NSError *error;
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    if (assetVideoTrack) {
        AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
    }
    if (assetAudioTrack) {
        AVMutableCompositionTrack *compositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
    }
    
    
    // ④ 将视频流旋转90°，截取中间区域：宽度不变，高度以16:9比例截取
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:mutableComposition.tracks.firstObject];
    double naturalHeight = assetVideoTrack.naturalSize.height;
    double naturalWidth = assetVideoTrack.naturalSize.width;
    CGAffineTransform transform = CGAffineTransformMakeTranslation(naturalHeight, 0.0);
    transform = CGAffineTransformRotate(transform, degreesToRadians(90.0));
    double ratio = (CGFloat)MAX(naturalHeight, naturalWidth) / (CGFloat)MIN(naturalHeight, naturalWidth);
    double finalHeight = naturalHeight / ratio;
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0, -(naturalWidth - finalHeight) / 2));
    [layerInstruction setTransform:transform atTime:kCMTimeZero];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mutableComposition duration]);
    instruction.layerInstructions = @[layerInstruction];
    
    
    // ⑤ 摄制帧率，渲染尺寸，截取数据instruction
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    mutableVideoComposition.renderSize = CGSizeMake(naturalHeight, finalHeight);
    mutableVideoComposition.instructions = @[instruction];
    
    
    // ⑥ 输出
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *outputURL = url.path;
    [manager removeItemAtPath:outputURL error:nil];
    
    
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:mutableComposition presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.videoComposition = mutableVideoComposition;
    exportSession.outputURL = [NSURL fileURLWithPath:outputURL];
    // 异步输出，任何UI操作请在 (- videoCaptureDidStartRecording:finishRecording:recordingFailed:) 中执行
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exportSession.status) {
            case AVAssetExportSessionStatusUnknown: {
                NSLog(@"AVAssetExportSessionStatusUnknown");
                break;
            }
            case AVAssetExportSessionStatusWaiting: {
                NSLog(@"Waiting for Export");
                break;
            }
            case AVAssetExportSessionStatusExporting: {
                NSLog(@"Exporting video");
                break;
            }
            case AVAssetExportSessionStatusCompleted: {
                NSLog(@"Export Completed");
                // 输出完成
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.succeedBlock) self.succeedBlock();
                });
                // 写入相册
                if (_writeToPhotoLibrary) {
                    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                    
                    [library writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:outputURL] completionBlock:^(NSURL *assetURL, NSError *error){
                        if (error) {
                            NSLog(@"Video could not be saved to photo library");
                        }
                    }];
                }
                
                break;
            }
            case AVAssetExportSessionStatusFailed: {
                NSLog(@"Export Failed:%@", exportSession.error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.failedBlock) {
                        self.failedBlock();
                    }
                });
                break;
            }
            case AVAssetExportSessionStatusCancelled: {
                NSLog(@"Export Canceled:%@", exportSession.error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.failedBlock) {
                        self.failedBlock();
                    }
                });
                break;
            }
        }
    }];
}

/**
 *  开始摄制视频流
 *
 *  @param filePath 视频流最终保存的路径
 *  @param write    是否写入相册
 */
- (void)startRecordingToOutputFileUrl:(NSString *)filePath writeVideoToPhotoLibrary:(BOOL)write {
    _writeToPhotoLibrary = write;
    // 转义目录，防止中文目录产生的问题
    filePath = [filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    // 保险起见创建目录
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    // 开始录制
    [_videoOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:filePath] recordingDelegate:self];
}

/** 停止摄制视频流 */
- (void)stopRecording {
    if (_videoOutput.isRecording) {
        [_videoOutput stopRecording];
    }
}

#pragma mark - AVCaptureFileOutputRecordignDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"start recording");
    if (self.startBlock) self.startBlock();
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    if (!error) {
        NSLog(@"record successed:%@", outputFileURL);
        [self compressVideoWithURL:outputFileURL];
    }else {
        NSLog(@"record failed");
        if (self.failedBlock) {
            self.failedBlock();
        }
    }
}

// 见头文件注释
- (void)videoCaptureDidStartRecording:(void(^)())start finishRecording:(void(^)())succeed recordingFailed:(void(^)())failed {
    self.startBlock = start;
    self.succeedBlock = succeed;
    self.failedBlock = failed;
}

- (void)destroy {
    [_session removeInput:_currentVideoInput];
    [_session removeOutput:_videoOutput];
    _currentVideoInput = nil;
    _videoOutput = nil;
    _session = nil;
    [_videoPreviewLayer removeFromSuperlayer];
    _videoPreviewLayer = nil;
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

@end
