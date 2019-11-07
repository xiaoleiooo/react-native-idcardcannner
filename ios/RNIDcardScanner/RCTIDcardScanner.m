//
//  RNIDcardScanner.m
//  RNIDcardScanner
//
//  Created by rain on 2019/10/31.
//  Copyright © 2019年 com.rainy.osource. All rights reserved.
//

#import "RCTIDcardScanner.h"
#import "UIColor+Hex.h"

// iPhone5/5c/5s/SE 4英寸 屏幕宽高：320*568点 屏幕模式：2x 分辨率：1136*640像素
#define iPhone5or5cor5sorSE ([UIScreen mainScreen].bounds.size.height == 568.0)

// iPhone6/6s/7/8 4.7英寸 屏幕宽高：375*667点 屏幕模式：2x 分辨率：1334*750像素
#define iPhone6or6sor7 ([UIScreen mainScreen].bounds.size.height == 667.0)

// iPhone6 Plus/6s Plus/7 Plus/8 Plus 5.5英寸 屏幕宽高：414*736点 屏幕模式：3x 分辨率：1920*1080像素
#define iPhone6Plusor6sPlusor7Plus ([UIScreen mainScreen].bounds.size.height == 736.0)

// iPhoneX/XS/11pro 5.8英寸 屏幕宽高：375x812点 屏幕模式：3x 分辨率：1125x2436像素
#define iPhoneXorXSor11Pro ([UIScreen mainScreen].bounds.size.height == 812.0)

// iPhoneXS Max/XR/11/11 Pro Max 6.5or5.1英寸 屏幕宽高：414x896点 屏幕模式：3x or 2x 分辨率：1242x2688 or 828x1792像素
#define iPhoneXSMaxorXRor11or11prox ([UIScreen mainScreen].bounds.size.height == 812.0)

// iPhoneXS Max/XR/11 6.5or5.1英寸 屏幕宽高：414x896点 屏幕模式：3x or 2x 分辨率：1242x2688 or 828x1792像素
#define iPhoneXSMaxorXRor11 ([UIScreen mainScreen].bounds.size.height == 812.0)

@interface RCTIDcardScanner(){
    CAShapeLayer *_IDCardScanningWindowLayer;
    NSTimer *_timer;
}

@property (nonatomic, weak) RCTIDCardScannerManager *manager;

@end

@implementation RCTIDcardScanner

-(id)initWithManager:(RCTIDCardScannerManager *)manager{
    if ((self = [super init])) {
        //NSLog(@"aaa %@",NSStringFromSelector(_cmd));
        self.manager = manager;
    }
    return self;
}


#pragma mark - 添加扫描窗口
-(void)addScaningWindow {
    // 中间包裹线
    _IDCardScanningWindowLayer = [CAShapeLayer layer];
    _IDCardScanningWindowLayer.position = self.layer.position;
    NSLog(@"viewPar :%f,  %ld",_IDCardScanningWindowLayer.position.x,_scannerRectTop);
    NSLog(@"viewPar 1 frame:%@========view1 bounds:%@",NSStringFromCGRect(_IDCardScanningWindowLayer.frame),NSStringFromCGRect(_IDCardScanningWindowLayer.bounds));
    
//    _IDCardScanningWindowLayer.position  = CGPointMake(_IDCardScanningWindowLayer.position.x, _scannerRectTop);
    CGFloat width = iPhone5or5cor5sorSE? 240: (iPhone6or6sor7? 270: 300);//self.scannerRectWidth; //
    _IDCardScanningWindowLayer.bounds = (CGRect){CGPointZero, {width, width * 1.574}};
    
    UIColor *cornerLineColor = [UIColor colorWithHexString:self.scannerRectColor];
    
    _IDCardScanningWindowLayer.cornerRadius = self.scannerRectCornerRadius;
    _IDCardScanningWindowLayer.borderColor = cornerLineColor.CGColor;//[UIColor whiteColor].CGColor;
    _IDCardScanningWindowLayer.borderWidth = self.scannerRectBorderWidth;
    
    NSLog(@"viewPar 2 frame:%@========view1 bounds:%@",NSStringFromCGRect(_IDCardScanningWindowLayer.frame),NSStringFromCGRect(_IDCardScanningWindowLayer.bounds));
    
    [_IDCardScanningWindowLayer setFrame:CGRectMake(_IDCardScanningWindowLayer.frame.origin.x, _scannerRectTop, _IDCardScanningWindowLayer.frame.size.width, _IDCardScanningWindowLayer.frame.size.height)];
    
    NSLog(@"viewPar 3 frame:%@========view1 bounds:%@",NSStringFromCGRect(_IDCardScanningWindowLayer.frame),NSStringFromCGRect(_IDCardScanningWindowLayer.bounds));

    [self.layer addSublayer:_IDCardScanningWindowLayer];
    
    // 最里层镂空
    UIBezierPath *transparentRoundedRectPath = [UIBezierPath bezierPathWithRoundedRect:_IDCardScanningWindowLayer.frame cornerRadius:_IDCardScanningWindowLayer.cornerRadius];
    
    // 最外层背景
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.frame];
    [path appendPath:transparentRoundedRectPath];
    [path setUsesEvenOddFillRule:YES];
    
    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.fillColor = [UIColor blackColor].CGColor;
    fillLayer.opacity = 0.6;
    
    [self.layer addSublayer:fillLayer];
    
    CGFloat facePathWidth = iPhone5or5cor5sorSE? 125: (iPhone6or6sor7? 150: 180);
    CGFloat facePathHeight = facePathWidth * 0.812;
    CGRect rect = _IDCardScanningWindowLayer.frame;
    self.facePathRect = (CGRect){CGRectGetMaxX(rect) - facePathWidth - 35,CGRectGetMaxY(rect) - facePathHeight - 25,facePathWidth,facePathHeight};
    
    // 提示标签
    CGPoint center = self.center;
    center.x = CGRectGetMaxX(_IDCardScanningWindowLayer.frame) + 20;
    [self addTipLabelWithText:@"将身份证人像面置于此区域内，头像对准，扫描" center:center];
    
    // 人像
    UIImageView *headIV = [[UIImageView alloc] initWithFrame:_facePathRect];
    headIV.image = [UIImage imageNamed:@"idcard_front_head"];
    headIV.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    headIV.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:headIV];
}

#pragma mark - 添加提示标签
-(void )addTipLabelWithText:(NSString *)text center:(CGPoint)center {
    UILabel *tipLabel = [[UILabel alloc] init];
    
    tipLabel.text = text;
    tipLabel.textColor = [UIColor whiteColor];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    
    tipLabel.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    [tipLabel sizeToFit];
    
    tipLabel.center = center;
    
    [self addSubview:tipLabel];
}

#pragma mark - 添加定时器
-(void)addTimer {
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
    [_timer fire];
}

-(void)timerFire:(id)notice {
    [self setNeedsDisplay];
}

-(void)dealloc {
    [_timer invalidate];
}

- (void)drawRect:(CGRect)rect {
    rect = _IDCardScanningWindowLayer.frame;
    
    // 人像提示框
    UIBezierPath *facePath = [UIBezierPath bezierPathWithRect:_facePathRect];
    facePath.lineWidth = 1.5;
    [[UIColor whiteColor] set];
    [facePath stroke];
    
    // 水平扫描线
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    static CGFloat moveX = 0;
    static CGFloat distanceX = 0;
    
    CGContextBeginPath(context);
    CGContextSetLineWidth(context, 2);
    CGContextSetRGBStrokeColor(context,0.3,0.8,0.3,0.8);
    CGPoint p1, p2;// p1, p2 连成水平扫描线;
    
    moveX += distanceX;
    if (moveX >= CGRectGetWidth(rect) - 2) {
        distanceX = -2;
    } else if (moveX <= 2){
        distanceX = 2;
    }
    
    p1 = CGPointMake(CGRectGetMaxX(rect) - moveX, rect.origin.y);
    p2 = CGPointMake(CGRectGetMaxX(rect) - moveX, rect.origin.y + rect.size.height);
    
    CGContextMoveToPoint(context,p1.x, p1.y);
    CGContextAddLineToPoint(context, p2.x, p2.y);
    
    /*
     // 竖直扫描线
     static CGFloat moveY = 0;
     static CGFloat distanceY = 0;
     CGPoint p3, p4;// p3, p4连成竖直扫描线
     
     moveY += distanceY;
     if (moveY >= CGRectGetHeight(rect) - 2) {
     distanceY = -2;
     } else if (moveY <= 2) {
     distanceY = 2;
     }
     p3 = CGPointMake(rect.origin.x, rect.origin.y + moveY);
     p4 = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + moveY);
     
     CGContextMoveToPoint(context,p3.x, p3.y);
     CGContextAddLineToPoint(context, p4.x, p4.y);
     */
    
    CGContextStrokePath(context);
}


-(void)layoutSubviews {
    //NSLog(@"aaa %@",NSStringFromSelector(_cmd));
    [super layoutSubviews];
//     [self.manager startSession];
    self.manager.previewLayer.frame = self.bounds;
    NSLog(@"viewPar layoutSubviews,frame:%@   bounds：%@",NSStringFromCGRect(self.frame),NSStringFromCGRect(self.bounds));

//    self.manager.previewLayer.transform = CATransform3DScale(self.manager.previewLayer.transform, 1.5, 1.5, 1);
    self.manager.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.layer insertSublayer:self.manager.previewLayer atIndex:0];

    self.backgroundColor = [UIColor clearColor];
    // 添加扫描窗口
    [self addScaningWindow];
    // 添加定时器
    [self addTimer];
    
    self.manager.faceDetectionFrame = self.facePathRect;
}

-(void)removeFromSuperview{
    //NSLog(@"aaa %@",NSStringFromSelector(_cmd));
    [self.manager endSession];
    [super removeFromSuperview];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//    [[UIColor colorWithWhite:0 alpha:0.7] setFill];
//    // 半透明区域
//    UIRectFill(rect);
//
//    // 透明区域
//    CGRect holeRection = self.layer.sublayers[0].frame;
//    /** union: 并集
//     CGRect CGRectUnion(CGRect r1, CGRect r2)
//     返回并集部分rect
//     */
//
//    /** Intersection: 交集
//     CGRect CGRectIntersection(CGRect r1, CGRect r2)
//     返回交集部分rect
//     */
//    CGRect holeiInterSection = CGRectIntersection(holeRection, rect);
//    [[UIColor clearColor] setFill];
//
//    //CGContextClearRect(ctx, <#CGRect rect#>)
//    //绘制
//    //CGContextDrawPath(ctx, kCGPathFillStroke);
//    UIRectFill(holeiInterSection);
//}


@end
