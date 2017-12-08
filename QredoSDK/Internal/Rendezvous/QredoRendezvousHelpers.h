/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>
#import "QredoRendezvousHelper.h"
#import "QredoCryptoImpl.h"

@interface QredoRendezvousHelpers :NSObject

+(id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                fullTag:(NSString *)fullTag
                                                                 crypto:(id<QredoCryptoImpl>)crypto
                                                         signingHandler:(signDataBlock)signingHandler
                                                                  error:(NSError **)error;

+(id<QredoRendezvousRespondHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                 fullTag:(NSString *)fullTag
                                                                  crypto:(id<QredoCryptoImpl>)crypto
                                                                   error:(NSError **)error;

+(NSInteger)saltLengthForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType;

@end
