#import <UIKit/UIKit.h>

@interface TSNewMainViewController : UIViewController

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *gradientBackgroundView;
@property (nonatomic, strong) UIVisualEffectView *cardView;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UIImageView *weatherImageView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *detailsContainerView;

- (void)setupAppInfoViews;
- (void)installAppButtonTapped;

@end 