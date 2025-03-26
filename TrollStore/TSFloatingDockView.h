#import <UIKit/UIKit.h>

@protocol TSFloatingDockViewDelegate <NSObject>
- (void)floatingDockDidSelectIndex:(NSInteger)index;
@end

@interface TSFloatingDockView : UIView

@property (nonatomic, weak) id<TSFloatingDockViewDelegate> delegate;
@property (nonatomic, assign) NSInteger selectedIndex;

- (instancetype)initWithFrame:(CGRect)frame icons:(NSArray<UIImage *> *)icons titles:(NSArray<NSString *> *)titles;
- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated;

@end 