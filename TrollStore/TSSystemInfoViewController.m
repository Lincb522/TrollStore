#import "TSSystemInfoViewController.h"
#import "TSUIStyleManager.h"
#import "TSNeumorphicButton.h"
#import <TSUtil.h>
#import <sys/utsname.h>

@implementation TSSystemInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"系统信息";
    
    // 设置动态背景效果
    [self setupDynamicBackground];
    
    [self setupUI];
    [self loadSystemInfo];
}

// 添加动态背景效果方法
- (void)setupDynamicBackground {
    // 创建一个纹理背景层
    CALayer *textureLayer = [CALayer layer];
    textureLayer.frame = self.view.bounds;
    textureLayer.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0].CGColor;
    [self.view.layer insertSublayer:textureLayer atIndex:0];
    
    // 添加噪点纹理
    UIImage *noiseImage = [self generateNoiseTextureWithSize:CGSizeMake(200, 200) opacity:0.03];
    textureLayer.contents = (__bridge id)noiseImage.CGImage;
    textureLayer.contentsGravity = kCAGravityResize;
}

// 生成噪点纹理图像
- (UIImage *)generateNoiseTextureWithSize:(CGSize)size opacity:(CGFloat)opacity {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (int i = 0; i < size.width * size.height * 0.1; i++) {
        CGFloat x = arc4random_uniform(size.width);
        CGFloat y = arc4random_uniform(size.height);
        CGFloat width = 1.0;
        CGFloat height = 1.0;
        
        CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.0 alpha:opacity].CGColor);
        CGContextFillRect(context, CGRectMake(x, y, width, height));
    }
    
    UIImage *noiseImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return noiseImage;
}

// 添加生命周期方法来确保布局正确刷新
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 强制更新布局
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    // 滚动到顶部
    if (_scrollView.contentOffset.y > 0) {
        [_scrollView setContentOffset:CGPointZero animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 确保滚动视图的内容偏移量重置到顶部
    [_scrollView setContentOffset:CGPointZero animated:NO];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // 确保动态背景填充整个视图
    for (CALayer *layer in self.view.layer.sublayers) {
        if (layer.frame.size.width >= self.view.bounds.size.width) {
            layer.frame = self.view.bounds;
        }
    }
    
    // 更新内容尺寸
    [self updateContentSize];
}

- (void)updateContentSize {
    // 查找最底部的子视图
    CGFloat maxY = 0;
    for (UIView *subview in _contentView.subviews) {
        CGFloat subviewMaxY = CGRectGetMaxY(subview.frame);
        if (subviewMaxY > maxY) {
            maxY = subviewMaxY;
        }
    }
    
    // 更新滚动视图的内容尺寸
    CGSize contentSize = CGSizeMake(_contentView.frame.size.width, maxY + 30); // 底部添加额外的间距
    if (!CGSizeEqualToSize(_scrollView.contentSize, contentSize)) {
        _scrollView.contentSize = contentSize;
    }
}

- (void)setupUI {
    // 创建滚动视图
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.showsVerticalScrollIndicator = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    
    // 增加内容底部间距，为底部悬浮Dock留出空间
    _scrollView.contentInset = UIEdgeInsetsMake(0, 0, 80, 0);
    _scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 80, 0);
    
    // 设置透明背景
    _scrollView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:_scrollView];
    
    // 创建内容视图
    _contentView = [[UIView alloc] init];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentView.backgroundColor = [UIColor clearColor];
    [_scrollView addSubview:_contentView];
    
    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_scrollView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [_scrollView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        [_contentView.topAnchor constraintEqualToAnchor:_scrollView.topAnchor],
        [_contentView.leftAnchor constraintEqualToAnchor:_scrollView.leftAnchor constant:20],
        [_contentView.rightAnchor constraintEqualToAnchor:_scrollView.rightAnchor constant:-20],
        [_contentView.bottomAnchor constraintEqualToAnchor:_scrollView.bottomAnchor],
        [_contentView.widthAnchor constraintEqualToAnchor:_scrollView.widthAnchor constant:-40]
    ]];
}

- (void)loadSystemInfo {
    // 添加TrollStore Logo - 增强新拟物风格
    UIView *logoContainer = [[UIView alloc] init];
    logoContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [TSUIStyleManager applyNeumorphicStyleToView:logoContainer];
    logoContainer.layer.cornerRadius = 60; // 大圆角边框
    [_contentView addSubview:logoContainer];
    
    UIImageView *logoView = [[UIImageView alloc] init];
    logoView.translatesAutoresizingMaskIntoConstraints = NO;
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    logoView.image = [UIImage imageNamed:@"AppIcon60x60"];
    logoView.layer.cornerRadius = 45; // 图标圆角
    logoView.layer.masksToBounds = YES;
    [logoContainer addSubview:logoView];
    
    // 添加大号标题 - 使用新拟物风格
    UIView *titleContainer = [[UIView alloc] init];
    titleContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [TSUIStyleManager applyNeumorphicStyleToView:titleContainer];
    [_contentView addSubview:titleContainer];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"TrollStore";
    titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
    titleLabel.textColor = [TSUIStyleManager textColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [titleContainer addSubview:titleLabel];
    
    // 创建版本信息卡片 - 使用新拟物风格
    UIView *versionCard = [[UIView alloc] init];
    versionCard.translatesAutoresizingMaskIntoConstraints = NO;
    [TSUIStyleManager applyNeumorphicStyleToView:versionCard];
    [_contentView addSubview:versionCard];
    
    // 版本标题图标 - 增加视觉吸引力
    UIImageView *versionIcon = [[UIImageView alloc] init];
    versionIcon.translatesAutoresizingMaskIntoConstraints = NO;
    versionIcon.image = [UIImage systemImageNamed:@"info.circle.fill"];
    versionIcon.contentMode = UIViewContentModeScaleAspectFit;
    versionIcon.tintColor = [TSUIStyleManager accentColor];
    [versionCard addSubview:versionIcon];
    
    // 版本标题 - 使用新拟物风格字体
    UILabel *versionTitle = [[UILabel alloc] init];
    versionTitle.translatesAutoresizingMaskIntoConstraints = NO;
    versionTitle.text = @"版本信息";
    versionTitle.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    versionTitle.textColor = [TSUIStyleManager textColor];
    [versionCard addSubview:versionTitle];
    
    // 版本信息 - 使用新拟物风格字体
    UILabel *versionInfo = [[UILabel alloc] init];
    versionInfo.translatesAutoresizingMaskIntoConstraints = NO;
    versionInfo.text = [NSString stringWithFormat:@"版本: %@", [self getTrollStoreVersion]];
    versionInfo.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    versionInfo.textColor = [TSUIStyleManager secondaryTextColor];
    versionInfo.numberOfLines = 0;
    [versionCard addSubview:versionInfo];
    
    // 创建系统信息卡片 - 使用新拟物风格
    UIView *systemCard = [[UIView alloc] init];
    systemCard.translatesAutoresizingMaskIntoConstraints = NO;
    [TSUIStyleManager applyNeumorphicStyleToView:systemCard];
    [_contentView addSubview:systemCard];
    
    // 系统信息图标
    UIImageView *systemIcon = [[UIImageView alloc] init];
    systemIcon.translatesAutoresizingMaskIntoConstraints = NO;
    systemIcon.image = [UIImage systemImageNamed:@"gear.circle.fill"];
    systemIcon.contentMode = UIViewContentModeScaleAspectFit;
    systemIcon.tintColor = [TSUIStyleManager accentColor];
    [systemCard addSubview:systemIcon];
    
    // 系统信息标题 - 使用新拟物风格字体
    UILabel *systemTitle = [[UILabel alloc] init];
    systemTitle.translatesAutoresizingMaskIntoConstraints = NO;
    systemTitle.text = @"系统信息";
    systemTitle.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    systemTitle.textColor = [TSUIStyleManager textColor];
    [systemCard addSubview:systemTitle];
    
    // 系统信息内容 - 使用新拟物风格字体
    UILabel *systemInfo = [[UILabel alloc] init];
    systemInfo.translatesAutoresizingMaskIntoConstraints = NO;
    systemInfo.text = [self getSystemInfoText];
    systemInfo.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    systemInfo.textColor = [TSUIStyleManager secondaryTextColor];
    systemInfo.numberOfLines = 0;
    [systemCard addSubview:systemInfo];
    
    // 添加操作按钮区域 - 使用新拟物风格
    UIView *actionsContainer = [[UIView alloc] init];
    actionsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [TSUIStyleManager applyNeumorphicStyleToView:actionsContainer];
    [_contentView addSubview:actionsContainer];
    
    // 操作标题图标
    UIImageView *actionsIcon = [[UIImageView alloc] init];
    actionsIcon.translatesAutoresizingMaskIntoConstraints = NO;
    actionsIcon.image = [UIImage systemImageNamed:@"bolt.horizontal.circle.fill"];
    actionsIcon.contentMode = UIViewContentModeScaleAspectFit;
    actionsIcon.tintColor = [TSUIStyleManager accentColor];
    [actionsContainer addSubview:actionsIcon];
    
    // 操作标题
    UILabel *actionsTitle = [[UILabel alloc] init];
    actionsTitle.translatesAutoresizingMaskIntoConstraints = NO;
    actionsTitle.text = @"快速操作";
    actionsTitle.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    actionsTitle.textColor = [TSUIStyleManager textColor];
    [actionsContainer addSubview:actionsTitle];
    
    // 重启SpringBoard按钮
    UIButton *respringButton = [UIButton buttonWithType:UIButtonTypeCustom];
    respringButton.translatesAutoresizingMaskIntoConstraints = NO;
    [respringButton setTitle:@"重启SpringBoard" forState:UIControlStateNormal];
    [respringButton setTitleColor:[TSUIStyleManager accentColor] forState:UIControlStateNormal];
    respringButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [respringButton addTarget:self action:@selector(respringButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [TSUIStyleManager applyToolbarButtonStyle:respringButton];
    [actionsContainer addSubview:respringButton];
    
    // 刷新应用注册按钮
    UIButton *refreshAppsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    refreshAppsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [refreshAppsButton setTitle:@"刷新应用注册" forState:UIControlStateNormal];
    [refreshAppsButton setTitleColor:[TSUIStyleManager accentColor] forState:UIControlStateNormal];
    refreshAppsButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [refreshAppsButton addTarget:self action:@selector(refreshAppRegistrationsPressed) forControlEvents:UIControlEventTouchUpInside];
    [TSUIStyleManager applyToolbarButtonStyle:refreshAppsButton];
    [actionsContainer addSubview:refreshAppsButton];
    
    // 重建图标缓存按钮
    UIButton *rebuildIconsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rebuildIconsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [rebuildIconsButton setTitle:@"重建图标缓存" forState:UIControlStateNormal];
    [rebuildIconsButton setTitleColor:[TSUIStyleManager accentColor] forState:UIControlStateNormal];
    rebuildIconsButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [rebuildIconsButton addTarget:self action:@selector(rebuildIconCachePressed) forControlEvents:UIControlEventTouchUpInside];
    [TSUIStyleManager applyToolbarButtonStyle:rebuildIconsButton];
    [actionsContainer addSubview:rebuildIconsButton];
    
    // 添加底部链接区域
    UIView *linksContainer = [[UIView alloc] init];
    linksContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [TSUIStyleManager applyNeumorphicStyleToView:linksContainer];
    [_contentView addSubview:linksContainer];
    
    // GitHub按钮
    UIButton *githubButton = [UIButton buttonWithType:UIButtonTypeCustom];
    githubButton.translatesAutoresizingMaskIntoConstraints = NO;
    [githubButton setTitle:@"GitHub项目页面" forState:UIControlStateNormal];
    [githubButton setTitleColor:[TSUIStyleManager accentColor] forState:UIControlStateNormal];
    githubButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [githubButton addTarget:self action:@selector(openGithubPage) forControlEvents:UIControlEventTouchUpInside];
    [TSUIStyleManager applyToolbarButtonStyle:githubButton];
    [linksContainer addSubview:githubButton];
    
    // 贡献者按钮
    UIButton *creditsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    creditsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [creditsButton setTitle:@"查看贡献者" forState:UIControlStateNormal];
    [creditsButton setTitleColor:[TSUIStyleManager accentColor] forState:UIControlStateNormal];
    creditsButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [creditsButton addTarget:self action:@selector(showCredits) forControlEvents:UIControlEventTouchUpInside];
    [TSUIStyleManager applyToolbarButtonStyle:creditsButton];
    [linksContainer addSubview:creditsButton];
    
    // 设置约束 - 使用更合理的间距和布局
    [NSLayoutConstraint activateConstraints:@[
        // Logo容器约束
        [logoContainer.topAnchor constraintEqualToAnchor:_contentView.topAnchor constant:30],
        [logoContainer.centerXAnchor constraintEqualToAnchor:_contentView.centerXAnchor],
        [logoContainer.widthAnchor constraintEqualToConstant:120],
        [logoContainer.heightAnchor constraintEqualToConstant:120],
        
        // Logo图标约束
        [logoView.centerXAnchor constraintEqualToAnchor:logoContainer.centerXAnchor],
        [logoView.centerYAnchor constraintEqualToAnchor:logoContainer.centerYAnchor],
        [logoView.widthAnchor constraintEqualToConstant:90],
        [logoView.heightAnchor constraintEqualToConstant:90],
        
        // 标题容器约束
        [titleContainer.topAnchor constraintEqualToAnchor:logoContainer.bottomAnchor constant:20],
        [titleContainer.centerXAnchor constraintEqualToAnchor:_contentView.centerXAnchor],
        [titleContainer.widthAnchor constraintEqualToConstant:200],
        [titleContainer.heightAnchor constraintEqualToConstant:60],
        
        // 标题标签约束
        [titleLabel.centerXAnchor constraintEqualToAnchor:titleContainer.centerXAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:titleContainer.centerYAnchor],
        [titleLabel.leftAnchor constraintEqualToAnchor:titleContainer.leftAnchor constant:10],
        [titleLabel.rightAnchor constraintEqualToAnchor:titleContainer.rightAnchor constant:-10],
        
        // 版本卡片约束
        [versionCard.topAnchor constraintEqualToAnchor:titleContainer.bottomAnchor constant:25],
        [versionCard.leftAnchor constraintEqualToAnchor:_contentView.leftAnchor],
        [versionCard.rightAnchor constraintEqualToAnchor:_contentView.rightAnchor],
        
        // 版本图标约束
        [versionIcon.topAnchor constraintEqualToAnchor:versionCard.topAnchor constant:16],
        [versionIcon.leftAnchor constraintEqualToAnchor:versionCard.leftAnchor constant:16],
        [versionIcon.widthAnchor constraintEqualToConstant:24],
        [versionIcon.heightAnchor constraintEqualToConstant:24],
        
        // 版本标题约束
        [versionTitle.topAnchor constraintEqualToAnchor:versionCard.topAnchor constant:16],
        [versionTitle.leftAnchor constraintEqualToAnchor:versionIcon.rightAnchor constant:10],
        [versionTitle.rightAnchor constraintEqualToAnchor:versionCard.rightAnchor constant:-16],
        
        // 版本信息约束
        [versionInfo.topAnchor constraintEqualToAnchor:versionTitle.bottomAnchor constant:10],
        [versionInfo.leftAnchor constraintEqualToAnchor:versionCard.leftAnchor constant:16],
        [versionInfo.rightAnchor constraintEqualToAnchor:versionCard.rightAnchor constant:-16],
        [versionInfo.bottomAnchor constraintEqualToAnchor:versionCard.bottomAnchor constant:-16],
        
        // 系统卡片约束
        [systemCard.topAnchor constraintEqualToAnchor:versionCard.bottomAnchor constant:20],
        [systemCard.leftAnchor constraintEqualToAnchor:_contentView.leftAnchor],
        [systemCard.rightAnchor constraintEqualToAnchor:_contentView.rightAnchor],
        
        // 系统图标约束
        [systemIcon.topAnchor constraintEqualToAnchor:systemCard.topAnchor constant:16],
        [systemIcon.leftAnchor constraintEqualToAnchor:systemCard.leftAnchor constant:16],
        [systemIcon.widthAnchor constraintEqualToConstant:24],
        [systemIcon.heightAnchor constraintEqualToConstant:24],
        
        // 系统标题约束
        [systemTitle.topAnchor constraintEqualToAnchor:systemCard.topAnchor constant:16],
        [systemTitle.leftAnchor constraintEqualToAnchor:systemIcon.rightAnchor constant:10],
        [systemTitle.rightAnchor constraintEqualToAnchor:systemCard.rightAnchor constant:-16],
        
        // 系统信息约束
        [systemInfo.topAnchor constraintEqualToAnchor:systemTitle.bottomAnchor constant:10],
        [systemInfo.leftAnchor constraintEqualToAnchor:systemCard.leftAnchor constant:16],
        [systemInfo.rightAnchor constraintEqualToAnchor:systemCard.rightAnchor constant:-16],
        [systemInfo.bottomAnchor constraintEqualToAnchor:systemCard.bottomAnchor constant:-16],
        
        // 操作容器约束
        [actionsContainer.topAnchor constraintEqualToAnchor:systemCard.bottomAnchor constant:20],
        [actionsContainer.leftAnchor constraintEqualToAnchor:_contentView.leftAnchor],
        [actionsContainer.rightAnchor constraintEqualToAnchor:_contentView.rightAnchor],
        
        // 操作图标约束
        [actionsIcon.topAnchor constraintEqualToAnchor:actionsContainer.topAnchor constant:16],
        [actionsIcon.leftAnchor constraintEqualToAnchor:actionsContainer.leftAnchor constant:16],
        [actionsIcon.widthAnchor constraintEqualToConstant:24],
        [actionsIcon.heightAnchor constraintEqualToConstant:24],
        
        // 操作标题约束
        [actionsTitle.topAnchor constraintEqualToAnchor:actionsContainer.topAnchor constant:16],
        [actionsTitle.leftAnchor constraintEqualToAnchor:actionsIcon.rightAnchor constant:10],
        [actionsTitle.rightAnchor constraintEqualToAnchor:actionsContainer.rightAnchor constant:-16],
        
        // 重启按钮约束
        [respringButton.topAnchor constraintEqualToAnchor:actionsTitle.bottomAnchor constant:16],
        [respringButton.leftAnchor constraintEqualToAnchor:actionsContainer.leftAnchor constant:16],
        [respringButton.rightAnchor constraintEqualToAnchor:actionsContainer.rightAnchor constant:-16],
        [respringButton.heightAnchor constraintEqualToConstant:44],
        
        // 刷新应用注册按钮约束
        [refreshAppsButton.topAnchor constraintEqualToAnchor:respringButton.bottomAnchor constant:10],
        [refreshAppsButton.leftAnchor constraintEqualToAnchor:actionsContainer.leftAnchor constant:16],
        [refreshAppsButton.rightAnchor constraintEqualToAnchor:actionsContainer.rightAnchor constant:-16],
        [refreshAppsButton.heightAnchor constraintEqualToConstant:44],
        
        // 重建图标缓存按钮约束
        [rebuildIconsButton.topAnchor constraintEqualToAnchor:refreshAppsButton.bottomAnchor constant:10],
        [rebuildIconsButton.leftAnchor constraintEqualToAnchor:actionsContainer.leftAnchor constant:16],
        [rebuildIconsButton.rightAnchor constraintEqualToAnchor:actionsContainer.rightAnchor constant:-16],
        [rebuildIconsButton.heightAnchor constraintEqualToConstant:44],
        [rebuildIconsButton.bottomAnchor constraintEqualToAnchor:actionsContainer.bottomAnchor constant:-16],
        
        // 链接容器约束
        [linksContainer.topAnchor constraintEqualToAnchor:actionsContainer.bottomAnchor constant:20],
        [linksContainer.leftAnchor constraintEqualToAnchor:_contentView.leftAnchor],
        [linksContainer.rightAnchor constraintEqualToAnchor:_contentView.rightAnchor],
        [linksContainer.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor constant:-30],
        
        // GitHub按钮约束
        [githubButton.topAnchor constraintEqualToAnchor:linksContainer.topAnchor constant:16],
        [githubButton.leftAnchor constraintEqualToAnchor:linksContainer.leftAnchor constant:16],
        [githubButton.rightAnchor constraintEqualToAnchor:linksContainer.rightAnchor constant:-16],
        [githubButton.heightAnchor constraintEqualToConstant:44],
        
        // 贡献者按钮约束
        [creditsButton.topAnchor constraintEqualToAnchor:githubButton.bottomAnchor constant:10],
        [creditsButton.leftAnchor constraintEqualToAnchor:linksContainer.leftAnchor constant:16],
        [creditsButton.rightAnchor constraintEqualToAnchor:linksContainer.rightAnchor constant:-16],
        [creditsButton.heightAnchor constraintEqualToConstant:44],
        [creditsButton.bottomAnchor constraintEqualToAnchor:linksContainer.bottomAnchor constant:-16]
    ]];
}

- (UIView *)createGlassCard {
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [TSUIStyleManager applyNeumorphicStyleToView:card];
    return card;
}

- (NSString *)getTrollStoreVersion {
    NSString *versionPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"version.plist"];
    NSDictionary *versionDict = [NSDictionary dictionaryWithContentsOfFile:versionPath];
    NSString *versionString = versionDict[@"Version"] ?: @"未知";
    return versionString;
}

- (NSString *)getSystemInfoText {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    
    // 检查是否越狱
    BOOL jailbroken = NO;
    if ([NSFileManager.defaultManager fileExistsAtPath:@"/Applications/Cydia.app"] ||
        [NSFileManager.defaultManager fileExistsAtPath:@"/Library/MobileSubstrate/MobileSubstrate.dylib"]) {
        jailbroken = YES;
    }
    NSString *jailbrokenStr = jailbroken ? @"是" : @"否";
    
    BOOL isAppSyncInstalled = shouldRegisterAsUserByDefault();
    NSString *appSyncStatus = isAppSyncInstalled ? @"已安装" : @"未安装";
    
    NSString *infoText = [NSString stringWithFormat:
                         @"设备型号: %@\n"
                         @"iOS 版本: %@\n"
                         @"设备已越狱: %@\n"
                         @"AppSync 状态: %@",
                         deviceModel, systemVersion, jailbrokenStr, appSyncStatus];
    
    return infoText;
}

#pragma mark - Button Actions

- (void)respringButtonPressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重启 SpringBoard" message:@"确定要重启SpringBoard吗？" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        respring();
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:confirmAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)refreshAppRegistrationsPressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"刷新应用注册" message:@"是否要刷新所有应用的注册状态？这将修复无法打开的应用。" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"刷新并重启" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // 使用spawnRoot函数来刷新应用注册
        spawnRoot(rootHelperPath(), @[@"refresh-apps"], nil, nil);
        respring();
    }];
    
    UIAlertAction *refreshOnlyAction = [UIAlertAction actionWithTitle:@"仅刷新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 使用spawnRoot函数来刷新应用注册
        spawnRoot(rootHelperPath(), @[@"refresh-apps"], nil, nil);
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:confirmAction];
    [alert addAction:refreshOnlyAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)rebuildIconCachePressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重建图标缓存" message:@"确定要重建图标缓存吗？这将刷新主屏幕上的所有图标。" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // 使用spawnRoot函数来重建图标缓存
        spawnRoot(rootHelperPath(), @[@"uicache", @"-a"], nil, nil);
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:confirmAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openGithubPage {
    NSURL *githubURL = [NSURL URLWithString:@"https://github.com/opa334/TrollStore"];
    [[UIApplication sharedApplication] openURL:githubURL options:@{} completionHandler:nil];
}

- (void)showCredits {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"贡献者" message:@"@opa334 - TrollStore开发者\n@alfiecg_dev - 发现并自动化了CoreTrust漏洞\nGoogle TAG - 报告了CoreTrust漏洞\n@LinusHenze - 发现了iOS 14-15安装时使用的installd绕过" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:closeAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end 