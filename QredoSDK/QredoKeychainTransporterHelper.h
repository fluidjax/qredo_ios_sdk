/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoConversation.h"
#import "QredoDeviceInfo.h"

@interface QredoKeychainTransporterHelper : NSObject

+ (NSString *)fingerprintWithConversation:(QredoConversation *)conversation;
+ (QredoDeviceInfo*)parseDeviceInfoFromMessage:(QredoConversationMessage *)message error:(NSError**)error;
+ (QredoDeviceInfo*)deviceInfo;
+ (QredoConversationMessage *)deviceInfoMessage;
@end
