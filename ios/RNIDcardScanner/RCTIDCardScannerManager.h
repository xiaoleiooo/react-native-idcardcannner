//
//  RCTIDCardScannerManager.h
//  RNIDcardScanner
//
//  Created by rain on 2019/10/31.
//  Copyright © 2019年 com.rainy.osource. All rights reserved.
//

#import <React/RCTViewManager.h>
#import <AVFoundation/AVFoundation.h>

@class RCTIDcardScanner;

@interface RCTIDCardScannerManager : RCTViewManager<AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) RCTIDcardScanner *IDcardScanner;

// 摄像头设备
@property (nonatomic,strong) AVCaptureDevice *device;

// AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
@property (nonatomic,strong) AVCaptureSession *session;

// 输出格式
@property (nonatomic,strong) NSNumber *outPutSetting;

// 出流对象
@property (nonatomic,strong) AVCaptureVideoDataOutput *videoDataOutput;

// 元数据（用于人脸识别）
@property (nonatomic,strong) AVCaptureMetadataOutput *metadataOutput;

// 预览图层
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;

// 人脸检测框区域
@property (nonatomic,assign) CGRect faceDetectionFrame;

// 队列
@property (nonatomic,strong) dispatch_queue_t queue;

// 是否打开手电筒
@property (nonatomic,assign,getter = isTorchOn) BOOL torchOn;

// 是否可以开始识别，如果是自动识别，则为true，手动的话 需要手动点击识别
@property (nonatomic,assign) BOOL isCanReg;

// 是否在识别
@property (nonatomic,assign) BOOL isInReg;

// session开始，即输入设备和输出设备开始数据传递
- (void)startSession;

// session停止，即输入设备和输出设备结束数据传递
-(void)stopSession;

//session 销毁
- (void)endSession;

//手动模式下，开始识别
- (void)setCanReg;

//识别成功下，需要调用这个方法激活下次识别
- (void)restartScanner;

@end
