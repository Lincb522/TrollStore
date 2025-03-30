#import "TSAdvancedSettingsViewController.h"
#import "TSUtil.h"
#import <TSPresentationDelegate.h>

// 用于访问TrollStore的用户默认值
extern NSUserDefaults* trollStoreUserDefaults(void);

@implementation TSAdvancedSettingsViewController

#pragma mark - 生命周期方法

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"高级设置";
    
    // 确保设置TSPresentationDelegate的presentationViewController
    TSPresentationDelegate.presentationViewController = self;
    
    // 设置白色背景
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self loadSettings];
}

#pragma mark - 加载设置

- (void)loadSettings {
    // 清空现有设置
    [self removeAllSections];
    
    // 安装方法部分
    TSSettingItem *installationMethodGroupItem = [TSSettingItem groupItemWithTitle:@"安装方法"];
    installationMethodGroupItem.footerText = @"installd方式:\n通过installd进行占位安装，修复权限后将应用添加到图标缓存。\n优点: 在图标缓存重载方面可能比自定义方法稍微更持久。\n缺点: 对某些应用可能会导致一些小问题（例如，使用此方法安装的Watusi无法保存偏好设置）。\n\n自定义方式 (推荐):\n通过手动使用MobileContainerManager创建一个包，将应用复制到其中并添加到图标缓存。\n优点: 没有已知问题（与installd方式中的Watusi问题不同）。\n缺点: 在图标缓存重载方面可能比installd方法稍微不那么持久。\n\n注意：如果选择了installd但占位安装失败，TrollStore会自动回退到使用自定义方法。";
    
    NSMutableArray *installationSection = [NSMutableArray arrayWithObject:installationMethodGroupItem];
    
    // 安装方法选择
    TSSettingItem *installationMethodItem = [TSSettingItem segmentItemWithTitle:@"安装方法" 
                                                                           key:@"installationMethod" 
                                                                        values:@[@0, @1] 
                                                                        titles:@{@0: @"installd", @1: @"自定义"} 
                                                                  defaultValue:@1];
    
    [installationSection addObject:installationMethodItem];
    
    [self addSection:installationSection];
    
    // 卸载方法部分
    TSSettingItem *uninstallationMethodGroupItem = [TSSettingItem groupItemWithTitle:@"卸载方法"];
    uninstallationMethodGroupItem.footerText = @"installd方式 (推荐):\n使用与SpringBoard从主屏幕卸载应用相同的API卸载应用。\n\n自定义方式:\n通过从图标缓存中移除应用并直接删除应用和数据包来卸载应用。\n\n注意：如果选择了installd但标准卸载失败，TrollStore会自动回退到使用自定义方法。";
    
    NSMutableArray *uninstallationSection = [NSMutableArray arrayWithObject:uninstallationMethodGroupItem];
    
    // 卸载方法选择
    TSSettingItem *uninstallationMethodItem = [TSSettingItem segmentItemWithTitle:@"卸载方法" 
                                                                             key:@"uninstallationMethod" 
                                                                          values:@[@0, @1] 
                                                                          titles:@{@0: @"installd", @1: @"自定义"} 
                                                                    defaultValue:@0];
    
    [uninstallationSection addObject:uninstallationMethodItem];
    
    [self addSection:uninstallationSection];
}

@end 