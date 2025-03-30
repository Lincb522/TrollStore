#import "TSNewSettingsViewController.h"
#import "TSAppTableViewController.h"
#import "TSUtil.h"
#import "TSInstallationController.h"
#import "TSApplicationsManager.h"
#import "TSAppInfo.h"
#import <TSPresentationDelegate.h>
@import UniformTypeIdentifiers;

// 导入高级设置和捐赠控制器的头文件
@class TSAdvancedSettingsViewController;
@class TSDonateSettingsViewController;

// 用于访问TrollStore的用户默认值
extern NSUserDefaults* trollStoreUserDefaults(void);

@interface TSNewSettingsViewController ()
{
    TSSettingItem* _installPersistenceHelperItem;
}
@end

@implementation TSNewSettingsViewController

#pragma mark - 生命周期方法

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadSettings) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadSettings) name:@"TrollStoreReloadSettingsNotification" object:nil];
    
    // 设置界面配置
    self.navigationItem.title = @"设置";
    
    // 添加返回到应用列表的主页按钮
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.left"] 
                                                                   style:UIBarButtonItemStylePlain 
                                                                  target:self 
                                                                  action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    // 确保设置TSPresentationDelegate的presentationViewController
    TSPresentationDelegate.presentationViewController = self;
    
    // 获取版本信息
#ifndef TROLLSTORE_LITE
    fetchLatestTrollStoreVersion(^(NSString* latestVersion) {
        NSString* currentVersion = [self getTrollStoreVersion];
        NSComparisonResult result = [currentVersion compare:latestVersion options:NSNumericSearch];
        if(result == NSOrderedAscending) {
            _newerVersion = latestVersion;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadSettings];
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
            _newerLdidVersion = latestVersion;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadSettings];
            });
        }
    });

    if (@available(iOS 16, *)) {
        _devModeEnabled = spawnRoot(rootHelperPath(), @[@"check-dev-mode"], nil, nil) == 0;
    } else {
        _devModeEnabled = YES;
    }
#endif
    
    // 加载设置
    [self loadSettings];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 数据方法

- (NSString *)getTrollStoreVersion {
    NSString *versionPlistPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"version.plist"];
    NSDictionary *versionDict = [NSDictionary dictionaryWithContentsOfFile:versionPlistPath];
    if (versionDict) {
        return versionDict[@"Version"] ?: @"未知";
    }
    return @"未知";
}

- (NSArray *)installationConfirmationValues {
    return @[@0, @1, @2];
}

- (NSArray *)installationConfirmationNames {
    return @[@"始终显示（推荐）", @"仅在远程URL安装时显示", @"从不显示（不推荐）"];
}

#pragma mark - 加载设置

- (void)loadSettings {
    // 清空现有设置
    [self removeAllSections];
    
#ifndef TROLLSTORE_LITE
    // 显示更新按钮
    if (_newerVersion) {
        TSSettingItem *updateGroupItem = [TSSettingItem groupItemWithTitle:@"可用更新"];
        
        NSMutableArray *updateSection = [NSMutableArray arrayWithObject:updateGroupItem];
        
        NSString *updateTitle = [NSString stringWithFormat:@"更新TrollStore到%@版本", _newerVersion];
        TSSettingItem *updateItem = [TSSettingItem buttonItemWithTitle:updateTitle target:self action:@selector(updateTrollStorePressed)];
        updateItem.identifier = @"updateTrollStore";
        [updateSection addObject:updateItem];
        
        [self addSection:updateSection];
    }
    
    // 开发者模式
    if (!_devModeEnabled) {
        TSSettingItem *developerGroupItem = [TSSettingItem groupItemWithTitle:@"开发者模式"];
        developerGroupItem.footerText = @"某些应用需要启用开发者模式才能运行。这需要重启设备才能生效。";
        
        NSMutableArray *developerSection = [NSMutableArray arrayWithObject:developerGroupItem];
        
        TSSettingItem *enableDevModeItem = [TSSettingItem buttonItemWithTitle:@"启用开发者模式" target:self action:@selector(enableDevModePressed)];
        enableDevModeItem.identifier = @"enableDevMode";
        [developerSection addObject:enableDevModeItem];
        
        [self addSection:developerSection];
    }
#endif
    
    // 工具部分
    TSSettingItem *utilitiesGroupItem = [TSSettingItem groupItemWithTitle:@"实用工具"];
    
    NSString *utilitiesDescription = @"";
#ifdef TROLLSTORE_LITE
    if (shouldRegisterAsUserByDefault()) {
        utilitiesDescription = @"由于已安装AppSync Unified，应用将默认注册为User类型。\n\n";
    } else {
        utilitiesDescription = @"由于未安装AppSync Unified，应用将默认注册为System类型。当应用失去System注册状态而无法工作时，点击"刷新应用注册"来修复。\n\n";
    }
#endif
    utilitiesDescription = [utilitiesDescription stringByAppendingString:@"如果应用安装后没有立即显示，请在此处重新加载SpringBoard，应用就会显示。"];
    utilitiesGroupItem.footerText = utilitiesDescription;
    
    NSMutableArray *utilitiesSection = [NSMutableArray arrayWithObject:utilitiesGroupItem];
    
    // 添加工具按钮
    TSSettingItem *respringItem = [TSSettingItem buttonItemWithTitle:@"重新加载SpringBoard" target:self action:@selector(respringButtonPressed)];
    respringItem.identifier = @"respring";
    [utilitiesSection addObject:respringItem];
    
    TSSettingItem *refreshAppRegistrationsItem = [TSSettingItem buttonItemWithTitle:@"刷新应用注册" target:self action:@selector(refreshAppRegistrationsPressed)];
    refreshAppRegistrationsItem.identifier = @"refreshAppRegistrations";
    [utilitiesSection addObject:refreshAppRegistrationsItem];
    
    TSSettingItem *rebuildIconCacheItem = [TSSettingItem buttonItemWithTitle:@"重建图标缓存" target:self action:@selector(rebuildIconCachePressed)];
    rebuildIconCacheItem.identifier = @"uicache";
    [utilitiesSection addObject:rebuildIconCacheItem];
    
    // 添加应用转移按钮（如果有）
    NSArray *inactiveBundlePaths = trollStoreInactiveInstalledAppBundlePaths();
    if (inactiveBundlePaths.count > 0) {
        NSString *transferTitle = [NSString stringWithFormat:@"转移 %zu 个"OTHER_APP_NAME@" %@", inactiveBundlePaths.count, inactiveBundlePaths.count > 1 ? @"应用" : @"应用"];
        TSSettingItem *transferAppsItem = [TSSettingItem buttonItemWithTitle:transferTitle target:self action:@selector(transferAppsPressed)];
        transferAppsItem.identifier = @"transferApps";
        transferAppsItem.subtitle = @"转移旧版本安装的应用";
        [utilitiesSection addObject:transferAppsItem];
    }
    
    [self addSection:utilitiesSection];
    
#ifndef TROLLSTORE_LITE
    // 签名部分
    NSString* ldidPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"ldid"];
    NSString* ldidVersionPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"ldid.version"];
    BOOL ldidInstalled = [[NSFileManager defaultManager] fileExistsAtPath:ldidPath];
    
    NSString* ldidVersion = nil;
    NSData* ldidVersionData = [NSData dataWithContentsOfFile:ldidVersionPath];
    if(ldidVersionData) {
        ldidVersion = [[NSString alloc] initWithData:ldidVersionData encoding:NSUTF8StringEncoding];
    }
    
    TSSettingItem *signingGroupItem = [TSSettingItem groupItemWithTitle:@"签名工具"];
    
    if(ldidInstalled) {
        signingGroupItem.footerText = @"ldid已安装，TrollStore可以安装未签名的IPA文件。";
    } else {
        signingGroupItem.footerText = @"为了使TrollStore能够安装未签名的IPA文件，需要使用此按钮安装ldid。由于许可证问题，它不能直接包含在TrollStore中。";
    }
    
    NSMutableArray *signingSection = [NSMutableArray arrayWithObject:signingGroupItem];
    
    if(ldidInstalled) {
        NSString* installedTitle = @"ldid: 已安装";
        if(ldidVersion) {
            installedTitle = [NSString stringWithFormat:@"%@ (%@)", installedTitle, ldidVersion];
        }
        
        TSSettingItem *ldidInstalledItem = [TSSettingItem staticTextItemWithTitle:installedTitle];
        ldidInstalledItem.identifier = @"ldidInstalled";
        [signingSection addObject:ldidInstalledItem];
        
        if(_newerLdidVersion && ![_newerLdidVersion isEqualToString:ldidVersion]) {
            NSString* updateTitle = [NSString stringWithFormat:@"更新到 %@", _newerLdidVersion];
            TSSettingItem *ldidUpdateItem = [TSSettingItem buttonItemWithTitle:updateTitle target:self action:@selector(installOrUpdateLdidPressed)];
            ldidUpdateItem.identifier = @"updateLdid";
            [signingSection addObject:ldidUpdateItem];
        }
    } else {
        TSSettingItem *installLdidItem = [TSSettingItem buttonItemWithTitle:@"安装ldid" target:self action:@selector(installOrUpdateLdidPressed)];
        installLdidItem.identifier = @"installLdid";
        [signingSection addObject:installLdidItem];
    }
    
    [self addSection:signingSection];
    
    // 持久化部分
    TSSettingItem *persistenceGroupItem = [TSSettingItem groupItemWithTitle:@"持久性"];
    
    NSMutableArray *persistenceSection = [NSMutableArray arrayWithObject:persistenceGroupItem];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/TrollStorePersistenceHelper.app"]) {
        persistenceGroupItem.footerText = @"当iOS重建图标缓存时，所有TrollStore应用（包括TrollStore本身）将恢复为\"User\"状态，可能会消失或无法启动。如果出现这种情况，您可以使用主屏幕上的TrollHelper应用刷新应用注册，这将使它们再次正常工作。";
        
        TSSettingItem *installedPersistenceHelperItem = [TSSettingItem staticTextItemWithTitle:@"辅助工具已安装为独立应用"];
        installedPersistenceHelperItem.identifier = @"persistenceHelperInstalled";
        [persistenceSection addObject:installedPersistenceHelperItem];
    } else {
        LSApplicationProxy* persistenceApp = findPersistenceHelperApp(PERSISTENCE_HELPER_TYPE_ALL);
        if(persistenceApp) {
            NSString* appName = [persistenceApp localizedName];
            
            persistenceGroupItem.footerText = [NSString stringWithFormat:@"当iOS重建图标缓存时，所有TrollStore应用（包括TrollStore本身）将恢复为\"User\"状态，可能会消失或无法启动。如果出现这种情况，您可以使用安装在%@中的持久性辅助工具刷新应用注册，这将使它们再次正常工作。", appName];
            
            TSSettingItem *installedPersistenceHelperItem = [TSSettingItem staticTextItemWithTitle:[NSString stringWithFormat:@"辅助工具已安装到%@", appName]];
            installedPersistenceHelperItem.identifier = @"persistenceHelperInstalled";
            [persistenceSection addObject:installedPersistenceHelperItem];
            
            TSSettingItem *uninstallPersistenceHelperItem = [TSSettingItem buttonItemWithTitle:@"卸载持久性辅助工具" target:self action:@selector(uninstallPersistenceHelperPressed)];
            uninstallPersistenceHelperItem.identifier = @"uninstallPersistenceHelper";
            [persistenceSection addObject:uninstallPersistenceHelperItem];
        } else {
            persistenceGroupItem.footerText = @"当iOS重建图标缓存时，所有TrollStore应用（包括TrollStore本身）将恢复为\"User\"状态，可能会消失或无法启动。在无根环境中实现持久性的唯一方法是替换系统应用程序，在这里您可以选择一个系统应用程序来替换为持久性辅助工具，以便在TrollStore相关应用消失或无法启动时刷新它们的注册。";
            
            _installPersistenceHelperItem = [TSSettingItem buttonItemWithTitle:@"安装持久性辅助工具" target:self action:@selector(installPersistenceHelperPressed)];
            _installPersistenceHelperItem.identifier = @"installPersistenceHelper";
            [persistenceSection addObject:_installPersistenceHelperItem];
        }
    }
    
    [self addSection:persistenceSection];
#endif
    
    // 安全设置部分
    TSSettingItem *securityGroupItem = [TSSettingItem groupItemWithTitle:@"安全设置"];
    securityGroupItem.footerText = @"启用URL方案后，应用程序和网站可以通过apple-magnifier://install?url=<IPA_URL>的URL方案触发TrollStore安装，并通过apple-magnifier://enable-jit?bundle-id=<BUNDLE_ID>的URL方案启用JIT。";
    
    NSMutableArray *securitySection = [NSMutableArray arrayWithObject:securityGroupItem];
    
    // URL方案开关
    BOOL URLSchemeActive = (BOOL)[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    TSSettingItem *URLSchemeItem = [TSSettingItem switchItemWithTitle:@"启用URL方案" key:@"URLSchemeEnabled" defaultValue:@(URLSchemeActive)];
    URLSchemeItem.identifier = @"URL Scheme Enabled";
    [securitySection addObject:URLSchemeItem];
    
    // 安装确认
    TSSettingItem *installAlertItem = [TSSettingItem selectionItemWithTitle:@"显示安装确认提醒" 
                                                                        key:@"installAlertConfiguration" 
                                                                     values:[self installationConfirmationValues] 
                                                                     titles:[NSDictionary dictionaryWithObjects:[self installationConfirmationNames] forKeys:[self installationConfirmationValues]] 
                                                               defaultValue:@0];
    installAlertItem.identifier = @"Show Install Confirmation Alert";
    [securitySection addObject:installAlertItem];
    
    [self addSection:securitySection];
    
    // 其他设置部分
    TSSettingItem *otherGroupItem = [TSSettingItem groupItemWithTitle:@"其他设置"];
    otherGroupItem.footerText = [NSString stringWithFormat:@"%@ %@\n\n© 2022-2024 Lars Fröder (opa334)\n\nTrollStore不用于盗版！\n\n贡献者：\nGoogle TAG, @alfiecg_dev: CoreTrust漏洞\n@lunotech11, @SerenaKit, @tylinux, @TheRealClarity, @dhinakg, @khanhduytran0: 各种贡献\n@ProcursusTeam: uicache, ldid\n@cstar_ow: uicache\n@saurik: ldid", APP_NAME, [self getTrollStoreVersion]];
    
    NSMutableArray *otherSection = [NSMutableArray arrayWithObject:otherGroupItem];
    
    // 高级设置
    TSSettingItem *advancedItem = [TSSettingItem linkItemWithTitle:@"高级设置" detailControllerClass:NSClassFromString(@"TSAdvancedSettingsViewController")];
    advancedItem.identifier = @"Advanced";
    [otherSection addObject:advancedItem];
    
    // 捐赠
    TSSettingItem *donateItem = [TSSettingItem linkItemWithTitle:@"捐赠" detailControllerClass:NSClassFromString(@"TSDonateSettingsViewController")];
    donateItem.identifier = @"Donate";
    [otherSection addObject:donateItem];
    
#ifndef TROLLSTORE_LITE
    // 卸载TrollStore
    TSSettingItem *uninstallTrollStoreItem = [TSSettingItem buttonItemWithTitle:@"卸载TrollStore" target:self action:@selector(uninstallTrollStorePressed)];
    uninstallTrollStoreItem.identifier = @"uninstallTrollStore";
    [otherSection addObject:uninstallTrollStoreItem];
#endif
    
    [self addSection:otherSection];
}

#pragma mark - 按钮动作处理

- (void)respringButtonPressed {
    respring();
}

- (void)refreshAppRegistrationsPressed {
    [TSPresentationDelegate startActivity:@"正在刷新..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int ret = spawnRoot(rootHelperPath(), @[@"refresh-apps", @"ALL"], nil, nil);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [TSPresentationDelegate stopActivityWithCompletion:^{
                if (ret != 0) {
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"错误" message:[NSString stringWithFormat:@"错误代码: %d", ret] preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];
                    [alert addAction:closeAction];
                    [TSPresentationDelegate presentViewController:alert animated:YES completion:nil];
                }
            }];
        });
    });
}

- (void)rebuildIconCachePressed {
    UIAlertController* uicacheTypeAlert = [UIAlertController alertControllerWithTitle:@"重建图标缓存" message:@"选择重建方式" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* fullAction = [UIAlertAction actionWithTitle:@"完整uicache（相当于重启）" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [TSPresentationDelegate startActivity:@"正在重建图标缓存..."];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            spawnRoot(rootHelperPath(), @[@"uicache", @"-a"], nil, nil);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [TSPresentationDelegate stopActivityWithCompletion:nil];
            });
        });
    }];
    [uicacheTypeAlert addAction:fullAction];
    
    UIAlertAction* trollStoreOnlyAction = [UIAlertAction actionWithTitle:@"仅TrollStore应用" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [TSPresentationDelegate startActivity:@"正在重建TrollStore应用图标缓存..."];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            spawnRoot(rootHelperPath(), @[@"uicache", @"-m", @"trollstore-apps"], nil, nil);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [TSPresentationDelegate stopActivityWithCompletion:nil];
            });
        });
    }];
    [uicacheTypeAlert addAction:trollStoreOnlyAction];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [uicacheTypeAlert addAction:cancelAction];
    
    [TSPresentationDelegate presentViewController:uicacheTypeAlert animated:YES completion:nil];
}

- (void)transferAppsPressed {
    NSArray *inactiveBundlePaths = trollStoreInactiveInstalledAppBundlePaths();
    UIAlertController *confirmationAlert = [UIAlertController alertControllerWithTitle:@"转移应用" message:[NSString stringWithFormat:@"此选项将把%zu个应用从\"OTHER_APP_NAME@\"转移到\"APP_NAME@\"。继续吗？", inactiveBundlePaths.count] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* transferAction = [UIAlertAction actionWithTitle:@"转移" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [TSPresentationDelegate startActivity:@"正在转移"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *log;
            int transferRet = spawnRoot(rootHelperPath(), @[@"transfer-apps"], nil, &log);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [TSPresentationDelegate stopActivityWithCompletion:^{
                    [self loadSettings];
                    
                    if (transferRet != 0) {
                        NSArray *remainingApps = trollStoreInactiveInstalledAppBundlePaths();
                        UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"转移失败" message:[NSString stringWithFormat:@"未能转移%zu个%@", remainingApps.count, remainingApps.count > 1 ? @"应用" : @"应用"] preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction* copyLogAction = [UIAlertAction actionWithTitle:@"复制调试日志" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
                            UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
                            pasteboard.string = log;
                        }];
                        [errorAlert addAction:copyLogAction];
                        
                        UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];
                        [errorAlert addAction:closeAction];
                        
                        [TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
                    }
                }];
            });
        });
    }];
    [confirmationAlert addAction:transferAction];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [confirmationAlert addAction:cancelAction];
    
    [TSPresentationDelegate presentViewController:confirmationAlert animated:YES completion:nil];
}

- (void)updateTrollStorePressed {
    // 下载并更新TrollStore
    NSURL* latestVersionURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/opa334/TrollStore/releases/download/%@/TrollStore.tar", _newerVersion]];
    [TSInstallationController handleAppInstallFromRemoteURL:latestVersionURL completion:nil];
}

- (void)enableDevModePressed {
    int ret = spawnRoot(rootHelperPath(), @[@"arm-dev-mode"], nil, nil);
    
    if (ret == 0) {
        UIAlertController* rebootNotification = [UIAlertController alertControllerWithTitle:@"需要重启"
                                                                                    message:@"重启后，选择\"打开\"以启用开发者模式。"
                                                                             preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
            [self loadSettings];
        }];
        [rebootNotification addAction:closeAction];
        
        UIAlertAction* rebootAction = [UIAlertAction actionWithTitle:@"立即重启" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
            spawnRoot(rootHelperPath(), @[@"reboot"], nil, nil);
        }];
        [rebootNotification addAction:rebootAction];
        
        [TSPresentationDelegate presentViewController:rebootNotification animated:YES completion:nil];
    } else {
        UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"错误 %d", ret] message:@"启用开发者模式失败。" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleDefault handler:nil];
        [errorAlert addAction:closeAction];
        
        [TSPresentationDelegate presentViewController:errorAlert animated:YES completion:nil];
    }
}

- (void)installOrUpdateLdidPressed {
    [TSInstallationController installLdid];
}

- (void)installPersistenceHelperPressed {
    NSMutableArray* appCandidates = [NSMutableArray new];
    [[LSApplicationWorkspace defaultWorkspace] enumerateApplicationsOfType:1 block:^(LSApplicationProxy* appProxy) {
        if(appProxy.installed && !appProxy.restricted) {
            if([[NSFileManager defaultManager] fileExistsAtPath:[@"/System/Library/AppSignatures" stringByAppendingPathComponent:appProxy.bundleIdentifier]]) {
                NSURL* trollStoreMarkURL = [appProxy.bundleURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:TS_ACTIVE_MARKER];
                if(![trollStoreMarkURL checkResourceIsReachableAndReturnError:nil]) {
                    [appCandidates addObject:appProxy];
                }
            }
        }
    }];
    
    UIAlertController* selectAppAlert = [UIAlertController alertControllerWithTitle:@"选择应用" message:@"选择一个系统应用来安装TrollStore持久性辅助工具。该应用的正常功能将不再可用，因此建议选择不常用的应用，如\"提示\"应用。" preferredStyle:UIAlertControllerStyleActionSheet];
    for(LSApplicationProxy* appProxy in appCandidates) {
        UIAlertAction* installAction = [UIAlertAction actionWithTitle:[appProxy localizedName] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
            spawnRoot(rootHelperPath(), @[@"install-persistence-helper", appProxy.bundleIdentifier], nil, nil);
            [self loadSettings];
        }];
        
        [selectAppAlert addAction:installAction];
    }
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [selectAppAlert addAction:cancelAction];
    
    [TSPresentationDelegate presentViewController:selectAppAlert animated:YES completion:nil];
}

- (void)uninstallPersistenceHelperPressed {
    UIAlertController* confirmationAlert = [UIAlertController alertControllerWithTitle:@"确认" message:@"确定要卸载持久性辅助工具吗？这将恢复原始应用，但会降低TrollStore的持久性。" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* uninstallAction = [UIAlertAction actionWithTitle:@"卸载" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
        spawnRoot(rootHelperPath(), @[@"uninstall-persistence-helper"], nil, nil);
        [self loadSettings];
    }];
    [confirmationAlert addAction:uninstallAction];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [confirmationAlert addAction:cancelAction];
    
    [TSPresentationDelegate presentViewController:confirmationAlert animated:YES completion:nil];
}

- (void)uninstallTrollStorePressed {
    UIAlertController* confirmationAlert = [UIAlertController alertControllerWithTitle:@"确认" message:@"确定要卸载TrollStore和所有使用它安装的应用吗？" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* uninstallAction = [UIAlertAction actionWithTitle:@"卸载" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
        NSMutableArray* args = @[@"uninstall-trollstore"].mutableCopy;
        
        NSNumber* uninstallationMethodToUseNum = [trollStoreUserDefaults() objectForKey:@"uninstallationMethod"];
        int uninstallationMethodToUse = uninstallationMethodToUseNum ? uninstallationMethodToUseNum.intValue : 0;
        if(uninstallationMethodToUse == 1) {
            [args addObject:@"custom"];
        }
        
        spawnRoot(rootHelperPath(), args, nil, nil);
    }];
    [confirmationAlert addAction:uninstallAction];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [confirmationAlert addAction:cancelAction];
    
    [TSPresentationDelegate presentViewController:confirmationAlert animated:YES completion:nil];
}

#pragma mark - Observer methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"URLSchemeEnabled"]) {
        NSNumber* newValue = change[NSKeyValueChangeNewKey];
        NSString* newStateString = [newValue boolValue] ? @"enable" : @"disable";
        spawnRoot(rootHelperPath(), @[@"url-scheme", newStateString], nil, nil);
        
        UIAlertController* rebuildNoticeAlert = [UIAlertController alertControllerWithTitle:@"URL方案已更改" message:@"为了正确应用URL方案设置的更改，需要重建图标缓存。" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* rebuildNowAction = [UIAlertAction actionWithTitle:@"立即重建" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
            [self rebuildIconCachePressed];
        }];
        [rebuildNoticeAlert addAction:rebuildNowAction];
        
        UIAlertAction* rebuildLaterAction = [UIAlertAction actionWithTitle:@"稍后重建" style:UIAlertActionStyleCancel handler:nil];
        [rebuildNoticeAlert addAction:rebuildLaterAction];
        
        [TSPresentationDelegate presentViewController:rebuildNoticeAlert animated:YES completion:nil];
    }
}

- (void)backToMainView {
    [self goBack];
}

- (void)goBack {
    NSLog(@"返回按钮被点击");
    if (self.navigationController) {
        if (self.navigationController.viewControllers.count > 1) {
            // 如果在导航栈中不是根视图控制器，则弹出当前控制器
            [self.navigationController popViewControllerAnimated:YES];
        } else if (self.navigationController.presentingViewController) {
            // 如果是模态呈现的根视图控制器，则关闭整个导航控制器
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
    } else {
        NSLog(@"无法确定如何返回");
    }
}

@end 