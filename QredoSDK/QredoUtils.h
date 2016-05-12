//
//  QredoUtils.h
//  QredoSDK
//
//  Created by Christopher Morris on 10/05/2016.
//
//

#import <Foundation/Foundation.h>

@interface QredoUtils : NSObject


+(NSString *)rfc1751Key2Eng:(NSData *)key;
+(NSData *)rfc1751Eng2Key:(NSString *)english;

//Non RFC1751 compliant
//Allow generate of words without parity check
//without any key length restrictions
+(NSData *)eng2Key:(NSString *)english;
+(NSString *)key2Eng:(NSData *)key;
+(NSData *)randomKey:(NSUInteger)size;
+(NSData*)randomBytesOfLength:(NSUInteger)size;
+(NSString *)dataToHexString:(NSData*)data;
+(NSData *)hexStringToData:(NSString *)hexString;
@end




@interface QredoSecureChannel : NSObject
/* Helper Class to faciliate the easy create of Diffie Hellman Channels - use for exchanging rendezvous over insecure comms
 1) Device 1 send publicKey to Device 2
 2) Device 2 send publicKey to Device 1
 3) Device 1 send message generated with encrypt to Device 2
 4) Device 2 decrypt message from device 1
 */


/* generates and returns a public keys for the DF channel */
-(NSString*)publicKey;


/* Sets the public key for the remote device */
-(void)setRemotePublicKey:(NSString*)key;

/* Encrypt/decrypt data of ruse in the DF channel
   NSString methods wrap up the NSData versions for ease of use*/
-(NSString*)encryptString:(NSString*)message;
-(NSString*)decryptString:(NSString*)cipherText;

-(NSData*)encrypt:(NSData*)message;
-(NSData*)decrypt:(NSData*)cipherText;
@end

