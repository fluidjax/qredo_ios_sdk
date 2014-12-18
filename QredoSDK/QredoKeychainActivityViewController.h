/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <UIKit/UIKit.h>

@interface QredoKeychainActivityViewController : UIViewController

@property (nonatomic, copy) NSString *activityTitle;
@property (nonatomic, copy) NSString *line1;
@property (nonatomic, copy) NSString *line2;
@property (nonatomic) BOOL spinning;

@end
