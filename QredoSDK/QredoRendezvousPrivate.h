/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#ifndef QredoSDK_QredoRendezvousPrivate_h
#define QredoSDK_QredoRendezvousPrivate_h

#import "QredoRendezvous.h"
#import "QredoClient.h"
#import "QredoTypesPrivate.h"

@interface QredoRendezvousMetadata ()

@property (readwrite) QredoRendezvousRef *rendezvousRef;
@property (readwrite) QredoRendezvousAuthenticationType authenticationType;
@property (readwrite, copy) NSString *tag;

- (instancetype)initWithTag:(NSString*)tag
         authenticationType:(QredoRendezvousAuthenticationType)authenticationType
              rendezvousRef:(QredoRendezvousRef *)rendezvousRef;

@end


@interface QredoRendezvous (Private)

@property (readwrite) QredoRendezvousConfiguration *configuration;
@property (readwrite) QredoRendezvousMetadata *metadata;
@property (readwrite) NSString *tag;
@property (readwrite) QredoRendezvousAuthenticationType authenticationType;


- (instancetype)initWithClient:(QredoClient *)client;
- (instancetype)initWithClient:(QredoClient *)client fromLFDescriptor:(QLFRendezvousDescriptor*)descriptor;
- (instancetype)initWithVaultItem:(QredoClient *)client fromVaultItem:(QredoVaultItem*)vaultItem;
- (void)createRendezvousWithTag:(NSString *)tag
             authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                  configuration:(QredoRendezvousConfiguration *)configuration
                trustedRootPems:(NSArray *)trustedRootPems
                        crlPems:(NSArray *)crlPems
                 signingHandler:(signDataBlock)signingHandler
              completionHandler:(void(^)(NSError *error))completionHandler;
- (void)activateRendezvous: (NSNumber *)duration completionHandler:(void (^)(NSError *error))completionHandler;
- (void)updateRendezvousWithDuration: (NSNumber *)duration completionHandler:(void (^)(NSError *error))completionHandler;
- (void)deactivateRendezvous :(void (^)(NSError *error))completionHandler;




@end

#endif
