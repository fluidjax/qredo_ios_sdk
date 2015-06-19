/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoQUID.h"

typedef int32_t QredoAccessLevel; // for now just an integer, but probably needs enum values


typedef NS_ENUM(NSUInteger, QredoRendezvousAuthenticationType) {
    QredoRendezvousAuthenticationTypeAnonymous = 0,                         // The tag is just a string, has no cryptographic identity
    QredoRendezvousAuthenticationTypeX509Pem,
    QredoRendezvousAuthenticationTypeX509PemSelfsigned,
    QredoRendezvousAuthenticationTypeEd25519,
    QredoRendezvousAuthenticationTypeRsa2048Pem,
    QredoRendezvousAuthenticationTypeRsa4096Pem
};

typedef NSData * (^signDataBlock)(NSData *data, QredoRendezvousAuthenticationType authenticationType);


@interface QredoObjectRef : NSObject

- (instancetype)initWithData:(NSData *)data;
@property (readonly) NSData *data;

@end

