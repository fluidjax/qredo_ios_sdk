/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoSettingsViewController.h"
#import "QredoMainViewController.h"
#import "QredoWelcomeViewController.h"
#import "QredoManagerAppRootViewController.h"


static NSString *const kInfoCellIdentifier = @"kInfoCellIdentifier";
static NSString *const kDestructiveActionCellIdentifier = @"kDestructiveActionCellIdentifier";


@interface QredoSettingsInfoTableViewCell : UITableViewCell
@end
@implementation QredoSettingsInfoTableViewCell
- (instancetype)init {
    return [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kInfoCellIdentifier];
}
@end

@interface QredoSettingsActionTableViewCell : UITableViewCell
@end
@implementation QredoSettingsActionTableViewCell
- (instancetype)init {
    return [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDestructiveActionCellIdentifier];
}
@end

@interface QredoSettingsItem : NSObject
@property (nonatomic, copy) NSString *cellIdentifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) void(^selectionHandler)();
@end
@implementation QredoSettingsItem
+ (instancetype)destructiveActionItemWithName:(NSString *)name selectionHandler:(void(^)())selectionHandler {
    return [self itemWithName:name value:nil cellIdentifier:kDestructiveActionCellIdentifier selectionHandler:selectionHandler];
}
+ (instancetype)infoItemWithName:(NSString *)name value:(NSString *)value {
    return [self itemWithName:name value:value cellIdentifier:kDestructiveActionCellIdentifier selectionHandler:nil];
}
+ (instancetype)itemWithName:(NSString *)name value:(NSString *)value cellIdentifier:(NSString *)cellIdentifier selectionHandler:(void(^)())selectionHandler {
    QredoSettingsItem *item = [[QredoSettingsItem alloc] init];
    item.name = name;
    item.value = value;
    item.cellIdentifier = cellIdentifier;
    item.selectionHandler = selectionHandler;
    return item;
}
@end


@interface QredoSettingsSection : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray *items;
@property (nonatomic, copy) NSString *footerText;
@end
@implementation QredoSettingsSection
+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray *)items footerText:(NSString *)footerText {
    QredoSettingsSection *section = [[QredoSettingsSection alloc] init];
    section.title = title;
    section.items = items;
    section.footerText = footerText;
    return section;
}
@end



@interface QredoSettingsViewController ()
@property (nonatomic, copy) NSArray *sections;
@end

@implementation QredoSettingsViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UIBarButtonItem *doneButton
    = [[UIBarButtonItem alloc]
       initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleDone
       target:self action:@selector(doneButtonPressed)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kInfoCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kDestructiveActionCellIdentifier];

    __weak QredoSettingsViewController *weakSelf = self;
    
    self.sections
    = @[
        [QredoSettingsSection
         sectionWithTitle:NSLocalizedString(@"Device info", @"")
         items:@[
                 [QredoSettingsItem
                  infoItemWithName:NSLocalizedString(@"Name", @"")
                  value:nil
                  ],
                 [QredoSettingsItem
                  infoItemWithName:NSLocalizedString(@"Model", @"")
                  value:nil
                  ],
                 [QredoSettingsItem
                  infoItemWithName:NSLocalizedString(@"iOS Version", @"")
                  value:nil
                  ],
                 [QredoSettingsItem
                  infoItemWithName:NSLocalizedString(@"Device ID", @"")
                  value:nil
                  ],
                 ]
         footerText:nil
         ],
        [QredoSettingsSection
         sectionWithTitle:nil
         items:@[
                 [QredoSettingsItem
                  destructiveActionItemWithName:NSLocalizedString(@"Delete Qredo from this device", @"")
                  selectionHandler:^{
                      [weakSelf deleteQredoButtonPressed];
                  }],
                 ]
         footerText:NSLocalizedString(@"Press this button if you want to remove all data stored with Qredo from this device.", @"")
         ],
        ];

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    QredoSettingsSection *sect = self.sections[section];
    return sect.title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    QredoSettingsSection *sect = self.sections[section];
    return sect.footerText;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    QredoSettingsSection *sect = self.sections[section];
    return [sect.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    QredoSettingsSection *sect = self.sections[indexPath.section];
    QredoSettingsItem *item = sect.items[indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:item.cellIdentifier forIndexPath:indexPath];
    if ([item.cellIdentifier isEqualToString:kInfoCellIdentifier]) {
        cell.textLabel.text = item.name;
        cell.detailTextLabel.text = item.value;
    } else if ([item.cellIdentifier isEqualToString:kDestructiveActionCellIdentifier]) {
        cell.textLabel.text = item.name;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    QredoSettingsSection *sect = self.sections[indexPath.section];
    QredoSettingsItem *item = sect.items[indexPath.row];
    if ([item.cellIdentifier isEqualToString:kInfoCellIdentifier]) {
        return NO;
    } else if ([item.cellIdentifier isEqualToString:kDestructiveActionCellIdentifier]) {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    QredoSettingsSection *sect = self.sections[indexPath.section];
    QredoSettingsItem *item = sect.items[indexPath.row];
    if ([item.cellIdentifier isEqualToString:kDestructiveActionCellIdentifier]) {
        if (item.selectionHandler) item.selectionHandler();
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)deleteQredoButtonPressed {
    UIViewController *presentingViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        QredoWelcomeViewController *welcomeViewController = [[QredoWelcomeViewController alloc] init];
        [presentingViewController qredo_presentNavigationViewControllerWithViewController:welcomeViewController animated:YES completion:nil];
    }];
}

- (void)doneButtonPressed {
    UIViewController *presentingViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        QredoMainViewController *mainViewController = [[QredoMainViewController alloc] init];
        [presentingViewController qredo_presentNavigationViewControllerWithViewController:mainViewController animated:YES completion:nil];
    }];
}

@end
