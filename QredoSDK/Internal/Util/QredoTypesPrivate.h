/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

@class QredoVaultItemDescriptor;
@class QredoVault;

@interface QredoObjectRef ()

typedef int32_t QredoAccessLevel; // for now just an integer, but probably needs enum values

typedef NS_ENUM (NSUInteger, QredoRendezvousAuthenticationType) {
    QredoRendezvousAuthenticationTypeAnonymous = 0,                 // The tag is just a string, has no cryptographic identity

};

typedef NSData * (^signDataBlock)(NSData *data, QredoRendezvousAuthenticationType authenticationType);

@property QredoVaultItemDescriptor *vaultItemDescriptor;
@property (readwrite) NSData *data;

- (instancetype)initWithVaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor vault:(QredoVault *)vault;

@end