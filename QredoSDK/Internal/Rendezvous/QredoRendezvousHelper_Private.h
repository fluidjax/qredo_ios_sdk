/* HEADER GOES HERE */
#import "QredoRendezvousHelper.h"
#import "QredoPrivate.h"
#import "CryptoImpl.h"

@protocol QredoRendezvousCreatePrivateHelper <QredoRendezvousCreateHelper>
-(instancetype)initWithFullTag:(NSString *)fullTag
                        crypto:(id<CryptoImpl>)crypto
                signingHandler:(signDataBlock)signingHandler
                         error:(NSError **)error;
@end

@protocol QredoRendezvousRespondPrivateHelper <QredoRendezvousRespondHelper>
-(instancetype)initWithFullTag:(NSString *)fullTag
                        crypto:(id<CryptoImpl>)crypto
                         error:(NSError **)error;
@end


@interface QredoAbstractRendezvousHelper :NSObject
@property (nonatomic,readonly) id<CryptoImpl> cryptoImpl;
-(instancetype)initWithCrypto:(id<CryptoImpl>)crypto;
@end


void updateErrorWithQredoRendezvousHelperError(NSError                    **error,
                                               QredoRendezvousHelperError errorCode,
                                               NSDictionary               *userInfo);
