/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoMainViewController.h"
#import "QredoSettingsViewController.h"
#import "QredoManagerAppRootViewController.h"
#import "QredoKeychainSenderQR.h"
#import "UIColor+Qredo.h"
#import "QredoPrivate.h"


static NSString *QredoMainViewControllerDeviceCellIdentifier = @"QredoMainViewControllerDeviceCell";

@interface QredoMainViewControllerDeviceCell : UITableViewCell
@end
@implementation QredoMainViewControllerDeviceCell

- (instancetype)init {
    
    self = [super
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:QredoMainViewControllerDeviceCellIdentifier];
    
    if (self) {
    }
    
    return self;
    
}

@end


@interface QredoMainViewController ()
@property (nonatomic, copy) NSArray *deviceList;
@property (nonatomic) QredoClient *qredoClient;
@end

@implementation QredoMainViewController


- (instancetype)init {
    return [self initWithStyle:UITableViewStyleGrouped];
}


#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Qredo", @"");
    
    self.view.backgroundColor = [UIColor qredoPrimaryBackgroundColor];
    self.view.tintColor = [UIColor qredoPrimaryTintColor];
    
    UIBarButtonItem *doneButton
    = [[UIBarButtonItem alloc]
       initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleDone
       target:self action:@selector(doneButtonPressed)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    
    UIBarButtonItem *addDeviceButton
    = [[UIBarButtonItem alloc]
       initWithTitle:NSLocalizedString(@"Add device", @"") style:UIBarButtonItemStylePlain
       target:self action:@selector(addDeviceButtonPressed)];
    
    UIBarButtonItem *flexibleSpace
    = [[UIBarButtonItem alloc]
       initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
       target:nil action:nil];
    
    UIBarButtonItem *settingsButton
    = [[UIBarButtonItem alloc]
       initWithTitle:NSLocalizedString(@"Settings", @"") style:UIBarButtonItemStylePlain
       target:self action:@selector(settingsButtonPressed)];
    
    self.toolbarItems = @[addDeviceButton, flexibleSpace, settingsButton];
    
    [self.tableView
     registerClass:[QredoMainViewControllerDeviceCell class]
     forCellReuseIdentifier:QredoMainViewControllerDeviceCellIdentifier];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl
     addTarget:self action:@selector(reloadDeviceList)
     forControlEvents:UIControlEventValueChanged];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO];
    
    [QredoClient
     authorizeWithConversationTypes:nil
     vaultDataTypes:@[QredoVaultItemTypeKeychain]
     completionHandler:^(QredoClient *client, NSError *error) {
         self.qredoClient = client;
     }];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.qredoClient = nil;
}


#pragma mark Table data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.deviceList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    QredoMainViewControllerDeviceCell *cell
    = [tableView
       dequeueReusableCellWithIdentifier:QredoMainViewControllerDeviceCellIdentifier
       forIndexPath:indexPath];
    
    NSString *deviceName = self.deviceList[indexPath.row];
    cell.textLabel.text = deviceName;
    
    return cell;
    
}


#pragma mark Misc methods

- (void)reloadDeviceList {
    
    if (!self.qredoClient) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl beginRefreshing];
    });
    
    NSMutableArray *deviceList = [NSMutableArray array];
    [self.qredoClient.defaultVault
     enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stop) {
         
         if ([vaultItemMetadata.dataType isEqualToString:QredoVaultItemTypeKeychain]) {
             NSString *deviceName = vaultItemMetadata.summaryValues[QredoVaultItemSummaryKeyDeviceName];
             [deviceList addObject:deviceName];
         }
         
     } completionHandler:^(NSError *error) {
         
         self.deviceList = deviceList;
         
         dispatch_async(dispatch_get_main_queue(), ^{
             [self.tableView reloadData];
             [self.refreshControl endRefreshing];
         });
         
     }];
    
}


#pragma mark Callbacks

- (void)doneButtonPressed {
    UIViewController *presentingViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        if ([presentingViewController respondsToSelector:@selector(close)]) {
            [presentingViewController performSelector:@selector(close)];
        }
    }];
}

- (void)addDeviceButtonPressed {
    
    UIViewController *presentingViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        
        QredoKeychainSenderQR *keychainQRSender = [[QredoKeychainSenderQR alloc] initWithDismissHandler:^{
            if ([presentingViewController respondsToSelector:@selector(presentDefaultViewController)]) {
                [presentingViewController performSelector:@selector(presentDefaultViewController)];
            }
        }];
        
        [presentingViewController
         qredo_presentNavigationViewControllerWithViewController:keychainQRSender
         animated:YES
         completion:nil];
        
    }];
    
}

- (void)settingsButtonPressed {
    
    UIViewController *presentingViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        
        QredoSettingsViewController *qredoSettingsViewController = [[QredoSettingsViewController alloc] init];
        
        [presentingViewController
         qredo_presentNavigationViewControllerWithViewController:qredoSettingsViewController
         animated:YES completion:nil];
        
    }];
    
}


#pragma mark Setters and getters

- (void)setQredoClient:(QredoClient *)qredoClient {
    if (_qredoClient == qredoClient) return;
    _qredoClient = qredoClient;
    [self reloadDeviceList];
}


@end


