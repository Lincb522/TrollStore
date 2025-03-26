#import <UIKit/UIKit.h>
#import "TSAppInfo.h"
#import <CoreServices.h>

@class TSAppInfo;
@class TSRootViewController;

@interface TSAppTableViewController : UITableViewController <UISearchControllerDelegate, UISearchResultsUpdating, UIDocumentPickerDelegate, LSApplicationWorkspaceObserverProtocol>
{
    UIImage* _placeholderIcon;
    NSArray<TSAppInfo*>* _cachedAppInfos;
    NSMutableDictionary* _cachedIcons;
    UISearchController* _searchController;
	NSString* _searchKey;
}

@property (nonatomic, strong) NSArray<TSAppInfo*>* cachedAppInfos;
@property (nonatomic, strong) NSMutableDictionary<NSString*, UIImage*>* cachedIcons;
@property (nonatomic, strong) UIImage* placeholderIcon;
@property (nonatomic, strong) NSString* searchKey;
@property (nonatomic, strong) UISearchController* searchController;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, weak) TSRootViewController *rootController;

- (void)reloadTable;
- (void)showInstallOptions;
- (void)setupAddButton;
- (void)updateAddButtonPosition;

@end