/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import <Foundation/Foundation.h>
#import "QredoClient.h"
#import "QredoTypes.h"
#import "QredoRendezvousHelper.h"
#import "QredoKeyRef.h"

@protocol QredoRendezvousHelper;

@interface QredoRendezvousCrypto :NSObject

+(QredoRendezvousCrypto *)instance;

-(QLFAuthenticationCode *)authenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                     authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef
                                   encryptedResponderData:(NSData *)encryptedResponderData;


-(QLFAuthenticationCode *)responderAuthenticationCodeWithHashedTag:(QLFRendezvousHashedTag *)hashedTag
                                              authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef
                                             responderPublicKeyRef:(QredoKeyRef *)responderPublicKeyRef;



-(NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                  encryptionKeyRef:(QredoKeyRef *)encryptionKeyRef;

-(NSData *)encryptResponderInfo:(QLFRendezvousResponderInfo *)responderInfo
                  encryptionKeyRef:(QredoKeyRef *)encryptionKeyRef
                             iv:(NSData *)iv;

-(QLFRendezvousResponderInfo *)decryptResponderInfoWithData:(NSData *)encryptedResponderData
                                           encryptionKeyRef:(QredoKeyRef *)encryptionKeyRef
                                                      error:(NSError **)error;

-(BOOL)validateEncryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo
                 authenticationKeyRef:(QredoKeyRef *)authenticationKeyRef
                                  tag:(NSString *)tag
                            hashedTag:(QLFRendezvousHashedTag *)hashedTag
                                error:(NSError **)error;

-(id<QredoRendezvousCreateHelper>)rendezvousHelperForAuthenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                                                fullTag:(NSString *)fullTag
                                                         signingHandler:(signDataBlock)signingHandler
                                                                  error:(NSError **)error;

-(QredoKeyRef *)masterKeyRefWithTag:(NSString *)tag appId:(NSString *)appId;

-(QLFRendezvousHashedTag *)hashedTagWithMasterKeyRef:(QredoKeyRef *)masterKey;
-(QredoKeyRef *)encryptionKeyRefWithMasterKeyRef:(QredoKeyRef *)masterKey;
-(QredoKeyRef *)authenticationKeyRefWithMasterKeyRef:(QredoKeyRef *)masterKey;


@end
