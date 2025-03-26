#import <UIKit/UIKit.h>

@class TSRootViewController;

@interface TSSettingsViewController : UIViewController

@property (nonatomic, readwrite, strong) UIScrollView *scrollView;
@property (nonatomic, readwrite, strong) UIView *contentView;
@property (nonatomic, weak) TSRootViewController *rootController;

// 版本信息
@property (nonatomic, readwrite, strong) NSString *newerVersion;
@property (nonatomic, readwrite, strong) NSString *newerLdidVersion;
@property (nonatomic, readwrite, assign) BOOL devModeEnabled;

// 重建UI方法
- (void)rebuildUI;
- (void)buildMinimalUI;
- (void)updateContentSize;
- (void)restartApp;

@end 