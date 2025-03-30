#import "TSNewMainViewController.h"
#import "TSAppTableViewController.h"
#import "TSUtil.h"
#import "TSInstallationController.h"
#import "TSApplicationsManager.h"
#import "TSAppInfo.h"
#import "TSNewSettingsViewController.h"
#import <TSPresentationDelegate.h>
@import UniformTypeIdentifiers;

// 定义图标格式常量
#define ICON_FORMAT_IPAD 8
#define ICON_FORMAT_IPHONE 10

// 获取当前设备适用的图标格式 - 改为静态内联函数并重命名
static inline NSInteger ts_iconFormatToUse(void)
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        return ICON_FORMAT_IPAD;
    }
    else
    {
        return ICON_FORMAT_IPHONE;
    }
}

// 调整图片大小的辅助函数 - 改为静态内联函数并重命名
static inline UIImage* ts_imageWithSize(UIImage* image, CGSize size)
{
    if(CGSizeEqualToSize(image.size, size)) return image;
    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
    CGRect imageRect = CGRectMake(0.0, 0.0, size.width, size.height);
    [image drawInRect:imageRect];
    UIImage* outImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outImage;
}

// 声明私有API
@interface UIImage ()
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)id format:(NSInteger)format scale:(double)scale;
@end

@interface TSNewMainViewController ()
@property (nonatomic, strong) NSArray *detailItems;
@property (nonatomic, strong) NSMutableArray *appInfoViews;
@property (nonatomic, strong) UIImage *placeholderIcon; // 添加占位图标
@property (nonatomic, strong) NSMutableDictionary *cachedIcons; // 添加图标缓存

// 添加动态渐变相关属性
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) CAGradientLayer *animatedGradient;
@property (nonatomic, strong) NSArray<UIColor *> *gradientColors;
@property (nonatomic, assign) CGFloat animationValue;
@property (nonatomic, assign) CGFloat animationDirection;

// 流体渐变相关属性
@property (nonatomic, strong) CALayer *baseLayer;
@property (nonatomic, strong) CALayer *highlightLayer;
@property (nonatomic, strong) NSMutableArray *blobs;
@property (nonatomic, strong) NSMutableArray *highlightBlobs;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@end

@implementation TSNewMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 初始化占位图标和图标缓存 - 使用重命名后的函数
    self.placeholderIcon = [UIImage _applicationIconImageForBundleIdentifier:@"com.apple.WebSheet" format:ts_iconFormatToUse() scale:[UIScreen mainScreen].scale];
    self.cachedIcons = [NSMutableDictionary new];
    
    // 初始化渐变动画参数
    self.animationValue = 0.0;
    self.animationDirection = 1.0;
    
    // 设置渐变颜色组
    self.gradientColors = @[
        [UIColor colorWithRed:0.95 green:0.98 blue:1.0 alpha:0.9],   // 非常淡的蓝色（接近白色）
        [UIColor colorWithRed:0.8 green:0.9 blue:0.98 alpha:0.85],   // 淡蓝色
        [UIColor colorWithRed:0.65 green:0.8 blue:0.95 alpha:0.8],   // 中淡蓝色
        [UIColor colorWithRed:0.45 green:0.7 blue:0.9 alpha:0.75],   // 中蓝色
        [UIColor colorWithRed:0.3 green:0.55 blue:0.85 alpha:0.7],   // 深蓝色
        [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:0.65]     // 更深蓝色
    ];
    
    // 设置TSPresentationDelegate的presentationViewController
    TSPresentationDelegate.presentationViewController = self;
    
    // 设置背景视图
    [self setupBackgroundViews];
    
    // 设置顶部状态栏
    [self setupStatusBar];
    
    // 设置顶部位置和天气信息
    [self setupHeaderViews];
    
    // 设置卡片视图
    [self setupCardView];
    
    // 设置详情视图
    [self setupDetailsView];
    
    // 设置提示视图
    [self setupTipsView];
    
    // 设置应用信息视图
    [self setupAppInfoViews];
    
    // 注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAppInfoViews) name:@"ApplicationsChanged" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 开始动画
    [self startGradientAnimation];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // 停止动画
    [self stopGradientAnimation];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopGradientAnimation];
}

#pragma mark - 界面设置

- (void)setupBackgroundViews {
    // 创建背景视图
    self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.backgroundView];
    
    // 创建顶部动态渐变背景
    self.gradientBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 360)];
    self.gradientBackgroundView.clipsToBounds = YES;
    
    // 初始化渐变色块数组
    self.blobs = [NSMutableArray array];
    self.highlightBlobs = [NSMutableArray array];
    
    // 创建基础层和高光层
    self.baseLayer = [CALayer layer];
    self.baseLayer.frame = self.gradientBackgroundView.bounds;
    
    self.highlightLayer = [CALayer layer];
    self.highlightLayer.frame = self.gradientBackgroundView.bounds;
    self.highlightLayer.compositingFilter = @"overlayBlendMode"; // 使用覆盖混合模式
    
    // 添加到视图中
    [self.gradientBackgroundView.layer addSublayer:self.baseLayer];
    [self.gradientBackgroundView.layer addSublayer:self.highlightLayer];
    
    // 创建更多数量的小型色块，使渐变效果更加平滑
    NSInteger blobCount = 14 + arc4random_uniform(4); // 增加到14-18个色块
    CGFloat maxBlobSize = self.gradientBackgroundView.bounds.size.width * 1.0; // 增大尺寸使色块更大更模糊
    CGFloat minBlobSize = self.gradientBackgroundView.bounds.size.width * 0.7; // 增大最小尺寸
    
    for (int i = 0; i < blobCount; i++) {
        // 创建基础色块
        CAGradientLayer *blob = [CAGradientLayer layer];
        CGFloat blobSize = minBlobSize + arc4random_uniform(maxBlobSize - minBlobSize);
        CGFloat x = arc4random_uniform(self.gradientBackgroundView.bounds.size.width);
        CGFloat y = arc4random_uniform(self.gradientBackgroundView.bounds.size.height);
        
        blob.frame = CGRectMake(x - blobSize/2, y - blobSize/2, blobSize, blobSize);
        blob.cornerRadius = blobSize / 1.5; // 使色块更不规则，不是完美的圆形
        
        // 随机选择渐变色，但选择更接近的颜色，减少对比度
        NSInteger colorIndex1 = arc4random_uniform(self.gradientColors.count);
        NSInteger colorIndex2 = (colorIndex1 + 1) % self.gradientColors.count;
        NSInteger colorIndex3 = (colorIndex2 + 1) % self.gradientColors.count;
        
        UIColor *color1 = self.gradientColors[colorIndex1];
        UIColor *color2 = self.gradientColors[colorIndex2];
        UIColor *color3 = self.gradientColors[colorIndex3];
        
        // 使用更大的渐变位置范围，使色彩过渡更加平滑
        blob.colors = @[(id)color1.CGColor, (id)color2.CGColor, (id)color3.CGColor];
        blob.locations = @[@0.0, @0.5, @1.0];
        
        // 随机选择渐变方向
        CGFloat angle = (arc4random_uniform(360)) * M_PI / 180.0;
        blob.startPoint = CGPointMake(0.5 + 0.5 * cos(angle), 0.5 + 0.5 * sin(angle));
        blob.endPoint = CGPointMake(0.5 - 0.5 * cos(angle), 0.5 - 0.5 * sin(angle));
        
        // 添加到基础层
        [self.baseLayer addSublayer:blob];
        [self.blobs addObject:blob];
        
        // 为高光层创建色块
        if (i % 3 == 0) { // 减少高光数量，只有三分之一的基础色块有对应高光
            CAGradientLayer *highlight = [CAGradientLayer layer];
            highlight.frame = CGRectMake(x - blobSize*0.7/2, y - blobSize*0.7/2, blobSize*0.7, blobSize*0.7);
            highlight.cornerRadius = blobSize*0.7 / 1.5; // 保持与基础层相同的圆角比例
            
            // 使用更低透明度的浅色调
            UIColor *lightColor1 = [UIColor colorWithWhite:1.0 alpha:0.4]; // 降低透明度
            UIColor *lightColor2 = [UIColor colorWithWhite:1.0 alpha:0.1]; // 降低透明度
            
            highlight.colors = @[(id)lightColor1.CGColor, (id)lightColor2.CGColor];
            highlight.locations = @[@0.0, @1.0];
            
            // 随机选择渐变方向
            CGFloat highlightAngle = (arc4random_uniform(360)) * M_PI / 180.0;
            highlight.startPoint = CGPointMake(0.5 + 0.5 * cos(highlightAngle), 0.5 + 0.5 * sin(highlightAngle));
            highlight.endPoint = CGPointMake(0.5 - 0.5 * cos(highlightAngle), 0.5 - 0.5 * sin(highlightAngle));
            
            // 添加到高光层
            [self.highlightLayer addSublayer:highlight];
            [self.highlightBlobs addObject:highlight];
        }
    }
    
    // 创建更强的模糊效果
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.blurView.frame = self.gradientBackgroundView.bounds;
    self.blurView.alpha = 0.85; // 增加模糊强度
    [self.gradientBackgroundView addSubview:self.blurView];
    
    [self.view addSubview:self.gradientBackgroundView];
}

- (void)startGradientAnimation {
    // 停止现有动画
    [self stopGradientAnimation];
    
    // 创建定时器
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateGradientAnimation)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopGradientAnimation {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)updateGradientAnimation {
    // 更新动画值
    self.animationValue += 0.0005 * self.animationDirection; // 将速度减半，使动画更加缓慢
    
    // 当动画值到达边界时反转方向
    if (self.animationValue >= 1.0) {
        self.animationValue = 1.0;
        self.animationDirection = -1.0;
    } else if (self.animationValue <= 0.0) {
        self.animationValue = 0.0;
        self.animationDirection = 1.0;
    }
    
    // 为每个色块添加动态效果
    CGFloat screenWidth = self.gradientBackgroundView.bounds.size.width;
    CGFloat screenHeight = self.gradientBackgroundView.bounds.size.height;
    
    // 更新基础层的色块
    for (int i = 0; i < self.blobs.count; i++) {
        CAGradientLayer *blob = self.blobs[i];
        
        // 计算移动方向和速度 - 使用Perlin噪声的思想
        CGFloat angle = (i * 0.7 + self.animationValue * M_PI * 2); // 减少角度变化
        CGFloat xSpeed = sin(angle) * 0.15; // 减少移动速度
        CGFloat ySpeed = cos(angle) * 0.15; // 减少移动速度
        
        // 更新位置
        CGPoint center = CGPointMake(blob.position.x + xSpeed, blob.position.y + ySpeed);
        
        // 边界检查 - 如果超出边界，则从另一侧进入
        if (center.x < -blob.bounds.size.width/2) {
            center.x = screenWidth + blob.bounds.size.width/2;
        } else if (center.x > screenWidth + blob.bounds.size.width/2) {
            center.x = -blob.bounds.size.width/2;
        }
        
        if (center.y < -blob.bounds.size.height/2) {
            center.y = screenHeight + blob.bounds.size.height/2;
        } else if (center.y > screenHeight + blob.bounds.size.height/2) {
            center.y = -blob.bounds.size.height/2;
        }
        
        // 更新色块位置
        [CATransaction begin];
        [CATransaction setDisableActions:YES]; // 禁用隐式动画
        blob.position = center;
        
        // 微调色块的大小和形状，使其看起来更有流动感，但变化幅度减小
        CGFloat scale = 1.0 + 0.05 * sin(self.animationValue * M_PI * 2 + i); // 将缩放振幅降低为0.05
        blob.transform = CATransform3DMakeScale(scale, scale, 1.0);
        
        // 同时轻微旋转渐变方向
        CGFloat rotationAngle = self.animationValue * M_PI / 8; // 减少旋转角度到22.5度
        blob.startPoint = CGPointMake(0.5 + 0.5 * cos(angle + rotationAngle), 0.5 + 0.5 * sin(angle + rotationAngle));
        blob.endPoint = CGPointMake(0.5 - 0.5 * cos(angle + rotationAngle), 0.5 - 0.5 * sin(angle + rotationAngle));
        [CATransaction commit];
    }
    
    // 更新高光层的色块
    for (int i = 0; i < self.highlightBlobs.count; i++) {
        CAGradientLayer *highlight = self.highlightBlobs[i];
        
        // 高光的移动方向与基础层相反，创造更丰富的视觉层次，但速度更慢
        CGFloat angle = ((i + 3) * 0.9 + self.animationValue * M_PI * 2);
        CGFloat xSpeed = sin(angle) * 0.2; // 减少高光移动速度
        CGFloat ySpeed = cos(angle) * 0.2;
        
        // 更新位置
        CGPoint center = CGPointMake(highlight.position.x + xSpeed, highlight.position.y + ySpeed);
        
        // 边界检查
        if (center.x < -highlight.bounds.size.width/2) {
            center.x = screenWidth + highlight.bounds.size.width/2;
        } else if (center.x > screenWidth + highlight.bounds.size.width/2) {
            center.x = -highlight.bounds.size.width/2;
        }
        
        if (center.y < -highlight.bounds.size.height/2) {
            center.y = screenHeight + highlight.bounds.size.height/2;
        } else if (center.y > screenHeight + highlight.bounds.size.height/2) {
            center.y = -highlight.bounds.size.height/2;
        }
        
        // 更新高光位置和形态
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        highlight.position = center;
        
        // 高光的形变更轻微
        CGFloat scale = 0.95 + 0.1 * sin(self.animationValue * M_PI * 3 + i); // 减少高光缩放范围
        highlight.transform = CATransform3DMakeScale(scale, scale, 1.0);
        [CATransaction commit];
    }
    
    // 轻微调整模糊强度，增加呼吸感，但幅度减小
    CGFloat blurIntensity = 0.8 + 0.1 * sin(self.animationValue * M_PI * 2); // 提高基础值，减少振幅
    self.blurView.alpha = blurIntensity;
}

- (void)setupStatusBar {
    // 创建顶部状态栏下方的内容
    UIView *statusBarContent = [[UIView alloc] initWithFrame:CGRectMake(0, 44, self.view.bounds.size.width, 40)];
    [self.view addSubview:statusBarContent];
    
    // 创建位置标签
    UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, self.view.bounds.size.width, 24)];
    locationLabel.text = @"TrollStore";
    locationLabel.textAlignment = NSTextAlignmentCenter;
    locationLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    locationLabel.textColor = [UIColor whiteColor];
    [statusBarContent addSubview:locationLabel];
    
    // 添加左侧返回按钮（这里可以用于切换到设置页面）
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    leftButton.frame = CGRectMake(21, 8, 24, 24);
    [leftButton setImage:[UIImage systemImageNamed:@"gear"] forState:UIControlStateNormal];
    [leftButton setTintColor:[UIColor whiteColor]];
    [leftButton addTarget:self action:@selector(settingsButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [statusBarContent addSubview:leftButton];
    
    // 添加右侧菜单按钮
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    rightButton.frame = CGRectMake(self.view.bounds.size.width - 45, 8, 24, 24);
    [rightButton setImage:[UIImage systemImageNamed:@"ellipsis"] forState:UIControlStateNormal];
    [rightButton setTintColor:[UIColor whiteColor]];
    [rightButton addTarget:self action:@selector(menuButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [statusBarContent addSubview:rightButton];
}

- (void)setupHeaderViews {
    // 创建中心图标视图
    self.weatherImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 120) / 2, 95, 120, 120)];
    self.weatherImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    // 使用系统图标并添加一个大字母"T"
    if (@available(iOS 13.0, *)) {
        // 创建背景基础视图 - 底层
        UIView *baseBgView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 100, 100)];
        baseBgView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
        baseBgView.layer.cornerRadius = 22;
        // 添加投影效果
        baseBgView.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.2].CGColor;
        baseBgView.layer.shadowOffset = CGSizeMake(0, 8);
        baseBgView.layer.shadowRadius = 12;
        baseBgView.layer.shadowOpacity = 0.8;
        [self.weatherImageView addSubview:baseBgView];
        
        // 创建主背景视图 - 新拟物风格
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 100, 100)];
        backgroundView.layer.cornerRadius = 22; // iOS应用图标的标准圆角
        backgroundView.clipsToBounds = YES;
        
        // 创建渐变背景
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = backgroundView.bounds;
        gradientLayer.colors = @[
            (id)[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.95 green:0.95 blue:0.98 alpha:1.0].CGColor
        ];
        gradientLayer.startPoint = CGPointMake(0.5, 0.0);
        gradientLayer.endPoint = CGPointMake(0.5, 1.0);
        [backgroundView.layer addSublayer:gradientLayer];
        
        // 添加内部阴影效果来增强立体感
        CALayer *innerShadowLayer = [CALayer layer];
        innerShadowLayer.frame = backgroundView.bounds;
        innerShadowLayer.cornerRadius = 22;
        innerShadowLayer.backgroundColor = [UIColor clearColor].CGColor;
        innerShadowLayer.shadowColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5].CGColor;
        innerShadowLayer.shadowOffset = CGSizeMake(0, 3);
        innerShadowLayer.shadowRadius = 5;
        innerShadowLayer.shadowOpacity = 1.0;
        innerShadowLayer.masksToBounds = NO;
        [backgroundView.layer addSublayer:innerShadowLayer];
        
        // 添加顶部高光效果
        UIView *highlightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
        CAGradientLayer *highlightGradient = [CAGradientLayer layer];
        highlightGradient.frame = highlightView.bounds;
        highlightGradient.colors = @[
            (id)[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8].CGColor,
            (id)[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0].CGColor
        ];
        highlightGradient.startPoint = CGPointMake(0.5, 0.0);
        highlightGradient.endPoint = CGPointMake(0.5, 1.0);
        highlightGradient.cornerRadius = 22;
        [highlightView.layer addSublayer:highlightGradient];
        [backgroundView addSubview:highlightView];
        
        [self.weatherImageView addSubview:backgroundView];
        
        // 添加大字母"T"（保持简洁）
        UILabel *tLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 15, 60, 60)];
        tLabel.text = @"T";
        tLabel.font = [UIFont systemFontOfSize:60 weight:UIFontWeightBold];
        tLabel.textColor = [UIColor colorWithRed:0.24 green:0.43 blue:0.82 alpha:1.0];
        tLabel.textAlignment = NSTextAlignmentCenter;
        [backgroundView addSubview:tLabel];
        
        // 添加确认勾号图标作为小标志（保持简洁）
        UIImageView *checkmarkView = [[UIImageView alloc] initWithFrame:CGRectMake(65, 62, 30, 30)];
        UIImage *checkmarkImage = [UIImage systemImageNamed:@"checkmark.circle.fill"];
        UIImageSymbolConfiguration *checkConfig = [UIImageSymbolConfiguration configurationWithPointSize:25 weight:UIImageSymbolWeightBold scale:UIImageSymbolScaleLarge];
        checkmarkView.image = [checkmarkImage imageByApplyingSymbolConfiguration:checkConfig];
        checkmarkView.tintColor = [UIColor colorWithRed:0.24 green:0.43 blue:0.82 alpha:1.0];
        [backgroundView addSubview:checkmarkView];
    } else {
        // 兼容低版本iOS的简化版本
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 100, 100)];
        backgroundView.backgroundColor = [UIColor whiteColor];
        backgroundView.layer.cornerRadius = 22;
        
        // 添加阴影效果
        backgroundView.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3].CGColor;
        backgroundView.layer.shadowOffset = CGSizeMake(0, 5);
        backgroundView.layer.shadowRadius = 8;
        backgroundView.layer.shadowOpacity = 0.8;
        
        [self.weatherImageView addSubview:backgroundView];
        
        // 添加字母"T"
        UILabel *tLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 15, 60, 60)];
        tLabel.text = @"T";
        tLabel.font = [UIFont systemFontOfSize:60 weight:UIFontWeightBold];
        tLabel.textColor = [UIColor colorWithRed:0.24 green:0.43 blue:0.82 alpha:1.0];
        tLabel.textAlignment = NSTextAlignmentCenter;
        [backgroundView addSubview:tLabel];
    }
    
    // 添加阴影效果
    self.weatherImageView.layer.shadowColor = [UIColor colorWithRed:0.12 green:0.14 blue:0.29 alpha:0.25].CGColor;
    self.weatherImageView.layer.shadowOffset = CGSizeMake(0, 17);
    self.weatherImageView.layer.shadowRadius = 15;
    self.weatherImageView.layer.shadowOpacity = 1.0;
    
    [self.view addSubview:self.weatherImageView];
    
    // 创建状态文本标签 - 修改为只显示TrollStore
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 226) / 2, 225, 226, 52)];
    self.statusLabel.text = @"TrollStore";
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold]; // 稍微增大字体
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.numberOfLines = 1; // 改为单行
    [self.view addSubview:self.statusLabel];
}

- (void)setupCardView {
    // 创建毛玻璃卡片视图
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.cardView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.cardView.frame = CGRectMake(16, 275, self.view.bounds.size.width - 32, 169);
    self.cardView.layer.cornerRadius = 20;
    self.cardView.clipsToBounds = YES;
    self.cardView.backgroundColor = [UIColor colorWithRed:0.92 green:0.96 blue:1.0 alpha:0.6];
    [self.view addSubview:self.cardView];
    
    // 创建"最近安装"标签按钮（不可点击）
    UIButton *todayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    CGFloat buttonWidth = 100; // 增加宽度以适应更长的文字
    CGFloat buttonX = self.view.bounds.size.width / 2 - buttonWidth / 2;
    
    todayButton.frame = CGRectMake(buttonX, 285, buttonWidth, 33);
    todayButton.backgroundColor = [UIColor colorWithRed:0.24 green:0.43 blue:0.82 alpha:1.0];
    todayButton.layer.cornerRadius = 16.5; // 半高，使其成为胶囊形状
    [todayButton setTitle:@"最近安装" forState:UIControlStateNormal];
    [todayButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    todayButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    todayButton.enabled = NO; // 禁用点击
    [self.view addSubview:todayButton];
}

- (void)setupDetailsView {
    // 创建详情容器视图
    self.detailsContainerView = [[UIView alloc] initWithFrame:CGRectMake(16, 468, self.view.bounds.size.width - 32, 192)];
    [self.view addSubview:self.detailsContainerView];
    
    // 创建"详情"标签
    UILabel *detailsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 101, 24)];
    detailsLabel.text = @"详情";
    detailsLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    detailsLabel.textColor = [UIColor colorWithRed:0.21 green:0.23 blue:0.39 alpha:1.0]; // Dark
    [self.detailsContainerView addSubview:detailsLabel];
    
    // 准备创建4个详情卡片
    CGFloat cardWidth = (self.detailsContainerView.bounds.size.width - 8) / 2; // 两列，中间间隔8
    CGFloat cardHeight = 76;
    CGFloat topSpacing = 32; // 第一行与标题的间距
    
    // 创建四个详情卡片
    NSMutableArray *detailBoxes = [NSMutableArray array];
    
    // 卡片1 - 度数
    UIView *tempBox = [self createDetailBoxWithFrame:CGRectMake(0, topSpacing, cardWidth, cardHeight)
                                               title:@"设备iOS版本"
                                                icon:@"uil:temperature-three-quarter"
                                               value:[self getCurrentIOSVersion]
                                          valueColor:[UIColor colorWithRed:0.21 green:0.23 blue:0.39 alpha:1.0]];
    [detailBoxes addObject:tempBox];
    
    // 卡片2 - 风力
    UIView *windBox = [self createDetailBoxWithFrame:CGRectMake(cardWidth + 8, topSpacing, cardWidth, cardHeight)
                                              title:@"应用数量"
                                               icon:@"mdi:weather-windy"
                                              value:[self getInstalledAppCount]
                                         valueColor:[UIColor colorWithRed:0.21 green:0.23 blue:0.39 alpha:1.0]];
    [detailBoxes addObject:windBox];
    
    // 卡片3 - 紫外线指数
    UIView *uvBox = [self createDetailBoxWithFrame:CGRectMake(0, topSpacing + cardHeight + 8, cardWidth, cardHeight)
                                            title:@"版本"
                                             icon:@"typcn:weather-sunny"
                                            value:@"2.0.12"
                                       valueColor:[UIColor colorWithRed:0.21 green:0.23 blue:0.39 alpha:1.0]];
    [detailBoxes addObject:uvBox];
    
    // 卡片4 - 湿度
    UIView *humidityBox = [self createDetailBoxWithFrame:CGRectMake(cardWidth + 8, topSpacing + cardHeight + 8, cardWidth, cardHeight)
                                                  title:@"存储空间"
                                                   icon:@"mdi:weather-hail"
                                                  value:[self getStorageSpace]
                                             valueColor:[UIColor colorWithRed:0.21 green:0.23 blue:0.39 alpha:1.0]];
    [detailBoxes addObject:humidityBox];
    
    // 将详情卡片添加到容器
    for (UIView *box in detailBoxes) {
        [self.detailsContainerView addSubview:box];
    }
    
    self.detailItems = detailBoxes;
}

- (UIView *)createDetailBoxWithFrame:(CGRect)frame title:(NSString *)title icon:(NSString *)iconName value:(NSString *)value valueColor:(UIColor *)valueColor {
    // 创建毛玻璃效果的容器
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    UIVisualEffectView *boxView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    boxView.frame = frame;
    boxView.layer.cornerRadius = 20;
    boxView.clipsToBounds = YES;
    
    // 添加一个轻微的背景色和透明度，融合毛玻璃效果
    boxView.backgroundColor = [UIColor colorWithRed:0.92 green:0.96 blue:1.0 alpha:0.3];
    
    // 创建图标
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 18, 30, 30)];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    
    // 根据图标名称设置图标，更换为更合适的SF Symbol图标
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightMedium scale:UIImageSymbolScaleMedium];
        UIImage *iconImage = nil;
        
        if ([iconName isEqualToString:@"uil:temperature-three-quarter"]) {
            // iOS版本 - 使用设备图标
            iconImage = [[UIImage systemImageNamed:@"iphone"] imageByApplyingSymbolConfiguration:config];
        } else if ([iconName isEqualToString:@"mdi:weather-windy"]) {
            // 应用数量 - 使用应用堆叠图标
            iconImage = [[UIImage systemImageNamed:@"square.stack.3d.up.fill"] imageByApplyingSymbolConfiguration:config];
        } else if ([iconName isEqualToString:@"typcn:weather-sunny"]) {
            // 版本 - 使用信息图标
            iconImage = [[UIImage systemImageNamed:@"info.circle.fill"] imageByApplyingSymbolConfiguration:config];
        } else if ([iconName isEqualToString:@"mdi:weather-hail"]) {
            // 存储空间 - 使用硬盘图标
            iconImage = [[UIImage systemImageNamed:@"internaldrive.fill"] imageByApplyingSymbolConfiguration:config];
        }
        
        iconView.image = iconImage;
        iconView.tintColor = [UIColor colorWithRed:0.24 green:0.43 blue:0.82 alpha:1.0];
    }
    
    [boxView.contentView addSubview:iconView];
    
    // 创建值标签 - 使用更小的字体确保完整显示
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 18, frame.size.width - 65, 16)];
    valueLabel.text = value;
    
    // 对于存储空间，使用稍小一点的字体
    if ([title isEqualToString:@"存储空间"]) {
        valueLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    } else {
        valueLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    }
    
    valueLabel.textColor = valueColor;
    // 确保长文本能够正确显示
    valueLabel.adjustsFontSizeToFitWidth = YES;
    valueLabel.minimumScaleFactor = 0.7;
    [boxView.contentView addSubview:valueLabel];
    
    // 创建标题标签
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 42, frame.size.width - 65, 16)];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    titleLabel.textColor = [UIColor colorWithRed:0.63 green:0.6 blue:0.68 alpha:1.0]; // #A098AE
    [boxView.contentView addSubview:titleLabel];
    
    return boxView;
}

- (void)setupTipsView {
    // 调整Y轴起始位置，让安装按钮更靠上一些
    CGFloat startY = 690;
    
    // 添加安装按钮，将它放在提示框上方
    UIButton *installButton = [UIButton buttonWithType:UIButtonTypeSystem];
    installButton.frame = CGRectMake((self.view.bounds.size.width - 200) / 2, startY, 200, 50);
    installButton.backgroundColor = [UIColor colorWithRed:0.24 green:0.43 blue:0.82 alpha:1.0];
    installButton.layer.cornerRadius = 25;
    [installButton setTitle:@"安装应用" forState:UIControlStateNormal];
    [installButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    installButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    [installButton addTarget:self action:@selector(installAppButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:installButton];
    
    // 创建提示视图容器，放在安装按钮下方
    UIView *tipsContainer = [[UIView alloc] initWithFrame:CGRectMake(16, startY + 60, self.view.bounds.size.width - 32, 70)];
    [self.view addSubview:tipsContainer];
    
    // 创建提示卡片，使用毛玻璃效果
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    UIVisualEffectView *tipBox = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    tipBox.frame = CGRectMake(0, 0, tipsContainer.bounds.size.width, 64);
    tipBox.layer.cornerRadius = 20;
    tipBox.clipsToBounds = YES;
    tipBox.backgroundColor = [UIColor colorWithRed:0.92 green:0.96 blue:1.0 alpha:0.3];
    [tipsContainer addSubview:tipBox];
    
    // 创建提示emoji
    UILabel *emojiLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 20, 32, 25)];
    emojiLabel.text = @"✨";
    emojiLabel.font = [UIFont systemFontOfSize:32];
    [tipBox.contentView addSubview:emojiLabel];
    
    // 创建提示文本，并支持多行显示
    UILabel *tipTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 12, tipBox.bounds.size.width - 79, 40)];
    tipTextLabel.text = @"安装应用时，请确保信任来源并检查应用权限!";
    tipTextLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    tipTextLabel.textColor = [UIColor colorWithRed:0.21 green:0.23 blue:0.39 alpha:1.0]; // Dark
    tipTextLabel.numberOfLines = 2; // 支持多行显示
    tipTextLabel.adjustsFontSizeToFitWidth = YES;
    tipTextLabel.minimumScaleFactor = 0.8;
    [tipBox.contentView addSubview:tipTextLabel];
}

- (void)setupAppInfoViews {
    // 应用信息视图将显示在卡片视图内
    self.appInfoViews = [NSMutableArray array];
    
    // 创建5个应用信息视图
    NSInteger appLimit = 5;
    CGFloat appViewWidth = (self.cardView.bounds.size.width - 20) / appLimit;
    
    // 在应用卡片视图中创建布局
    for (NSInteger i = 0; i < appLimit; i++) {
        // 应用容器
        UIView *appContainer = [[UIView alloc] initWithFrame:CGRectMake(10 + i * appViewWidth, 60, appViewWidth, 90)];
        
        // 应用名称标签
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, appViewWidth, 18)];
        nameLabel.text = @"";
        nameLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
        nameLabel.textColor = [UIColor colorWithRed:0.63 green:0.6 blue:0.68 alpha:1.0]; // #A098AE
        nameLabel.textAlignment = NSTextAlignmentCenter;
        [appContainer addSubview:nameLabel];
        
        // 创建图标背景 - 蓝色矩形
        UIView *iconBackground = [[UIView alloc] initWithFrame:CGRectMake((appViewWidth - 44) / 2, 20, 44, 44)];
        iconBackground.backgroundColor = [UIColor colorWithRed:0.24 green:0.43 blue:0.82 alpha:1.0];
        iconBackground.layer.cornerRadius = 8;
        [appContainer addSubview:iconBackground];
        
        // 应用图标 - 调整大小和位置
        UIImageView *appIcon = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 36, 36)];
        appIcon.contentMode = UIViewContentModeScaleAspectFill;
        appIcon.layer.cornerRadius = 6;
        appIcon.clipsToBounds = YES;
        appIcon.backgroundColor = [UIColor clearColor]; // 确保背景透明
        [iconBackground addSubview:appIcon];
        
        // 添加红色角标
        UIView *dotBadge = [[UIView alloc] initWithFrame:CGRectMake(32, 0, 14, 14)];
        dotBadge.backgroundColor = [UIColor redColor];
        dotBadge.layer.cornerRadius = 7;
        dotBadge.layer.borderWidth = 2;
        dotBadge.layer.borderColor = [UIColor whiteColor].CGColor;
        dotBadge.hidden = YES;
        [iconBackground addSubview:dotBadge];
        
        // 应用大小标签 (创建但隐藏)
        UILabel *sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 65, appViewWidth, 20)];
        sizeLabel.text = @"";
        sizeLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        sizeLabel.textColor = [UIColor colorWithRed:0.21 green:0.23 blue:0.39 alpha:1.0]; // Dark
        sizeLabel.textAlignment = NSTextAlignmentCenter;
        sizeLabel.hidden = YES; // 隐藏应用大小标签
        [appContainer addSubview:sizeLabel];
        
        [self.cardView.contentView addSubview:appContainer];
        [self.appInfoViews addObject:@{
            @"container": appContainer,
            @"nameLabel": nameLabel,
            @"iconBackground": iconBackground,
            @"iconView": appIcon,
            @"dotBadge": dotBadge,
            @"sizeLabel": sizeLabel
        }];
    }
    
    // 调用更新方法填充实际数据
    [self updateAppInfoViews];
}

- (void)updateAppInfoViews {
    // 获取已安装的应用信息
    NSArray* appPaths = [[TSApplicationsManager sharedInstance] installedAppPaths];
    NSMutableArray<TSAppInfo*>* appInfos = [NSMutableArray new];
    
    for(NSString* appPath in appPaths) {
        TSAppInfo* appInfo = [[TSAppInfo alloc] initWithAppBundlePath:appPath];
        [appInfo sync_loadBasicInfo];
        [appInfos addObject:appInfo];
    }
    
    // 先隐藏所有视图
    for (NSInteger i = 0; i < self.appInfoViews.count; i++) {
        NSDictionary *viewDict = self.appInfoViews[i];
        UIView *container = viewDict[@"container"];
        container.hidden = YES;
    }
    
    // 如果没有应用，则显示"无"
    if (appInfos.count == 0) {
        if (self.appInfoViews.count > 0) {
            NSDictionary *viewDict = self.appInfoViews[0];
            UILabel *nameLabel = viewDict[@"nameLabel"];
            UIImageView *iconView = viewDict[@"iconView"];
            UIView *container = viewDict[@"container"];
            UIView *dotBadge = viewDict[@"dotBadge"];
            
            nameLabel.text = @"无";
            if (@available(iOS 13.0, *)) {
                iconView.image = [UIImage systemImageNamed:@"xmark.circle"];
                iconView.tintColor = [UIColor whiteColor];
            }
            dotBadge.hidden = YES;
            container.hidden = NO;
        }
        return;
    }
    
    // 对应用按修改日期排序（最近安装）
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [appInfos sortUsingComparator:^NSComparisonResult(TSAppInfo *app1, TSAppInfo *app2) {
        NSDictionary *attr1 = [fileManager attributesOfItemAtPath:[app1 bundlePath] error:nil];
        NSDictionary *attr2 = [fileManager attributesOfItemAtPath:[app2 bundlePath] error:nil];
        
        NSDate *date1 = [attr1 fileCreationDate]; // 使用创建日期作为安装日期
        NSDate *date2 = [attr2 fileCreationDate];
        
        // 降序排列，最新的在前面
        return [date2 compare:date1];
    }];
    
    // 限制显示最近5个安装的应用
    NSInteger limit = MIN(5, appInfos.count);
    for (NSInteger i = 0; i < limit; i++) {
        // 获取视图元素
        NSDictionary *viewDict = self.appInfoViews[i];
        UILabel *nameLabel = viewDict[@"nameLabel"];
        UIImageView *iconView = viewDict[@"iconView"];
        UIView *container = viewDict[@"container"];
        UIView *dotBadge = viewDict[@"dotBadge"];
        
        container.hidden = NO;
        
        // 获取实际应用信息
        TSAppInfo *appInfo = appInfos[i];
        
        // 设置应用名称
        NSString *displayName = [appInfo displayName];
        if (displayName.length > 0) {
            nameLabel.text = displayName;
        } else {
            nameLabel.text = @"未知应用";
        }
        
        // 获取应用ID
        NSString *appId = [appInfo bundleIdentifier];
        
        // 使用应用列表中的方式获取图标
        if (appId) {
            // 从缓存中获取图标
            UIImage *cachedIcon = self.cachedIcons[appId];
            if (cachedIcon) {
                iconView.image = cachedIcon;
            } else {
                // 默认显示占位图标
                iconView.image = self.placeholderIcon;
                
                // 异步获取实际图标 - 使用重命名后的函数
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    // 使用私有API获取图标
                    UIImage *iconImage = ts_imageWithSize([UIImage _applicationIconImageForBundleIdentifier:appId 
                                                        format:ts_iconFormatToUse() 
                                                        scale:[UIScreen mainScreen].scale], 
                                                        CGSizeMake(36, 36));
                    
                    // 缓存图标
                    self.cachedIcons[appId] = iconImage;
                    
                    // 主线程更新UI
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // 更新对应容器中的图标
                        NSDictionary *curViewDict = self.appInfoViews[i];
                        UIImageView *curIconView = curViewDict[@"iconView"];
                        curIconView.image = iconImage;
                    });
                });
            }
        } else {
            // 如果无法获取应用ID，使用占位图标
            iconView.image = self.placeholderIcon;
        }
        
        // 只在最新安装的应用上显示红色角标
        dotBadge.hidden = (i != 0);
    }
}

- (void)settingsButtonTapped {
    TSNewSettingsViewController* settingsVC = [[TSNewSettingsViewController alloc] init];
    settingsVC.title = @"设置";
    
    UINavigationController* settingsNavController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    settingsNavController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:settingsNavController animated:YES completion:nil];
}

- (void)menuButtonTapped {
    // 创建操作菜单
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"选项" 
                                                                         message:nil 
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 添加"查看所有应用"选项
    UIAlertAction *viewAppsAction = [UIAlertAction actionWithTitle:@"查看所有应用" 
                                                             style:UIAlertActionStyleDefault 
                                                           handler:^(UIAlertAction * _Nonnull action) {
        TSAppTableViewController* appTableVC = [[TSAppTableViewController alloc] init];
        appTableVC.title = @"所有应用";
        
        UINavigationController* appNavController = [[UINavigationController alloc] initWithRootViewController:appTableVC];
        appNavController.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:appNavController animated:YES completion:nil];
    }];
    [actionSheet addAction:viewAppsAction];
    
    // 添加"设置"选项
    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"设置" 
                                                            style:UIAlertActionStyleDefault 
                                                          handler:^(UIAlertAction * _Nonnull action) {
        [self settingsButtonTapped];
    }];
    [actionSheet addAction:settingsAction];
    
    // 添加"关于"选项
    UIAlertAction *aboutAction = [UIAlertAction actionWithTitle:@"关于" 
                                                         style:UIAlertActionStyleDefault 
                                                       handler:^(UIAlertAction * _Nonnull action) {
        UIAlertController *aboutAlert = [UIAlertController alertControllerWithTitle:@"关于 TrollStore" 
                                                                           message:@"TrollStore是一个永久签名的越狱应用，可以永久安装任何IPA文件。\n\n开发者: opa334" 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"关闭" 
                                                             style:UIAlertActionStyleCancel 
                                                           handler:nil];
        [aboutAlert addAction:closeAction];
        
        [self presentViewController:aboutAlert animated:YES completion:nil];
    }];
    [actionSheet addAction:aboutAction];
    
    // 添加"取消"选项
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" 
                                                          style:UIAlertActionStyleCancel 
                                                        handler:nil];
    [actionSheet addAction:cancelAction];
    
    // 显示操作表
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)installAppButtonTapped {
    // 创建操作菜单
    UIAlertController *installOptions = [UIAlertController alertControllerWithTitle:@"安装应用" 
                                                                           message:@"选择安装方式" 
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 从文件安装
    UIAlertAction *installFromFileAction = [UIAlertAction actionWithTitle:@"从文件安装IPA" 
                                                                  style:UIAlertActionStyleDefault 
                                                                handler:^(UIAlertAction * _Nonnull action) {
        UTType* ipaType = [UTType typeWithFilenameExtension:@"ipa" conformingToType:UTTypeData];
        UTType* tipaType = [UTType typeWithFilenameExtension:@"tipa" conformingToType:UTTypeData];
        
        UIDocumentPickerViewController* documentPickerVC = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[ipaType, tipaType]];
        documentPickerVC.allowsMultipleSelection = NO;
        documentPickerVC.delegate = (id<UIDocumentPickerDelegate>)self;
        
        [self presentViewController:documentPickerVC animated:YES completion:nil];
    }];
    [installOptions addAction:installFromFileAction];
    
    // 从URL安装
    UIAlertAction *installFromURLAction = [UIAlertAction actionWithTitle:@"从URL安装" 
                                                                style:UIAlertActionStyleDefault 
                                                              handler:^(UIAlertAction * _Nonnull action) {
        UIAlertController* installURLController = [UIAlertController alertControllerWithTitle:@"从URL安装" 
                                                                                     message:@"" 
                                                                              preferredStyle:UIAlertControllerStyleAlert];
        
        [installURLController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"URL";
        }];
        
        UIAlertAction* installAction = [UIAlertAction actionWithTitle:@"安装" 
                                                               style:UIAlertActionStyleDefault 
                                                             handler:^(UIAlertAction* action) {
            NSString* URLString = installURLController.textFields.firstObject.text;
            NSURL* remoteURL = [NSURL URLWithString:URLString];
            
            [TSInstallationController handleAppInstallFromRemoteURL:remoteURL completion:nil];
        }];
        [installURLController addAction:installAction];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" 
                                                             style:UIAlertActionStyleCancel 
                                                           handler:nil];
        [installURLController addAction:cancelAction];
        
        [self presentViewController:installURLController animated:YES completion:nil];
    }];
    [installOptions addAction:installFromURLAction];
    
    // 取消
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" 
                                                         style:UIAlertActionStyleCancel 
                                                       handler:nil];
    [installOptions addAction:cancelAction];
    
    [self presentViewController:installOptions animated:YES completion:nil];
}

#pragma mark - 工具方法

- (NSString *)getCurrentIOSVersion {
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString *)getInstalledAppCount {
    NSArray* appPaths = [[TSApplicationsManager sharedInstance] installedAppPaths];
    return [NSString stringWithFormat:@"%lu", (unsigned long)appPaths.count];
}

- (NSString *)getStorageSpace {
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    
    if (error) {
        return @"未知";
    }
    
    // 获取总存储空间
    long long totalSpace = [[attributes objectForKey:NSFileSystemSize] longLongValue];
    float totalSpaceGB = totalSpace / (1024.0 * 1024.0 * 1024.0);
    
    // 恢复获取可用存储空间
    long long freeSpace = [[attributes objectForKey:NSFileSystemFreeSize] longLongValue];
    float freeSpaceGB = freeSpace / (1024.0 * 1024.0 * 1024.0);
    
    // 使用更紧凑的格式显示，确保能完整显示
    // 调整顺序：总容量在前，可用容量在后
    return [NSString stringWithFormat:@"%.0f/%.0fGB", totalSpaceGB, freeSpaceGB];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSString* pathToIPA = urls.firstObject.path;
    [TSInstallationController presentInstallationAlertIfEnabledForFile:pathToIPA isRemoteInstall:NO completion:nil];
}

@end 