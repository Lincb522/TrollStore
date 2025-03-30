#import <UIKit/UIKit.h>
#import "TSSettingItem.h"

@interface TSSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

// 界面属性
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<NSArray<TSSettingItem *> *> *sections;

// 图标字典
@property (nonatomic, strong) NSMutableDictionary *sectionIconsDict;
@property (nonatomic, strong) NSMutableDictionary *itemIconsDict;

// 设置项方法
- (void)addSection:(NSArray<TSSettingItem *> *)section;
- (void)addItem:(TSSettingItem *)item toSection:(NSInteger)section;
- (void)removeAllSections;

// 用户默认值
- (void)setPreferenceValue:(id)value forKey:(NSString *)key;
- (id)preferenceValueForKey:(NSString *)key;

// UI方法
- (void)setupIcons;
- (void)setupModernUI;
- (UIImage *)getIconForIdentifier:(NSString *)identifier;
- (UIView *)createCardViewWithColor:(UIColor *)color cornerRadius:(CGFloat)radius;
- (UIView *)createSettingsItemWithIcon:(UIImage *)icon title:(NSString *)title subtitle:(NSString *)subtitle accessoryType:(NSInteger)accessoryType;

// 导航方法
- (void)backToMainView;

@end 