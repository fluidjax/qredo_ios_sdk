/* HEADER GOES HERE */

#import <Foundation/Foundation.h>

#define ASN1_INTEGER_TAG       0x02
#define ASN1_BIT_STRING_TAG    0x03
#define ASN1_OCTET_STRING_TAG  0x04
#define ASN1_NULL_TAG          0x05
#define ASN1_OBJECT_IDENTIFIER 0x06
#define ASN1_SEQUENCE_TAG      0x30

typedef NS_ENUM (uint8_t,QredoAsn1ObjectIdentifier) {
    QredoAsn1ObjectIdentifierNotSet = 0,
    QredoAsn1ObjectIdentifierUnknown,
    QredoAsn1ObjectIdentifierRsa,
};

@interface QredoDerUtils :NSObject

+(NSData *)getRsaIdentifier;
+(BOOL)findOffsetOfDataWithExpectedTag:(uint8_t)expectedTag atOffset:(int)offset withinData:(NSData *)data offsetOfData:(int *)offsetOfData lengthOfData:(int *)lengthOfData;
+(NSData *)getLengthBytesForDataLength:(NSUInteger)dataLength;
+(QredoAsn1ObjectIdentifier)getIdentifierFromData:(NSData *)objectIdentifierData;
+(NSData *)wrapData:(NSData *)data withTagData:(NSData *)tagData;
+(NSData *)wrapData:(NSData *)data withTag:(uint8_t)tag;
+(NSData *)wrapByte:(uint8_t)byte withTag:(uint8_t)tag;
+(NSData *)getObjectIdentifierDataForIdentifier:(QredoAsn1ObjectIdentifier)identifier;

@end
