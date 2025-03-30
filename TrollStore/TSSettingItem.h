#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TSSettingItemType) {
    TSSettingItemTypeGroup,       // 组标题
    TSSettingItemTypeButton,      // 按钮
    TSSettingItemTypeSwitch,      // 开关
    TSSettingItemTypeLink,        // 链接（跳转到其他页面）
    TSSettingItemTypeSelection,   // 选择项
    TSSettingItemTypeSegment,     // 分段控制器
    TSSettingItemTypeStaticText   // 静态文本
};

@interface TSSettingItem : NSObject

// 基本属性
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, strong) UIImage *icon;
@property (nonatomic, assign) TSSettingItemType type;
@property (nonatomic, assign) BOOL enabled;

// 按钮和链接属性
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) Class detailControllerClass;

// 开关和选择项属性
@property (nonatomic, copy) NSString *key;
@property (nonatomic, strong) id defaultValue;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSDictionary *titleDictionary;

// 分组属性
@property (nonatomic, copy) NSString *footerText;

// 创建不同类型的设置项的便利方法
+ (instancetype)groupItemWithTitle:(NSString *)title;
+ (instancetype)buttonItemWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (instancetype)switchItemWithTitle:(NSString *)title key:(NSString *)key defaultValue:(id)defaultValue;
+ (instancetype)linkItemWithTitle:(NSString *)title detailControllerClass:(Class)detailControllerClass;
+ (instancetype)selectionItemWithTitle:(NSString *)title key:(NSString *)key values:(NSArray *)values titles:(NSDictionary *)titles defaultValue:(id)defaultValue;
+ (instancetype)segmentItemWithTitle:(NSString *)title key:(NSString *)key values:(NSArray *)values titles:(NSDictionary *)titles defaultValue:(id)defaultValue;
+ (instancetype)staticTextItemWithTitle:(NSString *)title;

@end 