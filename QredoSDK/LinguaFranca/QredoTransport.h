/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoClientId.h"

@class QredoCertificate;

extern NSString *const QredoTransportErrorDomain;

//Note: if modifying this list, also modify QredoTransportErrorUtils.m which includes enum to string conversion
typedef NS_ENUM (NSInteger,QredoTransportError) {
    QredoTransportErrorConnectionClosed = 5001,
    QredoTransportErrorConnectionRefused,
    QredoTransportErrorConnectionFailed,
    QredoTransportErrorCannotParseProtocol,
    QredoTransportErrorUnknown,
    QredoTransportErrorUnhandledTopic,
    QredoTransportErrorSendWhilstNotReady,
    QredoTransportErrorSendAfterTransportClosed,
    QredoTransportErrorReceivedDataAfterTransportClosed,
    QredoTransportErrorMultiResponseNotSupported
};

//Note: For HTTP transports, userData within the following blocks and delegates will contain the correlationID of the original outgoing message associated with this response/error.

typedef void (^ReceivedResponseBlock)(NSData *data,id userData);
typedef void (^ReceivedErrorBlock)(NSError *error,id userData);

@protocol QredoTransportDelegate <NSObject>
@required
-(void)didReceiveResponseData:(NSData *)data userData:(id)userData;
-(void)didReceiveError:(NSError *)error userData:(id)userData;
@end

@interface QredoTransport :NSObject {
@protected
    BOOL _transportClosed;
}

@property (readonly,strong) NSURL *serviceURL;
@property (readonly,strong) QredoClientId *clientId;
@property (readonly,assign) BOOL transportClosed;

//Set delegate to 'weak' if using ARC, otherwise assign
@property (weak) id <QredoTransportDelegate> responseDelegate;
@property (readonly,copy) ReceivedResponseBlock receivedResponseBlock;
@property (readonly,copy) ReceivedErrorBlock receivedErrorBlock;

+(instancetype)transportForServiceURL:(NSURL *)serviceURL;
+(BOOL)canHandleServiceURL:(NSURL *)serviceURL;
-(instancetype)initWithServiceURL:(NSURL *)serviceUR;
-(BOOL)supportsMultiResponse;
-(void)send:(NSData *)payload userData:(id)userData;
-(void)close;

-(void)configureReceivedResponseBlock:(ReceivedResponseBlock)block;
-(void)configureReceivedErrorBlock:(ReceivedErrorBlock)block;

//TODO: DH - not happy with these in 'public' header, but needed to allow child classes to access them.
//'Protected' members
-(BOOL)areHandlersConfigured;
-(void)notifyListenerOfResponseData:(NSData *)data userData:(id)userData;
-(void)notifyListenerOfError:(NSError *)error userData:(id)userData;
-(void)notifyListenerOfErrorCode:(QredoTransportError)code userData:(id)userData;
-(NSString *)getHexClientID;
-(int)port;

@end
