#import <UIKit/UIKit.h>

@class TSRootViewController;

@interface TSSystemInfoViewController : UIViewController

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, weak) TSRootViewController *rootController;

@end 