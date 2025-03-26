#import "TSSettingsViewController.h"
#import "TSUIStyleManager.h"
#import "TSNeumorphicButton.h"
#import <TSUtil.h>
#import "TSPresentationDelegate.h"
#import "TSInstallationController.h"
#import "TSSettingsAdvancedListController.h"
#import "TSDonateListController.h"

@interface NSUserDefaults (Private)
- (instancetype)_initWithSuiteName:(NSString *)suiteName container:(NSURL *)container;
@end

extern NSUserDefaults* trollStoreUserDefaults(void);

// 类扩展，只包含新增属性
@interface TSSettingsViewController () 
@property (nonatomic, strong) NSString *trollStoreVersion;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIVisualEffectView *blurEffectView; // 毛玻璃效果视图
@end

@implementation TSSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"设置";
    
    // 获取TrollStore版本
    self.trollStoreVersion = [self getTrollStoreVersion];
    
    // 设置光影动态渐变毛玻璃背景 - 使用与根视图控制器相同的背景样式
    [self setupDynamicBackground];
    
    // 初始化滚动视图
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    
    // 增加底部间距，为底部悬浮Dock留出空间
    self.scrollView.contentInset = UIEdgeInsetsMake(10, 0, 90, 0);
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(10, 0, 90, 0);
    
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.scrollView];
    
    // 初始化内容视图
    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.contentView];
    
    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:16],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:-16],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-32]
    ]];
    
    // 获取版本信息和开发者模式状态
    [self fetchVersionInfo];
    [self checkDevModeStatus];
    
    // 构建UI
    [self buildUI];
    
    // 添加通知观察者
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rebuildUI) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rebuildUI) name:@"TrollStoreReloadSettingsNotification" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 每次显示时更新状态并重建UI
    [self checkDevModeStatus];
    [self rebuildUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 确保滚动视图滚动到顶部
    if (self.scrollView.contentOffset.y > 0) {
        [self.scrollView setContentOffset:CGPointZero animated:YES];
    }
}

- (void)rebuildUI {
    // 安全检查：确保在主线程上执行
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self rebuildUI];
        });
        return;
    }
    
    // 安全检查：确保内容视图已加载
    if (!self.contentView) {
        NSLog(@"警告：无法重建UI，contentView未初始化");
        return;
    }
    
    @try {
        // 清除现有子视图
        for (UIView *subview in self.contentView.subviews) {
            [subview removeFromSuperview];
        }
        
        // 重建UI
        [self buildUI];
        
        // 更新滚动视图内容大小
        [self updateContentSize];
        
        // 确保滚动视图滚动到顶部
        self.scrollView.contentOffset = CGPointZero;
    } @catch (NSException *exception) {
        NSLog(@"重建UI时发生错误: %@", exception);
        
        // 尝试安全地构建最小化UI
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                [self buildMinimalUI];
            } @catch (NSException *innerException) {
                NSLog(@"构建最小化UI时也发生错误: %@", innerException);
                
                // 最后的保底措施：添加一个简单的错误标签
                if (self.contentView) {
                    UILabel *errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.contentView.bounds.size.width - 20, 40)];
                    errorLabel.text = @"加载设置时出错";
                    errorLabel.textAlignment = NSTextAlignmentCenter;
                    [self.contentView addSubview:errorLabel];
                }
            }
        });
    }
}

// 在UI构建失败时显示最小化UI - 增强安全性
- (void)buildMinimalUI {
    // 安全检查：确保在主线程上执行
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self buildMinimalUI];
        });
        return;
    }
    
    // 安全检查：确保内容视图有效
    if (!self.contentView) {
        NSLog(@"警告：无法构建最小化UI，contentView未初始化");
        return;
    }
    
    // 清除现有内容
    for (UIView *subview in self.contentView.subviews) {
        [subview removeFromSuperview];
    }
    
    // 创建错误消息标签
    UILabel *errorLabel = [[UILabel alloc] init];
    errorLabel.text = @"加载设置时出错";
    errorLabel.textAlignment = NSTextAlignmentCenter;
    errorLabel.numberOfLines = 0;
    errorLabel.frame = CGRectMake(20, 50, self.contentView.bounds.size.width - 40, 60);
    [self.contentView addSubview:errorLabel];
    
    // 添加重启按钮
    UIButton *restartButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [restartButton setTitle:@"重启应用" forState:UIControlStateNormal];
    restartButton.frame = CGRectMake((self.contentView.bounds.size.width - 120) / 2, 120, 120, 44);
    [restartButton addTarget:self action:@selector(restartApp) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:restartButton];
    
    // 更新内容大小
    self.scrollView.contentSize = CGSizeMake(self.contentView.bounds.size.width, 200);
}

// 更安全的重启应用方法
- (void)restartApp {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // 尝试重新加载设置视图
            [self rebuildUI];
        } @catch (NSException *exception) {
            NSLog(@"重启应用时发生异常: %@", exception);
            
            // 显示错误提示
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"重启失败" 
                                                                              message:@"请尝试手动关闭并重新打开应用" 
                                                                       preferredStyle:UIAlertControllerStyleAlert];
            [errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:errorAlert animated:YES completion:nil];
        }
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    @try {
        // 更新纹理层和阴影层的尺寸
        for (CALayer *layer in self.view.layer.sublayers) {
            if (layer.frame.size.width >= self.view.bounds.size.width) {
                layer.frame = self.view.bounds;
            }
        }
        
        // 确保内容视图宽度正确
        CGFloat contentWidth = self.scrollView.frame.size.width - 32;
        if (self.contentView.frame.size.width != contentWidth) {
            CGRect contentFrame = self.contentView.frame;
            contentFrame.size.width = contentWidth;
            self.contentView.frame = contentFrame;
            
            // 重新调整所有子视图的宽度
            for (UIView *subview in self.contentView.subviews) {
                CGRect frame = subview.frame;
                frame.size.width = contentWidth;
                subview.frame = frame;
            }
        }
        
        // 确保滚动视图内容尺寸正确
        [self updateContentSize];
    } @catch (NSException *exception) {
        NSLog(@"viewDidLayoutSubviews 发生异常: %@", exception);
    }
}

- (void)setupDynamicBackground {
    // 移除动态渐变背景和毛玻璃效果，改为纯新拟物风格背景
    
    // 创建纯色背景 - 新拟物风格纯白色背景
    self.view.backgroundColor = [UIColor whiteColor]; // 纯白色背景
    
    // 添加极其微妙的纹理，增强新拟物风格效果
    CALayer *textureLayer = [CALayer layer];
    textureLayer.frame = self.view.bounds;
    textureLayer.backgroundColor = [UIColor colorWithPatternImage:[self createNoiseTextureWithIntensity:0.01]].CGColor;
    textureLayer.opacity = 0.2; // 非常微妙的纹理
    [self.view.layer insertSublayer:textureLayer atIndex:0];
    
    // 添加全局的新拟物阴影容器 - 为整个界面提供轻微的新拟物效果
    // 这将给主视图一个非常微妙的立体感
    
    // 右下阴影 - 暗部
    CALayer *darkShadowLayer = [CALayer layer];
    darkShadowLayer.frame = CGRectInset(self.view.bounds, -10, -10);
    darkShadowLayer.backgroundColor = [UIColor clearColor].CGColor;
    darkShadowLayer.shadowColor = [UIColor blackColor].CGColor;
    darkShadowLayer.shadowOffset = CGSizeMake(2, 2);
    darkShadowLayer.shadowRadius = 10;
    darkShadowLayer.shadowOpacity = 0.08;
    [self.view.layer insertSublayer:darkShadowLayer atIndex:0];
    
    // 左上阴影 - 亮部
    CALayer *lightShadowLayer = [CALayer layer];
    lightShadowLayer.frame = CGRectInset(self.view.bounds, -10, -10);
    lightShadowLayer.backgroundColor = [UIColor clearColor].CGColor;
    lightShadowLayer.shadowColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.95 alpha:1.0].CGColor;
    lightShadowLayer.shadowOffset = CGSizeMake(-2, -2);
    lightShadowLayer.shadowRadius = 10;
    lightShadowLayer.shadowOpacity = 0.4;
    [self.view.layer insertSublayer:lightShadowLayer atIndex:0];
}

// 创建微妙的噪点纹理，增强新拟物风格的质感
- (UIImage *)createNoiseTextureWithIntensity:(CGFloat)intensity {
    CGSize size = CGSizeMake(200, 200);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (int y = 0; y < size.height; y++) {
        for (int x = 0; x < size.width; x++) {
            CGFloat white = (arc4random() % 100) / 100.0 * intensity;
            CGFloat gray = 0.5 + white; // 灰色值，范围在0.5到0.5+intensity之间
            CGContextSetGrayFillColor(context, gray, 1.0);
            CGContextFillRect(context, CGRectMake(x, y, 1, 1));
        }
    }
    
    UIImage *noiseImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return noiseImage;
}

- (void)fetchVersionInfo {
#ifndef TROLLSTORE_LITE
    fetchLatestTrollStoreVersion(^(NSString* latestVersion) {
        NSString* currentVersion = self.trollStoreVersion;
        NSComparisonResult result = [currentVersion compare:latestVersion options:NSNumericSearch];
        if(result == NSOrderedAscending) {
            self.newerVersion = latestVersion;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self rebuildUI];
            });
        }
    });
    
    fetchLatestLdidVersion(^(NSString* latestVersion) {
        NSString* ldidVersionPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"ldid.version"];
        NSString* ldidVersion = nil;
        NSData* ldidVersionData = [NSData dataWithContentsOfFile:ldidVersionPath];
        if(ldidVersionData) {
            ldidVersion = [[NSString alloc] initWithData:ldidVersionData encoding:NSUTF8StringEncoding];
        }
        
        if(![latestVersion isEqualToString:ldidVersion]) {
            self.newerLdidVersion = latestVersion;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self rebuildUI];
            });
        }
    });
#endif
}

- (void)checkDevModeStatus {
#ifndef TROLLSTORE_LITE
    if (@available(iOS 16, *)) {
        self.devModeEnabled = spawnRoot(rootHelperPath(), @[@"check-dev-mode"], nil, nil) == 0;
    } else {
        self.devModeEnabled = YES;
    }
#endif
}

- (void)buildUI {
    // 重新获取必要的状态信息
    [self checkDevModeStatus];
    
    CGFloat yPos = 0;
    CGFloat sectionSpacing = 30;
    CGFloat itemSpacing = 15;
    
#ifndef TROLLSTORE_LITE
    // 更新部分
    if (self.newerVersion) {
        yPos = [self addSectionTitleWithText:@"更新可用" atPosition:yPos];
        yPos += 10;
        
        NSString *buttonTitle = [NSString stringWithFormat:@"更新 TrollStore 到 %@", self.newerVersion];
        TSNeumorphicButton *updateButton = [self createButtonWithTitle:buttonTitle 
                                                subtitle:@"点击下载并安装最新版本"
                                               icon:[UIImage systemImageNamed:@"arrow.down.circle"]
                                              action:@selector(updateTrollStorePressed)];
        updateButton.frame = CGRectMake(0, yPos, self.contentView.bounds.size.width, 55);
        [self.contentView addSubview:updateButton];
        yPos += 55 + sectionSpacing;
    }
    
    // 开发者模式部分
    if (!self.devModeEnabled) {
        yPos = [self addSectionTitleWithText:@"开发者模式" atPosition:yPos];
        yPos += 10;
        
        UILabel *devModeDescription = [self createDescriptionLabelWithText:@"某些应用需要启用开发者模式才能运行。这需要重启设备才能生效。"];
        devModeDescription.frame = CGRectMake(10, yPos, self.contentView.bounds.size.width - 20, 60);
        [self.contentView addSubview:devModeDescription];
        yPos += 60 + 10;
        
        TSNeumorphicButton *enableDevModeButton = [self createButtonWithTitle:@"启用开发者模式" 
                                                      subtitle:@"需要重启设备"
                                                     icon:[UIImage systemImageNamed:@"hammer"]
                                                    action:@selector(enableDevModePressed)];
        enableDevModeButton.frame = CGRectMake(0, yPos, self.contentView.bounds.size.width, 55);
        [self.contentView addSubview:enableDevModeButton];
        yPos += 55 + sectionSpacing;
    }
#endif
    
    // 工具部分
    yPos = [self addSectionTitleWithText:@"工具" atPosition:yPos];
    yPos += 10;
    
    NSString *utilitiesDescription = @"";
#ifdef TROLLSTORE_LITE
    if (shouldRegisterAsUserByDefault()) {
        utilitiesDescription = @"由于已安装 AppSync Unified，应用程序将默认注册为用户级别应用。\n\n";
    } else {
        utilitiesDescription = @"由于未安装 AppSync Unified，应用程序将默认注册为系统级别应用。当应用程序失去系统注册并停止工作时，请按此处的"刷新应用程序注册"进行修复。\n\n";
    }
#endif
    utilitiesDescription = [utilitiesDescription stringByAppendingString:@"如果应用安装后没有立即显示，请在此处重新启动 SpringBoard，之后应该会显示。"];
    
    UILabel *utilitiesDescription2 = [self createDescriptionLabelWithText:utilitiesDescription];
    utilitiesDescription2.frame = CGRectMake(10, yPos, self.contentView.bounds.size.width - 20, 100);
    [self.contentView addSubview:utilitiesDescription2];
    yPos += 100 + 10;
    
    // 重新启动按钮
    TSNeumorphicButton *respringButton = [self createButtonWithTitle:@"重新启动 SpringBoard"
                                                subtitle:@"刷新主屏幕和应用程序"
                                               icon:[UIImage systemImageNamed:@"arrow.clockwise.circle"]
                                              action:@selector(respringButtonPressed)];
    respringButton.frame = CGRectMake(0, yPos, self.contentView.bounds.size.width, 55);
    [self.contentView addSubview:respringButton];
    yPos += 55 + itemSpacing;
    
    // 刷新应用注册按钮
    TSNeumorphicButton *refreshButton = [self createButtonWithTitle:@"刷新应用程序注册" 
                                              subtitle:@"修复无法打开的应用" 
                                             icon:[UIImage systemImageNamed:@"arrow.triangle.2.circlepath.circle"]
                                            action:@selector(refreshAppRegistrationsPressed)];
    refreshButton.frame = CGRectMake(0, yPos, self.contentView.bounds.size.width, 55);
    [self.contentView addSubview:refreshButton];
    yPos += 55 + itemSpacing;
    
    // 重建图标缓存按钮
    TSNeumorphicButton *rebuildButton = [self createButtonWithTitle:@"重建图标缓存" 
                                              subtitle:@"刷新主屏幕图标"
                                             icon:[UIImage systemImageNamed:@"photo.circle"]
                                            action:@selector(rebuildIconCachePressed)];
    rebuildButton.frame = CGRectMake(0, yPos, self.contentView.bounds.size.width, 55);
    [self.contentView addSubview:rebuildButton];
    yPos += 55 + sectionSpacing;
    
    // URL 方案部分
    yPos = [self addSectionTitleWithText:@"安全性" atPosition:yPos];
    yPos += 10;
    
    UILabel *urlSchemeDescription = [self createDescriptionLabelWithText:@"启用 URL 方案后，应用程序和网站可以通过 apple-magnifier://install?url=<IPA_URL> URL 方案触发 TrollStore 安装，并通过 apple-magnifier://enable-jit?bundle-id=<BUNDLE_ID> URL 方案启用 JIT。"];
    urlSchemeDescription.frame = CGRectMake(10, yPos, self.contentView.bounds.size.width - 20, 80);
    [self.contentView addSubview:urlSchemeDescription];
    yPos += 80 + 10;
    
    // URL 方案开关
    UIView *switchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, yPos, self.contentView.bounds.size.width, 50)];
    [TSUIStyleManager applyNeumorphicStyleToView:switchContainer];
    
    UILabel *switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, switchContainer.bounds.size.width - 70, 50)];
    switchLabel.text = @"启用 URL 方案";
    switchLabel.textColor = [TSUIStyleManager textColor];
    switchLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    [switchContainer addSubview:switchLabel];
    
    UISwitch *urlSchemeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(switchContainer.bounds.size.width - 70, 10, 51, 31)];
    urlSchemeSwitch.on = (BOOL)[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    urlSchemeSwitch.onTintColor = [TSUIStyleManager accentColor]; // 使用主题色
    [urlSchemeSwitch addTarget:self action:@selector(urlSchemeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [switchContainer addSubview:urlSchemeSwitch];
    
    [self.contentView addSubview:switchContainer];
    yPos += 50 + 10;
    
    // 安装确认选项
    UIView *confirmContainer = [[UIView alloc] initWithFrame:CGRectMake(0, yPos, self.contentView.bounds.size.width, 50)];
    [TSUIStyleManager applyNeumorphicStyleToView:confirmContainer];
    
    UILabel *confirmLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, confirmContainer.bounds.size.width - 40, 50)];
    confirmLabel.text = @"显示安装确认提示";
    confirmLabel.textColor = [TSUIStyleManager textColor];
    confirmLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    [confirmContainer addSubview:confirmLabel];
    
    // 添加右侧箭头
    UIImageView *accessoryImageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
    accessoryImageView.tintColor = [TSUIStyleManager textColor];
    accessoryImageView.frame = CGRectMake(confirmContainer.bounds.size.width - 30, 17, 10, 16);
    [confirmContainer addSubview:accessoryImageView];
    
    // 添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showInstallConfirmationOptions)];
    [confirmContainer addGestureRecognizer:tapGesture];
    
    [self.contentView addSubview:confirmContainer];
    yPos += 50 + sectionSpacing;
    
    // 高级选项部分
    TSNeumorphicButton *advancedButton = [self createButtonWithTitle:@"高级选项" 
                                               subtitle:@"更多设置和配置选项"
                                              icon:[UIImage systemImageNamed:@"gearshape.2"]
                                             action:@selector(showAdvancedOptions)];
    advancedButton.frame = CGRectMake(0, yPos, self.contentView.bounds.size.width, 55);
    [self.contentView addSubview:advancedButton];
    yPos += 55 + itemSpacing;
    
    // 捐赠按钮
    TSNeumorphicButton *donateButton = [self createButtonWithTitle:@"捐赠" 
                                            subtitle:@"支持开发者继续更新"
                                           icon:[UIImage systemImageNamed:@"heart"]
                                          action:@selector(showDonateOptions)];
    donateButton.frame = CGRectMake(0, yPos, self.contentView.bounds.size.width, 55);
    [self.contentView addSubview:donateButton];
    yPos += 55 + sectionSpacing;
    
#ifndef TROLLSTORE_LITE
    // 卸载 TrollStore 按钮
    TSNeumorphicButton *uninstallButton = [self createButtonWithTitle:@"卸载 TrollStore" 
                                                subtitle:@"移除所有通过 TrollStore 安装的应用"
                                               icon:[UIImage systemImageNamed:@"trash"]
                                              action:@selector(uninstallTrollStorePressed)];
    uninstallButton.frame = CGRectMake(0, yPos, self.contentView.bounds.size.width, 55);
    [self.contentView addSubview:uninstallButton];
    yPos += 55 + sectionSpacing;
#endif
    
    // 版本信息 - 使用半透明卡片样式
    UIView *versionCard = [[UIView alloc] initWithFrame:CGRectMake(0, yPos, self.contentView.bounds.size.width, 60)];
    [TSUIStyleManager applyNeumorphicStyleToView:versionCard];
    
    UILabel *versionLabel = [[UILabel alloc] init];
    versionLabel.text = [NSString stringWithFormat:@"TrollStore %@\n© 2022-2024 Lars Fröder (opa334)", self.trollStoreVersion];
    versionLabel.textColor = [TSUIStyleManager secondaryTextColor];
    versionLabel.font = [UIFont systemFontOfSize:13];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.numberOfLines = 0;
    versionLabel.frame = CGRectMake(0, 0, versionCard.bounds.size.width, versionCard.bounds.size.height);
    [versionCard addSubview:versionLabel];
    [self.contentView addSubview:versionCard];
    
    yPos += 60 + 30;
    
    // 更新滚动视图的内容尺寸
    CGSize contentSize = CGSizeMake(self.contentView.bounds.size.width, yPos);
    if (!CGSizeEqualToSize(self.scrollView.contentSize, contentSize)) {
        self.scrollView.contentSize = contentSize;
        
        // 调整内容视图的高度
        CGRect contentFrame = self.contentView.frame;
        contentFrame.size.height = yPos;
        self.contentView.frame = contentFrame;
    }
}

#pragma mark - UI 辅助方法

- (CGFloat)addSectionTitleWithText:(NSString *)text atPosition:(CGFloat)yPos {
    UILabel *sectionTitle = [[UILabel alloc] init];
    sectionTitle.text = text;
    sectionTitle.textColor = [TSUIStyleManager textColor];
    sectionTitle.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    
    [sectionTitle sizeToFit];
    sectionTitle.frame = CGRectMake(10, yPos, sectionTitle.frame.size.width, sectionTitle.frame.size.height);
    [self.contentView addSubview:sectionTitle];
    
    return yPos + sectionTitle.frame.size.height;
}

- (UILabel *)createDescriptionLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = [TSUIStyleManager secondaryTextColor];
    label.font = [UIFont systemFontOfSize:14];
    label.numberOfLines = 0;
    return label;
}

- (TSNeumorphicButton *)createButtonWithTitle:(NSString *)title subtitle:(NSString *)subtitle icon:(UIImage *)icon action:(SEL)action {
    TSNeumorphicButton *button = [[TSNeumorphicButton alloc] initWithStyle:TSButtonStyleNeumorphic];
    [button setTitle:title subtitle:subtitle];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button setIcon:icon];
    
    return button;
}

#pragma mark - 辅助方法

- (NSString *)getTrollStoreVersion {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return version;
}

#pragma mark - 操作方法

// 重新启动 SpringBoard
- (void)respringButtonPressed {
    respring();
}

// 刷新应用程序注册
- (void)refreshAppRegistrationsPressed {
    int ret = spawnRoot(rootHelperPath(), @[@"refresh-apps"], nil, nil);
    if (ret == 0) {
        UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"成功" 
                                                                             message:@"应用程序注册已刷新" 
                                                                      preferredStyle:UIAlertControllerStyleAlert];
        [successAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [TSPresentationDelegate presentViewController:successAlert animated:YES completion:nil];
    }
}

// 重建图标缓存
- (void)rebuildIconCachePressed {
    [TSPresentationDelegate startActivity:@"重建图标缓存"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        spawnRoot(rootHelperPath(), @[@"uicache", @"-a"], nil, nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            [TSPresentationDelegate stopActivityWithCompletion:nil];
        });
    });
}

// URL方案开关变更
- (void)urlSchemeSwitchChanged:(UISwitch *)sender {
    NSString *newStateString = sender.on ? @"enable" : @"disable";
    spawnRoot(rootHelperPath(), @[@"url-scheme", newStateString], nil, nil);
    
    UIAlertController *rebuildNoticeAlert = [UIAlertController alertControllerWithTitle:@"URL 方案已更改" 
                                                                                message:@"为了正确应用 URL 方案设置的更改，需要重建图标缓存。" 
                                                                         preferredStyle:UIAlertControllerStyleAlert];
    [rebuildNoticeAlert addAction:[UIAlertAction actionWithTitle:@"立即重建" 
                                                          style:UIAlertActionStyleDefault 
                                                        handler:^(UIAlertAction *action) {
        [self rebuildIconCachePressed];
    }]];
    
    [rebuildNoticeAlert addAction:[UIAlertAction actionWithTitle:@"稍后重建" 
                                                          style:UIAlertActionStyleCancel 
                                                        handler:nil]];
    
    [TSPresentationDelegate presentViewController:rebuildNoticeAlert animated:YES completion:nil];
}

// 显示安装确认选项
- (void)showInstallConfirmationOptions {
    UIAlertController *optionsAlert = [UIAlertController alertControllerWithTitle:@"显示安装确认提示" 
                                                                          message:nil 
                                                                   preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray *options = @[@"始终显示（推荐）", @"仅远程 URL 安装时显示", @"从不显示（不推荐）"];
    NSUserDefaults *tsDefaults = trollStoreUserDefaults();
    NSNumber *currentSetting = [tsDefaults objectForKey:@"installAlertConfiguration"];
    int currentValue = currentSetting ? [currentSetting intValue] : 0;
    
    for (int i = 0; i < options.count; i++) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:options[i] 
                                                         style:UIAlertActionStyleDefault 
                                                       handler:^(UIAlertAction *action) {
            [tsDefaults setObject:@(i) forKey:@"installAlertConfiguration"];
        }];
        
        if (i == currentValue) {
            action.accessibilityTraits = UIAccessibilityTraitSelected;
        }
        
        [optionsAlert addAction:action];
    }
    
    [optionsAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [TSPresentationDelegate presentViewController:optionsAlert animated:YES completion:nil];
}

// 显示高级选项
- (void)showAdvancedOptions {
    TSSettingsAdvancedListController *advancedVC = [[TSSettingsAdvancedListController alloc] init];
    [self.navigationController pushViewController:advancedVC animated:YES];
}

// 显示捐赠选项
- (void)showDonateOptions {
    TSDonateListController *donateVC = [[TSDonateListController alloc] init];
    [self.navigationController pushViewController:donateVC animated:YES];
}

#ifndef TROLLSTORE_LITE
// 更新 TrollStore
- (void)updateTrollStorePressed {
    NSURL *trollStoreURL = [NSURL URLWithString:@"https://github.com/opa334/TrollStore/releases/latest/download/TrollStore.tar"];
    [[UIApplication sharedApplication] openURL:trollStoreURL options:@{} completionHandler:nil];
}

// 启用开发者模式
- (void)enableDevModePressed {
    int ret = spawnRoot(rootHelperPath(), @[@"arm-dev-mode"], nil, nil);
    
    if (ret == 0) {
        UIAlertController *rebootNotification = [UIAlertController alertControllerWithTitle:@"需要重启" 
                                                                                   message:@"重启后，选择\"打开\"以启用开发者模式。" 
                                                                            preferredStyle:UIAlertControllerStyleAlert];
        
        [rebootNotification addAction:[UIAlertAction actionWithTitle:@"关闭" 
                                                               style:UIAlertActionStyleCancel 
                                                             handler:^(UIAlertAction *action) {
            [self rebuildUI];
        }]];
        
        [rebootNotification addAction:[UIAlertAction actionWithTitle:@"立即重启" 
                                                               style:UIAlertActionStyleDefault 
                                                             handler:^(UIAlertAction *action) {
            spawnRoot(rootHelperPath(), @[@"reboot"], nil, nil);
        }]];
        
        [TSPresentationDelegate presentViewController:rebootNotification animated:YES completion:nil];
    } else {
        UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"错误 %d", ret] 
                                                                            message:@"启用开发者模式失败。" 
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        
        [errorAlert addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil]];
        [TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
    }
}

// 卸载 TrollStore
- (void)uninstallTrollStorePressed {
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"确认卸载" 
                                                                          message:@"您确定要卸载 TrollStore 吗？这将移除所有通过 TrollStore 安装的应用程序。" 
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"卸载" 
                                                     style:UIAlertActionStyleDestructive 
                                                   handler:^(UIAlertAction *action) {
        NSMutableArray *args = @[@"uninstall-trollstore"].mutableCopy;
        
        NSNumber *uninstallationMethodToUseNum = [trollStoreUserDefaults() objectForKey:@"uninstallationMethod"];
        int uninstallationMethodToUse = uninstallationMethodToUseNum ? uninstallationMethodToUseNum.intValue : 0;
        if(uninstallationMethodToUse == 1) {
            [args addObject:@"custom"];
        }
        
        spawnRoot(rootHelperPath(), args, nil, nil);
    }]];
    
    [TSPresentationDelegate presentViewController:confirmAlert animated:YES completion:nil];
}
#endif

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateContentSize {
    // 安全检查：确保在主线程上执行
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateContentSize];
        });
        return;
    }
    
    // 安全检查
    if (!self.contentView || !self.scrollView) {
        NSLog(@"警告：无法更新内容大小，视图未初始化");
        return;
    }
    
    @try {
        // 计算内容视图中最底部子视图的位置
        CGFloat maxY = 0;
        for (UIView *subview in self.contentView.subviews) {
            CGFloat viewMaxY = CGRectGetMaxY(subview.frame);
            if (viewMaxY > maxY) {
                maxY = viewMaxY;
            }
        }
        
        // 确保内容大小至少和滚动视图一样高
        CGFloat minHeight = self.scrollView.frame.size.height;
        CGFloat contentHeight = MAX(maxY + 30, minHeight); // 添加底部间距
        
        // 设置内容大小
        self.scrollView.contentSize = CGSizeMake(self.contentView.frame.size.width, contentHeight);
        
        // 调整内容视图的高度
        CGRect contentFrame = self.contentView.frame;
        contentFrame.size.height = contentHeight;
        self.contentView.frame = contentFrame;
    } @catch (NSException *exception) {
        NSLog(@"更新内容大小时发生异常: %@", exception);
    }
}

@end 