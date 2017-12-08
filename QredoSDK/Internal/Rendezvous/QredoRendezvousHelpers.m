/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoRendezvousHelpers.h"
#import "QredoRendezvousAnonymousHelper.h"
#import "QredoLoggerPrivate.h"

@implementation QredoRendezvousHelpers

+(id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                fullTag:(NSString *)fullTag
                                                                 crypto:(id<QredoCryptoImpl>)crypto
                                                         signingHandler:(signDataBlock)signingHandler
                                                                  error:(NSError **)error {
    switch (authenticationType){
        case QredoRendezvousAuthenticationTypeAnonymous:
            return [[QredoRendezvousAnonymousCreateHelper alloc] initWithFullTag:fullTag
                                                                          crypto:crypto
                                                                  signingHandler:signingHandler
                                                                           error:(NSError **)error];
    }
    
    return nil;
}


+(id<QredoRendezvousRespondHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                 fullTag:(NSString *)fullTag
                                                                  crypto:(id<QredoCryptoImpl>)crypto
                                                                   error:(NSError **)error {
    switch (authenticationType){
        case QredoRendezvousAuthenticationTypeAnonymous:
            return [[QredoRendezvousAnonymousRespondHelper alloc] initWithFullTag:fullTag
                                                                           crypto:crypto
                                                                            error:error];
    }
    
    return nil;
}


+(NSInteger)saltLengthForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType {
    switch (authenticationType){
        case QredoRendezvousAuthenticationTypeAnonymous:
            return -1; //Salt not used
            
        default:
            NSAssert(true,@"Invalid authenticationg type");
            return 0;
    }
}


@end
