#import "TSUIStyleManager.h"

@implementation TSUIStyleManager

// 颜色 - 更新为增强的macOS风格
+ (UIColor *)primaryBackgroundColor {
    return [UIColor whiteColor]; // 纯白色背景
}

+ (UIColor *)secondaryBackgroundColor {
    return [UIColor whiteColor]; // 保持一致的纯白色背景
}

+ (UIColor *)accentColor {
    // 保持蓝色作为主题色，符合新拟物风格的柔和色调
    return [UIColor colorWithRed:0.0 green:0.5 blue:0.8 alpha:1.0]; // 柔和的蓝色
}

+ (UIColor *)textColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor labelColor];
    }
    return [UIColor blackColor];
}

+ (UIColor *)secondaryTextColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondaryLabelColor];
    }
    return [UIColor darkGrayColor];
}

+ (UIColor *)cardBackgroundColor {
    // 新拟物风格卡片背景色 - 纯白色，符合用户要求
    return [UIColor whiteColor]; // 纯白色
}

+ (NSArray *)gradientColors {
    // 新拟物风格不使用明显的渐变，返回纯白色
    UIColor *startColor = [UIColor whiteColor]; // 纯白色
    UIColor *endColor = [UIColor whiteColor]; // 纯白色
    return @[(id)startColor.CGColor, (id)endColor.CGColor];
}

// 模糊效果 - 保留但不再使用
+ (UIBlurEffect *)glassBlurEffect {
    if (@available(iOS 13.0, *)) {
        return [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    }
    return [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
}

// 增强新拟物风格的阴影效果
+ (void)applyNeumorphicStyleToView:(UIView *)view {
    view.layer.cornerRadius = [self cornerRadius];
    view.clipsToBounds = NO;
    
    // 纯净的背景颜色 - 纯白色
    view.backgroundColor = [UIColor whiteColor];
    
    // 清除现有阴影
    view.layer.shadowColor = nil;
    view.layer.shadowOffset = CGSizeZero;
    view.layer.shadowRadius = 0;
    view.layer.shadowOpacity = 0;
    
    // 移除所有现有的阴影层
    NSMutableArray *layersToRemove = [NSMutableArray array];
    for (CALayer *layer in view.layer.sublayers) {
        if ([layer.name isEqualToString:@"neumorphicShadow"]) {
            [layersToRemove addObject:layer];
        }
    }
    for (CALayer *layer in layersToRemove) {
        [layer removeFromSuperlayer];
    }
    
    // 创建强烈的新拟物风格双阴影效果 - 在白色背景上效果更明显
    
    // 1. 强暗部阴影 - 右下方向
    CALayer *darkShadowLayer = [CALayer layer];
    darkShadowLayer.name = @"neumorphicShadow";
    darkShadowLayer.frame = view.bounds;
    darkShadowLayer.cornerRadius = view.layer.cornerRadius;
    darkShadowLayer.backgroundColor = [UIColor clearColor].CGColor;
    darkShadowLayer.shadowColor = [UIColor blackColor].CGColor;
    darkShadowLayer.shadowOffset = CGSizeMake(6, 6); // 适当的偏移
    darkShadowLayer.shadowRadius = 8; // 模糊半径
    darkShadowLayer.shadowOpacity = 0.15; // 降低不透明度，适合白色背景
    [view.layer insertSublayer:darkShadowLayer atIndex:0];
    
    // 2. 强亮部阴影 - 左上方向
    CALayer *lightShadowLayer = [CALayer layer];
    lightShadowLayer.name = @"neumorphicShadow";
    lightShadowLayer.frame = view.bounds;
    lightShadowLayer.cornerRadius = view.layer.cornerRadius;
    lightShadowLayer.backgroundColor = [UIColor clearColor].CGColor;
    lightShadowLayer.shadowColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.9 alpha:1.0].CGColor; // 轻微的蓝紫色调高光
    lightShadowLayer.shadowOffset = CGSizeMake(-6, -6); // 更强烈的偏移
    lightShadowLayer.shadowRadius = 8; // 更大的模糊半径
    lightShadowLayer.shadowOpacity = 0.7; // 高不透明度创造强烈的对比
    [view.layer insertSublayer:lightShadowLayer atIndex:0];
    
    // 添加内部浮雕效果 - 新拟物风格的关键
    CALayer *innerLayer = [CALayer layer];
    innerLayer.name = @"neumorphicShadow";
    innerLayer.frame = CGRectInset(view.bounds, 2, 2);
    innerLayer.cornerRadius = view.layer.cornerRadius - 2;
    innerLayer.masksToBounds = YES;
    innerLayer.backgroundColor = [UIColor whiteColor].CGColor; // 纯白色内部
    [view.layer addSublayer:innerLayer];
    
    // 内部极微妙的渐变，增加深度感 - 新拟物风格典型特征
    CAGradientLayer *innerGradient = [CAGradientLayer layer];
    innerGradient.name = @"neumorphicShadow";
    innerGradient.frame = innerLayer.bounds;
    innerGradient.cornerRadius = innerLayer.cornerRadius;
    innerGradient.colors = @[
        (id)[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8].CGColor, // 顶部纯白
        (id)[UIColor colorWithRed:0.97 green:0.97 blue:0.99 alpha:0.1].CGColor  // 底部略带蓝紫色调
    ];
    innerGradient.startPoint = CGPointMake(0, 0);
    innerGradient.endPoint = CGPointMake(1, 1);
    innerGradient.opacity = 0.6;
    [innerLayer addSublayer:innerGradient];
    
    // 移除边框 - 新拟物风格通常不使用明显的边框
    view.layer.borderWidth = 0;
}

// 应用新拟物风格的凹陷效果
+ (void)applyGlassmorphismToView:(UIView *)view {
    view.layer.cornerRadius = [self cornerRadius];
    view.clipsToBounds = NO;
    
    // 纯净的背景颜色 - 纯白色
    view.backgroundColor = [UIColor whiteColor];
    
    // 清除现有阴影和边框
    view.layer.shadowColor = nil;
    view.layer.shadowOffset = CGSizeZero;
    view.layer.shadowRadius = 0;
    view.layer.shadowOpacity = 0;
    view.layer.borderWidth = 0;
    
    // 移除所有现有的阴影层
    NSMutableArray *layersToRemove = [NSMutableArray array];
    for (CALayer *layer in view.layer.sublayers) {
        if ([layer.name isEqualToString:@"neumorphicShadow"]) {
            [layersToRemove addObject:layer];
        }
    }
    for (CALayer *layer in layersToRemove) {
        [layer removeFromSuperlayer];
    }
    
    // 背景为纯白色，营造凹陷感
    view.backgroundColor = [UIColor whiteColor];
    
    // 创建内凹阴影效果 - 新拟物风格的特点
    
    // 添加内阴影容器
    CALayer *innerShadowContainer = [CALayer layer];
    innerShadowContainer.name = @"neumorphicShadow";
    innerShadowContainer.frame = view.bounds;
    innerShadowContainer.cornerRadius = view.layer.cornerRadius;
    innerShadowContainer.backgroundColor = [UIColor clearColor].CGColor;
    [view.layer addSublayer:innerShadowContainer];
    
    // 顶部内阴影 - 模拟下沉效果
    CALayer *topInnerShadow = [CALayer layer];
    topInnerShadow.name = @"neumorphicShadow";
    topInnerShadow.frame = CGRectMake(0, 0, view.bounds.size.width, 2);
    topInnerShadow.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.05].CGColor;
    [innerShadowContainer addSublayer:topInnerShadow];
    
    // 左侧内阴影
    CALayer *leftInnerShadow = [CALayer layer];
    leftInnerShadow.name = @"neumorphicShadow";
    leftInnerShadow.frame = CGRectMake(0, 0, 2, view.bounds.size.height);
    leftInnerShadow.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.04].CGColor;
    [innerShadowContainer addSublayer:leftInnerShadow];
    
    // 底部高光 - 模拟立体感
    CALayer *bottomHighlight = [CALayer layer];
    bottomHighlight.name = @"neumorphicShadow";
    bottomHighlight.frame = CGRectMake(0, view.bounds.size.height - 1, view.bounds.size.width, 1);
    bottomHighlight.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
    [innerShadowContainer addSublayer:bottomHighlight];
    
    // 右侧高光
    CALayer *rightHighlight = [CALayer layer];
    rightHighlight.name = @"neumorphicShadow";
    rightHighlight.frame = CGRectMake(view.bounds.size.width - 1, 0, 1, view.bounds.size.height);
    rightHighlight.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
    [innerShadowContainer addSublayer:rightHighlight];
}

// 更新圆角尺寸 - 新拟物风格通常使用较大的圆角
+ (CGFloat)cornerRadius {
    return 16.0; // 更大的圆角
}

// macOS风格的字体
+ (UIFont *)titleFont {
    if (@available(iOS 13.0, *)) {
        return [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    }
    return [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
}

+ (UIFont *)bodyFont {
    if (@available(iOS 13.0, *)) {
        return [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    }
    return [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
}

+ (UIFont *)smallFont {
    if (@available(iOS 13.0, *)) {
        return [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    }
    return [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
}

// 增强按钮按下效果
+ (void)animateButtonPress:(UIView *)button {
    // 移除任何现有动画
    [button.layer removeAllAnimations];
    
    // 获取按钮之前的变换
    CATransform3D originalTransform = button.layer.transform;
    
    // 创建按下时的缩放和轻微下移动画
    [UIView animateWithDuration:0.1 
                     animations:^{
        // 轻微的缩放和下移，模拟按下状态
        button.layer.transform = CATransform3DTranslate(CATransform3DScale(originalTransform, 0.97, 0.97, 1), 0, 1, 0);
        
        // 移除所有现有的新拟物阴影层
        NSMutableArray *layersToRemove = [NSMutableArray array];
        for (CALayer *layer in button.layer.sublayers) {
            if ([layer.name isEqualToString:@"neumorphicShadow"]) {
                [layersToRemove addObject:layer];
            }
        }
        for (CALayer *layer in layersToRemove) {
            [layer removeFromSuperlayer];
        }
        
        // 应用内凹效果
        [self applyGlassmorphismToView:button];
        
    } completion:^(BOOL finished) {
        // 恢复动画
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            // 恢复原始变换
            button.layer.transform = originalTransform;
            
            // 移除所有现有的新拟物阴影层
            NSMutableArray *layersToRemove = [NSMutableArray array];
            for (CALayer *layer in button.layer.sublayers) {
                if ([layer.name isEqualToString:@"neumorphicShadow"]) {
                    [layersToRemove addObject:layer];
                }
            }
            for (CALayer *layer in layersToRemove) {
                [layer removeFromSuperlayer];
            }
            
            // 恢复凸起效果
            [self applyNeumorphicStyleToView:button];
            
        } completion:nil];
    }];
}

// 增强macOS风格的工具栏按钮样式
+ (void)applyToolbarButtonStyle:(UIButton *)button {
    button.layer.cornerRadius = 10.0; // 适当的圆角
    
    // 清除现有样式
    button.layer.borderWidth = 0;
    button.layer.shadowOpacity = 0;
    
    // 应用标准的新拟物风格
    [self applyNeumorphicStyleToView:button];
    
    // 调整图标颜色
    [button setTintColor:[self accentColor]];
    
    // 确保文本颜色正确
    [button setTitleColor:[self textColor] forState:UIControlStateNormal];
}

@end 