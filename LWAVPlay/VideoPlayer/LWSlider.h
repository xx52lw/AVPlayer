//
//  LWSlider.h
//  LWSlider
//
//  Created by LW on 16/3/18.
//  Copyright © 2017年 GreatGate. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LWSlider;
// ====================================================================================================================================
#pragma mark 自定义block属性
typedef void (^SliderValueChangeBlock) (LWSlider *slider);
typedef void (^SliderFinishChangeBlock) (LWSlider *slider);
typedef void (^DraggingSliderBlock) (LWSlider *slider);
// ====================================================================================================================================
#pragma mark 自定义滑尺
@interface LWSlider : UIView

/** 划过值 From 0 to 1 */
@property (nonatomic, assign) CGFloat value;
/** 预加载值 From 0 to 1 */
@property (nonatomic, assign) CGFloat middleValue;
/** 滑尺宽度 */
@property (nonatomic, assign) CGFloat lineWidth;
/** 拖盘直径 */
@property (nonatomic, assign) CGFloat sliderDiameter;
/** 拖盘染色 */
@property (nonatomic, strong) UIColor *sliderColor;
/** 滑尺默认染色 */
@property (nonatomic, strong) UIColor *maxColor;
/** 滑尺预加载染色 */
@property (nonatomic, strong) UIColor *middleColor;
/** 滑尺划过染色 */
@property (nonatomic, strong) UIColor *minColor;
/** 滑尺值改变 */
@property (nonatomic, copy) SliderValueChangeBlock valueChangeBlock;
/** 滑尺滚动条到最后 */
@property (nonatomic, copy) SliderFinishChangeBlock finishChangeBlock;
/** 滑尺拖拽 */
@property (nonatomic, strong) DraggingSliderBlock draggingSliderBlock;

@end
// ====================================================================================================================================
