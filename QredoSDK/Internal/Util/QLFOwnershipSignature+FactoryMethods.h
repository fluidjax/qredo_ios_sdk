/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import "QredoClient.h"

@protocol QredoSigner;
@class QredoVaultItemDescriptor;

@interface QLFOwnershipSignature (FactoryMethods)

+(instancetype)ownershipSignatureWithSigner:(id<QredoSigner>)signer
                              operationType:(QLFOperationType *)operationType
                             marshalledData:(NSData *)marshalledData
                                      error:(NSError **)error;

+(instancetype)ownershipSignatureWithSigner:(id<QredoSigner>)signer
                              operationType:(QLFOperationType *)operationType
                                       data:(id<QredoMarshallable>)data
                                      error:(NSError **)error;

+(instancetype)ownershipSignatureForGetVaultItemWithSigner:(id<QredoSigner>)signer
                                       vaultItemDescriptor:(QredoVaultItemDescriptor *)itemDescriptor
                                   vaultItemSequenceValues:(NSSet *)sequenceValues
                                                     error:(NSError **)error;

+(instancetype)ownershipSignatureForListVaultItemsWithSigner:(id<QredoSigner>)signer
                                              sequenceStates:(NSSet *)sequenceStates
                                                       error:(NSError **)error;

@end
