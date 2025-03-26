#import "TSAppTableViewController.h"

#import "TSApplicationsManager.h"
#import <TSPresentationDelegate.h>
#import "TSInstallationController.h"
#import "TSUtil.h"
#import "TSUIStyleManager.h"
#import "TSAppTableViewCell.h"
@import UniformTypeIdentifiers;

#define ICON_FORMAT_IPAD 8
#define ICON_FORMAT_IPHONE 10

NSInteger iconFormatToUse(void)
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

UIImage* imageWithSize(UIImage* image, CGSize size)
{
	if(CGSizeEqualToSize(image.size, size)) return image;
	UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
	CGRect imageRect = CGRectMake(0.0, 0.0, size.width, size.height);
	[image drawInRect:imageRect];
	UIImage* outImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return outImage;
}

@interface UIImage ()
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)id format:(NSInteger)format scale:(double)scale;
@end

@implementation TSAppTableViewController

- (void)loadAppInfos
{
	NSArray* appPaths = [[TSApplicationsManager sharedInstance] installedAppPaths];
	NSMutableArray<TSAppInfo*>* appInfos = [NSMutableArray new];

	for(NSString* appPath in appPaths)
	{
		TSAppInfo* appInfo = [[TSAppInfo alloc] initWithAppBundlePath:appPath];
		[appInfo sync_loadBasicInfo];
		[appInfos addObject:appInfo];
	}

	if(_searchKey && ![_searchKey isEqualToString:@""])
	{
		[appInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TSAppInfo* appInfo, NSUInteger idx, BOOL* stop)
		{
			NSString* appName = [appInfo displayName];
			BOOL nameMatch = [appName rangeOfString:_searchKey options:NSCaseInsensitiveSearch range:NSMakeRange(0, [appName length]) locale:[NSLocale currentLocale]].location != NSNotFound;
			if(!nameMatch)
			{
				[appInfos removeObjectAtIndex:idx];
			}
		}];
	}

	[appInfos sortUsingComparator:^(TSAppInfo* appInfoA, TSAppInfo* appInfoB)
	{
		return [[appInfoA displayName] localizedStandardCompare:[appInfoB displayName]];
	}];

	_cachedAppInfos = appInfos.copy;
}

- (instancetype)init
{
	self = [super init];
	if(self)
	{
		[self loadAppInfos];
		_placeholderIcon = [UIImage _applicationIconImageForBundleIdentifier:@"com.apple.WebSheet" format:iconFormatToUse() scale:[UIScreen mainScreen].scale];
		_cachedIcons = [NSMutableDictionary new];
		[[LSApplicationWorkspace defaultWorkspace] addObserver:self];
	}
	return self;
}

- (void)dealloc
{
	[[LSApplicationWorkspace defaultWorkspace] removeObserver:self];
}

- (void)reloadTable
{
	// 在后台线程安全地加载应用信息
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		@try {
			// 加载应用信息
			[self loadAppInfos];
		
			// 在主线程更新UI
			dispatch_async(dispatch_get_main_queue(), ^{
				@try {
					if (self.tableView) {
						[self.tableView reloadData];
					
						// 添加额外的延迟刷新，解决某些情况下布局不正确的问题
						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
							@try {
								if (self.tableView) {
									[self.tableView reloadData];
								}
							} @catch (NSException *exception) {
								NSLog(@"延迟表格刷新时发生异常: %@", exception);
							}
						});
					}
				} @catch (NSException *exception) {
					NSLog(@"表格刷新时发生异常: %@", exception);
				}
			});
		} @catch (NSException *exception) {
			NSLog(@"加载应用信息时发生异常: %@", exception);
		}
	});
}

- (void)loadView
{
	[super loadView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:@"ApplicationsChanged" object:nil];
}

- (void)viewDidLoad
{
	@try {
		[super viewDidLoad];
		
		self.title = @"应用列表";
		self.tableView.allowsMultipleSelectionDuringEditing = NO;
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.tableView.backgroundColor = [UIColor clearColor];
		
		// 设置白色背景并添加精致纹理效果
		self.view.backgroundColor = [UIColor whiteColor];
		CALayer *textureLayer = [CALayer layer];
		UIImage *noiseImage = [self generateNoiseTextureWithSize:CGSizeMake(200, 200) opacity:0.03];
		textureLayer.contents = (__bridge id)noiseImage.CGImage;
		[self.view.layer insertSublayer:textureLayer atIndex:0];
		
		// 确保表格视图一开始就调整了内容缩进，为浮动Dock留出空间
		UIEdgeInsets contentInset = self.tableView.contentInset;
		contentInset.bottom = 80; // 为Dock和按钮预留足够空间
		self.tableView.contentInset = contentInset;
		
		// 安全地在主线程上设置添加按钮（确保延迟执行，等待视图完全加载）
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setupAddButton];
			// 延迟加载应用列表，确保UI已经完全初始化
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[self reloadTable];
			});
		});
		
		// 设置搜索控制器
		[self setupSearchBar];
	} @catch (NSException *exception) {
		NSLog(@"TSAppTableViewController viewDidLoad 发生异常: %@", exception);
		// 显示错误消息
		UILabel *errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.view.bounds.size.width - 40, 40)];
		errorLabel.text = @"加载应用列表视图时出错";
		errorLabel.textAlignment = NSTextAlignmentCenter;
		[self.view addSubview:errorLabel];
	}
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 加载应用数据
    [self reloadTable];
    
    // 确保添加按钮位置正确
    [self updateAddButtonPosition];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 确保表格滚动到顶部
    if (self.tableView.contentOffset.y > 0) {
        [self.tableView setContentOffset:CGPointZero animated:YES];
    }
    
    // 如果搜索栏已激活，刷新其内容
    if (self.searchController.isActive) {
        [self.searchController.searchBar becomeFirstResponder];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    @try {
        // 更新表格视图布局
        self.tableView.frame = self.view.bounds;
        
        // 更新添加按钮位置
        [self updateAddButtonPosition];
    } @catch (NSException *exception) {
        NSLog(@"viewDidLayoutSubviews 发生异常: %@", exception);
    }
}

- (void)updateAddButtonPosition {
    // 安全检查
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateAddButtonPosition];
        });
        return;
    }
    
    // 确保添加按钮和视图都存在
    if (!self.addButton || !self.view) {
        return;
    }
    
    @try {
        // 将按钮放置在右下角，考虑安全区域
        CGFloat bottomMargin = 20;
        if (@available(iOS 11.0, *)) {
            bottomMargin += self.view.safeAreaInsets.bottom;
        }
        
        CGRect buttonFrame = self.addButton.frame;
        buttonFrame.origin.x = self.view.bounds.size.width - buttonFrame.size.width - 20;
        buttonFrame.origin.y = self.view.bounds.size.height - buttonFrame.size.height - bottomMargin;
        self.addButton.frame = buttonFrame;
    } @catch (NSException *exception) {
        NSLog(@"更新添加按钮位置时出错: %@", exception);
    }
}

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

- (void)setupAddButton {
	// 安全检查：确保在主线程上执行
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setupAddButton];
		});
		return;
	}
	
	@try {
		// 检查按钮是否已经存在，如果存在则移除
		if (self.addButton) {
			[self.addButton removeFromSuperview];
		}
		
		// 创建添加按钮
		self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
		
		// 设置按钮大小和位置
		self.addButton.frame = CGRectMake(0, 0, 60, 60);
		
		// 设置按钮样式
		self.addButton.backgroundColor = [UIColor systemBlueColor];
		self.addButton.layer.cornerRadius = 30;
		self.addButton.clipsToBounds = YES;
		
		// 添加阴影效果
		self.addButton.layer.shadowColor = [UIColor blackColor].CGColor;
		self.addButton.layer.shadowOffset = CGSizeMake(0, 3);
		self.addButton.layer.shadowRadius = 5;
		self.addButton.layer.shadowOpacity = 0.3;
		self.addButton.layer.masksToBounds = NO;
		
		// 设置按钮图标
		if (@available(iOS 13.0, *)) {
			UIImage *plusImage = [UIImage systemImageNamed:@"plus"];
			if (plusImage) {
				UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightBold];
				UIImage *largerImage = [plusImage imageByApplyingSymbolConfiguration:config];
				[self.addButton setImage:largerImage forState:UIControlStateNormal];
				self.addButton.tintColor = [UIColor whiteColor];
			} else {
				// 如果系统图标不可用，使用文本
				[self.addButton setTitle:@"+" forState:UIControlStateNormal];
				self.addButton.titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
				[self.addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
			}
		} else {
			// iOS 13以下使用文本
			[self.addButton setTitle:@"+" forState:UIControlStateNormal];
			self.addButton.titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
			[self.addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		}
		
		// 安全添加目标动作
		[self.addButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside]; // 移除所有现有动作
		[self.addButton addTarget:self action:@selector(showInstallOptions) forControlEvents:UIControlEventTouchUpInside];
		
		// 将按钮添加到视图
		if (self.view && self.addButton) {
			[self.view addSubview:self.addButton];
			
			// 设置初始位置
			[self updateAddButtonPosition];
		}
	} @catch (NSException *exception) {
		NSLog(@"设置添加按钮时出错: %@", exception);
	}
}

- (void)reloadApps {
    // 更新应用列表数据
    [self loadAppInfos];
    
    // 在主线程上刷新表格
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadTable];
    });
}

- (void)setupSearchBar
{
	_searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	_searchController.searchResultsUpdater = self;
	_searchController.obscuresBackgroundDuringPresentation = NO;
	_searchController.searchBar.placeholder = @"搜索应用";
    
    // 增强搜索栏的新拟物风格
    if (@available(iOS 13.0, *)) {
        // 设置搜索栏样式
        UITextField *searchField = _searchController.searchBar.searchTextField;
        
        // 自定义搜索框背景
        searchField.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.98 alpha:1.0];
        searchField.layer.cornerRadius = 16.0;
        searchField.layer.masksToBounds = YES;
        
        // 设置搜索图标和文本颜色
        UIImageView *leftImageView = (UIImageView *)searchField.leftView;
        leftImageView.tintColor = [TSUIStyleManager accentColor];
        searchField.textColor = [TSUIStyleManager textColor];
        
        // 设置占位符文本颜色
        UIColor *placeholderColor = [[TSUIStyleManager textColor] colorWithAlphaComponent:0.6];
        [searchField setValue:placeholderColor forKeyPath:@"placeholderLabel.textColor"];
        
        // 应用阴影效果
        searchField.layer.shadowColor = [UIColor blackColor].CGColor;
        searchField.layer.shadowOffset = CGSizeMake(0, 1);
        searchField.layer.shadowRadius = 2.0;
        searchField.layer.shadowOpacity = 0.1;
        
        // 设置取消按钮颜色
        UIColor *accentColor = [TSUIStyleManager accentColor];
        [_searchController.searchBar setTintColor:accentColor];
    }
	
	self.navigationItem.searchController = _searchController;
	self.navigationItem.hidesSearchBarWhenScrolling = NO;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		_searchKey = searchController.searchBar.text;
		[self reloadTable];
	});
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
	NSString* pathToIPA = urls.firstObject.path;
	[TSInstallationController presentInstallationAlertIfEnabledForFile:pathToIPA isRemoteInstall:NO completion:nil];
}

- (void)openAppPressedForRowAtIndexPath:(NSIndexPath*)indexPath enableJIT:(BOOL)enableJIT
{
	TSApplicationsManager* appsManager = [TSApplicationsManager sharedInstance];

	TSAppInfo* appInfo = _cachedAppInfos[indexPath.row];
	NSString* appId = [appInfo bundleIdentifier];
	BOOL didOpen = [appsManager openApplicationWithBundleID:appId];

	// if we failed to open the app, show an alert
	if(!didOpen)
	{
		NSString* failMessage = @"";
		if([[appInfo registrationState] isEqualToString:@"User"])
		{
			failMessage = @"此应用无法启动，因为它的注册状态为\"User\"，请将其注册为\"System\"后重试。";
		}

		NSString* failTitle = [NSString stringWithFormat:@"无法打开 %@", appId];
		UIAlertController* didFailController = [UIAlertController alertControllerWithTitle:failTitle message:failMessage preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];

		[didFailController addAction:cancelAction];
		[TSPresentationDelegate presentViewController:didFailController animated:YES completion:nil];
	}
	else if (enableJIT)
	{
		int ret = [appsManager enableJITForBundleID:appId];
		if (ret != 0)
		{
			UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"错误" message:[NSString stringWithFormat:@"启用JIT时出错: trollstorehelper返回代码 %d", ret] preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];
			[errorAlert addAction:closeAction];
			[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
		}
	}
}

- (void)showDetailsPressedForRowAtIndexPath:(NSIndexPath*)indexPath
{
	TSAppInfo* appInfo = _cachedAppInfos[indexPath.row];

	[appInfo loadInfoWithCompletion:^(NSError* error)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			if(!error)
			{
				UIAlertController* detailsAlert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
				detailsAlert.attributedTitle = [appInfo detailedInfoTitle];
				detailsAlert.attributedMessage = [appInfo detailedInfoDescription];

				UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];
				[detailsAlert addAction:closeAction];

				[TSPresentationDelegate presentViewController:detailsAlert animated:YES completion:nil];
			}
			else
			{
				UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"解析错误 %ld", error.code] message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];
				[errorAlert addAction:closeAction];

				[TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
			}
		});
	}];
}

- (void)changeAppRegistrationForRowAtIndexPath:(NSIndexPath*)indexPath toState:(NSString*)newState
{
	TSAppInfo* appInfo = _cachedAppInfos[indexPath.row];

	if([newState isEqualToString:@"User"])
	{
		NSString* title = [NSString stringWithFormat:@"将'%@'切换到\"User\"注册状态", [appInfo displayName]];
		UIAlertController* confirmationAlert = [UIAlertController alertControllerWithTitle:title message:@"将此应用切换到\"User\"注册状态会导致下次重新启动SpringBoard后无法启动，因为TrollStore使用的漏洞只对注册为\"System\"的应用有效。\n此选项的目的是临时让应用在设置中显示，以便您可以调整设置，然后再将其切换回\"System\"注册状态（否则TrollStore安装的应用不会在设置中显示）。此外，\"User\"注册状态也可用于临时修复iTunes文件共享功能，这也是TrollStore安装的应用无法使用的功能。\n当您完成所需的更改并希望应用再次可启动时，需要在TrollStore中将其切换回\"System\"状态。" preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* switchToUserAction = [UIAlertAction actionWithTitle:@"切换到\"User\"" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
		{
			[[TSApplicationsManager sharedInstance] changeAppRegistration:[appInfo bundlePath] toState:newState];
			[appInfo sync_loadBasicInfo];
		}];

		[confirmationAlert addAction:switchToUserAction];

		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];

		[confirmationAlert addAction:cancelAction];

		[TSPresentationDelegate presentViewController:confirmationAlert animated:YES completion:nil];
	}
	else
	{
		[[TSApplicationsManager sharedInstance] changeAppRegistration:[appInfo bundlePath] toState:newState];
		[appInfo sync_loadBasicInfo];

		NSString* title = [NSString stringWithFormat:@"已将'%@'切换到\"System\"注册状态", [appInfo displayName]];

		UIAlertController* infoAlert = [UIAlertController alertControllerWithTitle:title message:@"该应用已切换到\"System\"注册状态，重启SpringBoard后即可再次启动。" preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* respringAction = [UIAlertAction actionWithTitle:@"重启SpringBoard" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			respring();
		}];

		[infoAlert addAction:respringAction];

		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];

		[infoAlert addAction:closeAction];

		[TSPresentationDelegate presentViewController:infoAlert animated:YES completion:nil];
	}
}

- (void)uninstallPressedForRowAtIndexPath:(NSIndexPath*)indexPath
{
	TSApplicationsManager* appsManager = [TSApplicationsManager sharedInstance];

	TSAppInfo* appInfo = _cachedAppInfos[indexPath.row];

	NSString* appPath = [appInfo bundlePath];
	NSString* appId = [appInfo bundleIdentifier];
	NSString* appName = [appInfo displayName];

	UIAlertController* confirmAlert = [UIAlertController alertControllerWithTitle:@"确认卸载" message:[NSString stringWithFormat:@"卸载应用'%@'将删除应用及其所有相关数据。", appName] preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction* uninstallAction = [UIAlertAction actionWithTitle:@"卸载" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
	{
		if(appId)
		{
			[appsManager uninstallApp:appId];
		}
		else
		{
			[appsManager uninstallAppByPath:appPath];
		}
	}];
	[confirmAlert addAction:uninstallAction];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
	[confirmAlert addAction:cancelAction];

	[TSPresentationDelegate presentViewController:confirmAlert animated:YES completion:nil];
}

- (void)deselectRow
{
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _cachedAppInfos.count;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
	[self reloadTable];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"AppCell";
    
    TSAppTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[TSAppTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }

	if(!indexPath || indexPath.row > (_cachedAppInfos.count - 1)) return cell;

	TSAppInfo* appInfo = _cachedAppInfos[indexPath.row];
	NSString* appId = [appInfo bundleIdentifier];
    
    // 配置应用信息
    cell.titleLabel.text = [appInfo displayName];
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ • %@", [appInfo versionString], appId];

	if(appId)
	{
		UIImage* cachedIcon = _cachedIcons[appId];
		if(cachedIcon)
		{
			cell.appIconView.image = cachedIcon;
		}
		else
		{
			cell.appIconView.image = _placeholderIcon;
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
			{
				UIImage* iconImage = imageWithSize([UIImage _applicationIconImageForBundleIdentifier:appId format:iconFormatToUse() scale:[UIScreen mainScreen].scale], _placeholderIcon.size);
				_cachedIcons[appId] = iconImage;
				dispatch_async(dispatch_get_main_queue(), ^{
					NSIndexPath *curIndexPath = [NSIndexPath indexPathForRow:[_cachedAppInfos indexOfObject:appInfo] inSection:0];
					TSAppTableViewCell *curCell = (TSAppTableViewCell *)[tableView cellForRowAtIndexPath:curIndexPath];
					if(curCell && [curCell isKindOfClass:[TSAppTableViewCell class]])
					{
						curCell.appIconView.image = iconImage;
						[curCell setNeedsLayout];
					}
				});
			});
		}
	}
	else
	{
		cell.appIconView.image = _placeholderIcon;
	}

	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 76.0f; // 优化的行高，保持卡片间距
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(editingStyle == UITableViewCellEditingStyleDelete)
	{
		[self uninstallPressedForRowAtIndexPath:indexPath];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	TSAppInfo* appInfo = _cachedAppInfos[indexPath.row];

	NSString* appId = [appInfo bundleIdentifier];
	NSString* appName = [appInfo displayName];

	UIAlertController* appSelectAlert = [UIAlertController alertControllerWithTitle:appName?:@"" message:appId?:@"" preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction* openAction = [UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		[self openAppPressedForRowAtIndexPath:indexPath enableJIT:NO];
		[self deselectRow];
	}];
	[appSelectAlert addAction:openAction];

	if ([appInfo isDebuggable])
	{
		UIAlertAction* openWithJITAction = [UIAlertAction actionWithTitle:@"启用JIT并打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			[self openAppPressedForRowAtIndexPath:indexPath enableJIT:YES];
			[self deselectRow];
		}];
		[appSelectAlert addAction:openWithJITAction];
	}

	UIAlertAction* showDetailsAction = [UIAlertAction actionWithTitle:@"显示详情" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		[self showDetailsPressedForRowAtIndexPath:indexPath];
		[self deselectRow];
	}];
	[appSelectAlert addAction:showDetailsAction];

	NSString* switchState;
	NSString* registrationState = [appInfo registrationState];
	UIAlertActionStyle switchActionStyle = 0;
	if([registrationState isEqualToString:@"System"])
	{
		switchState = @"User";
		switchActionStyle = UIAlertActionStyleDestructive;
	}
	else if([registrationState isEqualToString:@"User"])
	{
		switchState = @"System";
		switchActionStyle = UIAlertActionStyleDefault;
	}

	UIAlertAction* switchRegistrationAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"切换到\"%@\"注册状态", switchState] style:switchActionStyle handler:^(UIAlertAction* action)
	{
		[self changeAppRegistrationForRowAtIndexPath:indexPath toState:switchState];
		[self deselectRow];
	}];
	[appSelectAlert addAction:switchRegistrationAction];

	UIAlertAction* uninstallAction = [UIAlertAction actionWithTitle:@"卸载应用" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
	{
		[self uninstallPressedForRowAtIndexPath:indexPath];
		[self deselectRow];
	}];
	[appSelectAlert addAction:uninstallAction];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action)
	{
		[self deselectRow];
	}];
	[appSelectAlert addAction:cancelAction];

	appSelectAlert.popoverPresentationController.sourceView = tableView;
	appSelectAlert.popoverPresentationController.sourceRect = [tableView rectForRowAtIndexPath:indexPath];

	[TSPresentationDelegate presentViewController:appSelectAlert animated:YES completion:nil];
}

- (void)purgeCachedIconsForApps:(NSArray <LSApplicationProxy *>*)apps
{
	for (LSApplicationProxy *appProxy in apps) {
		NSString *appId = appProxy.bundleIdentifier;
		if (_cachedIcons[appId]) {
			[_cachedIcons removeObjectForKey:appId];
		}
	}
}

- (void)applicationsDidInstall:(NSArray <LSApplicationProxy *>*)apps
{
	[self purgeCachedIconsForApps:apps];
	[self reloadTable];
}

- (void)applicationsDidUninstall:(NSArray <LSApplicationProxy *>*)apps
{
	[self purgeCachedIconsForApps:apps];
	[self reloadTable];
}

- (void)setupNavigationBar {
    // 设置导航栏样式
    self.navigationItem.title = @"应用列表";
    
    // 创建刷新按钮
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                                                                    target:self 
                                                                                    action:@selector(refreshPressed)];
    
    // 设置按钮颜色
    refreshButton.tintColor = [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0];
    
    // 添加到导航栏
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    // 创建编辑按钮
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0];
}

- (void)refreshPressed {
    // 显示刷新指示器
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    [activityIndicator startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    
    // 刷新应用列表
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self reloadApps];
        
        // 恢复刷新按钮
        dispatch_async(dispatch_get_main_queue(), ^{
            UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                                                                          target:self 
                                                                                          action:@selector(refreshPressed)];
            refreshButton.tintColor = [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0];
            self.navigationItem.rightBarButtonItem = refreshButton;
        });
    });
}

- (void)showInstallOptions {
    @try {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"安装选项" 
                                                                                message:nil 
                                                                         preferredStyle:UIAlertControllerStyleActionSheet];
        
        // 添加"从文件安装"选项
        [alertController addAction:[UIAlertAction actionWithTitle:@"从文件安装" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self installFromFiles];
        }]];
        
        // 添加"从URL安装"选项
        [alertController addAction:[UIAlertAction actionWithTitle:@"从URL安装" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self installFromURL];
        }]];
        
        // 添加"取消"选项
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        
        // 使用非弃用的方法检查iPad
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            alertController.popoverPresentationController.sourceView = self.addButton;
            alertController.popoverPresentationController.sourceRect = self.addButton.bounds;
        }
        
        // 显示警告控制器
        [self presentViewController:alertController animated:YES completion:nil];
    } @catch (NSException *exception) {
        NSLog(@"显示安装选项时出错: %@", exception);
        
        // 显示简单错误消息
        UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误" 
                                                                           message:@"无法显示安装选项" 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
        [errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:errorAlert animated:YES completion:nil];
    }
}

- (void)installFromFiles {
    @try {
        // 根据iOS版本选择不同的初始化方法
        if (@available(iOS 14.0, *)) {
            // 创建文档类型数组 - 使用手动创建的UTType
            NSArray *documentTypes = @[@"com.apple.itunes.ipa", @"public.data"];
            
            // 使用Objective-C运行时检查新类是否可用
            Class utTypeClass = NSClassFromString(@"UTType");
            if (utTypeClass && [utTypeClass respondsToSelector:@selector(typeWithIdentifier:)]) {
                // UTType可用，创建文档选择器 - 使用新API
                UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:documentTypes];
                documentPickerVC.delegate = self;
                [self presentViewController:documentPickerVC animated:YES completion:nil];
            } else {
                // 降级到老方法，这里我们需要禁用警告
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] 
                                                                    initWithDocumentTypes:documentTypes
                                                                    inMode:UIDocumentPickerModeImport];
                documentPickerVC.delegate = self;
                [self presentViewController:documentPickerVC animated:YES completion:nil];
#pragma clang diagnostic pop
            }
        } else {
            // iOS 14之前的版本，这里我们需要禁用警告
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] 
                                                                initWithDocumentTypes:@[@"com.apple.itunes.ipa", @"public.item"]
                                                                inMode:UIDocumentPickerModeImport];
            documentPickerVC.delegate = self;
            [self presentViewController:documentPickerVC animated:YES completion:nil];
#pragma clang diagnostic pop
        }
    } @catch (NSException *exception) {
        NSLog(@"打开文件选择器时出错: %@", exception);
        
        // 显示错误提示
        UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误" 
                                                                           message:@"无法打开文件选择器" 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
        [errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:errorAlert animated:YES completion:nil];
    }
}

- (void)installFromURL {
	@try {
		// 创建警告控制器以获取URL
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"从URL安装" 
																				message:@"请输入IPA文件的URL" 
																		 preferredStyle:UIAlertControllerStyleAlert];
		
		// 添加文本字段
		[alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
			textField.placeholder = @"https://example.com/app.ipa";
			textField.autocorrectionType = UITextAutocorrectionTypeNo;
			textField.keyboardType = UIKeyboardTypeURL;
		}];
		
		// 添加确认操作
		[alertController addAction:[UIAlertAction actionWithTitle:@"安装" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			UITextField *urlField = alertController.textFields.firstObject;
			NSString *urlString = urlField.text;
			
			if (urlString.length > 0) {
				// 处理URL安装
				[self handleInstallFromURL:urlString];
			}
		}]];
		
		// 添加取消操作
		[alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
		
		// 显示警告控制器
		[self presentViewController:alertController animated:YES completion:nil];
	} @catch (NSException *exception) {
		NSLog(@"显示URL输入对话框时出错: %@", exception);
		
		// 显示错误提示
		UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误" 
																		   message:@"无法显示URL输入对话框" 
																	preferredStyle:UIAlertControllerStyleAlert];
		[errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:errorAlert animated:YES completion:nil];
	}
}

- (void)handleInstallFromURL:(NSString *)urlString {
	// 安全处理URL安装
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		@try {
			// 处理URL安装逻辑
			NSURL *url = [NSURL URLWithString:urlString];
			if (!url) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self showErrorWithMessage:@"无效的URL格式"];
				});
				return;
			}
			
			// 显示下载进度
			dispatch_async(dispatch_get_main_queue(), ^{
				[self showDownloadProgressForURL:url];
			});
			
			// 此处添加实际下载和安装逻辑
			// ...
			
		} @catch (NSException *exception) {
			NSLog(@"处理URL安装时出错: %@", exception);
			dispatch_async(dispatch_get_main_queue(), ^{
				[self showErrorWithMessage:@"处理URL安装时出错"];
			});
		}
	});
}

- (void)showDownloadProgressForURL:(NSURL *)url {
	// 显示下载进度UI
	@try {
		UIAlertController *progressAlert = [UIAlertController alertControllerWithTitle:@"下载中" 
																			  message:@"正在下载应用..." 
																	   preferredStyle:UIAlertControllerStyleAlert];
		
		// 添加取消按钮
		[progressAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			// 处理取消下载
		}]];
		
		// 显示进度警告
		[self presentViewController:progressAlert animated:YES completion:nil];
		
		// 注意：这里应该实现实际的下载逻辑和进度更新
	} @catch (NSException *exception) {
		NSLog(@"显示下载进度UI时出错: %@", exception);
	}
}

- (void)showErrorWithMessage:(NSString *)message {
	@try {
		UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误" 
																		   message:message 
																	preferredStyle:UIAlertControllerStyleAlert];
		[errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:errorAlert animated:YES completion:nil];
	} @catch (NSException *exception) {
		NSLog(@"显示错误消息时发生异常: %@", exception);
	}
}

@end
