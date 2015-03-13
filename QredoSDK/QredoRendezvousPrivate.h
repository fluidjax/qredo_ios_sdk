/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoRendezvousPrivate_h
#define QredoSDK_QredoRendezvousPrivate_h

#import "QredoRendezvous.h"
#import "QredoClient.h"

@interface QredoRendezvousMetadata () {
    QredoVaultItemDescriptor *_vaultItemDescriptor;
}

@property (readonly) QredoVaultItemDescriptor *vaultItemDescriptor;
@property (readwrite, copy) NSString *tag;

- (instancetype)initWithTag:(NSString*)tag vaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor;

@end

@interface QredoRendezvous (Private)

@property (readwrite) QredoRendezvousConfiguration *configuration;
@property (readwrite) NSString *tag;

- (instancetype)initWithClient:(QredoClient *)client;
- (instancetype)initWithClient:(QredoClient *)client fromLFDescriptor:(QredoRendezvousDescriptor*)descriptor;
- (void)createRendezvousWithTag:(NSString *)tag configuration:(QredoRendezvousConfiguration *)configuration signingHandler:(signDataBlock)signingHandler completionHandler:(void(^)(NSError *error))completionHandler;

@end

#endif
