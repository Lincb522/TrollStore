#import "TSRootViewController.h"
#import "TSAppTableViewController.h"
#import <TSPresentationDelegate.h>
#import "TSNewSettingsViewController.h"

@implementation TSRootViewController

- (void)loadView {
	[super loadView];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	TSPresentationDelegate.presentationViewController = self;

	// 创建应用列表控制器
	TSAppTableViewController* appTableVC = [[TSAppTableViewController alloc] init];
	appTableVC.title = @"Apps";
	UINavigationController* appNavigationController = [[UINavigationController alloc] initWithRootViewController:appTableVC];
	appNavigationController.tabBarItem.image = [UIImage systemImageNamed:@"square.stack.3d.up.fill"];
	appNavigationController.tabBarItem.title = @"应用";

	// 创建设置控制器
	UIViewController *settingsVC = [[TSNewSettingsViewController alloc] init];
	settingsVC.navigationItem.title = @"设置";
	UINavigationController *settingsNavController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
	settingsNavController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"设置" image:[UIImage systemImageNamed:@"gear"] tag:1];

	// 设置标签栏控制器
	self.viewControllers = @[appNavigationController, settingsNavController];
}

@end
