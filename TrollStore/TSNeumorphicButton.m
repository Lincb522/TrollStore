#import "TSNeumorphicButton.h"
#import "TSUIStyleManager.h"

@implementation TSNeumorphicButton

- (instancetype)initWithStyle:(TSButtonStyle)style {
    self = [super init];
    if (self) {
        _buttonStyle = style;
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    // 应用macOS风格的新拟物设计
    [TSUIStyleManager applyNeumorphicStyleToView:self];
    
    // 创建图标视图
    _iconView = [[UIImageView alloc] init];
    _iconView.translatesAutoresizingMaskIntoConstraints = NO;
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.tintColor = [TSUIStyleManager accentColor];
    [self addSubview:_iconView];
    
    // 创建标题标签 - 使用SF Pro字体更接近macOS风格
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [TSUIStyleManager bodyFont];
    _titleLabel.textColor = [TSUIStyleManager textColor];
    [self addSubview:_titleLabel];
    
    // 创建副标题标签 - 使用SF Pro字体更接近macOS风格
    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _subtitleLabel.font = [TSUIStyleManager smallFont];
    _subtitleLabel.textColor = [TSUIStyleManager secondaryTextColor];
    _subtitleLabel.numberOfLines = 2;
    [self addSubview:_subtitleLabel];
    
    // 调整约束以更符合macOS的按钮布局
    [NSLayoutConstraint activateConstraints:@[
        // 图标视图约束 - macOS图标通常小一点
        [_iconView.heightAnchor constraintEqualToConstant:20],
        [_iconView.widthAnchor constraintEqualToConstant:20],
        [_iconView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:14],
        [_iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        
        // 标题标签约束 - macOS风格布局
        [_titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:10],
        [_titleLabel.leftAnchor constraintEqualToAnchor:_iconView.rightAnchor constant:10],
        [_titleLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-14],
        
        // 副标题标签约束 - macOS风格布局
        [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:2],
        [_subtitleLabel.leftAnchor constraintEqualToAnchor:_iconView.rightAnchor constant:10],
        [_subtitleLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-14],
        [_subtitleLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-10]
    ]];
    
    // 添加触摸事件 - macOS风格的按下效果
    [self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
}

- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle {
    _titleLabel.text = title;
    
    if (subtitle && subtitle.length > 0) {
        _subtitleLabel.text = subtitle;
        _subtitleLabel.hidden = NO;
    } else {
        _subtitleLabel.text = @"";
        _subtitleLabel.hidden = YES;
        
        // 如果没有副标题，调整标题位置至居中 - 更符合macOS单行按钮样式
        if (!_subtitleLabel.hidden) {
            _titleLabel.center = CGPointMake(_titleLabel.center.x, self.bounds.size.height / 2);
        }
    }
}

- (void)setIcon:(UIImage *)icon {
    _iconView.image = icon;
    
    // macOS风格的图标渲染模式
    if (icon) {
        _iconView.image = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
}

- (void)touchDown {
    [TSUIStyleManager animateButtonPress:self];
}

- (void)touchUp {
    [UIView animateWithDuration:0.2 animations:^{
        self.transform = CGAffineTransformIdentity;
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 确保阴影图层跟随视图大小变化
    for (CALayer *layer in self.layer.sublayers) {
        if (layer.shadowOpacity > 0) {
            layer.frame = self.bounds;
        }
    }
}

@end 