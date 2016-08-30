/*
 *  Copyright (c) 2011-2016 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRsaPublicKey.h"
#import "QredoCrypto.h"
#import "QredoDerUtils.h"
#import "QredoLoggerPrivate.h"

@interface QredoRsaPublicKey ()

// 'Private' setters
@property (nonatomic, strong) NSData *modulus;
@property (nonatomic, strong) NSData *publicExponent;

@end

@implementation QredoRsaPublicKey

- (instancetype) init
{
    // We do not want to be initialised via the NSObect init method as we require arguments (no public setter properties)
    NSAssert(NO, @"Use -initWithPkcs1KeyData: or initWithModulus:");
    return nil;
}

- (instancetype)initWithModulus:(NSData*)modulus publicExponent:(NSData*)publicExponent
{
    if (!modulus)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Modulus argument is nil"]
                                     userInfo:nil];
    }
    
    if (!publicExponent)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Public Exponent argument is nil"]
                                     userInfo:nil];
    }

    self = [super init];
    if (self)
    {
        _modulus = modulus;
        _publicExponent = publicExponent;
    }
    
    return self;
}

- (instancetype)initWithPkcs1KeyData:(NSData*)keyData
{
    if (!keyData)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Key data argument is nil"]
                                     userInfo:nil];
    }
    
    self = [super init];
    if (self)
    {
        if (![self populatePublicKeyComponentsFromPublicKeyPkcs1Data:keyData])
        {
            // Something went wrong
            return nil;
        }
    }
    
    return self;
}

- (instancetype)initWithX509KeyData:(NSData*)keyData
{
    if (!keyData)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Key data argument is nil"]
                                     userInfo:nil];
    }
    
    self = [super init];
    if (self)
    {
        if (![self populatePublicKeyComponentsFromPublicKeyX509Data:keyData])
        {
            // Something went wrong
            return nil;
        }
    }
    
    return self;
}


- (NSData*)convertKeyToNSData
{
    // Override the QredoKey stuf - default format will be X.509, as it's interchangeable with BouncyCastle
    return [self convertToX509Format];
}

- (BOOL)populatePublicKeyComponentsFromPublicKeyX509Data:(NSData*)publicKeyData
{
    /*
     
     RSA Public key file X.509/SubjectPublicKeyInfo DER format
     
     PublicKeyInfo ::= SEQUENCE {
     algorithm AlgorithmIdentifier,
     PublicKey BIT STRING
     }
     
     AlgorithmIdentifier ::= SEQUENCE {
     algorithm ALGORITHM.id,
     parameters ALGORITHM.type OPTIONAL
     }
     
     RSAPublicKey ::= SEQUENCE {
     modulus           INTEGER,  -- n
     publicExponent    INTEGER   -- e
     }
     
     ASN.1 INTEGER marker is 0x02
     ASN.1 BIT STRING marker is 0x03
     ASN.1 NULL marker is 0x05
     ASN.1 OBJECT IDENTIFIER marker is 0x06
     ASN.1 SEQUENCE marker is 0x30
     
     So data should be in format (concatenated):
     0x30 <total length encoding>
        0x30 <algorithm identifier length encoding>
            0x06 <object identifier length encoding> <object ID>
            0x05 0x00 (BouncyCastle put a NULL after the Object ID)
        0x03 <length of PKCS1 data encoding>
            0x30 <total length encoding of following key data>
                0x02 <modulus length encoding> <modulus>
                0x02 <public exponent length encoding> <public exponent>
     
     Note that due to INTEGER in ASN.1 being encoded as 2's complement, 0x00 may be prepended onto odd numbers, which may or may not need to be removed/handled.
     
     */
    
    
    // This method will parse the first SEQUENCE section, and extract the PKCS#1 data, and then pass that data onto the other parser for processing of the actual key data
    
    BOOL dataIsValid = YES;
    
    if (!publicKeyData)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Public key data argument is nil"]
                                     userInfo:nil];
    }
    
    int currentOffset = 0;
    int dataOffset = 0;
    int dataLength = 0;
    NSData *objectIdentifier = nil;
    NSData *pkcs1KeyData = nil;
    
    // Process the SEQUENCE tag (don't need the data, but do need the data offset)
    dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_SEQUENCE_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    
    if (dataIsValid)
    {
        // SEQUENCE tag found.  Move to the start of the data, which should be the SEQUENCE field for the algorithm identifier
        currentOffset = dataOffset;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_SEQUENCE_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // SEQUENCE (algorithm identifier) tag found.  Move to the start of the data, which should be the OBJECT IDENTIFIER field signifying RSA
        currentOffset = dataOffset;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_OBJECT_IDENTIFIER atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // OBJECT IDENTIFIER tag found, should signify RSA
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        objectIdentifier = [publicKeyData subdataWithRange:dataRange];
        
        // Validate the object identifier is RSA
        QredoAsn1ObjectIdentifier identifier = [QredoDerUtils getIdentifierFromData:objectIdentifier];
        if (identifier != QredoAsn1ObjectIdentifierRsa)
        {
            QredoLogError(@"Object Identifier did not indicate RSA.  Interpreted enum: %d. Actual OID data: %@.", identifier, [QredoLogger hexRepresentationOfNSData:objectIdentifier]);
            dataIsValid = NO;
        }
    }
    
    if (dataIsValid)
    {
        //Move to the end of the data, which may be a NULL field (otherwise, should be a BIT STRING field for the following PKCS#1 key data)
        currentOffset = dataOffset + dataLength;
        
        BOOL nullPresent = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_NULL_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
        if (nullPresent)
        {
            // Move past the NULL, ready for the BIT SEQUENCE which should follow
            currentOffset = dataOffset + dataLength;
        }
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_BIT_STRING_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // BIT STRING tag (for PKCS#1 key data) found.

        // In a BIT STRING the leading byte in the data (value) field is the number of unused bits in the final byte.  This should be zero in RSA keys.
        
        // Sanity check the lengths (as will be doing length subtraction).
        // Min length = 00 30 <min length of modulus 00> 30 <min length of exponent 00> = 5 bytes
#define MIN_LENGTH_OF_PUBLIC_KEY_BIT_STRING 5
        if (dataLength < MIN_LENGTH_OF_PUBLIC_KEY_BIT_STRING)
        {
            QredoLogError(@"Public key bit string is too short (%d bytes). Should be at least %d bytes.", dataLength, MIN_LENGTH_OF_PUBLIC_KEY_BIT_STRING);
            dataIsValid = NO;
        }
    }
    
    if (dataIsValid)
    {
        // Verify unused bits is zero
#define NO_UNUSED_BITS 0
        const uint8_t* dataBytes = publicKeyData.bytes;
        if (dataBytes[dataOffset] != NO_UNUSED_BITS)
        {
            QredoLogError(@"Unused bits value (%d) incorrect. Should be %d.", dataBytes[dataOffset], NO_UNUSED_BITS);
            dataIsValid = NO;
       }
    }
    
    if (dataIsValid)
    {
        // Adjust the offsets/lengths to remove the unused bits marker;
#define UNUSED_BITS_MARKER_LENGTH 1
        dataOffset += UNUSED_BITS_MARKER_LENGTH;
        dataLength -= UNUSED_BITS_MARKER_LENGTH;
        
        // Get a range to get the PKCS#1 data
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        
        pkcs1KeyData = [publicKeyData subdataWithRange:dataRange];
        
        // Now pass the PKCS#1 data to the other parse function which will populate the instance variables
        dataIsValid = [self populatePublicKeyComponentsFromPublicKeyPkcs1Data:pkcs1KeyData];
    }
    
    return dataIsValid;
}

- (BOOL)populatePublicKeyComponentsFromPublicKeyPkcs1Data:(NSData*)publicKeyData
{
    /*
     
     RSA Public key file PKCS#1 DER format
     
     RSAPublicKey ::= SEQUENCE {
     modulus           INTEGER,  -- n
     publicExponent    INTEGER   -- e
     }
     
     ASN.1 SEQUENCE marker is 0x30
     ASN.1 INTEGER marker is 0x02
     
     So data should be in format (concatenated):
     0x30 <total length encoding >
        0x02 <modulus length encoding> <modulus>
        0x02 <public exponent length encoding> <public exponent>
     
     Note that due to INTEGER in ASN.1 being encoded as 2's complement, 0x00 may be prepended onto odd numbers, which may or may not need to be removed/handled.
     
     */
    
    BOOL dataIsValid = YES;
    
    if (!publicKeyData)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Public key data argument is nil"]
                                     userInfo:nil];
    }
    
    int currentOffset = 0;
    int dataOffset = 0;
    int dataLength = 0;
    NSData *modulus = nil;
    NSData *publicExponent = nil;
    
    // Process the SEQUENCE tag (don't need the data, but do need the data offset)
    dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_SEQUENCE_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    
    if (dataIsValid)
    {
        // SEQUENCE tag found.  Move to the start of the data, which should be the modulus INTEGER field
        currentOffset = dataOffset;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_INTEGER_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // INTEGER (modulus) tag found.
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        modulus = [publicKeyData subdataWithRange:dataRange];
        
        //Move to the end of the data, which should be the public exponent INTEGER field
        currentOffset = dataOffset + dataLength;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_INTEGER_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // INTEGER (public exponent) tag found.
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        publicExponent = [publicKeyData subdataWithRange:dataRange];
        
        // Now populate the instance variables (not via properties as we're being called from constructor)
        _modulus = modulus;
        _publicExponent = publicExponent;
        
    }

    return dataIsValid;
}

- (NSData*)convertToPkcs1Format
{
    /*
     
     RSA Public key file PKCS#1 DER format
     
     RSAPublicKey ::= SEQUENCE {
     modulus           INTEGER,  -- n
     publicExponent    INTEGER   -- e
     }
     
     ASN.1 SEQUENCE marker is 0x30
     ASN.1 INTEGER marker is 0x02
     
     So data should be in format (concatenated):
     0x30 <total length encoding >
        0x02 <modulus length encoding> <modulus>
        0x02 <public exponent length encoding> <public exponent>
     
     Note that due to INTEGER in ASN.1 being encoded as 2's complement, 0x00 may be prepended onto odd numbers, which may or may not need to be removed/handled.
     
     */

    NSMutableData *dataToWrap = [[NSMutableData alloc] init];
    [dataToWrap appendData:[QredoDerUtils wrapData:self.modulus withTag:ASN1_INTEGER_TAG]];
    [dataToWrap appendData:[QredoDerUtils wrapData:self.publicExponent withTag:ASN1_INTEGER_TAG]];

    NSData *wrappedData = [QredoDerUtils wrapData:dataToWrap withTag:ASN1_SEQUENCE_TAG];
    return wrappedData;
}

- (NSData*)convertToX509Format
{
    /*
     
     RSA Public key file X.509/SubjectPublicKeyInfo DER format
     
     PublicKeyInfo ::= SEQUENCE {
     algorithm AlgorithmIdentifier,
     PublicKey BIT STRING
     }
     
     AlgorithmIdentifier ::= SEQUENCE {
     algorithm ALGORITHM.id,
     parameters ALGORITHM.type OPTIONAL
     }
     
     RSAPublicKey ::= SEQUENCE {
     modulus           INTEGER,  -- n
     publicExponent    INTEGER   -- e
     }
     
     ASN.1 INTEGER marker is 0x02
     ASN.1 BIT STRING marker is 0x03
     ASN.1 NULL marker is 0x05
     ASN.1 OBJECT IDENTIFIER marker is 0x06
     ASN.1 SEQUENCE marker is 0x30
     
     So data should be in format (concatenated):
     0x30 <total length encoding>
        0x30 <algorithm identifier length encoding>
            0x06 <object identifier length encoding> <object ID>
            0x05 0x00 (BouncyCastle put a NULL after the Object ID)
        0x03 <length of PKCS1 data encoding>
            0x30 <total length encoding of following key data>
                0x02 <modulus length encoding> <modulus>
                0x02 <public exponent length encoding> <public exponent>
     
     Note that due to INTEGER in ASN.1 being encoded as 2's complement, 0x00 may be prepended onto odd numbers, which may or may not need to be removed/handled.
     
     */
    
    // Wrap the RSA object identifier and NULL (Bouncy castle provides a NULL tag after OBJECT IDENTIFIER, presumably optional parameters) to form the AlgorithmIdentifier element
    NSMutableData *algorithmIdentifier = [[NSMutableData alloc] init];
    [algorithmIdentifier appendData:[QredoDerUtils wrapData:[QredoDerUtils getObjectIdentifierDataForIdentifier:QredoAsn1ObjectIdentifierRsa] withTag:ASN1_OBJECT_IDENTIFIER]];
    [algorithmIdentifier appendData:[QredoDerUtils wrapData:nil withTag:ASN1_NULL_TAG]];

    // Wrap the RSA object identifier and NULL (Bouncy castle provides a NULL tag after OBJECT IDENTIFIER, presumably optional parameters) to form the AlgorithmIdentifier element
    NSMutableData *algorithmIdentifierSequence = [[NSMutableData alloc] init];
    [algorithmIdentifierSequence appendData:[QredoDerUtils wrapData:algorithmIdentifier withTag:ASN1_SEQUENCE_TAG]];
    
    // Now onto the RSAPublicKey part.
    // The BIT STRING is special and has a byte added to the start of the data defining the number of
    // unused bits at end of data.  In this situation, the number of unused bits will always be zero,
    // but we need to add it onto the start of the data.
    // So, initialise it with length 1 (zero initialised), then append the PKCS#1 data
    NSMutableData *pkcs1PublicKeyData = [[NSMutableData alloc] initWithLength:1];
    [pkcs1PublicKeyData appendData:[self convertToPkcs1Format]];
    
    // Wrap the PKCS#1 formatted data (with 00 added to start) with a BIT STRING tag to form the PublicKey element
    NSData *publicKey = [QredoDerUtils wrapData:pkcs1PublicKeyData withTag:ASN1_BIT_STRING_TAG];

    // Append the PublicKey onto the algorithm identifier SEQUENCE before wrapping in SEQUENCE tag to finish
    [algorithmIdentifierSequence appendData:publicKey];
    NSData *wrappedData = [QredoDerUtils wrapData:algorithmIdentifierSequence withTag:ASN1_SEQUENCE_TAG];
    return wrappedData;
}

@end