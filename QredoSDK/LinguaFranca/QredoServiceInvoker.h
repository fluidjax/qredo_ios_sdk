/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>
#import "QredoTransport.h"
#import "QredoWireFormat.h"

@class QredoCertificate;


extern NSString *const QredoLFErrorDomain;

typedef NS_ENUM (NSInteger,QredoLFError) {
    QredoLFErrorRemoteOperationFailure = 1000
};



@interface QredoServiceInvoker :NSObject <QredoTransportDelegate>

@property QredoTransport *transport;
+(instancetype)serviceInvokerWithServiceURL:(NSURL *)serviceURL appCredentials:(QredoAppCredentials *)appCredentials;

-(instancetype)initWithServiceURL:(NSURL *)serviceURL appCredentials:(QredoAppCredentials *)appCredentials;

-(void)terminate;

//calles the method below with multiResponse:NO
-(void)invokeService:(NSString *)serviceName
           operation:(NSString *)operationName
       requestWriter:(void (^)(QredoWireFormatWriter *writer))requestWriter
      responseReader:(void (^)(QredoWireFormatReader *reader))responseReader
        errorHandler:(void (^)(NSError *error))errorHandler;


-(void)invokeService:(NSString *)serviceName
           operation:(NSString *)operationName
       requestWriter:(void (^)(QredoWireFormatWriter *writer))requestWriter
      responseReader:(void (^)(QredoWireFormatReader *reader))responseReader
        errorHandler:(void (^)(NSError *error))errorHandler
       multiResponse:(BOOL)multiResponse;

-(BOOL)isTerminated;
-(BOOL)supportsMultiResponse;

@end
