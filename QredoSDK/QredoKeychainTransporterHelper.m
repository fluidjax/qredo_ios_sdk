/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoKeychainTransporterHelper.h"
#import "QredoErrorCodes.h"
#import "QredoKeychainTransporterConsts.h"

@implementation QredoKeychainTransporterHelper

+ (NSString *)fingerprintWithConversation:(QredoConversation *)conversation
{
    return [[conversation.metadata.conversationId QUIDString] substringToIndex:5];
}

+ (QredoDeviceInfo*)parseDeviceInfoFromMessage:(QredoConversationMessage *)message error:(NSError**)error
{
    id deviceName = message.summaryValues[QredoKeychainTransporterMessageKeyDeviceName];

    if (!deviceName || ![deviceName isKindOfClass:[NSString class]]) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeUnknown
                                     userInfo:@{NSLocalizedDescriptionKey : @"Invalid device name"}];
        }
        return nil;
    }

    QredoDeviceInfo *info = [[QredoDeviceInfo alloc] init];

    info.name = deviceName;

    return info;
}


+ (QredoDeviceInfo*)deviceInfo
{
    QredoDeviceInfo *info = [[QredoDeviceInfo alloc] init];

    info.name = @"iPhone"; // TODO: put the device name

    return info;
}

+ (QredoConversationMessage *)deviceInfoMessage
{
    return [[QredoConversationMessage alloc] initWithValue:nil
                                                  dataType:QredoKeychainTransporterMessageTypeDeviceInfo
                                             summaryValues:@{QredoKeychainTransporterMessageKeyDeviceName: [self deviceInfo].name}];
}

@end
