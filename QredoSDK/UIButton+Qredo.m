/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "UIButton+Qredo.h"
#import "UIColor+Qredo.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIButton (Qredo)
+ (instancetype)qredoButton {
    UIButton *newButton = [UIButton buttonWithType:UIButtonTypeCustom];
    newButton.backgroundColor = [UIColor qredoPrimaryTintColor];
    newButton.layer.cornerRadius = 5.0;
    newButton.clipsToBounds = YES;
    return newButton;
}
@end
