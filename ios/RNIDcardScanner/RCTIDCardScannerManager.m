//
//  RCTIDCardScannerManager.m
//  RNIDcardScanner
//
//  Created by rain on 2019/10/31.
//  Copyright © 2019年 com.rainy.osource. All rights reserved.
//

#import "RCTIDCardScannerManager.h"
#import "RCTIDcardScanner.h"
#import "excards.h"
#import "IDInfo.h"
#import "RectManager.h"
#import "UIImage+Extend.h"

@interface RCTIDCardScannerManager()

@end

@implementation RCTIDCardScannerManager

RCT_EXPORT_MODULE(RCTIDCardScanner)

RCT_EXPORT_VIEW_PROPERTY(isAutoReg, BOOL)

RCT_EXPORT_VIEW_PROPERTY(scannerRectWidth, NSInteger)

//RCT_EXPORT_VIEW_PROPERTY(scannerRectHeight, NSInteger)

RCT_EXPORT_VIEW_PROPERTY(scannerRectTop, NSInteger)

//RCT_EXPORT_VIEW_PROPERTY(scannerRectLeft, NSInteger)

RCT_EXPORT_VIEW_PROPERTY(scannerRectCornerRadius, NSInteger)

RCT_EXPORT_VIEW_PROPERTY(scannerRectBorderWidth, NSInteger)

RCT_EXPORT_VIEW_PROPERTY(scannerRectColor, NSString)

RCT_EXPORT_VIEW_PROPERTY(onIDScannerResult, RCTBubblingEventBlock)

    #if TARGET_IPHONE_SIMULATOR
    #else
    #endif
-(UIView *)view{
    
////NSLog(@"aaa %@",NSStringFromSelector(_cmd));
    [self loadEXCARDS];
    if(!self.IDcardScanner){
        self.IDcardScanner = [[RCTIDcardScanner alloc] initWithManager:self];
        [self.IDcardScanner setClipsToBounds:YES];
    }
    
    self.torchOn = NO;
    self.isInReg = NO;
    self.isCanReg = self.IDcardScanner.isAutoReg;
//NSLog(@"aaa %@   %d",NSStringFromSelector(_cmd),self.isCanReg);
    return self.IDcardScanner;
}

//#pragma mark - view即将消失时
//-(void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//
//    // 将AVCaptureViewController的navigationBar调为不透明
//    [[[self.navigationController.navigationBar subviews] objectAtIndex:0] setAlpha:1];
//    //    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]}];
//
//    [self stopSession];
//}
//

#pragma mark - 懒加载
#pragma mark device
-(AVCaptureDevice *)device{
    if (_device == nil) {
        //NSLog(@"aaa %@ nil",NSStringFromSelector(_cmd));
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        NSError *error = nil;
        if ([_device lockForConfiguration:&error]) {
            if ([_device isSmoothAutoFocusSupported]) {// 平滑对焦
                _device.smoothAutoFocusEnabled = YES;
            }
            
            if ([_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {// 自动持续对焦
                _device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            }
            
            if ([_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure ]) {// 自动持续曝光
                _device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            }
            
            if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {// 自动持续白平衡
                _device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
            }
            
            //            NSError *error1;
            //            CMTime frameDuration = CMTimeMake(1, 30); // 默认是1秒30帧
            //            NSArray *supportedFrameRateRanges = [_device.activeFormat videoSupportedFrameRateRanges];
            //            BOOL frameRateSupported = NO;
            //            for (AVFrameRateRange *range in supportedFrameRateRanges) {
            //                if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) && CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
            //                    frameRateSupported = YES;
            //                }
            //            }
            //
            //            if (frameRateSupported && [self.device lockForConfiguration:&error1]) {
            //                [_device setActiveVideoMaxFrameDuration:frameDuration];
            //                [_device setActiveVideoMinFrameDuration:frameDuration];
            ////                [self.device unlockForConfiguration];
            //            }
            
            [_device unlockForConfiguration];
        }
    }
    
    return _device;
}

#pragma mark outPutSetting
-(NSNumber *)outPutSetting {
    if (_outPutSetting == nil) {
        //NSLog(@"aaa %@ nil",NSStringFromSelector(_cmd));
        _outPutSetting = @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
    }
    
    return _outPutSetting;
}

#pragma mark metadataOutput
-(AVCaptureMetadataOutput *)metadataOutput {
    if (_metadataOutput == nil) {
        //NSLog(@"aaa %@ nil",NSStringFromSelector(_cmd));
        _metadataOutput = [[AVCaptureMetadataOutput alloc]init];

        [_metadataOutput setMetadataObjectsDelegate:self queue:self.queue];
    }

    return _metadataOutput;
}

#pragma mark videoDataOutput
-(AVCaptureVideoDataOutput *)videoDataOutput {
    if (_videoDataOutput == nil) {
        //NSLog(@"aaa %@ nil",NSStringFromSelector(_cmd));
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        _videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:self.outPutSetting};
        
        [_videoDataOutput setSampleBufferDelegate:self queue:self.queue];
    }
    
    return _videoDataOutput;
}

#pragma mark session
-(AVCaptureSession *)session {
    if (_session == nil) {
        //NSLog(@"aaa %@ nil",NSStringFromSelector(_cmd));
        _session = [[AVCaptureSession alloc] init];
        
        _session.sessionPreset = AVCaptureSessionPresetHigh;
        
        // 2、设置输入：由于模拟器没有摄像头，因此最好做一个判断
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
        
        if (error) {
        //todo
//            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
//            [self alertControllerWithTitle:@"没有摄像设备" message:error.localizedDescription okAction:okAction cancelAction:nil];
        }else {
            if ([_session canAddInput:input]) {
                [_session addInput:input];
            }
            
            if ([_session canAddOutput:self.videoDataOutput]) {
                [_session addOutput:self.videoDataOutput];
            }
            
            if ([_session canAddOutput:self.metadataOutput]) {
                [_session addOutput:self.metadataOutput];
                // 输出格式要放在addOutPut之后，否则奔溃
                self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
            }
        }
    }
    
    return _session;
}

#pragma mark previewLayer
-(AVCaptureVideoPreviewLayer *)previewLayer {
    if (_previewLayer == nil) {
        //NSLog(@"aaa %@ nil",NSStringFromSelector(_cmd));
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    }
    
    return _previewLayer;
}

#pragma mark queue
-(dispatch_queue_t)queue {
    if (_queue == nil) {
        //NSLog(@"aaa %@ nil",NSStringFromSelector(_cmd));
        //        _queue = dispatch_queue_create("AVCaptureSession_Start_Running_Queue", DISPATCH_QUEUE_SERIAL);
        _queue = dispatch_queue_create("IDCardScannerManagerQueue", DISPATCH_QUEUE_SERIAL);
//        _queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    
    return _queue;
}


#pragma mark - load EXCARDS
// session开始，即输入设备和输出设备开始数据传递
- (void)loadEXCARDS {
#if TARGET_IPHONE_SIMULATOR
    return;
#endif
//    if (![self.session isRunning]) {
        dispatch_async(self.queue, ^{
            // 初始化rect
            const char *thePath = [[[NSBundle mainBundle] resourcePath] UTF8String];
            int ret = EXCARDS_Init(thePath);
            if (ret != 0) {
                //NSLog(@"初始化失败：ret=%d", ret);
            }
        });
//    }
}

#pragma mark - 运行session
// session开始，即输入设备和输出设备开始数据传递
RCT_EXPORT_METHOD(startSession) {
#if TARGET_IPHONE_SIMULATOR
    return;
#endif
    //NSLog(@"aaa %@",NSStringFromSelector(_cmd));
    if (![self.session isRunning]) {
        //NSLog(@"aaa isRunning");
        dispatch_async(self.queue, ^{
            [self.session startRunning];
            [self.videoDataOutput setSampleBufferDelegate:self queue:self.queue];
        });
    }
}

#pragma mark - 停止session
// session停止，即输入设备和输出设备结束数据传递
RCT_EXPORT_METHOD(stopSession) {
#if TARGET_IPHONE_SIMULATOR
    return;
#endif
    //NSLog(@"aaa %@",NSStringFromSelector(_cmd));
    if ([self.session isRunning]) {
        dispatch_async(self.queue, ^{
            [self.session stopRunning];
            [self.videoDataOutput setSampleBufferDelegate:nil queue:self.queue];
        });
    }
}

// session停止，即输入设备和输出设备结束数据传递
RCT_EXPORT_METHOD(endSession) {
#if TARGET_IPHONE_SIMULATOR
    return;
#endif
    //NSLog(@"aaa %@",NSStringFromSelector(_cmd));
    if ([self.session isRunning]) {
        dispatch_async(self.queue, ^{
            [self.session stopRunning];
//            self.IDcardScanner = nil;
//            [self.previewLayer removeFromSuperlayer];
            [self.session stopRunning];
//            for(AVCaptureInput *input in self.session.inputs) {
//                [self.session removeInput:input];
//            }
//
//            for(AVCaptureOutput *output in self.session.outputs) {
//                [self.session removeOutput:output];
//            }
//
//            self.videoDataOutput = nil;
//            self.outPutSetting = nil;
        });
    }
}

RCT_EXPORT_METHOD(setCanReg) {
    //NSLog(@"aaa %@",NSStringFromSelector(_cmd));
    self.isCanReg = YES;
}

RCT_EXPORT_METHOD(restartScanner){
    ////NSLog(@"aaa %@",NSStringFromSelector(_cmd));
    self.isCanReg = YES;
    [self startSession];
}


#pragma mark - 打开／关闭手电筒
-(void)turnOnOrOffTorch {
    self.torchOn = !self.isTorchOn;
    
    if ([self.device hasTorch]){ // 判断是否有闪光灯
        [self.device lockForConfiguration:nil];// 请求独占访问硬件设备
        
        if (self.isTorchOn) {
//            self.navigationItem.rightBarButtonItem.image = [[UIImage imageNamed:@"nav_torch_on"] originalImage];
            [self.device setTorchMode:AVCaptureTorchModeOn];
        } else {
//            self.navigationItem.rightBarButtonItem.image = [[UIImage imageNamed:@"nav_torch_off"] originalImage];
            [self.device setTorchMode:AVCaptureTorchModeOff];
        }
        [self.device unlockForConfiguration];// 请求解除独占访问硬件设备
    }else {
//        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
//        [self alertControllerWithTitle:@"提示" message:@"您的设备没有闪光设备，不能提供手电筒功能，请检查" okAction:okAction cancelAction:nil];
    }
}


//#pragma mark - 展示UIAlertController
//-(void)alertControllerWithTitle:(NSString *)title message:(NSString *)message okAction:(UIAlertAction *)okAction cancelAction:(UIAlertAction *)cancelAction {
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message okAction:okAction cancelAction:cancelAction];
//    [self presentViewController:alertController animated:YES completion:nil];
//}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
#pragma mark 从输出的元数据中捕捉人脸
// 检测人脸是为了获得“人脸区域”，做“人脸区域”与“身份证人像框”的区域对比，当前者在后者范围内的时候，才能截取到完整的身份证图像
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count) {
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;

        AVMetadataObject *transformedMetadataObject = [self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
        CGRect faceRegion = transformedMetadataObject.bounds;

        if (metadataObject.type == AVMetadataObjectTypeFace) {
            //NSLog(@"是否包含头像：%d, facePathRect: %@, faceRegion: %@  isCanReg:%@" ,CGRectContainsRect(self.faceDetectionFrame,faceRegion),NSStringFromCGRect(self.faceDetectionFrame),NSStringFromCGRect(faceRegion), self.isCanReg?@"YES":@"NO");

            if (CGRectContainsRect(self.faceDetectionFrame, faceRegion) && self.isCanReg) {// 只有当人脸区域的确在小框内时，才再去做捕获此时的这一帧图像
                // 为videoDataOutput设置代理，程序就会自动调用下面的代理方法，捕获每一帧图像
                if (!self.videoDataOutput.sampleBufferDelegate) {
                    [self.videoDataOutput setSampleBufferDelegate:self queue:self.queue];
                }
            }
        }
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
#pragma mark 从输出的数据流捕捉单一的图像帧
// AVCaptureVideoDataOutput获取实时图像，这个代理方法的回调频率很快，几乎与手机屏幕的刷新频率一样快
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if(self.isInReg){
        return;
    }
    self.isInReg = YES;
    if ([self.outPutSetting isEqualToNumber:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]] || [self.outPutSetting isEqualToNumber:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]]) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        if ([captureOutput isEqual:self.videoDataOutput]) {
            // 身份证信息识别
            [self IDCardRecognit:imageBuffer];
            
//            // 身份证信息识别完毕后，就将videoDataOutput的代理去掉，防止频繁调用AVCaptureVideoDataOutputSampleBufferDelegate方法而引起的“混乱”
            if (self.videoDataOutput.sampleBufferDelegate) {
                [self.videoDataOutput setSampleBufferDelegate:nil queue:self.queue];
            }
        }
    } else {
        //NSLog(@"输出格式不支持");
    }
}

#pragma mark - 身份证信息识别
- (void)IDCardRecognit:(CVImageBufferRef)imageBuffer {
    CVBufferRetain(imageBuffer);
    // Lock the image buffer
    if (CVPixelBufferLockBaseAddress(imageBuffer, 0) == kCVReturnSuccess) {
        size_t width= CVPixelBufferGetWidth(imageBuffer);// 1920
        size_t height = CVPixelBufferGetHeight(imageBuffer);// 1080
        
        CVPlanarPixelBufferInfo_YCbCrBiPlanar *planar = CVPixelBufferGetBaseAddress(imageBuffer);
        size_t offset = NSSwapBigIntToHost(planar->componentInfoY.offset);
        size_t rowBytes = NSSwapBigIntToHost(planar->componentInfoY.rowBytes);
        unsigned char* baseAddress = (unsigned char *)CVPixelBufferGetBaseAddress(imageBuffer);
        unsigned char* pixelAddress = baseAddress + offset;
        
        static unsigned char *buffer = NULL;
        if (buffer == NULL) {
            buffer = (unsigned char *)malloc(sizeof(unsigned char) * width * height);
        }
        
        memcpy(buffer, pixelAddress, sizeof(unsigned char) * width * height);
        
        unsigned char pResult[1024];
        int ret = EXCARDS_RecoIDCardData(buffer, (int)width, (int)height, (int)rowBytes, (int)8, (char*)pResult, sizeof(pResult));
        if (ret <= 0) {
            //NSLog(@"ret=[%d]", ret);
        } else {
            //NSLog(@"ret=[%d]", ret);
            
//            // 播放一下“拍照”的声音，模拟拍照
//            AudioServicesPlaySystemSound(1108);
            
            if ([self.session isRunning]) {
                [self.session stopRunning];
                self.isCanReg = NO;
            }
            
            char ctype;
            char content[256];
            int xlen;
            int i = 0;
            
            IDInfo *iDInfo = [[IDInfo alloc] init];
            
            ctype = pResult[i++];
            
                        iDInfo.type = ctype;
            while(i < ret){
                ctype = pResult[i++];
                for(xlen = 0; i < ret; ++i){
                    if(pResult[i] == ' ') { ++i; break; }
                    content[xlen++] = pResult[i];
                }
                
                content[xlen] = 0;
                
                if(xlen) {
                    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
                    if(ctype == 0x21) {
                        iDInfo.num = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    } else if(ctype == 0x22) {
                        iDInfo.name = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    } else if(ctype == 0x23) {
                        iDInfo.gender = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    } else if(ctype == 0x24) {
                        iDInfo.nation = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    } else if(ctype == 0x25) {
                        iDInfo.address = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    } else if(ctype == 0x26) {
                        iDInfo.issue = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    } else if(ctype == 0x27) {
                        iDInfo.valid = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    }
                }
            }
            
            if (iDInfo) {// 读取到身份证信息，实例化出IDInfo对象后，截取身份证的有效区域，获取到图像
                //NSLog(@"\n%d\n正面\n姓名：%@\n性别：%@\n民族：%@\n住址：%@\n公民身份证号码：%@\n\n反面\n签发机关：%@\n有效期限：%@",iDInfo.type,iDInfo.name,iDInfo.gender,iDInfo.nation,iDInfo.address,iDInfo.num,iDInfo.issue,iDInfo.valid);
                CGRect effectRect = [RectManager getEffectImageRect:CGSizeMake(width, height)];
//                CGRect rect = [RectManager getGuideFrame:effectRect];
                CGRect rect = [RectManager getGuideFrame:effectRect width:_IDcardScanner.scannerRectWidth marTop:_IDcardScanner.scannerRectTop];
                UIImage *image = [UIImage getImageStream:imageBuffer];
                UIImage *subImage = [UIImage getSubImage:rect inImage:image];
                
                
        
                
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *fileName = [NSString stringWithFormat:@"%@.png",[self getNowTimeTimestamp]];
                NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
                [UIImagePNGRepresentation(subImage) writeToFile:filePath atomically:YES];
                
                
                
                if (!self.IDcardScanner.onIDScannerResult) {
                    return;
                }
                if(iDInfo.type == 1){
                    self.IDcardScanner.onIDScannerResult(@{
                                                           @"data": @{
                                                                   @"cardFace": @"front",
                                                                   @"name":iDInfo.name,
                                                                   @"sex":iDInfo.gender,
                                                                   @"nation":iDInfo.nation,
                                                                   @"birth": @"",
                                                                   @"address": iDInfo.address,
                                                                   @"cardNum": iDInfo.num,
                                                                   @"imgPath":filePath
                                                                   },
                                                           });
                }else if(iDInfo.type == 2){
                    self.IDcardScanner.onIDScannerResult(@{
                                                           @"data": @{
                                                                   @"cardFace": @"back",
                                                                   @"office":iDInfo.issue,
                                                                   @"validDate":iDInfo.valid,
                                                                   @"imgPath":filePath
                                                                   },
                                                           });
                }
            }
        }
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    }
    CVBufferRelease(imageBuffer);
    self.isInReg = NO;
}


-(NSString *)getNowTimeTimestamp{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"]; // ----------设置你想要的格式,hh与HH的区别:分别表示12小时制,24小时制
    //设置时区,这个对于时间的处理有时很重要
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setTimeZone:timeZone];
    NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];
    return timeSp;
}

RCT_EXPORT_METHOD(IDCardRecognitFromFile:(NSString *)file resolve:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    
    UIImage *image = [UIImage imageNamed:@"dd.png"];
    unsigned char *imageBytes = [self pixelBRGABytesFromImage:image];
    unsigned char pResult[1024];
    int ret = EXCARDS_RecoIDCardFile((char*)imageBytes, (char*)pResult, sizeof(pResult));
    if (ret <= 0) {
        //NSLog(@"ret=[%d]", ret);
    } else {
        //NSLog(@"ret=[%d]", ret);
        char ctype;
        char content[256];
        int xlen;
        int i = 0;
        
        IDInfo *iDInfo = [[IDInfo alloc] init];
        ctype = pResult[i++];
        iDInfo.type = ctype;
        while(i < ret){
            ctype = pResult[i++];
            for(xlen = 0; i < ret; ++i){
                if(pResult[i] == ' ') { ++i; break; }
                content[xlen++] = pResult[i];
            }
            content[xlen] = 0;
            if(xlen) {
                NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
                if(ctype == 0x21) {
                    iDInfo.num = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                } else if(ctype == 0x22) {
                    iDInfo.name = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                } else if(ctype == 0x23) {
                    iDInfo.gender = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                } else if(ctype == 0x24) {
                    iDInfo.nation = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                } else if(ctype == 0x25) {
                    iDInfo.address = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                } else if(ctype == 0x26) {
                    iDInfo.issue = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                } else if(ctype == 0x27) {
                    iDInfo.valid = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                }
            }
        }
        if (iDInfo) {// 读取到身份证信息，实例化出IDInfo对象后，截取身份证的有效区域，获取到图像
            //NSLog(@"\n%d\n正面\n姓名：%@\n性别：%@\n民族：%@\n住址：%@\n公民身份证号码：%@\n\n反面\n签发机关：%@\n有效期限：%@",iDInfo.type,iDInfo.name,iDInfo.gender,iDInfo.nation,iDInfo.address,iDInfo.num,iDInfo.issue,iDInfo.valid);
            if (!self.IDcardScanner.onIDScannerResult) {
                return;
            }
//            if(iDInfo.type == 1){
//                self.IDcardScanner.onIDScannerResult(@{
//                                                       @"data": @{
//                                                               @"cardFace": @"front",
//                                                               @"name":iDInfo.name,
//                                                               @"sex":iDInfo.gender,
//                                                               @"nation":iDInfo.nation,
//                                                               @"birth": @"",
//                                                               @"address": iDInfo.address,
//                                                               @"cardNum": iDInfo.num,
//                                                               @"imgPath":@""
//                                                               },
//                                                       });
//            }else if(iDInfo.type == 2){
//                self.IDcardScanner.onIDScannerResult(@{
//                                                       @"data": @{
//                                                               @"cardFace": @"back",
//                                                               @"office":iDInfo.issue,
//                                                               @"validDate":iDInfo.valid,
//                                                               @"imgPath":@""
//                                                               },
//                                                       });
//            }
        }
    }
    
    NSString *address = @"02:00:00:00:00:00";
    resolve(address);
    //注：不要忘记释放malloc的内存
    free(imageBytes);
}


- (unsigned char *)pixelBRGABytesFromImage:(UIImage *)image {
    return [self pixelBRGABytesFromImageRef:image.CGImage];
}

- (unsigned char *)pixelBRGABytesFromImageRef:(CGImageRef)imageRef {
    
    NSUInteger iWidth = CGImageGetWidth(imageRef);
    NSUInteger iHeight = CGImageGetHeight(imageRef);
    NSUInteger iBytesPerPixel = 4;
    NSUInteger iBytesPerRow = iBytesPerPixel * iWidth;
    NSUInteger iBitsPerComponent = 8;
    unsigned char *imageBytes = malloc(iWidth * iHeight * iBytesPerPixel);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(imageBytes,
                                                 iWidth,
                                                 iHeight,
                                                 iBitsPerComponent,
                                                 iBytesPerRow,
                                                 colorspace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGRect rect = CGRectMake(0 , 0 , iWidth , iHeight);
    CGContextDrawImage(context , rect ,imageRef);
    CGColorSpaceRelease(colorspace);
    CGContextRelease(context);
    CGImageRelease(imageRef);
    
    return imageBytes;
}

/*
 - (UIImage*)imageWithImageSimple:(NSData *)data scaledToSize:(CGSize)newSize {
 UIImage *image = [UIImage imageWithData:data];
 
 // Create a graphics image context
 UIGraphicsBeginImageContext(newSize);
 
 // Tell the old image to draw in this new context, with the desired
 // new size
 [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
 
 // Get the new image from the context
 UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
 
 // End the context
 UIGraphicsEndImageContext();
 
 // Return the new image.
 
 return newImage;
 }
 
 - (UIImage *)clipImageWithImage:(UIImage *)image InRect:(CGRect)rect {
 CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
 UIImage *thumbScale = [UIImage imageWithCGImage:imageRef];
 CGImageRelease(imageRef);
 
 return thumbScale;
 }
 
 - (void)addConnection {
 AVCaptureConnection *videoConnection;
 for (AVCaptureConnection *connection in [self.videoDataOutput connections]) {
 for (AVCaptureInputPort *port in [connection inputPorts]) {
 if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
 videoConnection = connection;
 }
 }
 }
 
 if ([videoConnection isVideoStabilizationSupported]) {
 if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
 videoConnection.enablesVideoStabilizationWhenAvailable = YES;
 }
 else {
 videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
 }
 }
 }
 
 - (void)configureDevice:(AVCaptureDevice *)device {
 // Use Smooth focus
 if( YES == [device lockForConfiguration:NULL] )
 {
 if([device respondsToSelector:@selector(setSmoothAutoFocusEnabled:)] && [device isSmoothAutoFocusSupported] )
 {
 [device setSmoothAutoFocusEnabled:YES];
 }
 AVCaptureFocusMode currentMode = [device focusMode];
 if( currentMode == AVCaptureFocusModeLocked )
 {
 currentMode = AVCaptureFocusModeAutoFocus;
 }
 if( [device isFocusModeSupported:currentMode] )
 {
 [device setFocusMode:currentMode];
 }
 [device unlockForConfiguration];
 }
 }
 */

@end

// 设置人脸扫描区域
/*
 
 为什么做人脸扫描？
 
 经实践证明，由于预览图层是全屏的，当用户有时没有将身份证对准拍摄框边缘时，也会成功读取身份证上的信息，即也会捕获到不完整的身份证图像。
 因此，为了截取到比较完整的身份证图像，在自定义扫描界面的合适位置上加了一个身份证头像框，让用户将该小框对准身份证上的头像，最终目的是使程序截取到完整的身份证图像。
 当该小框检测到人脸时，再对比人脸区域是否在这个小框内，若在，说明用户的确将身份证头像放在了这个框里，那么此时这一帧身份证图像大小正好合适且完整，接下来才捕获该帧，就获得了完整的身份证截图。（若不在，那么就不捕获此时的图像）
 
 理解：检测身份证上的人脸是为了获得证上的人脸区域，获得人脸区域是为了希望人脸区域能在小框内，这样的话，才截取到完整的身份证图像。
 
 个人认为：有了文字、拍摄区域的提示，99%的用户会主动将身份证和拍摄框边缘对齐，就能够获得完整的身份证图像，不做人脸区域的检测也可以。。。
 
 ps: 如果你不想加入人脸识别这一功能，你的app无需这么精细的话或者你又想读取到身份证反面的信息（签发机关，有效期），请这样做：
 
 1、请注释掉所有metadataOutput的代码及其下面的那个代理方法（-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection）
 
 2、请在videoDataOutput的懒加载方法的if(_videoDataOutput == nil){}语句块中添加[_videoDataOutput setSampleBufferDelegate:self queue:self.queue];
 
 3、请注释掉AVCaptureVideoDataOutputSampleBufferDelegate下的那个代理方法中的
 if (self.videoDataOutput.sampleBufferDelegate) {
 [self.videoDataOutput setSampleBufferDelegate:nil queue:self.queue];
 }
 
 4、运行程序，身份证正反两面皆可被检测到，请查看打印的信息。
 
 */
//    [[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification* _Nonnull note) {
//        __weak __typeof__(self) weakSelf = self;
//        self.metadataOutput.rectOfInterest = [self.previewLayer metadataOutputRectOfInterestForRect:IDCardScaningView.facePathRect];
//    }];
