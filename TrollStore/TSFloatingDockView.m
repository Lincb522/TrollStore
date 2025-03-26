#import "TSFloatingDockView.h"
#import "TSUIStyleManager.h"

@interface TSFloatingDockView ()
@property (nonatomic, strong) NSArray<UIImage *> *icons;
@property (nonatomic, strong) NSArray<NSString *> *titles;
@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;
@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) UIVisualEffectView *backgroundView;
@end

@implementation TSFloatingDockView

- (instancetype)initWithFrame:(CGRect)frame icons:(NSArray<UIImage *> *)icons titles:(NSArray<NSString *> *)titles {
    self = [super initWithFrame:frame];
    if (self) {
        _icons = icons;
        _titles = titles;
        _buttons = [NSMutableArray array];
        _selectedIndex = 0;
        
        [self setupView];
    }
    return self;
}

- (void)setupView {
    // 创建新拟物风格的背景
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = 24.0;
    self.clipsToBounds = NO;
    
    // 添加磨砂玻璃背景
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    _backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    _backgroundView.frame = self.bounds;
    _backgroundView.layer.cornerRadius = 24.0;
    _backgroundView.clipsToBounds = YES;
    [self addSubview:_backgroundView];
    
    // 应用新拟物样式的阴影效果
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.layer.shadowRadius = 15.0;
    self.layer.shadowOpacity = 0.1;
    
    // 添加微妙的边框
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
    
    // 创建指示器视图
    _indicatorView = [[UIView alloc] init];
    _indicatorView.backgroundColor = [TSUIStyleManager accentColor];
    _indicatorView.layer.cornerRadius = 2.0;
    [_backgroundView.contentView addSubview:_indicatorView];
    
    // 创建按钮
    [self setupButtons];
}

- (void)setupButtons {
    // 移除现有按钮
    for (UIButton *button in _buttons) {
        [button removeFromSuperview];
    }
    [_buttons removeAllObjects];
    
    // 计算每个按钮的宽度
    CGFloat buttonWidth = self.bounds.size.width / _icons.count;
    CGFloat buttonHeight = self.bounds.size.height;
    
    // 创建新按钮
    for (NSInteger i = 0; i < _icons.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(i * buttonWidth, 0, buttonWidth, buttonHeight);
        button.tag = i;
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // 垂直布局图标和文字
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *icon = [_icons[i] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [button setImage:icon forState:UIControlStateNormal];
        
        [button setTitle:_titles[i] forState:UIControlStateNormal];
        [button setTitleColor:[TSUIStyleManager secondaryTextColor] forState:UIControlStateNormal];
        
        // 设置垂直布局
        button.titleLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightMedium];
        button.imageEdgeInsets = UIEdgeInsetsMake(-10, 0, 0, 0);
        button.titleEdgeInsets = UIEdgeInsetsMake(30, -20, 0, 0);
        
        // 初始状态下颜色
        if (i == _selectedIndex) {
            button.tintColor = [TSUIStyleManager accentColor];
            [button setTitleColor:[TSUIStyleManager accentColor] forState:UIControlStateNormal];
        } else {
            button.tintColor = [TSUIStyleManager secondaryTextColor];
        }
        
        [_backgroundView.contentView addSubview:button];
        [_buttons addObject:button];
    }
    
    // 设置指示器的初始位置
    [self updateIndicatorPositionAnimated:NO];
}

- (void)buttonTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index != _selectedIndex) {
        [self setSelectedIndex:index animated:YES];
        
        // 通知代理
        if ([self.delegate respondsToSelector:@selector(floatingDockDidSelectIndex:)]) {
            [self.delegate floatingDockDidSelectIndex:index];
        }
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated {
    if (_selectedIndex != selectedIndex && selectedIndex < _buttons.count) {
        // 更新之前选中按钮的状态
        UIButton *previousButton = _buttons[_selectedIndex];
        previousButton.tintColor = [TSUIStyleManager secondaryTextColor];
        [previousButton setTitleColor:[TSUIStyleManager secondaryTextColor] forState:UIControlStateNormal];
        
        // 更新当前选中按钮的状态
        _selectedIndex = selectedIndex;
        UIButton *currentButton = _buttons[_selectedIndex];
        currentButton.tintColor = [TSUIStyleManager accentColor];
        [currentButton setTitleColor:[TSUIStyleManager accentColor] forState:UIControlStateNormal];
        
        // 更新指示器位置
        [self updateIndicatorPositionAnimated:animated];
    }
}

- (void)updateIndicatorPositionAnimated:(BOOL)animated {
    if (_buttons.count == 0) return;
    
    UIButton *selectedButton = _buttons[_selectedIndex];
    CGFloat buttonWidth = self.bounds.size.width / _buttons.count;
    
    CGFloat indicatorWidth = buttonWidth * 0.3;
    CGFloat indicatorHeight = 4.0;
    CGFloat x = selectedButton.center.x - indicatorWidth / 2;
    CGFloat y = self.bounds.size.height - indicatorHeight - 5.0;
    
    CGRect indicatorFrame = CGRectMake(x, y, indicatorWidth, indicatorHeight);
    
    if (animated) {
        [UIView animateWithDuration:0.25 
                         animations:^{
            self.indicatorView.frame = indicatorFrame;
        }];
    } else {
        self.indicatorView.frame = indicatorFrame;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 更新背景视图的尺寸
    _backgroundView.frame = self.bounds;
    
    // 如果按钮已经创建，重新计算它们的尺寸和位置
    if (_buttons.count > 0) {
        CGFloat buttonWidth = self.bounds.size.width / _buttons.count;
        CGFloat buttonHeight = self.bounds.size.height;
        
        for (NSInteger i = 0; i < _buttons.count; i++) {
            UIButton *button = _buttons[i];
            button.frame = CGRectMake(i * buttonWidth, 0, buttonWidth, buttonHeight);
        }
        
        // 更新指示器位置
        [self updateIndicatorPositionAnimated:NO];
    }
}

@end 