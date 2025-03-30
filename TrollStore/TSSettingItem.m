#import "TSSettingItem.h"

@implementation TSSettingItem

#pragma mark - 初始化方法

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled = YES;
    }
    return self;
}

#pragma mark - 便利构造器

+ (instancetype)groupItemWithTitle:(NSString *)title {
    TSSettingItem *item = [[TSSettingItem alloc] init];
    item.title = title;
    item.type = TSSettingItemTypeGroup;
    return item;
}

+ (instancetype)buttonItemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    TSSettingItem *item = [[TSSettingItem alloc] init];
    item.title = title;
    item.type = TSSettingItemTypeButton;
    item.target = target;
    item.action = action;
    item.identifier = title;
    return item;
}

+ (instancetype)switchItemWithTitle:(NSString *)title key:(NSString *)key defaultValue:(id)defaultValue {
    TSSettingItem *item = [[TSSettingItem alloc] init];
    item.title = title;
    item.type = TSSettingItemTypeSwitch;
    item.key = key;
    item.defaultValue = defaultValue;
    item.identifier = key;
    return item;
}

+ (instancetype)linkItemWithTitle:(NSString *)title detailControllerClass:(Class)detailControllerClass {
    TSSettingItem *item = [[TSSettingItem alloc] init];
    item.title = title;
    item.type = TSSettingItemTypeLink;
    item.detailControllerClass = detailControllerClass;
    item.identifier = title;
    return item;
}

+ (instancetype)selectionItemWithTitle:(NSString *)title key:(NSString *)key values:(NSArray *)values titles:(NSDictionary *)titles defaultValue:(id)defaultValue {
    TSSettingItem *item = [[TSSettingItem alloc] init];
    item.title = title;
    item.type = TSSettingItemTypeSelection;
    item.key = key;
    item.values = values;
    item.titleDictionary = titles;
    item.defaultValue = defaultValue;
    item.identifier = key;
    return item;
}

+ (instancetype)segmentItemWithTitle:(NSString *)title key:(NSString *)key values:(NSArray *)values titles:(NSDictionary *)titles defaultValue:(id)defaultValue {
    TSSettingItem *item = [[TSSettingItem alloc] init];
    item.title = title;
    item.type = TSSettingItemTypeSegment;
    item.key = key;
    item.values = values;
    item.titleDictionary = titles;
    item.defaultValue = defaultValue;
    item.identifier = key;
    return item;
}

+ (instancetype)staticTextItemWithTitle:(NSString *)title {
    TSSettingItem *item = [[TSSettingItem alloc] init];
    item.title = title;
    item.type = TSSettingItemTypeStaticText;
    item.enabled = NO;
    return item;
}

@end 