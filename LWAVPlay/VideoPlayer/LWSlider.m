//
//  LWSlider.m
//  LWSlider
//
//  Created by LW on 16/3/18.
//  Copyright © 2017年 GreatGate. All rights reserved.
//

#import "LWSlider.h"

static CGFloat panDistance; // 拖盘的距离
// ====================================================================================================================================
#pragma mark 自定义滑尺图层代理
@interface LayerDelegate : NSObject

@property (nonatomic, assign) CGFloat centerY;        // 滑尺Y中心点
@property (nonatomic, assign) CGFloat lineWidth;      // 滑尺宽度
@property (nonatomic, assign) CGFloat middleValue;    // 预加载值
@property (nonatomic, assign) CGFloat lineLength;     // 滑尺长度
@property (nonatomic, assign) CGFloat sliderDiameter; // 拖盘直径
@property (nonatomic, strong) UIColor *sliderColor;   // 拖盘颜色
@property (nonatomic, strong) UIColor *maxColor;      // 默认填充颜色
@property (nonatomic, strong) UIColor *middleColor;   // 预加载颜色
@property (nonatomic, strong) UIColor *minColor;      // 滑过颜色

@end
// ====================================================================================================================================
#pragma mark 自定义滑尺图层代理
@implementation LayerDelegate

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    //mark: 绘制整体滑尺
    CGMutablePathRef maxPath = CGPathCreateMutable();
    CGPathMoveToPoint(maxPath, NULL, panDistance + self.sliderDiameter, self.centerY); // 起点
    CGPathAddLineToPoint(maxPath, nil, self.lineLength, self.centerY); // 终点
    CGContextSetStrokeColorWithColor(ctx, self.maxColor.CGColor); // 默认填充颜色
    CGContextSetLineWidth(ctx, self.lineWidth); // 线宽
    // 绘制
    CGContextAddPath(ctx, maxPath);
    CGContextStrokePath(ctx);
    // 关闭
    CGPathCloseSubpath(maxPath);
    CGPathRelease(maxPath);
    
    // Mark：绘制预加载路径
    CGMutablePathRef middlePath = CGPathCreateMutable();
    CGPathMoveToPoint(middlePath, NULL, 0, self.centerY);
    CGPathAddLineToPoint(middlePath, nil, self.middleValue * self.lineLength, self.centerY);
    CGContextSetStrokeColorWithColor(ctx, self.middleColor.CGColor);
    CGContextSetLineWidth(ctx, self.lineWidth);
    CGContextAddPath(ctx, middlePath);
    CGPathCloseSubpath(middlePath);
    CGContextStrokePath(ctx);
    CGPathRelease(middlePath);
    
    // Mark：绘制划过路径
    CGMutablePathRef minPath = CGPathCreateMutable();
    CGPathMoveToPoint(minPath, NULL, 0, self.centerY);
    CGPathAddLineToPoint(minPath, nil, panDistance, self.centerY);
    CGContextSetStrokeColorWithColor(ctx, self.minColor.CGColor);
    CGContextSetLineWidth(ctx, self.lineWidth);
    CGContextAddPath(ctx, minPath);
    CGPathCloseSubpath(minPath);
    CGContextStrokePath(ctx);
    CGPathRelease(minPath);
    
    // Mark: 绘制拖盘
    CGMutablePathRef pointPath = CGPathCreateMutable();
    CGPathAddEllipseInRect(pointPath, nil, CGRectMake(panDistance, self.centerY - (self.sliderDiameter / 2), self.sliderDiameter, self.sliderDiameter));
    CGContextSetFillColorWithColor(ctx, self.sliderColor.CGColor);
    CGContextAddPath(ctx, pointPath);
    CGPathCloseSubpath(pointPath);
    CGContextFillPath(ctx);
    CGPathRelease(pointPath);
}

@end
// ====================================================================================================================================
#pragma mark - 自定义滑尺
@interface LWSlider () {
    CALayer *_lineLayer;
    LayerDelegate *_delegate;
}

@end
// ====================================================================================================================================
#pragma mark - 自定义滑尺
@implementation LWSlider
#pragma mark 重写init
- (instancetype)init {
    
    if (self = [super init]) {
        // 添加拖拽手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
        [self addGestureRecognizer:pan];
        // 添加点击手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tap];
        [tap requireGestureRecognizerToFail:pan];
        
        _delegate = [[LayerDelegate alloc] init];
        _delegate.maxColor = self.maxColor;
        _delegate.middleColor = self.middleColor;
        _delegate.minColor = self.minColor;
        _delegate.sliderDiameter = self.sliderDiameter;
        _delegate.sliderColor = self.sliderColor;
        _delegate.lineWidth = self.lineWidth;
        
        _lineLayer = [CALayer layer];
        _lineLayer.delegate = _delegate;
        [self.layer addSublayer:_lineLayer];
        [_lineLayer setNeedsDisplay];
        
        // 添加kvo监听
        [self addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"middleValue" options:NSKeyValueObservingOptionNew context:nil];
    }
        return self;
}
#pragma mark 重写layoutSubviews
- (void)layoutSubviews {
    [super layoutSubviews];
    _delegate.centerY = self.frame.size.height / 2.0f;
    _delegate.lineLength = self.frame.size.width;
    _lineLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [_lineLayer setNeedsDisplay];
}
#pragma mark 重写dealloc
- (void)dealloc {
    // 移除kvo监听
    [self removeObserver:self forKeyPath:@"value"];
    [self removeObserver:self forKeyPath:@"middleValue"];
}

#pragma mark KVO监听方法
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([keyPath isEqualToString:@"value"]){ // 滑尺值改变
        [_lineLayer setNeedsDisplay];
        if (self.valueChangeBlock) {
            self.valueChangeBlock(self);
        }
    }
    if ([keyPath isEqualToString:@"middleValue"]) { // 预加载值改变
        [_lineLayer setNeedsDisplay];
    }
}

#pragma mark 拖拽方法
- (void)panAction:(UIPanGestureRecognizer *)panGesture {
     // 拖拽到的X距离
    CGFloat detalX = [panGesture translationInView:self].x;
    NSLog(@"detalX = %f",detalX);
    panDistance += detalX;
    // 拖拽范围判断
    panDistance = panDistance >= 0 ? panDistance : 0;
    panDistance = panDistance <= (self.frame.size.width - self.sliderDiameter) ? panDistance : (self.frame.size.width - self.sliderDiameter);
    // 拖拽值归零
    [panGesture setTranslation:CGPointZero inView:self];
    // 比例值
    self.value = panDistance / (self.frame.size.width - self.sliderDiameter);
    // 拖拽结束到最后
    if (panGesture.state ==  UIGestureRecognizerStateEnded && self.finishChangeBlock) {
        self.finishChangeBlock(self);
       
    }
     // 拖拽中
    else if((panGesture.state == UIGestureRecognizerStateChanged || UIGestureRecognizerStateBegan) && self.draggingSliderBlock) {
        self.draggingSliderBlock(self);
    }
}
#pragma mark 点击方法
- (void)tapAction:(UITapGestureRecognizer *)tapGesture {
    
    CGPoint location = [tapGesture locationInView:self];
    panDistance = location.x;
    self.value =  panDistance / (self.frame.size.width - self.sliderDiameter);
    if (self.finishChangeBlock) {
        self.finishChangeBlock(self);
    }
}

#pragma mark - setter getter

@synthesize sliderColor = _sliderColor;
@synthesize lineWidth = _lineWidth;
@synthesize minColor = _minColor;
@synthesize middleColor = _middleColor;
@synthesize maxColor = _maxColor;
@synthesize sliderDiameter = _sliderDiameter;

- (void)setSliderColor:(UIColor *)sliderColor {
    _sliderColor = sliderColor;
    _delegate.sliderColor = _sliderColor;
}

- (UIColor *)sliderColor {
    if (!_sliderColor) {
        return [UIColor whiteColor];
    }
    return _sliderColor;
}

- (void)setSliderDiameter:(CGFloat)sliderDiameter {
    _sliderDiameter = sliderDiameter;
    _delegate.sliderDiameter = sliderDiameter;
}

- (CGFloat)sliderDiameter {
    if (!_sliderDiameter) {
        return 10.0f;
    }
    return _sliderDiameter;
}

- (void)setMinColor:(UIColor *)minColor {
    _minColor = minColor;
    _delegate.minColor = minColor;
}

- (UIColor *)minColor {
    if (!_minColor) {
        return [UIColor greenColor];
    }
    return _minColor;
}

- (void)setMaxColor:(UIColor *)maxColor {
    _maxColor = maxColor;
    _delegate.maxColor = maxColor;
}

- (UIColor *)maxColor {
    if (!_maxColor) {
        return [UIColor darkGrayColor];
    }
    return _maxColor;
}

- (void)setMiddleColor:(UIColor *)middleColor {
    _middleColor = middleColor;
    _delegate.middleColor = middleColor;
}

- (UIColor *)middleColor {
    if (!_middleColor) {
        return  [UIColor lightGrayColor];
//        return  [UIColor redColor];
    }
    return _middleColor;
}

- (CGFloat)lineWidth {
    if (!_lineWidth) {
        return 1.0f;
    }
    return _lineWidth;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    _delegate.lineWidth = lineWidth;
}

-(void)setMiddleValue:(CGFloat)middleValue {
    _middleValue = middleValue;
    _delegate.middleValue = middleValue;
}

- (void)setValue:(CGFloat)value {
    _value = value;
    panDistance = value * (self.frame.size.width - self.sliderDiameter);
}


@end
