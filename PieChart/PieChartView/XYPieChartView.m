//
//  XYPieChartView.m
//  PieChart
//
//  Created by GMY on 17/6/1.
//  Copyright © 2017年 com.gmy. All rights reserved.
//

#import "XYPieChartView.h"
#import "XYRotatedView.h"
#import "XYCommon.h"

@interface XYPieChartView()<RotatedViewDelegate>

// 旋转视图
@property (nonatomic,strong)XYRotatedView *rotatedView;

// 中心圆的按钮
@property (nonatomic,strong) UIButton *centerButton;

// 中心圆数值（总金额）
@property (nonatomic,strong) UILabel *centerAmount;

// 中心圆标题
@property (nonatomic, strong) UILabel *centerTitle;

// 数据数组
@property (nonatomic, strong) NSMutableArray *selectedTypeList;

@end

@implementation XYPieChartView

/**
 *
 * 初始化方法
 * param:{frame:位置, pieChartTypeArray:数据的数组, PercentArray:百分比数值 colorArr:颜色的数组}
 *
 */
- (id)initWithFrame:(CGRect)frame withPieChartTypeArray:(NSMutableArray *)pieChartTypeArray withPercentArray:(NSMutableArray *)percentArray withColorArray:(NSMutableArray *)colorArray
{
    
    if (self = [super initWithFrame:frame]) {
        
        self.selectedTypeList = pieChartTypeArray;
        
        // 初始化RotatedView
        self.rotatedView = [[XYRotatedView alloc]initWithFrame:self.bounds];
        
        // 给RotatedView 百分比数组赋值
        self.rotatedView.percentArray = percentArray;
        
        // 给RotatedView 颜色数组赋值
        self.rotatedView.mColorArray = colorArray;
        
        // 接收代理方法
        self.rotatedView.delegate = self;
        
        // 添加RotatedView
        [self addSubview:self.rotatedView];
        
        // 初始化中心圆按钮
        self.centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        // 移除点击事件
        [self.centerButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        
        // 是否接收事件
        self.centerButton.userInteractionEnabled = YES;
        
        // 设置按钮点击事件
        [self.centerButton addTarget:self action:@selector(changeInOut:) forControlEvents:UIControlEventTouchUpInside];
        
        // 中心圆图片
        UIImage *centerImage = [UIImage imageNamed:@"center_white"];
        
        // 图片尺寸
        CGSize centerImageSize = centerImage.size;
        
        if (centerImageSize.height == 0 && centerImageSize.width == 0) {
            
            // 如果图片尺寸为0，默认赋值width = 80, Height = 80
            centerImageSize = CGSizeMake(80, 80);
        }
        
        // 设置按钮普通状态下的背景图片
        [self.centerButton setBackgroundImage:centerImage forState:UIControlStateNormal];
        
        // 设置按钮高亮状态下的背景图片
        [self.centerButton setBackgroundImage:centerImage forState:UIControlStateHighlighted];
        
        // 设置按钮位置、尺寸 （frame）
        self.centerButton.frame = CGRectMake((frame.size.width - centerImageSize.width/2)/2, (frame.size.height - centerImageSize.height/2)/2, centerImageSize.width/2, centerImageSize.height/2);
        
        [self.centerButton.layer setMasksToBounds:YES];
        
        // 将按钮设置成圆形
        [self.centerButton.layer setCornerRadius:self.centerButton.frame.size.width/2];
        
        
        /** 中心圆上展示的标题和总金额 **/
        
        // 标题宽
        CGFloat centerTitleWidth = CenterTitleWidth;
        
        // 标题高
        CGFloat centerTitleHeight = CenterTitleWidth;
        
        // 设置标题位置
        self.centerTitle = [[UILabel alloc]initWithFrame:CGRectMake((centerImageSize.width/2 - centerTitleWidth)/2, (centerImageSize.height/2 - 75)/2, centerTitleWidth, centerTitleHeight)];
        
        // 标题背景色
        self.centerTitle.backgroundColor = [UIColor clearColor];
        
        // 字体居中
        self.centerTitle.textAlignment = NSTextAlignmentCenter;
        
        // 字体大小
        self.centerTitle.font = [UIFont systemFontOfSize:16];
        
        self.centerTitle.numberOfLines = 2;
        
        // 字体颜色
        self.centerTitle.textColor = [UIColor blackColor];
        
        // 添加标题
        [self.centerButton addSubview:self.centerTitle];
        
        /** 总金额 **/
        
        // 金额宽度
        CGFloat amountWidth = AmountWidth;
        
        // 金额宽度
        CGFloat amountHeight = AmountHeight;
        
        // 初始化金额Label 设置位置、大小
        self.centerAmount = [[UILabel alloc]initWithFrame:CGRectMake((centerImageSize.width/2 - amountWidth)/2, 53, amountWidth, amountHeight)];
        
        // 金额背景色
        self.centerAmount.backgroundColor = [UIColor clearColor];
        
        // 字体居中
        self.centerAmount.textAlignment = NSTextAlignmentCenter;
        
        // 字体大小
        self.centerAmount.font = [UIFont boldSystemFontOfSize:21];
        
        // 字体颜色
        self.centerAmount.textColor = [UIColor blackColor];
        
        // 字体大小宽度自适应
        [self.centerAmount setAdjustsFontSizeToFitWidth:YES];
        
        // 添加金额Label
        [self.centerButton addSubview:self.centerAmount];
        
        // 添加中心圆的按钮
        [self addSubview:self.centerButton];
        
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

/**
 * 按钮点击范围的方法
 */
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    
    //首先调用父类的方法确定点击的区域确实在按钮的区域中
    BOOL res = [super pointInside:point withEvent:event];
    if (res) {
        //绘制一个圆形path
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:self.centerButton.frame];
        if ([path containsPoint:point]) {
            //如果在path区域内，可以接收交互事件，从而截获父视图的点击事件
            self.centerButton.userInteractionEnabled = YES;
            return YES;
            
        } else {
            
            //如果不在path区域内，不可以接收交互事件，从而将事件传给父视图接收
            self.centerButton.userInteractionEnabled = NO;
            return YES;
        }
        
    }
    return NO;
}
/**
 * 中心圆按钮的点击事件
 */
- (void)changeInOut:(id)sender {
    // 触发点击回调方法
    if ([self.delegate respondsToSelector:@selector(onCenterClick:)]) {
        [self.delegate onCenterClick:self];
    }
}

/**
 * 设置标中心圆标题
 */
- (void)setTitleText:(NSMutableAttributedString *)text {
    [self.centerTitle setAttributedText:text];
}

/**
 * 设置标中心圆金额
 */
- (void)setAmountText:(NSString *)text {
    [self.centerAmount setText:text];
}

- (void)setCheckLessThanPercent:(CGFloat)lessPerent {

    [self.rotatedView lessThanPercent:lessPerent];
}
/**
 * 刷新PiaChart视图
 */
- (void)reloadChart {
    [self.rotatedView reloadPie];
}

/**
 * RotatedView 选中视图的delegate方法
 */
- (void)selectedFinish:(XYRotatedView *)rotatedView index:(NSInteger)index percent:(float)per {
    // 触发本视图的delegate方法
    if ([self.delegate respondsToSelector:@selector(selectedFinish:index:selectedType: )]) {
        
        [self.delegate selectedFinish:self index:index selectedType:self.selectedTypeList[index]];
    }
    
}

@end
