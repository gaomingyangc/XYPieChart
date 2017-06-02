//
//  XYCommon.h
//  PieChart
//
//  Created by GMY on 17/6/1.
//  Copyright © 2017年 com.gmy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define ScreenWidth [UIScreen mainScreen].bounds.size.width    //屏幕宽度
#define ScreenHeight [UIScreen mainScreen].bounds.size.height   //屏幕高度

/* 定义RGBCOLOR*/
#define ColorRGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]

@interface XYCommon : NSObject

UIKIT_EXTERN CGFloat const CenterTitleWidth;

UIKIT_EXTERN CGFloat const AmountWidth;

UIKIT_EXTERN CGFloat const AmountHeight;

@end
