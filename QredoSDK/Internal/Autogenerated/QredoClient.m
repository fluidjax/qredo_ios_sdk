#import <Foundation/Foundation.h>
#import "QredoHelpers.h"
#import "QredoWireFormat.h"
#import "QredoClient.h"
#import "QredoPrimitiveMarshallers.h"
#import "NSData+QredoDataEquality.h"
#import "NSArray+QredoArrayEquality.h"
#import "NSSet+QredoSetEquality.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
@implementation QLFCachedVaultItem



+ (QLFCachedVaultItem *)cachedVaultItemWithEncryptedItem:(NSData *)encryptedItem authCode:(QLFAuthCode *)authCode
{

    return [[QLFCachedVaultItem alloc] initWithEncryptedItem:encryptedItem authCode:authCode];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFCachedVaultItem *e = (QLFCachedVaultItem *)element;
        [writer writeConstructorStartWithObjectName:@"CachedVaultItem"];
            [writer writeFieldStartWithFieldName:@"authCode"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e authCode], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptedItem"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e encryptedItem], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'CachedVaultItem'
            [reader readFieldStart]; // TODO assert that field name is 'authCode'
                QLFAuthCode *authCode = (QLFAuthCode *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptedItem'
                NSData *encryptedItem = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFCachedVaultItem cachedVaultItemWithEncryptedItem:encryptedItem authCode:authCode];
    };
}

- (instancetype)initWithEncryptedItem:(NSData *)encryptedItem authCode:(QLFAuthCode *)authCode
{

    self = [super init];
    if (self) {
        _encryptedItem = encryptedItem;
        _authCode = authCode;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFCachedVaultItem *)other
{

    QREDO_COMPARE_OBJECT(encryptedItem);
    QREDO_COMPARE_OBJECT(authCode);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToCachedVaultItem:other];
       
}

- (BOOL)isEqualToCachedVaultItem:(QLFCachedVaultItem *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_encryptedItem != other.encryptedItem && ![_encryptedItem isEqual:other.encryptedItem])
        return NO;
    if (_authCode != other.authCode && ![_authCode isEqual:other.authCode])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_encryptedItem hash];
    hash = hash * 31u + [_authCode hash];
    return hash;
       
}

@end

@implementation QLFConversationAckResult



+ (QLFConversationAckResult *)conversationAckResult
{

    return [[QLFConversationAckResult alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFConversationAckResult *e = (QLFConversationAckResult *)element;
        [writer writeConstructorStartWithObjectName:@"ConversationAckResult"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'ConversationAckResult'

        [reader readEnd];
        return [QLFConversationAckResult conversationAckResult];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFConversationAckResult *)other
{

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToConversationAckResult:other];
       
}

- (BOOL)isEqualToConversationAckResult:(QLFConversationAckResult *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFConversationPublishResult



+ (QLFConversationPublishResult *)conversationPublishResultWithSequenceValue:(QLFConversationSequenceValue *)sequenceValue
{

    return [[QLFConversationPublishResult alloc] initWithSequenceValue:sequenceValue];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFConversationPublishResult *e = (QLFConversationPublishResult *)element;
        [writer writeConstructorStartWithObjectName:@"ConversationPublishResult"];
            [writer writeFieldStartWithFieldName:@"sequenceValue"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e sequenceValue], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'ConversationPublishResult'
            [reader readFieldStart]; // TODO assert that field name is 'sequenceValue'
                QLFConversationSequenceValue *sequenceValue = (QLFConversationSequenceValue *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFConversationPublishResult conversationPublishResultWithSequenceValue:sequenceValue];
    };
}

- (instancetype)initWithSequenceValue:(QLFConversationSequenceValue *)sequenceValue
{

    self = [super init];
    if (self) {
        _sequenceValue = sequenceValue;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFConversationPublishResult *)other
{

    QREDO_COMPARE_OBJECT(sequenceValue);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToConversationPublishResult:other];
       
}

- (BOOL)isEqualToConversationPublishResult:(QLFConversationPublishResult *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_sequenceValue != other.sequenceValue && ![_sequenceValue isEqual:other.sequenceValue])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_sequenceValue hash];
    return hash;
       
}

@end

@implementation QLFCtrl



+ (QLFCtrl *)qRV
{

    return [[QLFQRV alloc] init];
       
}

+ (QLFCtrl *)qRT
{

    return [[QLFQRT alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFQRV class]]) {
            [QLFQRV marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFQRT class]]) {
            [QLFQRT marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"QRV"]) {
            QLFCtrl *_temp = [QLFQRV unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"QRT"]) {
            QLFCtrl *_temp = [QLFQRT unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifQRV:(void (^)())ifQRVBlock ifQRT:(void (^)())ifQRTBlock
{
    if ([self isKindOfClass:[QLFQRV class]]) {
        ifQRVBlock();
    } else if ([self isKindOfClass:[QLFQRT class]]) {
        ifQRTBlock();
    }
}

- (NSComparisonResult)compare:(QLFCtrl *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToCtrl:(QLFCtrl *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFQRV



+ (QLFCtrl *)qRV
{

    return [[QLFQRV alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFQRV *e = (QLFQRV *)element;
        [writer writeConstructorStartWithObjectName:@"QRV"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFCtrl qRV];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFQRV *)other
{
    if ([other isKindOfClass:[QLFCtrl class]] && ![other isKindOfClass:[QLFQRV class]]) {
        // N.B. impose an ordering among subtypes of Ctrl
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToQRV:other];
       
}

- (BOOL)isEqualToQRV:(QLFQRV *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFQRT



+ (QLFCtrl *)qRT
{

    return [[QLFQRT alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFQRT *e = (QLFQRT *)element;
        [writer writeConstructorStartWithObjectName:@"QRT"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFCtrl qRT];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFQRT *)other
{
    if ([other isKindOfClass:[QLFCtrl class]] && ![other isKindOfClass:[QLFQRT class]]) {
        // N.B. impose an ordering among subtypes of Ctrl
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToQRT:other];
       
}

- (BOOL)isEqualToQRT:(QLFQRT *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFEncryptedConversationItem



+ (QLFEncryptedConversationItem *)encryptedConversationItemWithEncryptedMessage:(NSData *)encryptedMessage authCode:(QLFAuthCode *)authCode
{

    return [[QLFEncryptedConversationItem alloc] initWithEncryptedMessage:encryptedMessage authCode:authCode];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFEncryptedConversationItem *e = (QLFEncryptedConversationItem *)element;
        [writer writeConstructorStartWithObjectName:@"EncryptedConversationItem"];
            [writer writeFieldStartWithFieldName:@"authCode"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e authCode], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptedMessage"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e encryptedMessage], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'EncryptedConversationItem'
            [reader readFieldStart]; // TODO assert that field name is 'authCode'
                QLFAuthCode *authCode = (QLFAuthCode *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptedMessage'
                NSData *encryptedMessage = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFEncryptedConversationItem encryptedConversationItemWithEncryptedMessage:encryptedMessage authCode:authCode];
    };
}

- (instancetype)initWithEncryptedMessage:(NSData *)encryptedMessage authCode:(QLFAuthCode *)authCode
{

    self = [super init];
    if (self) {
        _encryptedMessage = encryptedMessage;
        _authCode = authCode;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFEncryptedConversationItem *)other
{

    QREDO_COMPARE_OBJECT(encryptedMessage);
    QREDO_COMPARE_OBJECT(authCode);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToEncryptedConversationItem:other];
       
}

- (BOOL)isEqualToEncryptedConversationItem:(QLFEncryptedConversationItem *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_encryptedMessage != other.encryptedMessage && ![_encryptedMessage isEqual:other.encryptedMessage])
        return NO;
    if (_authCode != other.authCode && ![_authCode isEqual:other.authCode])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_encryptedMessage hash];
    hash = hash * 31u + [_authCode hash];
    return hash;
       
}

@end

@implementation QLFConversationItemWithSequenceValue



+ (QLFConversationItemWithSequenceValue *)conversationItemWithSequenceValueWithItem:(QLFEncryptedConversationItem *)item sequenceValue:(QLFConversationSequenceValue *)sequenceValue
{

    return [[QLFConversationItemWithSequenceValue alloc] initWithItem:item sequenceValue:sequenceValue];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFConversationItemWithSequenceValue *e = (QLFConversationItemWithSequenceValue *)element;
        [writer writeConstructorStartWithObjectName:@"ConversationItemWithSequenceValue"];
            [writer writeFieldStartWithFieldName:@"item"];
                [QLFEncryptedConversationItem marshaller]([e item], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"sequenceValue"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e sequenceValue], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'ConversationItemWithSequenceValue'
            [reader readFieldStart]; // TODO assert that field name is 'item'
                QLFEncryptedConversationItem *item = (QLFEncryptedConversationItem *)[QLFEncryptedConversationItem unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sequenceValue'
                QLFConversationSequenceValue *sequenceValue = (QLFConversationSequenceValue *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFConversationItemWithSequenceValue conversationItemWithSequenceValueWithItem:item sequenceValue:sequenceValue];
    };
}

- (instancetype)initWithItem:(QLFEncryptedConversationItem *)item sequenceValue:(QLFConversationSequenceValue *)sequenceValue
{

    self = [super init];
    if (self) {
        _item = item;
        _sequenceValue = sequenceValue;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFConversationItemWithSequenceValue *)other
{

    QREDO_COMPARE_OBJECT(item);
    QREDO_COMPARE_OBJECT(sequenceValue);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToConversationItemWithSequenceValue:other];
       
}

- (BOOL)isEqualToConversationItemWithSequenceValue:(QLFConversationItemWithSequenceValue *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_item != other.item && ![_item isEqual:other.item])
        return NO;
    if (_sequenceValue != other.sequenceValue && ![_sequenceValue isEqual:other.sequenceValue])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_item hash];
    hash = hash * 31u + [_sequenceValue hash];
    return hash;
       
}

@end

@implementation QLFConversationQueryItemsResult



+ (QLFConversationQueryItemsResult *)conversationQueryItemsResultWithItems:(NSArray *)items maxSequenceValue:(QLFConversationSequenceValue *)maxSequenceValue current:(BOOL)current
{

    return [[QLFConversationQueryItemsResult alloc] initWithItems:items maxSequenceValue:maxSequenceValue current:current];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFConversationQueryItemsResult *e = (QLFConversationQueryItemsResult *)element;
        [writer writeConstructorStartWithObjectName:@"ConversationQueryItemsResult"];
            [writer writeFieldStartWithFieldName:@"current"];
                [QredoPrimitiveMarshallers booleanMarshaller]([NSNumber numberWithBool: [e current]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"items"];
                [QredoPrimitiveMarshallers sequenceMarshallerWithElementMarshaller:[QLFConversationItemWithSequenceValue marshaller]]([e items], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"maxSequenceValue"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e maxSequenceValue], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'ConversationQueryItemsResult'
            [reader readFieldStart]; // TODO assert that field name is 'current'
                BOOL current = (BOOL )[[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'items'
                NSArray *items = (NSArray *)[QredoPrimitiveMarshallers sequenceUnmarshallerWithElementUnmarshaller:[QLFConversationItemWithSequenceValue unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'maxSequenceValue'
                QLFConversationSequenceValue *maxSequenceValue = (QLFConversationSequenceValue *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFConversationQueryItemsResult conversationQueryItemsResultWithItems:items maxSequenceValue:maxSequenceValue current:current];
    };
}

- (instancetype)initWithItems:(NSArray *)items maxSequenceValue:(QLFConversationSequenceValue *)maxSequenceValue current:(BOOL)current
{

    self = [super init];
    if (self) {
        _items = items;
        _maxSequenceValue = maxSequenceValue;
        _current = current;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFConversationQueryItemsResult *)other
{

    QREDO_COMPARE_OBJECT(items);
    QREDO_COMPARE_OBJECT(maxSequenceValue);
    QREDO_COMPARE_SCALAR(current);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToConversationQueryItemsResult:other];
       
}

- (BOOL)isEqualToConversationQueryItemsResult:(QLFConversationQueryItemsResult *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_items != other.items && ![_items isEqual:other.items])
        return NO;
    if (_maxSequenceValue != other.maxSequenceValue && ![_maxSequenceValue isEqual:other.maxSequenceValue])
        return NO;
    if (_current != other.current)
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_items hash];
    hash = hash * 31u + [_maxSequenceValue hash];
    hash = hash * 31u + (NSUInteger)_current;
    return hash;
       
}

@end

@implementation QLFEncryptedRecoveryInfoType



+ (QLFEncryptedRecoveryInfoType *)encryptedRecoveryInfoTypeWithCredentialType:(int32_t)credentialType encryptedMasterKey:(NSData *)encryptedMasterKey
{

    return [[QLFEncryptedRecoveryInfoType alloc] initWithCredentialType:credentialType encryptedMasterKey:encryptedMasterKey];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFEncryptedRecoveryInfoType *e = (QLFEncryptedRecoveryInfoType *)element;
        [writer writeConstructorStartWithObjectName:@"EncryptedRecoveryInfoType"];
            [writer writeFieldStartWithFieldName:@"credentialType"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e credentialType]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptedMasterKey"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e encryptedMasterKey], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'EncryptedRecoveryInfoType'
            [reader readFieldStart]; // TODO assert that field name is 'credentialType'
                int32_t credentialType = (int32_t )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptedMasterKey'
                NSData *encryptedMasterKey = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFEncryptedRecoveryInfoType encryptedRecoveryInfoTypeWithCredentialType:credentialType encryptedMasterKey:encryptedMasterKey];
    };
}

- (instancetype)initWithCredentialType:(int32_t)credentialType encryptedMasterKey:(NSData *)encryptedMasterKey
{

    self = [super init];
    if (self) {
        _credentialType = credentialType;
        _encryptedMasterKey = encryptedMasterKey;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFEncryptedRecoveryInfoType *)other
{

    QREDO_COMPARE_SCALAR(credentialType);
    QREDO_COMPARE_OBJECT(encryptedMasterKey);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToEncryptedRecoveryInfoType:other];
       
}

- (BOOL)isEqualToEncryptedRecoveryInfoType:(QLFEncryptedRecoveryInfoType *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_credentialType != other.credentialType)
        return NO;
    if (_encryptedMasterKey != other.encryptedMasterKey && ![_encryptedMasterKey isEqual:other.encryptedMasterKey])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + (NSUInteger)_credentialType;
    hash = hash * 31u + [_encryptedMasterKey hash];
    return hash;
       
}

@end

@implementation QLFEncryptedKeychain



+ (QLFEncryptedKeychain *)encryptedKeychainWithCredentialType:(int32_t)credentialType encryptedKeyChain:(NSData *)encryptedKeyChain encryptedRecoveryInfo:(QLFEncryptedRecoveryInfoType *)encryptedRecoveryInfo
{

    return [[QLFEncryptedKeychain alloc] initWithCredentialType:credentialType encryptedKeyChain:encryptedKeyChain encryptedRecoveryInfo:encryptedRecoveryInfo];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFEncryptedKeychain *e = (QLFEncryptedKeychain *)element;
        [writer writeConstructorStartWithObjectName:@"EncryptedKeychain"];
            [writer writeFieldStartWithFieldName:@"credentialType"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e credentialType]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptedKeyChain"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e encryptedKeyChain], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptedRecoveryInfo"];
                [QLFEncryptedRecoveryInfoType marshaller]([e encryptedRecoveryInfo], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'EncryptedKeychain'
            [reader readFieldStart]; // TODO assert that field name is 'credentialType'
                int32_t credentialType = (int32_t )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptedKeyChain'
                NSData *encryptedKeyChain = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptedRecoveryInfo'
                QLFEncryptedRecoveryInfoType *encryptedRecoveryInfo = (QLFEncryptedRecoveryInfoType *)[QLFEncryptedRecoveryInfoType unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFEncryptedKeychain encryptedKeychainWithCredentialType:credentialType encryptedKeyChain:encryptedKeyChain encryptedRecoveryInfo:encryptedRecoveryInfo];
    };
}

- (instancetype)initWithCredentialType:(int32_t)credentialType encryptedKeyChain:(NSData *)encryptedKeyChain encryptedRecoveryInfo:(QLFEncryptedRecoveryInfoType *)encryptedRecoveryInfo
{

    self = [super init];
    if (self) {
        _credentialType = credentialType;
        _encryptedKeyChain = encryptedKeyChain;
        _encryptedRecoveryInfo = encryptedRecoveryInfo;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFEncryptedKeychain *)other
{

    QREDO_COMPARE_SCALAR(credentialType);
    QREDO_COMPARE_OBJECT(encryptedKeyChain);
    QREDO_COMPARE_OBJECT(encryptedRecoveryInfo);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToEncryptedKeychain:other];
       
}

- (BOOL)isEqualToEncryptedKeychain:(QLFEncryptedKeychain *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_credentialType != other.credentialType)
        return NO;
    if (_encryptedKeyChain != other.encryptedKeyChain && ![_encryptedKeyChain isEqual:other.encryptedKeyChain])
        return NO;
    if (_encryptedRecoveryInfo != other.encryptedRecoveryInfo && ![_encryptedRecoveryInfo isEqual:other.encryptedRecoveryInfo])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + (NSUInteger)_credentialType;
    hash = hash * 31u + [_encryptedKeyChain hash];
    hash = hash * 31u + [_encryptedRecoveryInfo hash];
    return hash;
       
}

@end

@implementation QLFKeyLF



+ (QLFKeyLF *)keyLFWithBytes:(NSData *)bytes
{

    return [[QLFKeyLF alloc] initWithBytes:bytes];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFKeyLF *e = (QLFKeyLF *)element;
        [writer writeConstructorStartWithObjectName:@"KeyLF"];
            [writer writeFieldStartWithFieldName:@"bytes"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e bytes], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'KeyLF'
            [reader readFieldStart]; // TODO assert that field name is 'bytes'
                NSData *bytes = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFKeyLF keyLFWithBytes:bytes];
    };
}

- (instancetype)initWithBytes:(NSData *)bytes
{

    self = [super init];
    if (self) {
        _bytes = bytes;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFKeyLF *)other
{

    QREDO_COMPARE_OBJECT(bytes);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToKeyLF:other];
       
}

- (BOOL)isEqualToKeyLF:(QLFKeyLF *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_bytes != other.bytes && ![_bytes isEqual:other.bytes])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_bytes hash];
    return hash;
       
}

@end

@implementation QLFKeyPairLF



+ (QLFKeyPairLF *)keyPairLFWithPubKey:(QLFKeyLF *)pubKey privKey:(QLFKeyLF *)privKey
{

    return [[QLFKeyPairLF alloc] initWithPubKey:pubKey privKey:privKey];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFKeyPairLF *e = (QLFKeyPairLF *)element;
        [writer writeConstructorStartWithObjectName:@"KeyPairLF"];
            [writer writeFieldStartWithFieldName:@"privKey"];
                [QLFKeyLF marshaller]([e privKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"pubKey"];
                [QLFKeyLF marshaller]([e pubKey], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'KeyPairLF'
            [reader readFieldStart]; // TODO assert that field name is 'privKey'
                QLFKeyLF *privKey = (QLFKeyLF *)[QLFKeyLF unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'pubKey'
                QLFKeyLF *pubKey = (QLFKeyLF *)[QLFKeyLF unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFKeyPairLF keyPairLFWithPubKey:pubKey privKey:privKey];
    };
}

- (instancetype)initWithPubKey:(QLFKeyLF *)pubKey privKey:(QLFKeyLF *)privKey
{

    self = [super init];
    if (self) {
        _pubKey = pubKey;
        _privKey = privKey;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFKeyPairLF *)other
{

    QREDO_COMPARE_OBJECT(pubKey);
    QREDO_COMPARE_OBJECT(privKey);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToKeyPairLF:other];
       
}

- (BOOL)isEqualToKeyPairLF:(QLFKeyPairLF *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_pubKey != other.pubKey && ![_pubKey isEqual:other.pubKey])
        return NO;
    if (_privKey != other.privKey && ![_privKey isEqual:other.privKey])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_pubKey hash];
    hash = hash * 31u + [_privKey hash];
    return hash;
       
}

@end

@implementation QLFOperationType



+ (QLFOperationType *)operationCreate
{

    return [[QLFOperationCreate alloc] init];
       
}

+ (QLFOperationType *)operationGet
{

    return [[QLFOperationGet alloc] init];
       
}

+ (QLFOperationType *)operationList
{

    return [[QLFOperationList alloc] init];
       
}

+ (QLFOperationType *)operationDelete
{

    return [[QLFOperationDelete alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFOperationCreate class]]) {
            [QLFOperationCreate marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFOperationGet class]]) {
            [QLFOperationGet marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFOperationList class]]) {
            [QLFOperationList marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFOperationDelete class]]) {
            [QLFOperationDelete marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"OperationCreate"]) {
            QLFOperationType *_temp = [QLFOperationCreate unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"OperationGet"]) {
            QLFOperationType *_temp = [QLFOperationGet unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"OperationList"]) {
            QLFOperationType *_temp = [QLFOperationList unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"OperationDelete"]) {
            QLFOperationType *_temp = [QLFOperationDelete unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifOperationCreate:(void (^)())ifOperationCreateBlock ifOperationGet:(void (^)())ifOperationGetBlock ifOperationList:(void (^)())ifOperationListBlock ifOperationDelete:(void (^)())ifOperationDeleteBlock
{
    if ([self isKindOfClass:[QLFOperationCreate class]]) {
        ifOperationCreateBlock();
    } else if ([self isKindOfClass:[QLFOperationGet class]]) {
        ifOperationGetBlock();
    } else if ([self isKindOfClass:[QLFOperationList class]]) {
        ifOperationListBlock();
    } else if ([self isKindOfClass:[QLFOperationDelete class]]) {
        ifOperationDeleteBlock();
    }
}

- (NSComparisonResult)compare:(QLFOperationType *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToOperationType:(QLFOperationType *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFOperationCreate



+ (QLFOperationType *)operationCreate
{

    return [[QLFOperationCreate alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFOperationCreate *e = (QLFOperationCreate *)element;
        [writer writeConstructorStartWithObjectName:@"OperationCreate"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFOperationType operationCreate];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFOperationCreate *)other
{
    if ([other isKindOfClass:[QLFOperationType class]] && ![other isKindOfClass:[QLFOperationCreate class]]) {
        // N.B. impose an ordering among subtypes of OperationType
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToOperationCreate:other];
       
}

- (BOOL)isEqualToOperationCreate:(QLFOperationCreate *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFOperationGet



+ (QLFOperationType *)operationGet
{

    return [[QLFOperationGet alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFOperationGet *e = (QLFOperationGet *)element;
        [writer writeConstructorStartWithObjectName:@"OperationGet"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFOperationType operationGet];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFOperationGet *)other
{
    if ([other isKindOfClass:[QLFOperationType class]] && ![other isKindOfClass:[QLFOperationGet class]]) {
        // N.B. impose an ordering among subtypes of OperationType
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToOperationGet:other];
       
}

- (BOOL)isEqualToOperationGet:(QLFOperationGet *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFOperationList



+ (QLFOperationType *)operationList
{

    return [[QLFOperationList alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFOperationList *e = (QLFOperationList *)element;
        [writer writeConstructorStartWithObjectName:@"OperationList"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFOperationType operationList];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFOperationList *)other
{
    if ([other isKindOfClass:[QLFOperationType class]] && ![other isKindOfClass:[QLFOperationList class]]) {
        // N.B. impose an ordering among subtypes of OperationType
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToOperationList:other];
       
}

- (BOOL)isEqualToOperationList:(QLFOperationList *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFOperationDelete



+ (QLFOperationType *)operationDelete
{

    return [[QLFOperationDelete alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFOperationDelete *e = (QLFOperationDelete *)element;
        [writer writeConstructorStartWithObjectName:@"OperationDelete"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFOperationType operationDelete];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFOperationDelete *)other
{
    if ([other isKindOfClass:[QLFOperationType class]] && ![other isKindOfClass:[QLFOperationDelete class]]) {
        // N.B. impose an ordering among subtypes of OperationType
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToOperationDelete:other];
       
}

- (BOOL)isEqualToOperationDelete:(QLFOperationDelete *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFRecoveryInfoType



+ (QLFRecoveryInfoType *)recoveryInfoTypeWithCredentialType:(int32_t)credentialType masterKey:(QLFEncryptionKey256 *)masterKey
{

    return [[QLFRecoveryInfoType alloc] initWithCredentialType:credentialType masterKey:masterKey];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRecoveryInfoType *e = (QLFRecoveryInfoType *)element;
        [writer writeConstructorStartWithObjectName:@"RecoveryInfoType"];
            [writer writeFieldStartWithFieldName:@"credentialType"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e credentialType]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"masterKey"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e masterKey], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'RecoveryInfoType'
            [reader readFieldStart]; // TODO assert that field name is 'credentialType'
                int32_t credentialType = (int32_t )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'masterKey'
                QLFEncryptionKey256 *masterKey = (QLFEncryptionKey256 *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFRecoveryInfoType recoveryInfoTypeWithCredentialType:credentialType masterKey:masterKey];
    };
}

- (instancetype)initWithCredentialType:(int32_t)credentialType masterKey:(QLFEncryptionKey256 *)masterKey
{

    self = [super init];
    if (self) {
        _credentialType = credentialType;
        _masterKey = masterKey;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRecoveryInfoType *)other
{

    QREDO_COMPARE_SCALAR(credentialType);
    QREDO_COMPARE_OBJECT(masterKey);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRecoveryInfoType:other];
       
}

- (BOOL)isEqualToRecoveryInfoType:(QLFRecoveryInfoType *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_credentialType != other.credentialType)
        return NO;
    if (_masterKey != other.masterKey && ![_masterKey isEqual:other.masterKey])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + (NSUInteger)_credentialType;
    hash = hash * 31u + [_masterKey hash];
    return hash;
       
}

@end

@implementation QLFRendezvousAuthSignature



+ (QLFRendezvousAuthSignature *)rendezvousAuthX509_PEMWithSignature:(NSData *)signature
{

    return [[QLFRendezvousAuthX509_PEM alloc] initWithSignature:signature];
       
}

+ (QLFRendezvousAuthSignature *)rendezvousAuthX509_PEM_SELFSIGNEDWithSignature:(NSData *)signature
{

    return [[QLFRendezvousAuthX509_PEM_SELFSIGNED alloc] initWithSignature:signature];
       
}

+ (QLFRendezvousAuthSignature *)rendezvousAuthED25519WithSignature:(NSData *)signature
{

    return [[QLFRendezvousAuthED25519 alloc] initWithSignature:signature];
       
}

+ (QLFRendezvousAuthSignature *)rendezvousAuthRSA2048_PEMWithSignature:(NSData *)signature
{

    return [[QLFRendezvousAuthRSA2048_PEM alloc] initWithSignature:signature];
       
}

+ (QLFRendezvousAuthSignature *)rendezvousAuthRSA4096_PEMWithSignature:(NSData *)signature
{

    return [[QLFRendezvousAuthRSA4096_PEM alloc] initWithSignature:signature];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFRendezvousAuthX509_PEM class]]) {
            [QLFRendezvousAuthX509_PEM marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFRendezvousAuthX509_PEM_SELFSIGNED class]]) {
            [QLFRendezvousAuthX509_PEM_SELFSIGNED marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFRendezvousAuthED25519 class]]) {
            [QLFRendezvousAuthED25519 marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFRendezvousAuthRSA2048_PEM class]]) {
            [QLFRendezvousAuthRSA2048_PEM marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFRendezvousAuthRSA4096_PEM class]]) {
            [QLFRendezvousAuthRSA4096_PEM marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"RendezvousAuthX509_PEM"]) {
            QLFRendezvousAuthSignature *_temp = [QLFRendezvousAuthX509_PEM unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"RendezvousAuthX509_PEM_SELFSIGNED"]) {
            QLFRendezvousAuthSignature *_temp = [QLFRendezvousAuthX509_PEM_SELFSIGNED unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"RendezvousAuthED25519"]) {
            QLFRendezvousAuthSignature *_temp = [QLFRendezvousAuthED25519 unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"RendezvousAuthRSA2048_PEM"]) {
            QLFRendezvousAuthSignature *_temp = [QLFRendezvousAuthRSA2048_PEM unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"RendezvousAuthRSA4096_PEM"]) {
            QLFRendezvousAuthSignature *_temp = [QLFRendezvousAuthRSA4096_PEM unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifRendezvousAuthX509_PEM:(void (^)(NSData *))ifRendezvousAuthX509_PEMBlock ifRendezvousAuthX509_PEM_SELFSIGNED:(void (^)(NSData *))ifRendezvousAuthX509_PEM_SELFSIGNEDBlock ifRendezvousAuthED25519:(void (^)(NSData *))ifRendezvousAuthED25519Block ifRendezvousAuthRSA2048_PEM:(void (^)(NSData *))ifRendezvousAuthRSA2048_PEMBlock ifRendezvousAuthRSA4096_PEM:(void (^)(NSData *))ifRendezvousAuthRSA4096_PEMBlock
{
    if ([self isKindOfClass:[QLFRendezvousAuthX509_PEM class]]) {
        ifRendezvousAuthX509_PEMBlock([((QLFRendezvousAuthX509_PEM *) self) signature]);
    } else if ([self isKindOfClass:[QLFRendezvousAuthX509_PEM_SELFSIGNED class]]) {
        ifRendezvousAuthX509_PEM_SELFSIGNEDBlock([((QLFRendezvousAuthX509_PEM_SELFSIGNED *) self) signature]);
    } else if ([self isKindOfClass:[QLFRendezvousAuthED25519 class]]) {
        ifRendezvousAuthED25519Block([((QLFRendezvousAuthED25519 *) self) signature]);
    } else if ([self isKindOfClass:[QLFRendezvousAuthRSA2048_PEM class]]) {
        ifRendezvousAuthRSA2048_PEMBlock([((QLFRendezvousAuthRSA2048_PEM *) self) signature]);
    } else if ([self isKindOfClass:[QLFRendezvousAuthRSA4096_PEM class]]) {
        ifRendezvousAuthRSA4096_PEMBlock([((QLFRendezvousAuthRSA4096_PEM *) self) signature]);
    }
}

- (NSComparisonResult)compare:(QLFRendezvousAuthSignature *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToRendezvousAuthSignature:(QLFRendezvousAuthSignature *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFRendezvousAuthX509_PEM



+ (QLFRendezvousAuthSignature *)rendezvousAuthX509_PEMWithSignature:(NSData *)signature
{

    return [[QLFRendezvousAuthX509_PEM alloc] initWithSignature:signature];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousAuthX509_PEM *e = (QLFRendezvousAuthX509_PEM *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousAuthX509_PEM"];
            [writer writeFieldStartWithFieldName:@"signature"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e signature], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'signature'
                NSData *signature = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        
        return [QLFRendezvousAuthSignature rendezvousAuthX509_PEMWithSignature:signature];
    };
}

- (instancetype)initWithSignature:(NSData *)signature
{

    self = [super init];
    if (self) {
        _signature = signature;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousAuthX509_PEM *)other
{
    if ([other isKindOfClass:[QLFRendezvousAuthSignature class]] && ![other isKindOfClass:[QLFRendezvousAuthX509_PEM class]]) {
        // N.B. impose an ordering among subtypes of RendezvousAuthSignature
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(signature);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousAuthX509_PEM:other];
       
}

- (BOOL)isEqualToRendezvousAuthX509_PEM:(QLFRendezvousAuthX509_PEM *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_signature != other.signature && ![_signature isEqual:other.signature])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_signature hash];
    return hash;
       
}

@end

@implementation QLFRendezvousAuthX509_PEM_SELFSIGNED



+ (QLFRendezvousAuthSignature *)rendezvousAuthX509_PEM_SELFSIGNEDWithSignature:(NSData *)signature
{

    return [[QLFRendezvousAuthX509_PEM_SELFSIGNED alloc] initWithSignature:signature];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousAuthX509_PEM_SELFSIGNED *e = (QLFRendezvousAuthX509_PEM_SELFSIGNED *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousAuthX509_PEM_SELFSIGNED"];
            [writer writeFieldStartWithFieldName:@"signature"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e signature], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'signature'
                NSData *signature = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        
        return [QLFRendezvousAuthSignature rendezvousAuthX509_PEM_SELFSIGNEDWithSignature:signature];
    };
}

- (instancetype)initWithSignature:(NSData *)signature
{

    self = [super init];
    if (self) {
        _signature = signature;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousAuthX509_PEM_SELFSIGNED *)other
{
    if ([other isKindOfClass:[QLFRendezvousAuthSignature class]] && ![other isKindOfClass:[QLFRendezvousAuthX509_PEM_SELFSIGNED class]]) {
        // N.B. impose an ordering among subtypes of RendezvousAuthSignature
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(signature);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousAuthX509_PEM_SELFSIGNED:other];
       
}

- (BOOL)isEqualToRendezvousAuthX509_PEM_SELFSIGNED:(QLFRendezvousAuthX509_PEM_SELFSIGNED *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_signature != other.signature && ![_signature isEqual:other.signature])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_signature hash];
    return hash;
       
}

@end

@implementation QLFRendezvousAuthED25519



+ (QLFRendezvousAuthSignature *)rendezvousAuthED25519WithSignature:(NSData *)signature
{

    return [[QLFRendezvousAuthED25519 alloc] initWithSignature:signature];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousAuthED25519 *e = (QLFRendezvousAuthED25519 *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousAuthED25519"];
            [writer writeFieldStartWithFieldName:@"signature"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e signature], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'signature'
                NSData *signature = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        
        return [QLFRendezvousAuthSignature rendezvousAuthED25519WithSignature:signature];
    };
}

- (instancetype)initWithSignature:(NSData *)signature
{

    self = [super init];
    if (self) {
        _signature = signature;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousAuthED25519 *)other
{
    if ([other isKindOfClass:[QLFRendezvousAuthSignature class]] && ![other isKindOfClass:[QLFRendezvousAuthED25519 class]]) {
        // N.B. impose an ordering among subtypes of RendezvousAuthSignature
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(signature);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousAuthED25519:other];
       
}

- (BOOL)isEqualToRendezvousAuthED25519:(QLFRendezvousAuthED25519 *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_signature != other.signature && ![_signature isEqual:other.signature])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_signature hash];
    return hash;
       
}

@end

@implementation QLFRendezvousAuthRSA2048_PEM



+ (QLFRendezvousAuthSignature *)rendezvousAuthRSA2048_PEMWithSignature:(NSData *)signature
{

    return [[QLFRendezvousAuthRSA2048_PEM alloc] initWithSignature:signature];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousAuthRSA2048_PEM *e = (QLFRendezvousAuthRSA2048_PEM *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousAuthRSA2048_PEM"];
            [writer writeFieldStartWithFieldName:@"signature"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e signature], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'signature'
                NSData *signature = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        
        return [QLFRendezvousAuthSignature rendezvousAuthRSA2048_PEMWithSignature:signature];
    };
}

- (instancetype)initWithSignature:(NSData *)signature
{

    self = [super init];
    if (self) {
        _signature = signature;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousAuthRSA2048_PEM *)other
{
    if ([other isKindOfClass:[QLFRendezvousAuthSignature class]] && ![other isKindOfClass:[QLFRendezvousAuthRSA2048_PEM class]]) {
        // N.B. impose an ordering among subtypes of RendezvousAuthSignature
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(signature);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousAuthRSA2048_PEM:other];
       
}

- (BOOL)isEqualToRendezvousAuthRSA2048_PEM:(QLFRendezvousAuthRSA2048_PEM *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_signature != other.signature && ![_signature isEqual:other.signature])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_signature hash];
    return hash;
       
}

@end

@implementation QLFRendezvousAuthRSA4096_PEM



+ (QLFRendezvousAuthSignature *)rendezvousAuthRSA4096_PEMWithSignature:(NSData *)signature
{

    return [[QLFRendezvousAuthRSA4096_PEM alloc] initWithSignature:signature];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousAuthRSA4096_PEM *e = (QLFRendezvousAuthRSA4096_PEM *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousAuthRSA4096_PEM"];
            [writer writeFieldStartWithFieldName:@"signature"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e signature], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'signature'
                NSData *signature = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        
        return [QLFRendezvousAuthSignature rendezvousAuthRSA4096_PEMWithSignature:signature];
    };
}

- (instancetype)initWithSignature:(NSData *)signature
{

    self = [super init];
    if (self) {
        _signature = signature;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousAuthRSA4096_PEM *)other
{
    if ([other isKindOfClass:[QLFRendezvousAuthSignature class]] && ![other isKindOfClass:[QLFRendezvousAuthRSA4096_PEM class]]) {
        // N.B. impose an ordering among subtypes of RendezvousAuthSignature
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(signature);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousAuthRSA4096_PEM:other];
       
}

- (BOOL)isEqualToRendezvousAuthRSA4096_PEM:(QLFRendezvousAuthRSA4096_PEM *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_signature != other.signature && ![_signature isEqual:other.signature])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_signature hash];
    return hash;
       
}

@end

@implementation QLFRendezvousAuthType



+ (QLFRendezvousAuthType *)rendezvousAnonymous
{

    return [[QLFRendezvousAnonymous alloc] init];
       
}

+ (QLFRendezvousAuthType *)rendezvousTrustedWithSignature:(QLFRendezvousAuthSignature *)signature
{

    return [[QLFRendezvousTrusted alloc] initWithSignature:signature];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFRendezvousAnonymous class]]) {
            [QLFRendezvousAnonymous marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFRendezvousTrusted class]]) {
            [QLFRendezvousTrusted marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"RendezvousAnonymous"]) {
            QLFRendezvousAuthType *_temp = [QLFRendezvousAnonymous unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"RendezvousTrusted"]) {
            QLFRendezvousAuthType *_temp = [QLFRendezvousTrusted unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifRendezvousAnonymous:(void (^)())ifRendezvousAnonymousBlock ifRendezvousTrusted:(void (^)(QLFRendezvousAuthSignature *))ifRendezvousTrustedBlock
{
    if ([self isKindOfClass:[QLFRendezvousAnonymous class]]) {
        ifRendezvousAnonymousBlock();
    } else if ([self isKindOfClass:[QLFRendezvousTrusted class]]) {
        ifRendezvousTrustedBlock([((QLFRendezvousTrusted *) self) signature]);
    }
}

- (NSComparisonResult)compare:(QLFRendezvousAuthType *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToRendezvousAuthType:(QLFRendezvousAuthType *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFRendezvousAnonymous



+ (QLFRendezvousAuthType *)rendezvousAnonymous
{

    return [[QLFRendezvousAnonymous alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousAnonymous *e = (QLFRendezvousAnonymous *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousAnonymous"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFRendezvousAuthType rendezvousAnonymous];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousAnonymous *)other
{
    if ([other isKindOfClass:[QLFRendezvousAuthType class]] && ![other isKindOfClass:[QLFRendezvousAnonymous class]]) {
        // N.B. impose an ordering among subtypes of RendezvousAuthType
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousAnonymous:other];
       
}

- (BOOL)isEqualToRendezvousAnonymous:(QLFRendezvousAnonymous *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFRendezvousTrusted



+ (QLFRendezvousAuthType *)rendezvousTrustedWithSignature:(QLFRendezvousAuthSignature *)signature
{

    return [[QLFRendezvousTrusted alloc] initWithSignature:signature];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousTrusted *e = (QLFRendezvousTrusted *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousTrusted"];
            [writer writeFieldStartWithFieldName:@"signature"];
                [QLFRendezvousAuthSignature marshaller]([e signature], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'signature'
                QLFRendezvousAuthSignature *signature = (QLFRendezvousAuthSignature *)[QLFRendezvousAuthSignature unmarshaller](reader);
            [reader readEnd];
        
        return [QLFRendezvousAuthType rendezvousTrustedWithSignature:signature];
    };
}

- (instancetype)initWithSignature:(QLFRendezvousAuthSignature *)signature
{

    self = [super init];
    if (self) {
        _signature = signature;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousTrusted *)other
{
    if ([other isKindOfClass:[QLFRendezvousAuthType class]] && ![other isKindOfClass:[QLFRendezvousTrusted class]]) {
        // N.B. impose an ordering among subtypes of RendezvousAuthType
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(signature);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousTrusted:other];
       
}

- (BOOL)isEqualToRendezvousTrusted:(QLFRendezvousTrusted *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_signature != other.signature && ![_signature isEqual:other.signature])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_signature hash];
    return hash;
       
}

@end

@implementation QLFEncryptedResponderInfo



+ (QLFEncryptedResponderInfo *)encryptedResponderInfoWithValue:(NSData *)value authenticationCode:(QLFAuthenticationCode *)authenticationCode authenticationType:(QLFRendezvousAuthType *)authenticationType
{

    return [[QLFEncryptedResponderInfo alloc] initWithValue:value authenticationCode:authenticationCode authenticationType:authenticationType];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFEncryptedResponderInfo *e = (QLFEncryptedResponderInfo *)element;
        [writer writeConstructorStartWithObjectName:@"EncryptedResponderInfo"];
            [writer writeFieldStartWithFieldName:@"authenticationCode"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e authenticationCode], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"authenticationType"];
                [QLFRendezvousAuthType marshaller]([e authenticationType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"value"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e value], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'EncryptedResponderInfo'
            [reader readFieldStart]; // TODO assert that field name is 'authenticationCode'
                QLFAuthenticationCode *authenticationCode = (QLFAuthenticationCode *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'authenticationType'
                QLFRendezvousAuthType *authenticationType = (QLFRendezvousAuthType *)[QLFRendezvousAuthType unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'value'
                NSData *value = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFEncryptedResponderInfo encryptedResponderInfoWithValue:value authenticationCode:authenticationCode authenticationType:authenticationType];
    };
}

- (instancetype)initWithValue:(NSData *)value authenticationCode:(QLFAuthenticationCode *)authenticationCode authenticationType:(QLFRendezvousAuthType *)authenticationType
{

    self = [super init];
    if (self) {
        _value = value;
        _authenticationCode = authenticationCode;
        _authenticationType = authenticationType;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFEncryptedResponderInfo *)other
{

    QREDO_COMPARE_OBJECT(value);
    QREDO_COMPARE_OBJECT(authenticationCode);
    QREDO_COMPARE_OBJECT(authenticationType);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToEncryptedResponderInfo:other];
       
}

- (BOOL)isEqualToEncryptedResponderInfo:(QLFEncryptedResponderInfo *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_value != other.value && ![_value isEqual:other.value])
        return NO;
    if (_authenticationCode != other.authenticationCode && ![_authenticationCode isEqual:other.authenticationCode])
        return NO;
    if (_authenticationType != other.authenticationType && ![_authenticationType isEqual:other.authenticationType])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_value hash];
    hash = hash * 31u + [_authenticationCode hash];
    hash = hash * 31u + [_authenticationType hash];
    return hash;
       
}

@end

@implementation QLFRendezvousDeactivated



+ (QLFRendezvousDeactivated *)rendezvousDeactivated
{

    return [[QLFRendezvousDeactivated alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousDeactivated *e = (QLFRendezvousDeactivated *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousDeactivated"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'RendezvousDeactivated'

        [reader readEnd];
        return [QLFRendezvousDeactivated rendezvousDeactivated];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousDeactivated *)other
{

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousDeactivated:other];
       
}

- (BOOL)isEqualToRendezvousDeactivated:(QLFRendezvousDeactivated *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFRendezvousResponseCountLimit



+ (QLFRendezvousResponseCountLimit *)rendezvousSingleResponse
{

    return [[QLFRendezvousSingleResponse alloc] init];
       
}

+ (QLFRendezvousResponseCountLimit *)rendezvousUnlimitedResponses
{

    return [[QLFRendezvousUnlimitedResponses alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFRendezvousSingleResponse class]]) {
            [QLFRendezvousSingleResponse marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFRendezvousUnlimitedResponses class]]) {
            [QLFRendezvousUnlimitedResponses marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"RendezvousSingleResponse"]) {
            QLFRendezvousResponseCountLimit *_temp = [QLFRendezvousSingleResponse unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"RendezvousUnlimitedResponses"]) {
            QLFRendezvousResponseCountLimit *_temp = [QLFRendezvousUnlimitedResponses unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifRendezvousSingleResponse:(void (^)())ifRendezvousSingleResponseBlock ifRendezvousUnlimitedResponses:(void (^)())ifRendezvousUnlimitedResponsesBlock
{
    if ([self isKindOfClass:[QLFRendezvousSingleResponse class]]) {
        ifRendezvousSingleResponseBlock();
    } else if ([self isKindOfClass:[QLFRendezvousUnlimitedResponses class]]) {
        ifRendezvousUnlimitedResponsesBlock();
    }
}

- (NSComparisonResult)compare:(QLFRendezvousResponseCountLimit *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToRendezvousResponseCountLimit:(QLFRendezvousResponseCountLimit *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFRendezvousSingleResponse



+ (QLFRendezvousResponseCountLimit *)rendezvousSingleResponse
{

    return [[QLFRendezvousSingleResponse alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousSingleResponse *e = (QLFRendezvousSingleResponse *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousSingleResponse"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFRendezvousResponseCountLimit rendezvousSingleResponse];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousSingleResponse *)other
{
    if ([other isKindOfClass:[QLFRendezvousResponseCountLimit class]] && ![other isKindOfClass:[QLFRendezvousSingleResponse class]]) {
        // N.B. impose an ordering among subtypes of RendezvousResponseCountLimit
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousSingleResponse:other];
       
}

- (BOOL)isEqualToRendezvousSingleResponse:(QLFRendezvousSingleResponse *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFRendezvousUnlimitedResponses



+ (QLFRendezvousResponseCountLimit *)rendezvousUnlimitedResponses
{

    return [[QLFRendezvousUnlimitedResponses alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousUnlimitedResponses *e = (QLFRendezvousUnlimitedResponses *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousUnlimitedResponses"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFRendezvousResponseCountLimit rendezvousUnlimitedResponses];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousUnlimitedResponses *)other
{
    if ([other isKindOfClass:[QLFRendezvousResponseCountLimit class]] && ![other isKindOfClass:[QLFRendezvousUnlimitedResponses class]]) {
        // N.B. impose an ordering among subtypes of RendezvousResponseCountLimit
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousUnlimitedResponses:other];
       
}

- (BOOL)isEqualToRendezvousUnlimitedResponses:(QLFRendezvousUnlimitedResponses *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFRendezvousCreationInfo



+ (QLFRendezvousCreationInfo *)rendezvousCreationInfoWithHashedTag:(QLFRendezvousHashedTag *)hashedTag durationSeconds:(QLFRendezvousDurationSeconds *)durationSeconds responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit ownershipPublicKey:(QLFRendezvousOwnershipPublicKey *)ownershipPublicKey encryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo
{

    return [[QLFRendezvousCreationInfo alloc] initWithHashedTag:hashedTag durationSeconds:durationSeconds responseCountLimit:responseCountLimit ownershipPublicKey:ownershipPublicKey encryptedResponderInfo:encryptedResponderInfo];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousCreationInfo *e = (QLFRendezvousCreationInfo *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousCreationInfo"];
            [writer writeFieldStartWithFieldName:@"durationSeconds"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int32Marshaller]]([e durationSeconds], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptedResponderInfo"];
                [QLFEncryptedResponderInfo marshaller]([e encryptedResponderInfo], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"hashedTag"];
                [QredoPrimitiveMarshallers quidMarshaller]([e hashedTag], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"ownershipPublicKey"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e ownershipPublicKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"responseCountLimit"];
                [QLFRendezvousResponseCountLimit marshaller]([e responseCountLimit], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'RendezvousCreationInfo'
            [reader readFieldStart]; // TODO assert that field name is 'durationSeconds'
                QLFRendezvousDurationSeconds *durationSeconds = (QLFRendezvousDurationSeconds *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers int32Unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptedResponderInfo'
                QLFEncryptedResponderInfo *encryptedResponderInfo = (QLFEncryptedResponderInfo *)[QLFEncryptedResponderInfo unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'hashedTag'
                QLFRendezvousHashedTag *hashedTag = (QLFRendezvousHashedTag *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'ownershipPublicKey'
                QLFRendezvousOwnershipPublicKey *ownershipPublicKey = (QLFRendezvousOwnershipPublicKey *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'responseCountLimit'
                QLFRendezvousResponseCountLimit *responseCountLimit = (QLFRendezvousResponseCountLimit *)[QLFRendezvousResponseCountLimit unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFRendezvousCreationInfo rendezvousCreationInfoWithHashedTag:hashedTag durationSeconds:durationSeconds responseCountLimit:responseCountLimit ownershipPublicKey:ownershipPublicKey encryptedResponderInfo:encryptedResponderInfo];
    };
}

- (instancetype)initWithHashedTag:(QLFRendezvousHashedTag *)hashedTag durationSeconds:(QLFRendezvousDurationSeconds *)durationSeconds responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit ownershipPublicKey:(QLFRendezvousOwnershipPublicKey *)ownershipPublicKey encryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo
{

    self = [super init];
    if (self) {
        _hashedTag = hashedTag;
        _durationSeconds = durationSeconds;
        _responseCountLimit = responseCountLimit;
        _ownershipPublicKey = ownershipPublicKey;
        _encryptedResponderInfo = encryptedResponderInfo;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousCreationInfo *)other
{

    QREDO_COMPARE_OBJECT(hashedTag);
    QREDO_COMPARE_OBJECT(durationSeconds);
    QREDO_COMPARE_OBJECT(responseCountLimit);
    QREDO_COMPARE_OBJECT(ownershipPublicKey);
    QREDO_COMPARE_OBJECT(encryptedResponderInfo);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousCreationInfo:other];
       
}

- (BOOL)isEqualToRendezvousCreationInfo:(QLFRendezvousCreationInfo *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_hashedTag != other.hashedTag && ![_hashedTag isEqual:other.hashedTag])
        return NO;
    if (_durationSeconds != other.durationSeconds && ![_durationSeconds isEqual:other.durationSeconds])
        return NO;
    if (_responseCountLimit != other.responseCountLimit && ![_responseCountLimit isEqual:other.responseCountLimit])
        return NO;
    if (_ownershipPublicKey != other.ownershipPublicKey && ![_ownershipPublicKey isEqual:other.ownershipPublicKey])
        return NO;
    if (_encryptedResponderInfo != other.encryptedResponderInfo && ![_encryptedResponderInfo isEqual:other.encryptedResponderInfo])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_hashedTag hash];
    hash = hash * 31u + [_durationSeconds hash];
    hash = hash * 31u + [_responseCountLimit hash];
    hash = hash * 31u + [_ownershipPublicKey hash];
    hash = hash * 31u + [_encryptedResponderInfo hash];
    return hash;
       
}

@end

@implementation QLFRendezvousResponseRejectionReason



+ (QLFRendezvousResponseRejectionReason *)rendezvousResponseMaxResponseCountReached
{

    return [[QLFRendezvousResponseMaxResponseCountReached alloc] init];
       
}

+ (QLFRendezvousResponseRejectionReason *)rendezvousResponseDurationElapsed
{

    return [[QLFRendezvousResponseDurationElapsed alloc] init];
       
}

+ (QLFRendezvousResponseRejectionReason *)rendezvousResponseInvalid
{

    return [[QLFRendezvousResponseInvalid alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFRendezvousResponseMaxResponseCountReached class]]) {
            [QLFRendezvousResponseMaxResponseCountReached marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFRendezvousResponseDurationElapsed class]]) {
            [QLFRendezvousResponseDurationElapsed marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFRendezvousResponseInvalid class]]) {
            [QLFRendezvousResponseInvalid marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"RendezvousResponseMaxResponseCountReached"]) {
            QLFRendezvousResponseRejectionReason *_temp = [QLFRendezvousResponseMaxResponseCountReached unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"RendezvousResponseDurationElapsed"]) {
            QLFRendezvousResponseRejectionReason *_temp = [QLFRendezvousResponseDurationElapsed unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"RendezvousResponseInvalid"]) {
            QLFRendezvousResponseRejectionReason *_temp = [QLFRendezvousResponseInvalid unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifRendezvousResponseMaxResponseCountReached:(void (^)())ifRendezvousResponseMaxResponseCountReachedBlock ifRendezvousResponseDurationElapsed:(void (^)())ifRendezvousResponseDurationElapsedBlock ifRendezvousResponseInvalid:(void (^)())ifRendezvousResponseInvalidBlock
{
    if ([self isKindOfClass:[QLFRendezvousResponseMaxResponseCountReached class]]) {
        ifRendezvousResponseMaxResponseCountReachedBlock();
    } else if ([self isKindOfClass:[QLFRendezvousResponseDurationElapsed class]]) {
        ifRendezvousResponseDurationElapsedBlock();
    } else if ([self isKindOfClass:[QLFRendezvousResponseInvalid class]]) {
        ifRendezvousResponseInvalidBlock();
    }
}

- (NSComparisonResult)compare:(QLFRendezvousResponseRejectionReason *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToRendezvousResponseRejectionReason:(QLFRendezvousResponseRejectionReason *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFRendezvousResponseMaxResponseCountReached



+ (QLFRendezvousResponseRejectionReason *)rendezvousResponseMaxResponseCountReached
{

    return [[QLFRendezvousResponseMaxResponseCountReached alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousResponseMaxResponseCountReached *e = (QLFRendezvousResponseMaxResponseCountReached *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousResponseMaxResponseCountReached"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFRendezvousResponseRejectionReason rendezvousResponseMaxResponseCountReached];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousResponseMaxResponseCountReached *)other
{
    if ([other isKindOfClass:[QLFRendezvousResponseRejectionReason class]] && ![other isKindOfClass:[QLFRendezvousResponseMaxResponseCountReached class]]) {
        // N.B. impose an ordering among subtypes of RendezvousResponseRejectionReason
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousResponseMaxResponseCountReached:other];
       
}

- (BOOL)isEqualToRendezvousResponseMaxResponseCountReached:(QLFRendezvousResponseMaxResponseCountReached *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFRendezvousResponseDurationElapsed



+ (QLFRendezvousResponseRejectionReason *)rendezvousResponseDurationElapsed
{

    return [[QLFRendezvousResponseDurationElapsed alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousResponseDurationElapsed *e = (QLFRendezvousResponseDurationElapsed *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousResponseDurationElapsed"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFRendezvousResponseRejectionReason rendezvousResponseDurationElapsed];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousResponseDurationElapsed *)other
{
    if ([other isKindOfClass:[QLFRendezvousResponseRejectionReason class]] && ![other isKindOfClass:[QLFRendezvousResponseDurationElapsed class]]) {
        // N.B. impose an ordering among subtypes of RendezvousResponseRejectionReason
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousResponseDurationElapsed:other];
       
}

- (BOOL)isEqualToRendezvousResponseDurationElapsed:(QLFRendezvousResponseDurationElapsed *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFRendezvousResponseInvalid



+ (QLFRendezvousResponseRejectionReason *)rendezvousResponseInvalid
{

    return [[QLFRendezvousResponseInvalid alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousResponseInvalid *e = (QLFRendezvousResponseInvalid *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousResponseInvalid"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFRendezvousResponseRejectionReason rendezvousResponseInvalid];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousResponseInvalid *)other
{
    if ([other isKindOfClass:[QLFRendezvousResponseRejectionReason class]] && ![other isKindOfClass:[QLFRendezvousResponseInvalid class]]) {
        // N.B. impose an ordering among subtypes of RendezvousResponseRejectionReason
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousResponseInvalid:other];
       
}

- (BOOL)isEqualToRendezvousResponseInvalid:(QLFRendezvousResponseInvalid *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFRendezvousRespondResult



+ (QLFRendezvousRespondResult *)rendezvousResponseRegisteredWithInfo:(QLFEncryptedResponderInfo *)info
{

    return [[QLFRendezvousResponseRegistered alloc] initWithInfo:info];
       
}

+ (QLFRendezvousRespondResult *)rendezvousResponseUnknownTag
{

    return [[QLFRendezvousResponseUnknownTag alloc] init];
       
}

+ (QLFRendezvousRespondResult *)rendezvousResponseRejectedWithReason:(QLFRendezvousResponseRejectionReason *)reason
{

    return [[QLFRendezvousResponseRejected alloc] initWithReason:reason];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFRendezvousResponseRegistered class]]) {
            [QLFRendezvousResponseRegistered marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFRendezvousResponseUnknownTag class]]) {
            [QLFRendezvousResponseUnknownTag marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFRendezvousResponseRejected class]]) {
            [QLFRendezvousResponseRejected marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"RendezvousResponseRegistered"]) {
            QLFRendezvousRespondResult *_temp = [QLFRendezvousResponseRegistered unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"RendezvousResponseUnknownTag"]) {
            QLFRendezvousRespondResult *_temp = [QLFRendezvousResponseUnknownTag unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"RendezvousResponseRejected"]) {
            QLFRendezvousRespondResult *_temp = [QLFRendezvousResponseRejected unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifRendezvousResponseRegistered:(void (^)(QLFEncryptedResponderInfo *))ifRendezvousResponseRegisteredBlock ifRendezvousResponseUnknownTag:(void (^)())ifRendezvousResponseUnknownTagBlock ifRendezvousResponseRejected:(void (^)(QLFRendezvousResponseRejectionReason *))ifRendezvousResponseRejectedBlock
{
    if ([self isKindOfClass:[QLFRendezvousResponseRegistered class]]) {
        ifRendezvousResponseRegisteredBlock([((QLFRendezvousResponseRegistered *) self) info]);
    } else if ([self isKindOfClass:[QLFRendezvousResponseUnknownTag class]]) {
        ifRendezvousResponseUnknownTagBlock();
    } else if ([self isKindOfClass:[QLFRendezvousResponseRejected class]]) {
        ifRendezvousResponseRejectedBlock([((QLFRendezvousResponseRejected *) self) reason]);
    }
}

- (NSComparisonResult)compare:(QLFRendezvousRespondResult *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToRendezvousRespondResult:(QLFRendezvousRespondResult *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFRendezvousResponseRegistered



+ (QLFRendezvousRespondResult *)rendezvousResponseRegisteredWithInfo:(QLFEncryptedResponderInfo *)info
{

    return [[QLFRendezvousResponseRegistered alloc] initWithInfo:info];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousResponseRegistered *e = (QLFRendezvousResponseRegistered *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousResponseRegistered"];
            [writer writeFieldStartWithFieldName:@"info"];
                [QLFEncryptedResponderInfo marshaller]([e info], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'info'
                QLFEncryptedResponderInfo *info = (QLFEncryptedResponderInfo *)[QLFEncryptedResponderInfo unmarshaller](reader);
            [reader readEnd];
        
        return [QLFRendezvousRespondResult rendezvousResponseRegisteredWithInfo:info];
    };
}

- (instancetype)initWithInfo:(QLFEncryptedResponderInfo *)info
{

    self = [super init];
    if (self) {
        _info = info;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousResponseRegistered *)other
{
    if ([other isKindOfClass:[QLFRendezvousRespondResult class]] && ![other isKindOfClass:[QLFRendezvousResponseRegistered class]]) {
        // N.B. impose an ordering among subtypes of RendezvousRespondResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(info);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousResponseRegistered:other];
       
}

- (BOOL)isEqualToRendezvousResponseRegistered:(QLFRendezvousResponseRegistered *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_info != other.info && ![_info isEqual:other.info])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_info hash];
    return hash;
       
}

@end

@implementation QLFRendezvousResponseUnknownTag



+ (QLFRendezvousRespondResult *)rendezvousResponseUnknownTag
{

    return [[QLFRendezvousResponseUnknownTag alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousResponseUnknownTag *e = (QLFRendezvousResponseUnknownTag *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousResponseUnknownTag"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFRendezvousRespondResult rendezvousResponseUnknownTag];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousResponseUnknownTag *)other
{
    if ([other isKindOfClass:[QLFRendezvousRespondResult class]] && ![other isKindOfClass:[QLFRendezvousResponseUnknownTag class]]) {
        // N.B. impose an ordering among subtypes of RendezvousRespondResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousResponseUnknownTag:other];
       
}

- (BOOL)isEqualToRendezvousResponseUnknownTag:(QLFRendezvousResponseUnknownTag *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFRendezvousResponseRejected



+ (QLFRendezvousRespondResult *)rendezvousResponseRejectedWithReason:(QLFRendezvousResponseRejectionReason *)reason
{

    return [[QLFRendezvousResponseRejected alloc] initWithReason:reason];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousResponseRejected *e = (QLFRendezvousResponseRejected *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousResponseRejected"];
            [writer writeFieldStartWithFieldName:@"reason"];
                [QLFRendezvousResponseRejectionReason marshaller]([e reason], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'reason'
                QLFRendezvousResponseRejectionReason *reason = (QLFRendezvousResponseRejectionReason *)[QLFRendezvousResponseRejectionReason unmarshaller](reader);
            [reader readEnd];
        
        return [QLFRendezvousRespondResult rendezvousResponseRejectedWithReason:reason];
    };
}

- (instancetype)initWithReason:(QLFRendezvousResponseRejectionReason *)reason
{

    self = [super init];
    if (self) {
        _reason = reason;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousResponseRejected *)other
{
    if ([other isKindOfClass:[QLFRendezvousRespondResult class]] && ![other isKindOfClass:[QLFRendezvousResponseRejected class]]) {
        // N.B. impose an ordering among subtypes of RendezvousRespondResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(reason);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousResponseRejected:other];
       
}

- (BOOL)isEqualToRendezvousResponseRejected:(QLFRendezvousResponseRejected *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_reason != other.reason && ![_reason isEqual:other.reason])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_reason hash];
    return hash;
       
}

@end

@implementation QLFRendezvousResponse



+ (QLFRendezvousResponse *)rendezvousResponseWithHashedTag:(QLFRendezvousHashedTag *)hashedTag responderPublicKey:(QLFResponderPublicKey *)responderPublicKey responderAuthenticationCode:(QLFAuthenticationCode *)responderAuthenticationCode
{

    return [[QLFRendezvousResponse alloc] initWithHashedTag:hashedTag responderPublicKey:responderPublicKey responderAuthenticationCode:responderAuthenticationCode];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousResponse *e = (QLFRendezvousResponse *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousResponse"];
            [writer writeFieldStartWithFieldName:@"hashedTag"];
                [QredoPrimitiveMarshallers quidMarshaller]([e hashedTag], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"responderAuthenticationCode"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e responderAuthenticationCode], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"responderPublicKey"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e responderPublicKey], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'RendezvousResponse'
            [reader readFieldStart]; // TODO assert that field name is 'hashedTag'
                QLFRendezvousHashedTag *hashedTag = (QLFRendezvousHashedTag *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'responderAuthenticationCode'
                QLFAuthenticationCode *responderAuthenticationCode = (QLFAuthenticationCode *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'responderPublicKey'
                QLFResponderPublicKey *responderPublicKey = (QLFResponderPublicKey *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFRendezvousResponse rendezvousResponseWithHashedTag:hashedTag responderPublicKey:responderPublicKey responderAuthenticationCode:responderAuthenticationCode];
    };
}

- (instancetype)initWithHashedTag:(QLFRendezvousHashedTag *)hashedTag responderPublicKey:(QLFResponderPublicKey *)responderPublicKey responderAuthenticationCode:(QLFAuthenticationCode *)responderAuthenticationCode
{

    self = [super init];
    if (self) {
        _hashedTag = hashedTag;
        _responderPublicKey = responderPublicKey;
        _responderAuthenticationCode = responderAuthenticationCode;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousResponse *)other
{

    QREDO_COMPARE_OBJECT(hashedTag);
    QREDO_COMPARE_OBJECT(responderPublicKey);
    QREDO_COMPARE_OBJECT(responderAuthenticationCode);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousResponse:other];
       
}

- (BOOL)isEqualToRendezvousResponse:(QLFRendezvousResponse *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_hashedTag != other.hashedTag && ![_hashedTag isEqual:other.hashedTag])
        return NO;
    if (_responderPublicKey != other.responderPublicKey && ![_responderPublicKey isEqual:other.responderPublicKey])
        return NO;
    if (_responderAuthenticationCode != other.responderAuthenticationCode && ![_responderAuthenticationCode isEqual:other.responderAuthenticationCode])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_hashedTag hash];
    hash = hash * 31u + [_responderPublicKey hash];
    hash = hash * 31u + [_responderAuthenticationCode hash];
    return hash;
       
}

@end

@implementation QLFRendezvousResponseWithSequenceValue



+ (QLFRendezvousResponseWithSequenceValue *)rendezvousResponseWithSequenceValueWithResponse:(QLFRendezvousResponse *)response sequenceValue:(QLFRendezvousSequenceValue)sequenceValue
{

    return [[QLFRendezvousResponseWithSequenceValue alloc] initWithResponse:response sequenceValue:sequenceValue];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousResponseWithSequenceValue *e = (QLFRendezvousResponseWithSequenceValue *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousResponseWithSequenceValue"];
            [writer writeFieldStartWithFieldName:@"response"];
                [QLFRendezvousResponse marshaller]([e response], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"sequenceValue"];
                [QredoPrimitiveMarshallers int64Marshaller]([NSNumber numberWithLongLong: [e sequenceValue]], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'RendezvousResponseWithSequenceValue'
            [reader readFieldStart]; // TODO assert that field name is 'response'
                QLFRendezvousResponse *response = (QLFRendezvousResponse *)[QLFRendezvousResponse unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sequenceValue'
                QLFRendezvousSequenceValue sequenceValue = (QLFRendezvousSequenceValue )[[QredoPrimitiveMarshallers int64Unmarshaller](reader) longLongValue];
            [reader readEnd];
        [reader readEnd];
        return [QLFRendezvousResponseWithSequenceValue rendezvousResponseWithSequenceValueWithResponse:response sequenceValue:sequenceValue];
    };
}

- (instancetype)initWithResponse:(QLFRendezvousResponse *)response sequenceValue:(QLFRendezvousSequenceValue)sequenceValue
{

    self = [super init];
    if (self) {
        _response = response;
        _sequenceValue = sequenceValue;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousResponseWithSequenceValue *)other
{

    QREDO_COMPARE_OBJECT(response);
    QREDO_COMPARE_SCALAR(sequenceValue);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousResponseWithSequenceValue:other];
       
}

- (BOOL)isEqualToRendezvousResponseWithSequenceValue:(QLFRendezvousResponseWithSequenceValue *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_response != other.response && ![_response isEqual:other.response])
        return NO;
    if (_sequenceValue != other.sequenceValue)
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_response hash];
    hash = hash * 31u + (NSUInteger)_sequenceValue;
    return hash;
       
}

@end

@implementation QLFRendezvousResponsesResult



+ (QLFRendezvousResponsesResult *)rendezvousResponsesResultWithResponses:(NSArray *)responses sequenceValue:(QLFRendezvousSequenceValue)sequenceValue
{

    return [[QLFRendezvousResponsesResult alloc] initWithResponses:responses sequenceValue:sequenceValue];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousResponsesResult *e = (QLFRendezvousResponsesResult *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousResponsesResult"];
            [writer writeFieldStartWithFieldName:@"responses"];
                [QredoPrimitiveMarshallers sequenceMarshallerWithElementMarshaller:[QLFRendezvousResponse marshaller]]([e responses], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"sequenceValue"];
                [QredoPrimitiveMarshallers int64Marshaller]([NSNumber numberWithLongLong: [e sequenceValue]], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'RendezvousResponsesResult'
            [reader readFieldStart]; // TODO assert that field name is 'responses'
                NSArray *responses = (NSArray *)[QredoPrimitiveMarshallers sequenceUnmarshallerWithElementUnmarshaller:[QLFRendezvousResponse unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sequenceValue'
                QLFRendezvousSequenceValue sequenceValue = (QLFRendezvousSequenceValue )[[QredoPrimitiveMarshallers int64Unmarshaller](reader) longLongValue];
            [reader readEnd];
        [reader readEnd];
        return [QLFRendezvousResponsesResult rendezvousResponsesResultWithResponses:responses sequenceValue:sequenceValue];
    };
}

- (instancetype)initWithResponses:(NSArray *)responses sequenceValue:(QLFRendezvousSequenceValue)sequenceValue
{

    self = [super init];
    if (self) {
        _responses = responses;
        _sequenceValue = sequenceValue;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousResponsesResult *)other
{

    QREDO_COMPARE_OBJECT(responses);
    QREDO_COMPARE_SCALAR(sequenceValue);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousResponsesResult:other];
       
}

- (BOOL)isEqualToRendezvousResponsesResult:(QLFRendezvousResponsesResult *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_responses != other.responses && ![_responses isEqual:other.responses])
        return NO;
    if (_sequenceValue != other.sequenceValue)
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_responses hash];
    hash = hash * 31u + (NSUInteger)_sequenceValue;
    return hash;
       
}

@end

@implementation QLFServiceAccess



+ (QLFServiceAccess *)serviceAccessWithToken:(QLFAnonymousToken1024 *)token signature:(QLFAnonymousToken1024 *)signature keyId:(int32_t)keyId
{

    return [[QLFServiceAccess alloc] initWithToken:token signature:signature keyId:keyId];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFServiceAccess *e = (QLFServiceAccess *)element;
        [writer writeConstructorStartWithObjectName:@"ServiceAccess"];
            [writer writeFieldStartWithFieldName:@"keyId"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e keyId]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"signature"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e signature], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"token"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e token], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'ServiceAccess'
            [reader readFieldStart]; // TODO assert that field name is 'keyId'
                int32_t keyId = (int32_t )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'signature'
                QLFAnonymousToken1024 *signature = (QLFAnonymousToken1024 *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'token'
                QLFAnonymousToken1024 *token = (QLFAnonymousToken1024 *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFServiceAccess serviceAccessWithToken:token signature:signature keyId:keyId];
    };
}

- (instancetype)initWithToken:(QLFAnonymousToken1024 *)token signature:(QLFAnonymousToken1024 *)signature keyId:(int32_t)keyId
{

    self = [super init];
    if (self) {
        _token = token;
        _signature = signature;
        _keyId = keyId;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFServiceAccess *)other
{

    QREDO_COMPARE_OBJECT(token);
    QREDO_COMPARE_OBJECT(signature);
    QREDO_COMPARE_SCALAR(keyId);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToServiceAccess:other];
       
}

- (BOOL)isEqualToServiceAccess:(QLFServiceAccess *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_token != other.token && ![_token isEqual:other.token])
        return NO;
    if (_signature != other.signature && ![_signature isEqual:other.signature])
        return NO;
    if (_keyId != other.keyId)
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_token hash];
    hash = hash * 31u + [_signature hash];
    hash = hash * 31u + (NSUInteger)_keyId;
    return hash;
       
}

@end

@implementation QLFConversationDescriptor



+ (QLFConversationDescriptor *)conversationDescriptorWithRendezvousTag:(NSString *)rendezvousTag rendezvousOwner:(BOOL)rendezvousOwner conversationId:(QLFConversationId *)conversationId conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType myKey:(QLFKeyPairLF *)myKey yourPublicKey:(QLFKeyLF *)yourPublicKey myPublicKeyVerified:(BOOL)myPublicKeyVerified yourPublicKeyVerified:(BOOL)yourPublicKeyVerified
{

    return [[QLFConversationDescriptor alloc] initWithRendezvousTag:rendezvousTag rendezvousOwner:rendezvousOwner conversationId:conversationId conversationType:conversationType authenticationType:authenticationType myKey:myKey yourPublicKey:yourPublicKey myPublicKeyVerified:myPublicKeyVerified yourPublicKeyVerified:yourPublicKeyVerified];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFConversationDescriptor *e = (QLFConversationDescriptor *)element;
        [writer writeConstructorStartWithObjectName:@"ConversationDescriptor"];
            [writer writeFieldStartWithFieldName:@"authenticationType"];
                [QLFRendezvousAuthType marshaller]([e authenticationType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"conversationId"];
                [QredoPrimitiveMarshallers quidMarshaller]([e conversationId], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"conversationType"];
                [QredoPrimitiveMarshallers stringMarshaller]([e conversationType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"myKey"];
                [QLFKeyPairLF marshaller]([e myKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"myPublicKeyVerified"];
                [QredoPrimitiveMarshallers booleanMarshaller]([NSNumber numberWithBool: [e myPublicKeyVerified]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"rendezvousOwner"];
                [QredoPrimitiveMarshallers booleanMarshaller]([NSNumber numberWithBool: [e rendezvousOwner]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"rendezvousTag"];
                [QredoPrimitiveMarshallers stringMarshaller]([e rendezvousTag], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"yourPublicKey"];
                [QLFKeyLF marshaller]([e yourPublicKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"yourPublicKeyVerified"];
                [QredoPrimitiveMarshallers booleanMarshaller]([NSNumber numberWithBool: [e yourPublicKeyVerified]], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'ConversationDescriptor'
            [reader readFieldStart]; // TODO assert that field name is 'authenticationType'
                QLFRendezvousAuthType *authenticationType = (QLFRendezvousAuthType *)[QLFRendezvousAuthType unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'conversationId'
                QLFConversationId *conversationId = (QLFConversationId *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'conversationType'
                NSString *conversationType = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'myKey'
                QLFKeyPairLF *myKey = (QLFKeyPairLF *)[QLFKeyPairLF unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'myPublicKeyVerified'
                BOOL myPublicKeyVerified = (BOOL )[[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'rendezvousOwner'
                BOOL rendezvousOwner = (BOOL )[[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'rendezvousTag'
                NSString *rendezvousTag = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'yourPublicKey'
                QLFKeyLF *yourPublicKey = (QLFKeyLF *)[QLFKeyLF unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'yourPublicKeyVerified'
                BOOL yourPublicKeyVerified = (BOOL )[[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
            [reader readEnd];
        [reader readEnd];
        return [QLFConversationDescriptor conversationDescriptorWithRendezvousTag:rendezvousTag rendezvousOwner:rendezvousOwner conversationId:conversationId conversationType:conversationType authenticationType:authenticationType myKey:myKey yourPublicKey:yourPublicKey myPublicKeyVerified:myPublicKeyVerified yourPublicKeyVerified:yourPublicKeyVerified];
    };
}

- (instancetype)initWithRendezvousTag:(NSString *)rendezvousTag rendezvousOwner:(BOOL)rendezvousOwner conversationId:(QLFConversationId *)conversationId conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType myKey:(QLFKeyPairLF *)myKey yourPublicKey:(QLFKeyLF *)yourPublicKey myPublicKeyVerified:(BOOL)myPublicKeyVerified yourPublicKeyVerified:(BOOL)yourPublicKeyVerified
{

    self = [super init];
    if (self) {
        _rendezvousTag = rendezvousTag;
        _rendezvousOwner = rendezvousOwner;
        _conversationId = conversationId;
        _conversationType = conversationType;
        _authenticationType = authenticationType;
        _myKey = myKey;
        _yourPublicKey = yourPublicKey;
        _myPublicKeyVerified = myPublicKeyVerified;
        _yourPublicKeyVerified = yourPublicKeyVerified;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFConversationDescriptor *)other
{

    QREDO_COMPARE_OBJECT(rendezvousTag);
    QREDO_COMPARE_SCALAR(rendezvousOwner);
    QREDO_COMPARE_OBJECT(conversationId);
    QREDO_COMPARE_OBJECT(conversationType);
    QREDO_COMPARE_OBJECT(authenticationType);
    QREDO_COMPARE_OBJECT(myKey);
    QREDO_COMPARE_OBJECT(yourPublicKey);
    QREDO_COMPARE_SCALAR(myPublicKeyVerified);
    QREDO_COMPARE_SCALAR(yourPublicKeyVerified);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToConversationDescriptor:other];
       
}

- (BOOL)isEqualToConversationDescriptor:(QLFConversationDescriptor *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_rendezvousTag != other.rendezvousTag && ![_rendezvousTag isEqual:other.rendezvousTag])
        return NO;
    if (_rendezvousOwner != other.rendezvousOwner)
        return NO;
    if (_conversationId != other.conversationId && ![_conversationId isEqual:other.conversationId])
        return NO;
    if (_conversationType != other.conversationType && ![_conversationType isEqual:other.conversationType])
        return NO;
    if (_authenticationType != other.authenticationType && ![_authenticationType isEqual:other.authenticationType])
        return NO;
    if (_myKey != other.myKey && ![_myKey isEqual:other.myKey])
        return NO;
    if (_yourPublicKey != other.yourPublicKey && ![_yourPublicKey isEqual:other.yourPublicKey])
        return NO;
    if (_myPublicKeyVerified != other.myPublicKeyVerified)
        return NO;
    if (_yourPublicKeyVerified != other.yourPublicKeyVerified)
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_rendezvousTag hash];
    hash = hash * 31u + (NSUInteger)_rendezvousOwner;
    hash = hash * 31u + [_conversationId hash];
    hash = hash * 31u + [_conversationType hash];
    hash = hash * 31u + [_authenticationType hash];
    hash = hash * 31u + [_myKey hash];
    hash = hash * 31u + [_yourPublicKey hash];
    hash = hash * 31u + (NSUInteger)_myPublicKeyVerified;
    hash = hash * 31u + (NSUInteger)_yourPublicKeyVerified;
    return hash;
       
}

@end

@implementation QLFNotificationTarget



+ (QLFNotificationTarget *)fcmRegistrationTokenWithToken:(NSString *)token
{

    return [[QLFFcmRegistrationToken alloc] initWithToken:token];
       
}

+ (QLFNotificationTarget *)apnsDeviceTokenWithToken:(NSData *)token
{

    return [[QLFApnsDeviceToken alloc] initWithToken:token];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFFcmRegistrationToken class]]) {
            [QLFFcmRegistrationToken marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFApnsDeviceToken class]]) {
            [QLFApnsDeviceToken marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"FcmRegistrationToken"]) {
            QLFNotificationTarget *_temp = [QLFFcmRegistrationToken unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"ApnsDeviceToken"]) {
            QLFNotificationTarget *_temp = [QLFApnsDeviceToken unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifFcmRegistrationToken:(void (^)(NSString *))ifFcmRegistrationTokenBlock ifApnsDeviceToken:(void (^)(NSData *))ifApnsDeviceTokenBlock
{
    if ([self isKindOfClass:[QLFFcmRegistrationToken class]]) {
        ifFcmRegistrationTokenBlock([((QLFFcmRegistrationToken *) self) token]);
    } else if ([self isKindOfClass:[QLFApnsDeviceToken class]]) {
        ifApnsDeviceTokenBlock([((QLFApnsDeviceToken *) self) token]);
    }
}

- (NSComparisonResult)compare:(QLFNotificationTarget *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToNotificationTarget:(QLFNotificationTarget *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFFcmRegistrationToken



+ (QLFNotificationTarget *)fcmRegistrationTokenWithToken:(NSString *)token
{

    return [[QLFFcmRegistrationToken alloc] initWithToken:token];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFFcmRegistrationToken *e = (QLFFcmRegistrationToken *)element;
        [writer writeConstructorStartWithObjectName:@"FcmRegistrationToken"];
            [writer writeFieldStartWithFieldName:@"token"];
                [QredoPrimitiveMarshallers stringMarshaller]([e token], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'token'
                NSString *token = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
        
        return [QLFNotificationTarget fcmRegistrationTokenWithToken:token];
    };
}

- (instancetype)initWithToken:(NSString *)token
{

    self = [super init];
    if (self) {
        _token = token;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFFcmRegistrationToken *)other
{
    if ([other isKindOfClass:[QLFNotificationTarget class]] && ![other isKindOfClass:[QLFFcmRegistrationToken class]]) {
        // N.B. impose an ordering among subtypes of NotificationTarget
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(token);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToFcmRegistrationToken:other];
       
}

- (BOOL)isEqualToFcmRegistrationToken:(QLFFcmRegistrationToken *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_token != other.token && ![_token isEqual:other.token])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_token hash];
    return hash;
       
}

@end

@implementation QLFApnsDeviceToken



+ (QLFNotificationTarget *)apnsDeviceTokenWithToken:(NSData *)token
{

    return [[QLFApnsDeviceToken alloc] initWithToken:token];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFApnsDeviceToken *e = (QLFApnsDeviceToken *)element;
        [writer writeConstructorStartWithObjectName:@"ApnsDeviceToken"];
            [writer writeFieldStartWithFieldName:@"token"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e token], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'token'
                NSData *token = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        
        return [QLFNotificationTarget apnsDeviceTokenWithToken:token];
    };
}

- (instancetype)initWithToken:(NSData *)token
{

    self = [super init];
    if (self) {
        _token = token;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFApnsDeviceToken *)other
{
    if ([other isKindOfClass:[QLFNotificationTarget class]] && ![other isKindOfClass:[QLFApnsDeviceToken class]]) {
        // N.B. impose an ordering among subtypes of NotificationTarget
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(token);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToApnsDeviceToken:other];
       
}

- (BOOL)isEqualToApnsDeviceToken:(QLFApnsDeviceToken *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_token != other.token && ![_token isEqual:other.token])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_token hash];
    return hash;
       
}

@end

@implementation QLFOwnershipSignature



+ (QLFOwnershipSignature *)ownershipSignatureWithOp:(QLFOperationType *)op nonce:(QLFNonce *)nonce timestamp:(QLFTimestamp)timestamp signature:(NSData *)signature
{

    return [[QLFOwnershipSignature alloc] initWithOp:op nonce:nonce timestamp:timestamp signature:signature];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFOwnershipSignature *e = (QLFOwnershipSignature *)element;
        [writer writeConstructorStartWithObjectName:@"OwnershipSignature"];
            [writer writeFieldStartWithFieldName:@"nonce"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e nonce], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"op"];
                [QLFOperationType marshaller]([e op], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"signature"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e signature], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"timestamp"];
                [QredoPrimitiveMarshallers int64Marshaller]([NSNumber numberWithLongLong: [e timestamp]], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'OwnershipSignature'
            [reader readFieldStart]; // TODO assert that field name is 'nonce'
                QLFNonce *nonce = (QLFNonce *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'op'
                QLFOperationType *op = (QLFOperationType *)[QLFOperationType unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'signature'
                NSData *signature = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'timestamp'
                QLFTimestamp timestamp = (QLFTimestamp )[[QredoPrimitiveMarshallers int64Unmarshaller](reader) longLongValue];
            [reader readEnd];
        [reader readEnd];
        return [QLFOwnershipSignature ownershipSignatureWithOp:op nonce:nonce timestamp:timestamp signature:signature];
    };
}

- (instancetype)initWithOp:(QLFOperationType *)op nonce:(QLFNonce *)nonce timestamp:(QLFTimestamp)timestamp signature:(NSData *)signature
{

    self = [super init];
    if (self) {
        _op = op;
        _nonce = nonce;
        _timestamp = timestamp;
        _signature = signature;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFOwnershipSignature *)other
{

    QREDO_COMPARE_OBJECT(op);
    QREDO_COMPARE_OBJECT(nonce);
    QREDO_COMPARE_SCALAR(timestamp);
    QREDO_COMPARE_OBJECT(signature);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToOwnershipSignature:other];
       
}

- (BOOL)isEqualToOwnershipSignature:(QLFOwnershipSignature *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_op != other.op && ![_op isEqual:other.op])
        return NO;
    if (_nonce != other.nonce && ![_nonce isEqual:other.nonce])
        return NO;
    if (_timestamp != other.timestamp)
        return NO;
    if (_signature != other.signature && ![_signature isEqual:other.signature])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_op hash];
    hash = hash * 31u + [_nonce hash];
    hash = hash * 31u + (NSUInteger)_timestamp;
    hash = hash * 31u + [_signature hash];
    return hash;
       
}

@end

@implementation QLFRendezvousResponderInfo



+ (QLFRendezvousResponderInfo *)rendezvousResponderInfoWithRequesterPublicKey:(QLFRequesterPublicKey *)requesterPublicKey conversationType:(NSString *)conversationType transCap:(NSSet *)transCap
{

    return [[QLFRendezvousResponderInfo alloc] initWithRequesterPublicKey:requesterPublicKey conversationType:conversationType transCap:transCap];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousResponderInfo *e = (QLFRendezvousResponderInfo *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousResponderInfo"];
            [writer writeFieldStartWithFieldName:@"conversationType"];
                [QredoPrimitiveMarshallers stringMarshaller]([e conversationType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"requesterPublicKey"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e requesterPublicKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"transCap"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]]([e transCap], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'RendezvousResponderInfo'
            [reader readFieldStart]; // TODO assert that field name is 'conversationType'
                NSString *conversationType = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'requesterPublicKey'
                QLFRequesterPublicKey *requesterPublicKey = (QLFRequesterPublicKey *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'transCap'
                NSSet *transCap = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFRendezvousResponderInfo rendezvousResponderInfoWithRequesterPublicKey:requesterPublicKey conversationType:conversationType transCap:transCap];
    };
}

- (instancetype)initWithRequesterPublicKey:(QLFRequesterPublicKey *)requesterPublicKey conversationType:(NSString *)conversationType transCap:(NSSet *)transCap
{

    self = [super init];
    if (self) {
        _requesterPublicKey = requesterPublicKey;
        _conversationType = conversationType;
        _transCap = transCap;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousResponderInfo *)other
{

    QREDO_COMPARE_OBJECT(requesterPublicKey);
    QREDO_COMPARE_OBJECT(conversationType);
    QREDO_COMPARE_OBJECT(transCap);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousResponderInfo:other];
       
}

- (BOOL)isEqualToRendezvousResponderInfo:(QLFRendezvousResponderInfo *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_requesterPublicKey != other.requesterPublicKey && ![_requesterPublicKey isEqual:other.requesterPublicKey])
        return NO;
    if (_conversationType != other.conversationType && ![_conversationType isEqual:other.conversationType])
        return NO;
    if (_transCap != other.transCap && ![_transCap isEqual:other.transCap])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_requesterPublicKey hash];
    hash = hash * 31u + [_conversationType hash];
    hash = hash * 31u + [_transCap hash];
    return hash;
       
}

@end

@implementation QLFRendezvousActivated



+ (QLFRendezvousActivated *)rendezvousActivatedWithExpiresAt:(NSSet *)expiresAt
{

    return [[QLFRendezvousActivated alloc] initWithExpiresAt:expiresAt];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousActivated *e = (QLFRendezvousActivated *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousActivated"];
            [writer writeFieldStartWithFieldName:@"expiresAt"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers utcDateTimeMarshaller]]([e expiresAt], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'RendezvousActivated'
            [reader readFieldStart]; // TODO assert that field name is 'expiresAt'
                NSSet *expiresAt = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers utcDateTimeUnmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFRendezvousActivated rendezvousActivatedWithExpiresAt:expiresAt];
    };
}

- (instancetype)initWithExpiresAt:(NSSet *)expiresAt
{

    self = [super init];
    if (self) {
        _expiresAt = expiresAt;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousActivated *)other
{

    QREDO_COMPARE_OBJECT(expiresAt);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousActivated:other];
       
}

- (BOOL)isEqualToRendezvousActivated:(QLFRendezvousActivated *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_expiresAt != other.expiresAt && ![_expiresAt isEqual:other.expiresAt])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_expiresAt hash];
    return hash;
       
}

@end

@implementation QLFRendezvousCreateResult



+ (QLFRendezvousCreateResult *)rendezvousCreatedWithExpiresAt:(NSSet *)expiresAt
{

    return [[QLFRendezvousCreated alloc] initWithExpiresAt:expiresAt];
       
}

+ (QLFRendezvousCreateResult *)rendezvousAlreadyExists
{

    return [[QLFRendezvousAlreadyExists alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFRendezvousCreated class]]) {
            [QLFRendezvousCreated marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFRendezvousAlreadyExists class]]) {
            [QLFRendezvousAlreadyExists marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"RendezvousCreated"]) {
            QLFRendezvousCreateResult *_temp = [QLFRendezvousCreated unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"RendezvousAlreadyExists"]) {
            QLFRendezvousCreateResult *_temp = [QLFRendezvousAlreadyExists unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifRendezvousCreated:(void (^)(NSSet *))ifRendezvousCreatedBlock ifRendezvousAlreadyExists:(void (^)())ifRendezvousAlreadyExistsBlock
{
    if ([self isKindOfClass:[QLFRendezvousCreated class]]) {
        ifRendezvousCreatedBlock([((QLFRendezvousCreated *) self) expiresAt]);
    } else if ([self isKindOfClass:[QLFRendezvousAlreadyExists class]]) {
        ifRendezvousAlreadyExistsBlock();
    }
}

- (NSComparisonResult)compare:(QLFRendezvousCreateResult *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToRendezvousCreateResult:(QLFRendezvousCreateResult *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFRendezvousCreated



+ (QLFRendezvousCreateResult *)rendezvousCreatedWithExpiresAt:(NSSet *)expiresAt
{

    return [[QLFRendezvousCreated alloc] initWithExpiresAt:expiresAt];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousCreated *e = (QLFRendezvousCreated *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousCreated"];
            [writer writeFieldStartWithFieldName:@"expiresAt"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers utcDateTimeMarshaller]]([e expiresAt], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'expiresAt'
                NSSet *expiresAt = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers utcDateTimeUnmarshaller]](reader);
            [reader readEnd];
        
        return [QLFRendezvousCreateResult rendezvousCreatedWithExpiresAt:expiresAt];
    };
}

- (instancetype)initWithExpiresAt:(NSSet *)expiresAt
{

    self = [super init];
    if (self) {
        _expiresAt = expiresAt;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousCreated *)other
{
    if ([other isKindOfClass:[QLFRendezvousCreateResult class]] && ![other isKindOfClass:[QLFRendezvousCreated class]]) {
        // N.B. impose an ordering among subtypes of RendezvousCreateResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(expiresAt);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousCreated:other];
       
}

- (BOOL)isEqualToRendezvousCreated:(QLFRendezvousCreated *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_expiresAt != other.expiresAt && ![_expiresAt isEqual:other.expiresAt])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_expiresAt hash];
    return hash;
       
}

@end

@implementation QLFRendezvousAlreadyExists



+ (QLFRendezvousCreateResult *)rendezvousAlreadyExists
{

    return [[QLFRendezvousAlreadyExists alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousAlreadyExists *e = (QLFRendezvousAlreadyExists *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousAlreadyExists"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFRendezvousCreateResult rendezvousAlreadyExists];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousAlreadyExists *)other
{
    if ([other isKindOfClass:[QLFRendezvousCreateResult class]] && ![other isKindOfClass:[QLFRendezvousAlreadyExists class]]) {
        // N.B. impose an ordering among subtypes of RendezvousCreateResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousAlreadyExists:other];
       
}

- (BOOL)isEqualToRendezvousAlreadyExists:(QLFRendezvousAlreadyExists *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
    return hash;
       
}

@end

@implementation QLFRendezvousDescriptor



+ (QLFRendezvousDescriptor *)rendezvousDescriptorWithTag:(NSString *)tag hashedTag:(QLFRendezvousHashedTag *)hashedTag conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType durationSeconds:(NSSet *)durationSeconds expiresAt:(NSSet *)expiresAt responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit requesterKeyPair:(QLFKeyPairLF *)requesterKeyPair ownershipKeyPair:(QLFKeyPairLF *)ownershipKeyPair
{

    return [[QLFRendezvousDescriptor alloc] initWithTag:tag hashedTag:hashedTag conversationType:conversationType authenticationType:authenticationType durationSeconds:durationSeconds expiresAt:expiresAt responseCountLimit:responseCountLimit requesterKeyPair:requesterKeyPair ownershipKeyPair:ownershipKeyPair];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousDescriptor *e = (QLFRendezvousDescriptor *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousDescriptor"];
            [writer writeFieldStartWithFieldName:@"authenticationType"];
                [QLFRendezvousAuthType marshaller]([e authenticationType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"conversationType"];
                [QredoPrimitiveMarshallers stringMarshaller]([e conversationType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"durationSeconds"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int32Marshaller]]([e durationSeconds], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"expiresAt"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers utcDateTimeMarshaller]]([e expiresAt], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"hashedTag"];
                [QredoPrimitiveMarshallers quidMarshaller]([e hashedTag], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"ownershipKeyPair"];
                [QLFKeyPairLF marshaller]([e ownershipKeyPair], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"requesterKeyPair"];
                [QLFKeyPairLF marshaller]([e requesterKeyPair], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"responseCountLimit"];
                [QLFRendezvousResponseCountLimit marshaller]([e responseCountLimit], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"tag"];
                [QredoPrimitiveMarshallers stringMarshaller]([e tag], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'RendezvousDescriptor'
            [reader readFieldStart]; // TODO assert that field name is 'authenticationType'
                QLFRendezvousAuthType *authenticationType = (QLFRendezvousAuthType *)[QLFRendezvousAuthType unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'conversationType'
                NSString *conversationType = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'durationSeconds'
                NSSet *durationSeconds = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers int32Unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'expiresAt'
                NSSet *expiresAt = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers utcDateTimeUnmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'hashedTag'
                QLFRendezvousHashedTag *hashedTag = (QLFRendezvousHashedTag *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'ownershipKeyPair'
                QLFKeyPairLF *ownershipKeyPair = (QLFKeyPairLF *)[QLFKeyPairLF unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'requesterKeyPair'
                QLFKeyPairLF *requesterKeyPair = (QLFKeyPairLF *)[QLFKeyPairLF unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'responseCountLimit'
                QLFRendezvousResponseCountLimit *responseCountLimit = (QLFRendezvousResponseCountLimit *)[QLFRendezvousResponseCountLimit unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'tag'
                NSString *tag = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFRendezvousDescriptor rendezvousDescriptorWithTag:tag hashedTag:hashedTag conversationType:conversationType authenticationType:authenticationType durationSeconds:durationSeconds expiresAt:expiresAt responseCountLimit:responseCountLimit requesterKeyPair:requesterKeyPair ownershipKeyPair:ownershipKeyPair];
    };
}

- (instancetype)initWithTag:(NSString *)tag hashedTag:(QLFRendezvousHashedTag *)hashedTag conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType durationSeconds:(NSSet *)durationSeconds expiresAt:(NSSet *)expiresAt responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit requesterKeyPair:(QLFKeyPairLF *)requesterKeyPair ownershipKeyPair:(QLFKeyPairLF *)ownershipKeyPair
{

    self = [super init];
    if (self) {
        _tag = tag;
        _hashedTag = hashedTag;
        _conversationType = conversationType;
        _authenticationType = authenticationType;
        _durationSeconds = durationSeconds;
        _expiresAt = expiresAt;
        _responseCountLimit = responseCountLimit;
        _requesterKeyPair = requesterKeyPair;
        _ownershipKeyPair = ownershipKeyPair;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousDescriptor *)other
{

    QREDO_COMPARE_OBJECT(tag);
    QREDO_COMPARE_OBJECT(hashedTag);
    QREDO_COMPARE_OBJECT(conversationType);
    QREDO_COMPARE_OBJECT(authenticationType);
    QREDO_COMPARE_OBJECT(durationSeconds);
    QREDO_COMPARE_OBJECT(expiresAt);
    QREDO_COMPARE_OBJECT(responseCountLimit);
    QREDO_COMPARE_OBJECT(requesterKeyPair);
    QREDO_COMPARE_OBJECT(ownershipKeyPair);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousDescriptor:other];
       
}

- (BOOL)isEqualToRendezvousDescriptor:(QLFRendezvousDescriptor *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_tag != other.tag && ![_tag isEqual:other.tag])
        return NO;
    if (_hashedTag != other.hashedTag && ![_hashedTag isEqual:other.hashedTag])
        return NO;
    if (_conversationType != other.conversationType && ![_conversationType isEqual:other.conversationType])
        return NO;
    if (_authenticationType != other.authenticationType && ![_authenticationType isEqual:other.authenticationType])
        return NO;
    if (_durationSeconds != other.durationSeconds && ![_durationSeconds isEqual:other.durationSeconds])
        return NO;
    if (_expiresAt != other.expiresAt && ![_expiresAt isEqual:other.expiresAt])
        return NO;
    if (_responseCountLimit != other.responseCountLimit && ![_responseCountLimit isEqual:other.responseCountLimit])
        return NO;
    if (_requesterKeyPair != other.requesterKeyPair && ![_requesterKeyPair isEqual:other.requesterKeyPair])
        return NO;
    if (_ownershipKeyPair != other.ownershipKeyPair && ![_ownershipKeyPair isEqual:other.ownershipKeyPair])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_tag hash];
    hash = hash * 31u + [_hashedTag hash];
    hash = hash * 31u + [_conversationType hash];
    hash = hash * 31u + [_authenticationType hash];
    hash = hash * 31u + [_durationSeconds hash];
    hash = hash * 31u + [_expiresAt hash];
    hash = hash * 31u + [_responseCountLimit hash];
    hash = hash * 31u + [_requesterKeyPair hash];
    hash = hash * 31u + [_ownershipKeyPair hash];
    return hash;
       
}

@end

@implementation QLFRendezvousInfo



+ (QLFRendezvousInfo *)rendezvousInfoWithNumOfResponses:(QLFRendezvousNumOfResponses)numOfResponses responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit expiresAt:(NSSet *)expiresAt deactivatedAt:(NSSet *)deactivatedAt
{

    return [[QLFRendezvousInfo alloc] initWithNumOfResponses:numOfResponses responseCountLimit:responseCountLimit expiresAt:expiresAt deactivatedAt:deactivatedAt];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousInfo *e = (QLFRendezvousInfo *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousInfo"];
            [writer writeFieldStartWithFieldName:@"deactivatedAt"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers utcDateTimeMarshaller]]([e deactivatedAt], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"expiresAt"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers utcDateTimeMarshaller]]([e expiresAt], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"numOfResponses"];
                [QredoPrimitiveMarshallers int64Marshaller]([NSNumber numberWithLongLong: [e numOfResponses]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"responseCountLimit"];
                [QLFRendezvousResponseCountLimit marshaller]([e responseCountLimit], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'RendezvousInfo'
            [reader readFieldStart]; // TODO assert that field name is 'deactivatedAt'
                NSSet *deactivatedAt = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers utcDateTimeUnmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'expiresAt'
                NSSet *expiresAt = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers utcDateTimeUnmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'numOfResponses'
                QLFRendezvousNumOfResponses numOfResponses = (QLFRendezvousNumOfResponses )[[QredoPrimitiveMarshallers int64Unmarshaller](reader) longLongValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'responseCountLimit'
                QLFRendezvousResponseCountLimit *responseCountLimit = (QLFRendezvousResponseCountLimit *)[QLFRendezvousResponseCountLimit unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFRendezvousInfo rendezvousInfoWithNumOfResponses:numOfResponses responseCountLimit:responseCountLimit expiresAt:expiresAt deactivatedAt:deactivatedAt];
    };
}

- (instancetype)initWithNumOfResponses:(QLFRendezvousNumOfResponses)numOfResponses responseCountLimit:(QLFRendezvousResponseCountLimit *)responseCountLimit expiresAt:(NSSet *)expiresAt deactivatedAt:(NSSet *)deactivatedAt
{

    self = [super init];
    if (self) {
        _numOfResponses = numOfResponses;
        _responseCountLimit = responseCountLimit;
        _expiresAt = expiresAt;
        _deactivatedAt = deactivatedAt;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousInfo *)other
{

    QREDO_COMPARE_SCALAR(numOfResponses);
    QREDO_COMPARE_OBJECT(responseCountLimit);
    QREDO_COMPARE_OBJECT(expiresAt);
    QREDO_COMPARE_OBJECT(deactivatedAt);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousInfo:other];
       
}

- (BOOL)isEqualToRendezvousInfo:(QLFRendezvousInfo *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_numOfResponses != other.numOfResponses)
        return NO;
    if (_responseCountLimit != other.responseCountLimit && ![_responseCountLimit isEqual:other.responseCountLimit])
        return NO;
    if (_expiresAt != other.expiresAt && ![_expiresAt isEqual:other.expiresAt])
        return NO;
    if (_deactivatedAt != other.deactivatedAt && ![_deactivatedAt isEqual:other.deactivatedAt])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + (NSUInteger)_numOfResponses;
    hash = hash * 31u + [_responseCountLimit hash];
    hash = hash * 31u + [_expiresAt hash];
    hash = hash * 31u + [_deactivatedAt hash];
    return hash;
       
}

@end

@implementation QLFSV



+ (QLFSV *)sBoolWithV:(BOOL)v
{

    return [[QLFSBool alloc] initWithV:v];
       
}

+ (QLFSV *)sInt64WithV:(int64_t)v
{

    return [[QLFSInt64 alloc] initWithV:v];
       
}

+ (QLFSV *)sDTWithV:(QredoUTCDateTime *)v
{

    return [[QLFSDT alloc] initWithV:v];
       
}

+ (QLFSV *)sQUIDWithV:(QredoQUID *)v
{

    return [[QLFSQUID alloc] initWithV:v];
       
}

+ (QLFSV *)sStringWithV:(NSString *)v
{

    return [[QLFSString alloc] initWithV:v];
       
}

+ (QLFSV *)sBytesWithV:(NSData *)v
{

    return [[QLFSBytes alloc] initWithV:v];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFSBool class]]) {
            [QLFSBool marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFSInt64 class]]) {
            [QLFSInt64 marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFSDT class]]) {
            [QLFSDT marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFSQUID class]]) {
            [QLFSQUID marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFSString class]]) {
            [QLFSString marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFSBytes class]]) {
            [QLFSBytes marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"SBool"]) {
            QLFSV *_temp = [QLFSBool unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"SInt64"]) {
            QLFSV *_temp = [QLFSInt64 unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"SDT"]) {
            QLFSV *_temp = [QLFSDT unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"SQUID"]) {
            QLFSV *_temp = [QLFSQUID unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"SString"]) {
            QLFSV *_temp = [QLFSString unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"SBytes"]) {
            QLFSV *_temp = [QLFSBytes unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifSBool:(void (^)(BOOL ))ifSBoolBlock ifSInt64:(void (^)(int64_t ))ifSInt64Block ifSDT:(void (^)(QredoUTCDateTime *))ifSDTBlock ifSQUID:(void (^)(QredoQUID *))ifSQUIDBlock ifSString:(void (^)(NSString *))ifSStringBlock ifSBytes:(void (^)(NSData *))ifSBytesBlock
{
    if ([self isKindOfClass:[QLFSBool class]]) {
        ifSBoolBlock([((QLFSBool *) self) v]);
    } else if ([self isKindOfClass:[QLFSInt64 class]]) {
        ifSInt64Block([((QLFSInt64 *) self) v]);
    } else if ([self isKindOfClass:[QLFSDT class]]) {
        ifSDTBlock([((QLFSDT *) self) v]);
    } else if ([self isKindOfClass:[QLFSQUID class]]) {
        ifSQUIDBlock([((QLFSQUID *) self) v]);
    } else if ([self isKindOfClass:[QLFSString class]]) {
        ifSStringBlock([((QLFSString *) self) v]);
    } else if ([self isKindOfClass:[QLFSBytes class]]) {
        ifSBytesBlock([((QLFSBytes *) self) v]);
    }
}

- (NSComparisonResult)compare:(QLFSV *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToSV:(QLFSV *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFSBool



+ (QLFSV *)sBoolWithV:(BOOL)v
{

    return [[QLFSBool alloc] initWithV:v];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFSBool *e = (QLFSBool *)element;
        [writer writeConstructorStartWithObjectName:@"SBool"];
            [writer writeFieldStartWithFieldName:@"v"];
                [QredoPrimitiveMarshallers booleanMarshaller]([NSNumber numberWithBool: [e v]], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'v'
                BOOL v = (BOOL )[[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
            [reader readEnd];
        
        return [QLFSV sBoolWithV:v];
    };
}

- (instancetype)initWithV:(BOOL)v
{

    self = [super init];
    if (self) {
        _v = v;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFSBool *)other
{
    if ([other isKindOfClass:[QLFSV class]] && ![other isKindOfClass:[QLFSBool class]]) {
        // N.B. impose an ordering among subtypes of SV
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_SCALAR(v);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToSBool:other];
       
}

- (BOOL)isEqualToSBool:(QLFSBool *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_v != other.v)
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + (NSUInteger)_v;
    return hash;
       
}

@end

@implementation QLFSInt64



+ (QLFSV *)sInt64WithV:(int64_t)v
{

    return [[QLFSInt64 alloc] initWithV:v];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFSInt64 *e = (QLFSInt64 *)element;
        [writer writeConstructorStartWithObjectName:@"SInt64"];
            [writer writeFieldStartWithFieldName:@"v"];
                [QredoPrimitiveMarshallers int64Marshaller]([NSNumber numberWithLongLong: [e v]], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'v'
                int64_t v = (int64_t )[[QredoPrimitiveMarshallers int64Unmarshaller](reader) longLongValue];
            [reader readEnd];
        
        return [QLFSV sInt64WithV:v];
    };
}

- (instancetype)initWithV:(int64_t)v
{

    self = [super init];
    if (self) {
        _v = v;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFSInt64 *)other
{
    if ([other isKindOfClass:[QLFSV class]] && ![other isKindOfClass:[QLFSInt64 class]]) {
        // N.B. impose an ordering among subtypes of SV
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_SCALAR(v);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToSInt64:other];
       
}

- (BOOL)isEqualToSInt64:(QLFSInt64 *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_v != other.v)
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + (NSUInteger)_v;
    return hash;
       
}

@end

@implementation QLFSDT



+ (QLFSV *)sDTWithV:(QredoUTCDateTime *)v
{

    return [[QLFSDT alloc] initWithV:v];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFSDT *e = (QLFSDT *)element;
        [writer writeConstructorStartWithObjectName:@"SDT"];
            [writer writeFieldStartWithFieldName:@"v"];
                [QredoPrimitiveMarshallers utcDateTimeMarshaller]([e v], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'v'
                QredoUTCDateTime *v = (QredoUTCDateTime *)[QredoPrimitiveMarshallers utcDateTimeUnmarshaller](reader);
            [reader readEnd];
        
        return [QLFSV sDTWithV:v];
    };
}

- (instancetype)initWithV:(QredoUTCDateTime *)v
{

    self = [super init];
    if (self) {
        _v = v;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFSDT *)other
{
    if ([other isKindOfClass:[QLFSV class]] && ![other isKindOfClass:[QLFSDT class]]) {
        // N.B. impose an ordering among subtypes of SV
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(v);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToSDT:other];
       
}

- (BOOL)isEqualToSDT:(QLFSDT *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_v != other.v && ![_v isEqual:other.v])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_v hash];
    return hash;
       
}

@end

@implementation QLFSQUID



+ (QLFSV *)sQUIDWithV:(QredoQUID *)v
{

    return [[QLFSQUID alloc] initWithV:v];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFSQUID *e = (QLFSQUID *)element;
        [writer writeConstructorStartWithObjectName:@"SQUID"];
            [writer writeFieldStartWithFieldName:@"v"];
                [QredoPrimitiveMarshallers quidMarshaller]([e v], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'v'
                QredoQUID *v = (QredoQUID *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
        
        return [QLFSV sQUIDWithV:v];
    };
}

- (instancetype)initWithV:(QredoQUID *)v
{

    self = [super init];
    if (self) {
        _v = v;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFSQUID *)other
{
    if ([other isKindOfClass:[QLFSV class]] && ![other isKindOfClass:[QLFSQUID class]]) {
        // N.B. impose an ordering among subtypes of SV
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(v);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToSQUID:other];
       
}

- (BOOL)isEqualToSQUID:(QLFSQUID *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_v != other.v && ![_v isEqual:other.v])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_v hash];
    return hash;
       
}

@end

@implementation QLFSString



+ (QLFSV *)sStringWithV:(NSString *)v
{

    return [[QLFSString alloc] initWithV:v];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFSString *e = (QLFSString *)element;
        [writer writeConstructorStartWithObjectName:@"SString"];
            [writer writeFieldStartWithFieldName:@"v"];
                [QredoPrimitiveMarshallers stringMarshaller]([e v], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'v'
                NSString *v = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
        
        return [QLFSV sStringWithV:v];
    };
}

- (instancetype)initWithV:(NSString *)v
{

    self = [super init];
    if (self) {
        _v = v;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFSString *)other
{
    if ([other isKindOfClass:[QLFSV class]] && ![other isKindOfClass:[QLFSString class]]) {
        // N.B. impose an ordering among subtypes of SV
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(v);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToSString:other];
       
}

- (BOOL)isEqualToSString:(QLFSString *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_v != other.v && ![_v isEqual:other.v])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_v hash];
    return hash;
       
}

@end

@implementation QLFSBytes



+ (QLFSV *)sBytesWithV:(NSData *)v
{

    return [[QLFSBytes alloc] initWithV:v];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFSBytes *e = (QLFSBytes *)element;
        [writer writeConstructorStartWithObjectName:@"SBytes"];
            [writer writeFieldStartWithFieldName:@"v"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e v], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'v'
                NSData *v = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        
        return [QLFSV sBytesWithV:v];
    };
}

- (instancetype)initWithV:(NSData *)v
{

    self = [super init];
    if (self) {
        _v = v;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFSBytes *)other
{
    if ([other isKindOfClass:[QLFSV class]] && ![other isKindOfClass:[QLFSBytes class]]) {
        // N.B. impose an ordering among subtypes of SV
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(v);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToSBytes:other];
       
}

- (BOOL)isEqualToSBytes:(QLFSBytes *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_v != other.v && ![_v isEqual:other.v])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_v hash];
    return hash;
       
}

@end

@implementation QLFIndexable



+ (QLFIndexable *)indexableWithKey:(NSString *)key value:(QLFSV *)value
{

    return [[QLFIndexable alloc] initWithKey:key value:value];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFIndexable *e = (QLFIndexable *)element;
        [writer writeConstructorStartWithObjectName:@"Indexable"];
            [writer writeFieldStartWithFieldName:@"key"];
                [QredoPrimitiveMarshallers stringMarshaller]([e key], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"value"];
                [QLFSV marshaller]([e value], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'Indexable'
            [reader readFieldStart]; // TODO assert that field name is 'key'
                NSString *key = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'value'
                QLFSV *value = (QLFSV *)[QLFSV unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFIndexable indexableWithKey:key value:value];
    };
}

- (instancetype)initWithKey:(NSString *)key value:(QLFSV *)value
{

    self = [super init];
    if (self) {
        _key = key;
        _value = value;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFIndexable *)other
{

    QREDO_COMPARE_OBJECT(key);
    QREDO_COMPARE_OBJECT(value);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToIndexable:other];
       
}

- (BOOL)isEqualToIndexable:(QLFIndexable *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_key != other.key && ![_key isEqual:other.key])
        return NO;
    if (_value != other.value && ![_value isEqual:other.value])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_key hash];
    hash = hash * 31u + [_value hash];
    return hash;
       
}

@end

@implementation QLFConversationMessageMetadata



+ (QLFConversationMessageMetadata *)conversationMessageMetadataWithID:(QLFConversationMessageId *)id parentId:(NSSet *)parentId sequence:(QLFConversationSequenceValue *)sequence sentByMe:(BOOL)sentByMe created:(QredoUTCDateTime *)created dataType:(NSString *)dataType values:(NSSet *)values
{

    return [[QLFConversationMessageMetadata alloc] initWithID:id parentId:parentId sequence:sequence sentByMe:sentByMe created:created dataType:dataType values:values];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFConversationMessageMetadata *e = (QLFConversationMessageMetadata *)element;
        [writer writeConstructorStartWithObjectName:@"ConversationMessageMetadata"];
            [writer writeFieldStartWithFieldName:@"created"];
                [QredoPrimitiveMarshallers utcDateTimeMarshaller]([e created], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"dataType"];
                [QredoPrimitiveMarshallers stringMarshaller]([e dataType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"id"];
                [QredoPrimitiveMarshallers quidMarshaller]([e id], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"parentId"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers quidMarshaller]]([e parentId], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"sentByMe"];
                [QredoPrimitiveMarshallers booleanMarshaller]([NSNumber numberWithBool: [e sentByMe]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"sequence"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e sequence], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"values"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFIndexable marshaller]]([e values], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'ConversationMessageMetadata'
            [reader readFieldStart]; // TODO assert that field name is 'created'
                QredoUTCDateTime *created = (QredoUTCDateTime *)[QredoPrimitiveMarshallers utcDateTimeUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'dataType'
                NSString *dataType = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'id'
                QLFConversationMessageId *id = (QLFConversationMessageId *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'parentId'
                NSSet *parentId = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers quidUnmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sentByMe'
                BOOL sentByMe = (BOOL )[[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sequence'
                QLFConversationSequenceValue *sequence = (QLFConversationSequenceValue *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'values'
                NSSet *values = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFIndexable unmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFConversationMessageMetadata conversationMessageMetadataWithID:id parentId:parentId sequence:sequence sentByMe:sentByMe created:created dataType:dataType values:values];
    };
}

- (instancetype)initWithID:(QLFConversationMessageId *)id parentId:(NSSet *)parentId sequence:(QLFConversationSequenceValue *)sequence sentByMe:(BOOL)sentByMe created:(QredoUTCDateTime *)created dataType:(NSString *)dataType values:(NSSet *)values
{

    self = [super init];
    if (self) {
        _id = id;
        _parentId = parentId;
        _sequence = sequence;
        _sentByMe = sentByMe;
        _created = created;
        _dataType = dataType;
        _values = values;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFConversationMessageMetadata *)other
{

    QREDO_COMPARE_OBJECT(id);
    QREDO_COMPARE_OBJECT(parentId);
    QREDO_COMPARE_OBJECT(sequence);
    QREDO_COMPARE_SCALAR(sentByMe);
    QREDO_COMPARE_OBJECT(created);
    QREDO_COMPARE_OBJECT(dataType);
    QREDO_COMPARE_OBJECT(values);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToConversationMessageMetadata:other];
       
}

- (BOOL)isEqualToConversationMessageMetadata:(QLFConversationMessageMetadata *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_id != other.id && ![_id isEqual:other.id])
        return NO;
    if (_parentId != other.parentId && ![_parentId isEqual:other.parentId])
        return NO;
    if (_sequence != other.sequence && ![_sequence isEqual:other.sequence])
        return NO;
    if (_sentByMe != other.sentByMe)
        return NO;
    if (_created != other.created && ![_created isEqual:other.created])
        return NO;
    if (_dataType != other.dataType && ![_dataType isEqual:other.dataType])
        return NO;
    if (_values != other.values && ![_values isEqual:other.values])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_id hash];
    hash = hash * 31u + [_parentId hash];
    hash = hash * 31u + [_sequence hash];
    hash = hash * 31u + (NSUInteger)_sentByMe;
    hash = hash * 31u + [_created hash];
    hash = hash * 31u + [_dataType hash];
    hash = hash * 31u + [_values hash];
    return hash;
       
}

@end

@implementation QLFConversationMessage



+ (QLFConversationMessage *)conversationMessageWithMetadata:(QLFConversationMessageMetadata *)metadata body:(NSData *)body
{

    return [[QLFConversationMessage alloc] initWithMetadata:metadata body:body];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFConversationMessage *e = (QLFConversationMessage *)element;
        [writer writeConstructorStartWithObjectName:@"ConversationMessage"];
            [writer writeFieldStartWithFieldName:@"body"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e body], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"metadata"];
                [QLFConversationMessageMetadata marshaller]([e metadata], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'ConversationMessage'
            [reader readFieldStart]; // TODO assert that field name is 'body'
                NSData *body = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'metadata'
                QLFConversationMessageMetadata *metadata = (QLFConversationMessageMetadata *)[QLFConversationMessageMetadata unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFConversationMessage conversationMessageWithMetadata:metadata body:body];
    };
}

- (instancetype)initWithMetadata:(QLFConversationMessageMetadata *)metadata body:(NSData *)body
{

    self = [super init];
    if (self) {
        _metadata = metadata;
        _body = body;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFConversationMessage *)other
{

    QREDO_COMPARE_OBJECT(metadata);
    QREDO_COMPARE_OBJECT(body);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToConversationMessage:other];
       
}

- (BOOL)isEqualToConversationMessage:(QLFConversationMessage *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_metadata != other.metadata && ![_metadata isEqual:other.metadata])
        return NO;
    if (_body != other.body && ![_body isEqual:other.body])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_metadata hash];
    hash = hash * 31u + [_body hash];
    return hash;
       
}

@end

@implementation QLFServiceAccessInfo



+ (QLFServiceAccessInfo *)serviceAccessInfoWithServiceAccess:(QLFServiceAccess *)serviceAccess expirySeconds:(int32_t)expirySeconds renegotiationSeconds:(int32_t)renegotiationSeconds issuanceDateTimeUTC:(QredoUTCDateTime *)issuanceDateTimeUTC
{

    return [[QLFServiceAccessInfo alloc] initWithServiceAccess:serviceAccess expirySeconds:expirySeconds renegotiationSeconds:renegotiationSeconds issuanceDateTimeUTC:issuanceDateTimeUTC];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFServiceAccessInfo *e = (QLFServiceAccessInfo *)element;
        [writer writeConstructorStartWithObjectName:@"ServiceAccessInfo"];
            [writer writeFieldStartWithFieldName:@"expirySeconds"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e expirySeconds]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"issuanceDateTimeUTC"];
                [QredoPrimitiveMarshallers utcDateTimeMarshaller]([e issuanceDateTimeUTC], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"renegotiationSeconds"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e renegotiationSeconds]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"serviceAccess"];
                [QLFServiceAccess marshaller]([e serviceAccess], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'ServiceAccessInfo'
            [reader readFieldStart]; // TODO assert that field name is 'expirySeconds'
                int32_t expirySeconds = (int32_t )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'issuanceDateTimeUTC'
                QredoUTCDateTime *issuanceDateTimeUTC = (QredoUTCDateTime *)[QredoPrimitiveMarshallers utcDateTimeUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'renegotiationSeconds'
                int32_t renegotiationSeconds = (int32_t )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'serviceAccess'
                QLFServiceAccess *serviceAccess = (QLFServiceAccess *)[QLFServiceAccess unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFServiceAccessInfo serviceAccessInfoWithServiceAccess:serviceAccess expirySeconds:expirySeconds renegotiationSeconds:renegotiationSeconds issuanceDateTimeUTC:issuanceDateTimeUTC];
    };
}

- (instancetype)initWithServiceAccess:(QLFServiceAccess *)serviceAccess expirySeconds:(int32_t)expirySeconds renegotiationSeconds:(int32_t)renegotiationSeconds issuanceDateTimeUTC:(QredoUTCDateTime *)issuanceDateTimeUTC
{

    self = [super init];
    if (self) {
        _serviceAccess = serviceAccess;
        _expirySeconds = expirySeconds;
        _renegotiationSeconds = renegotiationSeconds;
        _issuanceDateTimeUTC = issuanceDateTimeUTC;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFServiceAccessInfo *)other
{

    QREDO_COMPARE_OBJECT(serviceAccess);
    QREDO_COMPARE_SCALAR(expirySeconds);
    QREDO_COMPARE_SCALAR(renegotiationSeconds);
    QREDO_COMPARE_OBJECT(issuanceDateTimeUTC);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToServiceAccessInfo:other];
       
}

- (BOOL)isEqualToServiceAccessInfo:(QLFServiceAccessInfo *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_serviceAccess != other.serviceAccess && ![_serviceAccess isEqual:other.serviceAccess])
        return NO;
    if (_expirySeconds != other.expirySeconds)
        return NO;
    if (_renegotiationSeconds != other.renegotiationSeconds)
        return NO;
    if (_issuanceDateTimeUTC != other.issuanceDateTimeUTC && ![_issuanceDateTimeUTC isEqual:other.issuanceDateTimeUTC])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_serviceAccess hash];
    hash = hash * 31u + (NSUInteger)_expirySeconds;
    hash = hash * 31u + (NSUInteger)_renegotiationSeconds;
    hash = hash * 31u + [_issuanceDateTimeUTC hash];
    return hash;
       
}

@end

@implementation QLFOperatorInfo



+ (QLFOperatorInfo *)operatorInfoWithName:(NSString *)name serviceUri:(NSString *)serviceUri accountID:(NSString *)accountID currentServiceAccess:(NSSet *)currentServiceAccess nextServiceAccess:(NSSet *)nextServiceAccess
{

    return [[QLFOperatorInfo alloc] initWithName:name serviceUri:serviceUri accountID:accountID currentServiceAccess:currentServiceAccess nextServiceAccess:nextServiceAccess];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFOperatorInfo *e = (QLFOperatorInfo *)element;
        [writer writeConstructorStartWithObjectName:@"OperatorInfo"];
            [writer writeFieldStartWithFieldName:@"accountID"];
                [QredoPrimitiveMarshallers stringMarshaller]([e accountID], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"currentServiceAccess"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFServiceAccessInfo marshaller]]([e currentServiceAccess], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"name"];
                [QredoPrimitiveMarshallers stringMarshaller]([e name], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"nextServiceAccess"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFServiceAccessInfo marshaller]]([e nextServiceAccess], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"serviceUri"];
                [QredoPrimitiveMarshallers stringMarshaller]([e serviceUri], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'OperatorInfo'
            [reader readFieldStart]; // TODO assert that field name is 'accountID'
                NSString *accountID = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'currentServiceAccess'
                NSSet *currentServiceAccess = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFServiceAccessInfo unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'name'
                NSString *name = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'nextServiceAccess'
                NSSet *nextServiceAccess = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFServiceAccessInfo unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'serviceUri'
                NSString *serviceUri = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFOperatorInfo operatorInfoWithName:name serviceUri:serviceUri accountID:accountID currentServiceAccess:currentServiceAccess nextServiceAccess:nextServiceAccess];
    };
}

- (instancetype)initWithName:(NSString *)name serviceUri:(NSString *)serviceUri accountID:(NSString *)accountID currentServiceAccess:(NSSet *)currentServiceAccess nextServiceAccess:(NSSet *)nextServiceAccess
{

    self = [super init];
    if (self) {
        _name = name;
        _serviceUri = serviceUri;
        _accountID = accountID;
        _currentServiceAccess = currentServiceAccess;
        _nextServiceAccess = nextServiceAccess;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFOperatorInfo *)other
{

    QREDO_COMPARE_OBJECT(name);
    QREDO_COMPARE_OBJECT(serviceUri);
    QREDO_COMPARE_OBJECT(accountID);
    QREDO_COMPARE_OBJECT(currentServiceAccess);
    QREDO_COMPARE_OBJECT(nextServiceAccess);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToOperatorInfo:other];
       
}

- (BOOL)isEqualToOperatorInfo:(QLFOperatorInfo *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_name != other.name && ![_name isEqual:other.name])
        return NO;
    if (_serviceUri != other.serviceUri && ![_serviceUri isEqual:other.serviceUri])
        return NO;
    if (_accountID != other.accountID && ![_accountID isEqual:other.accountID])
        return NO;
    if (_currentServiceAccess != other.currentServiceAccess && ![_currentServiceAccess isEqual:other.currentServiceAccess])
        return NO;
    if (_nextServiceAccess != other.nextServiceAccess && ![_nextServiceAccess isEqual:other.nextServiceAccess])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_name hash];
    hash = hash * 31u + [_serviceUri hash];
    hash = hash * 31u + [_accountID hash];
    hash = hash * 31u + [_currentServiceAccess hash];
    hash = hash * 31u + [_nextServiceAccess hash];
    return hash;
       
}

@end

@implementation QLFVaultItemMetadata



+ (QLFVaultItemMetadata *)vaultItemMetadataWithDataType:(NSString *)dataType created:(QredoUTCDateTime *)created values:(NSSet *)values
{

    return [[QLFVaultItemMetadata alloc] initWithDataType:dataType created:created values:values];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFVaultItemMetadata *e = (QLFVaultItemMetadata *)element;
        [writer writeConstructorStartWithObjectName:@"VaultItemMetadata"];
            [writer writeFieldStartWithFieldName:@"created"];
                [QredoPrimitiveMarshallers utcDateTimeMarshaller]([e created], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"dataType"];
                [QredoPrimitiveMarshallers stringMarshaller]([e dataType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"values"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFIndexable marshaller]]([e values], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'VaultItemMetadata'
            [reader readFieldStart]; // TODO assert that field name is 'created'
                QredoUTCDateTime *created = (QredoUTCDateTime *)[QredoPrimitiveMarshallers utcDateTimeUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'dataType'
                NSString *dataType = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'values'
                NSSet *values = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFIndexable unmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFVaultItemMetadata vaultItemMetadataWithDataType:dataType created:created values:values];
    };
}

- (instancetype)initWithDataType:(NSString *)dataType created:(QredoUTCDateTime *)created values:(NSSet *)values
{

    self = [super init];
    if (self) {
        _dataType = dataType;
        _created = created;
        _values = values;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFVaultItemMetadata *)other
{

    QREDO_COMPARE_OBJECT(dataType);
    QREDO_COMPARE_OBJECT(created);
    QREDO_COMPARE_OBJECT(values);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToVaultItemMetadata:other];
       
}

- (BOOL)isEqualToVaultItemMetadata:(QLFVaultItemMetadata *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_dataType != other.dataType && ![_dataType isEqual:other.dataType])
        return NO;
    if (_created != other.created && ![_created isEqual:other.created])
        return NO;
    if (_values != other.values && ![_values isEqual:other.values])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_dataType hash];
    hash = hash * 31u + [_created hash];
    hash = hash * 31u + [_values hash];
    return hash;
       
}

@end

@implementation QLFVaultKeyPair



+ (QLFVaultKeyPair *)vaultKeyPairWithEncryptionKey:(QLFEncryptionKey256 *)encryptionKey authenticationKey:(QLFAuthenticationKey256 *)authenticationKey
{

    return [[QLFVaultKeyPair alloc] initWithEncryptionKey:encryptionKey authenticationKey:authenticationKey];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFVaultKeyPair *e = (QLFVaultKeyPair *)element;
        [writer writeConstructorStartWithObjectName:@"VaultKeyPair"];
            [writer writeFieldStartWithFieldName:@"authenticationKey"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e authenticationKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptionKey"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e encryptionKey], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'VaultKeyPair'
            [reader readFieldStart]; // TODO assert that field name is 'authenticationKey'
                QLFAuthenticationKey256 *authenticationKey = (QLFAuthenticationKey256 *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptionKey'
                QLFEncryptionKey256 *encryptionKey = (QLFEncryptionKey256 *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFVaultKeyPair vaultKeyPairWithEncryptionKey:encryptionKey authenticationKey:authenticationKey];
    };
}

- (instancetype)initWithEncryptionKey:(QLFEncryptionKey256 *)encryptionKey authenticationKey:(QLFAuthenticationKey256 *)authenticationKey
{

    self = [super init];
    if (self) {
        _encryptionKey = encryptionKey;
        _authenticationKey = authenticationKey;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFVaultKeyPair *)other
{

    QREDO_COMPARE_OBJECT(encryptionKey);
    QREDO_COMPARE_OBJECT(authenticationKey);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToVaultKeyPair:other];
       
}

- (BOOL)isEqualToVaultKeyPair:(QLFVaultKeyPair *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_encryptionKey != other.encryptionKey && ![_encryptionKey isEqual:other.encryptionKey])
        return NO;
    if (_authenticationKey != other.authenticationKey && ![_authenticationKey isEqual:other.authenticationKey])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_encryptionKey hash];
    hash = hash * 31u + [_authenticationKey hash];
    return hash;
       
}

@end

@implementation QLFAccessLevelVaultKeys



+ (QLFAccessLevelVaultKeys *)accessLevelVaultKeysWithMaxAccessLevel:(int32_t)maxAccessLevel vaultKeys:(NSArray *)vaultKeys
{

    return [[QLFAccessLevelVaultKeys alloc] initWithMaxAccessLevel:maxAccessLevel vaultKeys:vaultKeys];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFAccessLevelVaultKeys *e = (QLFAccessLevelVaultKeys *)element;
        [writer writeConstructorStartWithObjectName:@"AccessLevelVaultKeys"];
            [writer writeFieldStartWithFieldName:@"maxAccessLevel"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e maxAccessLevel]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"vaultKeys"];
                [QredoPrimitiveMarshallers sequenceMarshallerWithElementMarshaller:[QLFVaultKeyPair marshaller]]([e vaultKeys], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'AccessLevelVaultKeys'
            [reader readFieldStart]; // TODO assert that field name is 'maxAccessLevel'
                int32_t maxAccessLevel = (int32_t )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'vaultKeys'
                NSArray *vaultKeys = (NSArray *)[QredoPrimitiveMarshallers sequenceUnmarshallerWithElementUnmarshaller:[QLFVaultKeyPair unmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFAccessLevelVaultKeys accessLevelVaultKeysWithMaxAccessLevel:maxAccessLevel vaultKeys:vaultKeys];
    };
}

- (instancetype)initWithMaxAccessLevel:(int32_t)maxAccessLevel vaultKeys:(NSArray *)vaultKeys
{

    self = [super init];
    if (self) {
        _maxAccessLevel = maxAccessLevel;
        _vaultKeys = vaultKeys;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFAccessLevelVaultKeys *)other
{

    QREDO_COMPARE_SCALAR(maxAccessLevel);
    QREDO_COMPARE_OBJECT(vaultKeys);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToAccessLevelVaultKeys:other];
       
}

- (BOOL)isEqualToAccessLevelVaultKeys:(QLFAccessLevelVaultKeys *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_maxAccessLevel != other.maxAccessLevel)
        return NO;
    if (_vaultKeys != other.vaultKeys && ![_vaultKeys isEqual:other.vaultKeys])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + (NSUInteger)_maxAccessLevel;
    hash = hash * 31u + [_vaultKeys hash];
    return hash;
       
}

@end

@implementation QLFVaultKeyStore



+ (QLFVaultKeyStore *)vaultKeyStoreWithAccessLevel:(int32_t)accessLevel credentialType:(int32_t)credentialType encryptedVaultKeys:(NSData *)encryptedVaultKeys
{

    return [[QLFVaultKeyStore alloc] initWithAccessLevel:accessLevel credentialType:credentialType encryptedVaultKeys:encryptedVaultKeys];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFVaultKeyStore *e = (QLFVaultKeyStore *)element;
        [writer writeConstructorStartWithObjectName:@"VaultKeyStore"];
            [writer writeFieldStartWithFieldName:@"accessLevel"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e accessLevel]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"credentialType"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e credentialType]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptedVaultKeys"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e encryptedVaultKeys], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'VaultKeyStore'
            [reader readFieldStart]; // TODO assert that field name is 'accessLevel'
                int32_t accessLevel = (int32_t )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'credentialType'
                int32_t credentialType = (int32_t )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptedVaultKeys'
                NSData *encryptedVaultKeys = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFVaultKeyStore vaultKeyStoreWithAccessLevel:accessLevel credentialType:credentialType encryptedVaultKeys:encryptedVaultKeys];
    };
}

- (instancetype)initWithAccessLevel:(int32_t)accessLevel credentialType:(int32_t)credentialType encryptedVaultKeys:(NSData *)encryptedVaultKeys
{

    self = [super init];
    if (self) {
        _accessLevel = accessLevel;
        _credentialType = credentialType;
        _encryptedVaultKeys = encryptedVaultKeys;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFVaultKeyStore *)other
{

    QREDO_COMPARE_SCALAR(accessLevel);
    QREDO_COMPARE_SCALAR(credentialType);
    QREDO_COMPARE_OBJECT(encryptedVaultKeys);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToVaultKeyStore:other];
       
}

- (BOOL)isEqualToVaultKeyStore:(QLFVaultKeyStore *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_accessLevel != other.accessLevel)
        return NO;
    if (_credentialType != other.credentialType)
        return NO;
    if (_encryptedVaultKeys != other.encryptedVaultKeys && ![_encryptedVaultKeys isEqual:other.encryptedVaultKeys])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + (NSUInteger)_accessLevel;
    hash = hash * 31u + (NSUInteger)_credentialType;
    hash = hash * 31u + [_encryptedVaultKeys hash];
    return hash;
       
}

@end

@implementation QLFVaultInfoType



+ (QLFVaultInfoType *)vaultInfoTypeWithVaultID:(QLFVaultId *)vaultID ownershipPrivateKey:(QLFVaultOwnershipPrivateKey *)ownershipPrivateKey keyStore:(NSSet *)keyStore
{

    return [[QLFVaultInfoType alloc] initWithVaultID:vaultID ownershipPrivateKey:ownershipPrivateKey keyStore:keyStore];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFVaultInfoType *e = (QLFVaultInfoType *)element;
        [writer writeConstructorStartWithObjectName:@"VaultInfoType"];
            [writer writeFieldStartWithFieldName:@"keyStore"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFVaultKeyStore marshaller]]([e keyStore], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"ownershipPrivateKey"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e ownershipPrivateKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"vaultID"];
                [QredoPrimitiveMarshallers quidMarshaller]([e vaultID], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'VaultInfoType'
            [reader readFieldStart]; // TODO assert that field name is 'keyStore'
                NSSet *keyStore = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFVaultKeyStore unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'ownershipPrivateKey'
                QLFVaultOwnershipPrivateKey *ownershipPrivateKey = (QLFVaultOwnershipPrivateKey *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'vaultID'
                QLFVaultId *vaultID = (QLFVaultId *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFVaultInfoType vaultInfoTypeWithVaultID:vaultID ownershipPrivateKey:ownershipPrivateKey keyStore:keyStore];
    };
}

- (instancetype)initWithVaultID:(QLFVaultId *)vaultID ownershipPrivateKey:(QLFVaultOwnershipPrivateKey *)ownershipPrivateKey keyStore:(NSSet *)keyStore
{

    self = [super init];
    if (self) {
        _vaultID = vaultID;
        _ownershipPrivateKey = ownershipPrivateKey;
        _keyStore = keyStore;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFVaultInfoType *)other
{

    QREDO_COMPARE_OBJECT(vaultID);
    QREDO_COMPARE_OBJECT(ownershipPrivateKey);
    QREDO_COMPARE_OBJECT(keyStore);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToVaultInfoType:other];
       
}

- (BOOL)isEqualToVaultInfoType:(QLFVaultInfoType *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_vaultID != other.vaultID && ![_vaultID isEqual:other.vaultID])
        return NO;
    if (_ownershipPrivateKey != other.ownershipPrivateKey && ![_ownershipPrivateKey isEqual:other.ownershipPrivateKey])
        return NO;
    if (_keyStore != other.keyStore && ![_keyStore isEqual:other.keyStore])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_vaultID hash];
    hash = hash * 31u + [_ownershipPrivateKey hash];
    hash = hash * 31u + [_keyStore hash];
    return hash;
       
}

@end

@implementation QLFKeychain



+ (QLFKeychain *)keychainWithCredentialType:(int32_t)credentialType operatorInfo:(QLFOperatorInfo *)operatorInfo vaultInfo:(QLFVaultInfoType *)vaultInfo encryptedRecoveryInfo:(QLFEncryptedRecoveryInfoType *)encryptedRecoveryInfo
{

    return [[QLFKeychain alloc] initWithCredentialType:credentialType operatorInfo:operatorInfo vaultInfo:vaultInfo encryptedRecoveryInfo:encryptedRecoveryInfo];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFKeychain *e = (QLFKeychain *)element;
        [writer writeConstructorStartWithObjectName:@"Keychain"];
            [writer writeFieldStartWithFieldName:@"credentialType"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e credentialType]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptedRecoveryInfo"];
                [QLFEncryptedRecoveryInfoType marshaller]([e encryptedRecoveryInfo], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"operatorInfo"];
                [QLFOperatorInfo marshaller]([e operatorInfo], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"vaultInfo"];
                [QLFVaultInfoType marshaller]([e vaultInfo], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'Keychain'
            [reader readFieldStart]; // TODO assert that field name is 'credentialType'
                int32_t credentialType = (int32_t )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptedRecoveryInfo'
                QLFEncryptedRecoveryInfoType *encryptedRecoveryInfo = (QLFEncryptedRecoveryInfoType *)[QLFEncryptedRecoveryInfoType unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'operatorInfo'
                QLFOperatorInfo *operatorInfo = (QLFOperatorInfo *)[QLFOperatorInfo unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'vaultInfo'
                QLFVaultInfoType *vaultInfo = (QLFVaultInfoType *)[QLFVaultInfoType unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFKeychain keychainWithCredentialType:credentialType operatorInfo:operatorInfo vaultInfo:vaultInfo encryptedRecoveryInfo:encryptedRecoveryInfo];
    };
}

- (instancetype)initWithCredentialType:(int32_t)credentialType operatorInfo:(QLFOperatorInfo *)operatorInfo vaultInfo:(QLFVaultInfoType *)vaultInfo encryptedRecoveryInfo:(QLFEncryptedRecoveryInfoType *)encryptedRecoveryInfo
{

    self = [super init];
    if (self) {
        _credentialType = credentialType;
        _operatorInfo = operatorInfo;
        _vaultInfo = vaultInfo;
        _encryptedRecoveryInfo = encryptedRecoveryInfo;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFKeychain *)other
{

    QREDO_COMPARE_SCALAR(credentialType);
    QREDO_COMPARE_OBJECT(operatorInfo);
    QREDO_COMPARE_OBJECT(vaultInfo);
    QREDO_COMPARE_OBJECT(encryptedRecoveryInfo);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToKeychain:other];
       
}

- (BOOL)isEqualToKeychain:(QLFKeychain *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_credentialType != other.credentialType)
        return NO;
    if (_operatorInfo != other.operatorInfo && ![_operatorInfo isEqual:other.operatorInfo])
        return NO;
    if (_vaultInfo != other.vaultInfo && ![_vaultInfo isEqual:other.vaultInfo])
        return NO;
    if (_encryptedRecoveryInfo != other.encryptedRecoveryInfo && ![_encryptedRecoveryInfo isEqual:other.encryptedRecoveryInfo])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + (NSUInteger)_credentialType;
    hash = hash * 31u + [_operatorInfo hash];
    hash = hash * 31u + [_vaultInfo hash];
    hash = hash * 31u + [_encryptedRecoveryInfo hash];
    return hash;
       
}

@end

@implementation QLFVaultItemRef



+ (QLFVaultItemRef *)vaultItemRefWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QLFVaultItemId *)itemId
{

    return [[QLFVaultItemRef alloc] initWithVaultId:vaultId sequenceId:sequenceId sequenceValue:sequenceValue itemId:itemId];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFVaultItemRef *e = (QLFVaultItemRef *)element;
        [writer writeConstructorStartWithObjectName:@"VaultItemRef"];
            [writer writeFieldStartWithFieldName:@"itemId"];
                [QredoPrimitiveMarshallers quidMarshaller]([e itemId], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"sequenceId"];
                [QredoPrimitiveMarshallers quidMarshaller]([e sequenceId], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"sequenceValue"];
                [QredoPrimitiveMarshallers int64Marshaller]([NSNumber numberWithLongLong: [e sequenceValue]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"vaultId"];
                [QredoPrimitiveMarshallers quidMarshaller]([e vaultId], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'VaultItemRef'
            [reader readFieldStart]; // TODO assert that field name is 'itemId'
                QLFVaultItemId *itemId = (QLFVaultItemId *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sequenceId'
                QLFVaultSequenceId *sequenceId = (QLFVaultSequenceId *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sequenceValue'
                QLFVaultSequenceValue sequenceValue = (QLFVaultSequenceValue )[[QredoPrimitiveMarshallers int64Unmarshaller](reader) longLongValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'vaultId'
                QLFVaultId *vaultId = (QLFVaultId *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFVaultItemRef vaultItemRefWithVaultId:vaultId sequenceId:sequenceId sequenceValue:sequenceValue itemId:itemId];
    };
}

- (instancetype)initWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QLFVaultItemId *)itemId
{

    self = [super init];
    if (self) {
        _vaultId = vaultId;
        _sequenceId = sequenceId;
        _sequenceValue = sequenceValue;
        _itemId = itemId;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFVaultItemRef *)other
{

    QREDO_COMPARE_OBJECT(vaultId);
    QREDO_COMPARE_OBJECT(sequenceId);
    QREDO_COMPARE_SCALAR(sequenceValue);
    QREDO_COMPARE_OBJECT(itemId);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToVaultItemRef:other];
       
}

- (BOOL)isEqualToVaultItemRef:(QLFVaultItemRef *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_vaultId != other.vaultId && ![_vaultId isEqual:other.vaultId])
        return NO;
    if (_sequenceId != other.sequenceId && ![_sequenceId isEqual:other.sequenceId])
        return NO;
    if (_sequenceValue != other.sequenceValue)
        return NO;
    if (_itemId != other.itemId && ![_itemId isEqual:other.itemId])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_vaultId hash];
    hash = hash * 31u + [_sequenceId hash];
    hash = hash * 31u + (NSUInteger)_sequenceValue;
    hash = hash * 31u + [_itemId hash];
    return hash;
       
}

@end

@implementation QLFEncryptedVaultItemHeader



+ (QLFEncryptedVaultItemHeader *)encryptedVaultItemHeaderWithRef:(QLFVaultItemRef *)ref encryptedMetadata:(NSData *)encryptedMetadata authCode:(QLFAuthCode *)authCode
{

    return [[QLFEncryptedVaultItemHeader alloc] initWithRef:ref encryptedMetadata:encryptedMetadata authCode:authCode];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFEncryptedVaultItemHeader *e = (QLFEncryptedVaultItemHeader *)element;
        [writer writeConstructorStartWithObjectName:@"EncryptedVaultItemHeader"];
            [writer writeFieldStartWithFieldName:@"authCode"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e authCode], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptedMetadata"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e encryptedMetadata], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"ref"];
                [QLFVaultItemRef marshaller]([e ref], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'EncryptedVaultItemHeader'
            [reader readFieldStart]; // TODO assert that field name is 'authCode'
                QLFAuthCode *authCode = (QLFAuthCode *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptedMetadata'
                NSData *encryptedMetadata = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'ref'
                QLFVaultItemRef *ref = (QLFVaultItemRef *)[QLFVaultItemRef unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFEncryptedVaultItemHeader encryptedVaultItemHeaderWithRef:ref encryptedMetadata:encryptedMetadata authCode:authCode];
    };
}

- (instancetype)initWithRef:(QLFVaultItemRef *)ref encryptedMetadata:(NSData *)encryptedMetadata authCode:(QLFAuthCode *)authCode
{

    self = [super init];
    if (self) {
        _ref = ref;
        _encryptedMetadata = encryptedMetadata;
        _authCode = authCode;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFEncryptedVaultItemHeader *)other
{

    QREDO_COMPARE_OBJECT(ref);
    QREDO_COMPARE_OBJECT(encryptedMetadata);
    QREDO_COMPARE_OBJECT(authCode);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToEncryptedVaultItemHeader:other];
       
}

- (BOOL)isEqualToEncryptedVaultItemHeader:(QLFEncryptedVaultItemHeader *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_ref != other.ref && ![_ref isEqual:other.ref])
        return NO;
    if (_encryptedMetadata != other.encryptedMetadata && ![_encryptedMetadata isEqual:other.encryptedMetadata])
        return NO;
    if (_authCode != other.authCode && ![_authCode isEqual:other.authCode])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_ref hash];
    hash = hash * 31u + [_encryptedMetadata hash];
    hash = hash * 31u + [_authCode hash];
    return hash;
       
}

@end

@implementation QLFEncryptedVaultItem



+ (QLFEncryptedVaultItem *)encryptedVaultItemWithHeader:(QLFEncryptedVaultItemHeader *)header encryptedBody:(NSData *)encryptedBody authCode:(QLFAuthCode *)authCode
{

    return [[QLFEncryptedVaultItem alloc] initWithHeader:header encryptedBody:encryptedBody authCode:authCode];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFEncryptedVaultItem *e = (QLFEncryptedVaultItem *)element;
        [writer writeConstructorStartWithObjectName:@"EncryptedVaultItem"];
            [writer writeFieldStartWithFieldName:@"authCode"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e authCode], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptedBody"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e encryptedBody], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"header"];
                [QLFEncryptedVaultItemHeader marshaller]([e header], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'EncryptedVaultItem'
            [reader readFieldStart]; // TODO assert that field name is 'authCode'
                QLFAuthCode *authCode = (QLFAuthCode *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptedBody'
                NSData *encryptedBody = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'header'
                QLFEncryptedVaultItemHeader *header = (QLFEncryptedVaultItemHeader *)[QLFEncryptedVaultItemHeader unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFEncryptedVaultItem encryptedVaultItemWithHeader:header encryptedBody:encryptedBody authCode:authCode];
    };
}

- (instancetype)initWithHeader:(QLFEncryptedVaultItemHeader *)header encryptedBody:(NSData *)encryptedBody authCode:(QLFAuthCode *)authCode
{

    self = [super init];
    if (self) {
        _header = header;
        _encryptedBody = encryptedBody;
        _authCode = authCode;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFEncryptedVaultItem *)other
{

    QREDO_COMPARE_OBJECT(header);
    QREDO_COMPARE_OBJECT(encryptedBody);
    QREDO_COMPARE_OBJECT(authCode);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToEncryptedVaultItem:other];
       
}

- (BOOL)isEqualToEncryptedVaultItem:(QLFEncryptedVaultItem *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_header != other.header && ![_header isEqual:other.header])
        return NO;
    if (_encryptedBody != other.encryptedBody && ![_encryptedBody isEqual:other.encryptedBody])
        return NO;
    if (_authCode != other.authCode && ![_authCode isEqual:other.authCode])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_header hash];
    hash = hash * 31u + [_encryptedBody hash];
    hash = hash * 31u + [_authCode hash];
    return hash;
       
}

@end

@implementation QLFVaultItem



+ (QLFVaultItem *)vaultItemWithRef:(QLFVaultItemRef *)ref metadata:(QLFVaultItemMetadata *)metadata body:(NSData *)body
{

    return [[QLFVaultItem alloc] initWithRef:ref metadata:metadata body:body];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFVaultItem *e = (QLFVaultItem *)element;
        [writer writeConstructorStartWithObjectName:@"VaultItem"];
            [writer writeFieldStartWithFieldName:@"body"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e body], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"metadata"];
                [QLFVaultItemMetadata marshaller]([e metadata], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"ref"];
                [QLFVaultItemRef marshaller]([e ref], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'VaultItem'
            [reader readFieldStart]; // TODO assert that field name is 'body'
                NSData *body = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'metadata'
                QLFVaultItemMetadata *metadata = (QLFVaultItemMetadata *)[QLFVaultItemMetadata unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'ref'
                QLFVaultItemRef *ref = (QLFVaultItemRef *)[QLFVaultItemRef unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFVaultItem vaultItemWithRef:ref metadata:metadata body:body];
    };
}

- (instancetype)initWithRef:(QLFVaultItemRef *)ref metadata:(QLFVaultItemMetadata *)metadata body:(NSData *)body
{

    self = [super init];
    if (self) {
        _ref = ref;
        _metadata = metadata;
        _body = body;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFVaultItem *)other
{

    QREDO_COMPARE_OBJECT(ref);
    QREDO_COMPARE_OBJECT(metadata);
    QREDO_COMPARE_OBJECT(body);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToVaultItem:other];
       
}

- (BOOL)isEqualToVaultItem:(QLFVaultItem *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_ref != other.ref && ![_ref isEqual:other.ref])
        return NO;
    if (_metadata != other.metadata && ![_metadata isEqual:other.metadata])
        return NO;
    if (_body != other.body && ![_body isEqual:other.body])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_ref hash];
    hash = hash * 31u + [_metadata hash];
    hash = hash * 31u + [_body hash];
    return hash;
       
}

@end

@implementation QLFVaultItemQueryResults



+ (QLFVaultItemQueryResults *)vaultItemQueryResultsWithResults:(NSArray *)results current:(BOOL)current sequenceIds:(NSSet *)sequenceIds
{

    return [[QLFVaultItemQueryResults alloc] initWithResults:results current:current sequenceIds:sequenceIds];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFVaultItemQueryResults *e = (QLFVaultItemQueryResults *)element;
        [writer writeConstructorStartWithObjectName:@"VaultItemQueryResults"];
            [writer writeFieldStartWithFieldName:@"current"];
                [QredoPrimitiveMarshallers booleanMarshaller]([NSNumber numberWithBool: [e current]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"results"];
                [QredoPrimitiveMarshallers sequenceMarshallerWithElementMarshaller:[QLFEncryptedVaultItemHeader marshaller]]([e results], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"sequenceIds"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers quidMarshaller]]([e sequenceIds], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'VaultItemQueryResults'
            [reader readFieldStart]; // TODO assert that field name is 'current'
                BOOL current = (BOOL )[[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'results'
                NSArray *results = (NSArray *)[QredoPrimitiveMarshallers sequenceUnmarshallerWithElementUnmarshaller:[QLFEncryptedVaultItemHeader unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sequenceIds'
                NSSet *sequenceIds = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers quidUnmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFVaultItemQueryResults vaultItemQueryResultsWithResults:results current:current sequenceIds:sequenceIds];
    };
}

- (instancetype)initWithResults:(NSArray *)results current:(BOOL)current sequenceIds:(NSSet *)sequenceIds
{

    self = [super init];
    if (self) {
        _results = results;
        _current = current;
        _sequenceIds = sequenceIds;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFVaultItemQueryResults *)other
{

    QREDO_COMPARE_OBJECT(results);
    QREDO_COMPARE_SCALAR(current);
    QREDO_COMPARE_OBJECT(sequenceIds);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToVaultItemQueryResults:other];
       
}

- (BOOL)isEqualToVaultItemQueryResults:(QLFVaultItemQueryResults *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_results != other.results && ![_results isEqual:other.results])
        return NO;
    if (_current != other.current)
        return NO;
    if (_sequenceIds != other.sequenceIds && ![_sequenceIds isEqual:other.sequenceIds])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_results hash];
    hash = hash * 31u + (NSUInteger)_current;
    hash = hash * 31u + [_sequenceIds hash];
    return hash;
       
}

@end

@implementation QLFVaultSequenceState



+ (QLFVaultSequenceState *)vaultSequenceStateWithSequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue
{

    return [[QLFVaultSequenceState alloc] initWithSequenceId:sequenceId sequenceValue:sequenceValue];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFVaultSequenceState *e = (QLFVaultSequenceState *)element;
        [writer writeConstructorStartWithObjectName:@"VaultSequenceState"];
            [writer writeFieldStartWithFieldName:@"sequenceId"];
                [QredoPrimitiveMarshallers quidMarshaller]([e sequenceId], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"sequenceValue"];
                [QredoPrimitiveMarshallers int64Marshaller]([NSNumber numberWithLongLong: [e sequenceValue]], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'VaultSequenceState'
            [reader readFieldStart]; // TODO assert that field name is 'sequenceId'
                QLFVaultSequenceId *sequenceId = (QLFVaultSequenceId *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sequenceValue'
                QLFVaultSequenceValue sequenceValue = (QLFVaultSequenceValue )[[QredoPrimitiveMarshallers int64Unmarshaller](reader) longLongValue];
            [reader readEnd];
        [reader readEnd];
        return [QLFVaultSequenceState vaultSequenceStateWithSequenceId:sequenceId sequenceValue:sequenceValue];
    };
}

- (instancetype)initWithSequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue
{

    self = [super init];
    if (self) {
        _sequenceId = sequenceId;
        _sequenceValue = sequenceValue;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFVaultSequenceState *)other
{

    QREDO_COMPARE_OBJECT(sequenceId);
    QREDO_COMPARE_SCALAR(sequenceValue);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToVaultSequenceState:other];
       
}

- (BOOL)isEqualToVaultSequenceState:(QLFVaultSequenceState *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_sequenceId != other.sequenceId && ![_sequenceId isEqual:other.sequenceId])
        return NO;
    if (_sequenceValue != other.sequenceValue)
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_sequenceId hash];
    hash = hash * 31u + (NSUInteger)_sequenceValue;
    return hash;
       
}

@end

@implementation QLFConversations

{
QredoServiceInvoker *_invoker;
}

+ (QLFConversations *)conversationsWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker
{

    return [[self alloc] initWithServiceInvoker:serviceInvoker];
       
}

- (instancetype)initWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker
{

    self = [super init];
    if (self) {
        _invoker    = serviceInvoker;
    }
    return self;
       
}

- (void)publishWithQueueId:(QLFConversationQueueId *)queueId item:(QLFEncryptedConversationItem *)item signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFConversationPublishResult *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Conversations"
               operation:@"publish"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](queueId, writer);
                  [QLFEncryptedConversationItem marshaller](item, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFConversationPublishResult *result = [QLFConversationPublishResult unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:NO];
         
}

- (void)queryItemsWithQueueId:(QLFConversationQueueId *)queueId after:(NSSet *)after fetchSize:(NSSet *)fetchSize signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFConversationQueryItemsResult *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Conversations"
               operation:@"queryItems"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](queueId, writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]](after, writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int32Marshaller]](fetchSize, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFConversationQueryItemsResult *result = [QLFConversationQueryItemsResult unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:NO];
         
}

- (void)acknowledgeReceiptWithQueueId:(QLFConversationQueueId *)queueId upTo:(QLFConversationSequenceValue *)upTo signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFConversationAckResult *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Conversations"
               operation:@"acknowledgeReceipt"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](queueId, writer);
                  [QredoPrimitiveMarshallers byteSequenceMarshaller](upTo, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFConversationAckResult *result = [QLFConversationAckResult unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:NO];
         
}

- (void)subscribeWithQueueId:(QLFConversationQueueId *)queueId signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFConversationItemWithSequenceValue *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Conversations"
               operation:@"subscribe"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](queueId, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFConversationItemWithSequenceValue *result = [QLFConversationItemWithSequenceValue unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:YES];
         
}

- (void)subscribeAfterWithQueueId:(QLFConversationQueueId *)queueId after:(NSSet *)after fetchSize:(NSSet *)fetchSize signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFConversationItemWithSequenceValue *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Conversations"
               operation:@"subscribeAfter"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](queueId, writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]](after, writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int32Marshaller]](fetchSize, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFConversationItemWithSequenceValue *result = [QLFConversationItemWithSequenceValue unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:YES];
         
}

- (void)subscribeWithPushWithQueueId:(QLFConversationQueueId *)queueId notificationId:(QLFNotificationTarget *)notificationId completionHandler:(void(^)(QLFConversationItemWithSequenceValue *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Conversations"
               operation:@"subscribeWithPush"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](queueId, writer);
                  [QLFNotificationTarget marshaller](notificationId, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFConversationItemWithSequenceValue *result = [QLFConversationItemWithSequenceValue unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:YES];
         
}

@end

@implementation QLFPing

{
QredoServiceInvoker *_invoker;
}

+ (QLFPing *)pingWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker
{

    return [[self alloc] initWithServiceInvoker:serviceInvoker];
       
}

- (instancetype)initWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker
{

    self = [super init];
    if (self) {
        _invoker    = serviceInvoker;
    }
    return self;
       
}

- (void)pingWithCompletionHandler:(void(^)(BOOL result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Ping"
               operation:@"ping"
           requestWriter:^(QredoWireFormatWriter *writer) {

           }
          responseReader:^(QredoWireFormatReader *reader) {
               BOOL result = [[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(NO, error);
            }
           multiResponse:NO];
         
}

@end

@implementation QLFRendezvous

{
QredoServiceInvoker *_invoker;
}

+ (QLFRendezvous *)rendezvousWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker
{

    return [[self alloc] initWithServiceInvoker:serviceInvoker];
       
}

- (instancetype)initWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker
{

    self = [super init];
    if (self) {
        _invoker    = serviceInvoker;
    }
    return self;
       
}

- (void)createWithCreationInfo:(QLFRendezvousCreationInfo *)creationInfo completionHandler:(void(^)(QLFRendezvousCreateResult *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Rendezvous"
               operation:@"create"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QLFRendezvousCreationInfo marshaller](creationInfo, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFRendezvousCreateResult *result = [QLFRendezvousCreateResult unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:NO];
         
}

- (void)activateWithHashedTag:(QLFRendezvousHashedTag *)hashedTag durationSeconds:(QLFRendezvousDurationSeconds *)durationSeconds signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousActivated *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Rendezvous"
               operation:@"activate"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](hashedTag, writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int32Marshaller]](durationSeconds, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFRendezvousActivated *result = [QLFRendezvousActivated unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:NO];
         
}

- (void)getInfoWithHashedTag:(QLFRendezvousHashedTag *)hashedTag signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousInfo *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Rendezvous"
               operation:@"getInfo"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](hashedTag, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFRendezvousInfo *result = [QLFRendezvousInfo unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:NO];
         
}

- (void)respondWithResponse:(QLFRendezvousResponse *)response completionHandler:(void(^)(QLFRendezvousRespondResult *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Rendezvous"
               operation:@"respond"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QLFRendezvousResponse marshaller](response, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFRendezvousRespondResult *result = [QLFRendezvousRespondResult unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:NO];
         
}

- (void)getResponsesWithHashedTag:(QLFRendezvousHashedTag *)hashedTag after:(QLFRendezvousSequenceValue)after signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousResponsesResult *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Rendezvous"
               operation:@"getResponses"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](hashedTag, writer);
                  [QredoPrimitiveMarshallers int64Marshaller]([NSNumber numberWithLongLong: after], writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFRendezvousResponsesResult *result = [QLFRendezvousResponsesResult unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:NO];
         
}

- (void)subscribeToResponsesWithHashedTag:(QLFRendezvousHashedTag *)hashedTag signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousResponseWithSequenceValue *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Rendezvous"
               operation:@"subscribeToResponses"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](hashedTag, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFRendezvousResponseWithSequenceValue *result = [QLFRendezvousResponseWithSequenceValue unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:YES];
         
}

- (void)subscribeToResponsesAfterWithHashedTag:(QLFRendezvousHashedTag *)hashedTag after:(QLFRendezvousSequenceValue)after fetchSize:(NSSet *)fetchSize signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousResponseWithSequenceValue *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Rendezvous"
               operation:@"subscribeToResponsesAfter"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](hashedTag, writer);
                  [QredoPrimitiveMarshallers int64Marshaller]([NSNumber numberWithLongLong: after], writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int32Marshaller]](fetchSize, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFRendezvousResponseWithSequenceValue *result = [QLFRendezvousResponseWithSequenceValue unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:YES];
         
}

- (void)deactivateWithHashedTag:(QLFRendezvousHashedTag *)hashedTag signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousDeactivated *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Rendezvous"
               operation:@"deactivate"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](hashedTag, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFRendezvousDeactivated *result = [QLFRendezvousDeactivated unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:NO];
         
}

@end

@implementation QLFVault

{
QredoServiceInvoker *_invoker;
}

+ (QLFVault *)vaultWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker
{

    return [[self alloc] initWithServiceInvoker:serviceInvoker];
       
}

- (instancetype)initWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker
{

    self = [super init];
    if (self) {
        _invoker    = serviceInvoker;
    }
    return self;
       
}

- (void)putItemWithItem:(QLFEncryptedVaultItem *)item signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(BOOL result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Vault"
               operation:@"putItem"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QLFEncryptedVaultItem marshaller](item, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               BOOL result = [[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(NO, error);
            }
           multiResponse:NO];
         
}

- (void)getItemWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(NSSet *)sequenceValue itemId:(QLFVaultItemId *)itemId signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(NSSet *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Vault"
               operation:@"getItem"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](vaultId, writer);
                  [QredoPrimitiveMarshallers quidMarshaller](sequenceId, writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int64Marshaller]](sequenceValue, writer);
                  [QredoPrimitiveMarshallers quidMarshaller](itemId, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               NSSet *result = [QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFEncryptedVaultItem unmarshaller]](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:NO];
         
}

- (void)getItemHeaderWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(NSSet *)sequenceValue itemId:(QLFVaultItemId *)itemId signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(NSSet *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Vault"
               operation:@"getItemHeader"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](vaultId, writer);
                  [QredoPrimitiveMarshallers quidMarshaller](sequenceId, writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int64Marshaller]](sequenceValue, writer);
                  [QredoPrimitiveMarshallers quidMarshaller](itemId, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               NSSet *result = [QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFEncryptedVaultItemHeader unmarshaller]](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:NO];
         
}

- (void)queryItemHeadersWithVaultId:(QLFVaultId *)vaultId sequenceStates:(NSSet *)sequenceStates signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFVaultItemQueryResults *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Vault"
               operation:@"queryItemHeaders"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](vaultId, writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFVaultSequenceState marshaller]](sequenceStates, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFVaultItemQueryResults *result = [QLFVaultItemQueryResults unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:NO];
         
}

- (void)subscribeToItemHeadersWithVaultId:(QLFVaultId *)vaultId signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFEncryptedVaultItemHeader *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Vault"
               operation:@"subscribeToItemHeaders"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](vaultId, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFEncryptedVaultItemHeader *result = [QLFEncryptedVaultItemHeader unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:YES];
         
}

- (void)subscribeToItemHeadersAfterWithVaultId:(QLFVaultId *)vaultId sequenceStates:(NSSet *)sequenceStates fetchSize:(NSSet *)fetchSize signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFEncryptedVaultItemHeader *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Vault"
               operation:@"subscribeToItemHeadersAfter"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](vaultId, writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFVaultSequenceState marshaller]](sequenceStates, writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int32Marshaller]](fetchSize, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFEncryptedVaultItemHeader *result = [QLFEncryptedVaultItemHeader unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }
           multiResponse:YES];
         
}

@end

#pragma clang diagnostic pop
