#import "TSAppTableViewCell.h"
#import "TSUIStyleManager.h"

@implementation TSAppTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    // 设置单元格背景
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // 创建macOS风格的容器视图
    _containerView = [[UIView alloc] init];
    _containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [TSUIStyleManager applyNeumorphicStyleToView:_containerView];
    
    // macOS风格的交互状态提示边框 - 初始为透明
    _containerView.layer.borderWidth = 1.0;
    _containerView.layer.borderColor = [UIColor clearColor].CGColor;
    
    [self.contentView addSubview:_containerView];
    
    // 创建图标视图 - macOS图标通常更圆润
    _appIconView = [[UIImageView alloc] init];
    _appIconView.translatesAutoresizingMaskIntoConstraints = NO;
    _appIconView.layer.cornerRadius = 8; // macOS应用图标圆角
    _appIconView.layer.masksToBounds = YES;
    _appIconView.contentMode = UIViewContentModeScaleAspectFit;
    [_containerView addSubview:_appIconView];
    
    // 创建标题标签 - 使用macOS风格字体
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [TSUIStyleManager titleFont];
    _titleLabel.textColor = [TSUIStyleManager textColor];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:_titleLabel];
    
    // 创建副标题标签 - 使用macOS风格字体
    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.font = [TSUIStyleManager smallFont];
    _subtitleLabel.textColor = [TSUIStyleManager secondaryTextColor];
    _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:_subtitleLabel];
    
    // 设置约束 - macOS风格的间距和布局
    [NSLayoutConstraint activateConstraints:@[
        // 容器视图约束 - macOS表格行通常较矮
        [_containerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
        [_containerView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:12],
        [_containerView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-12],
        [_containerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],
        
        // 图标视图约束 - macOS图标通常较小
        [_appIconView.heightAnchor constraintEqualToConstant:40],
        [_appIconView.widthAnchor constraintEqualToConstant:40],
        [_appIconView.leftAnchor constraintEqualToAnchor:_containerView.leftAnchor constant:12],
        [_appIconView.centerYAnchor constraintEqualToAnchor:_containerView.centerYAnchor],
        
        // 标题标签约束 - macOS标签通常对齐得更好
        [_titleLabel.topAnchor constraintEqualToAnchor:_containerView.topAnchor constant:12],
        [_titleLabel.leftAnchor constraintEqualToAnchor:_appIconView.rightAnchor constant:12],
        [_titleLabel.rightAnchor constraintEqualToAnchor:_containerView.rightAnchor constant:-12],
        
        // 副标题标签约束 - macOS副标题更接近主标题
        [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:2],
        [_subtitleLabel.leftAnchor constraintEqualToAnchor:_appIconView.rightAnchor constant:12],
        [_subtitleLabel.rightAnchor constraintEqualToAnchor:_containerView.rightAnchor constant:-12],
        [_subtitleLabel.bottomAnchor constraintLessThanOrEqualToAnchor:_containerView.bottomAnchor constant:-12]
    ]];
    
    // 添加一个轻微的macOS风格悬停效果
    UIHoverGestureRecognizer *hoverGesture = [[UIHoverGestureRecognizer alloc] initWithTarget:self action:@selector(handleHover:)];
    [_containerView addGestureRecognizer:hoverGesture];
}

// macOS风格的悬停效果
- (void)handleHover:(UIHoverGestureRecognizer *)recognizer {
    if (@available(iOS 13.0, *)) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            // 悬停开始 - 轻微突出显示
            [UIView animateWithDuration:0.2 animations:^{
                self->_containerView.transform = CGAffineTransformMakeScale(1.01, 1.01);
                self->_containerView.layer.borderColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.3].CGColor;
            }];
        } else if (recognizer.state == UIGestureRecognizerStateEnded) {
            // 悬停结束 - 恢复默认状态
            [UIView animateWithDuration:0.2 animations:^{
                self->_containerView.transform = CGAffineTransformIdentity;
                self->_containerView.layer.borderColor = [UIColor clearColor].CGColor;
            }];
        }
    }
}

- (void)configureWithAppInfo:(TSAppInfo *)appInfo {
    self.titleLabel.text = [appInfo displayName];
    self.subtitleLabel.text = [appInfo bundleIdentifier];
    
    // 设置图标 - macOS风格的圆角图标
    UIImage *icon = [appInfo iconForSize:self.appIconView.bounds.size];
    if (icon) {
        // 渲染图标时可以添加轻微阴影 - macOS风格
        self.appIconView.image = icon;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        // macOS风格高亮效果 - 微妙的缩放和边框
        _containerView.transform = CGAffineTransformMakeScale(0.98, 0.98);
        
        // 设置突出边框 - macOS风格
        if (@available(iOS 13.0, *)) {
            _containerView.layer.borderColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.5].CGColor;
        } else {
            _containerView.layer.borderColor = [[UIColor blueColor] colorWithAlphaComponent:0.5].CGColor;
        }
        
        // 轻微调整阴影以增加按下感
        for (CALayer *layer in _containerView.layer.sublayers) {
            if (layer.shadowOpacity > 0) {
                layer.shadowOpacity = layer.shadowOpacity * 0.7;
            }
        }
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            // 恢复正常状态
            self->_containerView.transform = CGAffineTransformIdentity;
            self->_containerView.layer.borderColor = [UIColor clearColor].CGColor;
            
            // 恢复阴影
            for (CALayer *layer in self->_containerView.layer.sublayers) {
                if (layer.shadowOpacity > 0) {
                    if (layer.shadowOffset.height > 0) {
                        layer.shadowOpacity = 0.1;
                    } else if (layer.shadowOffset.height < 0) {
                        layer.shadowOpacity = 0.05;
                    }
                }
            }
        }];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.appIconView.image = nil;
    self.titleLabel.text = @"";
    self.subtitleLabel.text = @"";
    _containerView.transform = CGAffineTransformIdentity;
    _containerView.layer.borderColor = [UIColor clearColor].CGColor;
}

@end 