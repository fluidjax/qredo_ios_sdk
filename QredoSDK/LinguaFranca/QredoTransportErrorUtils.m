/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoTransportErrorUtils.h"

@implementation QredoTransportErrorUtils

+(NSString *)descriptionForErrorCode:(QredoTransportError)code {
    NSString *description = nil;
    
    switch (code){
        case QredoTransportErrorConnectionClosed:
            description = @"Connection with server closed.";
            break;
            
        case QredoTransportErrorConnectionRefused:
            description = @"Connection refused.";
            break;
            
        case QredoTransportErrorConnectionFailed:
            description = @"Connection error.";
            break;
            
        case QredoTransportErrorCannotParseProtocol:
            description = @"Protocol error detected.";
            break;
            
        case QredoTransportErrorUnknown:
            description = @"Unknown comms error.";
            break;
            
        case QredoTransportErrorUnhandledTopic:
            description = @"Received message on an unhandled topic.";
            break;
            
        case QredoTransportErrorSendWhilstNotReady:
            description = @"Tried to send whilst not transport is not connected and ready.";
            break;
            
        case QredoTransportErrorSendAfterTransportClosed:
            NSLog(@"************************Tried to send after the transport has been closed");
            description = @"Tried to send after the transport has been closed.";
            break;
            
        case QredoTransportErrorReceivedDataAfterTransportClosed:
            description = @"Received data after the transport has been closed.";
            break;
            
        case QredoTransportErrorMultiResponseNotSupported:
            description = @"Transport does not support multi-response.";
            break;
            
        default:
            description = [NSString stringWithFormat:@"QredoErrorCode %d is not recognised.",(int)code];
            break;
    }
    
    return description;
}


+(NSError *)errorWithErrorCode:(QredoTransportError)code {
    NSString *description = [self descriptionForErrorCode:code];
    
    return [self errorWithErrorCode:code description:description];
}


+(NSError *)errorWithErrorCode:(QredoTransportError)code description:(NSString *)description {
    NSError *error = [NSError errorWithDomain:QredoTransportErrorDomain code:code userInfo:@{ NSLocalizedDescriptionKey:description }];
    
    return error;
}


@end
