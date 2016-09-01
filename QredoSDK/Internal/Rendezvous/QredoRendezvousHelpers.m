/* HEADER GOES HERE */
#import "QredoRendezvousHelpers.h"
#import "QredoRendezvousAnonymousHelper.h"
#import "QredoLoggerPrivate.h"

@implementation QredoRendezvousHelpers

+(id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                fullTag:(NSString *)fullTag
                                                                 crypto:(id<CryptoImpl>)crypto
                                                        trustedRootPems:(NSArray *)trustedRootPems
                                                                crlPems:(NSArray *)crlPems
                                                         signingHandler:(signDataBlock)signingHandler
                                                                  error:(NSError **)error {
    switch (authenticationType){
        case QredoRendezvousAuthenticationTypeAnonymous:
            return [[QredoRendezvousAnonymousCreateHelper alloc] initWithFullTag:fullTag
                                                                          crypto:crypto
                                                                 trustedRootPems:trustedRootPems
                                                                         crlPems:crlPems
                                                                  signingHandler:signingHandler
                                                                           error:(NSError **)error];
    }
    
    return nil;
}

+(id<QredoRendezvousRespondHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                 fullTag:(NSString *)fullTag
                                                                  crypto:(id<CryptoImpl>)crypto
                                                         trustedRootPems:(NSArray *)trustedRootPems
                                                                 crlPems:(NSArray *)crlPems
                                                                   error:(NSError **)error {
    switch (authenticationType){
        case QredoRendezvousAuthenticationTypeAnonymous:
            return [[QredoRendezvousAnonymousRespondHelper alloc] initWithFullTag:fullTag
                                                                           crypto:crypto
                                                                  trustedRootPems:trustedRootPems
                                                                          crlPems:crlPems
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
