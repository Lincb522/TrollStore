#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TSButtonStyle) {
    TSButtonStyleNeumorphic,  // 新拟物风格
    TSButtonStyleGlassmorphic // 玻璃拟态风格
};

@interface TSNeumorphicButton : UIControl

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, assign) TSButtonStyle buttonStyle;

- (instancetype)initWithStyle:(TSButtonStyle)style;
- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle;
- (void)setIcon:(UIImage *)icon;

@end 