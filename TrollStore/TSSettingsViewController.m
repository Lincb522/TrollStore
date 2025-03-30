#import "TSSettingsViewController.h"
#import "TSUtil.h"
#import <objc/runtime.h>

// 用于访问TrollStore的用户默认值
extern NSUserDefaults* trollStoreUserDefaults(void);

@implementation TSSettingsViewController

#pragma mark - 生命周期方法

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化数据
    _sections = [NSMutableArray array];
    _sectionIconsDict = [NSMutableDictionary dictionary];
    _itemIconsDict = [NSMutableDictionary dictionary];
    
    // 设置导航栏
    self.navigationItem.title = @"设置";
    
    // 设置返回按钮（只有在非根视图控制器时才设置）
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.left"] 
                                                                    style:UIBarButtonItemStylePlain 
                                                                   target:self 
                                                                   action:@selector(backToMainView)];
        self.navigationItem.leftBarButtonItem = backButton;
    }
    
    // 设置白色背景
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 设置表格视图
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0];
    self.tableView.contentInset = UIEdgeInsetsMake(15, 0, 20, 0);
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    
    // 设置UI
    [self setupIcons];
    [self setupModernUI];
    
    // 为选择项添加观察者
    for (NSArray<TSSettingItem *> *section in _sections) {
        for (TSSettingItem *item in section) {
            if (item.key && (item.type == TSSettingItemTypeSwitch || item.type == TSSettingItemTypeSelection)) {
                // 添加键值观察
                [self addObserver:self forKeyPath:item.key options:NSKeyValueObservingOptionNew context:NULL];
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - 导航方法

- (void)backToMainView {
    // 检查是否在导航堆栈中
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.tabBarController) {
        // 如果在标签栏中，则切换到第一个标签
        [self.tabBarController setSelectedIndex:0];
    }
}

#pragma mark - 设置项管理

- (void)addSection:(NSArray<TSSettingItem *> *)section {
    [_sections addObject:[section mutableCopy]];
    [self.tableView reloadData];
}

- (void)addItem:(TSSettingItem *)item toSection:(NSInteger)section {
    if (section < 0 || section >= _sections.count) {
        NSMutableArray *newSection = [NSMutableArray arrayWithObject:item];
        [_sections addObject:newSection];
    } else {
        NSMutableArray *sectionArray = [_sections[section] mutableCopy];
        [sectionArray addObject:item];
        _sections[section] = sectionArray;
    }
    [self.tableView reloadData];
}

- (void)removeAllSections {
    [_sections removeAllObjects];
    [self.tableView reloadData];
}

#pragma mark - 偏好设置

- (void)setPreferenceValue:(id)value forKey:(NSString *)key {
    NSUserDefaults *defaults = trollStoreUserDefaults();
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

- (id)preferenceValueForKey:(NSString *)key {
    NSUserDefaults *defaults = trollStoreUserDefaults();
    id value = [defaults objectForKey:key];
    return value;
}

#pragma mark - UI设置

- (void)setupIcons {
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightRegular];
        
        // 部分标题图标
        [_sectionIconsDict setObject:[UIImage systemImageNamed:@"hammer.fill" withConfiguration:config] forKey:@"UTILITIES"];
        [_sectionIconsDict setObject:[UIImage systemImageNamed:@"signature" withConfiguration:config] forKey:@"SIGNING"];
        [_sectionIconsDict setObject:[UIImage systemImageNamed:@"arrow.clockwise.circle.fill" withConfiguration:config] forKey:@"PERSISTENCE"];
        [_sectionIconsDict setObject:[UIImage systemImageNamed:@"lock.shield.fill" withConfiguration:config] forKey:@"SECURITY"];
        [_sectionIconsDict setObject:[UIImage systemImageNamed:@"gift.fill" withConfiguration:config] forKey:@"ALFIE"];
        [_sectionIconsDict setObject:[UIImage systemImageNamed:@"gift.fill" withConfiguration:config] forKey:@"OPA"];
        [_sectionIconsDict setObject:[UIImage systemImageNamed:@"gear" withConfiguration:config] forKey:@"INSTALLATION METHOD"];
        [_sectionIconsDict setObject:[UIImage systemImageNamed:@"trash" withConfiguration:config] forKey:@"UNINSTALLATION METHOD"];
        
        // 设置项图标
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"arrow.3.trianglepath" withConfiguration:config] forKey:@"respring"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"app.badge.checkmark.fill" withConfiguration:config] forKey:@"refreshAppRegistrations"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"photo.stack.fill" withConfiguration:config] forKey:@"uicache"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"square.and.arrow.down.fill" withConfiguration:config] forKey:@"transferApps"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"signature" withConfiguration:config] forKey:@"installLdid"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"signature" withConfiguration:config] forKey:@"ldidInstalled"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"square.and.arrow.up.fill" withConfiguration:config] forKey:@"updateLdid"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"person.circle.fill" withConfiguration:config] forKey:@"persistenceHelperInstalled"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"trash.fill" withConfiguration:config] forKey:@"uninstallPersistenceHelper"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"link.circle.fill" withConfiguration:config] forKey:@"URL Scheme Enabled"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"bell.fill" withConfiguration:config] forKey:@"Show Install Confirmation Alert"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"gear" withConfiguration:config] forKey:@"Advanced"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"heart.fill" withConfiguration:config] forKey:@"Donate"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"trash.circle.fill" withConfiguration:config] forKey:@"uninstallTrollStore"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"gift.fill" withConfiguration:config] forKey:@"donateToAlfie"];
        [_itemIconsDict setObject:[UIImage systemImageNamed:@"gift.fill" withConfiguration:config] forKey:@"donateToOpa"];
    }
}

- (void)setupModernUI {
    // 可以在子类中重写以提供额外的UI定制
}

- (UIImage *)getIconForIdentifier:(NSString *)identifier {
    // 首先检查是否有直接的图标映射
    UIImage *itemIcon = [_itemIconsDict objectForKey:identifier];
    if (itemIcon) return itemIcon;
    
    // 特殊图标处理
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular];
        
        if ([identifier isEqualToString:@"back"]) {
            return [UIImage systemImageNamed:@"chevron.left"];
        } else if ([identifier isEqualToString:@"updateTrollStore"]) {
            return [UIImage systemImageNamed:@"arrow.down.app.fill" withConfiguration:config];
        } else if ([identifier isEqualToString:@"enableDevMode"]) {
            return [UIImage systemImageNamed:@"hammer.circle.fill" withConfiguration:config];
        } else if ([identifier containsString:@"ldid"]) {
            return [UIImage systemImageNamed:@"signature" withConfiguration:config];
        } else if ([identifier containsString:@"install"]) {
            return [UIImage systemImageNamed:@"square.and.arrow.down" withConfiguration:config];
        } else if ([identifier containsString:@"uninstall"]) {
            return [UIImage systemImageNamed:@"trash.fill" withConfiguration:config];
        } else if ([identifier containsString:@"donate"]) {
            return [UIImage systemImageNamed:@"gift.fill" withConfiguration:config];
        } else if ([identifier isEqualToString:@"default"]) {
            return [UIImage systemImageNamed:@"circle.fill" withConfiguration:config];
        }
    }
    
    // 使用默认图标
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:@"circle.fill"];
    }
    
    return nil;
}

- (UIView *)createCardViewWithColor:(UIColor *)color cornerRadius:(CGFloat)radius {
    UIView *cardView = [[UIView alloc] init];
    
    // 使用浅蓝色背景
    cardView.backgroundColor = [UIColor colorWithRed:0.94 green:0.96 blue:0.99 alpha:1.0];
    cardView.layer.cornerRadius = 12;
    cardView.clipsToBounds = YES;
    
    // 轻微的阴影效果
    cardView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.05].CGColor;
    cardView.layer.shadowOffset = CGSizeMake(0, 1);
    cardView.layer.shadowOpacity = 0.8;
    cardView.layer.shadowRadius = 2;
    
    return cardView;
}

- (UIView *)createSettingsItemWithIcon:(UIImage *)icon title:(NSString *)title subtitle:(NSString *)subtitle accessoryType:(NSInteger)accessoryType {
    // 根据是否有副标题确定高度
    CGFloat itemHeight = (subtitle && subtitle.length > 0) ? 50 : 40;
    
    UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 40, itemHeight)];
    
    // 图标垂直居中
    CGFloat iconY = (itemHeight - 20) / 2;
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(15, iconY, 20, 20)];
    iconView.image = icon;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.tintColor = [UIColor colorWithRed:0.24 green:0.43 blue:0.82 alpha:1.0]; // 保留蓝色图标
    [itemView addSubview:iconView];
    
    if (subtitle && subtitle.length > 0) {
        // 有副标题时，调整标题位置
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 8, itemView.bounds.size.width - 80, 18)];
        titleLabel.text = title;
        titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        titleLabel.textColor = [UIColor blackColor];
        [itemView addSubview:titleLabel];
        
        // 副标题标签
        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 28, itemView.bounds.size.width - 80, 20)];
        subtitleLabel.text = subtitle;
        subtitleLabel.font = [UIFont systemFontOfSize:12];
        subtitleLabel.textColor = [UIColor grayColor];
        subtitleLabel.numberOfLines = 2; // 允许显示两行
        subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping; // 按词换行
        [itemView addSubview:subtitleLabel];
    } else {
        // 无副标题时，标题垂直居中
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, (itemHeight - 20) / 2, itemView.bounds.size.width - 80, 20)];
        titleLabel.text = title;
        titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        titleLabel.textColor = [UIColor blackColor];
        [itemView addSubview:titleLabel];
    }
    
    // 添加右侧箭头图标
    if (accessoryType == 1) { // 箭头
        UIImageView *arrowView = [[UIImageView alloc] initWithFrame:CGRectMake(itemView.bounds.size.width - 25, (itemHeight - 14) / 2, 14, 14)];
        if (@available(iOS 13.0, *)) {
            arrowView.image = [UIImage systemImageNamed:@"chevron.right"];
            arrowView.tintColor = [UIColor lightGrayColor];
        }
        [itemView addSubview:arrowView];
    }
    
    return itemView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < _sections.count) {
        return _sections[section].count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TSSettingCell";
    static NSString *GroupCellIdentifier = @"TSGroupCell";
    
    if (indexPath.section < _sections.count && indexPath.row < _sections[indexPath.section].count) {
        TSSettingItem *item = _sections[indexPath.section][indexPath.row];
        
        // 组标题使用不同的单元格
        if (item.type == TSSettingItemTypeGroup) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GroupCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GroupCellIdentifier];
            }
            
            // 设置组标题样式
            cell.textLabel.text = item.title;
            cell.textLabel.textColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.35 alpha:1.0];
            cell.textLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
            cell.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            return cell;
        }
        
        // 常规设置项
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        // 清除现有内容
        for (UIView *view in cell.contentView.subviews) {
            [view removeFromSuperview];
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
        cell.imageView.image = nil;
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // 确定行高
        CGFloat rowHeight = (item.subtitle && item.subtitle.length > 0) ? 60 : 50;
        
        // 创建卡片视图，并调整高度以匹配行高
        UIView *cardView = [self createCardViewWithColor:[UIColor whiteColor] cornerRadius:12.0];
        cardView.frame = CGRectMake(15, 5, tableView.bounds.size.width - 30, rowHeight - 10);
        [cell.contentView addSubview:cardView];
        
        // 获取图标
        UIImage *icon = item.icon;
        if (!icon) {
            icon = [self getIconForIdentifier:item.identifier];
        }
        
        NSInteger accessoryType = 0;
        
        switch (item.type) {
            case TSSettingItemTypeLink:
            case TSSettingItemTypeSelection:
                accessoryType = 1; // 箭头
                break;
                
            case TSSettingItemTypeButton:
                accessoryType = 0; // 无附件
                break;
                
            case TSSettingItemTypeSwitch: {
                UISwitch *switchView = [[UISwitch alloc] init];
                
                // 获取当前值
                id value = [self preferenceValueForKey:item.key];
                if (!value) {
                    value = item.defaultValue;
                }
                
                [switchView setOn:[value boolValue] animated:NO];
                
                // 设置动作
                [switchView addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
                objc_setAssociatedObject(switchView, @"settingItem", item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                
                // 开关颜色
                switchView.onTintColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:1.0];
                
                // 容器
                UIView *switchContainer = [[UIView alloc] initWithFrame:CGRectMake(cardView.frame.size.width - 60, 0, 60, cardView.frame.size.height)];
                switchView.center = CGPointMake(switchContainer.frame.size.width / 2, switchContainer.frame.size.height / 2);
                [switchContainer addSubview:switchView];
                [cardView addSubview:switchContainer];
                break;
            }
            
            case TSSettingItemTypeSegment: {
                // 创建分段控制器
                UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:@[]];
                
                // 获取当前值
                id currentValue = [self preferenceValueForKey:item.key];
                if (!currentValue) {
                    currentValue = item.defaultValue;
                }
                
                // 添加选项并设置当前选中项
                NSInteger selectedIndex = 0;
                for (NSInteger i = 0; i < item.values.count; i++) {
                    id value = item.values[i];
                    NSString *title = [item.titleDictionary objectForKey:value];
                    [segmentControl insertSegmentWithTitle:title atIndex:i animated:NO];
                    
                    if ([currentValue isEqual:value]) {
                        selectedIndex = i;
                    }
                }
                
                // 设置当前选中项
                segmentControl.selectedSegmentIndex = selectedIndex;
                
                // 设置颜色和样式
                segmentControl.tintColor = [UIColor colorWithRed:0.24 green:0.43 blue:0.82 alpha:1.0];
                
                // 设置大小和位置
                segmentControl.frame = CGRectMake(cardView.frame.size.width - 150, 0, 140, 30);
                segmentControl.center = CGPointMake(segmentControl.center.x, cardView.frame.size.height / 2);
                
                // 设置动作
                [segmentControl addTarget:self action:@selector(segmentValueChanged:) forControlEvents:UIControlEventValueChanged];
                objc_setAssociatedObject(segmentControl, @"settingItem", item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                
                [cardView addSubview:segmentControl];
                break;
            }
                
            default:
                break;
        }
        
        // 创建并添加设置项视图
        UIView *settingsItem = [self createSettingsItemWithIcon:icon title:item.title subtitle:item.subtitle accessoryType:accessoryType];
        settingsItem.frame = cardView.bounds;
        [cardView addSubview:settingsItem];
        
        return cell;
    }
    
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < _sections.count && indexPath.row < _sections[indexPath.section].count) {
        TSSettingItem *item = _sections[indexPath.section][indexPath.row];
        
        // 获取单元格和卡片视图
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIView *cardView = nil;
        for (UIView *view in cell.contentView.subviews) {
            if (view.layer.cornerRadius > 0) {
                cardView = view;
                break;
            }
        }
        
        // 添加点击动画效果
        [UIView animateWithDuration:0.15 animations:^{
            cardView.alpha = 0.8;
            cardView.transform = CGAffineTransformMakeScale(0.97, 0.97);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15 animations:^{
                cardView.alpha = 1.0;
                cardView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                // 动画完成后处理点击事件
                [self handleItemSelection:item];
            }];
        }];
    }
}

// 新增方法：处理设置项的选择
- (void)handleItemSelection:(TSSettingItem *)item {
    switch (item.type) {
        case TSSettingItemTypeButton:
            if (item.target && item.action && [item.target respondsToSelector:item.action]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [item.target performSelector:item.action];
                #pragma clang diagnostic pop
            }
            break;
            
        case TSSettingItemTypeLink:
            if (item.detailControllerClass) {
                UIViewController *detailVC = [[item.detailControllerClass alloc] init];
                detailVC.title = item.title;
                [self.navigationController pushViewController:detailVC animated:YES];
            }
            break;
            
        case TSSettingItemTypeSegment:
        case TSSettingItemTypeSelection: {
            // 处理选择列表 - 创建选择器列表
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:item.title
                                                                                   message:nil
                                                                            preferredStyle:UIAlertControllerStyleActionSheet];
            
            // 获取当前值
            id currentValue = [self preferenceValueForKey:item.key];
            if (!currentValue) {
                currentValue = item.defaultValue;
            }
            
            // 为每个可能的值创建一个动作
            for (id value in item.values) {
                NSString *title = [item.titleDictionary objectForKey:value];
                if (!title) {
                    title = [value description];
                }
                
                // 如果是当前选中值，添加勾号
                if ([currentValue isEqual:value]) {
                    title = [NSString stringWithFormat:@"✓ %@", title];
                }
                
                UIAlertAction *action = [UIAlertAction actionWithTitle:title
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                    // 保存新值
                    [self setPreferenceValue:value forKey:item.key];
                    
                    // 刷新表格
                    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
                    if (indexPath) {
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    }
                    
                    // 通知值已更改
                    [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@Changed", item.key] object:nil];
                    
                    // 调用观察者方法
                    if ([self respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
                        NSDictionary *change = @{NSKeyValueChangeNewKey: value};
                        [self observeValueForKeyPath:item.key ofObject:self change:change context:NULL];
                    }
                }];
                
                [alertController addAction:action];
            }
            
            // 添加取消操作
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [alertController addAction:cancelAction];
            
            // 在iPad上，设置弹出位置
            if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
                alertController.popoverPresentationController.sourceView = cell;
                alertController.popoverPresentationController.sourceRect = cell.bounds;
            }
            
            [self presentViewController:alertController animated:YES completion:nil];
            break;
        }
            
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < _sections.count && indexPath.row < _sections[indexPath.section].count) {
        TSSettingItem *item = _sections[indexPath.section][indexPath.row];
        
        if (item.type == TSSettingItemTypeGroup) {
            return 30; // 组标题高度
        }
        
        // 根据是否有副标题来动态调整高度
        if (item.subtitle && item.subtitle.length > 0) {
            return 60; // 增加高度以容纳副标题
        }
        
        return 50; // 无副标题的设置项高度
    }
    
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 10;
    }
    return 25;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section < _sections.count && _sections[section].count > 0) {
        // 假设每个分组的第一个项目是组标题
        TSSettingItem *groupItem = _sections[section][0];
        if (groupItem.type == TSSettingItemTypeGroup) {
            return groupItem.footerText;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.45 alpha:1.0];
        header.textLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        header.backgroundView = nil;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
        footer.textLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.55 alpha:1.0];
        footer.textLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        footer.backgroundView = nil;
    }
}

#pragma mark - 控件事件处理

- (void)switchValueChanged:(UISwitch *)sender {
    TSSettingItem *item = objc_getAssociatedObject(sender, @"settingItem");
    if (item && item.key) {
        // 保存值到用户默认设置
        [self setPreferenceValue:@(sender.isOn) forKey:item.key];
        
        // 发送通知，使其他组件知道设置已更改
        [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@Changed", item.key] object:nil];
        
        // 如果设置了观察者，则调用相应的键值观察方法
        if ([self respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
            NSDictionary *change = @{
                NSKeyValueChangeNewKey: @(sender.isOn),
                NSKeyValueChangeOldKey: @(!sender.isOn)
            };
            [self observeValueForKeyPath:item.key ofObject:self change:change context:NULL];
        }
    }
}

- (void)segmentValueChanged:(UISegmentedControl *)sender {
    TSSettingItem *item = objc_getAssociatedObject(sender, @"settingItem");
    if (item && item.key) {
        // 获取当前值
        id currentValue = [self preferenceValueForKey:item.key];
        if (!currentValue) {
            currentValue = item.defaultValue;
        }
        
        // 获取新值
        id newValue = item.values[sender.selectedSegmentIndex];
        
        // 保存新值
        [self setPreferenceValue:newValue forKey:item.key];
        
        // 刷新表格
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
        
        // 通知值已更改
        [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@Changed", item.key] object:nil];
        
        // 调用观察者方法
        if ([self respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
            NSDictionary *change = @{NSKeyValueChangeNewKey: newValue};
            [self observeValueForKeyPath:item.key ofObject:self change:change context:NULL];
        }
    }
}

- (void)dealloc {
    // 移除观察者
    for (NSArray<TSSettingItem *> *section in _sections) {
        for (TSSettingItem *item in section) {
            if (item.key && (item.type == TSSettingItemTypeSwitch || item.type == TSSettingItemTypeSelection)) {
                // 移除键值观察
                [self removeObserver:self forKeyPath:item.key];
            }
        }
    }
}

@end 