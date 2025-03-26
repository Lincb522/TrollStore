#import "TSRootViewController.h"
#import "TSAppTableViewController.h"
#import "TSSettingsListController.h"
#import "TSSystemInfoViewController.h"
#import "TSSettingsViewController.h"
#import <TSPresentationDelegate.h>
#import "TSUIStyleManager.h"
#import "TSFloatingDockView.h"

@interface TSRootViewController () <TSFloatingDockViewDelegate>
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) TSFloatingDockView *floatingDock;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) NSArray<UIViewController *> *viewControllers;
@property (nonatomic, assign) NSInteger currentIndex;
@end

@implementation TSRootViewController

- (void)loadView {
	[super loadView];

	// 先设置基本背景色，确保视图控制器有基本样式
	self.view.backgroundColor = [UIColor whiteColor];

	// 创建主导航控制器
	self.navigationController = [[UINavigationController alloc] initWithRootViewController:self];
	
	// 设置导航栏为完全透明，与背景融合
	if (@available(iOS 13.0, *)) {
		UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
		[navBarAppearance configureWithTransparentBackground];
		navBarAppearance.backgroundColor = [UIColor clearColor]; // 完全透明
		navBarAppearance.shadowColor = [UIColor clearColor]; // 移除底部阴影线
		navBarAppearance.titleTextAttributes = @{
			NSForegroundColorAttributeName: [TSUIStyleManager textColor],
			NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold] // macOS风格标题字体
		};
		
		self.navigationController.navigationBar.standardAppearance = navBarAppearance;
		self.navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance;
		
		// 设置导航栏为透明
		self.navigationController.navigationBar.translucent = YES;
	}

	self.title = @"TrollStore";
	
	// 创建子视图控制器容器
	self.containerView = [[UIView alloc] initWithFrame:self.view.bounds];
	self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:self.containerView];
	
	// 设置约束，考虑底部的浮动Dock高度
	[NSLayoutConstraint activateConstraints:@[
		[self.containerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
		[self.containerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[self.containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[self.containerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
	]];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	@try {
		self.view.backgroundColor = [UIColor systemBackgroundColor];
		
		UITabBar *tabBar = [[UITabBar alloc] init];
		tabBar.delegate = self;
		UITabBarItem *rootTabItem = [[UITabBarItem alloc] initWithTitle:@"应用" image:[UIImage systemImageNamed:@"square.grid.2x2"] tag:0];
		UITabBarItem *utilityTabItem = [[UITabBarItem alloc] initWithTitle:@"工具" image:[UIImage systemImageNamed:@"hammer"] tag:1];
		UITabBarItem *settingsTabItem = [[UITabBarItem alloc] initWithTitle:@"设置" image:[UIImage systemImageNamed:@"gear"] tag:2];
		[tabBar setItems:@[rootTabItem, utilityTabItem, settingsTabItem]];
		self.tabBar = tabBar;
		
		[self.view addSubview:tabBar];
		
		[tabBar setSelectedItem:rootTabItem];
		
		CATextLayer *titleLayer = [CATextLayer layer];
		titleLayer.string = @"TrollStore";
		titleLayer.font = CFBridgingRetain([UIFont boldSystemFontOfSize:20].fontName);
		titleLayer.fontSize = 20;
		titleLayer.alignmentMode = kCAAlignmentCenter;
		CGFloat width = [@"TrollStore" sizeWithAttributes:@{
			NSFontAttributeName:[UIFont boldSystemFontOfSize:20]
		}].width;
		
		titleLayer.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, 56, width, 30);
		if (@available(iOS 13.0, *)) {
			titleLayer.foregroundColor = [UIColor labelColor].CGColor;
		} else {
			titleLayer.foregroundColor = [UIColor blackColor].CGColor;
		}
		[self.view.layer addSublayer:titleLayer];
		self.titleLayer = titleLayer;
		
		UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
		[refreshControl addTarget:self action:@selector(refreshUI) forControlEvents:UIControlEventValueChanged];
		self.refreshControl = refreshControl;
		
		[self showViewControllerAtIndex:0];
	} @catch (NSException *exception) {
		NSLog(@"TSRootViewController viewDidLoad 发生异常: %@", exception);
		[self performMinimalSetup:exception];
	}
}

// 在初始化过程发生异常时执行最小化设置
- (void)performMinimalSetup:(NSException *)exception {
	// 安全检查：确保在主线程上执行
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self performMinimalSetup:exception];
		});
		return;
	}
	
	// 清理视图
	for (UIView *subview in self.view.subviews) {
		[subview removeFromSuperview];
	}
	for (CALayer *layer in self.view.layer.sublayers) {
		[layer removeFromSuperlayer];
	}
	
	// 创建错误界面
	self.view.backgroundColor = [UIColor systemBackgroundColor];
	
	// 显示错误消息
	UILabel *errorLabel = [[UILabel alloc] init];
	errorLabel.text = [NSString stringWithFormat:@"初始化出错：%@", exception.reason];
	errorLabel.textAlignment = NSTextAlignmentCenter;
	errorLabel.numberOfLines = 0;
	errorLabel.frame = CGRectMake(20, 100, self.view.bounds.size.width - 40, 100);
	[self.view addSubview:errorLabel];
	
	// 添加重启按钮
	UIButton *restartButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[restartButton setTitle:@"重新加载" forState:UIControlStateNormal];
	restartButton.frame = CGRectMake((self.view.bounds.size.width - 120) / 2, 210, 120, 44);
	[restartButton addTarget:self action:@selector(recoverFromError) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:restartButton];
}

// 尝试从错误中恢复
- (void)recoverFromError {
	dispatch_async(dispatch_get_main_queue(), ^{
		@try {
			[self viewDidLoad];
		} @catch (NSException *exception) {
			NSLog(@"无法从错误中恢复: %@", exception);
			
			// 显示无法恢复的消息
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"无法恢复" 
																	   message:@"请尝试重新启动应用" 
																preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
			[self presentViewController:alert animated:YES completion:nil];
		}
	});
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	// 当视图已完全呈现后再应用复杂的视觉效果
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		// 创建新拟物风格背景
		[self setupDynamicBackground];
	});
}

- (void)setupDynamicBackground {
	// 添加极其微妙的纹理，增强新拟物风格效果
	CALayer *textureLayer = [CALayer layer];
	textureLayer.backgroundColor = [UIColor colorWithPatternImage:[self createNoiseTextureWithIntensity:0.01]].CGColor;
	textureLayer.opacity = 0.2; // 非常微妙的纹理
	textureLayer.frame = self.view.bounds;
	[self.view.layer insertSublayer:textureLayer atIndex:0];
	
	// 添加全局的新拟物阴影容器 - 为整个界面提供轻微的新拟物效果
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
	lightShadowLayer.shadowColor = [UIColor whiteColor].CGColor;
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
			CGContextSetGrayFillColor(context, white, 1.0);
			CGContextFillRect(context, CGRectMake(x, y, 1, 1));
		}
	}
	
	UIImage *noiseImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return noiseImage;
}

// 修改setupViewControllers方法，增加异常处理和线程安全性
- (void)setupViewControllers {
	@try {
		// 创建所有子视图控制器
		TSAppTableViewController *appTableVC = [[TSAppTableViewController alloc] init];
		appTableVC.title = @"应用列表";
		
		TSSystemInfoViewController *systemInfoVC = [[TSSystemInfoViewController alloc] init];
		systemInfoVC.title = @"系统信息";
		
		TSSettingsViewController *settingsVC = [[TSSettingsViewController alloc] init];
		settingsVC.title = @"设置";
		
		// 保存到数组中
		self.viewControllers = @[appTableVC, systemInfoVC, settingsVC];
		
		// 默认显示第一个视图控制器
		self.currentIndex = 0;
		
		// 使用主线程执行初始视图控制器显示
		if ([NSThread isMainThread]) {
			[self showViewControllerAtIndex:self.currentIndex];
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self showViewControllerAtIndex:self.currentIndex];
			});
		}
	} @catch (NSException *exception) {
		NSLog(@"TSRootViewController setupViewControllers 发生异常: %@", exception);
	}
}

- (void)setupFloatingDock {
	// 设置浮动Dock的图标和标题
	NSArray<UIImage *> *icons;
	
	if (@available(iOS 13.0, *)) {
		icons = @[
			[UIImage systemImageNamed:@"square.grid.2x2.fill"],
			[UIImage systemImageNamed:@"info.circle.fill"],
			[UIImage systemImageNamed:@"gear.circle.fill"]
		];
	} else {
		// 为iOS 13以下提供替代图标
		icons = @[
			[UIImage imageNamed:@"AppIcon60x60"],
			[UIImage imageNamed:@"AppIcon60x60"],
			[UIImage imageNamed:@"AppIcon60x60"]
		];
	}
	
	NSArray<NSString *> *titles = @[@"应用", @"信息", @"设置"];
	
	// 创建浮动Dock
	CGFloat dockHeight = 60.0;
	CGFloat dockWidth = 220.0;
	CGFloat screenWidth = CGRectGetWidth(self.view.bounds);
	CGFloat screenHeight = CGRectGetHeight(self.view.bounds);
	
	CGRect dockFrame = CGRectMake((screenWidth - dockWidth) / 2, 
							 screenHeight - dockHeight - 20, 
							 dockWidth, 
							 dockHeight);
	
	self.floatingDock = [[TSFloatingDockView alloc] initWithFrame:dockFrame 
													  icons:icons 
													 titles:titles];
	self.floatingDock.delegate = self;
	self.floatingDock.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	
	[self.view addSubview:self.floatingDock];
}

// 修改showViewControllerAtIndex方法，添加额外的防御性检查
- (void)showViewControllerAtIndex:(NSInteger)index {
	// 安全检查：确保在主线程上执行
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self showViewControllerAtIndex:index];
		});
		return;
	}
	
	@try {
		// 安全移除当前视图控制器
		if (self.currentViewController) {
			[self.currentViewController.view removeFromSuperview];
			[self.currentViewController removeFromParentViewController];
			self.currentViewController = nil; // 确保在移除后清空引用
		}
		
		// 检查索引有效性
		if (index < 0 || index > 2) {
			NSLog(@"无效的视图控制器索引: %ld", (long)index);
			return;
		}
		
		// 创建新视图控制器
		UIViewController *newViewController = nil;
		
		if (index == 0) {
			TSAppTableViewController *appTableVC = [[TSAppTableViewController alloc] init];
			appTableVC.rootController = self;
			if (self.refreshControl) {
				[appTableVC.tableView addSubview:self.refreshControl];
			}
			newViewController = appTableVC;
		} else if (index == 1) {
			TSSystemInfoViewController *systemInfoVC = [[TSSystemInfoViewController alloc] init];
			systemInfoVC.rootController = self;
			newViewController = systemInfoVC;
		} else if (index == 2) {
			TSSettingsViewController *settingsVC = [[TSSettingsViewController alloc] init];
			settingsVC.rootController = self;
			newViewController = settingsVC;
		}
		
		// 安全检查：确保成功创建了视图控制器
		if (!newViewController) {
			NSLog(@"错误：无法创建索引 %ld 的视图控制器", (long)index);
			return;
		}
		
		// 设置当前视图控制器并添加到视图层次结构
		[self addChildViewController:newViewController];
		newViewController.view.frame = CGRectMake(0, 100, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - 183);
		[self.view addSubview:newViewController.view];
		[newViewController didMoveToParentViewController:self];
		self.currentViewController = newViewController;
		
		// 安全地触发布局更新
		dispatch_async(dispatch_get_main_queue(), ^{
			[newViewController.view setNeedsLayout];
			[newViewController.view layoutIfNeeded];
			
			// 特定控制器的额外初始化
			if (index == 0 && [newViewController isKindOfClass:[TSAppTableViewController class]]) {
				TSAppTableViewController *appTableVC = (TSAppTableViewController *)newViewController;
				[appTableVC reloadTable];
			} else if (index == 2 && [newViewController isKindOfClass:[TSSettingsViewController class]]) {
				TSSettingsViewController *settingsVC = (TSSettingsViewController *)newViewController;
				[settingsVC rebuildUI];
			}
		});
	} @catch (NSException *exception) {
		NSLog(@"切换视图控制器时发生异常: %@", exception);
		
		// 显示错误提示
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"视图切换错误" 
																	   message:[NSString stringWithFormat:@"切换到标签 %ld 时出错: %@", (long)index, exception.reason] 
																preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

- (void)refreshUI {
	dispatch_async(dispatch_get_main_queue(), ^{
		@try {
			if ([self.currentViewController isKindOfClass:[TSAppTableViewController class]]) {
				TSAppTableViewController *appTableVC = (TSAppTableViewController *)self.currentViewController;
				[appTableVC reloadTable];
			} else if ([self.currentViewController isKindOfClass:[TSSettingsViewController class]]) {
				TSSettingsViewController *settingsVC = (TSSettingsViewController *)self.currentViewController;
				[settingsVC rebuildUI];
			}
			
			if (self.refreshControl && self.refreshControl.isRefreshing) {
				[self.refreshControl endRefreshing];
			}
		} @catch (NSException *exception) {
			NSLog(@"刷新UI时发生异常: %@", exception);
			
			if (self.refreshControl && self.refreshControl.isRefreshing) {
				[self.refreshControl endRefreshing];
			}
			
			// 显示错误提示（使用简单alert避免嵌套问题）
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"刷新错误" 
																		  message:@"刷新界面时发生错误" 
															   preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
			[self presentViewController:alert animated:YES completion:nil];
		}
	});
}

#pragma mark - TSFloatingDockViewDelegate

- (void)floatingDockDidSelectIndex:(NSInteger)index {
	if (index != self.currentIndex) {
		self.currentIndex = index;
		[self showViewControllerAtIndex:index];
		
		// 设置滚动视图滚动到顶部
		UIViewController *vc = self.viewControllers[index];
		if ([vc isKindOfClass:[TSAppTableViewController class]]) {
			TSAppTableViewController *appVC = (TSAppTableViewController *)vc;
			[appVC.tableView setContentOffset:CGPointZero animated:YES];
		} else if ([vc isKindOfClass:[TSSettingsViewController class]]) {
			TSSettingsViewController *settingsVC = (TSSettingsViewController *)vc;
			[settingsVC.scrollView setContentOffset:CGPointZero animated:YES];
		} else if ([vc isKindOfClass:[TSSystemInfoViewController class]]) {
			TSSystemInfoViewController *infoVC = (TSSystemInfoViewController *)vc;
			[infoVC.scrollView setContentOffset:CGPointZero animated:YES];
		}
	}
}

// 修改viewDidLayoutSubviews方法，添加异常处理
- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	@try {
		// 确保自定义层尺寸与视图尺寸同步更新
		for (CALayer *layer in self.view.layer.sublayers) {
			if ([layer isKindOfClass:[CALayer class]] && layer.opacity < 1.0) {
				layer.frame = self.view.bounds;
			}
		}
		
		// 更新容器视图的尺寸
		self.containerView.frame = self.view.bounds;
		
		// 确保当前视图控制器的视图尺寸正确
		if (self.currentViewController) {
			self.currentViewController.view.frame = self.containerView.bounds;
		}
		
		// 更新浮动Dock的位置
		if (self.floatingDock) {
			CGFloat dockHeight = 60.0;
			CGFloat dockWidth = 220.0;
			CGFloat screenWidth = CGRectGetWidth(self.view.bounds);
			CGFloat screenHeight = CGRectGetHeight(self.view.bounds);
			
			self.floatingDock.frame = CGRectMake((screenWidth - dockWidth) / 2, 
												  screenHeight - dockHeight - 20, 
												  dockWidth, 
												  dockHeight);
		}
	} @catch (NSException *exception) {
		NSLog(@"viewDidLayoutSubviews 发生异常: %@", exception);
	}
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	// 在方向变化过程中更新布局
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		// 更新子视图控制器的视图尺寸
		if (self.currentViewController) {
			[self.currentViewController.view setNeedsLayout];
		}
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		// 在布局变化后更新背景效果
		for (CALayer *layer in self.view.layer.sublayers) {
			if ([layer isKindOfClass:[CALayer class]] && layer.opacity < 1.0) {
				layer.frame = self.view.bounds;
			}
		}
		
		// 强制重新计算当前显示视图的布局
		[self.containerView setNeedsLayout];
		[self.containerView layoutIfNeeded];
		
		// 如果是列表视图，触发重新加载
		if ([self.currentViewController isKindOfClass:[TSAppTableViewController class]]) {
			TSAppTableViewController *appVC = (TSAppTableViewController *)self.currentViewController;
			[appVC.tableView reloadData];
		} else if ([self.currentViewController isKindOfClass:[TSSettingsViewController class]]) {
			TSSettingsViewController *settingsVC = (TSSettingsViewController *)self.currentViewController;
			[settingsVC rebuildUI];
		}
	}];
}

@end
