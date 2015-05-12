/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "Qredo.h"
#import "QredoPrivate.h"
#import "QredoVault.h"
#import "QredoVaultPrivate.h"
#import "QredoRendezvousPrivate.h"
#import "QredoConversationPrivate.h"

#import "QredoPrimitiveMarshallers.h"
#import "QredoServiceInvoker.h"
#import "QredoLogging.h"

#import "QredoKeychain.h"
#import "QredoKeychainArchiver.h"
#import "QredoKeychainSender.h"
#import "QredoKeychainReceiver.h"
#import "NSData+QredoRandomData.h"
#import "QredoManagerAppRootViewController.h"
#import "QredoCertificate.h"

// TEMP
#import "QredoConversationProtocol.h"


#import <UIKit/UIKit.h>

NSString *const QredoVaultItemTypeKeychain = @"com.qredo.keychain.device-name";
NSString *const QredoVaultItemTypeKeychainAttempt = @"com.qredo.keychain.transfer-attempt";
NSString *const QredoVaultItemSummaryKeyDeviceName = @"device-name";


NSString *const QredoClientOptionCreateNewSystemVault = @"com.qredo.option.create.new.system.vault";
NSString *const QredoClientOptionServiceURL = @"com.qredo.option.serviceUrl";

//static NSString *const QredoClientDefaultServiceURL = @"http://dev.qredo.me:8080/services";
static NSString *const QredoClientDefaultServiceURL = @"https://dev.qredo.me:443/services";

//static NSString *const QredoClientMQTTServiceURL = @"tcp://dev.qredo.me:1883";
static NSString *const QredoClientMQTTServiceURL = @"ssl://dev.qredo.me:8883";

static NSString *const QredoClientWebSocketsServiceURL = @"wss://dev.qredo.me:443/services";

NSString *const QredoRendezvousURIProtocol = @"qrp:";


static NSString *const QredoKeychainOperatorName = @"Qredo Mock Operator";
static NSString *const QredoKeychainOperatorAccountId = @"1234567890";
static NSString *const QredoKeychainPassword = @"Password123";



@implementation QredoClientOptions
{
    QredoCertificate *_certificate;
}

- (instancetype)init
{
    self = [super init];
    NSAssert(FALSE, @"Please use [QredoClientOptions initWithPinnedCertificate:] in stead of init without arguments]");
    self = nil;
    return self;
}

- (instancetype)initWithDefaultTrustedRoots
{
    self = [super init];
    if (self) {
        _certificate = nil;
    }
    return self;
}

- (instancetype)initDefaultPinnnedCertificate
{
    self = [super init];
    if (self) {
        _certificate = [self createDefaultPinnedCertificate];
    }
    return self;
}

- (instancetype)initWithPinnedCertificate:(QredoCertificate *)certificate
{
    self = [super init];
    if (self) {
        NSAssert(certificate, @"In -initWithPinnedCertificate: a certificate must be provided.");
        _certificate = certificate;
    }
    return self;
}

- (QredoCertificate *)certificate
{
    return _certificate;
}


- (QredoCertificate *)createDefaultPinnedCertificate
{
    /* 
     
     This is the server self signed test certificate using an RSA Public Key: (1024 bit).
     
        Certificate:
            Data:
                Version: 1 (0x0)
                Serial Number: 1 (0x1)
                Signature Algorithm: sha1WithRSAEncryption
                Issuer: C=GB, ST=Some-State, L=London, O=Qredo Ltd, CN=*.qredo.me
                Validity
                    Not Before: Jan 27 11:36:07 2015 GMT
                    Not After : Jan 27 11:36:07 2016 GMT
                Subject: C=GB, ST=Some-State, L=London, O=Qredo Ltd, CN=*.qredo.me
                Subject Public Key Info:
                    Public Key Algorithm: rsaEncryption
                    RSA Public Key: (1024 bit)
                        Modulus (1024 bit):
                            00:a6:36:ad:40:85:fa:a5:77:80:aa:fe:b1:58:06:
                            8a:6d:d6:5b:38:1b:9a:e3:55:97:de:75:3c:42:b0:
                            4e:34:a2:8b:a2:a6:d1:b3:bb:16:1b:48:7c:ab:c5:
                            ce:07:ed:01:79:04:c2:9a:75:1d:44:6b:41:de:00:
                            dd:62:88:b0:01:33:c2:3d:18:5b:93:d1:78:37:69:
                            ca:c4:66:41:1b:4a:4e:cc:27:83:1d:e6:dd:5e:e4:
                            b3:bb:2f:77:48:8d:bb:87:2c:6d:91:f4:ac:32:f6:
                            a0:61:d8:37:e6:c9:20:83:bf:c4:af:4c:02:9d:ef:
                            46:fb:77:b5:c4:50:fb:ea:43
                        Exponent: 65537 (0x10001)
            Signature Algorithm: sha1WithRSAEncryption
                51:6a:10:5e:85:31:bf:b7:31:54:50:27:8f:f6:9b:79:6d:a7:
                a0:9f:5d:fa:7e:58:c6:99:cb:32:4e:ac:33:b4:a0:bb:7d:80:
                6b:1b:08:29:ca:73:a3:c2:34:4e:97:da:a0:9f:e4:95:7a:12:
                f6:35:c1:34:59:0b:ed:66:9c:10:85:da:e3:e4:3f:22:23:16:
                57:41:b1:fe:c7:00:7a:51:14:f5:f3:20:1f:f3:7c:9f:6a:d8:
                b6:9b:28:2e:05:0a:b1:60:de:94:b1:e8:48:05:be:1f:5f:b6:
                4c:81:72:5f:36:fb:d8:89:34:61:d0:65:f1:ed:23:ca:de:e8:
                27:aa:55:f4:18:df:2e:b3:08:8d:43:b4:a5:d5:4e:94:19:69:
                84:33:de:dc:c9:dc:53:48:ab:1c:ef:96:63:75:3c:c2:d3:3b:
                bc:22:82:36:9b:61:17:be:b7:20:44:53:5b:04:27:8f:77:c4:
                46:ea:69:69:6f:ce:a5:8e:ef:e6:54:4f:56:b3:fb:cc:0d:a3:
                a6:dd:27:dd:df:8a:ae:7e:c8:8f:83:53:33:52:47:4a:11:d4:
                13:e6:2b:16:2f:66:f0:92:44:4d:dc:94:9b:78:ff:4f:43:95:
                fc:47:6c:17:d4:ed:d5:8a:b8:c4:0e:41:68:d6:86:f2:89:1d:
                26:30:47:73:12:83:b1:ed:01:40:29:9c:25:9c:7b:23:87:f7:
                e7:94:79:9d:84:b1:b9:ef:a6:82:30:1c:3b:7d:4e:6f:ce:c6:
                98:05:7c:1b:25:91:85:f0:88:26:04:01:40:0c:13:31:ff:58:
                73:65:ba:24:fd:b6:32:bb:47:66:73:89:c9:d7:24:5d:a6:63:
                3f:e2:d0:11:35:38:bf:55:33:82:ab:40:87:7e:3e:9e:fe:96:
                31:8d:d5:c6:8a:d3:b3:36:aa:b1:42:c3:29:e6:86:3a:1d:30:
                d2:57:c5:8d:fa:05:ba:3a:56:5b:1e:82:6e:36:fa:a5:61:ed:
                a1:4d:c3:ee:8b:c3:7d:0c:31:10:38:1f:6d:88:20:58:e1:ef:
                d2:75:02:ad:95:5d:bc:7a:25:47:f8:eb:7b:0e:14:56:f6:47:
                8c:8b:08:3f:2f:90:eb:7b:19:33:c2:91:d9:8e:e8:48:7b:3e:
                61:d2:4b:28:a5:54:01:7c:03:73:5a:14:8c:22:a7:ec:a3:cd:
                de:6e:f0:40:39:d0:0b:74:3c:7c:41:9d:37:80:37:26:e5:fd:
                62:2b:07:aa:f6:1f:44:97:53:d1:a1:f6:4d:f2:a0:9d:d0:52:
                da:47:d5:9e:6d:76:6b:ac:c4:a7:40:8a:3f:04:41:35:b7:e9:
                35:85:37:e2:74:7e:d2:d5
     
        -----BEGIN CERTIFICATE-----
        MIIDqDCCAZACAQEwDQYJKoZIhvcNAQEFBQAwXDELMAkGA1UEBhMCR0IxEzARBgNV
        BAgTClNvbWUtU3RhdGUxDzANBgNVBAcTBkxvbmRvbjESMBAGA1UEChMJUXJlZG8g
        THRkMRMwEQYDVQQDFAoqLnFyZWRvLm1lMB4XDTE1MDEyNzExMzYwN1oXDTE2MDEy
        NzExMzYwN1owXDELMAkGA1UEBhMCR0IxEzARBgNVBAgTClNvbWUtU3RhdGUxDzAN
        BgNVBAcTBkxvbmRvbjESMBAGA1UEChMJUXJlZG8gTHRkMRMwEQYDVQQDFAoqLnFy
        ZWRvLm1lMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCmNq1Ahfqld4Cq/rFY
        Bopt1ls4G5rjVZfedTxCsE40oouiptGzuxYbSHyrxc4H7QF5BMKadR1Ea0HeAN1i
        iLABM8I9GFuT0Xg3acrEZkEbSk7MJ4Md5t1e5LO7L3dIjbuHLG2R9Kwy9qBh2Dfm
        ySCDv8SvTAKd70b7d7XEUPvqQwIDAQABMA0GCSqGSIb3DQEBBQUAA4ICAQBRahBe
        hTG/tzFUUCeP9pt5baegn136fljGmcsyTqwztKC7fYBrGwgpynOjwjROl9qgn+SV
        ehL2NcE0WQvtZpwQhdrj5D8iIxZXQbH+xwB6URT18yAf83yfati2myguBQqxYN6U
        sehIBb4fX7ZMgXJfNvvYiTRh0GXx7SPK3ugnqlX0GN8uswiNQ7Sl1U6UGWmEM97c
        ydxTSKsc75ZjdTzC0zu8IoI2m2EXvrcgRFNbBCePd8RG6mlpb86lju/mVE9Ws/vM
        DaOm3Sfd34qufsiPg1MzUkdKEdQT5isWL2bwkkRN3JSbeP9PQ5X8R2wX1O3VirjE
        DkFo1obyiR0mMEdzEoOx7QFAKZwlnHsjh/fnlHmdhLG576aCMBw7fU5vzsaYBXwb
        JZGF8IgmBAFADBMx/1hzZbok/bYyu0dmc4nJ1yRdpmM/4tARNTi/VTOCq0CHfj6e
        /pYxjdXGitOzNqqxQsMp5oY6HTDSV8WN+gW6OlZbHoJuNvqlYe2hTcPui8N9DDEQ
        OB9tiCBY4e/SdQKtlV28eiVH+Ot7DhRW9keMiwg/L5DrexkzwpHZjuhIez5h0kso
        pVQBfANzWhSMIqfso83ebvBAOdALdDx8QZ03gDcm5f1iKweq9h9El1PRofZN8qCd
        0FLaR9WebXZrrMSnQIo/BEE1t+k1hTfidH7S1Q==
        -----END CERTIFICATE-----
     
     */
    NSString *base64EncodedDerCertificateData
    = @"MIIDqDCCAZACAQEwDQYJKoZIhvcNAQEFBQAwXDELMAkGA1UEBhMCR0IxEzARBgNV\
    BAgTClNvbWUtU3RhdGUxDzANBgNVBAcTBkxvbmRvbjESMBAGA1UEChMJUXJlZG8g\
    THRkMRMwEQYDVQQDFAoqLnFyZWRvLm1lMB4XDTE1MDEyNzExMzYwN1oXDTE2MDEy\
    NzExMzYwN1owXDELMAkGA1UEBhMCR0IxEzARBgNVBAgTClNvbWUtU3RhdGUxDzAN\
    BgNVBAcTBkxvbmRvbjESMBAGA1UEChMJUXJlZG8gTHRkMRMwEQYDVQQDFAoqLnFy\
    ZWRvLm1lMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCmNq1Ahfqld4Cq/rFY\
    Bopt1ls4G5rjVZfedTxCsE40oouiptGzuxYbSHyrxc4H7QF5BMKadR1Ea0HeAN1i\
    iLABM8I9GFuT0Xg3acrEZkEbSk7MJ4Md5t1e5LO7L3dIjbuHLG2R9Kwy9qBh2Dfm\
    ySCDv8SvTAKd70b7d7XEUPvqQwIDAQABMA0GCSqGSIb3DQEBBQUAA4ICAQBRahBe\
    hTG/tzFUUCeP9pt5baegn136fljGmcsyTqwztKC7fYBrGwgpynOjwjROl9qgn+SV\
    ehL2NcE0WQvtZpwQhdrj5D8iIxZXQbH+xwB6URT18yAf83yfati2myguBQqxYN6U\
    sehIBb4fX7ZMgXJfNvvYiTRh0GXx7SPK3ugnqlX0GN8uswiNQ7Sl1U6UGWmEM97c\
    ydxTSKsc75ZjdTzC0zu8IoI2m2EXvrcgRFNbBCePd8RG6mlpb86lju/mVE9Ws/vM\
    DaOm3Sfd34qufsiPg1MzUkdKEdQT5isWL2bwkkRN3JSbeP9PQ5X8R2wX1O3VirjE\
    DkFo1obyiR0mMEdzEoOx7QFAKZwlnHsjh/fnlHmdhLG576aCMBw7fU5vzsaYBXwb\
    JZGF8IgmBAFADBMx/1hzZbok/bYyu0dmc4nJ1yRdpmM/4tARNTi/VTOCq0CHfj6e\
    /pYxjdXGitOzNqqxQsMp5oY6HTDSV8WN+gW6OlZbHoJuNvqlYe2hTcPui8N9DDEQ\
    OB9tiCBY4e/SdQKtlV28eiVH+Ot7DhRW9keMiwg/L5DrexkzwpHZjuhIez5h0kso\
    pVQBfANzWhSMIqfso83ebvBAOdALdDx8QZ03gDcm5f1iKweq9h9El1PRofZN8qCd\
    0FLaR9WebXZrrMSnQIo/BEE1t+k1hTfidH7S1Q==";
    
    NSData *derCertificateData
    = [[NSData alloc] initWithBase64EncodedString:base64EncodedDerCertificateData
                                          options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    SecCertificateRef secCert = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)(derCertificateData));
    QredoCertificate *qredoCert = [QredoCertificate certificateWithSecCertificateRef:secCert];
    
    return qredoCert;
}

@end

// Private stuff
@interface QredoClient ()
{
    QredoVault *_systemVault;
    QredoVault *_defaultVault;
    QredoServiceInvoker *_serviceInvoker;
    QredoKeychain *_keychain;

    dispatch_queue_t _rendezvousQueue;
}

@property NSURL *serviceURL;

/** Creates instance of qredo client
 @param serviceURL Root URL for Qredo services
 */
- (instancetype)initWithServiceURL:(NSURL *)serviceURL;


@end

@implementation QredoClient

- (QredoVault*)systemVault
{
    // For rev1 we have only one vault
    // Keeping this method as a placeholder and it is used in Rendezvous and Conversations
    return _systemVault;
}

- (QredoKeychain *)keychain {
    return _keychain;
}

- (QredoServiceInvoker*)serviceInvoker {
    return _serviceInvoker;
}

+ (void)authorizeWithConversationTypes:(NSArray*)conversationTypes
                        vaultDataTypes:(NSArray*)vaultDataTypes
                     completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler
{
    [self authorizeWithConversationTypes:conversationTypes
                          vaultDataTypes:vaultDataTypes
                                 options:nil
                       completionHandler:completionHandler];
}

+ (void)authorizeWithConversationTypes:(NSArray*)conversationTypes
                        vaultDataTypes:(NSArray*)vaultDataTypes options:(QredoClientOptions*)options
                     completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler
{
    // TODO: DH - Update to display the QredoClientOptions contents, now it's no longer a dictionary
    LogDebug(@"Authorising client for conversation types: %@. VaultDataTypes: %@. Options: %@.", conversationTypes, vaultDataTypes, options);

    if (!options) {
        options = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    }
    
    NSURL *serviceURL = nil;
    switch (options.transportType) {
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
    
    __block NSError *error = nil;
    
    __block QredoClient *client = [[QredoClient alloc] initWithServiceURL:serviceURL pinnedCertificate:options.certificate];
    
    void(^completeAuthorization)() = ^() {
        
        if (error) {
            if (completionHandler) completionHandler(nil, error);
        } else {
            // This assert is very important!!!
            NSAssert(client.defaultVault, @"No QredoClient without a system vault must be passed to the client code.");
            if (completionHandler) completionHandler(client, error);
        }
        
    };
    
    
    if (options.resetData) {
        
        [client createSystemVaultWithCompletionHandler:^(NSError *error) {
            if (!error) {
                [client saveStateWithError:&error];
            }

            completeAuthorization();
        }];

        return;
        
    }
    
    
    if (![client loadStateWithError:&error]) {
        
        if ([error.domain isEqualToString:QredoErrorDomain] && error.code == QredoErrorCodeKeychainCouldNotBeFound) {
            
            // TODO: [GR]: Show new device screen insted of creating the vault starit away.
            error = nil;
            [client createSystemVaultWithCompletionHandler:^(NSError *error) {
                if (!error) {
                    [client saveStateWithError:&error];
                }

                completeAuthorization();
            }];

        } else {
            
            // TODO: [GR]: Show alert for corrupted keychain instead of the placeholder below.
            // Also implement a way of recovering a keychian here.
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIAlertController *alertController
                = [UIAlertController alertControllerWithTitle:@"Keychain is corrupted"
                                                      message:@"The system vault keychain seems to be corrupted."
                                               preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:
                 [UIAlertAction actionWithTitle:@"Try later"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action)
                  {
                      completeAuthorization();
                  }]];
                
                [alertController addAction:
                 [UIAlertAction actionWithTitle:@"Remove keychain"
                                          style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *action)
                  {
                      [client createSystemVaultWithCompletionHandler:^(NSError *error) {
                          if (!error) {
                              [client saveStateWithError:&error];
                          }
                          
                          completeAuthorization();
                      }];
                  }]];
                
                [[UIApplication sharedApplication].keyWindow.rootViewController
                 presentViewController:alertController animated:YES completion:nil];
            });
            
        }
        
        return;
        
    }
    
    completeAuthorization();
    
}

+ (void)openSettings
{
    QredoManagerAppRootViewController *managerAppRootViewController = [[QredoManagerAppRootViewController alloc] init];
    [managerAppRootViewController show];
}


- (instancetype)initWithServiceURL:(NSURL *)serviceURL
{
    return [self initWithServiceURL:serviceURL pinnedCertificate:nil];
}

- (instancetype)initWithServiceURL:(NSURL *)serviceURL pinnedCertificate:(QredoCertificate *)certificate
{
    self = [self init];
    if (!self) return nil;

    _serviceURL = serviceURL;
    if (_serviceURL) {
        _serviceInvoker = [[QredoServiceInvoker alloc] initWithServiceURL:_serviceURL pinnedCertificate:certificate];
    }

    _rendezvousQueue = dispatch_queue_create("com.qredo.rendezvous", nil);

    return self;
}

- (void)dealloc
{
    // Ensure that we close our session, even if caller forgot
    [self closeSession];
}

- (BOOL)isClosed
{
    return _serviceInvoker.isTerminated;
}

- (BOOL)isAuthenticated
{
    // rev 1 doesn't have authentication
    return YES;
}

- (void)closeSession
{
    LogDebug(@"Closing client session.  Will need to re-initialise/authorise client before further use.");

    // Need to terminate transport, which ends associated threads and subsriptions etc.
    [_serviceInvoker terminate];

    // TODO: DH - somehow indicate that the client has been closed and therefore cannot be used again.
}

- (QredoVault*) defaultVault
{
    if (!_defaultVault) {
        // should not happen, but just in case
        [self initializeVaults];
    }
    return _defaultVault;
}

#pragma mark -
#pragma mark Rendezvous

// TODO: DH - Create unit tests for createAnonymousRendezvousWithTag
- (void)createAnonymousRendezvousWithTag:(NSString *)tag
                           configuration:(QredoRendezvousConfiguration *)configuration
                       completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    // Anonymous Rendezvous are created using the full tag. Signing handler, trustedRootPems and crlPems are unused
    [self createRendezvousWithTag:tag
               authenticationType:QredoRendezvousAuthenticationTypeAnonymous
                    configuration:configuration
                  trustedRootPems:[[NSArray alloc] init]
                          crlPems:[[NSArray alloc] init]
                   signingHandler:nil
                completionHandler:completionHandler];
}

// TODO: DH - Create unit tests for createAuthenticatedRendezvousWithPrefix (internal keys)
// TODO: DH - create unit tests which provide incorrect authentication types
- (void)createAuthenticatedRendezvousWithPrefix:(NSString *)prefix
                             authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                  configuration:(QredoRendezvousConfiguration *)configuration
                              completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    if (authenticationType == QredoRendezvousAuthenticationTypeAnonymous) {
        // Not an authenticated rendezvous, so shouldn't be using this method
        NSString *message = @"'Anonymous' is invalid, use the method dedicated to anonymous rendezvous.";
        LogError(@"%@", message);
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        completionHandler(nil, error);
        return;
    } else if (authenticationType == QredoRendezvousAuthenticationTypeX509Pem ||
               authenticationType == QredoRendezvousAuthenticationTypeX509PemSelfsigned) {
        // X.509 authenticated rendezvous MUST use externally generated certificates, so MUST use method with signingHandler
        NSString *message = @"'X.509' is invalid, use the method dedicated to externally generated keys/certs which has a signing handler.";
        LogError(@"%@", message);
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        completionHandler(nil, error);
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
                completionHandler:completionHandler];
}

// TODO: DH - Create unit tests for createAuthenticatedRendezvousWithPrefix (external keys)
// TODO: DH - create unit test with nil signing handler and confirm detected deeper down stack
- (void)createAuthenticatedRendezvousWithPrefix:(NSString *)prefix
                             authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                                  configuration:(QredoRendezvousConfiguration *)configuration
                                      publicKey:(NSString *)publicKey
                                trustedRootPems:(NSArray *)trustedRootPems
                                        crlPems:(NSArray *)crlPems
                                 signingHandler:(signDataBlock)signingHandler
                              completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    if (authenticationType == QredoRendezvousAuthenticationTypeAnonymous) {
        // Not an authenticated rendezvous, so shouldn't be using this method
        NSString *message = @"'Anonymous' is invalid, use the method dedicated to anonymous rendezvous.";
        LogError(@"%@", message);
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        completionHandler(nil, error);
        return;
    }
    else if (authenticationType == QredoRendezvousAuthenticationTypeX509Pem) {
        if (!trustedRootPems) {
            // Cannot have nil trusted root PEMs
            NSString *message = @"TrustedRootPems cannot be nil when creating X.509 authenicated rendezvous, as creation will fail.";
            LogError(@"%@", message);
            NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                                 code:QredoErrorCodeRendezvousInvalidData
                                             userInfo:@{ NSLocalizedDescriptionKey : message }];
            completionHandler(nil, error);
            return;
        }
        else if (trustedRootPems.count == 0) {
            // Cannot have no trusted root refs
            NSString *message = @"TrustedRootPems cannot be empty when creating X.509 authenicated rendezvous, as creation will fail.";
            LogError(@"%@", message);
            NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                                 code:QredoErrorCodeRendezvousInvalidData
                                             userInfo:@{ NSLocalizedDescriptionKey : message }];
            completionHandler(nil, error);
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
                completionHandler:completionHandler];
}

- (void)createRendezvousWithTag:(NSString *)tag
             authenticationType:(QredoRendezvousAuthenticationType)authenticationType
                  configuration:(QredoRendezvousConfiguration *)configuration
                trustedRootPems:(NSArray *)trustedRootPems
                        crlPems:(NSArray *)crlPems
                 signingHandler:(signDataBlock)signingHandler
              completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    // although createRendezvousWithTag is asynchronous, it generates keys synchronously, which may cause a lag
    dispatch_async(_rendezvousQueue, ^{
        QredoRendezvous *rendezvous = [[QredoRendezvous alloc] initWithClient:self];
        [rendezvous createRendezvousWithTag:tag
                         authenticationType:authenticationType
                              configuration:configuration
                            trustedRootPems:trustedRootPems
                                    crlPems:crlPems
                             signingHandler:signingHandler
                          completionHandler:^(NSError *error) {
            if (error) {
                completionHandler(nil, error);
            } else {
                completionHandler(rendezvous, error);
            }
        }];
    });
}

- (QredoRendezvous*)rendezvousFromVaultItem:(QredoVaultItem*)vaultItem error:(NSError**)error {
    @try {
        QLFRendezvousDescriptor *descriptor
        = [QredoPrimitiveMarshallers unmarshalObject:vaultItem.value
                                        unmarshaller:[QLFRendezvousDescriptor unmarshaller]];

        QredoRendezvous *rendezvous = [[QredoRendezvous alloc] initWithClient:self fromLFDescriptor:descriptor];
        rendezvous.configuration
        = [[QredoRendezvousConfiguration alloc] initWithConversationType:descriptor.conversationType
                                                         durationSeconds:[descriptor.durationSeconds anyObject]
                                                        maxResponseCount:[descriptor.maxResponseCount anyObject]];
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

- (QredoConversation*)conversationFromVaultItem:(QredoVaultItem*)vaultItem error:(NSError**)error {
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

- (void)enumerateRendezvousWithBlock:(void (^)(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop))block
                   completionHandler:(void(^)(NSError *error))completionHandler
{
    QredoVault *vault = [self systemVault];

    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stopVaultEnumeration) {
        if ([vaultItemMetadata.dataType isEqualToString:kQredoRendezvousVaultItemType]) {

            NSString *tag = [vaultItemMetadata.summaryValues objectForKey:kQredoRendezvousVaultItemLabelTag];
            QredoRendezvousAuthenticationType authenticationType
            = [[vaultItemMetadata.summaryValues objectForKey:kQredoRendezvousVaultItemLabelAuthenticationType] intValue];

            QredoRendezvousMetadata *metadata
            = [[QredoRendezvousMetadata alloc] initWithTag:tag
                                        authenticationType:authenticationType
                                       vaultItemDescriptor:vaultItemMetadata.descriptor];

            BOOL stopObjectEnumeration = NO; // here we lose the feature when *stop == YES, then we are on the last object
            block(metadata, &stopObjectEnumeration);
            *stopVaultEnumeration = stopObjectEnumeration;
        }
    } completionHandler:^(NSError *error) {
        completionHandler(error);
    }];
}

- (void)fetchRendezvousWithTag:(NSString *)tag
             completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    QredoVault *vault = [self systemVault];
    QredoQUID *vaultItemId = [vault itemIdWithName:tag type:kQredoRendezvousVaultItemType];

    QredoVaultItemDescriptor *itemDescriptor
    = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vault.sequenceId itemId:vaultItemId];
    [self fetchRendezvousWithVaultItemDescriptor:itemDescriptor completionHandler:completionHandler];
}

- (void)fetchRendezvousWithMetadata:(QredoRendezvousMetadata *)metadata
                  completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    [self fetchRendezvousWithVaultItemDescriptor:metadata.vaultItemDescriptor completionHandler:completionHandler];
}


// private method
- (void)fetchRendezvousWithVaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor
                             completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    QredoVault *vault = [self systemVault];

    [vault getItemWithDescriptor:vaultItemDescriptor
               completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         if (error) {
             completionHandler(nil, error);
             return ;
         }
         
         NSError *parsingError = nil;
         QredoRendezvous *rendezvous = [self rendezvousFromVaultItem:vaultItem error:&parsingError];
         
         completionHandler(rendezvous, parsingError);
     }];
}

- (void)respondWithTag:(NSString *)tag
     completionHandler:(void (^)(QredoConversation *conversation, NSError *error))completionHandler
{
    [self respondWithTag:tag trustedRootPems:nil crlPems:nil completionHandler:completionHandler];
}

- (void)respondWithTag:(NSString *)tag
       trustedRootPems:(NSArray *)trustedRootPems
               crlPems:(NSArray *)crlPems
     completionHandler:(void (^)(QredoConversation *conversation, NSError *error))completionHandler
{
    NSAssert(completionHandler, @"completionHandler should not be nil");

    dispatch_async(_rendezvousQueue, ^{
        QredoConversation *conversation = [[QredoConversation alloc] initWithClient:self];
        [conversation respondToRendezvousWithTag:tag
                                 trustedRootPems:trustedRootPems
                                         crlPems:crlPems
                               completionHandler:^(NSError *error) {
            if (error) {
                completionHandler(nil, error);
            } else {
                completionHandler(conversation, nil);
            }
        }];
    });
}

- (void)enumerateConversationsWithBlock:(void (^)(QredoConversationMetadata *conversationMetadata, BOOL *stop))block
                      completionHandler:(void (^)(NSError *))completionHandler
{
    QredoVault *vault = [self systemVault];

    [vault enumerateVaultItemsUsingBlock:^(QredoVaultItemMetadata *vaultItemMetadata, BOOL *stopVaultEnumeration) {
        if ([vaultItemMetadata.dataType isEqualToString:kQredoConversationVaultItemType]) {
            QredoConversationMetadata *metadata = [[QredoConversationMetadata alloc] init];
            // TODO: DH - populate metadata.rendezvousMetadata
            metadata.conversationId = [vaultItemMetadata.summaryValues objectForKey:kQredoConversationVaultItemLabelId];
            metadata.amRendezvousOwner = [[vaultItemMetadata.summaryValues objectForKey:kQredoConversationVaultItemLabelAmOwner] boolValue];
            metadata.type = [vaultItemMetadata.summaryValues objectForKey:kQredoConversationVaultItemLabelType];
            metadata.rendezvousTag = [vaultItemMetadata.summaryValues objectForKey:kQredoConversationVaultItemLabelTag];

            BOOL stopObjectEnumeration = NO; // here we lose the feature when *stop == YES, then we are on the last object
            block(metadata, &stopObjectEnumeration);
            *stopVaultEnumeration = stopObjectEnumeration;
        }
    } completionHandler:^(NSError *error) {
        completionHandler(error);
    }];
}

- (void)fetchConversationWithId:(QredoQUID*)conversationId
              completionHandler:(void(^)(QredoConversation* conversation, NSError *error))completionHandler
{
    QredoVault *vault = [self systemVault];

    QLFVaultId *vaultItemId = [vault itemIdWithQUID:conversationId type:kQredoConversationVaultItemType];
    QredoVaultItemDescriptor *vaultItemDescriptor
    = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vault.sequenceId itemId:vaultItemId];
    [vault getItemWithDescriptor:vaultItemDescriptor
               completionHandler:^(QredoVaultItem *vaultItem, NSError *error)
     {
         if (error) {
             completionHandler(nil, error);
             return ;
         }
         
         NSError *parsingError = nil;
         QredoConversation *conversation = [self conversationFromVaultItem:vaultItem error:&parsingError];
         completionHandler(conversation, parsingError);
     }];
}

- (void)deleteConversationWithId:(QredoQUID*)conversationId
               completionHandler:(void(^)(NSError *error))completionHandler
{
    [self fetchConversationWithId:conversationId
                completionHandler:^(QredoConversation *conversation, NSError *error)
     {
         if (error) {
             completionHandler(error);
             return ;
         }
         
         [conversation deleteConversationWithCompletionHandler:completionHandler];
     }];
}

#pragma mark -
#pragma mark Private Methods

- (NSString *)deviceName {
    NSString *name = [[UIDevice currentDevice] name];
    return (!name) ? @"iOS device" : name;
}

- (void)addDeviceToVaultWithCompletionHandler:(void(^)(NSError *error))completionHandler {
    QredoVault *systemVault = [self systemVault];

    QredoVaultItemMetadata *metadata
    = [QredoVaultItemMetadata vaultItemMetadataWithDataType:QredoVaultItemTypeKeychain
                                                accessLevel:0
                                              summaryValues:
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

- (BOOL)saveStateWithError:(NSError **)error
{
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    return [self saveSystemVaultKeychain:_keychain
        withKeychainWithKeychainArchiver:keychainArchiver
                                   error:error];
}

- (BOOL)loadStateWithError:(NSError **)error
{
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

- (void)createSystemVaultWithCompletionHandler:(void(^)(NSError *error))completionHandler {
    [self createDefaultKeychain];
    [self initializeVaults];

    [self addDeviceToVaultWithCompletionHandler:completionHandler];
}

- (void)initializeVaults {
    _systemVault = [[QredoVault alloc] initWithClient:self vaultKeys:_keychain.systemVaultKeys];
    _defaultVault = [[QredoVault alloc] initWithClient:self vaultKeys:_keychain.defaultVaultKeys];
}

- (id<QredoKeychainArchiver>)qredoKeychainArchiver
{
    return [QredoKeychainArchivers defaultQredoKeychainArchiver];
}

- (void)createDefaultKeychain
{
    QLFOperatorInfo *operatorInfo
    = [QLFOperatorInfo operatorInfoWithName:QredoKeychainOperatorName
                                   serviceUri:self.serviceURL.absoluteString
                                    accountID:QredoKeychainOperatorAccountId
                         currentServiceAccess:[NSSet set]
                            nextServiceAccess:[NSSet set]];
    
    QredoKeychain *keychain = [[QredoKeychain alloc] initWithOperatorInfo:operatorInfo];
    [keychain generateNewKeys];

    _keychain = keychain;
}

NSString *systemVaultKeychainArchiveIdentifier = @"com.qredo.system.vault.key";

- (QredoKeychain *)loadSystemVaultKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver
                                                         error:(NSError **)error
{
    return [keychainArchiver loadQredoKeychainWithIdentifier:systemVaultKeychainArchiveIdentifier error:error];
}

- (BOOL)saveSystemVaultKeychain:(QredoKeychain *)keychain
withKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver
                          error:(NSError **)error
{
    return [keychainArchiver saveQredoKeychain:keychain
                                withIdentifier:systemVaultKeychainArchiveIdentifier error:error];
}

- (BOOL)hasSystemVaultKeychainWithKeychainArchiver:(id<QredoKeychainArchiver>)keychainArchiver
                                             error:(NSError **)error
{
    return [keychainArchiver hasQredoKeychainWithIdentifier:systemVaultKeychainArchiveIdentifier error:error];
}

- (BOOL)setKeychain:(QredoKeychain *)keychain
              error:(NSError **)error
{
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    BOOL result = [self saveSystemVaultKeychain:keychain
               withKeychainWithKeychainArchiver:keychainArchiver
                                          error:error];

    QredoClient *newClient = [[QredoClient alloc] initWithServiceURL:
                              [NSURL URLWithString:keychain.operatorInfo.serviceUri]];
    [newClient loadStateWithError:error];
    [newClient addDeviceToVaultWithCompletionHandler:nil];

    return result;
}

- (BOOL)deleteDefaultVaultKeychainWithError:(NSError **)error
{
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    return [self saveSystemVaultKeychain:nil withKeychainWithKeychainArchiver:keychainArchiver error:error];
}

- (BOOL)hasDefaultVaultKeychainWithError:(NSError **)error
{
    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    return [self hasSystemVaultKeychainWithKeychainArchiver:keychainArchiver error:error];
}


+ (BOOL)deleteDefaultVaultKeychainWithError:(NSError **)error
{
    QredoClient *newClient = [[QredoClient alloc] initWithServiceURL:nil];
    return [newClient deleteDefaultVaultKeychainWithError:error];
}

+ (BOOL)hasDefaultVaultKeychainWithError:(NSError **)error
{
    QredoClient *newClient = [[QredoClient alloc] initWithServiceURL:nil];
    return [newClient hasDefaultVaultKeychainWithError:error];
}


@end