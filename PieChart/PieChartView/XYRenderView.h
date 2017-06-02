//
//  XYRenderView.h
//  PieChart
//
//  Created by GMY on 17/6/1.
//  Copyright © 2017年 com.gmy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XYRenderView;

@protocol RenderViewDataSource <NSObject>

@required

// 数据源方法 饼图共有几个区域
- (NSUInteger)numberOfSlicesInPieChart:(XYRenderView *)pieChart;

// 选中的区域索引
- (CGFloat)pieChart:(XYRenderView *)pieChart valueForSliceAtIndex:(NSUInteger)index;

@optional
// 选中的区域颜色
- (UIColor *)pieChart:(XYRenderView *)pieChart colorForSliceAtIndex:(NSUInteger)index;

@end

@protocol RenderViewtDelegate <NSObject>

@optional

// will Select
- (void)pieChart:(XYRenderView *)pieChart willSelectSliceAtIndex:(NSUInteger)index;

// did Select
- (void)pieChart:(XYRenderView *)pieChart didSelectSliceAtIndex:(NSUInteger)index;

// will Deselect
- (void)pieChart:(XYRenderView *)pieChart willDeselectSliceAtIndex:(NSUInteger)index;

// did Deselect
- (void)pieChart:(XYRenderView *)pieChart didDeselectSliceAtIndex:(NSUInteger)index;

// 动画结束
- (void)animateFinish:(XYRenderView *)pieChart;

@end

@interface XYRenderView : UIView

@property(nonatomic, weak) id<RenderViewDataSource> dataSource;

@property(nonatomic, weak) id<RenderViewtDelegate> delegate;

@property(nonatomic, assign) CGFloat startPieAngle;

@property(nonatomic, assign) CGFloat animationSpeed;

@property(nonatomic, assign) CGPoint pieCenter;

@property(nonatomic, assign) CGFloat pieRadius;

@property(nonatomic, assign) BOOL showLabel;

@property(nonatomic, strong) UIFont *labelFont;

@property(nonatomic, assign) CGFloat labelRadius;

@property(nonatomic, assign) CGFloat selectedSliceStroke;

@property(nonatomic, assign) CGFloat selectedSliceOffsetRadius;

@property(nonatomic, assign) BOOL showPercentage;

@property (strong, nonatomic) NSMutableArray *textLayerArray;

@property (nonatomic, assign) CGFloat textAngle;

@property (nonatomic, assign) CGFloat textrelativeTheta;

@property (nonatomic, strong) CATextLayer *textLayer;

@property (nonatomic, strong) CALayer *lineLayer;

@property (nonatomic, assign) CGFloat checkLessPercent;

- (id)initWithFrame:(CGRect)frame Center:(CGPoint)center Radius:(CGFloat)radius;

- (void)reloadData;

- (void)setPieBackgroundColor:(UIColor *)color;

- (void)pieSelected:(NSInteger)selIndex;

- (void)checkLessPercent:(CGFloat)lessPercent;
@end
