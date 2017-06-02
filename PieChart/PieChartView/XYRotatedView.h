//
//  XYRotatedView.h
//  PieChart
//
//  Created by GMY on 17/6/1.
//  Copyright © 2017年 com.gmy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYRenderView.h"

@class XYRotatedView;
@protocol RotatedViewDelegate <NSObject>

@optional
// 选中的回调
- (void)selectedFinish:(XYRotatedView *)rotatedView index:(NSInteger)index percent:(float)percent;
@end

@interface XYRotatedView : UIView<RenderViewDataSource,RenderViewtDelegate>

@property(nonatomic, assign) float mZeroAngle;

// 颜色数组
@property(nonatomic, strong) NSMutableArray *mColorArray;

// 百分比数组
@property(nonatomic, strong) NSMutableArray *percentArray;

// 角度数组
@property(nonatomic, strong) NSMutableArray *mThetaArray;

@property(nonatomic, assign) BOOL isAnimating;
@property(nonatomic, assign) BOOL isTapStopped;
@property(nonatomic, assign) BOOL isAutoRotation;

@property(nonatomic, assign) float mAbsoluteTheta;
@property(nonatomic, assign) float mRelativeTheta;

@property(nonatomic,retain) UITextView *mInfoTextView;

@property(nonatomic, assign) float mDragSpeed;
@property(nonatomic, strong) NSDate *mDragBeforeDate;
@property(nonatomic, assign) float mDragBeforeTheta;
@property(nonatomic, strong) NSTimer *mDecelerateTimer;

@property(nonatomic, assign) id<RotatedViewDelegate> delegate;

@property (nonatomic)float fracValue;

@property (nonatomic, assign) BOOL showPercent;

@property (nonatomic, assign) CGFloat checkLessPercent;

/**
 * 开始动画
 */
- (void)startedAnimate;

/**
 * 刷新pie
 */
- (void)reloadPie;

- (void)lessThanPercent:(CGFloat)lessThanPercent;
@end
