#import <UIKit/UIKit.h>
#import "TSAppInfo.h"

@interface TSAppTableViewCell : UITableViewCell

@property (nonatomic, strong) UIImageView *appIconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *containerView;

- (void)configureWithAppInfo:(TSAppInfo *)appInfo;

@end 