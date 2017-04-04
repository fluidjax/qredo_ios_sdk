/* HEADER GOES HERE */
#import <Foundation/Foundation.h>

/** A collection of utility functions for converting between keys, hex data strings and readable words.
 [RFC1751](https://tools.ietf.org/html/rfc1751) is a standard for the representation of binary keys as 3 or 4 character English words.
 
 This class includes RFC1751 compliant methods and a non-compliant implementation designed for smaller, low entropy keys */

@interface QredoUtils :NSObject

/** RFC1751 compliant method to convert between a key and a readable English string
 This supports keys of at least 16 bytes in multiples of 8 bytes
 
 @param key The key to convert into a string */

+(NSString *)rfc1751Key2Eng:(NSData *)key;

/** Convert a readable string back into a key. RFC1751 compliant.
 
 @param english The string to convert
 */

+(NSData *)rfc1751Eng2Key:(NSString *)english;


/** Non RFC1751 method to convert between a readable string and a key.
 This supports smaller keys, used for the low entropy Rendezvous tags used during testing
 
 @param english The string to convert
 @return The original key as a NSData object
 */
+(NSData *)eng2Key:(NSString *)english;


/** Non RFC1751 method to convert between key to a readable string.
 Supports the generation of a words with no parity check, supporting smaller keys.
 Used to convert low entropy Rendezvous tags to strings
 
 @param key The data to convert to a String
 @return The readable text string
 */

+(NSString *)key2Eng:(NSData *)key;

/** Generate a random key of the specified size in bytes.
 Used to create a random tag by createAnonymousRendezvousWithTagType */

+(NSData *)randomKey:(NSUInteger)size;

/** Generates random bytes of the specified length */
+(NSData *)randomBytesOfLength:(NSUInteger)size;

/** Converts the specified data, such as a key or fingerprint into a hex string. Used to store the Rendezvous tag as a string */
+(NSString *)dataToHexString:(NSData *)data;

/** Converts the hexstring into a NSData object. Used to get an object to pass to eng2Key */
+(NSData *)hexStringToData:(NSString *)hexString;
@end


/** Helper Class to faciliate the easy creation of Diffie Hellman Channels. Use for exchanging Rendezvous over an insecure communciations channel.
 
 - Device 1 sends publicKey to Device 2
 
 - Device 2 sends publicKey to Device 1
 
 - Device 1 sends encrypted message to Device 2
 
 - Device 2 decrypts message from device 1
 */


@interface QredoSecureChannel :NSObject


/** Generates and returns a public key for the Diffie Hellman channel */
-(NSString *)publicKey;


/** Sets the public key for the remote device */
-(void)setRemotePublicKey:(NSString *)key;

/** Encrypt/decrypt data to uses in the Diffie Hellman channel
 NSString methods wrap up the NSData versions for ease of use*/

/** Encrypt a string to use in the Diffie Hellman channel */
-(NSString *)encryptString:(NSString *)message;

/** Decrypt a string from the Diffie Hellman channel */
-(NSString *)decryptString:(NSString *)cipherText;

/** Encrypt the specified data */
-(NSData *)encrypt:(NSData *)message;

/** Decrypt the specified data */
-(NSData *)decrypt:(NSData *)cipherText;
@end
