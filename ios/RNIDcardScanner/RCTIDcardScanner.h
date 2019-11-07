//
//  RNIDcardScanner.h
//  RNIDcardScanner
//
//  Created by rain on 2019/10/31.
//  Copyright © 2019年 com.rainy.osource. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "RCTIDCardScannerManager.h"

@interface RCTIDcardScanner : UIView

@property (nonatomic,assign) CGRect facePathRect;
@property (nonatomic, copy) RCTBubblingEventBlock onIDScannerResult;
@property (nonatomic, assign) BOOL isAutoReg;
@property (nonatomic, assign) NSInteger scannerRectWidth;
//@property (nonatomic, assign) NSInteger scannerRectHeight;
@property (nonatomic, assign) NSInteger scannerRectTop;
//@property (nonatomic, assign) NSInteger scannerRectLeft;
//@property (nonatomic, assign) NSInteger scannerLineInterval;
@property (nonatomic, assign) NSInteger scannerRectCornerRadius;
@property (nonatomic, assign) NSInteger scannerRectBorderWidth;
@property (nonatomic, copy) NSString *scannerRectColor;

-(id)initWithManager:(RCTIDCardScannerManager *) manager;

@end
