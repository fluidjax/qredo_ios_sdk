/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */



#import <Foundation/Foundation.h>
#import "QredoClient.h"

@protocol QredoSigner;
@class QredoVaultItemDescriptor;

@interface QLFOwnershipSignature (FactoryMethods)

+ (instancetype)ownershipSignatureWithSigner:(id<QredoSigner>)signer
                            operationType:(QLFOperationType *)operationType
                           marshalledData:(NSData *)marshalledData
                                    error:(NSError **)error;

+ (instancetype)ownershipSignatureWithSigner:(id<QredoSigner>)signer
                            operationType:(QLFOperationType *)operationType
                                     data:(id<QredoMarshallable>)data
                                    error:(NSError **)error;

+ (instancetype)ownershipSignatureWithSigner:(id<QredoSigner>)signer
                            operationType:(QLFOperationType *)operationType
                                     data:(id<QredoMarshallable>)data
                                    nonce:(QLFNonce *)nonce
                                timestamp:(QLFTimestamp)timestamp
                                    error:(NSError **)error;

+ (instancetype)ownershipSignatureWithSigner:(id<QredoSigner>)signer
                            operationType:(QLFOperationType *)operationType
                           marshalledData:(NSData *)marshalledData
                                    nonce:(QLFNonce *)nonce
                                timestamp:(QLFTimestamp)timestamp
                                    error:(NSError **)error;

+ (instancetype)ownershipSignatureWithSigner:(id<QredoSigner>)signer
                               operationType:(QLFOperationType *)operationType
                         vaultItemDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
                     vaultItemSequenceValues:(NSSet *)sequenceValues
                                       error:(NSError **)error;

@end



