/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper.h"
#import "CryptoImpl.h"

@protocol QredoRendezvousCreatePrivateHelper <QredoRendezvousCreateHelper>
- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto signingHandler:(signDataBlock)signingHandler error:(NSError **)error;
@end

@protocol QredoRendezvousRespondPrivateHelper <QredoRendezvousRespondHelper>
- (instancetype)initWithFullTag:(NSString *)fullTag crypto:(id<CryptoImpl>)crypto error:(NSError **)error;
@end


@interface QredoAbstractRendezvousHelper : NSObject
@property (nonatomic, readonly) id<CryptoImpl> cryptoImpl;
- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto;
@end


NSError *qredoRendezvousHelperError(QredoRendezvousHelperError errorCode, NSDictionary *userInfo);

