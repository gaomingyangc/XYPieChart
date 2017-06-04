//
//  ViewController.m
//  PieChart
//
//  Created by GMY on 17/6/1.
//  Copyright © 2017年 com.gmy. All rights reserved.
//

#import "ViewController.h"
#import "XYPieChartView.h"
#import "XYCommon.h"

@interface ViewController ()<PieChartDelegate>

@property (nonatomic, strong)XYPieChartView *pieChartView;

/**
 * 数据
 */
@property (nonatomic, strong)NSMutableArray *pieChartArray;

/**
 * 数据（百分比）
 */
@property (nonatomic, strong)NSMutableArray *pieChartPercentArray;
/**
 * 数据（颜色）
 */
@property (nonatomic,strong) NSMutableArray *colorArray;

/**
 * 选中的标题
 */
@property (weak, nonatomic) IBOutlet UILabel *titlelabel;

/**
 * 选中的金额
 */
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;

/**
 * 选中的百分比
 */
@property (weak, nonatomic) IBOutlet UILabel *percentLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpPieChart];
}

- (void)setUpPieChart {

    CGRect pieChartFrame = CGRectMake((ScreenWidth - ScreenWidth * 0.6) / 2, ScreenHeight * 0.3, ScreenWidth * 0.6, ScreenWidth * 0.6);
    
    // 初始化饼图
    self.pieChartView = [[XYPieChartView alloc] initWithFrame:pieChartFrame withPieChartTypeArray:self.pieChartArray withPercentArray:self.pieChartPercentArray withColorArray:self.colorArray];
    
    self.pieChartView.delegate = self;
    
    // 当有一项数据的百分比小于你所校验的数值时，会将该项数值百分比移出饼图展示（校验数值从0~100）
    [self.pieChartView setCheckLessThanPercent:16];
    
    // 刷新加载
    [self.pieChartView reloadChart];
    
    // 设置圆心标题 （NSString类型）
//    [self.pieChartView setAmountText:@"总资产"];
    
    NSMutableAttributedString * str = [[NSMutableAttributedString alloc] initWithString:@"总支出"];
    
    // 设置圆心标题（NSMutableAttributedString类型）
    [self.pieChartView setTitleText:str];
    
    [self.view addSubview:self.pieChartView];
}

- (NSMutableArray *)pieChartArray {

    if (_pieChartArray == nil) {
        
        _pieChartArray = [NSMutableArray arrayWithObjects:@{@"title":@"餐饮", @"percent":@"33.2", @"amount":@"10234"}, @{@"title":@"购物", @"percent":@"26.8", @"amount":@"9820"} ,@{@"title":@"娱乐", @"percent":@"5.5", @"amount":@"1450"} ,@{@"title":@"零食", @"percent":@"35.5", @"amount":@"9700"}, nil];
    }
    
    return _pieChartArray;
}

- (NSMutableArray *)pieChartPercentArray {

    if (_pieChartPercentArray == nil) {
        
        _pieChartPercentArray = [NSMutableArray arrayWithObjects:@"33.2", @"26.8", @"5.5", @"35.5", nil];
    }
    return _pieChartPercentArray;
}

- (NSMutableArray *)colorArray {

    if (_colorArray == nil) {
        
//        (餐饮、购物、娱乐、零食)
        _colorArray = [NSMutableArray arrayWithObjects:
                         ColorRGBA(125, 207, 21, 1),
                         ColorRGBA(221, 203, 103, 1),
                         ColorRGBA(253, 171, 41, 1),
                         ColorRGBA(72, 197, 252, 1),
                         nil];
    }
    
    return _colorArray;
}

#pragma mark - <选中扇形回调>
- (void)selectedFinish:(XYPieChartView *)pieChartView index:(NSInteger)index selectedType:(NSDictionary *)selectedType {
    
    self.titlelabel.text = selectedType[@"title"];
    
    self.amountLabel.text = selectedType[@"amount"];
    
    self.percentLabel.text = [NSString stringWithFormat:@"%@%%", selectedType[@"percent"]];

}

#pragma mark - <点击扇形同心圆回调>
- (void)onCenterClick:(XYPieChartView *)PieChartView {

    NSLog(@"点击了圆心");
}

@end
