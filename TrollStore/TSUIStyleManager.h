#import <UIKit/UIKit.h>

@interface TSUIStyleManager : NSObject

// 颜色
+ (UIColor *)primaryBackgroundColor;
+ (UIColor *)secondaryBackgroundColor;
+ (UIColor *)accentColor;
+ (UIColor *)textColor;
+ (UIColor *)secondaryTextColor;
+ (UIColor *)cardBackgroundColor;
+ (NSArray *)gradientColors;

// 模糊效果
+ (UIBlurEffect *)glassBlurEffect;

// 新拟物阴影
+ (void)applyNeumorphicStyleToView:(UIView *)view;
+ (void)applyGlassmorphismToView:(UIView *)view;

// macOS风格工具栏按钮
+ (void)applyToolbarButtonStyle:(UIButton *)button;

// 圆角
+ (CGFloat)cornerRadius;

// 字体
+ (UIFont *)titleFont;
+ (UIFont *)bodyFont;
+ (UIFont *)smallFont;

// 动画
+ (void)animateButtonPress:(UIView *)button;

@end 