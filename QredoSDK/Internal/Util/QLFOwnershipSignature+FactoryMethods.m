/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QLFOwnershipSignature+FactoryMethods.h"
#import "QredoED25519SigningKey.h"
#import "CryptoImplV1.h"



@implementation QLFOwnershipSignature (FactoryMethods)

+ (instancetype)ownershipSignatureWithKey:(QredoED25519SigningKey *)key
                            operationType:(QLFOperationType *)operationType
                                     data:(id<QredoMarshallable>)data
                                    nonce:(QLFNonce *)nonce
                                timestamp:(QLFTimestamp)timestamp
                                    error:(NSError **)error
{
    NSAssert2(data, @"Data must be provided in [%@ %@].", NSStringFromClass(self), NSStringFromSelector(_cmd));
    
    NSData *marshalledData = [QredoPrimitiveMarshallers marshalObject:data marshaller:[[data class] marshaller]];
    return [self ownershipSignatureWithKey:key
                             operationType:operationType
                            marshalledData:marshalledData
                                     nonce:nonce
                                 timestamp:timestamp
                                     error:error];
}

+ (instancetype)ownershipSignatureWithKey:(QredoED25519SigningKey *)key
                            operationType:(QLFOperationType *)operationType
                           marshalledData:(NSData *)marshalledData
                                    nonce:(QLFNonce *)nonce
                                timestamp:(QLFTimestamp)timestamp
                                    error:(NSError **)error
{
    NSAssert2(key, @"The signing key must be provided in [%@ %@].", NSStringFromClass(self), NSStringFromSelector(_cmd));
    
    NSData *marshalledOperationType = [QredoPrimitiveMarshallers marshalObject:operationType
                                                                    marshaller:[[operationType class] marshaller]];
    NSData *marshalledNonce = [QredoPrimitiveMarshallers marshalObject:nonce
                                                            marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]];
    NSData *marshalledTimestamp = [QredoPrimitiveMarshallers marshalObject:@(timestamp)
                                                                marshaller:[QredoPrimitiveMarshallers int64Marshaller]];
    
    NSData *signature =  [self signatureWithKey:key
                        marshalledOperationType:marshalledOperationType
                                 marshalledData:marshalledData
                                marshalledNonce:marshalledNonce
                            marshalledTimestamp:marshalledTimestamp
                                          error:error];
    
    if (!signature) {
        return nil;
    }
    
    return [self ownershipSignatureWithOp:operationType nonce:nonce timestamp:timestamp signature:signature];
}

+ (NSData *)signatureWithKey:(QredoED25519SigningKey *)key
     marshalledOperationType:(NSData *)marshalledOperationType
              marshalledData:(NSData *)marshalledData
             marshalledNonce:(NSData *)marshalledNonce
         marshalledTimestamp:(NSData *)marshalledTimestamp
                       error:(NSError **)error
{
    
    NSMutableData *dataBuffer = [[NSMutableData alloc] init];
    [dataBuffer appendData:marshalledOperationType];
    [dataBuffer appendData:marshalledData];
    [dataBuffer appendData:marshalledNonce];
    [dataBuffer appendData:marshalledTimestamp];
    
    NSData *signature = [[CryptoImplV1 sharedInstance] qredoED25519SignMessage:dataBuffer withKey:key error:error];
    
    return signature;
}


@end
