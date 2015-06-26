/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoSettingsViewController.h"
#import "QredoMainViewController.h"
#import "QredoWelcomeViewController.h"
#import "QredoManagerAppRootViewController.h"
#import "Qredo.h"
#import "QredoPrivate.h"


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
    return [self itemWithName:name value:value cellIdentifier:kInfoCellIdentifier selectionHandler:nil];
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
@property (nonatomic) QredoClient *qredoClient;
@property (nonatomic, copy) NSArray *sections;
@end

@implementation QredoSettingsViewController

- (instancetype)initWithQredoClient:(QredoClient *)qredoClient
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.qredoClient = qredoClient;
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Settings", @"");
    
    UIBarButtonItem *doneButton
    = [[UIBarButtonItem alloc]
       initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleDone
       target:self action:@selector(doneButtonPressed)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    [self.tableView registerClass:[QredoSettingsInfoTableViewCell class] forCellReuseIdentifier:kInfoCellIdentifier];
    [self.tableView registerClass:[QredoSettingsActionTableViewCell class] forCellReuseIdentifier:kDestructiveActionCellIdentifier];

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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([cell.reuseIdentifier isEqualToString:kInfoCellIdentifier]) {
        cell.textLabel.textColor = [UIColor blackColor];
    } else if ([cell.reuseIdentifier isEqualToString:kDestructiveActionCellIdentifier]) {
        cell.textLabel.textColor = [UIColor redColor];
    }
    
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

- (void)deleteQredo {
    UIViewController *presentingViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        NSError *error = nil;
        [self.qredoClient deleteCurrentDataWithError:&error];
        if (!error) {
            
            if ([presentingViewController respondsToSelector:@selector(presentDefaultViewController)]) {
                [presentingViewController performSelector:@selector(presentDefaultViewController)];
            }
            
        } else {
            
            UIAlertController *alertController
            = [UIAlertController
               alertControllerWithTitle:NSLocalizedString(@"Could not delete Qredo", @"")
               message:[error localizedDescription]
               preferredStyle:UIAlertControllerStyleAlert];
            [alertController
             addAction:[UIAlertAction
                        actionWithTitle:NSLocalizedString(@"OK", @"")
                        style:UIAlertActionStyleDefault
                        handler:^(UIAlertAction *action) {
                            if ([presentingViewController respondsToSelector:@selector(presentDefaultViewController)]) {
                                [presentingViewController performSelector:@selector(presentDefaultViewController)];
                            }
                        }]];
            [self presentViewController:alertController animated:YES completion:nil];
            
        }
    }];
}

- (void)deleteQredoButtonPressed {
    UIAlertController *alertController
    = [UIAlertController
       alertControllerWithTitle:NSLocalizedString(@"Delete Qredo?", @"")
       message:nil
       preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction
                                actionWithTitle:NSLocalizedString(@"Delete Qredo", @"")
                                style:UIAlertActionStyleDestructive
                                handler:^(UIAlertAction *action) {
                                    [self deleteQredo];
                                }]];
    [alertController addAction:[UIAlertAction
                                actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                style:UIAlertActionStyleCancel
                                handler:^(UIAlertAction *action) {
                                }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)doneButtonPressed {
    UIViewController *presentingViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        QredoMainViewController *mainViewController = [[QredoMainViewController alloc] init];
        [presentingViewController qredo_presentNavigationViewControllerWithViewController:mainViewController animated:YES completion:nil];
    }];
}

@end
