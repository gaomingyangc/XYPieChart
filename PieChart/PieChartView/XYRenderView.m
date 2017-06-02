//
//  XYRenderView.m
//  PieChart
//
//  Created by GMY on 17/6/1.
//  Copyright © 2017年 com.gmy. All rights reserved.
//

#import "XYRenderView.h"
#import <QuartzCore/QuartzCore.h>
#import "XYCommon.h"

@interface SliceLayer : CAShapeLayer

@property (nonatomic, assign) CGFloat value;

@property (nonatomic, assign) CGFloat percentage;

@property (nonatomic, assign) double startAngle;

@property (nonatomic, assign) double endAngle;

@property (nonatomic, assign) BOOL isSelected;

- (void)createArcAnimationForKey:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to Delegate:(id)delegate;

@end

@implementation SliceLayer

- (NSString*)description {
    return @"";
}

+ (BOOL)needsDisplayForKey:(NSString *)key {
    if ([key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"]) {
        return YES;
    }
    else {
        return [super needsDisplayForKey:key];
    }
}

- (id)initWithLayer:(id)layer {
    if (self = [super initWithLayer:layer])
    {
        if ([layer isKindOfClass:[SliceLayer class]]) {
            self.startAngle = [(SliceLayer *)layer startAngle];
            self.endAngle = [(SliceLayer *)layer endAngle];
        }
    }
    return self;
}

- (void)createArcAnimationForKey:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to Delegate:(id)delegate {
    CABasicAnimation *arcAnimation = [CABasicAnimation animationWithKeyPath:key];
    
    NSNumber *currentAngle = [[self presentationLayer] valueForKey:key];
    
    if(!currentAngle) currentAngle = from;
    
    [arcAnimation setFromValue:currentAngle];
    
    [arcAnimation setToValue:to];
    
    [arcAnimation setDelegate:delegate];
    
    [arcAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
    
    [self addAnimation:arcAnimation forKey:key];
    
    [self setValue:to forKey:key];
}

@end

@interface XYRenderView ()

- (void)updateTimerFired:(NSTimer *)timer;

- (SliceLayer *)createSliceLayer;

- (void)updateLabelForLayer:(SliceLayer *)pieLayer value:(CGFloat)value;

- (void)notifyDelegateOfSelectionChangeFrom:(NSUInteger)previousSelection to:(NSUInteger)newSelection;

@end

@implementation XYRenderView
{
    NSInteger _selectedSliceIndex;
    //pie view, contains all slices
    UIView  *_pieView;
    
    //animation control
    NSTimer *_animationTimer;
    
    NSMutableArray *_animations;
    
}
static NSUInteger kDefaultSliceZOrder = 100;

static CGPathRef CGPathCreateArc(CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat endAngle) {
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, center.x, center.y);
    
    CGPathAddArc(path, NULL, center.x, center.y, radius, startAngle, endAngle, 0);
    
    CGPathCloseSubpath(path);
    
    return path;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor clearColor];
        
        _pieView = [[UIView alloc] initWithFrame:frame];
        
        [_pieView setBackgroundColor:[UIColor clearColor]];
        
        [self addSubview:_pieView];
        
        _selectedSliceIndex = -1;
        
        _animations = [[NSMutableArray alloc] init];
        
        _animationSpeed = 0.5;
        
        _startPieAngle = M_PI_2*3;
        
        _selectedSliceStroke = 3.0;
        
        self.pieRadius = MIN(frame.size.width/2, frame.size.height/2);
        
        self.pieCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
        
        self.labelFont = [UIFont boldSystemFontOfSize:MAX((int)self.pieRadius/10, 5)];
        
        _labelRadius = _pieRadius/2;
        
        _selectedSliceOffsetRadius = MAX(10, _pieRadius/10);
        
        _showLabel = YES;
        
        _showPercentage = YES;
        
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame Center:(CGPoint)center Radius:(CGFloat)radius {
    if (self = [super initWithFrame:frame]) {
        self.pieCenter = center;
        self.pieRadius = radius;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        _pieView = [[UIView alloc] initWithFrame:self.bounds];
        [_pieView setBackgroundColor:[UIColor clearColor]];
        [self insertSubview:_pieView atIndex:0];
        
        _selectedSliceIndex = -1;
        _animations = [[NSMutableArray alloc] init];
        
        _animationSpeed = 0.5;
        _startPieAngle = M_PI_2*3;
        _selectedSliceStroke = 3.0;
        
        CGRect bounds = [[self layer] bounds];
        self.pieRadius = MIN(bounds.size.width/2, bounds.size.height/2) - 10;
        self.pieCenter = CGPointMake(bounds.size.width/2, bounds.size.height/2);
        self.labelFont = [UIFont boldSystemFontOfSize:MAX((int)self.pieRadius/10, 5)];
        _labelRadius = _pieRadius/2;
        _selectedSliceOffsetRadius = MAX(10, _pieRadius/10);
        
        _showLabel = YES;
        _showPercentage = YES;
        
    }
    return self;
}

- (void)setPieCenter:(CGPoint)pieCenter {
    [_pieView setCenter:pieCenter];
    
    _pieCenter = CGPointMake(_pieView.frame.size.width/2, _pieView.frame.size.height/2);
}

- (void)setPieRadius:(CGFloat)pieRadius {
    _pieRadius = pieRadius;
    
    CGRect frame = CGRectMake(_pieCenter.x-pieRadius, _pieCenter.y-pieRadius, pieRadius*2, pieRadius*2);
    
    _pieCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
    
    [_pieView setFrame:frame];
    
    [_pieView.layer setCornerRadius:_pieRadius];
}

- (void)setPieBackgroundColor:(UIColor *)color {
    [_pieView setBackgroundColor:color];
}

#pragma mark - manage settings
#pragma mark 显示扇形百分比
- (void)setShowPercentage:(BOOL)showPercentage {
    _showPercentage = showPercentage;
    
    for(SliceLayer *layer in _pieView.layer.sublayers)
    {
        CATextLayer *textLayer = (CATextLayer*)[[layer sublayers] objectAtIndex:0];
        
        [textLayer setHidden:!_showLabel];
        
        if(!_showLabel) return;
        
        NSString *label;
        
        if(_showPercentage){
            
            label = [NSString stringWithFormat:@"%0.0f", layer.percentage*100];
        } else {
            label = [NSString stringWithFormat:@"%0.0f", layer.value];
        }
        
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:13]};
        
        CGSize infoSize = CGSizeMake(10, 20);
        
        CGSize size = [label boundingRectWithSize:infoSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attributes context:nil].size;
        
        if(M_PI*2*_labelRadius*layer.percentage < MAX(size.width,size.height))
        {
            [textLayer setString:@""];
        }
        else
        {
            [textLayer setString:label];
            [textLayer setBounds:CGRectMake(0, 0, size.width, size.height)];
        }
    }
}

#pragma mark - 计算选中的扇形滑出的位置和角度
- (void)setSliceSelectedAtIndex:(NSInteger)index {
    if(_selectedSliceOffsetRadius <= 0) {
        
        return;
    }
    
    SliceLayer *layer = (SliceLayer*)[_pieView.layer.sublayers objectAtIndex:index];
    
    if (layer) {
        
        float adjust = 0.5;
        
        CGPoint currPos = layer.position;
        
        double middleAngle = (layer.startAngle + layer.endAngle)/2.0;
        
        // 此处是选中的扇形滑出的位置
        CGPoint newPos = CGPointMake(currPos.x + _selectedSliceOffsetRadius*cos(middleAngle)*adjust, currPos.y + _selectedSliceOffsetRadius*sin(middleAngle)*adjust);
        
        layer.position = newPos;
        
        layer.isSelected = YES;
    }
}

#pragma mark - 计算扇形取消选中后滑出的位置和角度
- (void)setSliceDeselectedAtIndex:(NSInteger)index {
    if(_selectedSliceOffsetRadius <= 0) {
        
        return;
    }
    
    SliceLayer *layer = (SliceLayer*)[_pieView.layer.sublayers objectAtIndex:index];
    
    if (layer) {
        
        layer.position = CGPointMake(0, 0);
        layer.isSelected = NO;
    }
}

#pragma mark - Pie Reload Data With Animation
- (void)reloadData {
    if (_dataSource && !_animationTimer)
    {
        CALayer *parentLayer = [_pieView layer];
        NSArray *slicelayers = [parentLayer sublayers];
        
        _selectedSliceIndex = -1;
        [slicelayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            SliceLayer *layer = (SliceLayer *)obj;
            if(layer.isSelected)
            [self setSliceDeselectedAtIndex:idx];
        }];
        
        double startToAngle = 0.0;
        double endToAngle = startToAngle;
        
        NSUInteger sliceCount = [_dataSource numberOfSlicesInPieChart:self];
        
        double sum = 0.0;
        double values[sliceCount];
        for (int index = 0; index < sliceCount; index++) {
            values[index] = [_dataSource pieChart:self valueForSliceAtIndex:index];
            sum += values[index];
        }
        
        double angles[sliceCount];
        for (int index = 0; index < sliceCount; index++) {
            double div;
            if (sum == 0)
            div = 0;
            else
            div = values[index] / sum;
            angles[index] = M_PI * 2 * div;
        }
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:_animationSpeed];
        
        [_pieView setUserInteractionEnabled:NO];
        
        __block NSMutableArray *layersToRemove = nil;
        [CATransaction setCompletionBlock:^{
            
            [layersToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [obj removeFromSuperlayer];
            }];
            
            [layersToRemove removeAllObjects];
            
            for(SliceLayer *layer in _pieView.layer.sublayers)
            {
                [layer setZPosition:kDefaultSliceZOrder];
            }
            
            [_pieView setUserInteractionEnabled:YES];
            if([_delegate respondsToSelector:@selector(animateFinish:)]){
                [_delegate animateFinish:self];
            }
        }];
        
        BOOL isOnStart = ([slicelayers count] == 0 && sliceCount);
        NSInteger diff = sliceCount - [slicelayers count];
        layersToRemove = [NSMutableArray arrayWithArray:slicelayers];
        
        BOOL isOnEnd = ([slicelayers count] && (sliceCount == 0 || sum <= 0));
        if(isOnEnd)
        {
            for(SliceLayer *layer in _pieView.layer.sublayers){
                [self updateLabelForLayer:layer value:0];
                [layer createArcAnimationForKey:@"startAngle"
                                      fromValue:[NSNumber numberWithDouble:_startPieAngle]
                                        toValue:[NSNumber numberWithDouble:_startPieAngle]
                                       Delegate:self];
                [layer createArcAnimationForKey:@"endAngle"
                                      fromValue:[NSNumber numberWithDouble:_startPieAngle]
                                        toValue:[NSNumber numberWithDouble:_startPieAngle]
                                       Delegate:self];
            }
            [CATransaction commit];
            return;
        }
        
        for(int index = 0; index < sliceCount; index ++)
        {
            SliceLayer *layer;
            double angle = angles[index];
            endToAngle += angle;
            double startFromAngle = _startPieAngle + startToAngle;
            double endFromAngle = _startPieAngle + endToAngle;
            
            if( index >= [slicelayers count] )
            {
                layer = [self createSliceLayer];
                if (isOnStart)
                startFromAngle = endFromAngle = _startPieAngle;
                [parentLayer addSublayer:layer];
                diff--;
            }
            else
            {
                SliceLayer *onelayer = [slicelayers objectAtIndex:index];
                if(diff == 0 || onelayer.value == (CGFloat)values[index])
                {
                    layer = onelayer;
                    [layersToRemove removeObject:layer];
                }
                else if(diff > 0)
                {
                    layer = [self createSliceLayer];
                    [parentLayer insertSublayer:layer atIndex:index];
                    diff--;
                }
                else if(diff < 0)
                {
                    while(diff < 0)
                    {
                        [onelayer removeFromSuperlayer];
                        [parentLayer addSublayer:onelayer];
                        diff++;
                        onelayer = [slicelayers objectAtIndex:index];
                        if(onelayer.value == (CGFloat)values[index] || diff == 0)
                        {
                            layer = onelayer;
                            [layersToRemove removeObject:layer];
                            break;
                        }
                    }
                }
            }
            
            layer.value = values[index];
            layer.percentage = (sum)?layer.value:0;
            UIColor *color = nil;
            if([_dataSource respondsToSelector:@selector(pieChart:colorForSliceAtIndex:)])
            {
                color = [_dataSource pieChart:self colorForSliceAtIndex:index];
            }
            
            if(!color)
            {
                // 如果没有设置扇形颜色这是默认颜色
                color = [UIColor colorWithHue:((index/8)%20)/20.0+0.02 saturation:(index%8+3)/10.0 brightness:91/100.0 alpha:1];
            }
            
            [layer setFillColor:color.CGColor];
            if (sliceCount > 1) {
                [layer setStrokeColor:ColorRGBA(255, 255, 255, 1).CGColor];
                [layer setLineWidth:3.0];
            }
            
            [self updateLabelForLayer:layer value:values[index]];
            [layer createArcAnimationForKey:@"startAngle"
                                  fromValue:[NSNumber numberWithDouble:startFromAngle]
                                    toValue:[NSNumber numberWithDouble:startToAngle+_startPieAngle]
                                   Delegate:self];
            [layer createArcAnimationForKey:@"endAngle"
                                  fromValue:[NSNumber numberWithDouble:endFromAngle]
                                    toValue:[NSNumber numberWithDouble:endToAngle+_startPieAngle]
                                   Delegate:self];
            startToAngle = endToAngle;
        }
        [CATransaction setDisableActions:YES];
        for(SliceLayer *layer in layersToRemove)
        {
            [layer setFillColor:[self backgroundColor].CGColor];
            [layer setDelegate:nil];
            [layer setZPosition:0];
            CATextLayer *textLayer = (CATextLayer*)[[layer sublayers] objectAtIndex:0];
            [textLayer setHidden:YES];
        }
        [CATransaction setDisableActions:NO];
        [CATransaction commit];
    }
}

#pragma mark - Animation Delegate + Run Loop Timer

- (void)updateTimerFired:(NSTimer *)timer;
{
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    [pieLayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SliceLayer *layer = (SliceLayer *)obj;
        
        NSNumber *presentationLayerStartAngle = [[obj presentationLayer] valueForKey:@"startAngle"];
        CGFloat interpolatedStartAngle = [presentationLayerStartAngle doubleValue];
        
        NSNumber *presentationLayerEndAngle = [[obj presentationLayer] valueForKey:@"endAngle"];
        CGFloat interpolatedEndAngle = [presentationLayerEndAngle doubleValue];
        
        CGPathRef path = CGPathCreateArc(_pieCenter, _pieRadius, interpolatedStartAngle, interpolatedEndAngle);
        [obj setPath:path];
        CFRelease(path);
        
        {
            CATextLayer *labelLayer = (CATextLayer*)[[obj sublayers] objectAtIndex:0];
            CAShapeLayer *lineLayer = (CAShapeLayer*)[[obj sublayers] objectAtIndex:1];
            CGFloat interpolatedMidAngle = (interpolatedEndAngle + interpolatedStartAngle) / 2;
            [CATransaction setDisableActions:YES];
            
            if (layer.percentage < self.checkLessPercent) {

                [labelLayer setForegroundColor:[UIColor grayColor].CGColor];

                float labelLayerX = _pieCenter.x + ((_labelRadius + 70) * cos(interpolatedMidAngle));

                float labelLayerY = _pieCenter.y + ((_labelRadius + 70) * sin(interpolatedMidAngle));

                UIBezierPath *linePath = [UIBezierPath bezierPath];
                // 起点
                [linePath moveToPoint:CGPointMake(_pieCenter.x + ((_labelRadius+ 35) * cos(interpolatedMidAngle)), _pieCenter.y + ((_labelRadius + 35) * sin(interpolatedMidAngle)))];
                // 终点
                [linePath addLineToPoint:CGPointMake(_pieCenter.x + ((_labelRadius+ 50) * cos(interpolatedMidAngle)), _pieCenter.y + ((_labelRadius + 50) * sin(interpolatedMidAngle)))];

                lineLayer.path = linePath.CGPath;

                [labelLayer setPosition:CGPointMake(labelLayerX * 1, labelLayerY * 1)];
            } else {

                float labelLayerX = _pieCenter.x + (_labelRadius * cos(interpolatedMidAngle));

                float labelLayerY = _pieCenter.y + (_labelRadius * sin(interpolatedMidAngle));

                [labelLayer setPosition:CGPointMake(labelLayerX * 1, labelLayerY * 1)];

            }

            [CATransaction setDisableActions:NO];
        }
    }];
}

- (void)animationDidStart:(CAAnimation *)anim {
    if (_animationTimer == nil) {
        static float timeInterval = 1.0/60.0;
        _animationTimer= [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(updateTimerFired:) userInfo:nil repeats:YES];
    }
    
    [_animations addObject:anim];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)animationCompleted {
    [_animations removeObject:anim];
    
    if ([_animations count] == 0) {
        [_animationTimer invalidate];
        _animationTimer = nil;
    }
}

#pragma mark - Touch Handing (Selection Notification) 选中扇形的索引
- (NSInteger)getCurrentSelectedOnTouch:(CGPoint)point {
    __block NSUInteger selectedIndex = -1;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    [pieLayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SliceLayer *pieLayer = (SliceLayer *)obj;
        CGPathRef path = [pieLayer path];
        
        if (CGPathContainsPoint(path, &transform, point, 0)) {
            [pieLayer setLineWidth:_selectedSliceStroke];
            [pieLayer setStrokeColor:[UIColor whiteColor].CGColor];
            [pieLayer setLineJoin:kCALineJoinBevel];
            [pieLayer setZPosition:MAXFLOAT];
            selectedIndex = idx;
        } else {
            [pieLayer setZPosition:kDefaultSliceZOrder];
            [pieLayer setLineWidth:0.0];
        }
    }];
    return selectedIndex;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:_pieView];
    [self getCurrentSelectedOnTouch:point];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:_pieView];
    NSInteger selectedIndex = [self getCurrentSelectedOnTouch:point];
    [self notifyDelegateOfSelectionChangeFrom:_selectedSliceIndex to:selectedIndex];
    [self touchesCancelled:touches withEvent:event];
}

#pragma mark - 选中事件
- (void)pieSelected:(NSInteger)selIndex {
    [self notifyDelegateOfSelectionChangeFrom:_selectedSliceIndex to:selIndex];
    [self touchesCancelled:[NSSet set] withEvent:nil];
}

#pragma marK - 点击旋转事件结束后
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    for (SliceLayer *pieLayer in pieLayers) {
        
        [pieLayer setZPosition:kDefaultSliceZOrder];
        [self createSliceLayer];
        if (pieLayers.count > 1) {
            [pieLayer setLineWidth:3.0];
        }
    }
    
}

#pragma mark - Selection Notification
- (void)notifyDelegateOfSelectionChangeFrom:(NSUInteger)previousSelection to:(NSUInteger)newSelection {
    // 将上一次选中的Selection和最新选中的Selection做比较
    if (previousSelection != newSelection)
    {
        if (previousSelection != -1 && [_delegate respondsToSelector:@selector(pieChart:willDeselectSliceAtIndex:)])
        {
            [_delegate pieChart:self willDeselectSliceAtIndex:previousSelection];
        }
        
        _selectedSliceIndex = newSelection;
        
        if (newSelection != -1)
        {
            if([_delegate respondsToSelector:@selector(pieChart:willSelectSliceAtIndex:)])
            [_delegate pieChart:self willSelectSliceAtIndex:newSelection];
            if(previousSelection != -1 && [_delegate respondsToSelector:@selector(pieChart:didDeselectSliceAtIndex:)])
            [_delegate pieChart:self didDeselectSliceAtIndex:previousSelection];
            if([_delegate respondsToSelector:@selector(pieChart:didSelectSliceAtIndex:)])
            [_delegate pieChart:self didSelectSliceAtIndex:newSelection];
            [self setSliceSelectedAtIndex:newSelection];
        }
        
        if(previousSelection != -1)
        {
            [self setSliceDeselectedAtIndex:previousSelection];
            if([_delegate respondsToSelector:@selector(pieChart:didDeselectSliceAtIndex:)])
            [_delegate pieChart:self didDeselectSliceAtIndex:previousSelection];
        }
    }
    else if (newSelection != -1)
    {
        SliceLayer *layer = (SliceLayer*)[_pieView.layer.sublayers objectAtIndex:newSelection];
        if(_selectedSliceOffsetRadius > 0 && layer){
            
            if (layer.isSelected) {
                if ([_delegate respondsToSelector:@selector(pieChart:willDeselectSliceAtIndex:)])
                [_delegate pieChart:self willDeselectSliceAtIndex:newSelection];
                [self setSliceDeselectedAtIndex:newSelection];
                if (newSelection != -1 && [_delegate respondsToSelector:@selector(pieChart:didDeselectSliceAtIndex:)])
                [_delegate pieChart:self didDeselectSliceAtIndex:newSelection];
            }
            else {
                if ([_delegate respondsToSelector:@selector(pieChart:willSelectSliceAtIndex:)])
                [_delegate pieChart:self willSelectSliceAtIndex:newSelection];
                [self setSliceSelectedAtIndex:newSelection];
                if (newSelection != -1 && [_delegate respondsToSelector:@selector(pieChart:didSelectSliceAtIndex:)])
                [_delegate pieChart:self didSelectSliceAtIndex:newSelection];
            }
        }
    }
}

#pragma mark - <扇形中百分比Label的旋转角度>
- (void)setTextAngle:(CGFloat)textAngle {
    
    NSString *angle = [NSString stringWithFormat:@"%0.6f", textAngle];
    // 将扇形百分比的旋转角度精确到小数点后六位，如果角度是0，则不进行角度旋转
    if ([angle isEqualToString:@"0.000000"] || [angle isEqualToString:@"-0.000000"]) {
        
        return;
    }
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    [pieLayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        CALayer *labelLayer = [[obj sublayers] objectAtIndex:0];
        
        // 扇形中百分比Label的旋转角度
        labelLayer.transform = CATransform3DMakeRotation(-textAngle, 0, 0, 1);
    }];
}

#pragma mark - Pie Layer Creation Method
- (SliceLayer *)createSliceLayer {
    SliceLayer *pieLayer = [SliceLayer layer];
    [pieLayer setZPosition:0];
    [pieLayer setStrokeColor:NULL];
    CATextLayer *textLayer = [CATextLayer layer];
    
#pragma mark - 这里可以修改整扇形title字体
    // 扇形百分比字体
    [textLayer setFontSize:self.labelFont.pointSize - 2];
    // 扇形百分比颜色
    [textLayer setForegroundColor:[UIColor whiteColor].CGColor];
    [textLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
    // 扇形百分比字体居中
    [textLayer setAlignmentMode:kCAAlignmentCenter];
    // 扇形百分比字体清晰度
    [textLayer setContentsScale:[UIScreen mainScreen].scale];
    // 扇形百分比背景色
    [textLayer setBackgroundColor:[UIColor clearColor].CGColor];
    
    // 当百分比过小时，划线显示百分比
    CAShapeLayer *lineLayer = [CAShapeLayer layer];
    lineLayer.lineWidth = 1;
    lineLayer.strokeColor = [UIColor grayColor].CGColor;
    
    [CATransaction setDisableActions:NO];
    [self.textLayerArray addObject:textLayer];
    self.textLayer = textLayer;
    [pieLayer addSublayer:textLayer];
    [pieLayer addSublayer:lineLayer];
    return pieLayer;
    
}

- (void)updateLabelForLayer:(SliceLayer *)pieLayer value:(CGFloat)value {
    CATextLayer *textLayer = (CATextLayer*)[[pieLayer sublayers] objectAtIndex:0];
    [textLayer setHidden:!_showLabel];
    if(!_showLabel) return;
    NSString *label;
   
    // 百分比预留小数点后一位
    label = [NSString stringWithFormat:@"%.1f%%", pieLayer.percentage];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:13]};
    
    CGSize infoSize = CGSizeMake(10, 20);
    
    CGSize size = [label boundingRectWithSize:infoSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attributes context:nil].size;
    
    [CATransaction setDisableActions:YES];

    [textLayer setString:label];
    
    [textLayer setBounds:CGRectMake(0, 0, size.width + 30, size.height)];
    [CATransaction setDisableActions:NO];
}

- (void)checkLessPercent:(CGFloat)lessPercent {

    _checkLessPercent = lessPercent;
}
@end
