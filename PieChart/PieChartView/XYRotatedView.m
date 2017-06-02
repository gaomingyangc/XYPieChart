//
//  XYRotatedView.m
//  PieChart
//
//  Created by GMY on 17/6/1.
//  Copyright © 2017年 com.gmy. All rights reserved.
//

#import "XYRotatedView.h"
#import "XYRenderView.h"
#import <QuartzCore/QuartzCore.h>
#include <math.h>

#define K_EPSINON        (1e-127)
#define IS_ZERO_FLOAT(X) (X < K_EPSINON && X > -K_EPSINON)
#define K_MAX_SPEED             12.0f
#define K_POINTER_ANGLE         (M_PI / 2)

@interface XYRotatedView()

@property (nonatomic,assign) NSInteger selectedIndex;

@property (strong, nonatomic) XYRenderView *pieChart;

@property (nonatomic, assign) BOOL canLayerOpen;

@end

@implementation XYRotatedView

/**
 * RotatedView 初始化
 */
- (id)initWithFrame:(CGRect)frame {
    
    if ((self = [super initWithFrame:frame])) {
        
        // 视图背景色
        self.backgroundColor = [UIColor clearColor];
        
        _mRelativeTheta = 0.0;
        
        // 动画是否开始
        _isAnimating = NO;
        
        // 点击是否结束
        _isTapStopped = NO;
        
        // 环形图初始化 位置\尺寸
        self.pieChart = [[XYRenderView alloc]initWithFrame:frame];
        
        // 环形图数据源方法
        self.pieChart.dataSource = self;
        
        // 环形图代理方法
        self.pieChart.delegate = self;
        
        // 开始的角度
        [self.pieChart setStartPieAngle:0];
        
        // 绘制环形图所需的动画时间
        [self.pieChart setAnimationSpeed:1.0];
        
        // 环状图上Label（百分比）所处的半径
        CGFloat radius = frame.size.width * 0.4;
        
        [self.pieChart setLabelRadius:radius];
        
        // 环形图上标题的字体大小
        [self.pieChart setLabelFont:[UIFont fontWithName:@"DBLCDTempBlack" size:15]];
        
        // 环形图中心点
        [self.pieChart setPieCenter:CGPointMake(frame.size.width/2, frame.size.height/2)];
        
        // 环形图是否接受触摸事件
        [self.pieChart setUserInteractionEnabled:NO];
        
        // 添加pieChart
        [self addSubview:self.pieChart];
    }
    
    return self;
}

/**
 * 刷新视图方法
 */
- (void)reloadPie {
    _isAutoRotation = YES;
    
    // 调用渲染视图的数据刷新方法
    [self.pieChart reloadData];
}

- (void)lessThanPercent:(CGFloat)lessThanPercent {

    // 校验最小百分比
    [self.pieChart checkLessPercent:lessThanPercent];
}
/**
 * 系统绘画方法
 */
- (void)drawRect:(CGRect)rect {
    
    NSInteger wedges = [_percentArray count];
    if (wedges > [_mColorArray count]) {
        
        for (NSInteger i= _mColorArray.count; i<wedges; ++i) {
            [_mColorArray addObject:[UIColor whiteColor]];
        }
    }
    
    _mThetaArray = [[NSMutableArray alloc] initWithCapacity:wedges];
    
    float sum = 0.0;
    for (int i = 0; i < wedges; ++i) {
        sum += [[_percentArray objectAtIndex:i] floatValue];
    }
    
    float frac = 2.0 * M_PI / sum;
    self.fracValue = frac;
    
//    float startAngle = _mZeroAngle;
    float endAngle   = _mZeroAngle;
    for (int i = 0; i < wedges; ++i) {
        
//        startAngle = endAngle;
        endAngle  += [[_percentArray objectAtIndex:i] floatValue] * frac;
        [_mThetaArray addObject:[NSNumber numberWithFloat:endAngle]];
    }
}


- (void)startedAnimate {
    [self performSelector:@selector(delayAnimate) withObject:nil afterDelay:0.0f];
}

#pragma mark -
#pragma mark handle rotation angle
- (float)thetaForX:(float)x andY:(float)y {
    if (IS_ZERO_FLOAT(y)) {
        if (x < 0) {
            return M_PI;
        } else {
            return 0;
        }
    }
    
    float theta = atan(y / x);
    if (x < 0 && y > 0) {
        theta = M_PI + theta;
    } else if (x < 0 && y < 0) {
        theta = M_PI + theta;
    } else if (x > 0 && y < 0) {
        theta = 2 * M_PI + theta;
    }
    return theta;
}

/* 计算将当前以相对角度为单位的触摸点旋转到绝对角度为newTheta的位置所需要旋转到的角度 */
- (float)rotationThetaForNewTheta:(float)newTheta {
    float rotationTheta;
    if (_mRelativeTheta > (3 * M_PI / 2) && (newTheta < M_PI / 2)) {
        rotationTheta = newTheta + (2 * M_PI - _mRelativeTheta);
    } else {
        rotationTheta = newTheta - _mRelativeTheta;
    }
    // 返回最后旋转的角度
    return rotationTheta;
}

- (float)thetaForTouch:(UITouch *)touch onView:view {
    CGPoint location = [touch locationInView:view];
    float xOffset    = self.bounds.size.width / 2;
    float yOffset    = self.bounds.size.height / 2;
    float centeredX  = location.x - xOffset;
    float centeredY  = location.y - yOffset;
    
    return [self thetaForX:centeredX andY:centeredY];
}

#pragma mark -
#pragma mark Private & handle rotation
- (void)timerStop {
    [_mDecelerateTimer invalidate];
    _mDecelerateTimer = nil;
    _mDragSpeed = 0;
    _isAnimating = NO;
    
    [self performSelector:@selector(delayAnimate) withObject:nil afterDelay:0.0f];
    return;
}

- (void)delayAnimate {
    double tan2 = atan2(self.transform.b, self.transform.a);
    
    //根据旋转角度判断当前在那个扇区中
    float curTheta = M_PI/2 - tan2;
    curTheta = curTheta > 0?curTheta:M_PI*2+curTheta;
    int selIndex = 0;
    for (;selIndex < [_mThetaArray count]; selIndex++) {
        if (curTheta < [[_mThetaArray objectAtIndex:selIndex] floatValue]) {
            break;
        }
    }
    
    //根据当前旋转弧度和选中扇区的起止弧度，判断居中需要旋转的弧度
    float calTheta = [[_mThetaArray objectAtIndex:selIndex] floatValue] - curTheta;
    float fanTheta = [[_percentArray objectAtIndex:selIndex] floatValue] * self.fracValue;
    float rotateTheta = fanTheta/2 - calTheta;
    
    //设置动画 选中后扇形外滑的动画
    [UIView animateWithDuration:0.42 animations:^{
        
        self.transform = CGAffineTransformRotate(self.transform,rotateTheta);
        self.pieChart.textAngle = rotateTheta;
        
    } completion:^(BOOL finished) {
        
            [self outPie];
    }];
    
        [self delayAnimateStop:selIndex];
}

- (void)outPie {
    [self.pieChart pieSelected:self.selectedIndex];
    self.canLayerOpen = YES;
}

- (void)delayAnimateStop:(NSInteger)index {
    float sum = 0.0;
    for (int i = 0; i < [_percentArray count]; ++i) {
        sum += [[_percentArray objectAtIndex:i] floatValue];
    }
    float percent = [[_percentArray objectAtIndex:index] floatValue]/sum;
    self.selectedIndex = index;
    
    if ([self.delegate respondsToSelector:@selector(selectedFinish:index:percent:)]) {
        [self.delegate selectedFinish:self index:index percent:percent];
    }
}

- (void)animationDidStop:(NSString*)str finished:(NSNumber*)flag context:(void*)context {
    _isAutoRotation = NO;
    [self delayAnimate];
}

- (int)touchIndex {
    int index;
    
    for (index = 0; index < [_mThetaArray count]; index++) {
        if (_mRelativeTheta < [[_mThetaArray objectAtIndex:index] floatValue]) {
            break;
        }
    }
    
    return index;
}

#pragma mark - 点击结束，触发旋转方法
- (void)tapStopped {
    int tapAreaIndex = [self touchIndex];
    
    if (tapAreaIndex == 0) {
        _mRelativeTheta = [[_mThetaArray objectAtIndex:0] floatValue] / 2;
    } else {
        _mRelativeTheta = [[_mThetaArray objectAtIndex:tapAreaIndex] floatValue]
        - (([[_mThetaArray objectAtIndex:tapAreaIndex] floatValue]
            - [[_mThetaArray objectAtIndex:tapAreaIndex - 1] floatValue]) / 2);
    }
    self.pieChart.textrelativeTheta = _mRelativeTheta;
    if (tapAreaIndex != self.selectedIndex) {
        if (self.canLayerOpen) {
            [self.pieChart pieSelected:self.selectedIndex];
            self.canLayerOpen = NO;
        }
        _isAutoRotation = YES;
        [UIView beginAnimations:@"tap stopped" context:nil];
        
#pragma mark- 点击旋转速度
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        self.pieChart.textAngle = [self rotationThetaForNewTheta:K_POINTER_ANGLE];
        self.transform = CGAffineTransformMakeRotation([self rotationThetaForNewTheta:K_POINTER_ANGLE]);
        [UIView commitAnimations];
    }
    
    return;
}

#pragma mark -
#pragma mark Responder
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (_isAutoRotation) {
        return;
    }
    
    _isTapStopped = IS_ZERO_FLOAT(_mDragSpeed);
    
    if ([_mDecelerateTimer isValid]) {
        [_mDecelerateTimer invalidate];
        _mDecelerateTimer = nil;
        _mDragSpeed = 0;
        _isAnimating = NO;
    }
    
    UITouch *touch   = [touches anyObject];
    _mAbsoluteTheta   = [self thetaForTouch:touch onView:self.superview];
    _mRelativeTheta   = [self thetaForTouch:touch onView:self];
    _mDragBeforeDate  = [NSDate date];
    _mDragBeforeTheta = 0.0f;
    
    return;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_isAutoRotation) {
        return;
    }
    
    if (IS_ZERO_FLOAT(_mDragSpeed)) {
        if (_isTapStopped) {
            [self tapStopped];
            return;
        } else {
            [self delayAnimate];
            return;
        }
    } else if ((fabsf(_mDragSpeed) > K_MAX_SPEED)) {
        _mDragSpeed = (_mDragSpeed > 0) ? K_MAX_SPEED : -K_MAX_SPEED;
    }

}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

#pragma -mark xypieSource
- (NSUInteger)numberOfSlicesInPieChart:(XYRenderView *)pieChart {
    return [_percentArray count];
}

- (CGFloat)pieChart:(XYRenderView *)pieChart valueForSliceAtIndex:(NSUInteger)index {
    return [[_percentArray objectAtIndex:index] floatValue];
}

- (UIColor *)pieChart:(XYRenderView *)pieChart colorForSliceAtIndex:(NSUInteger)index {
    return [_mColorArray objectAtIndex:index];
}

- (void)animateFinish:(XYRenderView *)pieChart {
    _isAutoRotation = NO;
    [self startedAnimate];
}

@end
