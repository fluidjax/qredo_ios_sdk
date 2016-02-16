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
#import "QredoLoggerPrivate.h"

#import "QredoKeychain.h"
#import "QredoKeychainArchiver.h"
#import "NSData+QredoRandomData.h"
#import "NSData+ParseHex.h"

#import "QredoCertificate.h"
#import "QredoUserCredentials.h"

// TEMP
#import "QredoConversationProtocol.h"


#import <UIKit/UIKit.h>

NSString *const QredoVaultItemTypeKeychain = @"com.qredo.keychain.device-name";
NSString *const QredoVaultItemTypeKeychainAttempt = @"com.qredo.keychain.transfer-attempt";
NSString *const QredoVaultItemSummaryKeyDeviceName = @"device-name";


NSString *const QredoClientOptionCreateNewSystemVault = @"com.qredo.option.create.new.system.vault";
NSString *const QredoClientOptionServiceURL = @"com.qredo.option.serviceUrl";

//static NSString *const QredoClientDefaultServiceURL = @"https://suchlog.qredo.me:443/services";
//static NSString *const QredoClientMQTTServiceURL = @"ssl://suchlog.qredo.me:8883";
//static NSString *const QredoClientWebSocketsServiceURL = @"wss://suchlog.qredo.me:443/services";




static NSString *const QredoClientDefaultServiceURL = @"https://early1.qredo.me:443/services";
static NSString *const QredoClientMQTTServiceURL = @"ssl://early1.qredo.me:8883";
static NSString *const QredoClientWebSocketsServiceURL = @"wss://early1.qredo.me:443/services";





NSString *const QredoRendezvousURIProtocol = @"qrp:";


static NSString *const QredoKeychainOperatorName = @"Qredo Mock Operator";
static NSString *const QredoKeychainOperatorAccountId = @"1234567890";
static NSString *const QredoKeychainPassword = @"Password123";

NSString *systemVaultKeychainArchiveIdentifier;

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
     
     This is the server self signed test certificate using an RSA Public Key: (4096 bit).
     
        Certificate:
            Data:
                Version: 3 (0x2)
                Serial Number:
                    bb:40:1c:43:f5:5e:4f:b0
                Signature Algorithm: sha1WithRSAEncryption
                Issuer: C=CH, O=SwissSign AG, CN=SwissSign Gold CA - G2
                Validity
                    Not Before: Oct 25 08:30:35 2006 GMT
                    Not After : Oct 25 08:30:35 2036 GMT
                Subject: C=CH, O=SwissSign AG, CN=SwissSign Gold CA - G2
                Subject Public Key Info:
                    Public Key Algorithm: rsaEncryption
                    RSA Public Key: (4096 bit)
                        Modulus (4096 bit):
                            00:af:e4:ee:7e:8b:24:0e:12:6e:a9:50:2d:16:44:
                            3b:92:92:5c:ca:b8:5d:84:92:42:13:2a:bc:65:57:
                            82:40:3e:57:24:cd:50:8b:25:2a:b7:6f:fc:ef:a2:
                            d0:c0:1f:02:24:4a:13:96:8f:23:13:e6:28:58:00:
                            a3:47:c7:06:a7:84:23:2b:bb:bd:96:2b:7f:55:cc:
                            8b:c1:57:1f:0e:62:65:0f:dd:3d:56:8a:73:da:ae:
                            7e:6d:ba:81:1c:7e:42:8c:20:35:d9:43:4d:84:fa:
                            84:db:52:2c:f3:0e:27:77:0b:6b:bf:11:2f:72:78:
                            9f:2e:d8:3e:e6:18:37:5a:2a:72:f9:da:62:90:92:
                            95:ca:1f:9c:e9:b3:3c:2b:cb:f3:01:13:bf:5a:cf:
                            c1:b5:0a:60:bd:dd:b5:99:64:53:b8:a0:96:b3:6f:
                            e2:26:77:91:8c:e0:62:10:02:9f:34:0f:a4:d5:92:
                            33:51:de:be:8d:ba:84:7a:60:3c:6a:db:9f:2b:ec:
                            de:de:01:3f:6e:4d:e5:50:86:cb:b4:af:ed:44:40:
                            c5:ca:5a:8c:da:d2:2b:7c:a8:ee:be:a6:e5:0a:aa:
                            0e:a5:df:05:52:b7:55:c7:22:5d:32:6a:97:97:63:
                            13:db:c9:db:79:36:7b:85:3a:4a:c5:52:89:f9:24:
                            e7:9d:77:a9:82:ff:55:1c:a5:71:69:2b:d1:02:24:
                            f2:b3:26:d4:6b:da:04:55:e5:c1:0a:c7:6d:30:37:
                            90:2a:e4:9e:14:33:5e:16:17:55:c5:5b:b5:cb:34:
                            89:92:f1:9d:26:8f:a1:07:d4:c6:b2:78:50:db:0c:
                            0c:0b:7c:0b:8c:41:d7:b9:e9:dd:8c:88:f7:a3:4d:
                            b2:32:cc:d8:17:da:cd:b7:ce:66:9d:d4:fd:5e:ff:
                            bd:97:3e:29:75:e7:7e:a7:62:58:af:25:34:a5:41:
                            c7:3d:bc:0d:50:ca:03:03:0f:08:5a:1f:95:73:78:
                            62:bf:af:72:14:69:0e:a5:e5:03:0e:78:8e:26:28:
                            42:f0:07:0b:62:20:10:67:39:46:fa:a9:03:cc:04:
                            38:7a:66:ef:20:83:b5:8c:4a:56:8e:91:00:fc:8e:
                            5c:82:de:88:a0:c3:e2:68:6e:7d:8d:ef:3c:dd:65:
                            f4:5d:ac:51:ef:24:80:ae:aa:56:97:6f:f9:ad:7d:
                            da:61:3f:98:77:3c:a5:91:b6:1c:8c:26:da:65:a2:
                            09:6d:c1:e2:54:e3:b9:ca:4c:4c:80:8f:77:7b:60:
                            9a:1e:df:b6:f2:48:1e:0e:ba:4e:54:6d:98:e0:e1:
                            a2:1a:a2:77:50:cf:c4:63:92:ec:47:19:9d:eb:e6:
                            6b:ce:c1
                        Exponent: 65537 (0x10001)
                X509v3 extensions:
                    X509v3 Key Usage: critical
                        Certificate Sign, CRL Sign
                    X509v3 Basic Constraints: critical
                        CA:TRUE
                    X509v3 Subject Key Identifier: 
                        5B:25:7B:96:A4:65:51:7E:B8:39:F3:C0:78:66:5E:E8:3A:E7:F0:EE
                    X509v3 Authority Key Identifier: 
                        keyid:5B:25:7B:96:A4:65:51:7E:B8:39:F3:C0:78:66:5E:E8:3A:E7:F0:EE

                    X509v3 Certificate Policies: 
                        Policy: 2.16.756.1.89.1.2.1.1
                          CPS: http://repository.swisssign.com/

            Signature Algorithm: sha1WithRSAEncryption
                27:ba:e3:94:7c:f1:ae:c0:de:17:e6:e5:d8:d5:f5:54:b0:83:
                f4:bb:cd:5e:05:7b:4f:9f:75:66:af:3c:e8:56:7e:fc:72:78:
                38:03:d9:2b:62:1b:00:b9:f8:e9:60:cd:cc:ce:51:8a:c7:50:
                31:6e:e1:4a:7e:18:2f:69:59:b6:3d:64:81:2b:e3:83:84:e6:
                22:87:8e:7d:e0:ee:02:99:61:b8:1e:f4:b8:2b:88:12:16:84:
                c2:31:93:38:96:31:a6:b9:3b:53:3f:c3:24:93:56:5b:69:92:
                ec:c5:c1:bb:38:00:e3:ec:17:a9:b8:dc:c7:7c:01:83:9f:32:
                47:ba:52:22:34:1d:32:7a:09:56:a7:7c:25:36:a9:3d:4b:da:
                c0:82:6f:0a:bb:12:c8:87:4b:27:11:f9:1e:2d:c7:93:3f:9e:
                db:5f:26:6b:52:d9:2e:8a:f1:14:c6:44:8d:15:a9:b7:bf:bd:
                de:a6:1a:ee:ae:2d:fb:48:77:17:fe:bb:ec:af:18:f5:2a:51:
                f0:39:84:97:95:6c:6e:1b:c3:2b:c4:74:60:79:25:b0:0a:27:
                df:df:5e:d2:39:cf:45:7d:42:4b:df:b3:2c:1e:c5:c6:5d:ca:
                55:3a:a0:9c:69:9a:8f:da:ef:b2:b0:3c:9f:87:6c:12:2b:65:
                70:15:52:31:1a:24:cf:6f:31:23:50:1f:8c:4f:8f:23:c3:74:
                41:63:1c:55:a8:14:dd:3e:e0:51:50:cf:f1:1b:30:56:0e:92:
                b0:82:85:d8:83:cb:22:64:bc:2d:b8:25:d5:54:a2:b8:06:ea:
                ad:92:a4:24:a0:c1:86:b5:4a:13:6a:47:cf:2e:0b:56:95:54:
                cb:ce:9a:db:6a:b4:a6:b2:db:41:08:86:27:77:f7:6a:a0:42:
                6c:0b:38:ce:d7:75:50:32:92:c2:df:2b:30:22:48:d0:d5:41:
                38:25:5d:a4:e9:5d:9f:c6:94:75:d0:45:fd:30:97:43:8f:90:
                ab:0a:c7:86:73:60:4a:69:2d:de:a5:78:d7:06:da:6a:9e:4b:
                3e:77:3a:20:13:22:01:d0:bf:68:9e:63:60:6b:35:4d:0b:6d:
                ba:a1:3d:c0:93:e0:7f:23:b3:55:ad:72:25:4e:46:f9:d2:16:
                ef:b0:64:c1:01:9e:e9:ca:a0:6a:98:0e:cf:d8:60:f2:2f:49:
                b8:e4:42:e1:38:35:16:f4:c8:6e:4f:f7:81:56:e8:ba:a3:be:
                23:af:ae:fd:6f:03:e0:02:3b:30:76:fa:1b:6d:41:cf:01:b1:
                e9:b8:c9:66:f4:db:26:f3:3a:a4:74:f2:49:24:5b:c9:b0:d0:
                57:c1:fa:3e:7a:e1:97:c9
     
     */
    
    //this is Charles root key for debugging
    //use this key & start charles
    NSString *base64EncodedDerCertificateData_CHARLES
    = @"\
MIIFbjCCBFagAwIBAgIGAVJ5ULzjMA0GCSqGSIb3DQEBCwUAMIG7MU0wSwYDVQQDDERDaGFybGVz\
IFByb3h5IEN1c3RvbSBSb290IENlcnRpZmljYXRlIChidWlsdCBvbiBxdWluY2UsIDI1IEphbiAy\
MDE2KTEkMCIGA1UECwwbaHR0cDovL2NoYXJsZXNwcm94eS5jb20vc3NsMREwDwYDVQQKDAhYSzcy\
IEx0ZDERMA8GA1UEBwwIQXVja2xhbmQxETAPBgNVBAgMCEF1Y2tsYW5kMQswCQYDVQQGEwJOWjAe\
Fw0wMDAxMDEwMDAwMDBaFw00NTAzMjMxNTA0NDBaMIG7MU0wSwYDVQQDDERDaGFybGVzIFByb3h5\
IEN1c3RvbSBSb290IENlcnRpZmljYXRlIChidWlsdCBvbiBxdWluY2UsIDI1IEphbiAyMDE2KTEk\
MCIGA1UECwwbaHR0cDovL2NoYXJsZXNwcm94eS5jb20vc3NsMREwDwYDVQQKDAhYSzcyIEx0ZDER\
MA8GA1UEBwwIQXVja2xhbmQxETAPBgNVBAgMCEF1Y2tsYW5kMQswCQYDVQQGEwJOWjCCASIwDQYJ\
KoZIhvcNAQEBBQADggEPADCCAQoCggEBAIE0afLxakBnz4SkQUXa/owSwrtI6e2FOcEiEVVwzLQn\
t1cZoo7KCNoKWjPa+pNtlJ0naEDcxIdPfOwWz8wmyg1aXRpe7Cn2dVPsK5mKQKE4DOw5XMqQj9iM\
DFw7L8CoUcsBzyQtMLBxm4vhO7i3KlnzOAaO0LzZ81zp0NLxCbxg0LSnXHoJCCnxSUqmfd6fMheg\
uLtLOruiSR6TTXVrzn3ymn58LhBTMrosUjdJvM+OyTHdNpH9n+GTQeEeYXte5wFn1NWsxvohI/BF\
jXjP0ap1lnu+eHnQEPwouOQVnBqiQzt2FHXKDlDFHwSnOTUhg9CjJv1bgpWTmmxBWMtLyG0CAwEA\
AaOCAXQwggFwMA8GA1UdEwEB/wQFMAMBAf8wggEsBglghkgBhvhCAQ0EggEdE4IBGVRoaXMgUm9v\
dCBjZXJ0aWZpY2F0ZSB3YXMgZ2VuZXJhdGVkIGJ5IENoYXJsZXMgUHJveHkgZm9yIFNTTCBQcm94\
eWluZy4gSWYgdGhpcyBjZXJ0aWZpY2F0ZSBpcyBwYXJ0IG9mIGEgY2VydGlmaWNhdGUgY2hhaW4s\
IHRoaXMgbWVhbnMgdGhhdCB5b3UncmUgYnJvd3NpbmcgdGhyb3VnaCBDaGFybGVzIFByb3h5IHdp\
dGggU1NMIFByb3h5aW5nIGVuYWJsZWQgZm9yIHRoaXMgd2Vic2l0ZS4gUGxlYXNlIHNlZSBodHRw\
Oi8vY2hhcmxlc3Byb3h5LmNvbS9zc2wgZm9yIG1vcmUgaW5mb3JtYXRpb24uMA4GA1UdDwEB/wQE\
AwICBDAdBgNVHQ4EFgQUuEXgnNm2K6PDOmPu0/T8kEVBKOUwDQYJKoZIhvcNAQELBQADggEBAB4n\
Oeg7/14raScFPSpdfPzLYkgmmJx5tJYkt2GwoSmFWaKY2sRvGxZ5CKb30LiwXW5fYJWBi7V6eBuN\
GRWeXpObTTHjWjRSjj5al8/iLFax2inKK3v0QDd5/xn5zj5f4eMfNZdL5dwf4/qY4fXXs8nX3TI/\
uvHi0vyTR2TTEuo9BzmX0Lp/4D6SdEZLMEaunh3z/78INf8I6yTwytOSuwGv5k5pINrKjUc4p8i8\
KMpsX1xsx4Cvc/Vy/C5TZcTnIDul0aCI7Z1sSefbFjtiehAx+gmZMQqXLYa8afJ9PwLIFOw1vf7b\
ldRMSpzB9BEMBs6YVotd0s+xvbr9Hyymyi4=";

    
    NSString *base64EncodedDerCertificateData_QREDO
    = @"\
MIIFujCCA6KgAwIBAgIJALtAHEP1Xk+wMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV\
BAYTAkNIMRUwEwYDVQQKEwxTd2lzc1NpZ24gQUcxHzAdBgNVBAMTFlN3aXNzU2ln\
biBHb2xkIENBIC0gRzIwHhcNMDYxMDI1MDgzMDM1WhcNMzYxMDI1MDgzMDM1WjBF\
MQswCQYDVQQGEwJDSDEVMBMGA1UEChMMU3dpc3NTaWduIEFHMR8wHQYDVQQDExZT\
d2lzc1NpZ24gR29sZCBDQSAtIEcyMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC\
CgKCAgEAr+TufoskDhJuqVAtFkQ7kpJcyrhdhJJCEyq8ZVeCQD5XJM1QiyUqt2/8\
76LQwB8CJEoTlo8jE+YoWACjR8cGp4QjK7u9lit/VcyLwVcfDmJlD909Vopz2q5+\
bbqBHH5CjCA12UNNhPqE21Is8w4ndwtrvxEvcnifLtg+5hg3Wipy+dpikJKVyh+c\
6bM8K8vzARO/Ws/BtQpgvd21mWRTuKCWs2/iJneRjOBiEAKfNA+k1ZIzUd6+jbqE\
emA8atufK+ze3gE/bk3lUIbLtK/tREDFylqM2tIrfKjuvqblCqoOpd8FUrdVxyJd\
MmqXl2MT28nbeTZ7hTpKxVKJ+STnnXepgv9VHKVxaSvRAiTysybUa9oEVeXBCsdt\
MDeQKuSeFDNeFhdVxVu1yzSJkvGdJo+hB9TGsnhQ2wwMC3wLjEHXuendjIj3o02y\
MszYF9rNt85mndT9Xv+9lz4pded+p2JYryU0pUHHPbwNUMoDAw8IWh+Vc3hiv69y\
FGkOpeUDDniOJihC8AcLYiAQZzlG+qkDzAQ4embvIIO1jEpWjpEA/I5cgt6IoMPi\
aG59je883WX0XaxR7ySArqpWl2/5rX3aYT+YdzylkbYcjCbaZaIJbcHiVOO5ykxM\
gI93e2CaHt+28kgeDrpOVG2Y4OGiGqJ3UM/EY5LsRxmd6+ZrzsECAwEAAaOBrDCB\
qTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUWyV7\
lqRlUX64OfPAeGZe6Drn8O4wHwYDVR0jBBgwFoAUWyV7lqRlUX64OfPAeGZe6Drn\
8O4wRgYDVR0gBD8wPTA7BglghXQBWQECAQEwLjAsBggrBgEFBQcCARYgaHR0cDov\
L3JlcG9zaXRvcnkuc3dpc3NzaWduLmNvbS8wDQYJKoZIhvcNAQEFBQADggIBACe6\
45R88a7A3hfm5djV9VSwg/S7zV4Fe0+fdWavPOhWfvxyeDgD2StiGwC5+OlgzczO\
UYrHUDFu4Up+GC9pWbY9ZIEr44OE5iKHjn3g7gKZYbge9LgriBIWhMIxkziWMaa5\
O1M/wySTVltpkuzFwbs4AOPsF6m43Md8AYOfMke6UiI0HTJ6CVanfCU2qT1L2sCC\
bwq7EsiHSycR+R4tx5M/nttfJmtS2S6K8RTGRI0Vqbe/vd6mGu6uLftIdxf+u+yv\
GPUqUfA5hJeVbG4bwyvEdGB5JbAKJ9/fXtI5z0V9QkvfsywexcZdylU6oJxpmo/a\
77KwPJ+HbBIrZXAVUjEaJM9vMSNQH4xPjyPDdEFjHFWoFN0+4FFQz/EbMFYOkrCC\
hdiDyyJkvC24JdVUorgG6q2SpCSgwYa1ShNqR88uC1aVVMvOmttqtKay20EIhid3\
92qgQmwLOM7XdVAyksLfKzAiSNDVQTglXaTpXZ/GlHXQRf0wl0OPkKsKx4ZzYEpp\
Ld6leNcG2mqeSz53OiATIgHQv2ieY2BrNU0LbbqhPcCT4H8js1WtciVORvnSFu+w\
ZMEBnunKoGqYDs/YYPIvSbjkQuE4NRb0yG5P94FW6LqjviOvrv1vA+ACOzB2+htt\
Qc8Bsem4yWb02ybzOqR08kkkW8mw0FfB+j564ZfJ"
    ;
    
    
    NSString *base64EncodedDerCertificateData=base64EncodedDerCertificateData_QREDO;
    
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
    QredoUserCredentials *_userCredentials;
    QredoAppCredentials *_appCredentials;
    

    dispatch_queue_t _rendezvousQueue;
}

@property NSURL *serviceURL;
@property QredoClientOptions *clientOptions;

/** Creates instance of qredo client
 @param serviceURL Root URL for Qredo services
 */
- (instancetype)initWithServiceURL:(NSURL *)serviceURL  appCredentials:(QredoAppCredentials *)appCredentials;


@end

@implementation QredoClient


- (NSString *)versionString{
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    return [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)buildString{
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    return [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
}





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

+(void)initializeWithAppSecret:(NSString*)appSecret
                        userId:(NSString*)userId
                    userSecret:(NSString*)userSecret
            completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler{
    [self initializeWithAppSecret:appSecret
                           userId:userId
                       userSecret:userSecret
                          options:nil
                completionHandler:completionHandler];
}


+(void)initializeWithAppSecret:(NSString*)appSecret
                                 userId:(NSString*)userId
                             userSecret:(NSString*)userSecret
                               options:(QredoClientOptions*)options
                     completionHandler:(void(^)(QredoClient *client, NSError *error))completionHandler{
    
    
    
    // TODO: DH - Update to display the QredoClientOptions contents, now it's no longer a dictionary
    if (!options) {
        options = [[QredoClientOptions alloc] initDefaultPinnnedCertificate];
    }

    
    NSString* appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    if (!appID)appID = @"test";
    
    
    QredoUserCredentials *userCredentials = [[QredoUserCredentials alloc] initWithAppId:appID
                                                                                 userId:userId
                                                                             userSecure:userSecret];

    QredoLogDebug(@"UserCredentials: Appid:%@   userID:%@   userSecure:%@",appID,userId,userSecret);
    
    
    
    QredoAppCredentials *appCredentials = [QredoAppCredentials appCredentialsWithAppId:appID
                                                                             appSecret:[NSData dataWithHexString:appSecret]];
    
    QredoLogDebug(@"AppCredentials: Appid:%@   appSecret:%@",appID,appSecret);
    
    systemVaultKeychainArchiveIdentifier = [userCredentials createSystemVaultIdentifier];
    
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
    
    __block QredoClient *client = [[QredoClient alloc] initWithServiceURL:serviceURL
                                                        pinnedCertificate:options.certificate
                                                           appCredentials:appCredentials];
    
    client.clientOptions = options;
    
    void(^completeAuthorization)(NSError *) = ^void(NSError *error) {
        
        if (error) {
            if (completionHandler) completionHandler(nil, error);
        } else {
            // This assert is very important!!!
            if (!client.defaultVault)QredoLogError(@"No QredoClient without a system vault must be passed to the client code.");
            if (completionHandler) completionHandler(client, error);
        }
        
    };

    BOOL loaded = [client loadStateWithError:&error];
    
    if (options.resetData) {
        
        [client createSystemVaultWithUserCredentials:userCredentials completionHandler:^(NSError *error) {
            if (!error) {
                [client saveStateWithError:&error];
            }

            completeAuthorization(error);
        }];

        return;
        
    }
    
    
    if (!loaded) {
        
        if ([error.domain isEqualToString:QredoErrorDomain] && error.code == QredoErrorCodeKeychainCouldNotBeFound) {
            
            // TODO: [GR]: Show new device screen insted of creating the vault straight away.
            error = nil;
            [client createSystemVaultWithUserCredentials:userCredentials completionHandler:^(NSError *error) {
                if (!error) {
                    [client saveStateWithError:&error];
                }

                completeAuthorization(error);
            }];

        } else {
            
            // TODO: [GR]: Show alert for corrupted keychain instead of the placeholder below.
            // Also implement a way of recovering a keychain here.
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIAlertController *alertController
                = [UIAlertController alertControllerWithTitle:@"Keychain is corrupt"
                                                      message:@"The system vault keychain seems to be corrupt."
                                               preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:
                 [UIAlertAction actionWithTitle:@"Try later"
                                          style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action)
                  {
                      completeAuthorization(error);
                  }]];
                
                [alertController addAction:
                 [UIAlertAction actionWithTitle:@"Remove keychain"
                                          style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *action)
                  {
                      [client createSystemVaultWithUserCredentials:userCredentials completionHandler:^(NSError *error) {
                          if (!error) {
                              [client saveStateWithError:&error];
                          }
                          
                          completeAuthorization(error);
                      }];
                  }]];
                
                [[UIApplication sharedApplication].keyWindow.rootViewController
                 presentViewController:alertController animated:YES completion:nil];
            });
            
        }
        
        return;
        
    }
    
    completeAuthorization(error);
    
}


- (instancetype)initWithServiceURL:(NSURL *)serviceURL appCredentials:(QredoAppCredentials *)appCredentials
{
    return [self initWithServiceURL:serviceURL pinnedCertificate:nil appCredentials:appCredentials];
}

- (instancetype)initWithServiceURL:(NSURL *)serviceURL pinnedCertificate:(QredoCertificate *)certificate appCredentials:(QredoAppCredentials *)appCredentials
{
    self = [self init];
    if (!self) return nil;

    _serviceURL = serviceURL;
    if (_serviceURL) {
        _serviceInvoker = [[QredoServiceInvoker alloc] initWithServiceURL:_serviceURL pinnedCertificate:certificate appCredentials:appCredentials];
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
    // Need to terminate transport, which ends associated threads and subscriptions etc.
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



-(NSString*)appId{
    NSString* appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    
    if (!appID || [appID isEqualToString:@""]){
        appID = @"testtag";
    }
    return appID;
}


-(void)createAnonymousRendezvousWithTag:(NSString *)tag
                      completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler{
    
    [self createAnonymousRendezvousWithTag:tag
                          conversationType:[self appId]
                                  duration:0
                        unlimitedResponses:YES
                         completionHandler:completionHandler];
    
}



-(void)createAnonymousRendezvousWithTag:(NSString *)tag
                               duration:(long)duration
                      completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler{

    [self createAnonymousRendezvousWithTag:tag
                          conversationType:[self appId]
                                  duration:duration
                        unlimitedResponses:YES
                         completionHandler:completionHandler];

}




-(void)createAnonymousRendezvousWithTag:(NSString *)tag
                       conversationType:(NSString*)conversationType
                              duration:(long)duration
                         unlimitedResponses:(BOOL)unlimitedResponses
                     completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler{
    // Anonymous Rendezvous are created using the full tag. Signing handler, trustedRootPems and crlPems are unused
    QredoLogVerbose(@"Start createAnonymousRendezvousWithTag %@", tag);
                         

     QredoRendezvousConfiguration *configuration = [[QredoRendezvousConfiguration alloc]
                                                    initWithConversationType:conversationType
                                                             durationSeconds:[NSNumber numberWithLong:duration]
                                                     isUnlimitedResponseCount:unlimitedResponses];
    
    [self createRendezvousWithTag:tag
               authenticationType:QredoRendezvousAuthenticationTypeAnonymous
                    configuration:configuration
                  trustedRootPems:[[NSArray alloc] init]
                          crlPems:[[NSArray alloc] init]
                   signingHandler:nil
                completionHandler:completionHandler];
    QredoLogVerbose(@"Complete createAnonymousRendezvousWithTag %@", tag);
}






// TODO: DH - Create unit tests for createAnonymousRendezvousWithTag
- (void)createAnonymousRendezvousWithTag:(NSString *)tag
                           configuration:(QredoRendezvousConfiguration *)configuration
                       completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    // Anonymous Rendezvous are created using the full tag. Signing handler, trustedRootPems and crlPems are unused
    QredoLogVerbose(@"Start createAnonymousRendezvousWithTag %@", tag);
    [self createRendezvousWithTag:tag
               authenticationType:QredoRendezvousAuthenticationTypeAnonymous
                    configuration:configuration
                  trustedRootPems:[[NSArray alloc] init]
                          crlPems:[[NSArray alloc] init]
                   signingHandler:nil
                completionHandler:completionHandler];
    QredoLogVerbose(@"Complete createAnonymousRendezvousWithTag %@", tag);
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
        QredoLogError(@"%@", message);
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        completionHandler(nil, error);
        return;
    } else if (authenticationType == QredoRendezvousAuthenticationTypeX509Pem ||
               authenticationType == QredoRendezvousAuthenticationTypeX509PemSelfsigned) {
        // X.509 authenticated rendezvous MUST use externally generated certificates, so MUST use method with signingHandler
        NSString *message = @"'X.509' is invalid, use the method dedicated to externally generated keys/certs which has a signing handler.";
        QredoLogError(@"%@", message);
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
        QredoLogError(@"%@", message);
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
            QredoLogError(@"%@", message);
            NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                                 code:QredoErrorCodeRendezvousInvalidData
                                             userInfo:@{ NSLocalizedDescriptionKey : message }];
            completionHandler(nil, error);
            return;
        }
        else if (trustedRootPems.count == 0) {
            // Cannot have no trusted root refs
            NSString *message = @"TrustedRootPems cannot be empty when creating X.509 authenicated rendezvous, as creation will fail.";
            QredoLogError(@"%@", message);
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
                          completionHandler:^(NSError *error) {
            if (error) {
                completionHandler(nil, error);
            } else {
                completionHandler(rendezvous, error);
            }
        }];
        QredoLogVerbose(@"End createRendezvousWithTag on rendezvousQueue %@", tag);
        
    });

    QredoLogVerbose(@"End createRendezvousWithTag %@", tag);

    
}

- (QredoRendezvous*)rendezvousFromVaultItem:(QredoVaultItem*)vaultItem error:(NSError**)error {
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


-(void)fetchRendezvousWithTag:(NSString *)tag completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler{
    __block QredoRendezvousMetadata *matchedRendezvousMetadata;
    
    [self enumerateRendezvousWithBlock:^(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop) {
        if ([tag isEqualToString:rendezvousMetadata.tag]){
            matchedRendezvousMetadata =rendezvousMetadata;
            *stop = YES;
        }
    } completionHandler:^(NSError *error) {
        if (error){
            completionHandler(nil,error);
        }else if(!matchedRendezvousMetadata){
            NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                                 code:QredoErrorCodeRendezvousNotFound
                                             userInfo:@{ NSLocalizedDescriptionKey : @"Rendezvous was not found in vault" }];
            completionHandler(nil,error);
        }else{
            [self fetchRendezvousWithMetadata:matchedRendezvousMetadata completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
                completionHandler(rendezvous, error);
            }];
        }
    }];
    
}


- (void)enumerateRendezvousWithBlock:(void (^)(QredoRendezvousMetadata *rendezvousMetadata, BOOL *stop))block
                   completionHandler:(void(^)(NSError *error))completionHandler
{
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
                                             rendezvousRef:rendezvousRef];
            
            BOOL stopObjectEnumeration = NO; // here we lose the feature when *stop == YES, then we are on the last object
            block(metadata, &stopObjectEnumeration);
            *stopVaultEnumeration = stopObjectEnumeration;
        }
    } completionHandler:^(NSError *error) {
        completionHandler(error);
    }];
}




- (void)fetchRendezvousWithRef:(QredoRendezvousRef *)ref
             completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
  // an unknown ref will throw an exception, but catch a nil ref here
  if (ref == nil)
   {
        NSString *message = @"'The RendezvousRef must not be nil";
        
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        completionHandler(nil, error);
        return;
   }
    
    [self fetchRendezvousWithVaultItemDescriptor:ref.vaultItemDescriptor completionHandler:completionHandler];
}

- (void)fetchRendezvousWithMetadata:(QredoRendezvousMetadata *)metadata
                  completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler
{
    [self fetchRendezvousWithRef:metadata.rendezvousRef completionHandler:completionHandler];
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
                      completionHandler:(void (^)(NSError *error))completionHandler
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
            metadata.conversationRef = [[QredoConversationRef alloc] initWithVaultItemDescriptor:vaultItemMetadata.descriptor vault:vault];

            BOOL stopObjectEnumeration = NO; // here we lose the feature when *stop == YES, then we are on the last object
            block(metadata, &stopObjectEnumeration);
            *stopVaultEnumeration = stopObjectEnumeration;
        }
    } completionHandler:^(NSError *error) {
        completionHandler(error);
    }];
}

- (void)fetchConversationWithRef:(QredoConversationRef *)conversationRef
              completionHandler:(void(^)(QredoConversation* conversation, NSError *error))completionHandler
{
    QredoVault *vault = [self systemVault];

    [vault getItemWithDescriptor:conversationRef.vaultItemDescriptor
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


- (void)deleteConversationWithRef:(QredoConversationRef *)conversationRef
               completionHandler:(void(^)(NSError *error))completionHandler
{
    [self fetchConversationWithRef:conversationRef
                completionHandler:^(QredoConversation *conversation, NSError *error)
     {
         if (error) {
             completionHandler(error);
             return ;
         }
         
         [conversation deleteConversationWithCompletionHandler:completionHandler];
     }];
}


- (void)activateRendezvousWithRef:(QredoRendezvousRef *)ref
              duration:(NSNumber *)duration
              completionHandler:(void (^)(QredoRendezvous *rendezvous, NSError *error))completionHandler

{
    
    if (completionHandler == nil) {
        
        NSException* myException = [NSException
                                    exceptionWithName:@"NilCompletionHandler"
                                    reason:@"CompletionHandlerisNil"
                                    userInfo:nil];
        @throw myException;
        
    }
    
    // validate that the duration is >= 0 and that the RendezvousRef is not nil
      if ([duration longValue] < 0)

    {
        NSString *message =  @"'The Rendezvous duration must not be negative";

        QredoLogError(@"%@", message);
        NSError *error = [NSError errorWithDomain:QredoErrorDomain
                                             code:QredoErrorCodeRendezvousInvalidData
                                         userInfo:@{ NSLocalizedDescriptionKey : message }];
        completionHandler(nil, error);
        return;
    }
    

    // get the Rendezvous using the ref
    [self fetchRendezvousWithRef: ref completionHandler:^(QredoRendezvous *rendezvous, NSError *error) {
        
        if (error) {
            completionHandler(nil, error);
            return ;
        }
        
        
      [rendezvous activateRendezvous:duration completionHandler:^(NSError *error)
           {
               if (error) {
                   completionHandler(nil, error);
               } else {
                   completionHandler(rendezvous, nil);
               }
            }
         ];
        }
     ];
    
    
}


- (void)deactivateRendezvousWithRef:(QredoRendezvousRef *)ref
           completionHandler:(void (^)(NSError *))completionHandler

{
    
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
            completionHandler(error);
            return ;
        }
        
    [rendezvous deactivateRendezvous:^(NSError *error) {
        
         completionHandler(error);
      }];
        
          
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

- (BOOL)deleteCurrentDataWithError:(NSError **)error {
    if (!_systemVault || !_defaultVault) {
        return YES;
    }

    [_systemVault clearAllData];
    [_defaultVault clearAllData];

    return [self deleteDefaultVaultKeychainWithError:error];
}

- (void)createSystemVaultWithUserCredentials:(QredoUserCredentials*)userCredentials completionHandler:(void(^)(NSError *error))completionHandler{
    [self deleteCurrentDataWithError:nil];

    [self createDefaultKeychain:userCredentials];
    [self initializeVaults];

    [self addDeviceToVaultWithCompletionHandler:completionHandler];
}

- (void)initializeVaults {
    _systemVault = [[QredoVault alloc] initWithClient:self vaultKeys:_keychain.systemVaultKeys  withLocalIndex:NO];

    if (self.clientOptions.disableMetadataIndex==YES){
        _defaultVault = [[QredoVault alloc] initWithClient:self vaultKeys:_keychain.defaultVaultKeys withLocalIndex:NO];
    }else{
        _defaultVault = [[QredoVault alloc] initWithClient:self vaultKeys:_keychain.defaultVaultKeys withLocalIndex:YES];
    }
    
}

- (id<QredoKeychainArchiver>)qredoKeychainArchiver
{
    return [QredoKeychainArchivers defaultQredoKeychainArchiver];
}

- (void)createDefaultKeychain:(QredoUserCredentials*)userCredentials
{
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
    [self deleteCurrentDataWithError:nil];

    id<QredoKeychainArchiver> keychainArchiver = [self qredoKeychainArchiver];
    BOOL result = [self saveSystemVaultKeychain:keychain
               withKeychainWithKeychainArchiver:keychainArchiver
                                          error:error];

    QredoClient *newClient = [[QredoClient alloc] initWithServiceURL:
                              [NSURL URLWithString:keychain.operatorInfo.serviceUri]
                              appCredentials:_appCredentials];
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

@end