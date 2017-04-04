/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

@interface QredoCertificateUtils :NSObject

+(NSString *)convertCertificateRefsToPemCertificate:(NSArray *)certificateRefs;
+(NSString *)convertKeyIdentifierToPemKey:(NSString *)keyIdentifier;
+(NSData *)getPkcs1PublicKeyDataFromUnknownPublicKeyData:(NSData *)unknownPublicKeyData;
+(NSData *)convertPemPublicKeyToDer:(NSString *)pemEncodedPublicKey;
+(NSString *)getFirstPemCertificateFromString:(NSString *)string;
+(NSArray *)splitPemCertificateChain:(NSString *)pemCertificateChain;
+(NSArray *)getCertificateRefsFromPemCertificates:(NSString *)pemCertificates;
+(NSArray *)getCertificateRefsFromPemCertificatesArray:(NSArray *)pemCertificatesArray;
+(SecKeyRef)validateCertificateChain:(NSArray *)certificateChainRefs rootCertificateRefs:(NSArray *)rootCertificateRefs;
+(NSDictionary *)createAndValidateIdentityFromPkcs12Data:(NSData *)pkcs12Data password:(NSString *)password rootCertificateRefs:(NSArray *)rootCertificateRefs;

@end
