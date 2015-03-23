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
@property (readwrite) QredoRendezvousAuthenticationType authenticationType;
@property (readwrite, copy) NSString *tag;

- (instancetype)initWithTag:(NSString*)tag
         authenticationType:(QredoRendezvousAuthenticationType)authenticationType
        vaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor;

@end

@interface QredoRendezvous (Private)

@property (readwrite) QredoRendezvousConfiguration *configuration;
@property (readwrite) NSString *tag;
// TODO: DH - confirm still need authenticationType property on Rendezvous once refactoring complete
@property (readwrite) QredoRendezvousAuthenticationType authenticationType;

- (instancetype)initWithClient:(QredoClient *)client;
- (instancetype)initWithClient:(QredoClient *)client fromLFDescriptor:(QLFRendezvousDescriptor*)descriptor;
- (void)createRendezvousWithTag:(NSString *)tag
             authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                  configuration:(QredoRendezvousConfiguration *)configuration
                 signingHandler:(signDataBlock)signingHandler
              completionHandler:(void(^)(NSError *error))completionHandler;

@end

#endif
