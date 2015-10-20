/*
 *  Copyright (c) 2011-2014 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "QredoRsaPrivateKey.h"
#import "QredoDerUtils.h"
#import "QredoLogging.h"

#define PKCS_FORMAT_VERSION_LENGTH 1
#define PKCS8_SUPPORTED_FORMAT_VERSION 0
#define PKCS1_SUPPORTED_FORMAT_VERSION 0

@interface QredoRsaPrivateKey ()

// 'Private' setters
@property (nonatomic, strong) NSData *version;
@property (nonatomic, strong) NSData *modulus;
@property (nonatomic, strong) NSData *publicExponent;
@property (nonatomic, strong) NSData *privateExponent;
@property (nonatomic, strong) NSData *crtPrime1;
@property (nonatomic, strong) NSData *crtPrime2;
@property (nonatomic, strong) NSData *crtExponent1;
@property (nonatomic, strong) NSData *crtExponent2;
@property (nonatomic, strong) NSData *crtCoefficient;

@end

@implementation QredoRsaPrivateKey

- (instancetype) init
{
    // We do not want to be initialised via the NSObect init method as we require arguments (no public setter properties)
    NSAssert(NO, @"Use -initWithPkcs1KeyData: or initWithModulus:");
    return nil;
}

- (instancetype)initWithModulus:(NSData*)modulus publicExponent:(NSData*)publicExponent privateExponent:(NSData*)privateExponent crtPrime1:(NSData*)crtPrime1 crtPrime2:(NSData*)crtPrime2 crtExponent1:(NSData*)crtExponent1  crtExponent2:(NSData*)crtExponent2 crtCoefficient:(NSData*)crtCoefficient
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
    
    if (!privateExponent)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Private Exponent argument is nil"]
                                     userInfo:nil];
    }
    
    if (!crtPrime1)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"CRT Prime 1 argument is nil"]
                                     userInfo:nil];
    }
    
    if (!crtPrime2)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"CRT Prime 2 argument is nil"]
                                     userInfo:nil];
    }
    
    if (!crtExponent1)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"CRT Exponent 1 argument is nil"]
                                     userInfo:nil];
    }
    
    if (!crtExponent2)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"CRT Exponent 2 argument is nil"]
                                     userInfo:nil];
    }
    
    if (!crtCoefficient)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"CRT Coefficient argument is nil"]
                                     userInfo:nil];
    }
    
    self = [super init];
    if (self)
    {
        _modulus = modulus;
        _publicExponent = publicExponent;
        _privateExponent = privateExponent;
        _crtPrime1 = crtPrime1;
        _crtPrime2 = crtPrime2;
        _crtExponent1 = crtExponent1;
        _crtExponent2 = crtExponent2;
        _crtCoefficient = crtCoefficient;
    }
    
    return self;
}


- (instancetype)initWithPkcs1KeyData:(NSData*)keyData
{
    if (!keyData)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Key identifier argument is nil"]
                                     userInfo:nil];
    }
    
    self = [super init];
    if (self)
    {
        if (![self populatePrivateKeyComponentsFromPrivateKeyPkcs1Data:keyData])
        {
            // Something went wrong
            return nil;
        }
    }
    
    return self;
}

- (instancetype)initWithPkcs8KeyData:(NSData*)keyData
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
        if (![self populatePrivateKeyComponentsFromPublicKeyPkcs8Data:keyData])
        {
            // Something went wrong
            return nil;
        }
    }
    
    return self;
}

- (NSData*)convertKeyToNSData
{
    // Override the QredoKey stuf - default format will be PKCS#8, as it's interchangeable with BouncyCastle
    return [self convertToPkcs8Format];
}

- (BOOL)populatePrivateKeyComponentsFromPublicKeyPkcs8Data:(NSData*)privateKeyData
{
    /*
     
     RSA Private key file PKCS#8 DER format
     
     PrivateKeyInfo ::= SEQUENCE {
     version Version,
     privateKeyAlgorithm PrivateKeyAlgorithmIdentifier,
     privateKey PrivateKey,
     attributes [0] IMPLICIT Attributes OPTIONAL
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
     ASN.1 OCTET STRING marker is 0x04
     ASN.1 NULL marker is 0x05
     ASN.1 OBJECT IDENTIFIER marker is 0x06
     ASN.1 SEQUENCE marker is 0x30
     
     So data should be in format (concatenated):
     0x30 <total length encoding>
        0x02 <version length encoding - 0x01> <version - 0x00>
        0x30 <algorithm identifier length encoding>
            0x06 <object identifier length encoding> <object ID>
            0x05 0x00 (BouncyCastle put a NULL after the Object ID)
        0x04 <length of PKCS1 data encoding>
            0x30 <total length encoding of following key data>
                0x30 <total length encoding >
                0x02 <version length encoding - 0x01> <version - 0x00
                0x02 <modulus length encoding> <modulus>
                0x02 <public exponent length encoding> <public exponent>
                0x02 <private exponent length encoding> <private exponent>
                0x02 <prime1 length encoding> <prime1>
                0x02 <prime2 length encoding> <prime2>
                0x02 <exponent1 length encoding> <exponent1>
                0x02 <exponent2 length encoding> <exponent2>
                0x02 <coefficient length encoding> <coefficient>
     
     Note that due to INTEGER in ASN.1 being encoded as 2's complement, 0x00 may be prepended onto odd numbers, which may or may not need to be removed/handled.
     
     */
    
    
    // This method will parse the first SEQUENCE section, and extract the PKCS#1 data, and then pass that data onto the other parser for processing of the actual key data
    
    BOOL dataIsValid = YES;
    
    if (!privateKeyData)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Private key data argument is nil"]
                                     userInfo:nil];
    }
    
    int currentOffset = 0;
    int dataOffset = 0;
    int dataLength = 0;
    NSData *version = nil;
    NSData *objectIdentifier = nil;
    NSData *pkcs1KeyData = nil;
    
    // Process the SEQUENCE tag (don't need the data, but do need the data offset)
    dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_SEQUENCE_TAG atOffset:currentOffset withinData:privateKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    
    if (dataIsValid)
    {
        // SEQUENCE tag found.  Move to the start of the data, which should be the INTEGER field for the outer version
        currentOffset = dataOffset;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_INTEGER_TAG atOffset:currentOffset withinData:privateKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }

    if (dataIsValid)
    {
        // INTEGER (version) tag found.
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        version = [privateKeyData subdataWithRange:dataRange];
        
        // Check the Version field is present and correct length
        if ((!version) || (version.length != PKCS_FORMAT_VERSION_LENGTH))
        {
            dataIsValid = NO;
        }
        
        // Verify the Version field matches our expected value (otherwise format is not what we can process)
        if (dataIsValid)
        {
            const uint8_t *versionBytes = version.bytes;
            
            if (versionBytes[0] != PKCS8_SUPPORTED_FORMAT_VERSION)
            {
                dataIsValid = NO;
            }
        }
    }
    
    if (dataIsValid)
    {
        //Move to the end of the data, which should be the SEQUENCE field for the algorithm identifier
        currentOffset = dataOffset + dataLength;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_SEQUENCE_TAG atOffset:currentOffset withinData:privateKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // SEQUENCE (algorithm identifier) tag found.  Move to the start of the data, which should be the OBJECT IDENTIFIER field signifying RSA
        currentOffset = dataOffset;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_OBJECT_IDENTIFIER atOffset:currentOffset withinData:privateKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // OBJECT IDENTIFIER tag found, should signify RSA
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        objectIdentifier = [privateKeyData subdataWithRange:dataRange];
        
        // Validate the object identifier is RSA
        QredoAsn1ObjectIdentifier identifier = [QredoDerUtils getIdentifierFromData:objectIdentifier];
        if (identifier != QredoAsn1ObjectIdentifierRsa)
        {
            LogError(@"Object Identifier did not indicate RSA.  Interpreted enum: %d. Actual OID data: %@.", identifier, [QredoLogging hexRepresentationOfNSData:objectIdentifier]);
            dataIsValid = NO;
        }
    }
    
    if (dataIsValid)
    {
        // Move to the end of the data, which may be a NULL field (otherwise, should be a BIT STRING field for the following PKCS#1 key data)
        currentOffset = dataOffset + dataLength;
        
        BOOL nullPresent = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_NULL_TAG atOffset:currentOffset withinData:privateKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
        if (nullPresent)
        {
            // Move past the NULL, ready for the BIT SEQUENCE which should follow
            currentOffset = dataOffset + dataLength;
        }
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_OCTET_STRING_TAG atOffset:currentOffset withinData:privateKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // OCTET STRING tag (for PKCS#1 key data) found.

        // Get a range to get the PKCS#1 data
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        
        pkcs1KeyData = [privateKeyData subdataWithRange:dataRange];
        
        // Now pass the PKCS#1 data to the other parse function which will populate the instance variables
        dataIsValid = [self populatePrivateKeyComponentsFromPrivateKeyPkcs1Data:pkcs1KeyData];
    }
    
    return dataIsValid;
}

- (BOOL)populatePrivateKeyComponentsFromPrivateKeyPkcs1Data:(NSData*)publicKeyData
{
    /*
     
     RSA Private key file PKCS#1 DER format
     
     RSAPrivateKey ::= SEQUENCE {
     version           Version, (INTEGER)
     modulus           INTEGER,  -- n
     publicExponent    INTEGER,  -- e
     privateExponent   INTEGER,  -- d
     prime1            INTEGER,  -- p
     prime2            INTEGER,  -- q
     exponent1         INTEGER,  -- d mod (p-1)
     exponent2         INTEGER,  -- d mod (q-1)
     coefficient       INTEGER,  -- (inverse of q) mod p
     otherPrimeInfos   OtherPrimeInfos OPTIONAL
     }
     
     CRT name equivalents for other common names:
     D = PrivateExponent
     P = Prime1
     Q = Prime2
     DP = Exponent1
     DQ = Exponent2
     InverseQ = Coefficient
     
     ASN.1 SEQUENCE marker is 0x30
     ASN.1 INTEGER marker is 0x02
     
     So data should be in format (concatenated):
     0x30 <total length encoding >
        0x02 <version length encoding> <version>
        0x02 <modulus length encoding> <modulus>
        0x02 <public exponent length encoding> <public exponent>
        0x02 <private exponent length encoding> <private exponent>
        0x02 <prime1 length encoding> <prime1>
        0x02 <prime2 length encoding> <prime2>
        0x02 <exponent1 length encoding> <exponent1>
        0x02 <exponent2 length encoding> <exponent2>
        0x02 <coefficient length encoding> <coefficient>
     
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
    NSData *version = nil;
    NSData *modulus = nil;
    NSData *publicExponent = nil;
    NSData *privateExponent = nil;
    NSData *prime1 = nil;
    NSData *prime2 = nil;
    NSData *exponent1 = nil;
    NSData *exponent2 = nil;
    NSData *coefficient = nil;
    
    // Process the SEQUENCE tag (don't need the data, but do need the data offset)
    dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_SEQUENCE_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    
    if (dataIsValid)
    {
        // SEQUENCE tag found.  Move to the start of the data, which should be the version INTEGER field
        currentOffset = dataOffset;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_INTEGER_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // INTEGER (version) tag found.
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        version = [publicKeyData subdataWithRange:dataRange];

        // Check the Version field is present and correct length
        if ((!version) || (version.length != PKCS_FORMAT_VERSION_LENGTH))
        {
            dataIsValid = NO;
        }
        
        // Verify the Version field matches our expected value (otherwise format is not what we can process)
        if (dataIsValid)
        {
            const uint8_t *versionBytes = version.bytes;
            
            if (versionBytes[0] != PKCS1_SUPPORTED_FORMAT_VERSION)
            {
                dataIsValid = NO;
            }
        }
    }
    
    if (dataIsValid)
    {
        //Move to the end of the data, which should be the modulus INTEGER field
        currentOffset = dataOffset + dataLength;
        
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
        // INTEGER (modulus) tag found.
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        publicExponent = [publicKeyData subdataWithRange:dataRange];
        
        //Move to the end of the data, which should be the private exponent INTEGER field
        currentOffset = dataOffset + dataLength;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_INTEGER_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // INTEGER (private exponent) tag found.
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        privateExponent = [publicKeyData subdataWithRange:dataRange];
        
        //Move to the end of the data, which should be the prime1 INTEGER field
        currentOffset = dataOffset + dataLength;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_INTEGER_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // INTEGER (prime1) tag found.
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        prime1 = [publicKeyData subdataWithRange:dataRange];
        
        //Move to the end of the data, which should be the prime2 INTEGER field
        currentOffset = dataOffset + dataLength;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_INTEGER_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // INTEGER (prime2) tag found.
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        prime2 = [publicKeyData subdataWithRange:dataRange];
        
        //Move to the end of the data, which should be the exponent1 INTEGER field
        currentOffset = dataOffset + dataLength;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_INTEGER_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // INTEGER (exponent1) tag found.
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        exponent1 = [publicKeyData subdataWithRange:dataRange];
        
        //Move to the end of the data, which should be the exponent2 INTEGER field
        currentOffset = dataOffset + dataLength;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_INTEGER_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // INTEGER (exponent2) tag found.
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        exponent2 = [publicKeyData subdataWithRange:dataRange];
        
        //Move to the end of the data, which should be the coefficient INTEGER field
        currentOffset = dataOffset + dataLength;
        
        dataIsValid = [QredoDerUtils findOffsetOfDataWithExpectedTag:ASN1_INTEGER_TAG atOffset:currentOffset withinData:publicKeyData offsetOfData:&dataOffset lengthOfData:&dataLength];
    }
    
    if (dataIsValid)
    {
        // INTEGER (coefficient) tag found.
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        coefficient = [publicKeyData subdataWithRange:dataRange];
        
        // Now populate the instance variables (not via properties as we're being called from constructor)
        _version = version;
        _modulus = modulus;
        _publicExponent = publicExponent;
        _privateExponent = privateExponent;
        _crtPrime1 = prime1;
        _crtPrime2 = prime2;
        _crtExponent1 = exponent1;
        _crtExponent2 = exponent2;
        _crtCoefficient = coefficient;
        
    }
    
    return dataIsValid;
}

- (NSData*)convertToPkcs1Format
{
    /*
     
     RSA Private key file PKCS#1 DER format
     
     RSAPrivateKey ::= SEQUENCE {
     version           Version, (INTEGER)
     modulus           INTEGER,  -- n
     publicExponent    INTEGER,  -- e
     privateExponent   INTEGER,  -- d
     prime1            INTEGER,  -- p
     prime2            INTEGER,  -- q
     exponent1         INTEGER,  -- d mod (p-1)
     exponent2         INTEGER,  -- d mod (q-1)
     coefficient       INTEGER,  -- (inverse of q) mod p
     otherPrimeInfos   OtherPrimeInfos OPTIONAL
     }
     
     CRT name equivalents for other common names:
     D = PrivateExponent
     P = Prime1
     Q = Prime2
     DP = Exponent1
     DQ = Exponent2
     InverseQ = Coefficient
     
     ASN.1 SEQUENCE marker is 0x30
     ASN.1 INTEGER marker is 0x02
     
     So data should be in format (concatenated):
     0x30 <total length encoding >
        0x02 <version length encoding> <version>
        0x02 <modulus length encoding> <modulus>
        0x02 <public exponent length encoding> <public exponent>
        0x02 <private exponent length encoding> <private exponent>
        0x02 <prime1 length encoding> <prime1>
        0x02 <prime2 length encoding> <prime2>
        0x02 <exponent1 length encoding> <exponent1>
        0x02 <exponent2 length encoding> <exponent2>
        0x02 <coefficient length encoding> <coefficient>
     
     Note that due to INTEGER in ASN.1 being encoded as 2's complement, 0x00 may be prepended onto odd numbers, which may or may not need to be removed/handled.
     
     */
    
    NSMutableData *dataToWrap = [[NSMutableData alloc] init];
    [dataToWrap appendData:[QredoDerUtils wrapByte:PKCS1_SUPPORTED_FORMAT_VERSION withTag:ASN1_INTEGER_TAG]];
    [dataToWrap appendData:[QredoDerUtils wrapData:self.modulus withTag:ASN1_INTEGER_TAG]];
    [dataToWrap appendData:[QredoDerUtils wrapData:self.publicExponent withTag:ASN1_INTEGER_TAG]];
    [dataToWrap appendData:[QredoDerUtils wrapData:self.privateExponent withTag:ASN1_INTEGER_TAG]];
    [dataToWrap appendData:[QredoDerUtils wrapData:self.crtPrime1 withTag:ASN1_INTEGER_TAG]];
    [dataToWrap appendData:[QredoDerUtils wrapData:self.crtPrime2 withTag:ASN1_INTEGER_TAG]];
    [dataToWrap appendData:[QredoDerUtils wrapData:self.crtExponent1 withTag:ASN1_INTEGER_TAG]];
    [dataToWrap appendData:[QredoDerUtils wrapData:self.crtExponent2 withTag:ASN1_INTEGER_TAG]];
    [dataToWrap appendData:[QredoDerUtils wrapData:self.crtCoefficient withTag:ASN1_INTEGER_TAG]];

    NSData *wrappedData = [QredoDerUtils wrapData:dataToWrap withTag:ASN1_SEQUENCE_TAG];
    return wrappedData;
}

- (NSData*)convertToPkcs8Format
{
    /*
     
     RSA Private key file PKCS#8 DER format
     
     PrivateKeyInfo ::= SEQUENCE {
     version Version,
     privateKeyAlgorithm PrivateKeyAlgorithmIdentifier,
     privateKey PrivateKey,
     attributes [0] IMPLICIT Attributes OPTIONAL
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
     ASN.1 OCTET STRING marker is 0x04
     ASN.1 NULL marker is 0x05
     ASN.1 OBJECT IDENTIFIER marker is 0x06
     ASN.1 SEQUENCE marker is 0x30
     
     So data should be in format (concatenated):
     0x30 <total length encoding>
        0x02 <version length encoding - 0x01> <version - 0x00>
        0x30 <algorithm identifier length encoding>
            0x06 <object identifier length encoding> <object ID>
            0x05 0x00 (BouncyCastle put a NULL after the Object ID)
        0x04 <length of PKCS1 data encoding>
            0x30 <total length encoding of following key data>
                0x30 <total length encoding >
                0x02 <version length encoding - 0x01> <version - 0x00
                0x02 <modulus length encoding> <modulus>
                0x02 <public exponent length encoding> <public exponent>
                0x02 <private exponent length encoding> <private exponent>
                0x02 <prime1 length encoding> <prime1>
                0x02 <prime2 length encoding> <prime2>
                0x02 <exponent1 length encoding> <exponent1>
                0x02 <exponent2 length encoding> <exponent2>
                0x02 <coefficient length encoding> <coefficient>
     
     Note that due to INTEGER in ASN.1 being encoded as 2's complement, 0x00 may be prepended onto odd numbers, which may or may not need to be removed/handled.
     
     */

    // Prepare the Version data
    NSData *version = [QredoDerUtils wrapByte:PKCS8_SUPPORTED_FORMAT_VERSION withTag:ASN1_INTEGER_TAG];
    
    // Wrap the RSA object identifier and NULL (Bouncy castle provides a NULL tag after OBJECT IDENTIFIER, presumably optional parameters) to form the AlgorithmIdentifier element
    NSMutableData *algorithmIdentifier = [[NSMutableData alloc] init];
    [algorithmIdentifier appendData:[QredoDerUtils wrapData:[QredoDerUtils getObjectIdentifierDataForIdentifier:QredoAsn1ObjectIdentifierRsa] withTag:ASN1_OBJECT_IDENTIFIER]];
    [algorithmIdentifier appendData:[QredoDerUtils wrapData:nil withTag:ASN1_NULL_TAG]];
    
    // Wrap the RSA object identifier and NULL (Bouncy castle provides a NULL tag after OBJECT IDENTIFIER, presumably optional parameters) to form the AlgorithmIdentifier element
    NSMutableData *algorithmIdentifierSequence = [[NSMutableData alloc] init];
    [algorithmIdentifierSequence appendData:[QredoDerUtils wrapData:algorithmIdentifier withTag:ASN1_SEQUENCE_TAG]];
    
    // Wrap the PKCS#1 formatted data with a OCTET STRING tag to form the PublicKey element
    NSData *privateKey = [QredoDerUtils wrapData:[self convertToPkcs1Format] withTag:ASN1_OCTET_STRING_TAG];
    
    // Put the Version, AlgorithmIdentifier sequence and PrivateKey data together before wrapping in SEQUENCE tag
    NSMutableData *dataToWrap = [[NSMutableData alloc] init];
    [dataToWrap appendData:version];
    [dataToWrap appendData:algorithmIdentifierSequence];
    [dataToWrap appendData:privateKey];
    
    NSData *wrappedData = [QredoDerUtils wrapData:dataToWrap withTag:ASN1_SEQUENCE_TAG];
    return wrappedData;
}

@end
