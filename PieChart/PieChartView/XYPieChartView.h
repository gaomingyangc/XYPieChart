//
//  XYPieChartView.h
//  PieChart
//
//  Created by GMY on 17/6/1.
//  Copyright © 2017年 com.gmy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XYPieChartView;
@protocol PieChartDelegate <NSObject>

@required
/**
 * 选中扇形的回调数据
 */
- (void)selectedFinish:(XYPieChartView *)pieChartView index:(NSInteger)index selectedType:(NSDictionary *)selectedType;

@optional
/**
 * 点击中心按钮的回调
 */
- (void)onCenterClick:(XYPieChartView *)PieChartView;

@end

@interface XYPieChartView : UIView

@property (nonatomic, assign) id<PieChartDelegate> delegate;

/**
 * param:{frame:位置, AssetTypeArray:数据的数组, PercentArray:百分比数值 colorArr:颜色的数组}
 */
- (id)initWithFrame:(CGRect)frame withPieChartTypeArray:(NSMutableArray *)pieChartTypeArray withPercentArray:(NSMutableArray *)percentArray withColorArray:(NSMutableArray *)colorArray;

/**
 * 总标题信息
 */
- (void)setAmountText:(NSString *)text;

/**
 * 总金额 
 */
- (void)setTitleText:(NSMutableAttributedString *)text;

/**
 * 刷新chart
 */
- (void)reloadChart;

/**
 * 校验小于百分比时，另外的展现形式
 */
- (void)setCheckLessThanPercent:(CGFloat)lessPerent;
@end
