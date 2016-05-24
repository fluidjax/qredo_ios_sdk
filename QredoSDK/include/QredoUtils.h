//
//  QredoUtils.h
//  QredoSDK
//
//  Created by Christopher Morris on 10/05/2016.
//
//

#import <Foundation/Foundation.h>


/** A collection of utility functions for converting between keys, hex data strings and readable words. [RFC1751](http://tools.ietf.org/html/rfc1751) is a standard for the representation of binary keys as 3 or 4 character English words.
 
 This class includes RFC1751 compliant methods and a non-compliant implementation designed for smaller, low
 entropy keys */

@interface QredoUtils : NSObject

/** RFC1751 compliant method to convert between a key and a readable English string
 This supports keys of at least 16 bytes in multiples of 8 bytes 
 
 @param key The key to convert into a string
 @return A string containing a series of 3 and 4 character words representing the key. All uppercase and space delimited
 */
+(NSString *)rfc1751Key2Eng:(NSData *)key;

/** Convert a readable string back into a key. RFC1751 compliant.  
 
 @param key The string to convert
 @return The original key as a NSData object

 */
+(NSData *)rfc1751Eng2Key:(NSString *)english;


/** Non RFC1751 method to convert between a readable string and a key. This supports smaller keys, used for the low entropy Rendezvous tags used during testing 
 
 @param key The string to convert
 @return The original key as a NSData object
 */
+(NSData *)eng2Key:(NSString *)english;


/** Non RFC1751 method to convert between key to a readable string. Supports the generation of a words with no parity check, supporting smaller keys. Used to convert low entropy Rendezvous tags to strings
 
 @param key The string to convert
 @return A string containing a space delimited collection of 3 or 4 character words representing the key
 */

+(NSString *)key2Eng:(NSData *)key;


/** Generate a random key of the specified size in bytes. Used to create a random tag by [createAnonymousRendezvousWithTagType](QredoClient.html#/c:objc(cs)QredoClient(im)createAnonymousRendezvousWithTagType:completionHandler:) */

+(NSData *)randomKey:(NSUInteger)size;

/** Generates random bytes of the specified length */
+(NSData*)randomBytesOfLength:(NSUInteger)size;

/** Converts the specified data, such as a key or fingerprint into a hex string. Used to store the Rendezvous tag as a string */
+(NSString *)dataToHexString:(NSData*)data;

/** Converts the hexstring into a NSData object. Used to get an object to pass to `eng2Key`  */
+(NSData *)hexStringToData:(NSString *)hexString;
@end


/** Helper Class to faciliate the easy creation of Diffie-Hellman Channels - use for exchanging Rendezvous over insecure comms
 
 
 - Device 1 sends publicKey to Device 2
 
 - Device 2 sends publicKey to Device 1
 
 - Device 1 sends an encrypted message generated with encryption to Device 2
 
 - Device 2 decrypts message from device 1
 */

@interface QredoSecureChannel : NSObject


/** generates and returns public keys for the Diffie-Hellman channel */
-(NSString*)publicKey;

/** Sets the public key for the remote device */
-(void)setRemotePublicKey:(NSString*)key;

/** Encrypt a string in the Diffie-Hellman channel. This is a wrapper around the NSData version for ease of use */
-(NSString*)encryptString:(NSString*)message;

/** Decrypt a string in the Diffie-Hellman channel. This is a wrapper around the NSData version for ease of use */
-(NSString*)decryptString:(NSString*)cipherText;

/** Encrypt data used in the Diffie-Hellman channel */
-(NSData*)encrypt:(NSData*)message;

/** Decrypt data used in the Diffie-Hellman channel */
-(NSData*)decrypt:(NSData*)cipherText;
@end

