/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "QredoRendezvousPrivate.h"
#import "QredoConversationPrivate.h"

#import "QredoPrimitiveMarshallers.h"
#import "QredoServiceInvoker.h"
#import "QredoLoggerPrivate.h"

#import "QredoKeychain.h"
#import "QredoKeychainArchiver.h"
#import "NSData+QredoRandomData.h"
#import "NSData+ParseHex.h"

#import "QredoCertificate.h"
#import "QredoUserCredentials.h"
#import "QredoLocalIndexDataStore.h"
#import "QredoConversationProtocol.h"
#import "QredoNetworkTime.h"
#import <UIKit/UIKit.h>
#import "MasterConfig.h"

NSString *const QredoVaultItemTypeKeychain                  = @"com.qredo.keychain.device-name";
NSString *const QredoVaultItemTypeKeychainAttempt           = @"com.qredo.keychain.transfer-attempt";
NSString *const QredoVaultItemSummaryKeyDeviceName          = @"device-name";


NSString *const QredoClientOptionCreateNewSystemVault       = @"com.qredo.option.create.new.system.vault";
NSString *const QredoClientOptionServiceURL                 = @"com.qredo.option.serviceUrl";


static NSString *const QredoClientDefaultServiceURL         = @"https://" QREDO_SERVER_URL  @":443/services";
static NSString *const QredoClientMQTTServiceURL            = @"ssl://"   QREDO_SERVER_URL  @":8883";
static NSString *const QredoClientWebSocketsServiceURL      = @"wss://"   QREDO_SERVER_URL  @":443/services";


NSString *const QredoRendezvousURIProtocol                  = @"qrp:";
static NSString *const QredoKeychainOperatorName            = @"Qredo Mock Operator";
static NSString *const QredoKeychainOperatorAccountId       = @"1234567890";
static NSString *const QredoKeychainPassword                = @"Password123";

NSString *systemVaultKeychainArchiveIdentifier;




@implementation QredoClientOptions
{
    QredoCertificate *_certificate;
}

-(instancetype)init {
    self = [super init];
    NSAssert(FALSE, @"Please use [QredoClientOptions initWithPinnedCertificate:] instead of init without arguments]");
    self = nil;
    return self;
}


-(instancetype)initWithDefaultTrustedRoots {
    self = [super init];
    if (self) {
        _certificate = nil;
    }
    return self;
}


-(QredoCertificate *)certificate {
    return _certificate;
}


@end

// Private stuff
@interface QredoClient ()
{
    QredoVault *_systemVault;
    QredoVault *_defaultVault;
    QredoServiceInvoker *_serviceInvoker;
    QredoKeychain *_keychain;
    QredoUserCredentials *_userCredentials;
    QredoAppCredentials *_appCredentials;
    
    
    dispatch_queue_t _rendezvousQueue;
}

@property NSURL *serviceURL;
@property QredoClientOptions *clientOptions;

/** Creates instance of qredo client
 @param serviceURL Root URL for Qredo services
 */
-(instancetype)initWithServiceURL:(NSURL *)serviceURL appCredentials:(QredoAppCredentials *)appCredentials  userCredentials:(QredoUserCredentials *)userCredentials;


@end

@implementation QredoClient


+(NSDate*)dateTime{
    return [QredoNetworkTime dateTime];
}


-(QredoAppCredentials *)appCredentials{
    return _appCredentials;
}

-(QredoUserCredentials *)userCredentials{
    return _userCredentials;
}

-(NSString *)versionString {
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    return [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}


-(NSString *)buildString {
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    return [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
}


-(QredoVault*)systemVault {
    // For rev1 we have only one vault
    // Keeping this method as a placeholder and it is used in Rendezvous and Conversations
    return _systemVault;
}


-(QredoKeychain *)keychain {
    return _keychain;
}


-(QredoServiceInvoker*)serviceInvoker {
    return _serviceInvoker;
}


+(void)initializeWithAppId:(NSString*)appId
                 appSecret:(NSString*)appSecret
                    userId:(NSString*)userId
                userSecret:(NSString*)userSecret
         completionHandler:(void (^)(QredoClient *client, NSError *error))completionHandler {
    
    [self initializeWithAppId:appId
                    appSecret:appSecret
                       userId:userId
                   userSecret:userSecret
                      options:nil
            completionHandler:completionHandler];
}

+(NSURL*)chooseServiceURL:(QredoClientOptions*)options{
    long transportType = options.transportType?options.transportType:QredoClientOptionsTransportTypeHTTP;
    NSString *serviceURLString = options.serverURL;

    NSURL *serviceURL;
    
    if (serviceURLString)return [NSURL URLWithString:serviceURLString];
    
    switch (transportType) {
        case QredoClientOptionsTransportTypeHTTP:
            
            serviceURL = [NSURL URLWithString:QredoClientDefaultServiceURL];
            break;
        case QredoClientOptionsTransportTypeMQTT:
            serviceURL = [NSURL URLWithString:QredoClientMQTTServiceURL];
            break;
        case QredoClientOptionsTransportTypeWebSockets:
            serviceURL = [NSURL URLWithString:QredoClientWebSocketsServiceURL];
            break;
    }
    return serviceURL;
}


+(void)initializeWithAppId:(NSString*)appId
                 appSecret:(NSString*)appSecret
                    userId:(NSString*)userId
                userSecret:(NSString*)userSecret
                   options:(QredoClientOptions*)options
             completionHandler:(void (^)(QredoClient *client, NSError *error))completionHandler {
    // TODO: DH - Update to display the QredoClientOptions contents, now it's no longer a dictionary
    
    
    
    
    
    
    if (!options) {
        options = [[QredoClientOptions alloc] initWithDefaultTrustedRoots];
    }
    
    
    QredoUserCredentials *userCredentials = [[QredoUserCredentials alloc] initWithAppId:appId
                                                                                 userId:userId
                                                                             userSecure:userSecret];
    
    QredoLogInfo(@"UserCredentials: Appid:%@   userID:%@   userSecure:%@",appId,userId,userSecret);
    
    
    
    QredoAppCredentials *appCredentials = [QredoAppCredentials appCredentialsWithAppId:appId
                                                                             appSecret:[NSData dataWithHexString:appSecret]];
    
    QredoLogInfo(@"AppCredentials: Appid:%@   appSecret:%@",appId,appSecret);
    
    systemVaultKeychainArchiveIdentifier = [userCredentials createSystemVaultIdentifier];

    
    NSURL *serviceURL = [self chooseServiceURL:options];

    __block NSError *error = nil;
    
//    __block QredoClient *client = [[QredoClient alloc] initWithServiceURL:serviceURL
//                                                           appCredentials:appCredentials
//                                                          userCredentials:userCredentials];
//    
    
    
    __block QredoClient *client = [[QredoClient alloc] initWithServiceURL:serviceURL
                                                           appCredentials:appCredentials
                                                          userCredentials:userCredentials];
    
    client.clientOptions = options;
    
    void (^completeAuthorization)(NSError *) = ^void (NSError *error) {
        if (error) {
            if (error)QredoLogError(@"Failed to create client");
            if (completionHandler) completionHandler(nil, error);
        } else {
            // This assert is very important!!!
            if (!client.defaultVault) QredoLogError(@"No QredoClient without a system vault must be passed to the client code.");
            QredoLogInfo(@"Client Inialized");
            if (completionHandler) completionHandler(client, error);
        }
    };

    BOOL loaded = [client loadStateWithError:&error];
    
    
    
    if (!loaded) {
        if ([error.domain isEqualToString:QredoErrorDomain] && error.code == QredoErrorCodeKeychainCouldNotBeFound) {
            //New KeyChain is required
          
            error = nil;
            
            [client createSystemVaultWithUserCredentials:userCredentials completionHandler:^(NSError *error) {
                if (error)QredoLogError(@"Failed to create system vault");
                if (!error) {
	                 [client saveStateWithError:&error];
                }
                
                completeAuthorization(error);
            }];
        } else {
            // TODO: [GR]: Show alert for corrupted keychain instead of the placeholder below.
            // Also implement a way of recovering a keychain here.
            
             QredoLogError(@"Critical error - possible keychain corruption");
        }
        return;
        
    }
    completeAuthorization(error);
}



-(instancetype)initWithServiceURL:(NSURL *)serviceURL
                   appCredentials:(QredoAppCredentials *)appCredentials
                  userCredentials:(QredoUserCredentials *)userCredentials{
    
    self = [self init];
    if (!self) return nil;
    
    _userCredentials = userCredentials;
    _appCredentials = appCredentials;
    _serviceURL = serviceURL;
    if (_serviceURL) {
        _serviceInvoker = [[QredoServiceInvoker alloc] initWithServiceURL:_serviceURL appCredentials:appCredentials];
    }
    
    _rendezvousQueue = dispatch_queue_create("com.qredo.rendezvous", nil);
    
    return self;
}


-(void)dealloc {
    // Ensure that we close our session, even if caller forgot
    [self closeSession];
}


-(BOOL)isClosed {
    return _serviceInvoker.isTerminated;
}


-(BOOL)isAuthenticated {
    // rev 1 doesn't have authentication
    return YES;
}


-(void)closeSession {
    // Need to terminate transport, which ends associated threads and subscriptions etc.
    QredoLogInfo(@"Close session");
    [self.defaultVault removeAllObservers];
    [_serviceInvoker terminate];

    
    // TODO: DH - somehow indicate that the client has been closed and therefore cannot be used again.
}


-(QredoVault*)defaultVault {
    if (!_defaultVault) {
        // should not happen, but just in case
        [self initializeVaults];
    }
    return _defaultVault;
}


#pragma mark -
#pragma mark Rendezvous



-(NSString*)appId {
    NSString* appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    
    if (!appID || [appID isEqualToString:@""]) {
        appID = @"testtag";
    }
    return appID;
}



+(NSString *)randomStringWithLength:(int)len{
    NSString *letters = @"abcdefghjklmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    }
    return randomString;
}




-(NSData*)createTagWithSecurityLevel:(QredoSecurityLevel)securityLevel{
    NSData *key = [QredoUtils randomKey:securityLevel];
    return key;
}







-(void)createAnonymousRendezvousWithCompletionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler{
    [self createAnonymousRendezvousWithTagType:QREDO_HIGH_SECURITY
                                  duration:0
                        unlimitedResponses:YES
                               summaryValues:nil
                         completionHandler:completionHandler];
}



-(void)createAnonymousRendezvousWithTagType:(QredoSecurityLevel)tagSecurityLevel
                      completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler {
    
    [self createAnonymousRendezvousWithTagType:tagSecurityLevel
                                  duration:0
                        unlimitedResponses:YES
                               summaryValues:nil
                         completionHandler:completionHandler];
}


-(void)createAnonymousRendezvousWithTag:(QredoSecurityLevel)tagSecurityLevel
                               duration:(long)duration
                      completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler {
    [self createAnonymousRendezvousWithTagType:tagSecurityLevel
                                  duration:duration
                        unlimitedResponses:YES
                               summaryValues:nil
                         completionHandler:completionHandler];
}


-(void)createAnonymousRendezvousWithTag:(NSString*)tag
                               duration:(long)duration
                     unlimitedResponses:(BOOL)unlimitedResponses
                      completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler{
    
    QredoLogVerbose(@"Start createAnonymousRendezvousWithTag %@", tag);
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc]
                                                   initWithConversationType:@""
                                                   durationSeconds:duration
                                                   summaryValues:nil
                                                   isUnlimitedResponseCount:unlimitedResponses];
    
    [self createRendezvousWithTag:tag
               authenticationType:QredoRendezvousAuthenticationTypeAnonymous
                    configuration:configuration
                  trustedRootPems:[[NSArray alloc] init]
                          crlPems:[[NSArray alloc] init]
                   signingHandler:nil
                   appCredentials:self.appCredentials
                completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                    QredoLogInfo(@"CreatedAnonymousRendezvousWithTag %@", tag);
                    if (completionHandler)completionHandler(rendezvous,error);
                }
     ];
}


-(void)createAnonymousRendezvousWithTagType:(QredoSecurityLevel)tagSecurityLevel
                               duration:(long)duration
                     unlimitedResponses:(BOOL)unlimitedResponses
                            summaryValues:(NSDictionary*)summaryValues
                      completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler {
    // Anonymous Rendezvous are created using the full tag. Signing handler, trustedRootPems and crlPems are unused


    NSData *dataTag = [QredoUtils randomKey:tagSecurityLevel];
    NSString *tag = [QredoUtils dataToHexString:dataTag];
    
    
    QredoLogVerbose(@"Start createAnonymousRendezvousWithTag %@", tag);
    QredoRendezvousConfiguration *configuration =  [[QredoRendezvousConfiguration alloc] initWithConversationType:@""
                                                   durationSeconds:duration
                                                   summaryValues:summaryValues
                                                   isUnlimitedResponseCount:unlimitedResponses];
    
    
    

    
    [self createRendezvousWithTag:tag
               authenticationType:QredoRendezvousAuthenticationTypeAnonymous
                    configuration:configuration
                  trustedRootPems:[[NSArray alloc] init]
                          crlPems:[[NSArray alloc] init]
                   signingHandler:nil
                   appCredentials:self.appCredentials
                completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                    QredoLogInfo(@"CreatedAnonymousRendezvousWithTag %@", tag);
                    if (completionHandler)completionHandler(rendezvous,error);
                }
     ];

}





// TODO: DH - Create unit tests for createAnonymousRendezvousWithTag
-(void)createAnonymousRendezvousWithTag:(NSString *)tag
                          configuration:(QredoRendezvousConfiguration *)configuration
                      completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler {
    // Anonymous Rendezvous are created using the full tag. Signing handler, trustedRootPems and crlPems are unused
    QredoLogVerbose(@"Start createAnonymousRendezvousWithTag %@", tag);
    [self createRendezvousWithTag:tag
               authenticationType:QredoRendezvousAuthenticationTypeAnonymous
                    configuration:configuration
                  trustedRootPems:[[NSArray alloc] init]
                          crlPems:[[NSArray alloc] init]
                   signingHandler:nil
                   appCredentials:self.appCredentials
                completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                    QredoLogInfo(@"CreatedAnonymousRendezvousWithTag %@", tag);
                    if (completionHandler)completionHandler(rendezvous,error);
                }
     ];
}


// TODO: DH - Create unit tests for createAuthenticatedRendezvousWithPrefix (internal keys)
// TODO: DH - create unit tests which provide incorrect authentication types
-(void)createAuthenticatedRendezvousWithPrefix:(NSString *)prefix
                            authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                 configuration:(QredoRendezvousConfiguration *)configuration
                             completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler {
    if (authenticationType == QredoRendezvousAuthenticationTypeAnonymous) {
        // Not an authenticated rendezvous, so shouldn't be using this method
        NSString *message = @"'Anonymous' is invalid, use the method dedicated to anonymous rendezvous.";
        QredoLogError(@"%@", message);
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        if (completionHandler)completionHandler(nil, error);
        
        return;
    } else if (authenticationType == QredoRendezvousAuthenticationTypeX509Pem ||
               authenticationType == QredoRendezvousAuthenticationTypeX509PemSelfsigned) {
        // X.509 authenticated rendezvous MUST use externally generated certificates, so MUST use method with signingHandler
        NSString *message = @"'X.509' is invalid, use the method dedicated to externally generated keys/certs which has a signing handler.";
        QredoLogError(@"%@", message);
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        if (completionHandler)completionHandler(nil, error);
        return;
    }
    
    // Authenticated Rendezvous with internally generated keys are created using just the optional prefix.
    // @ is not part of the prefix and must not appear in prefix (this will be validated later)
    
    // Nil, or empty prefix is fine. The final tag will have the public key appended, but keypair hasn't been
    // generated yet, so for now just use @, and add prefix if provided
    NSString *prefixedTag = @"@";
    if (prefix) {
        prefixedTag = [NSString stringWithFormat:@"%@@", prefix];
    }
    
    // Authenticated Rendezvous with internally generated keys. Signing handler, trustedRootPems and crlPems are unused
    [self createRendezvousWithTag:prefixedTag
               authenticationType:authenticationType
                    configuration:configuration
                  trustedRootPems:[[NSArray alloc] init]
                          crlPems:[[NSArray alloc] init]
                   signingHandler:nil
                   appCredentials:self.appCredentials
                completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                    QredoLogInfo(@"CreatedAnonymousRendezvousWithTag %@", prefixedTag);
                    if (completionHandler)completionHandler(rendezvous,error);
                }
     ];

}


// TODO: DH - Create unit tests for createAuthenticatedRendezvousWithPrefix (external keys)
// TODO: DH - create unit test with nil signing handler and confirm detected deeper down stack
-(void)createAuthenticatedRendezvousWithPrefix:(NSString *)prefix
                            authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                 configuration:(QredoRendezvousConfiguration *)configuration
                                     publicKey:(NSString *)publicKey
                               trustedRootPems:(NSArray *)trustedRootPems
                                       crlPems:(NSArray *)crlPems
                                signingHandler:(signDataBlock)signingHandler
                             completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler {
    if (authenticationType == QredoRendezvousAuthenticationTypeAnonymous) {
        // Not an authenticated rendezvous, so shouldn't be using this method
        NSString *message = @"'Anonymous' is invalid, use the method dedicated to anonymous rendezvous.";
        QredoLogError(@"%@", message);
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        if (completionHandler)completionHandler(nil, error);
        return;
    }
    else if (authenticationType == QredoRendezvousAuthenticationTypeX509Pem) {
        if (!trustedRootPems) {
            // Cannot have nil trusted root PEMs
            NSString *message = @"TrustedRootPems cannot be nil when creating X.509 authenicated rendezvous, as creation will fail.";
            QredoLogError(@"%@", message);
            NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                                 code:QredoErrorCodeRendezvousInvalidData
                                             userInfo:@{ NSLocalizedDescriptionKey : message }];
            if (completionHandler)completionHandler(nil, error);
            return;
        }
        else if (trustedRootPems.count == 0) {
            // Cannot have no trusted root refs
            NSString *message = @"TrustedRootPems cannot be empty when creating X.509 authenicated rendezvous, as creation will fail.";
            QredoLogError(@"%@", message);
            NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                                 code:QredoErrorCodeRendezvousInvalidData
                                             userInfo:@{ NSLocalizedDescriptionKey : message }];
            if (completionHandler)completionHandler(nil, error);
            return;
        }
    }
    
    // TODO: DH - validate that the configuration provided is an authenticated rendezvous, and that public key is present
    // TODO: DH - validate inputs (any which aren't validated later)
    
    // Authenticated Rendezvous with externally generated keys are created using optional prefix and mandatory
    // public key data. @ is indicator of an authenticated rendebous but is not part of the prefix and must not
    // appear in prefix, or public key parts
    
    // The full tag is (optional) prefix and (mandatory) public key/cert appended
    NSString *fullTag = nil;
    if (prefix) {
        // Prefix and public key
        fullTag = [NSString stringWithFormat:@"%@@%@", prefix, publicKey];
    }
    else {
        // Just public key
        fullTag = [NSString stringWithFormat:@"@%@", publicKey];
    }
    
    // Authenticated Rendezvous with externally generated keys. Signing handler is required
    [self createRendezvousWithTag:fullTag
               authenticationType:authenticationType
                    configuration:configuration
                  trustedRootPems:trustedRootPems
                          crlPems:crlPems
                   signingHandler:signingHandler
                   appCredentials:self.appCredentials
                completionHandler:completionHandler];
}


-(void)createRendezvousWithTag:(NSString *)tag
            authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                 configuration:(QredoRendezvousConfiguration *)configuration
               trustedRootPems:(NSArray *)trustedRootPems
                       crlPems:(NSArray *)crlPems
                signingHandler:(signDataBlock)signingHandler
                appCredentials:(QredoAppCredentials *)appCredentials
             completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler {
    // although createRendezvousWithTag is asynchronous, it generates keys synchronously, which may cause a lag
    
    QredoLogVerbose(@"Start createRendezvousWithTag %@", tag);
    
    
    dispatch_async(_rendezvousQueue, ^{
        QredoRendezvous *rendezvous = [[QredoRendezvous alloc] initWithClient:self];
        
        QredoLogVerbose(@"Start createRendezvousWithTag on rendezvousQueue %@", tag);
        
        [rendezvous createRendezvousWithTag:tag
                         authenticationType:authenticationType
                              configuration:configuration
                            trustedRootPems:trustedRootPems
                                    crlPems:crlPems
                             signingHandler:signingHandler
                             appCredentials:appCredentials
                          completionHandler:^(NSError *error) {
                              if (error) {
                                  if (completionHandler)completionHandler(nil, error);
                              } else {
                                  if (completionHandler)completionHandler(rendezvous, error);
                              }
                          }];
        QredoLogVerbose(@"End createRendezvousWithTag on rendezvousQueue %@", tag);
    });
    
    QredoLogVerbose(@"End createRendezvousWithTag %@", tag);
}


-(QredoRendezvous*)rendezvousFromVaultItem:(QredoVaultItem*)vaultItem error:(NSError**)error {
    @try {
        QredoRendezvous *rendezvous = [[QredoRendezvous alloc] initWithVaultItem:self fromVaultItem:vaultItem];
        return rendezvous;
    }
    @catch (NSException *e) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousInvalidData
                                     userInfo:
                      @{
                        NSLocalizedDescriptionKey:@"Failed to extract rendezvous from the vault item",
                        NSUnderlyingErrorKey: e
                        }];
        }
        return nil;
    }
}


-(QredoConversation*)conversationFromVaultItem:(QredoVaultItem*)vaultItem error:(NSError**)error {
    @try {
        QLFConversationDescriptor *descriptor
        = [QredoPrimitiveMarshallers unmarshalObject:vaultItem.value
                                        unmarshaller:[QLFConversationDescriptor unmarshaller]];
        
        QredoConversation *conversation = [[QredoConversation alloc] initWithClient:self fromLFDescriptor:descriptor];
        
        [conversation loadHighestHWMWithCompletionHandler:nil];
        
        return conversation;
    }
    @catch (NSException *e) {
        if (error) {
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversationInvalidData
                                     userInfo:
                      @{
                        NSLocalizedDescriptionKey:@"Failed to extract conversation from the vault item",
                        NSUnderlyingErrorKey: e
                        }];
        }
        return nil;
    }
}


-(void)fetchRendezvousWithTag:(NSString *)tag completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler {
    __block QredoRendezvousMetadata *matchedRendezvousMetadata;
    
    [self enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop) {
        if ([tag isEqualToString:rendezvousMetadata.tag]) {
            matchedRendezvousMetadata =rendezvousMetadata;
            *stop = YES;
        }
    } completionHandler:^(NSError *error) {
        if (error) {
            QredoLogError(@"Fetch Rendezvous Error %@",error);
            if (completionHandler)completionHandler(nil,error);
        }else if(!matchedRendezvousMetadata) {
            NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                                 code:QredoErrorCodeRendezvousNotFound
                                             userInfo:@{ NSLocalizedDescriptionKey : @"Rendezvous was not found in vault" }];
            QredoLogError(@"Fetch Rendezvous Error %@",error);
            if (completionHandler)completionHandler(nil,error);
        }else{
            [self fetchRendezvousWithMetadata:matchedRendezvousMetadata completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
               QredoLogInfo(@"Fetch Rendezvous complete");
                if (completionHandler)completionHandler(rendezvous, error);
            }];
        }
    }];
}



-(void)enumerateRendezvousWithBlock:(void (^)(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop))block
                  completionHandler:(void (^)(NSError *error))completionHandler {
    QredoVault *vault = [self systemVault];
    
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stopVaultEnumeration) {
        if ([vaultItemMetadata.dataType isEqualToString:kQredoRendezvousVaultItemType]) {
            NSString *tag = [vaultItemMetadata.summaryValues objectForKey:kQredoRendezvousVaultItemLabelTag];
            QredoRendezvousAuthenticationType authenticationType  = [[vaultItemMetadata.summaryValues
                                                                      objectForKey:kQredoRendezvousVaultItemLabelAuthenticationType] intValue];
            
            QredoRendezvousRef *rendezvousRef = [[QredoRendezvousRef alloc] initWithVaultItemDescriptor:vaultItemMetadata.descriptor
                                                                                                  vault:vault];
            
            QredoRendezvousMetadata *metadata = [[QredoRendezvousMetadata alloc] initWithTag:tag
                                                                          authenticationType:authenticationType
                                                                               rendezvousRef:rendezvousRef
                                                                                summaryValues:vaultItemMetadata.summaryValues];
            
            BOOL stopObjectEnumeration = NO; // here we lose the feature when *stop == YES, then we are on the last object
            block(metadata, &stopObjectEnumeration);
            *stopVaultEnumeration = stopObjectEnumeration;
        }
    } completionHandler:^(NSError *error) {
        QredoLogInfo(@"Enumerate Rendezvous complete");
        if (completionHandler)completionHandler(error);
    }];
}


-(void)fetchRendezvousWithRef:(QredoRendezvousRef *)ref
            completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler {
    // an unknown ref will throw an exception, but catch a nil ref here
    if (ref == nil)    {
        NSString *message = @"'The RendezvousRef must not be nil";
        QredoLogError(@"fetchRendezvousWithRef - RendezvousRef must not be nil ");
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        if (completionHandler)completionHandler(nil, error);
        return;
    }
    
    [self fetchRendezvousWithVaultItemDescriptor:ref.vaultItemDescriptor completionHandler:completionHandler];
}


-(void)fetchRendezvousWithMetadata:(QredoRendezvousMetadata *)metadata
                 completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler {
    [self fetchRendezvousWithRef:metadata.rendezvousRef completionHandler:completionHandler];
}


// private method
-(void)fetchRendezvousWithVaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor
                            completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler {
    QredoVault *vault = [self systemVault];
    
    [vault getItemWithDescriptor:vaultItemDescriptor
               completionHandler:^(QredoVaultItem *vaultItem, NSError *error) {
         if (error) {
             QredoLogError(@"Fetch Rendezvous Error %@",error);
             if (completionHandler)completionHandler(nil, error);
             return;
         }
         
         NSError *parsingError = nil;
         QredoRendezvous *rendezvous = [self rendezvousFromVaultItem:vaultItem error:&parsingError];
         QredoLogInfo(@"Fetch Rendezvous complete");
         if (completionHandler)completionHandler(rendezvous, parsingError);
     }];
}


-(void)respondWithTag:(NSString *)tag
    completionHandler:(void (^)(QredoConversation *conversation, NSError *error))completionHandler {
    [self respondWithTag:tag trustedRootPems:nil crlPems:nil completionHandler:completionHandler];
}


-(void)respondWithTag:(NSString *)tag
      trustedRootPems:(NSArray *)trustedRootPems
              crlPems:(NSArray *)crlPems
    completionHandler:(void (^)(QredoConversation *conversation, NSError *error))completionHandler {
    NSAssert(completionHandler, @"completionHandler should not be nil");
    
    dispatch_async(_rendezvousQueue, ^{
        QredoConversation *conversation = [[QredoConversation alloc] initWithClient:self];
        [conversation respondToRendezvousWithTag:tag
                                 trustedRootPems:trustedRootPems
                                         crlPems:crlPems
                                  appCredentials:self.appCredentials
                               completionHandler:^(NSError *error) {
                                   if (error) {
                                       if (completionHandler)completionHandler(nil, error);
                                   } else {
                                       if (completionHandler)completionHandler(conversation, nil);
                                   }
                               }];
    });
}


-(void)enumerateConversationsWithBlock:(void (^)(QredoConversationMetadata *conversationMetadata, BOOL *stop))block
                     completionHandler:(void (^)(NSError *error))completionHandler {
    QredoVault *vault = [self systemVault];
    
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stopVaultEnumeration) {
        if ([vaultItemMetadata.dataType isEqualToString:kQredoConversationVaultItemType]) {
            QredoConversationMetadata *metadata = [[QredoConversationMetadata alloc] init];
            // TODO: DH - populate metadata.rendezvousMetadata
            metadata.conversationId = [vaultItemMetadata.summaryValues objectForKey:kQredoConversationVaultItemLabelId];
            metadata.amRendezvousOwner = [[vaultItemMetadata.summaryValues objectForKey:kQredoConversationVaultItemLabelAmOwner] boolValue];
            metadata.type = [vaultItemMetadata.summaryValues objectForKey:kQredoConversationVaultItemLabelType];
            metadata.rendezvousTag = [vaultItemMetadata.summaryValues objectForKey:kQredoConversationVaultItemLabelTag];
            metadata.conversationRef = [[QredoConversationRef alloc] initWithVaultItemDescriptor:vaultItemMetadata.descriptor vault:vault];
            metadata.summaryValues =  vaultItemMetadata.summaryValues;
            
            BOOL stopObjectEnumeration = NO; // here we lose the feature when *stop == YES, then we are on the last object
            
            block(metadata, &stopObjectEnumeration);
            *stopVaultEnumeration = stopObjectEnumeration;
        }
    } completionHandler:^(NSError *error) {
        QredoLogInfo(@"Enumermate Conversation Complete");
        if (completionHandler)completionHandler(error);
    }];
}


-(void)fetchConversationWithRef:(QredoConversationRef *)conversationRef
              completionHandler:(void (^)(QredoConversation* conversation, NSError *error))completionHandler {
    QredoVault *vault = [self systemVault];
    
    [vault getItemWithDescriptor:conversationRef.vaultItemDescriptor
               completionHandler:^(QredoVaultItem *vaultItem, NSError *error){
         if (error) {
             if (completionHandler)completionHandler(nil, error);
             return;
         }
         
         NSError *parsingError = nil;
         QredoConversation *conversation = [self conversationFromVaultItem:vaultItem error:&parsingError];
         conversation.metadata.conversationRef = conversationRef;
         conversation.metadata.summaryValues = vaultItem.metadata.summaryValues;
         QredoLogInfo(@"Fetch Conversation with Ref complete");
         if (completionHandler)completionHandler(conversation, parsingError);
     }];
}


-(void)deleteConversationWithRef:(QredoConversationRef *)conversationRef
               completionHandler:(void (^)(NSError *error))completionHandler {
    [self fetchConversationWithRef:conversationRef
                 completionHandler:^(QredoConversation *conversation, NSError *error)
     {
         if (error) {
             if (completionHandler)completionHandler(error);
             return;
         }
         
         [conversation deleteConversationWithCompletionHandler:completionHandler];
     }];
}


-(void)activateRendezvousWithRef:(QredoRendezvousRef *)ref
                        duration:(long)duration
               completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler {
    if (completionHandler == nil) {
        NSException* myException = [NSException
                                    exceptionWithName:@"NilCompletionHandler"
                                    reason:@"CompletionHandlerisNil"
                                    userInfo:nil];
        @throw myException;
    }
    
    // validate that the duration is >= 0 and that the RendezvousRef is not nil
    if (duration < 0)
        
    {
        NSString *message =  @"'The Rendezvous duration must not be negative";
        
        QredoLogError(@"%@", message);
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        if (completionHandler)completionHandler(nil, error);
        return;
    }
    
    
    // get the Rendezvous using the ref
    [self fetchRendezvousWithRef: ref completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        if (error) {
            if (completionHandler)completionHandler(nil, error);
            return;
        }
        
        
        [rendezvous activateRendezvous:duration completionHandler:^(NSError *error){
             if (error) {
                 if (completionHandler)completionHandler(nil, error);
                 QredoLogError(@"Failed to activate Rendezvous");
             } else {
                 if (completionHandler)completionHandler(rendezvous, nil);
                                
             }
         }
         ];
    }
     ];
}


-(void)deactivateRendezvousWithRef:(QredoRendezvousRef *)ref
                 completionHandler:(void (^)(NSError *))completionHandler {
    if (completionHandler == nil) {
        NSException* myException = [NSException
                                    exceptionWithName:@"NilCompletionHandler"
                                    reason:@"CompletionHandlerisNil"
                                    userInfo:nil];
        @throw myException;
    }
    
    
    // get the Rendezvous using the ref
    [self fetchRendezvousWithRef: ref completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        if (error) {
            if (completionHandler)completionHandler(error);
            return;
        }
        
        [rendezvous deactivateRendezvous:^(NSError *error) {
            QredoLogInfo(@"Rendezvous deactivated"); 
            if (completionHandler)completionHandler(error);
        }];
    }];
}


#pragma mark -
#pragma mark Private Methods

-(NSString *)deviceName {
    NSString *name = [[UIDevice currentDevice] name];
    return (!name) ? @"iOS device" : name;
}


-(void)addDeviceToVaultWithCompletionHandler:(void (^)(NSError *error))completionHandler {
    QredoVault *systemVault = [self systemVault];
    
    QredoVaultItemMetadata *metadata
    = [QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:
       @{
         QredoVaultItemSummaryKeyDeviceName : [self deviceName]
         }];
    QredoVaultItem *deviceInfoItem = [QredoVaultItem vaultItemWithMetadata:metadata value:nil];
    
    
    [systemVault putItem:deviceInfoItem
       completionHandler:^(QredoVaultItemMetadata *newItemMetadata, NSError *error)
     {
         if (completionHandler) completionHandler(error);
     }];
}


-(BOOL)saveStateWithError:(NSError **)error {
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    return [self saveSystemVaultKeychain:_keychain
        withKeychainWithKeychainArchiver:keychainArchiver
                                   error:error];
}


-(BOOL)loadStateWithError:(NSError **)error {
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    QredoKeychain *systemVaultKeychain = [self loadSystemVaultKeychainWithKeychainArchiver:keychainArchiver
                                                                                     error:error];
    if (systemVaultKeychain) {
        _keychain = systemVaultKeychain;
        [self initializeVaults];
        return YES;
    }
    
    return NO;
}


-(BOOL)deleteCurrentDataWithError:(NSError **)error {
    if (!_systemVault || !_defaultVault) {
        return YES;
    }
    
    [_systemVault clearAllData];
    [_defaultVault clearAllData];
    
    return [self deleteDefaultVaultKeychainWithError:error];
}


-(void)createSystemVaultWithUserCredentials:(QredoUserCredentials*)userCredentials completionHandler:(void (^)(NSError *error))completionHandler {
    _userCredentials = userCredentials;
    [self deleteCurrentDataWithError:nil];
    
    [self createDefaultKeychain:userCredentials];
    [self initializeVaults];
    
    [self addDeviceToVaultWithCompletionHandler:completionHandler];
}


-(void)initializeVaults {
    _systemVault = [[QredoVault alloc] initWithClient:self vaultKeys:_keychain.systemVaultKeys withLocalIndex:NO];
    
    if (self.clientOptions.disableMetadataIndex==YES) {
        _defaultVault = [[QredoVault alloc] initWithClient:self vaultKeys:_keychain.defaultVaultKeys withLocalIndex:NO];
    }else{
        _defaultVault = [[QredoVault alloc] initWithClient:self vaultKeys:_keychain.defaultVaultKeys withLocalIndex:YES];
    }
}


-(id<QredoKeychainArchiver>)qredoKeychainArchiver {
    return [QredoKeychainArchivers defaultQredoKeychainArchiver];
}


-(void)createDefaultKeychain:(QredoUserCredentials*)userCredentials {
    QLFOperatorInfo *operatorInfo
    = [QLFOperatorInfo operatorInfoWithName:QredoKeychainOperatorName
                                 serviceUri:self.serviceURL.absoluteString
                                  accountID:QredoKeychainOperatorAccountId
                       currentServiceAccess:[NSSet set]
                          nextServiceAccess:[NSSet set]];
    
    QredoKeychain *keychain = [[QredoKeychain alloc] initWithOperatorInfo:operatorInfo];
    [keychain generateNewKeys:userCredentials];
    
    _keychain = keychain;
}


//+(void)changeUserCredentialsAppId:(NSString*)appId
//                           userId:(NSString*)userId
//                   fromUserSecure:(NSString*)fromUserSecure
//                     toUserSecure:(NSString*)toUserSecure
//                            error:(NSError **)error{
//
//
//    QredoUserCredentials *sourceCredentials        = [[QredoUserCredentials alloc] initWithAppId:appId
//                                                                                          userId:userId
//                                                                                      userSecure:fromUserSecure];
//    QredoUserCredentials *destinationCredentials   = [[QredoUserCredentials alloc] initWithAppId:appId
//                                                                                          userId:userId
//                                                                                      userSecure:toUserSecure];
//    
//    id<QredoKeychainArchiver>keychainArchiver = [QredoKeychainArchivers defaultQredoKeychainArchiver];
//    
//    //get exsiting keychain
//    QredoKeychain * keyChain = [keychainArchiver loadQredoKeychainWithIdentifier:[sourceCredentials createSystemVaultIdentifier] error:error];
//    if (*error)return;
//    
//    [QredoLocalIndexDataStore renameStoreFrom:sourceCredentials to:destinationCredentials];
//
//    //save to  new iD
//    [keychainArchiver saveQredoKeychain:keyChain  withIdentifier:[destinationCredentials createSystemVaultIdentifier] error:error];
//    
//}



-(QredoKeychain *)loadSystemVaultKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver
                                                        error:(NSError **)error {
    return [keychainArchiver loadQredoKeychainWithIdentifier:systemVaultKeychainArchiveIdentifier error:error];
}


-(BOOL)saveSystemVaultKeychain:(QredoKeychain *)keychain
withKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver
                         error:(NSError **)error {
    return [keychainArchiver saveQredoKeychain:keychain
                                withIdentifier:systemVaultKeychainArchiveIdentifier error:error];
}


-(BOOL)hasSystemVaultKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver
                                            error:(NSError **)error {
    return [keychainArchiver hasQredoKeychainWithIdentifier:systemVaultKeychainArchiveIdentifier error:error];
}


-(BOOL)setKeychain:(QredoKeychain *)keychain
             error:(NSError **)error {
    [self deleteCurrentDataWithError:nil];
    
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    BOOL result = [self saveSystemVaultKeychain:keychain
               withKeychainWithKeychainArchiver:keychainArchiver
                                          error:error];
    
    QredoClient *newClient = [[QredoClient alloc] initWithServiceURL:
                              [NSURL URLWithString:keychain.operatorInfo.serviceUri]
                                                      appCredentials:_appCredentials
                                                     userCredentials:_userCredentials];
    [newClient loadStateWithError:error];
    [newClient addDeviceToVaultWithCompletionHandler:nil];
    
    return result;
}


-(BOOL)deleteDefaultVaultKeychainWithError:(NSError **)error {
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    return [self saveSystemVaultKeychain:nil withKeychainWithKeychainArchiver:keychainArchiver error:error];
}


-(BOOL)hasDefaultVaultKeychainWithError:(NSError **)error {
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    return [self hasSystemVaultKeychainWithKeychainArchiver:keychainArchiver error:error];
}







@end