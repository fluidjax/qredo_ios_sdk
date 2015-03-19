/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QLFOwnershipSignature+FactoryMethods.h"
#import "QredoED25519SigningKey.h"
#import "CryptoImplV1.h"
#import "NSData+QredoRandomData.h"
#import "QredoSigner.h"


@implementation QLFOwnershipSignature (FactoryMethods)

+ (int64_t)timestamp {
    return [[NSDate date] timeIntervalSince1970] * 1000LL;
}



+ (instancetype)ownershipSignatureWithSigner:(id<QredoSigner>)signer
                               operationType:(QLFOperationType *)operationType
                              marshalledData:(NSData *)marshalledData
                                       error:(NSError **)error
{
    return [self ownershipSignatureWithSigner:signer
                                operationType:operationType
                               marshalledData:marshalledData
                                        nonce:[NSData dataWithRandomBytesOfLength:16]
                                    timestamp:[self timestamp]
                                        error:error];
}


+ (instancetype)ownershipSignatureWithSigner:(id<QredoSigner>)signer
                               operationType:(QLFOperationType *)operationType
                                        data:(id<QredoMarshallable>)data
                                       error:(NSError **)error
{
    return [self ownershipSignatureWithSigner:signer
                                operationType:operationType
                                         data:data
                                        nonce:[NSData dataWithRandomBytesOfLength:16]
                                    timestamp:[self timestamp]
                                        error:error];
}


+ (instancetype)ownershipSignatureWithSigner:(id<QredoSigner>)signer
                               operationType:(QLFOperationType *)operationType
                                        data:(id<QredoMarshallable>)data
                                       nonce:(QLFNonce *)nonce
                                   timestamp:(QLFTimestamp)timestamp
                                       error:(NSError **)error
{
    NSAssert2(data, @"Data must be provided in [%@ %@].", NSStringFromClass(self), NSStringFromSelector(_cmd));

    NSData *marshalledData = [QredoPrimitiveMarshallers marshalObject:data
                                                           marshaller:[[data class] marshaller]
                                                        includeHeader:NO];
    return [self ownershipSignatureWithSigner:signer
                                operationType:operationType
                               marshalledData:marshalledData
                                        nonce:nonce
                                    timestamp:timestamp
                                        error:error];
}

+ (instancetype)ownershipSignatureWithSigner:(id<QredoSigner>)signer
                               operationType:(QLFOperationType *)operationType
                              marshalledData:(NSData *)marshalledData
                                       nonce:(QLFNonce *)nonce
                                   timestamp:(QLFTimestamp)timestamp
                                       error:(NSError **)error
{
    NSAssert2(signer, @"The signer be provided in [%@ %@].", NSStringFromClass(self), NSStringFromSelector(_cmd));

    NSData *marshalledOperationType = [QredoPrimitiveMarshallers marshalObject:operationType
                                                                    marshaller:[[operationType class] marshaller]
                                                                 includeHeader:NO];
    NSData *marshalledNonce = [QredoPrimitiveMarshallers marshalObject:nonce
                                                            marshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]
                                                         includeHeader:NO];
    NSData *marshalledTimestamp = [QredoPrimitiveMarshallers marshalObject:@(timestamp)
                                                                marshaller:[QredoPrimitiveMarshallers int64Marshaller]
                                                             includeHeader:NO];

    NSData *signature =  [self signatureWithSigner:signer
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

+ (NSData *)signatureWithSigner:(id<QredoSigner>)signer
        marshalledOperationType:(NSData *)marshalledOperationType
                 marshalledData:(NSData *)marshalledData
                marshalledNonce:(NSData *)marshalledNonce
            marshalledTimestamp:(NSData *)marshalledTimestamp
                          error:(NSError **)error
{

    NSMutableData *dataBuffer = [[NSMutableData alloc] init];
    [dataBuffer appendData:marshalledOperationType];
    if (marshalledData) {
        [dataBuffer appendData:marshalledData];
    }
    [dataBuffer appendData:marshalledNonce];
    [dataBuffer appendData:marshalledTimestamp];

    NSData *signature = [signer signData:dataBuffer error:error];
    
    return signature;
}


@end
