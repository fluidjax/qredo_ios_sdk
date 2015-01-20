/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRendezvousHelper.h"


@protocol CryptoImpl;

@protocol QredoRendezvousCreatePrivateHelper <QredoRendezvousCreateHelper>
- (instancetype)initWithPrefix:(NSString *)prefix crypto:(id<CryptoImpl>)crypto error:(NSError **)error;
@end

@protocol QredoRendezvousRespondPrivateHelper <QredoRendezvousRespondHelper>
- (instancetype)initWithFullTag:(NSString *)fullTtag crypto:(id<CryptoImpl>)crypto error:(NSError **)error;
@end


@interface QredoAbstractRendezvousHelper : NSObject
@property (nonatomic, readonly) id<CryptoImpl> cryptoImpl;
- (instancetype)initWithCrypto:(id<CryptoImpl>)crypto;
@end


NSError *qredoRendezvousHelperError(QredoRendezvousHelperError errorCode, NSDictionary *userInfo);

