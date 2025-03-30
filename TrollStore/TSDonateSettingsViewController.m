#import "TSDonateSettingsViewController.h"

@implementation TSDonateSettingsViewController

#pragma mark - 生命周期方法

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"捐赠";
    
    // 设置白色背景
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self loadSettings];
}

#pragma mark - 捐赠方法

- (void)donateToAlfiePressed {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://ko-fi.com/alfiecg_dev"] options:@{} completionHandler:^(BOOL success){}];
}

- (void)donateToOpaPressed {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=opa334@protonmail.com&item_name=TrollStore"] options:@{} completionHandler:^(BOOL success){}];
}

#pragma mark - 加载设置

- (void)loadSettings {
    // 清空现有设置
    [self removeAllSections];
    
    // Alfie部分
    TSSettingItem *alfieGroupItem = [TSSettingItem groupItemWithTitle:@"ALFIE"];
    alfieGroupItem.footerText = @"Alfie通过补丁比较发现了新的CoreTrust漏洞(CVE-2023-41991)，制作了概念验证二进制文件，并与ChOma库的帮助下自动应用它，同时也为该库做出了贡献。";
    
    NSMutableArray *alfieSection = [NSMutableArray arrayWithObject:alfieGroupItem];
    
    TSSettingItem *alfieDonateItem = [TSSettingItem buttonItemWithTitle:@"向alfiecg_dev捐赠" target:self action:@selector(donateToAlfiePressed)];
    alfieDonateItem.identifier = @"donateToAlfie";
    [alfieSection addObject:alfieDonateItem];
    
    [self addSection:alfieSection];
    
    // Opa部分
    TSSettingItem *opaGroupItem = [TSSettingItem groupItemWithTitle:@"OPA"];
    opaGroupItem.footerText = @"Opa开发了ChOma库，帮助使用它自动化利用漏洞，并将其集成到TrollStore中。";
    
    NSMutableArray *opaSection = [NSMutableArray arrayWithObject:opaGroupItem];
    
    TSSettingItem *opaDonateItem = [TSSettingItem buttonItemWithTitle:@"向opa334捐赠" target:self action:@selector(donateToOpaPressed)];
    opaDonateItem.identifier = @"donateToOpa";
    [opaSection addObject:opaDonateItem];
    
    [self addSection:opaSection];
}

@end 