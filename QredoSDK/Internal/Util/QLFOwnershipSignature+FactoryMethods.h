/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */



#import <Foundation/Foundation.h>
#import "QredoClient.h"


@class QredoED25519SigningKey;

@interface QLFOwnershipSignature (FactoryMethods)

+ (instancetype)ownershipSignatureWithKey:(QredoED25519SigningKey *)key
                            operationType:(QLFOperationType *)operationType
                                     data:(id<QredoMarshallable>)data
                                    nonce:(QLFNonce *)nonce
                                timestamp:(QLFTimestamp)timestamp
                                    error:(NSError **)error;

+ (instancetype)ownershipSignatureWithKey:(QredoED25519SigningKey *)key
                            operationType:(QLFOperationType *)operationType
                           marshalledData:(NSData *)marshalledData
                                    nonce:(QLFNonce *)nonce
                                timestamp:(QLFTimestamp)timestamp
                                    error:(NSError **)error;

@end



