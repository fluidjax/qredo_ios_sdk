/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/



#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoVault.h"
#import "QredoTypesPrivate.h"
#import "QredoVaultPrivate.h"
#import "QredoRendezvousPrivate.h"
#import "QredoConversationPrivate.h"

#import "QredoPrimitiveMarshallers.h"
#import "QredoServiceInvoker.h"
#import "QredoLoggerPrivate.h"

#import "QredoKeychain.h"
#import "QredoKeychainArchiver.h"
#import "NSData+QredoRandomData.h"
#import "NSData+HexTools.h"

#import "QredoCertificate.h"
#import "QredoUserCredentials.h"
#import "QredoLocalIndexDataStore.h"
#import "QredoConversationProtocol.h"
#import "QredoNetworkTime.h"
#import <UIKit/UIKit.h>
#import "MasterConfig.h"
#import "KeychainItemWrapper.h"
#import "NSData+HexTools.h"



NSString *const QredoVaultItemTypeKeychain                  = @"com.qredo.keychain.device-name";
NSString *const QredoVaultItemTypeKeychainAttempt           = @"com.qredo.keychain.transfer-attempt";
NSString *const QredoVaultItemSummaryKeyDeviceName          = @"device-name";

NSString *const QredoClientOptionCreateNewSystemVault       = @"com.qredo.option.create.new.system.vault";
NSString *const QredoClientOptionServiceURL                 = @"com.qredo.option.serviceUrl";

NSString *const QredoRendezvousURIProtocol                  = @"qrp:";
static NSString *const QredoKeychainOperatorName            = @"Qredo Mock Operator";
static NSString *const QredoKeychainOperatorAccountId       = @"1234567890";
static NSString *const QredoKeychainPassword                = @"Password123";

//keyname constants for the keychain stored credentials
static NSString *const QredoStoredAppIDKey           = @"QA";
static NSString *const QredoStoredAppSecretKey       = @"QB";
static NSString *const QredoStoredUserIDKey          = @"QC";
static NSString *const QredoStoredUserSecretKey      = @"QD";
static NSString *const QredoStoredAppGroup           = @"QE";
static NSString *const QredoStoredOptions            = @"QF";

static NSString *const QredoStoredUserDefautlCredentialsKey     = @"QREDO_USER_DEFAULT_CREDENTIALS";

NSString *systemVaultKeychainArchiveIdentifier;


@implementation QredoClientOptions{
    QredoCertificate *_certificate;
}

-(void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject:self.serverURL              forKey:@"Q1"];
    [coder encodeInt:self.transportType             forKey:@"Q2"];
    [coder encodeBool:self.resetData                forKey:@"Q3"];
    [coder encodeBool:self.disableMetadataIndex     forKey:@"Q4"];
    [coder encodeObject:self.appGroup               forKey:@"Q6"];
    [coder encodeObject:self.keyChainGroup          forKey:@"Q7"];
    [coder encodeBool:self.useHTTP                  forKey:@"Q8"];
}


-(instancetype)initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if (self) {
        self.serverURL                  = [decoder decodeObjectForKey:@"Q1"];
        self.transportType              = [decoder decodeIntForKey:@"Q2"];
        self.resetData                  = [decoder decodeBoolForKey:@"Q3"];
        self.disableMetadataIndex       = [decoder decodeBoolForKey:@"Q4"];
        self.appGroup                   = [decoder decodeObjectForKey:@"Q6"];
        self.keyChainGroup              = [decoder decodeObjectForKey:@"Q7"];
        self.useHTTP                    = [decoder decodeBoolForKey:@"Q8"];
    }
    return self;
}


-(instancetype)init{
    return [self initLive];
}


-(instancetype)initLive {
    self = [super init];
    if (self){
        self.serverURL      = LIVE_SERVER_URL;
        self.useHTTP        = LIVE_USE_HTTP;
        self.appGroup       = nil;
        self.keyChainGroup  = nil;
    }
    return self;
}

-(instancetype)initDev {
    self = [super init];
    if (self){
        self.serverURL      = DEV_SERVER_URL;
        self.useHTTP        = DEV_USE_HTTP;
        self.appGroup       = nil;
        self.keyChainGroup  = nil;
    }
    return self;
}


-(instancetype)initTest {
    self = [super init];
    if (self){
        self.serverURL      = TEST_SERVER_URL;
        self.useHTTP        = TEST_USE_HTTP;
        self.appGroup       = TEST_APP_GROUP;
        self.keyChainGroup  = TEST_KEYCHAIN_GROUP;
    }
    return self;
}








-(QredoCertificate *)certificate {
    return _certificate;
}


-(NSString*)description{
    NSMutableString *retString = [[NSMutableString alloc] init];
    
    [retString appendString:@"\n"];
    [retString appendString:[NSString stringWithFormat:@"serverURL:         %@\n", self.serverURL]];
    [retString appendString:[NSString stringWithFormat:@"appGroup:          %@\n", self.appGroup]];
    [retString appendString:[NSString stringWithFormat:@"keyChainGroup:     %@\n", self.keyChainGroup]];
    
    if (self.useHTTP==YES){
        [retString appendString:                       @"useHTTP:           YES\n"];
    }else{
        [retString appendString:                       @"useHTTP:           NO\n"];
    }
    
    if (self.transportType==QredoClientOptionsTransportTypeHTTP)[retString appendString:@"Transport:         HTTP\n"];
    if (self.transportType==QredoClientOptionsTransportTypeWebSockets)[retString appendString:@"Transport:         WebSockets"];
    
    return [retString copy];
    
}

@end

//Private stuff
@interface QredoClient (){
    QredoVault *_systemVault;
    QredoVault *_defaultVault;
    QredoServiceInvoker *_serviceInvoker;
    QredoKeychain *_keychain;
    QredoUserCredentials *_userCredentials;
    QredoAppCredentials *_appCredentials;
    
    dispatch_queue_t _rendezvousQueue;
}

@property NSURL *serviceURL;
@property (readwrite) QredoClientOptions *clientOptions;


/** Creates instance of qredo client
 @param serviceURL Root URL for Qredo services
 */
-(instancetype)initWithServiceURL:(NSURL *)serviceURL appCredentials:(QredoAppCredentials *)appCredentials userCredentials:(QredoUserCredentials *)userCredentials;


@end

@implementation QredoClient



+(NSDate *)dateTime {
    return [QredoNetworkTime dateTime];
}


-(QredoAppCredentials *)appCredentials {
    return _appCredentials;
}


-(QredoUserCredentials *)userCredentials {
    return _userCredentials;
}


-(NSString *)versionString {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
    return [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}


-(NSString *)buildString {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
    return [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
}


-(QredoVault *)systemVault {
    //For rev1 we have only one vault
    //Keeping this method as a placeholder and it is used in Rendezvous and Conversations
    return _systemVault;
}


-(QredoServiceInvoker *)serviceInvoker {
    return _serviceInvoker;
}



+(void)initializeFromUserDefaultCredentialsInAppGroup:(NSString*)appGroup
                withCompletionHandler:(void (^)(QredoClient *client,NSError *error))completionHandler {
    if (!appGroup){
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeUnknown
                                         userInfo:@{ NSLocalizedDescriptionKey:@"No App Group Defined"}];
        if (completionHandler)completionHandler(nil, error);
        return;
    }
    NSDictionary *credentials = [QredoClient retrieveCredentialsUserDefaultsAppGroup:appGroup];
    NSString *appId         = [credentials objectForKey:QredoStoredAppIDKey];
    NSString *appSecret     = [credentials objectForKey:QredoStoredAppSecretKey];
    NSString *userId        = [credentials objectForKey:QredoStoredUserIDKey];
    NSString *userSecret    = [credentials objectForKey:QredoStoredUserSecretKey];
    QredoClientOptions *options = [credentials objectForKey:QredoStoredOptions];

    
    if (userSecret && userId && appSecret && appId){
        [self initializeWithAppId:appId
                        appSecret:appSecret
                           userId:userId
                       userSecret:userSecret
                          options:options
                completionHandler:completionHandler];
    }else{
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeUnknown
                                         userInfo:@{ NSLocalizedDescriptionKey:@"Invalid Stored Credentials"}];
        if (completionHandler)completionHandler(nil, error);
    }
}



+(void)initializeFromKeychainCredentialsInGroup:(NSString*)keyChainGroup
            withCompletionHandler:(void (^)(QredoClient *client,NSError *error))completionHandler {
    NSDictionary *credentials = [QredoClient retrieveCredentialsFromKeychainGroup:keyChainGroup];
    
    NSString *appId = [credentials objectForKey:QredoStoredAppIDKey];
    NSString *appSecret = [credentials objectForKey:QredoStoredAppSecretKey];
    NSString *userId = [credentials objectForKey:QredoStoredUserIDKey];
    NSString *userSecret = [credentials objectForKey:QredoStoredUserSecretKey];
    
    QredoClientOptions *options = [credentials objectForKey:QredoStoredOptions];
    
    if (userSecret && userId && appSecret && appId){
        [self initializeWithAppId:appId
                        appSecret:appSecret
                           userId:userId
                       userSecret:userSecret
                          options:options
                completionHandler:completionHandler];
    }else{
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey:@"Invalid Stored Credentials"}];
        if (completionHandler)completionHandler(nil, error);
    }
}






+(void)initializeWithAppId:(NSString *)appId
                 appSecret:(NSString *)appSecret
                    userId:(NSString *)userId
                userSecret:(NSString *)userSecret
         completionHandler:(void (^)(QredoClient *client,NSError *error))completionHandler {
    
    
    
    [self initializeWithAppId:appId
                    appSecret:appSecret
                       userId:userId
                   userSecret:userSecret
                      options:nil
            completionHandler:completionHandler];
}




+(NSURL *)chooseServiceURL:(QredoClientOptions *)options {
    long transportType = options.transportType ? options.transportType : QredoClientOptionsTransportTypeWebSockets;
    NSString *protocol;
    NSString *port;
    
    switch (transportType) {
        case QredoClientOptionsTransportTypeHTTP:
            protocol = @"https://";
            port = @"443";
            
            if (options.useHTTP == YES){
                protocol = @"http://";
                port = @"8080";
            }
            
            break;
        case QredoClientOptionsTransportTypeWebSockets:
            protocol = @"wss://";
            port = @"443";
            if (options.useHTTP == YES){
                protocol = @"ws://";
                port = @"8080";
            }
            break;
        default:
            break;
    }
    NSString *serviceURLString = [NSString stringWithFormat:@"%@%@:%@/services",protocol, options.serverURL, port ];
    //NSLog(@"Service URL: %@",serviceURLString);
    return [NSURL URLWithString:serviceURLString];
}



+(void)initializeWithAppId:(NSString *)appId
                 appSecret:(NSString *)appSecret
                    userId:(NSString *)userId
                userSecret:(NSString *)userSecret
                   options:(QredoClientOptions *)options
         completionHandler:(void (^)(QredoClient *client,NSError *error))completionHandler {

    
    
    if (!options){
        options = [[QredoClientOptions alloc] initLive];
    }
    
    

    
    
    QredoUserCredentials *userCredentials = [[QredoUserCredentials alloc] initWithAppId:appId
                                                                                 userId:userId
                                                                             userSecure:userSecret];
    
    //NSLog(@"UserCredentials: Appid:%@   userID:%@   userSecure:%@",appId,userId,userSecret);
    
    
    
    QredoAppCredentials *appCredentials = [QredoAppCredentials appCredentialsWithAppId:appId
                                                                             appSecret:[NSData dataWithHexString:appSecret]];
    
   //NSLog(@"AppCredentials: Appid:%@   appSecret:%@",appId,appSecret);
    
    systemVaultKeychainArchiveIdentifier = [userCredentials createSystemVaultIdentifier];
    
    
    NSURL *serviceURL = [self chooseServiceURL:options];
    
    __block NSError *error = nil;
    
    //__block QredoClient *client = [[QredoClient alloc] initWithServiceURL:serviceURL
    //appCredentials:appCredentials
    //userCredentials:userCredentials];
    //
    
    
    
    //NSLog(@"QREDO: Attempt to conntect using %@ %@ %@", serviceURL, appCredentials, userCredentials);
    
    __block QredoClient *client = [[QredoClient alloc] initWithServiceURL:serviceURL
                                                           appCredentials:appCredentials
                                                          userCredentials:userCredentials];
    
    client.clientOptions = options;
    
    void (^completeAuthorization)(NSError *) = ^void (NSError *error) {
        if (error){
            if (error)QredoLogError(@"Failed to create client");
            
            if (completionHandler)completionHandler(nil,error);
        } else {
            //This assert is very important!!!
            if (!client.defaultVault)QredoLogError(@"No QredoClient without a system vault must be passed to the client code.");
            
            QredoLogInfo(@"Client Inialized");
            
            if (completionHandler)completionHandler(client,error);
        }
    };
    
    BOOL loaded = [client loadStateWithError:&error];
    
    if (!loaded){
        if ([error.domain isEqualToString:QredoErrorDomain] && error.code == QredoErrorCodeKeychainCouldNotBeFound){
            //New KeyChain is required
            
            error = nil;
            
            [client createSystemVaultWithUserCredentials:userCredentials
                                       completionHandler:^(NSError *error) {
                                           if (error) QredoLogError(@"Failed to create system vault");
                                           
                                           if (!error){
                                               [client saveStateWithError:&error];
                                           }
                                           
                                           completeAuthorization(error);
                                       }];
        } else {
            //TODO: [GR]: Show alert for corrupted keychain instead of the placeholder below.
            //Also implement a way of recovering a keychain here.
            
            QredoLogError(@"Critical error - possible keychain corruption");
        }
        
        return;
    }
    
    completeAuthorization(error);
}


-(instancetype)initWithServiceURL:(NSURL *)serviceURL
                   appCredentials:(QredoAppCredentials *)appCredentials
                  userCredentials:(QredoUserCredentials *)userCredentials {
    self = [self init];
    
    if (!self)return nil;
    
    _userCredentials = userCredentials;
    _appCredentials = appCredentials;
    _serviceURL = serviceURL;
    
    if (_serviceURL){
        _serviceInvoker = [[QredoServiceInvoker alloc] initWithServiceURL:_serviceURL appCredentials:appCredentials];
    }
    
    _rendezvousQueue = dispatch_queue_create("com.qredo.rendezvous",nil);
    
    return self;
}


-(void)dealloc {
    //Ensure that we close our session, even if caller forgot
    [self closeSession];
}


-(BOOL)isClosed {
    return _serviceInvoker.isTerminated;
}


-(BOOL)isAuthenticated {
    //rev 1 doesn't have authentication
    return YES;
}


-(void)closeSession {
    //Need to terminate transport, which ends associated threads and subscriptions etc.
    QredoLogInfo(@"Close session");
    [self.defaultVault purgeQueue];
    [self.systemVault purgeQueue];
    
    [self.defaultVault removeAllObservers];
    [self.systemVault removeAllObservers];

    [_serviceInvoker terminate];

    
    //TODO: DH - somehow indicate that the client has been closed and therefore cannot be used again.
}


-(QredoVault *)defaultVault {
    if (!_defaultVault){
        //should not happen, but just in case
        [self initializeVaults];
    }
    
    return _defaultVault;
}


#pragma mark -
#pragma mark Rendezvous



-(NSString *)appId {
    NSString *appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    
    if (!appID || [appID isEqualToString:@""]){
        appID = @"testtag";
    }
    
    return appID;
}


+(NSString *)randomStringWithLength:(int)len {
    NSString *letters = @"abcdefghjklmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
    
    for (int i = 0; i < len; i++){
        [randomString appendFormat:@"%C",[letters characterAtIndex:arc4random_uniform((int)[letters length])]];
    }
    
    return randomString;
}


-(NSData *)createTagWithSecurityLevel:(QredoSecurityLevel)securityLevel {
    NSData *key = [QredoUtils randomKey:securityLevel];
    
    return key;
}



#pragma Public Create Rendezvous

-(void)createAnonymousRendezvousWithTagType:(QredoSecurityLevel)tagSecurityLevel
                          completionHandler:(void (^)(QredoRendezvous *rendezvous,NSError *error))completionHandler {
    [self createAnonymousRendezvousWithTagType:tagSecurityLevel
                                      duration:0
                            unlimitedResponses:YES
                                 summaryValues:nil
                             completionHandler:completionHandler];
}



-(void)createAnonymousRendezvousWithTagType:(QredoSecurityLevel)tagSecurityLevel
                                   duration:(long)duration
                         unlimitedResponses:(BOOL)unlimitedResponses
                              summaryValues:summaryValues
                          completionHandler:(void (^)(QredoRendezvous *rendezvous,NSError *error))completionHandler {

    NSData *dataTag = [QredoUtils randomKey:tagSecurityLevel];
    NSString *tag = [QredoUtils dataToHexString:dataTag];

    QredoLogVerbose(@"Start createAnonymousRendezvousWithTag %@",tag);
    
    [self createAnonymousRendezvousWithTag:tag
                                  duration:duration
                        unlimitedResponses:unlimitedResponses
                             summaryValues:summaryValues
                         completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                                QredoLogInfo(@"CreatedAnonymousRendezvousWithTag %@",tag);
                                if (completionHandler) completionHandler(rendezvous,error);
                         }
     ];
}


#pragma Private Create Rendezvous - manually specified tag - removed from Public interface

-(void)createAnonymousRendezvousWithTag:(NSString *)tag
                               duration:(long)duration
                     unlimitedResponses:(BOOL)unlimitedResponses
                          summaryValues:summaryValues
                      completionHandler:(void (^)(QredoRendezvous *rendezvous,NSError *error))completionHandler {
    QredoLogVerbose(@"Start createAnonymousRendezvousWithTag %@",tag);
    QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc]
                                                   initWithConversationType:@""
                                                   durationSeconds:duration
                                                   summaryValues:summaryValues
                                                   isUnlimitedResponseCount:unlimitedResponses];
    
    [self makeRendezvousWithTag:tag
               authenticationType:QredoRendezvousAuthenticationTypeAnonymous
                    configuration:configuration
                   signingHandler:nil
                   appCredentials:self.appCredentials
                completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                    QredoLogInfo(@"CreatedAnonymousRendezvousWithTag %@",tag);
                    
                    if (completionHandler) completionHandler(rendezvous,error);
                }
     ];
}



-(void)makeRendezvousWithTag:(NSString *)tag
            authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                 configuration:(QredoRendezvousConfiguration *)configuration
                signingHandler:(signDataBlock)signingHandler
                appCredentials:(QredoAppCredentials *)appCredentials
             completionHandler:(void (^)(QredoRendezvous *rendezvous,NSError *error))completionHandler {
    
    QredoLogVerbose(@"Start createRendezvousWithTag %@",tag);
    
    dispatch_async(_rendezvousQueue,^{
        QredoRendezvous *rendezvous = [[QredoRendezvous alloc] initWithClient:self];
        QredoLogVerbose(@"Start createRendezvousWithTag on rendezvousQueue %@",tag);
        
        [rendezvous createRendezvousWithTag:tag
                         authenticationType:authenticationType
                              configuration:configuration
                             signingHandler:signingHandler
                             appCredentials:appCredentials
                          completionHandler:^(NSError *error) {
                              if (error){
                                  if (completionHandler) completionHandler(nil,error);
                              } else {
                                  if (completionHandler) completionHandler(rendezvous,error);
                              }
                          }];
        QredoLogVerbose(@"End createRendezvousWithTag on rendezvousQueue %@",tag);
    });
    
    QredoLogVerbose(@"End createRendezvousWithTag %@",tag);
}


-(QredoRendezvous *)rendezvousFromVaultItem:(QredoVaultItem *)vaultItem error:(NSError **)error {
    @try {
        QredoRendezvous *rendezvous = [[QredoRendezvous alloc] initWithVaultItem:self fromVaultItem:vaultItem];
        return rendezvous;
    } @catch (NSException *e){
        if (error){
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeRendezvousInvalidData
                                     userInfo:
                      @{
                        NSLocalizedDescriptionKey:@"Failed to extract rendezvous from the vault item",
                        NSUnderlyingErrorKey:e
                        }];
        }
        
        return nil;
    }
}


-(QredoConversation *)conversationFromVaultItem:(QredoVaultItem *)vaultItem error:(NSError **)error {
    @try {
        QLFConversationDescriptor *descriptor
        = [QredoPrimitiveMarshallers unmarshalObject:vaultItem.value
                                        unmarshaller:[QLFConversationDescriptor unmarshaller]];
        
        QredoConversation *conversation = [[QredoConversation alloc] initWithClient:self fromLFDescriptor:descriptor];
        
        [conversation loadHighestHWMWithCompletionHandler:nil];
        
        return conversation;
    } @catch (NSException *e){
        if (error){
            *error = [NSError errorWithDomain:QredoErrorDomain
                                         code:QredoErrorCodeConversationInvalidData
                                     userInfo:
                      @{
                        NSLocalizedDescriptionKey:@"Failed to extract conversation from the vault item",
                        NSUnderlyingErrorKey:e
                        }];
        }
        
        return nil;
    }
}


-(void)fetchRendezvousWithTag:(NSString *)tag completionHandler:(void (^)(QredoRendezvous *rendezvous,NSError *error))completionHandler {
    __block QredoRendezvousMetadata *matchedRendezvousMetadata;
    
    [self enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata,BOOL *stop) {
        if ([tag isEqualToString:rendezvousMetadata.tag]){
            matchedRendezvousMetadata = rendezvousMetadata;
            *stop = YES;
        }
    }
                     completionHandler:^(NSError *error) {
                         if (error){
                             QredoLogError(@"Fetch Rendezvous Error %@",error);
                             
                             if (completionHandler) completionHandler(nil,error);
                         } else if (!matchedRendezvousMetadata){
                             NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                                                  code:QredoErrorCodeRendezvousNotFound
                                                              userInfo:@{ NSLocalizedDescriptionKey:@"Rendezvous was not found in vault" }];
                             QredoLogError(@"Fetch Rendezvous Error %@",error);
                             
                             if (completionHandler) completionHandler(nil,error);
                         } else {
                             [self fetchRendezvousWithMetadata:matchedRendezvousMetadata
                                             completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                                                 QredoLogInfo(@"Fetch Rendezvous complete");
                                                 
                                                 if (completionHandler) completionHandler(rendezvous,error);
                                             }];
                         }
                     }];
}


-(void)enumerateRendezvousWithBlock:(void (^)(QredoRendezvousMetadata *rendezvousMetadata,BOOL *stop))block
                  completionHandler:(void (^)(NSError *error))completionHandler {
    QredoVault *vault = [self systemVault];

    //Changed to use the INDEX!
     NSPredicate *predicate = [NSPredicate predicateWithFormat:@" 1 == 1 "];
    [vault enumerateIndexUsingPredicate:predicate withBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stopVaultEnumeration) {
    //[vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stopVaultEnumeration) {
        
        
        
        if ([vaultItemMetadata.dataType
             isEqualToString:kQredoRendezvousVaultItemType]){
            NSString *tag = [vaultItemMetadata.summaryValues
                             objectForKey:kQredoRendezvousVaultItemLabelTag];
            QredoRendezvousAuthenticationType authenticationType  = [[vaultItemMetadata.summaryValues
                                                                      objectForKey:kQredoRendezvousVaultItemLabelAuthenticationType] intValue];
            
            QredoRendezvousRef *rendezvousRef = [[QredoRendezvousRef alloc]    initWithVaultItemDescriptor:vaultItemMetadata.descriptor
                                                                                                     vault:vault];
            
            QredoRendezvousMetadata *metadata = [[QredoRendezvousMetadata alloc]    initWithTag:tag
                                                                             authenticationType:authenticationType
                                                                                  rendezvousRef:rendezvousRef
                                                                                  summaryValues:vaultItemMetadata.summaryValues];
            
            BOOL stopObjectEnumeration = NO; //here we lose the feature when *stop == YES, then we are on the last object
            block(metadata,&stopObjectEnumeration);
            *stopVaultEnumeration = stopObjectEnumeration;
        }
    }
                       completionHandler:^(NSError *error) {
                           QredoLogInfo(@"Enumerate Rendezvous complete");
                           
                           if (completionHandler) completionHandler(error);
                       }];
}


-(void)fetchRendezvousWithRef:(QredoRendezvousRef *)ref
            completionHandler:(void (^)(QredoRendezvous *rendezvous,NSError *error))completionHandler {
    //an unknown ref will throw an exception, but catch a nil ref here
    if (ref == nil){
        NSString *message = @"'The RendezvousRef must not be nil";
        QredoLogError(@"fetchRendezvousWithRef - RendezvousRef must not be nil ");
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey:message }];
        
        if (completionHandler)completionHandler(nil,error);
        
        return;
    }
    
    [self fetchRendezvousWithVaultItemDescriptor:ref.vaultItemDescriptor completionHandler:completionHandler];
}


-(void)fetchRendezvousWithMetadata:(QredoRendezvousMetadata *)metadata
                 completionHandler:(void (^)(QredoRendezvous *rendezvous,NSError *error))completionHandler {
    [self fetchRendezvousWithRef:metadata.rendezvousRef completionHandler:completionHandler];
}


//private method
-(void)fetchRendezvousWithVaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor
                            completionHandler:(void (^)(QredoRendezvous *rendezvous,NSError *error))completionHandler {
    QredoVault *vault = [self systemVault];
    
    [vault getItemWithDescriptor:vaultItemDescriptor
               completionHandler:^(QredoVaultItem *vaultItem,NSError *error) {
                   if (error){
                       QredoLogError(@"Fetch Rendezvous Error %@",error);
                       
                       if (completionHandler) completionHandler(nil,error);
                       
                       return;
                   }
                   
                   NSError *parsingError = nil;
                   QredoRendezvous *rendezvous = [self  rendezvousFromVaultItem:vaultItem
                                                                          error:&parsingError];
                   QredoLogInfo(@"Fetch Rendezvous complete");
                   
                   if (completionHandler) completionHandler(rendezvous,parsingError);
               }];
}


-(void)respondWithTag:(NSString *)tag
    completionHandler:(void (^)(QredoConversation *conversation,NSError *error))completionHandler {
    NSAssert(completionHandler,@"completionHandler should not be nil");
    
    dispatch_async(_rendezvousQueue,^{
        QredoConversation *conversation = [[QredoConversation alloc] initWithClient:self];
        [conversation respondToRendezvousWithTag:tag
                                  appCredentials:self.appCredentials
                               completionHandler:^(NSError *error) {
                                   if (error){
                                       if (completionHandler) completionHandler(nil,error);
                                   } else {
                                       if (completionHandler) completionHandler(conversation,nil);
                                   }
                               }];
    });
}


-(void)enumerateConversationsWithBlock:(void (^)(QredoConversationMetadata *conversationMetadata,BOOL *stop))block
                     completionHandler:(void (^)(NSError *error))completionHandler {
    QredoVault *vault = [self systemVault];
    
    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata,BOOL *stopVaultEnumeration) {
        if ([vaultItemMetadata.dataType isEqualToString:kQredoConversationVaultItemType]){
            QredoConversationMetadata *metadata = [[QredoConversationMetadata alloc] init];
            //TODO: DH - populate metadata.rendezvousMetadata
            metadata.conversationId = [vaultItemMetadata.summaryValues
                                       objectForKey:kQredoConversationVaultItemLabelId];
            metadata.amRendezvousOwner = [[vaultItemMetadata.summaryValues
                                           objectForKey:kQredoConversationVaultItemLabelAmOwner] boolValue];
            metadata.type = [vaultItemMetadata.summaryValues
                             objectForKey:kQredoConversationVaultItemLabelType];
            metadata.rendezvousTag = [vaultItemMetadata.summaryValues
                                      objectForKey:kQredoConversationVaultItemLabelTag];
            metadata.conversationRef = [[QredoConversationRef alloc]    initWithVaultItemDescriptor:vaultItemMetadata.descriptor
                                                                                              vault:vault];
            metadata.summaryValues =  vaultItemMetadata.summaryValues;
            
            BOOL stopObjectEnumeration = NO; //here we lose the feature when *stop == YES, then we are on the last object
            
            block(metadata,&stopObjectEnumeration);
            *stopVaultEnumeration = stopObjectEnumeration;
        }
    }
                       completionHandler:^(NSError *error) {
                           QredoLogInfo(@"Enumermate Conversation Complete");
                           
                           if (completionHandler) completionHandler(error);
                       }];
}


-(void)fetchConversationWithRef:(QredoConversationRef *)conversationRef
              completionHandler:(void (^)(QredoConversation *conversation,NSError *error))completionHandler {
    QredoVault *vault = [self systemVault];
    
    [vault getItemWithDescriptor:conversationRef.vaultItemDescriptor
               completionHandler:^(QredoVaultItem *vaultItem,NSError *error) {
                   if (error){
                       if (completionHandler) completionHandler(nil,error);
                       
                       return;
                   }
                   
                   NSError *parsingError = nil;
                   QredoConversation *conversation = [self  conversationFromVaultItem:vaultItem
                                                                                error:&parsingError];
                   conversation.metadata.conversationRef = conversationRef;
                   conversation.metadata.summaryValues = vaultItem.metadata.summaryValues;
                   QredoLogInfo(@"Fetch Conversation with Ref complete");
                   
                   if (completionHandler) completionHandler(conversation,parsingError);
               }];
}


-(void)deleteConversationWithRef:(QredoConversationRef *)conversationRef
               completionHandler:(void (^)(NSError *error))completionHandler{
    [self fetchConversationWithRef:conversationRef
                 completionHandler:^(QredoConversation *conversation,NSError *error){
         if (error){
             if (completionHandler) completionHandler(error);
             
             return;
         }
         
         [conversation deleteConversationWithCompletionHandler:completionHandler];
     }];
}


-(void)activateRendezvousWithRef:(QredoRendezvousRef *)ref
                        duration:(long)duration
               completionHandler:(void (^)(QredoRendezvous *rendezvous,NSError *error))completionHandler {
    if (completionHandler == nil){
        NSException *myException = [NSException
                                    exceptionWithName:@"NilCompletionHandler"
                                    reason:@"CompletionHandlerisNil"
                                    userInfo:nil];
        @throw myException;
    }
    
    //validate that the duration is >= 0 and that the RendezvousRef is not nil
    if (duration < 0){
        NSString *message =  @"'The Rendezvous duration must not be negative";
        
        QredoLogError(@"%@",message);
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey:message }];
        
        if (completionHandler)completionHandler(nil,error);
        
        return;
    }
    
    //get the Rendezvous using the ref
    [self fetchRendezvousWithRef:ref
               completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                   if (error){
                       if (completionHandler) completionHandler(nil,error);
                       
                       return;
                   }
                   
                   [rendezvous  activateRendezvous:duration
                                 completionHandler:^(NSError *error) {
                                     if (error){
                                         if (completionHandler) completionHandler(nil,error);
                                         
                                         QredoLogError(@"Failed to activate Rendezvous");
                                     } else {
                                         if (completionHandler) completionHandler(rendezvous,nil);
                                     }
                                 }
                    ];
               }
     ];
}


-(void)deactivateRendezvousWithRef:(QredoRendezvousRef *)ref
                 completionHandler:(void (^)(NSError *))completionHandler {
    if (completionHandler == nil){
        NSException *myException = [NSException
                                    exceptionWithName:@"NilCompletionHandler"
                                    reason:@"CompletionHandlerisNil"
                                    userInfo:nil];
        @throw myException;
    }
    
    //get the Rendezvous using the ref
    [self fetchRendezvousWithRef:ref completionHandler:^(QredoRendezvous *rendezvous,NSError *error) {
                   if (error){
                       if (completionHandler) completionHandler(error);
                       return;
                   }
                   
                   [rendezvous deactivateRendezvous:^(NSError *error) {
                       QredoLogInfo(@"Rendezvous deactivated");
                       
                       if (completionHandler) completionHandler(error);
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
    
    QredoVaultItemMetadata *metadata = [QredoVaultItemMetadata vaultItemMetadataWithSummaryValues:@{
                    QredoVaultItemSummaryKeyDeviceName:[self deviceName]
    }];
    
    QredoVaultItem *deviceInfoItem = [QredoVaultItem vaultItemWithMetadata:metadata value:nil];
    
    [systemVault  putItem:deviceInfoItem completionHandler:^(__unused QredoVaultItemMetadata *newItemMetadata,NSError *error){
         if (completionHandler) completionHandler(error);
    }];
}


-(BOOL)saveStateWithError:(NSError **)error {
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    return [self saveSystemVaultKeychain:_keychain withKeychainWithKeychainArchiver:keychainArchiver error:error];
}


-(BOOL)loadStateWithError:(NSError **)error {
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    QredoKeychain *systemVaultKeychain = [self loadSystemVaultKeychainWithKeychainArchiver:keychainArchiver error:error];
    
    if (systemVaultKeychain){
        _keychain = systemVaultKeychain;
        [self initializeVaults];
        return YES;
    }
    return NO;
}


-(BOOL)deleteCurrentDataWithError:(NSError **)error {
    if (!_systemVault || !_defaultVault){
        return YES;
    }
    [_systemVault clearAllData];
    [_defaultVault clearAllData];
    return [self deleteDefaultVaultKeychainWithError:error];
}


-(void)createSystemVaultWithUserCredentials:(QredoUserCredentials *)userCredentials completionHandler:(void (^)(NSError *error))completionHandler {
    _userCredentials = userCredentials;
    [self deleteCurrentDataWithError:nil];
    [self createDefaultKeychain:userCredentials];
    [self initializeVaults];
    [self addDeviceToVaultWithCompletionHandler:completionHandler];
}


-(void)initializeVaults {
    _systemVault = [[QredoVault alloc] initWithClient:self vaultKeys:_keychain.systemVaultKeys withLocalIndex:YES  vaultType:QredoSystemVault];
    //always add an observer for the system vault
    [_systemVault addMetadataIndexObserver];
    BOOL withIndex = !self.clientOptions.disableMetadataIndex;
    _defaultVault = [[QredoVault alloc] initWithClient:self vaultKeys:_keychain.defaultVaultKeys withLocalIndex:withIndex  vaultType:QredoDefaultVault];
}


-(id<QredoKeychainArchiver>)qredoKeychainArchiver {
    return [QredoKeychainArchivers defaultQredoKeychainArchiver];
}


-(void)createDefaultKeychain:(QredoUserCredentials *)userCredentials {
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




-(QredoKeychain *)loadSystemVaultKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver
                                                        error:(NSError **)error {
    return [keychainArchiver loadQredoKeychainWithIdentifier:systemVaultKeychainArchiveIdentifier error:error];
}


-(BOOL)      saveSystemVaultKeychain:(QredoKeychain *)keychain
    withKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver
                               error:(NSError **)error {
    return [keychainArchiver saveQredoKeychain:keychain
                                withIdentifier:systemVaultKeychainArchiveIdentifier
                                         error:error];
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



+(KeychainItemWrapper*)keychainItemWrapperGroup:(NSString*)keyChainGroup;{
    NSString *keyChainID = [NSString stringWithFormat:@"%@.qredoClientCredentials", keyChainGroup];
    NSString *accessGroup = [NSString stringWithFormat:@"%@.%@", [QredoClient bundleSeedID], keyChainGroup];
    return [[KeychainItemWrapper alloc] initWithIdentifier:keyChainID accessGroup:accessGroup];
}



-(void)saveCredentialsInUserDefaults{
    NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
    if (self.clientOptions.appGroup)userdefaults = [[NSUserDefaults alloc] initWithSuiteName:self.clientOptions.appGroup];

    NSDictionary *credentials = [NSDictionary dictionaryWithObjectsAndKeys:
                                 self.appCredentials.appId,QredoStoredAppIDKey,
                                 [self.appCredentials.appSecret hexadecimalString], QredoStoredAppSecretKey,
                                 self.userCredentials.userId, QredoStoredUserIDKey,
                                 self.userCredentials.userSecure, QredoStoredUserSecretKey,
                                 self.clientOptions, QredoStoredOptions,
                                 nil];
    //serialize to nsdata
    NSData *credentialData = [NSKeyedArchiver archivedDataWithRootObject:credentials];
    [userdefaults setObject:credentialData forKey:QredoStoredUserDefautlCredentialsKey];
    [userdefaults synchronize];
}


+(BOOL)hasCredentialsInUserDefaultsAppGroup:(NSString*)appGroup{
    NSDictionary *dict = [self retrieveCredentialsUserDefaultsAppGroup:appGroup];
    if (!dict)return NO;
    if ([dict objectForKey:QredoStoredAppIDKey] &&
        [dict objectForKey:QredoStoredAppSecretKey] &&
        [dict objectForKey:QredoStoredUserIDKey] &&
        [dict objectForKey:QredoStoredUserSecretKey]) {
        return YES;
    }else{
        return NO;
    }
}


+(void)deleteCredentialsInUserDefaultsAppGroup:(NSString*)appGroup{
    NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
    if (appGroup)userdefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroup];
    [userdefaults setObject:nil forKey:QredoStoredUserDefautlCredentialsKey];
    [userdefaults synchronize];
}


+(NSDictionary*)retrieveCredentialsUserDefaultsAppGroup:(NSString*)appGroup{
    NSUserDefaults *userdefaults;
    if (appGroup){
        userdefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroup];
    }else{
        userdefaults = [NSUserDefaults standardUserDefaults];
    }
    
    NSData *credentialData = [userdefaults objectForKey:QredoStoredUserDefautlCredentialsKey];
    if ([credentialData length]==0)return nil;
    
    NSDictionary *credentials = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:credentialData];
    return credentials;
}

-(void)saveCredentialsInKeychain{
    KeychainItemWrapper *keychain = [QredoClient keychainItemWrapperGroup:self.clientOptions.keyChainGroup];
    [keychain resetKeychainItem];
    NSDictionary *credentials = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self.appCredentials.appId,QredoStoredAppIDKey,
                                    [self.appCredentials.appSecret hexadecimalString], QredoStoredAppSecretKey,
                                    self.userCredentials.userId, QredoStoredUserIDKey,
                                    self.userCredentials.userSecure, QredoStoredUserSecretKey,
                                    self.clientOptions, QredoStoredOptions,
                                    nil];
    //serialize to nsdata
    NSData *credentialData = [NSKeyedArchiver archivedDataWithRootObject:credentials];
    //Sotre in keychain
    [keychain setObject:credentialData forKey:(__bridge id)kSecValueData];
}


+(BOOL)hasCredentialsInKeychainGroup:(NSString *)keyChainGroup{
    NSDictionary *dict = [QredoClient retrieveCredentialsFromKeychainGroup:keyChainGroup];
    if (!dict)return NO;
    if ([dict objectForKey:QredoStoredAppIDKey] &&
        [dict objectForKey:QredoStoredAppSecretKey] &&
        [dict objectForKey:QredoStoredUserIDKey] &&
        [dict objectForKey:QredoStoredUserSecretKey]) {
        return YES;
    }else{
     return NO;
    }
}


+(void)deleteCredentialsInKeychainGroup:(NSString *)keyChainGroup{
    KeychainItemWrapper *keychain = [QredoClient keychainItemWrapperGroup:keyChainGroup];
    [keychain resetKeychainItem];
}


+(NSDictionary*)retrieveCredentialsFromKeychainGroup:(NSString *)keyChainGroup{
    KeychainItemWrapper *keychain = [QredoClient keychainItemWrapperGroup:keyChainGroup];
    NSData *credentialData = [keychain objectForKey:(__bridge id)(kSecValueData)];
    if ([credentialData length]==0)return nil;
    NSDictionary *credentials = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:credentialData];
    return credentials;
}


+(NSString *)bundleSeedID {
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, (__bridge NSString *)kSecClass,
                           @"bundleSeedID", kSecAttrAccount,
                           @"", kSecAttrService,
                           (id)kCFBooleanTrue, kSecReturnAttributes,
                           nil];
    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status == errSecItemNotFound){
        status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    }
    if (status != errSecSuccess){
        return nil;
    }
    NSString *accessGroup = [(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kSecAttrAccessGroup];
    NSArray *components = [accessGroup componentsSeparatedByString:@"."];
    NSString *bundleSeedID = [[components objectEnumerator] nextObject];
    CFRelease(result);
    return bundleSeedID;
}

@end



//@implementation QredoClient (Pseudonym)
//
//+(QredoPseudonym *)create:(NSString *)localName{
//    //Create system vault item for Pseudonym
//    return nil;
//}
//
//
//+ (void)destroy:(QredoPseudonym *)pseudonym{
//    //delete from sys vault
//}
//
//
//+ (bool)exists:(NSString *)localName{
//    // return bool on (QredoPseudonym *)get:(NSString *)localName
//    return nil;
//}
//
//
//+ (QredoPseudonym *)get:(NSString *)localName{
//    //loop Pseudonyms in sys vault and return
//    return nil;
//}
//
//+ (NSArray *)list{
//    //return array of all current (not deleted) QredoPseudonym
//    return nil;
//}
//
//@end
