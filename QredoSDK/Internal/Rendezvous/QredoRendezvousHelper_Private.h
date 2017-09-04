/* HEADER GOES HERE */
#import "QredoRendezvousHelper.h"
#import "QredoPrivate.h"
#import "QredoCryptoImpl.h"

@protocol QredoRendezvousCreatePrivateHelper <QredoRendezvousCreateHelper>
-(instancetype)initWithFullTag:(NSString *)fullTag
                        crypto:(id<QredoCryptoImpl>)crypto
                signingHandler:(signDataBlock)signingHandler
                         error:(NSError **)error;
@end

@protocol QredoRendezvousRespondPrivateHelper <QredoRendezvousRespondHelper>
-(instancetype)initWithFullTag:(NSString *)fullTag
                        crypto:(id<QredoCryptoImpl>)crypto
                         error:(NSError **)error;
@end


@interface QredoAbstractRendezvousHelper :NSObject
@property (nonatomic,readonly) id<QredoCryptoImpl> qredoCryptoImpl;
-(instancetype)initWithCrypto:(id<QredoCryptoImpl>)crypto;
@end


void updateErrorWithQredoRendezvousHelperError(NSError                    **error,
                                               QredoRendezvousHelperError errorCode,
                                               NSDictionary               *userInfo);
