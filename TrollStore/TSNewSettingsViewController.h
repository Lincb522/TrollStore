#import "TSSettingsViewController.h"

@interface TSNewSettingsViewController : TSSettingsViewController

@property (nonatomic, strong) NSString *newerVersion;
@property (nonatomic, strong) NSString *newerLdidVersion;
@property (nonatomic, assign) BOOL devModeEnabled;

// 实用工具方法
- (void)respringButtonPressed;
- (void)refreshAppRegistrationsPressed;
- (void)rebuildIconCachePressed;
- (void)transferAppsPressed;
- (void)updateTrollStorePressed;
- (void)enableDevModePressed;
- (void)installOrUpdateLdidPressed;
- (void)installPersistenceHelperPressed;
- (void)uninstallPersistenceHelperPressed;
- (void)uninstallTrollStorePressed;

// 数据方法
- (NSString *)getTrollStoreVersion;
- (NSArray *)installationConfirmationValues;
- (NSArray *)installationConfirmationNames;

@end 