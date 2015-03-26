/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "QredoRendezvousHelper.h"
#import "CryptoImpl.h"

@interface QredoRendezvousHelpers : NSObject

+ (id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                 fullTag:(NSString *)fullTag
                                                                  crypto:(id<CryptoImpl>)crypto
                                                         trustedRootRefs:(NSArray *)trustedRootRefs
                                                          signingHandler:(signDataBlock)signingHandler
                                                                   error:(NSError **)error;

+ (id<QredoRendezvousRespondHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                  fullTag:(NSString *)fullTag
                                                                   crypto:(id<CryptoImpl>)crypto
                                                          trustedRootRefs:(NSArray *)trustedRootRefs
                                                                    error:(NSError **)error;

+ (NSInteger)saltLengthForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType;

@end


