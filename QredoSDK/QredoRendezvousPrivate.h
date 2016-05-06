/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
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




/** This class is used for creating rendezvous and for getting information about rendezvous */
@interface QredoRendezvousConfiguration : NSObject
/** Reverse domain name service notation. For example, `com.qredo.qatchat` */
@property (readwrite, copy) NSString *conversationType;

/** if 0, then conversation doesn't have a time limit */
@property (readwrite) long durationSeconds;
@property (readwrite) BOOL isUnlimitedResponseCount;
@property (readwrite) NSDate *expiresAt;



/** Should be used only for creating a new rendezvous */
//- (instancetype)initWithConversationType:(NSString*)conversationType;
/** Should be used only for creating a new rendezvous */
- (instancetype)initWithConversationType:(NSString*)conversationType
                         durationSeconds:(long)durationSeconds
                isUnlimitedResponseCount:(BOOL)isUnlimitedResponseCount
                               expiresAt:(NSDate*)expiresAt;

- (instancetype)initWithConversationType:(NSString*)conversationType
                         durationSeconds:(long)durationSeconds
                isUnlimitedResponseCount:(BOOL)isUnlimitedResponseCount;


@end



@interface QredoRendezvous (Private)




- (instancetype)initWithClient:(QredoClient *)client;
- (instancetype)initWithClient:(QredoClient *)client fromLFDescriptor:(QLFRendezvousDescriptor*)descriptor;
- (instancetype)initWithVaultItem:(QredoClient *)client fromVaultItem:(QredoVaultItem*)vaultItem;
- (void)createRendezvousWithTag:(NSString *)tag
             authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                  configuration:(QredoRendezvousConfiguration *)configuration
                trustedRootPems:(NSArray *)trustedRootPems
                        crlPems:(NSArray *)crlPems
                 signingHandler:(signDataBlock)signingHandler
                 appCredentials:(QredoAppCredentials*)appCredentials
              completionHandler:(void(^)(NSError *error))completionHandler;
- (void)activateRendezvous:(long)duration completionHandler:(void (^)(NSError *error))completionHandler;
- (void)updateRendezvousWithDuration:(long)duration expiresAt:(NSSet*)expiresAt completionHandler:(void (^)(NSError *error))completionHandler;
- (void)deactivateRendezvous :(void (^)(NSError *error))completionHandler;




@end

#endif
