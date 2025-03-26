#import <UIKit/UIKit.h>

@interface TSRootViewController : UIViewController <UITabBarDelegate>

// 添加必要的属性
@property (nonatomic, strong) UITabBar *tabBar;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) CATextLayer *titleLayer;
@property (nonatomic, strong) UIViewController *currentViewController;

// 方法声明
- (void)showViewControllerAtIndex:(NSInteger)index;
- (void)refreshUI;

@end
