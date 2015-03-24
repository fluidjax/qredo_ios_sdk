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

@implementation QLFConversationItemWithSequenceValue



+ (QLFConversationItemWithSequenceValue *)conversationItemWithSequenceValueWithItem:(QLFConversationItem *)item sequenceValue:(QLFConversationSequenceValue *)sequenceValue
{

    return [[QLFConversationItemWithSequenceValue alloc] initWithItem:item sequenceValue:sequenceValue];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFConversationItemWithSequenceValue *e = (QLFConversationItemWithSequenceValue *)element;
        [writer writeConstructorStartWithObjectName:@"ConversationItemWithSequenceValue"];
            [writer writeFieldStartWithFieldName:@"item"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e item], writer);
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
                QLFConversationItem *item = (QLFConversationItem *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sequenceValue'
                QLFConversationSequenceValue *sequenceValue = (QLFConversationSequenceValue *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFConversationItemWithSequenceValue conversationItemWithSequenceValueWithItem:item sequenceValue:sequenceValue];
    };
}

- (instancetype)initWithItem:(QLFConversationItem *)item sequenceValue:(QLFConversationSequenceValue *)sequenceValue
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
    hash = hash * 31u + _current;
    return hash;
       
}

@end

@implementation QLFCredentialValidationResult



+ (QLFCredentialValidationResult *)credentialValidity
{

    return [[QLFCredentialValidity alloc] init];
       
}

+ (QLFCredentialValidationResult *)certificateChainRevoked
{

    return [[QLFCertificateChainRevoked alloc] init];
       
}

+ (QLFCredentialValidationResult *)credentialRevoked
{

    return [[QLFCredentialRevoked alloc] init];
       
}

+ (QLFCredentialValidationResult *)credentialExpired
{

    return [[QLFCredentialExpired alloc] init];
       
}

+ (QLFCredentialValidationResult *)credentialNotValid
{

    return [[QLFCredentialNotValid alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFCredentialValidity class]]) {
            [QLFCredentialValidity marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFCertificateChainRevoked class]]) {
            [QLFCertificateChainRevoked marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFCredentialRevoked class]]) {
            [QLFCredentialRevoked marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFCredentialExpired class]]) {
            [QLFCredentialExpired marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFCredentialNotValid class]]) {
            [QLFCredentialNotValid marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"CredentialValidity"]) {
            QLFCredentialValidationResult *_temp = [QLFCredentialValidity unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"CertificateChainRevoked"]) {
            QLFCredentialValidationResult *_temp = [QLFCertificateChainRevoked unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"CredentialRevoked"]) {
            QLFCredentialValidationResult *_temp = [QLFCredentialRevoked unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"CredentialExpired"]) {
            QLFCredentialValidationResult *_temp = [QLFCredentialExpired unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"CredentialNotValid"]) {
            QLFCredentialValidationResult *_temp = [QLFCredentialNotValid unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifCredentialValidity:(void (^)())ifCredentialValidityBlock ifCertificateChainRevoked:(void (^)())ifCertificateChainRevokedBlock ifCredentialRevoked:(void (^)())ifCredentialRevokedBlock ifCredentialExpired:(void (^)())ifCredentialExpiredBlock ifCredentialNotValid:(void (^)())ifCredentialNotValidBlock
{
    if ([self isKindOfClass:[QLFCredentialValidity class]]) {
        ifCredentialValidityBlock();
    } else if ([self isKindOfClass:[QLFCertificateChainRevoked class]]) {
        ifCertificateChainRevokedBlock();
    } else if ([self isKindOfClass:[QLFCredentialRevoked class]]) {
        ifCredentialRevokedBlock();
    } else if ([self isKindOfClass:[QLFCredentialExpired class]]) {
        ifCredentialExpiredBlock();
    } else if ([self isKindOfClass:[QLFCredentialNotValid class]]) {
        ifCredentialNotValidBlock();
    }
}

- (NSComparisonResult)compare:(QLFCredentialValidationResult *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToCredentialValidationResult:(QLFCredentialValidationResult *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFCredentialValidity



+ (QLFCredentialValidationResult *)credentialValidity
{

    return [[QLFCredentialValidity alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFCredentialValidity *e = (QLFCredentialValidity *)element;
        [writer writeConstructorStartWithObjectName:@"CredentialValidity"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFCredentialValidationResult credentialValidity];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFCredentialValidity *)other
{
    if ([other isKindOfClass:[QLFCredentialValidationResult class]] && ![other isKindOfClass:[QLFCredentialValidity class]]) {
        // N.B. impose an ordering among subtypes of CredentialValidationResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToCredentialValidity:other];
       
}

- (BOOL)isEqualToCredentialValidity:(QLFCredentialValidity *)other
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

@implementation QLFCertificateChainRevoked



+ (QLFCredentialValidationResult *)certificateChainRevoked
{

    return [[QLFCertificateChainRevoked alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFCertificateChainRevoked *e = (QLFCertificateChainRevoked *)element;
        [writer writeConstructorStartWithObjectName:@"CertificateChainRevoked"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFCredentialValidationResult certificateChainRevoked];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFCertificateChainRevoked *)other
{
    if ([other isKindOfClass:[QLFCredentialValidationResult class]] && ![other isKindOfClass:[QLFCertificateChainRevoked class]]) {
        // N.B. impose an ordering among subtypes of CredentialValidationResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToCertificateChainRevoked:other];
       
}

- (BOOL)isEqualToCertificateChainRevoked:(QLFCertificateChainRevoked *)other
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

@implementation QLFCredentialRevoked



+ (QLFCredentialValidationResult *)credentialRevoked
{

    return [[QLFCredentialRevoked alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFCredentialRevoked *e = (QLFCredentialRevoked *)element;
        [writer writeConstructorStartWithObjectName:@"CredentialRevoked"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFCredentialValidationResult credentialRevoked];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFCredentialRevoked *)other
{
    if ([other isKindOfClass:[QLFCredentialValidationResult class]] && ![other isKindOfClass:[QLFCredentialRevoked class]]) {
        // N.B. impose an ordering among subtypes of CredentialValidationResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToCredentialRevoked:other];
       
}

- (BOOL)isEqualToCredentialRevoked:(QLFCredentialRevoked *)other
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

@implementation QLFCredentialExpired



+ (QLFCredentialValidationResult *)credentialExpired
{

    return [[QLFCredentialExpired alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFCredentialExpired *e = (QLFCredentialExpired *)element;
        [writer writeConstructorStartWithObjectName:@"CredentialExpired"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFCredentialValidationResult credentialExpired];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFCredentialExpired *)other
{
    if ([other isKindOfClass:[QLFCredentialValidationResult class]] && ![other isKindOfClass:[QLFCredentialExpired class]]) {
        // N.B. impose an ordering among subtypes of CredentialValidationResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToCredentialExpired:other];
       
}

- (BOOL)isEqualToCredentialExpired:(QLFCredentialExpired *)other
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

@implementation QLFCredentialNotValid



+ (QLFCredentialValidationResult *)credentialNotValid
{

    return [[QLFCredentialNotValid alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFCredentialNotValid *e = (QLFCredentialNotValid *)element;
        [writer writeConstructorStartWithObjectName:@"CredentialNotValid"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFCredentialValidationResult credentialNotValid];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFCredentialNotValid *)other
{
    if ([other isKindOfClass:[QLFCredentialValidationResult class]] && ![other isKindOfClass:[QLFCredentialNotValid class]]) {
        // N.B. impose an ordering among subtypes of CredentialValidationResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToCredentialNotValid:other];
       
}

- (BOOL)isEqualToCredentialNotValid:(QLFCredentialNotValid *)other
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
    hash = hash * 31u + _credentialType;
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
    hash = hash * 31u + _credentialType;
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

@implementation QLFKeySlot



+ (QLFKeySlot *)keySlotWithSlotNumber:(QLFKeySlotNumber)slotNumber blindingKey:(QLFBlindingKey *)blindingKey nextBlindingKey:(NSSet *)nextBlindingKey
{

    return [[QLFKeySlot alloc] initWithSlotNumber:slotNumber blindingKey:blindingKey nextBlindingKey:nextBlindingKey];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFKeySlot *e = (QLFKeySlot *)element;
        [writer writeConstructorStartWithObjectName:@"KeySlot"];
            [writer writeFieldStartWithFieldName:@"blindingKey"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e blindingKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"nextBlindingKey"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]]([e nextBlindingKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"slotNumber"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e slotNumber]], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'KeySlot'
            [reader readFieldStart]; // TODO assert that field name is 'blindingKey'
                QLFBlindingKey *blindingKey = (QLFBlindingKey *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'nextBlindingKey'
                NSSet *nextBlindingKey = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'slotNumber'
                QLFKeySlotNumber slotNumber = (QLFKeySlotNumber )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
        [reader readEnd];
        return [QLFKeySlot keySlotWithSlotNumber:slotNumber blindingKey:blindingKey nextBlindingKey:nextBlindingKey];
    };
}

- (instancetype)initWithSlotNumber:(QLFKeySlotNumber)slotNumber blindingKey:(QLFBlindingKey *)blindingKey nextBlindingKey:(NSSet *)nextBlindingKey
{

    self = [super init];
    if (self) {
        _slotNumber = slotNumber;
        _blindingKey = blindingKey;
        _nextBlindingKey = nextBlindingKey;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFKeySlot *)other
{

    QREDO_COMPARE_SCALAR(slotNumber);
    QREDO_COMPARE_OBJECT(blindingKey);
    QREDO_COMPARE_OBJECT(nextBlindingKey);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToKeySlot:other];
       
}

- (BOOL)isEqualToKeySlot:(QLFKeySlot *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_slotNumber != other.slotNumber)
        return NO;
    if (_blindingKey != other.blindingKey && ![_blindingKey isEqual:other.blindingKey])
        return NO;
    if (_nextBlindingKey != other.nextBlindingKey && ![_nextBlindingKey isEqual:other.nextBlindingKey])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + _slotNumber;
    hash = hash * 31u + [_blindingKey hash];
    hash = hash * 31u + [_nextBlindingKey hash];
    return hash;
       
}

@end

@implementation QLFGetKeySlotsResponse



+ (QLFGetKeySlotsResponse *)getKeySlotsResponseWithCurrentKeySlotNumber:(QLFKeySlotNumber)currentKeySlotNumber keySlots:(NSSet *)keySlots
{

    return [[QLFGetKeySlotsResponse alloc] initWithCurrentKeySlotNumber:currentKeySlotNumber keySlots:keySlots];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFGetKeySlotsResponse *e = (QLFGetKeySlotsResponse *)element;
        [writer writeConstructorStartWithObjectName:@"GetKeySlotsResponse"];
            [writer writeFieldStartWithFieldName:@"currentKeySlotNumber"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e currentKeySlotNumber]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"keySlots"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFKeySlot marshaller]]([e keySlots], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'GetKeySlotsResponse'
            [reader readFieldStart]; // TODO assert that field name is 'currentKeySlotNumber'
                QLFKeySlotNumber currentKeySlotNumber = (QLFKeySlotNumber )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'keySlots'
                NSSet *keySlots = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFKeySlot unmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFGetKeySlotsResponse getKeySlotsResponseWithCurrentKeySlotNumber:currentKeySlotNumber keySlots:keySlots];
    };
}

- (instancetype)initWithCurrentKeySlotNumber:(QLFKeySlotNumber)currentKeySlotNumber keySlots:(NSSet *)keySlots
{

    self = [super init];
    if (self) {
        _currentKeySlotNumber = currentKeySlotNumber;
        _keySlots = keySlots;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFGetKeySlotsResponse *)other
{

    QREDO_COMPARE_SCALAR(currentKeySlotNumber);
    QREDO_COMPARE_OBJECT(keySlots);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToGetKeySlotsResponse:other];
       
}

- (BOOL)isEqualToGetKeySlotsResponse:(QLFGetKeySlotsResponse *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_currentKeySlotNumber != other.currentKeySlotNumber)
        return NO;
    if (_keySlots != other.keySlots && ![_keySlots isEqual:other.keySlots])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + _currentKeySlotNumber;
    hash = hash * 31u + [_keySlots hash];
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
    hash = hash * 31u + _credentialType;
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

@implementation QLFRendezvousCreateResult



+ (QLFRendezvousCreateResult *)rendezvousCreated
{

    return [[QLFRendezvousCreated alloc] init];
       
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

- (void)ifRendezvousCreated:(void (^)())ifRendezvousCreatedBlock ifRendezvousAlreadyExists:(void (^)())ifRendezvousAlreadyExistsBlock
{
    if ([self isKindOfClass:[QLFRendezvousCreated class]]) {
        ifRendezvousCreatedBlock();
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



+ (QLFRendezvousCreateResult *)rendezvousCreated
{

    return [[QLFRendezvousCreated alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousCreated *e = (QLFRendezvousCreated *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousCreated"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFRendezvousCreateResult rendezvousCreated];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousCreated *)other
{
    if ([other isKindOfClass:[QLFRendezvousCreateResult class]] && ![other isKindOfClass:[QLFRendezvousCreated class]]) {
        // N.B. impose an ordering among subtypes of RendezvousCreateResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
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
    
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    
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

@implementation QLFRendezvousDeleteResult



+ (QLFRendezvousDeleteResult *)rendezvousDeleteSuccessful
{

    return [[QLFRendezvousDeleteSuccessful alloc] init];
       
}

+ (QLFRendezvousDeleteResult *)rendezvousDeleteRejected
{

    return [[QLFRendezvousDeleteRejected alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFRendezvousDeleteSuccessful class]]) {
            [QLFRendezvousDeleteSuccessful marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFRendezvousDeleteRejected class]]) {
            [QLFRendezvousDeleteRejected marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"RendezvousDeleteSuccessful"]) {
            QLFRendezvousDeleteResult *_temp = [QLFRendezvousDeleteSuccessful unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"RendezvousDeleteRejected"]) {
            QLFRendezvousDeleteResult *_temp = [QLFRendezvousDeleteRejected unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifRendezvousDeleteSuccessful:(void (^)())ifRendezvousDeleteSuccessfulBlock ifRendezvousDeleteRejected:(void (^)())ifRendezvousDeleteRejectedBlock
{
    if ([self isKindOfClass:[QLFRendezvousDeleteSuccessful class]]) {
        ifRendezvousDeleteSuccessfulBlock();
    } else if ([self isKindOfClass:[QLFRendezvousDeleteRejected class]]) {
        ifRendezvousDeleteRejectedBlock();
    }
}

- (NSComparisonResult)compare:(QLFRendezvousDeleteResult *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToRendezvousDeleteResult:(QLFRendezvousDeleteResult *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFRendezvousDeleteSuccessful



+ (QLFRendezvousDeleteResult *)rendezvousDeleteSuccessful
{

    return [[QLFRendezvousDeleteSuccessful alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousDeleteSuccessful *e = (QLFRendezvousDeleteSuccessful *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousDeleteSuccessful"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFRendezvousDeleteResult rendezvousDeleteSuccessful];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousDeleteSuccessful *)other
{
    if ([other isKindOfClass:[QLFRendezvousDeleteResult class]] && ![other isKindOfClass:[QLFRendezvousDeleteSuccessful class]]) {
        // N.B. impose an ordering among subtypes of RendezvousDeleteResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousDeleteSuccessful:other];
       
}

- (BOOL)isEqualToRendezvousDeleteSuccessful:(QLFRendezvousDeleteSuccessful *)other
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

@implementation QLFRendezvousDeleteRejected



+ (QLFRendezvousDeleteResult *)rendezvousDeleteRejected
{

    return [[QLFRendezvousDeleteRejected alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousDeleteRejected *e = (QLFRendezvousDeleteRejected *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousDeleteRejected"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFRendezvousDeleteResult rendezvousDeleteRejected];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousDeleteRejected *)other
{
    if ([other isKindOfClass:[QLFRendezvousDeleteResult class]] && ![other isKindOfClass:[QLFRendezvousDeleteRejected class]]) {
        // N.B. impose an ordering among subtypes of RendezvousDeleteResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToRendezvousDeleteRejected:other];
       
}

- (BOOL)isEqualToRendezvousDeleteRejected:(QLFRendezvousDeleteRejected *)other
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



+ (QLFRendezvousCreationInfo *)rendezvousCreationInfoWithHashedTag:(QLFRendezvousHashedTag *)hashedTag authenticationType:(QLFRendezvousAuthType *)authenticationType durationSeconds:(NSSet *)durationSeconds maxResponseCount:(NSSet *)maxResponseCount ownershipPublicKey:(QLFRendezvousOwnershipPublicKey *)ownershipPublicKey encryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo authenticationCode:(QLFAuthenticationCode *)authenticationCode
{

    return [[QLFRendezvousCreationInfo alloc] initWithHashedTag:hashedTag authenticationType:authenticationType durationSeconds:durationSeconds maxResponseCount:maxResponseCount ownershipPublicKey:ownershipPublicKey encryptedResponderInfo:encryptedResponderInfo authenticationCode:authenticationCode];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousCreationInfo *e = (QLFRendezvousCreationInfo *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousCreationInfo"];
            [writer writeFieldStartWithFieldName:@"authenticationCode"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e authenticationCode], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"authenticationType"];
                [QLFRendezvousAuthType marshaller]([e authenticationType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"durationSeconds"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int64Marshaller]]([e durationSeconds], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptedResponderInfo"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e encryptedResponderInfo], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"hashedTag"];
                [QredoPrimitiveMarshallers quidMarshaller]([e hashedTag], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"maxResponseCount"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int64Marshaller]]([e maxResponseCount], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"ownershipPublicKey"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e ownershipPublicKey], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'RendezvousCreationInfo'
            [reader readFieldStart]; // TODO assert that field name is 'authenticationCode'
                QLFAuthenticationCode *authenticationCode = (QLFAuthenticationCode *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'authenticationType'
                QLFRendezvousAuthType *authenticationType = (QLFRendezvousAuthType *)[QLFRendezvousAuthType unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'durationSeconds'
                NSSet *durationSeconds = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers int64Unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptedResponderInfo'
                QLFEncryptedResponderInfo *encryptedResponderInfo = (QLFEncryptedResponderInfo *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'hashedTag'
                QLFRendezvousHashedTag *hashedTag = (QLFRendezvousHashedTag *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'maxResponseCount'
                NSSet *maxResponseCount = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers int64Unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'ownershipPublicKey'
                QLFRendezvousOwnershipPublicKey *ownershipPublicKey = (QLFRendezvousOwnershipPublicKey *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFRendezvousCreationInfo rendezvousCreationInfoWithHashedTag:hashedTag authenticationType:authenticationType durationSeconds:durationSeconds maxResponseCount:maxResponseCount ownershipPublicKey:ownershipPublicKey encryptedResponderInfo:encryptedResponderInfo authenticationCode:authenticationCode];
    };
}

- (instancetype)initWithHashedTag:(QLFRendezvousHashedTag *)hashedTag authenticationType:(QLFRendezvousAuthType *)authenticationType durationSeconds:(NSSet *)durationSeconds maxResponseCount:(NSSet *)maxResponseCount ownershipPublicKey:(QLFRendezvousOwnershipPublicKey *)ownershipPublicKey encryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo authenticationCode:(QLFAuthenticationCode *)authenticationCode
{

    self = [super init];
    if (self) {
        _hashedTag = hashedTag;
        _authenticationType = authenticationType;
        _durationSeconds = durationSeconds;
        _maxResponseCount = maxResponseCount;
        _ownershipPublicKey = ownershipPublicKey;
        _encryptedResponderInfo = encryptedResponderInfo;
        _authenticationCode = authenticationCode;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousCreationInfo *)other
{

    QREDO_COMPARE_OBJECT(hashedTag);
    QREDO_COMPARE_OBJECT(authenticationType);
    QREDO_COMPARE_OBJECT(durationSeconds);
    QREDO_COMPARE_OBJECT(maxResponseCount);
    QREDO_COMPARE_OBJECT(ownershipPublicKey);
    QREDO_COMPARE_OBJECT(encryptedResponderInfo);
    QREDO_COMPARE_OBJECT(authenticationCode);
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
    if (_authenticationType != other.authenticationType && ![_authenticationType isEqual:other.authenticationType])
        return NO;
    if (_durationSeconds != other.durationSeconds && ![_durationSeconds isEqual:other.durationSeconds])
        return NO;
    if (_maxResponseCount != other.maxResponseCount && ![_maxResponseCount isEqual:other.maxResponseCount])
        return NO;
    if (_ownershipPublicKey != other.ownershipPublicKey && ![_ownershipPublicKey isEqual:other.ownershipPublicKey])
        return NO;
    if (_encryptedResponderInfo != other.encryptedResponderInfo && ![_encryptedResponderInfo isEqual:other.encryptedResponderInfo])
        return NO;
    if (_authenticationCode != other.authenticationCode && ![_authenticationCode isEqual:other.authenticationCode])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_hashedTag hash];
    hash = hash * 31u + [_authenticationType hash];
    hash = hash * 31u + [_durationSeconds hash];
    hash = hash * 31u + [_maxResponseCount hash];
    hash = hash * 31u + [_ownershipPublicKey hash];
    hash = hash * 31u + [_encryptedResponderInfo hash];
    hash = hash * 31u + [_authenticationCode hash];
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



+ (QLFRendezvousRespondResult *)rendezvousResponseRegisteredWithEncryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo authenticationCode:(QLFAuthenticationCode *)authenticationCode authenticationType:(QLFRendezvousAuthType *)authenticationType
{

    return [[QLFRendezvousResponseRegistered alloc] initWithEncryptedResponderInfo:encryptedResponderInfo authenticationCode:authenticationCode authenticationType:authenticationType];
       
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

- (void)ifRendezvousResponseRegistered:(void (^)(QLFEncryptedResponderInfo *, QLFAuthenticationCode *, QLFRendezvousAuthType *))ifRendezvousResponseRegisteredBlock ifRendezvousResponseUnknownTag:(void (^)())ifRendezvousResponseUnknownTagBlock ifRendezvousResponseRejected:(void (^)(QLFRendezvousResponseRejectionReason *))ifRendezvousResponseRejectedBlock
{
    if ([self isKindOfClass:[QLFRendezvousResponseRegistered class]]) {
        ifRendezvousResponseRegisteredBlock([((QLFRendezvousResponseRegistered *) self) encryptedResponderInfo], [((QLFRendezvousResponseRegistered *) self) authenticationCode], [((QLFRendezvousResponseRegistered *) self) authenticationType]);
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



+ (QLFRendezvousRespondResult *)rendezvousResponseRegisteredWithEncryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo authenticationCode:(QLFAuthenticationCode *)authenticationCode authenticationType:(QLFRendezvousAuthType *)authenticationType
{

    return [[QLFRendezvousResponseRegistered alloc] initWithEncryptedResponderInfo:encryptedResponderInfo authenticationCode:authenticationCode authenticationType:authenticationType];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousResponseRegistered *e = (QLFRendezvousResponseRegistered *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousResponseRegistered"];
            [writer writeFieldStartWithFieldName:@"authenticationCode"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e authenticationCode], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"authenticationType"];
                [QLFRendezvousAuthType marshaller]([e authenticationType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"encryptedResponderInfo"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e encryptedResponderInfo], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'authenticationCode'
                QLFAuthenticationCode *authenticationCode = (QLFAuthenticationCode *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'authenticationType'
                QLFRendezvousAuthType *authenticationType = (QLFRendezvousAuthType *)[QLFRendezvousAuthType unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'encryptedResponderInfo'
                QLFEncryptedResponderInfo *encryptedResponderInfo = (QLFEncryptedResponderInfo *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        
        return [QLFRendezvousRespondResult rendezvousResponseRegisteredWithEncryptedResponderInfo:encryptedResponderInfo authenticationCode:authenticationCode authenticationType:authenticationType];
    };
}

- (instancetype)initWithEncryptedResponderInfo:(QLFEncryptedResponderInfo *)encryptedResponderInfo authenticationCode:(QLFAuthenticationCode *)authenticationCode authenticationType:(QLFRendezvousAuthType *)authenticationType
{

    self = [super init];
    if (self) {
        _encryptedResponderInfo = encryptedResponderInfo;
        _authenticationCode = authenticationCode;
        _authenticationType = authenticationType;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFRendezvousResponseRegistered *)other
{
    if ([other isKindOfClass:[QLFRendezvousRespondResult class]] && ![other isKindOfClass:[QLFRendezvousResponseRegistered class]]) {
        // N.B. impose an ordering among subtypes of RendezvousRespondResult
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(encryptedResponderInfo);
    QREDO_COMPARE_OBJECT(authenticationCode);
    QREDO_COMPARE_OBJECT(authenticationType);
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
    if (_encryptedResponderInfo != other.encryptedResponderInfo && ![_encryptedResponderInfo isEqual:other.encryptedResponderInfo])
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
    hash = hash * 31u + [_encryptedResponderInfo hash];
    hash = hash * 31u + [_authenticationCode hash];
    hash = hash * 31u + [_authenticationType hash];
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
    hash = hash * 31u + _sequenceValue;
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
    hash = hash * 31u + _sequenceValue;
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
    hash = hash * 31u + _keyId;
    return hash;
       
}

@end

@implementation QLFGetAccessTokenResponse



+ (QLFGetAccessTokenResponse *)accessGrantedWithSignedBlindedToken:(QLFSignedBlindedToken *)signedBlindedToken slotNumber:(QLFKeySlotNumber)slotNumber remainingSecondsUntilTokenExpires:(int64_t)remainingSecondsUntilTokenExpires remainingSecondsUntilNextTokenIsAvailable:(int64_t)remainingSecondsUntilNextTokenIsAvailable
{

    return [[QLFAccessGranted alloc] initWithSignedBlindedToken:signedBlindedToken slotNumber:slotNumber remainingSecondsUntilTokenExpires:remainingSecondsUntilTokenExpires remainingSecondsUntilNextTokenIsAvailable:remainingSecondsUntilNextTokenIsAvailable];
       
}

+ (QLFGetAccessTokenResponse *)accessDenied
{

    return [[QLFAccessDenied alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        if ([element isKindOfClass:[QLFAccessGranted class]]) {
            [QLFAccessGranted marshaller](element, writer);
        } else if ([element isKindOfClass:[QLFAccessDenied class]]) {
            [QLFAccessDenied marshaller](element, writer);
        } else {
            // TODO throw exception instead
        }
    };
         
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        NSString *constructorSymbol = [reader readConstructorStart];
        if ([constructorSymbol isEqualToString:@"AccessGranted"]) {
            QLFGetAccessTokenResponse *_temp = [QLFAccessGranted unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

        if ([constructorSymbol isEqualToString:@"AccessDenied"]) {
            QLFGetAccessTokenResponse *_temp = [QLFAccessDenied unmarshaller](reader);
            [reader readEnd];
            return _temp;
        }

       return nil;// TODO throw exception instead?
    };

}

- (void)ifAccessGranted:(void (^)(QLFSignedBlindedToken *, QLFKeySlotNumber , int64_t , int64_t ))ifAccessGrantedBlock ifAccessDenied:(void (^)())ifAccessDeniedBlock
{
    if ([self isKindOfClass:[QLFAccessGranted class]]) {
        ifAccessGrantedBlock([((QLFAccessGranted *) self) signedBlindedToken], [((QLFAccessGranted *) self) slotNumber], [((QLFAccessGranted *) self) remainingSecondsUntilTokenExpires], [((QLFAccessGranted *) self) remainingSecondsUntilNextTokenIsAvailable]);
    } else if ([self isKindOfClass:[QLFAccessDenied class]]) {
        ifAccessDeniedBlock();
    }
}

- (NSComparisonResult)compare:(QLFGetAccessTokenResponse *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't compare instances of this class" userInfo:nil];
}

- (BOOL)isEqualTo:(id)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (BOOL)isEqualToGetAccessTokenResponse:(QLFGetAccessTokenResponse *)other
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't check instances of this class for equality" userInfo:nil];
}

- (NSUInteger)hash
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Can't hash instances of this class" userInfo:nil];
}

@end

@implementation QLFAccessGranted



+ (QLFGetAccessTokenResponse *)accessGrantedWithSignedBlindedToken:(QLFSignedBlindedToken *)signedBlindedToken slotNumber:(QLFKeySlotNumber)slotNumber remainingSecondsUntilTokenExpires:(int64_t)remainingSecondsUntilTokenExpires remainingSecondsUntilNextTokenIsAvailable:(int64_t)remainingSecondsUntilNextTokenIsAvailable
{

    return [[QLFAccessGranted alloc] initWithSignedBlindedToken:signedBlindedToken slotNumber:slotNumber remainingSecondsUntilTokenExpires:remainingSecondsUntilTokenExpires remainingSecondsUntilNextTokenIsAvailable:remainingSecondsUntilNextTokenIsAvailable];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFAccessGranted *e = (QLFAccessGranted *)element;
        [writer writeConstructorStartWithObjectName:@"AccessGranted"];
            [writer writeFieldStartWithFieldName:@"remainingSecondsUntilNextTokenIsAvailable"];
                [QredoPrimitiveMarshallers int64Marshaller]([NSNumber numberWithLongLong: [e remainingSecondsUntilNextTokenIsAvailable]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"remainingSecondsUntilTokenExpires"];
                [QredoPrimitiveMarshallers int64Marshaller]([NSNumber numberWithLongLong: [e remainingSecondsUntilTokenExpires]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"signedBlindedToken"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e signedBlindedToken], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"slotNumber"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e slotNumber]], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        
            [reader readFieldStart]; // TODO assert that field name is 'remainingSecondsUntilNextTokenIsAvailable'
                int64_t remainingSecondsUntilNextTokenIsAvailable = (int64_t )[[QredoPrimitiveMarshallers int64Unmarshaller](reader) longLongValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'remainingSecondsUntilTokenExpires'
                int64_t remainingSecondsUntilTokenExpires = (int64_t )[[QredoPrimitiveMarshallers int64Unmarshaller](reader) longLongValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'signedBlindedToken'
                QLFSignedBlindedToken *signedBlindedToken = (QLFSignedBlindedToken *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'slotNumber'
                QLFKeySlotNumber slotNumber = (QLFKeySlotNumber )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
        
        return [QLFGetAccessTokenResponse accessGrantedWithSignedBlindedToken:signedBlindedToken slotNumber:slotNumber remainingSecondsUntilTokenExpires:remainingSecondsUntilTokenExpires remainingSecondsUntilNextTokenIsAvailable:remainingSecondsUntilNextTokenIsAvailable];
    };
}

- (instancetype)initWithSignedBlindedToken:(QLFSignedBlindedToken *)signedBlindedToken slotNumber:(QLFKeySlotNumber)slotNumber remainingSecondsUntilTokenExpires:(int64_t)remainingSecondsUntilTokenExpires remainingSecondsUntilNextTokenIsAvailable:(int64_t)remainingSecondsUntilNextTokenIsAvailable
{

    self = [super init];
    if (self) {
        _signedBlindedToken = signedBlindedToken;
        _slotNumber = slotNumber;
        _remainingSecondsUntilTokenExpires = remainingSecondsUntilTokenExpires;
        _remainingSecondsUntilNextTokenIsAvailable = remainingSecondsUntilNextTokenIsAvailable;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFAccessGranted *)other
{
    if ([other isKindOfClass:[QLFGetAccessTokenResponse class]] && ![other isKindOfClass:[QLFAccessGranted class]]) {
        // N.B. impose an ordering among subtypes of GetAccessTokenResponse
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    QREDO_COMPARE_OBJECT(signedBlindedToken);
    QREDO_COMPARE_SCALAR(slotNumber);
    QREDO_COMPARE_SCALAR(remainingSecondsUntilTokenExpires);
    QREDO_COMPARE_SCALAR(remainingSecondsUntilNextTokenIsAvailable);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToAccessGranted:other];
       
}

- (BOOL)isEqualToAccessGranted:(QLFAccessGranted *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_signedBlindedToken != other.signedBlindedToken && ![_signedBlindedToken isEqual:other.signedBlindedToken])
        return NO;
    if (_slotNumber != other.slotNumber)
        return NO;
    if (_remainingSecondsUntilTokenExpires != other.remainingSecondsUntilTokenExpires)
        return NO;
    if (_remainingSecondsUntilNextTokenIsAvailable != other.remainingSecondsUntilNextTokenIsAvailable)
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_signedBlindedToken hash];
    hash = hash * 31u + _slotNumber;
    hash = hash * 31u + _remainingSecondsUntilTokenExpires;
    hash = hash * 31u + _remainingSecondsUntilNextTokenIsAvailable;
    return hash;
       
}

@end

@implementation QLFAccessDenied



+ (QLFGetAccessTokenResponse *)accessDenied
{

    return [[QLFAccessDenied alloc] init];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFAccessDenied *e = (QLFAccessDenied *)element;
        [writer writeConstructorStartWithObjectName:@"AccessDenied"];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        

        
        return [QLFGetAccessTokenResponse accessDenied];
    };
}

- (instancetype)init
{

    self = [super init];
    if (self) {
        
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFAccessDenied *)other
{
    if ([other isKindOfClass:[QLFGetAccessTokenResponse class]] && ![other isKindOfClass:[QLFAccessDenied class]]) {
        // N.B. impose an ordering among subtypes of GetAccessTokenResponse
        return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
    }

    
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToAccessDenied:other];
       
}

- (BOOL)isEqualToAccessDenied:(QLFAccessDenied *)other
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

@implementation QLFAuthenticatedClaim



+ (QLFAuthenticatedClaim *)authenticatedClaimWithValidity:(QLFCredentialValidationResult *)validity claimHash:(QLFAuthenticationCode *)claimHash attesterInfo:(NSString *)attesterInfo
{

    return [[QLFAuthenticatedClaim alloc] initWithValidity:validity claimHash:claimHash attesterInfo:attesterInfo];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFAuthenticatedClaim *e = (QLFAuthenticatedClaim *)element;
        [writer writeConstructorStartWithObjectName:@"AuthenticatedClaim"];
            [writer writeFieldStartWithFieldName:@"attesterInfo"];
                [QredoPrimitiveMarshallers stringMarshaller]([e attesterInfo], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"claimHash"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e claimHash], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"validity"];
                [QLFCredentialValidationResult marshaller]([e validity], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'AuthenticatedClaim'
            [reader readFieldStart]; // TODO assert that field name is 'attesterInfo'
                NSString *attesterInfo = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'claimHash'
                QLFAuthenticationCode *claimHash = (QLFAuthenticationCode *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'validity'
                QLFCredentialValidationResult *validity = (QLFCredentialValidationResult *)[QLFCredentialValidationResult unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFAuthenticatedClaim authenticatedClaimWithValidity:validity claimHash:claimHash attesterInfo:attesterInfo];
    };
}

- (instancetype)initWithValidity:(QLFCredentialValidationResult *)validity claimHash:(QLFAuthenticationCode *)claimHash attesterInfo:(NSString *)attesterInfo
{

    self = [super init];
    if (self) {
        _validity = validity;
        _claimHash = claimHash;
        _attesterInfo = attesterInfo;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFAuthenticatedClaim *)other
{

    QREDO_COMPARE_OBJECT(validity);
    QREDO_COMPARE_OBJECT(claimHash);
    QREDO_COMPARE_OBJECT(attesterInfo);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToAuthenticatedClaim:other];
       
}

- (BOOL)isEqualToAuthenticatedClaim:(QLFAuthenticatedClaim *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_validity != other.validity && ![_validity isEqual:other.validity])
        return NO;
    if (_claimHash != other.claimHash && ![_claimHash isEqual:other.claimHash])
        return NO;
    if (_attesterInfo != other.attesterInfo && ![_attesterInfo isEqual:other.attesterInfo])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_validity hash];
    hash = hash * 31u + [_claimHash hash];
    hash = hash * 31u + [_attesterInfo hash];
    return hash;
       
}

@end

@implementation QLFAuthenticationResponse



+ (QLFAuthenticationResponse *)authenticationResponseWithCredentialValidationResults:(NSArray *)credentialValidationResults sameIdentity:(BOOL)sameIdentity authenticatorCertChain:(NSData *)authenticatorCertChain signature:(NSData *)signature
{

    return [[QLFAuthenticationResponse alloc] initWithCredentialValidationResults:credentialValidationResults sameIdentity:sameIdentity authenticatorCertChain:authenticatorCertChain signature:signature];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFAuthenticationResponse *e = (QLFAuthenticationResponse *)element;
        [writer writeConstructorStartWithObjectName:@"AuthenticationResponse"];
            [writer writeFieldStartWithFieldName:@"authenticatorCertChain"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e authenticatorCertChain], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"credentialValidationResults"];
                [QredoPrimitiveMarshallers sequenceMarshallerWithElementMarshaller:[QLFAuthenticatedClaim marshaller]]([e credentialValidationResults], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"sameIdentity"];
                [QredoPrimitiveMarshallers booleanMarshaller]([NSNumber numberWithBool: [e sameIdentity]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"signature"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e signature], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'AuthenticationResponse'
            [reader readFieldStart]; // TODO assert that field name is 'authenticatorCertChain'
                NSData *authenticatorCertChain = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'credentialValidationResults'
                NSArray *credentialValidationResults = (NSArray *)[QredoPrimitiveMarshallers sequenceUnmarshallerWithElementUnmarshaller:[QLFAuthenticatedClaim unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sameIdentity'
                BOOL sameIdentity = (BOOL )[[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'signature'
                NSData *signature = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFAuthenticationResponse authenticationResponseWithCredentialValidationResults:credentialValidationResults sameIdentity:sameIdentity authenticatorCertChain:authenticatorCertChain signature:signature];
    };
}

- (instancetype)initWithCredentialValidationResults:(NSArray *)credentialValidationResults sameIdentity:(BOOL)sameIdentity authenticatorCertChain:(NSData *)authenticatorCertChain signature:(NSData *)signature
{

    self = [super init];
    if (self) {
        _credentialValidationResults = credentialValidationResults;
        _sameIdentity = sameIdentity;
        _authenticatorCertChain = authenticatorCertChain;
        _signature = signature;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFAuthenticationResponse *)other
{

    QREDO_COMPARE_OBJECT(credentialValidationResults);
    QREDO_COMPARE_SCALAR(sameIdentity);
    QREDO_COMPARE_OBJECT(authenticatorCertChain);
    QREDO_COMPARE_OBJECT(signature);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToAuthenticationResponse:other];
       
}

- (BOOL)isEqualToAuthenticationResponse:(QLFAuthenticationResponse *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_credentialValidationResults != other.credentialValidationResults && ![_credentialValidationResults isEqual:other.credentialValidationResults])
        return NO;
    if (_sameIdentity != other.sameIdentity)
        return NO;
    if (_authenticatorCertChain != other.authenticatorCertChain && ![_authenticatorCertChain isEqual:other.authenticatorCertChain])
        return NO;
    if (_signature != other.signature && ![_signature isEqual:other.signature])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_credentialValidationResults hash];
    hash = hash * 31u + _sameIdentity;
    hash = hash * 31u + [_authenticatorCertChain hash];
    hash = hash * 31u + [_signature hash];
    return hash;
       
}

@end

@implementation QLFClaim



+ (QLFClaim *)claimWithName:(NSSet *)name datatype:(NSString *)datatype value:(NSData *)value
{

    return [[QLFClaim alloc] initWithName:name datatype:datatype value:value];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFClaim *e = (QLFClaim *)element;
        [writer writeConstructorStartWithObjectName:@"Claim"];
            [writer writeFieldStartWithFieldName:@"datatype"];
                [QredoPrimitiveMarshallers stringMarshaller]([e datatype], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"name"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers stringMarshaller]]([e name], writer);
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
        [reader readConstructorStart];// TODO assert that constructor name is 'Claim'
            [reader readFieldStart]; // TODO assert that field name is 'datatype'
                NSString *datatype = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'name'
                NSSet *name = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers stringUnmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'value'
                NSData *value = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFClaim claimWithName:name datatype:datatype value:value];
    };
}

- (instancetype)initWithName:(NSSet *)name datatype:(NSString *)datatype value:(NSData *)value
{

    self = [super init];
    if (self) {
        _name = name;
        _datatype = datatype;
        _value = value;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFClaim *)other
{

    QREDO_COMPARE_OBJECT(name);
    QREDO_COMPARE_OBJECT(datatype);
    QREDO_COMPARE_OBJECT(value);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToClaim:other];
       
}

- (BOOL)isEqualToClaim:(QLFClaim *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_name != other.name && ![_name isEqual:other.name])
        return NO;
    if (_datatype != other.datatype && ![_datatype isEqual:other.datatype])
        return NO;
    if (_value != other.value && ![_value isEqual:other.value])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_name hash];
    hash = hash * 31u + [_datatype hash];
    hash = hash * 31u + [_value hash];
    return hash;
       
}

@end

@implementation QLFAttestationRequest



+ (QLFAttestationRequest *)attestationRequestWithAttestationId:(NSString *)attestationId identityPubKey:(QLFAuthenticationKey256 *)identityPubKey claims:(NSSet *)claims signature:(NSData *)signature
{

    return [[QLFAttestationRequest alloc] initWithAttestationId:attestationId identityPubKey:identityPubKey claims:claims signature:signature];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFAttestationRequest *e = (QLFAttestationRequest *)element;
        [writer writeConstructorStartWithObjectName:@"AttestationRequest"];
            [writer writeFieldStartWithFieldName:@"attestationId"];
                [QredoPrimitiveMarshallers stringMarshaller]([e attestationId], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"claims"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFClaim marshaller]]([e claims], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"identityPubKey"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e identityPubKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"signature"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e signature], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'AttestationRequest'
            [reader readFieldStart]; // TODO assert that field name is 'attestationId'
                NSString *attestationId = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'claims'
                NSSet *claims = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFClaim unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'identityPubKey'
                QLFAuthenticationKey256 *identityPubKey = (QLFAuthenticationKey256 *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'signature'
                NSData *signature = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFAttestationRequest attestationRequestWithAttestationId:attestationId identityPubKey:identityPubKey claims:claims signature:signature];
    };
}

- (instancetype)initWithAttestationId:(NSString *)attestationId identityPubKey:(QLFAuthenticationKey256 *)identityPubKey claims:(NSSet *)claims signature:(NSData *)signature
{

    self = [super init];
    if (self) {
        _attestationId = attestationId;
        _identityPubKey = identityPubKey;
        _claims = claims;
        _signature = signature;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFAttestationRequest *)other
{

    QREDO_COMPARE_OBJECT(attestationId);
    QREDO_COMPARE_OBJECT(identityPubKey);
    QREDO_COMPARE_OBJECT(claims);
    QREDO_COMPARE_OBJECT(signature);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToAttestationRequest:other];
       
}

- (BOOL)isEqualToAttestationRequest:(QLFAttestationRequest *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_attestationId != other.attestationId && ![_attestationId isEqual:other.attestationId])
        return NO;
    if (_identityPubKey != other.identityPubKey && ![_identityPubKey isEqual:other.identityPubKey])
        return NO;
    if (_claims != other.claims && ![_claims isEqual:other.claims])
        return NO;
    if (_signature != other.signature && ![_signature isEqual:other.signature])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_attestationId hash];
    hash = hash * 31u + [_identityPubKey hash];
    hash = hash * 31u + [_claims hash];
    hash = hash * 31u + [_signature hash];
    return hash;
       
}

@end

@implementation QLFCredential



+ (QLFCredential *)credentialWithSerialNumber:(NSString *)serialNumber claimant:(NSData *)claimant hashedClaim:(NSData *)hashedClaim notBefore:(NSString *)notBefore notAfter:(NSString *)notAfter revocationLocator:(NSString *)revocationLocator attesterInfo:(NSString *)attesterInfo signature:(NSData *)signature
{

    return [[QLFCredential alloc] initWithSerialNumber:serialNumber claimant:claimant hashedClaim:hashedClaim notBefore:notBefore notAfter:notAfter revocationLocator:revocationLocator attesterInfo:attesterInfo signature:signature];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFCredential *e = (QLFCredential *)element;
        [writer writeConstructorStartWithObjectName:@"Credential"];
            [writer writeFieldStartWithFieldName:@"attesterInfo"];
                [QredoPrimitiveMarshallers stringMarshaller]([e attesterInfo], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"claimant"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e claimant], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"hashedClaim"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e hashedClaim], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"notAfter"];
                [QredoPrimitiveMarshallers stringMarshaller]([e notAfter], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"notBefore"];
                [QredoPrimitiveMarshallers stringMarshaller]([e notBefore], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"revocationLocator"];
                [QredoPrimitiveMarshallers stringMarshaller]([e revocationLocator], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"serialNumber"];
                [QredoPrimitiveMarshallers stringMarshaller]([e serialNumber], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"signature"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e signature], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'Credential'
            [reader readFieldStart]; // TODO assert that field name is 'attesterInfo'
                NSString *attesterInfo = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'claimant'
                NSData *claimant = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'hashedClaim'
                NSData *hashedClaim = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'notAfter'
                NSString *notAfter = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'notBefore'
                NSString *notBefore = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'revocationLocator'
                NSString *revocationLocator = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'serialNumber'
                NSString *serialNumber = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'signature'
                NSData *signature = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFCredential credentialWithSerialNumber:serialNumber claimant:claimant hashedClaim:hashedClaim notBefore:notBefore notAfter:notAfter revocationLocator:revocationLocator attesterInfo:attesterInfo signature:signature];
    };
}

- (instancetype)initWithSerialNumber:(NSString *)serialNumber claimant:(NSData *)claimant hashedClaim:(NSData *)hashedClaim notBefore:(NSString *)notBefore notAfter:(NSString *)notAfter revocationLocator:(NSString *)revocationLocator attesterInfo:(NSString *)attesterInfo signature:(NSData *)signature
{

    self = [super init];
    if (self) {
        _serialNumber = serialNumber;
        _claimant = claimant;
        _hashedClaim = hashedClaim;
        _notBefore = notBefore;
        _notAfter = notAfter;
        _revocationLocator = revocationLocator;
        _attesterInfo = attesterInfo;
        _signature = signature;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFCredential *)other
{

    QREDO_COMPARE_OBJECT(serialNumber);
    QREDO_COMPARE_OBJECT(claimant);
    QREDO_COMPARE_OBJECT(hashedClaim);
    QREDO_COMPARE_OBJECT(notBefore);
    QREDO_COMPARE_OBJECT(notAfter);
    QREDO_COMPARE_OBJECT(revocationLocator);
    QREDO_COMPARE_OBJECT(attesterInfo);
    QREDO_COMPARE_OBJECT(signature);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToCredential:other];
       
}

- (BOOL)isEqualToCredential:(QLFCredential *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_serialNumber != other.serialNumber && ![_serialNumber isEqual:other.serialNumber])
        return NO;
    if (_claimant != other.claimant && ![_claimant isEqual:other.claimant])
        return NO;
    if (_hashedClaim != other.hashedClaim && ![_hashedClaim isEqual:other.hashedClaim])
        return NO;
    if (_notBefore != other.notBefore && ![_notBefore isEqual:other.notBefore])
        return NO;
    if (_notAfter != other.notAfter && ![_notAfter isEqual:other.notAfter])
        return NO;
    if (_revocationLocator != other.revocationLocator && ![_revocationLocator isEqual:other.revocationLocator])
        return NO;
    if (_attesterInfo != other.attesterInfo && ![_attesterInfo isEqual:other.attesterInfo])
        return NO;
    if (_signature != other.signature && ![_signature isEqual:other.signature])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_serialNumber hash];
    hash = hash * 31u + [_claimant hash];
    hash = hash * 31u + [_hashedClaim hash];
    hash = hash * 31u + [_notBefore hash];
    hash = hash * 31u + [_notAfter hash];
    hash = hash * 31u + [_revocationLocator hash];
    hash = hash * 31u + [_attesterInfo hash];
    hash = hash * 31u + [_signature hash];
    return hash;
       
}

@end

@implementation QLFAttestation



+ (QLFAttestation *)attestationWithClaim:(QLFClaim *)claim credential:(QLFCredential *)credential
{

    return [[QLFAttestation alloc] initWithClaim:claim credential:credential];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFAttestation *e = (QLFAttestation *)element;
        [writer writeConstructorStartWithObjectName:@"Attestation"];
            [writer writeFieldStartWithFieldName:@"claim"];
                [QLFClaim marshaller]([e claim], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"credential"];
                [QLFCredential marshaller]([e credential], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'Attestation'
            [reader readFieldStart]; // TODO assert that field name is 'claim'
                QLFClaim *claim = (QLFClaim *)[QLFClaim unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'credential'
                QLFCredential *credential = (QLFCredential *)[QLFCredential unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFAttestation attestationWithClaim:claim credential:credential];
    };
}

- (instancetype)initWithClaim:(QLFClaim *)claim credential:(QLFCredential *)credential
{

    self = [super init];
    if (self) {
        _claim = claim;
        _credential = credential;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFAttestation *)other
{

    QREDO_COMPARE_OBJECT(claim);
    QREDO_COMPARE_OBJECT(credential);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToAttestation:other];
       
}

- (BOOL)isEqualToAttestation:(QLFAttestation *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_claim != other.claim && ![_claim isEqual:other.claim])
        return NO;
    if (_credential != other.credential && ![_credential isEqual:other.credential])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_claim hash];
    hash = hash * 31u + [_credential hash];
    return hash;
       
}

@end

@implementation QLFAttestationResponse



+ (QLFAttestationResponse *)attestationResponseWithAttestationId:(NSString *)attestationId attestations:(NSSet *)attestations
{

    return [[QLFAttestationResponse alloc] initWithAttestationId:attestationId attestations:attestations];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFAttestationResponse *e = (QLFAttestationResponse *)element;
        [writer writeConstructorStartWithObjectName:@"AttestationResponse"];
            [writer writeFieldStartWithFieldName:@"attestationId"];
                [QredoPrimitiveMarshallers stringMarshaller]([e attestationId], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"attestations"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFAttestation marshaller]]([e attestations], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'AttestationResponse'
            [reader readFieldStart]; // TODO assert that field name is 'attestationId'
                NSString *attestationId = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'attestations'
                NSSet *attestations = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFAttestation unmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFAttestationResponse attestationResponseWithAttestationId:attestationId attestations:attestations];
    };
}

- (instancetype)initWithAttestationId:(NSString *)attestationId attestations:(NSSet *)attestations
{

    self = [super init];
    if (self) {
        _attestationId = attestationId;
        _attestations = attestations;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFAttestationResponse *)other
{

    QREDO_COMPARE_OBJECT(attestationId);
    QREDO_COMPARE_OBJECT(attestations);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToAttestationResponse:other];
       
}

- (BOOL)isEqualToAttestationResponse:(QLFAttestationResponse *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_attestationId != other.attestationId && ![_attestationId isEqual:other.attestationId])
        return NO;
    if (_attestations != other.attestations && ![_attestations isEqual:other.attestations])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_attestationId hash];
    hash = hash * 31u + [_attestations hash];
    return hash;
       
}

@end

@implementation QLFClaimMessage



+ (QLFClaimMessage *)claimMessageWithClaimHash:(QLFAuthenticationCode *)claimHash credential:(QLFCredential *)credential
{

    return [[QLFClaimMessage alloc] initWithClaimHash:claimHash credential:credential];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFClaimMessage *e = (QLFClaimMessage *)element;
        [writer writeConstructorStartWithObjectName:@"ClaimMessage"];
            [writer writeFieldStartWithFieldName:@"claimHash"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e claimHash], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"credential"];
                [QLFCredential marshaller]([e credential], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'ClaimMessage'
            [reader readFieldStart]; // TODO assert that field name is 'claimHash'
                QLFAuthenticationCode *claimHash = (QLFAuthenticationCode *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'credential'
                QLFCredential *credential = (QLFCredential *)[QLFCredential unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFClaimMessage claimMessageWithClaimHash:claimHash credential:credential];
    };
}

- (instancetype)initWithClaimHash:(QLFAuthenticationCode *)claimHash credential:(QLFCredential *)credential
{

    self = [super init];
    if (self) {
        _claimHash = claimHash;
        _credential = credential;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFClaimMessage *)other
{

    QREDO_COMPARE_OBJECT(claimHash);
    QREDO_COMPARE_OBJECT(credential);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToClaimMessage:other];
       
}

- (BOOL)isEqualToClaimMessage:(QLFClaimMessage *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_claimHash != other.claimHash && ![_claimHash isEqual:other.claimHash])
        return NO;
    if (_credential != other.credential && ![_credential isEqual:other.credential])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_claimHash hash];
    hash = hash * 31u + [_credential hash];
    return hash;
       
}

@end

@implementation QLFAuthenticationRequest



+ (QLFAuthenticationRequest *)authenticationRequestWithClaimMessages:(NSArray *)claimMessages conversationSecret:(QLFEncryptionKey256 *)conversationSecret
{

    return [[QLFAuthenticationRequest alloc] initWithClaimMessages:claimMessages conversationSecret:conversationSecret];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFAuthenticationRequest *e = (QLFAuthenticationRequest *)element;
        [writer writeConstructorStartWithObjectName:@"AuthenticationRequest"];
            [writer writeFieldStartWithFieldName:@"claimMessages"];
                [QredoPrimitiveMarshallers sequenceMarshallerWithElementMarshaller:[QLFClaimMessage marshaller]]([e claimMessages], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"conversationSecret"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e conversationSecret], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'AuthenticationRequest'
            [reader readFieldStart]; // TODO assert that field name is 'claimMessages'
                NSArray *claimMessages = (NSArray *)[QredoPrimitiveMarshallers sequenceUnmarshallerWithElementUnmarshaller:[QLFClaimMessage unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'conversationSecret'
                QLFEncryptionKey256 *conversationSecret = (QLFEncryptionKey256 *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFAuthenticationRequest authenticationRequestWithClaimMessages:claimMessages conversationSecret:conversationSecret];
    };
}

- (instancetype)initWithClaimMessages:(NSArray *)claimMessages conversationSecret:(QLFEncryptionKey256 *)conversationSecret
{

    self = [super init];
    if (self) {
        _claimMessages = claimMessages;
        _conversationSecret = conversationSecret;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFAuthenticationRequest *)other
{

    QREDO_COMPARE_OBJECT(claimMessages);
    QREDO_COMPARE_OBJECT(conversationSecret);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToAuthenticationRequest:other];
       
}

- (BOOL)isEqualToAuthenticationRequest:(QLFAuthenticationRequest *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_claimMessages != other.claimMessages && ![_claimMessages isEqual:other.claimMessages])
        return NO;
    if (_conversationSecret != other.conversationSecret && ![_conversationSecret isEqual:other.conversationSecret])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_claimMessages hash];
    hash = hash * 31u + [_conversationSecret hash];
    return hash;
       
}

@end

@implementation QLFPresentation



+ (QLFPresentation *)presentationWithAttestations:(NSSet *)attestations
{

    return [[QLFPresentation alloc] initWithAttestations:attestations];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFPresentation *e = (QLFPresentation *)element;
        [writer writeConstructorStartWithObjectName:@"Presentation"];
            [writer writeFieldStartWithFieldName:@"attestations"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFAttestation marshaller]]([e attestations], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'Presentation'
            [reader readFieldStart]; // TODO assert that field name is 'attestations'
                NSSet *attestations = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFAttestation unmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFPresentation presentationWithAttestations:attestations];
    };
}

- (instancetype)initWithAttestations:(NSSet *)attestations
{

    self = [super init];
    if (self) {
        _attestations = attestations;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFPresentation *)other
{

    QREDO_COMPARE_OBJECT(attestations);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToPresentation:other];
       
}

- (BOOL)isEqualToPresentation:(QLFPresentation *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_attestations != other.attestations && ![_attestations isEqual:other.attestations])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_attestations hash];
    return hash;
       
}

@end

@implementation QLFPresentationRequest



+ (QLFPresentationRequest *)presentationRequestWithRequestedAttestationTypes:(NSSet *)requestedAttestationTypes authenticator:(NSString *)authenticator
{

    return [[QLFPresentationRequest alloc] initWithRequestedAttestationTypes:requestedAttestationTypes authenticator:authenticator];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFPresentationRequest *e = (QLFPresentationRequest *)element;
        [writer writeConstructorStartWithObjectName:@"PresentationRequest"];
            [writer writeFieldStartWithFieldName:@"authenticator"];
                [QredoPrimitiveMarshallers stringMarshaller]([e authenticator], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"requestedAttestationTypes"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers stringMarshaller]]([e requestedAttestationTypes], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'PresentationRequest'
            [reader readFieldStart]; // TODO assert that field name is 'authenticator'
                NSString *authenticator = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'requestedAttestationTypes'
                NSSet *requestedAttestationTypes = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers stringUnmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFPresentationRequest presentationRequestWithRequestedAttestationTypes:requestedAttestationTypes authenticator:authenticator];
    };
}

- (instancetype)initWithRequestedAttestationTypes:(NSSet *)requestedAttestationTypes authenticator:(NSString *)authenticator
{

    self = [super init];
    if (self) {
        _requestedAttestationTypes = requestedAttestationTypes;
        _authenticator = authenticator;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFPresentationRequest *)other
{

    QREDO_COMPARE_OBJECT(requestedAttestationTypes);
    QREDO_COMPARE_OBJECT(authenticator);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToPresentationRequest:other];
       
}

- (BOOL)isEqualToPresentationRequest:(QLFPresentationRequest *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_requestedAttestationTypes != other.requestedAttestationTypes && ![_requestedAttestationTypes isEqual:other.requestedAttestationTypes])
        return NO;
    if (_authenticator != other.authenticator && ![_authenticator isEqual:other.authenticator])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_requestedAttestationTypes hash];
    hash = hash * 31u + [_authenticator hash];
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
    hash = hash * 31u + _timestamp;
    hash = hash * 31u + [_signature hash];
    return hash;
       
}

@end

@implementation QLFConversationDescriptor



+ (QLFConversationDescriptor *)conversationDescriptorWithRendezvousTag:(NSString *)rendezvousTag amRendezvousOwner:(BOOL)amRendezvousOwner conversationId:(QLFConversationId *)conversationId conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType myKey:(QLFKeyPairLF *)myKey yourPublicKey:(QLFKeyLF *)yourPublicKey inboundBulkKey:(QLFKeyLF *)inboundBulkKey outboundBulkKey:(QLFKeyLF *)outboundBulkKey initialTransCap:(NSSet *)initialTransCap
{

    return [[QLFConversationDescriptor alloc] initWithRendezvousTag:rendezvousTag amRendezvousOwner:amRendezvousOwner conversationId:conversationId conversationType:conversationType authenticationType:authenticationType myKey:myKey yourPublicKey:yourPublicKey inboundBulkKey:inboundBulkKey outboundBulkKey:outboundBulkKey initialTransCap:initialTransCap];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFConversationDescriptor *e = (QLFConversationDescriptor *)element;
        [writer writeConstructorStartWithObjectName:@"ConversationDescriptor"];
            [writer writeFieldStartWithFieldName:@"amRendezvousOwner"];
                [QredoPrimitiveMarshallers booleanMarshaller]([NSNumber numberWithBool: [e amRendezvousOwner]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"authenticationType"];
                [QLFRendezvousAuthType marshaller]([e authenticationType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"conversationId"];
                [QredoPrimitiveMarshallers quidMarshaller]([e conversationId], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"conversationType"];
                [QredoPrimitiveMarshallers stringMarshaller]([e conversationType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"inboundBulkKey"];
                [QLFKeyLF marshaller]([e inboundBulkKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"initialTransCap"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers byteSequenceMarshaller]]([e initialTransCap], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"myKey"];
                [QLFKeyPairLF marshaller]([e myKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"outboundBulkKey"];
                [QLFKeyLF marshaller]([e outboundBulkKey], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"rendezvousTag"];
                [QredoPrimitiveMarshallers stringMarshaller]([e rendezvousTag], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"yourPublicKey"];
                [QLFKeyLF marshaller]([e yourPublicKey], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'ConversationDescriptor'
            [reader readFieldStart]; // TODO assert that field name is 'amRendezvousOwner'
                BOOL amRendezvousOwner = (BOOL )[[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'authenticationType'
                QLFRendezvousAuthType *authenticationType = (QLFRendezvousAuthType *)[QLFRendezvousAuthType unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'conversationId'
                QLFConversationId *conversationId = (QLFConversationId *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'conversationType'
                NSString *conversationType = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'inboundBulkKey'
                QLFKeyLF *inboundBulkKey = (QLFKeyLF *)[QLFKeyLF unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'initialTransCap'
                NSSet *initialTransCap = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'myKey'
                QLFKeyPairLF *myKey = (QLFKeyPairLF *)[QLFKeyPairLF unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'outboundBulkKey'
                QLFKeyLF *outboundBulkKey = (QLFKeyLF *)[QLFKeyLF unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'rendezvousTag'
                NSString *rendezvousTag = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'yourPublicKey'
                QLFKeyLF *yourPublicKey = (QLFKeyLF *)[QLFKeyLF unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFConversationDescriptor conversationDescriptorWithRendezvousTag:rendezvousTag amRendezvousOwner:amRendezvousOwner conversationId:conversationId conversationType:conversationType authenticationType:authenticationType myKey:myKey yourPublicKey:yourPublicKey inboundBulkKey:inboundBulkKey outboundBulkKey:outboundBulkKey initialTransCap:initialTransCap];
    };
}

- (instancetype)initWithRendezvousTag:(NSString *)rendezvousTag amRendezvousOwner:(BOOL)amRendezvousOwner conversationId:(QLFConversationId *)conversationId conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType myKey:(QLFKeyPairLF *)myKey yourPublicKey:(QLFKeyLF *)yourPublicKey inboundBulkKey:(QLFKeyLF *)inboundBulkKey outboundBulkKey:(QLFKeyLF *)outboundBulkKey initialTransCap:(NSSet *)initialTransCap
{

    self = [super init];
    if (self) {
        _rendezvousTag = rendezvousTag;
        _amRendezvousOwner = amRendezvousOwner;
        _conversationId = conversationId;
        _conversationType = conversationType;
        _authenticationType = authenticationType;
        _myKey = myKey;
        _yourPublicKey = yourPublicKey;
        _inboundBulkKey = inboundBulkKey;
        _outboundBulkKey = outboundBulkKey;
        _initialTransCap = initialTransCap;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFConversationDescriptor *)other
{

    QREDO_COMPARE_OBJECT(rendezvousTag);
    QREDO_COMPARE_SCALAR(amRendezvousOwner);
    QREDO_COMPARE_OBJECT(conversationId);
    QREDO_COMPARE_OBJECT(conversationType);
    QREDO_COMPARE_OBJECT(authenticationType);
    QREDO_COMPARE_OBJECT(myKey);
    QREDO_COMPARE_OBJECT(yourPublicKey);
    QREDO_COMPARE_OBJECT(inboundBulkKey);
    QREDO_COMPARE_OBJECT(outboundBulkKey);
    QREDO_COMPARE_OBJECT(initialTransCap);
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
    if (_amRendezvousOwner != other.amRendezvousOwner)
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
    if (_inboundBulkKey != other.inboundBulkKey && ![_inboundBulkKey isEqual:other.inboundBulkKey])
        return NO;
    if (_outboundBulkKey != other.outboundBulkKey && ![_outboundBulkKey isEqual:other.outboundBulkKey])
        return NO;
    if (_initialTransCap != other.initialTransCap && ![_initialTransCap isEqual:other.initialTransCap])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_rendezvousTag hash];
    hash = hash * 31u + _amRendezvousOwner;
    hash = hash * 31u + [_conversationId hash];
    hash = hash * 31u + [_conversationType hash];
    hash = hash * 31u + [_authenticationType hash];
    hash = hash * 31u + [_myKey hash];
    hash = hash * 31u + [_yourPublicKey hash];
    hash = hash * 31u + [_inboundBulkKey hash];
    hash = hash * 31u + [_outboundBulkKey hash];
    hash = hash * 31u + [_initialTransCap hash];
    return hash;
       
}

@end

@implementation QLFRendezvousDescriptor



+ (QLFRendezvousDescriptor *)rendezvousDescriptorWithTag:(NSString *)tag hashedTag:(QLFRendezvousHashedTag *)hashedTag conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType durationSeconds:(NSSet *)durationSeconds maxResponseCount:(NSSet *)maxResponseCount transCap:(NSSet *)transCap requesterKeyPair:(QLFKeyPairLF *)requesterKeyPair accessControlKeyPair:(QLFKeyPairLF *)accessControlKeyPair
{

    return [[QLFRendezvousDescriptor alloc] initWithTag:tag hashedTag:hashedTag conversationType:conversationType authenticationType:authenticationType durationSeconds:durationSeconds maxResponseCount:maxResponseCount transCap:transCap requesterKeyPair:requesterKeyPair accessControlKeyPair:accessControlKeyPair];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFRendezvousDescriptor *e = (QLFRendezvousDescriptor *)element;
        [writer writeConstructorStartWithObjectName:@"RendezvousDescriptor"];
            [writer writeFieldStartWithFieldName:@"accessControlKeyPair"];
                [QLFKeyPairLF marshaller]([e accessControlKeyPair], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"authenticationType"];
                [QLFRendezvousAuthType marshaller]([e authenticationType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"conversationType"];
                [QredoPrimitiveMarshallers stringMarshaller]([e conversationType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"durationSeconds"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int64Marshaller]]([e durationSeconds], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"hashedTag"];
                [QredoPrimitiveMarshallers quidMarshaller]([e hashedTag], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"maxResponseCount"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int64Marshaller]]([e maxResponseCount], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"requesterKeyPair"];
                [QLFKeyPairLF marshaller]([e requesterKeyPair], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"tag"];
                [QredoPrimitiveMarshallers stringMarshaller]([e tag], writer);
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
        [reader readConstructorStart];// TODO assert that constructor name is 'RendezvousDescriptor'
            [reader readFieldStart]; // TODO assert that field name is 'accessControlKeyPair'
                QLFKeyPairLF *accessControlKeyPair = (QLFKeyPairLF *)[QLFKeyPairLF unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'authenticationType'
                QLFRendezvousAuthType *authenticationType = (QLFRendezvousAuthType *)[QLFRendezvousAuthType unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'conversationType'
                NSString *conversationType = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'durationSeconds'
                NSSet *durationSeconds = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers int64Unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'hashedTag'
                QLFRendezvousHashedTag *hashedTag = (QLFRendezvousHashedTag *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'maxResponseCount'
                NSSet *maxResponseCount = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers int64Unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'requesterKeyPair'
                QLFKeyPairLF *requesterKeyPair = (QLFKeyPairLF *)[QLFKeyPairLF unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'tag'
                NSString *tag = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'transCap'
                NSSet *transCap = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers byteSequenceUnmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFRendezvousDescriptor rendezvousDescriptorWithTag:tag hashedTag:hashedTag conversationType:conversationType authenticationType:authenticationType durationSeconds:durationSeconds maxResponseCount:maxResponseCount transCap:transCap requesterKeyPair:requesterKeyPair accessControlKeyPair:accessControlKeyPair];
    };
}

- (instancetype)initWithTag:(NSString *)tag hashedTag:(QLFRendezvousHashedTag *)hashedTag conversationType:(NSString *)conversationType authenticationType:(QLFRendezvousAuthType *)authenticationType durationSeconds:(NSSet *)durationSeconds maxResponseCount:(NSSet *)maxResponseCount transCap:(NSSet *)transCap requesterKeyPair:(QLFKeyPairLF *)requesterKeyPair accessControlKeyPair:(QLFKeyPairLF *)accessControlKeyPair
{

    self = [super init];
    if (self) {
        _tag = tag;
        _hashedTag = hashedTag;
        _conversationType = conversationType;
        _authenticationType = authenticationType;
        _durationSeconds = durationSeconds;
        _maxResponseCount = maxResponseCount;
        _transCap = transCap;
        _requesterKeyPair = requesterKeyPair;
        _accessControlKeyPair = accessControlKeyPair;
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
    QREDO_COMPARE_OBJECT(maxResponseCount);
    QREDO_COMPARE_OBJECT(transCap);
    QREDO_COMPARE_OBJECT(requesterKeyPair);
    QREDO_COMPARE_OBJECT(accessControlKeyPair);
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
    if (_maxResponseCount != other.maxResponseCount && ![_maxResponseCount isEqual:other.maxResponseCount])
        return NO;
    if (_transCap != other.transCap && ![_transCap isEqual:other.transCap])
        return NO;
    if (_requesterKeyPair != other.requesterKeyPair && ![_requesterKeyPair isEqual:other.requesterKeyPair])
        return NO;
    if (_accessControlKeyPair != other.accessControlKeyPair && ![_accessControlKeyPair isEqual:other.accessControlKeyPair])
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
    hash = hash * 31u + [_maxResponseCount hash];
    hash = hash * 31u + [_transCap hash];
    hash = hash * 31u + [_requesterKeyPair hash];
    hash = hash * 31u + [_accessControlKeyPair hash];
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

       return nil;// TODO throw exception instead?
    };

}

- (void)ifSBool:(void (^)(BOOL ))ifSBoolBlock ifSInt64:(void (^)(int64_t ))ifSInt64Block ifSDT:(void (^)(QredoUTCDateTime *))ifSDTBlock ifSQUID:(void (^)(QredoQUID *))ifSQUIDBlock ifSString:(void (^)(NSString *))ifSStringBlock
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
    hash = hash * 31u + _v;
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
    hash = hash * 31u + _v;
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

@implementation QLFConversationMessageMetaDataLF



+ (QLFConversationMessageMetaDataLF *)conversationMessageMetaDataLFWithID:(QLFConversationMessageId *)id parentId:(NSSet *)parentId sequence:(QLFConversationSequenceValue *)sequence dataType:(NSString *)dataType summaryValues:(NSSet *)summaryValues
{

    return [[QLFConversationMessageMetaDataLF alloc] initWithID:id parentId:parentId sequence:sequence dataType:dataType summaryValues:summaryValues];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFConversationMessageMetaDataLF *e = (QLFConversationMessageMetaDataLF *)element;
        [writer writeConstructorStartWithObjectName:@"ConversationMessageMetaDataLF"];
            [writer writeFieldStartWithFieldName:@"dataType"];
                [QredoPrimitiveMarshallers stringMarshaller]([e dataType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"id"];
                [QredoPrimitiveMarshallers quidMarshaller]([e id], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"parentId"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers quidMarshaller]]([e parentId], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"sequence"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e sequence], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"summaryValues"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFIndexable marshaller]]([e summaryValues], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'ConversationMessageMetaDataLF'
            [reader readFieldStart]; // TODO assert that field name is 'dataType'
                NSString *dataType = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'id'
                QLFConversationMessageId *id = (QLFConversationMessageId *)[QredoPrimitiveMarshallers quidUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'parentId'
                NSSet *parentId = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers quidUnmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sequence'
                QLFConversationSequenceValue *sequence = (QLFConversationSequenceValue *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'summaryValues'
                NSSet *summaryValues = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFIndexable unmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFConversationMessageMetaDataLF conversationMessageMetaDataLFWithID:id parentId:parentId sequence:sequence dataType:dataType summaryValues:summaryValues];
    };
}

- (instancetype)initWithID:(QLFConversationMessageId *)id parentId:(NSSet *)parentId sequence:(QLFConversationSequenceValue *)sequence dataType:(NSString *)dataType summaryValues:(NSSet *)summaryValues
{

    self = [super init];
    if (self) {
        _id = id;
        _parentId = parentId;
        _sequence = sequence;
        _dataType = dataType;
        _summaryValues = summaryValues;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFConversationMessageMetaDataLF *)other
{

    QREDO_COMPARE_OBJECT(id);
    QREDO_COMPARE_OBJECT(parentId);
    QREDO_COMPARE_OBJECT(sequence);
    QREDO_COMPARE_OBJECT(dataType);
    QREDO_COMPARE_OBJECT(summaryValues);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToConversationMessageMetaDataLF:other];
       
}

- (BOOL)isEqualToConversationMessageMetaDataLF:(QLFConversationMessageMetaDataLF *)other
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
    if (_dataType != other.dataType && ![_dataType isEqual:other.dataType])
        return NO;
    if (_summaryValues != other.summaryValues && ![_summaryValues isEqual:other.summaryValues])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_id hash];
    hash = hash * 31u + [_parentId hash];
    hash = hash * 31u + [_sequence hash];
    hash = hash * 31u + [_dataType hash];
    hash = hash * 31u + [_summaryValues hash];
    return hash;
       
}

@end

@implementation QLFConversationMessageLF



+ (QLFConversationMessageLF *)conversationMessageLFWithMetadata:(QLFConversationMessageMetaDataLF *)metadata value:(NSData *)value
{

    return [[QLFConversationMessageLF alloc] initWithMetadata:metadata value:value];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFConversationMessageLF *e = (QLFConversationMessageLF *)element;
        [writer writeConstructorStartWithObjectName:@"ConversationMessageLF"];
            [writer writeFieldStartWithFieldName:@"metadata"];
                [QLFConversationMessageMetaDataLF marshaller]([e metadata], writer);
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
        [reader readConstructorStart];// TODO assert that constructor name is 'ConversationMessageLF'
            [reader readFieldStart]; // TODO assert that field name is 'metadata'
                QLFConversationMessageMetaDataLF *metadata = (QLFConversationMessageMetaDataLF *)[QLFConversationMessageMetaDataLF unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'value'
                NSData *value = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFConversationMessageLF conversationMessageLFWithMetadata:metadata value:value];
    };
}

- (instancetype)initWithMetadata:(QLFConversationMessageMetaDataLF *)metadata value:(NSData *)value
{

    self = [super init];
    if (self) {
        _metadata = metadata;
        _value = value;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFConversationMessageLF *)other
{

    QREDO_COMPARE_OBJECT(metadata);
    QREDO_COMPARE_OBJECT(value);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToConversationMessageLF:other];
       
}

- (BOOL)isEqualToConversationMessageLF:(QLFConversationMessageLF *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_metadata != other.metadata && ![_metadata isEqual:other.metadata])
        return NO;
    if (_value != other.value && ![_value isEqual:other.value])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_metadata hash];
    hash = hash * 31u + [_value hash];
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
    hash = hash * 31u + _expirySeconds;
    hash = hash * 31u + _renegotiationSeconds;
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

@implementation QLFVaultItemMetaDataLF



+ (QLFVaultItemMetaDataLF *)vaultItemMetaDataLFWithDataType:(NSString *)dataType accessLevel:(int32_t)accessLevel summaryValues:(NSSet *)summaryValues
{

    return [[QLFVaultItemMetaDataLF alloc] initWithDataType:dataType accessLevel:accessLevel summaryValues:summaryValues];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFVaultItemMetaDataLF *e = (QLFVaultItemMetaDataLF *)element;
        [writer writeConstructorStartWithObjectName:@"VaultItemMetaDataLF"];
            [writer writeFieldStartWithFieldName:@"accessLevel"];
                [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: [e accessLevel]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"dataType"];
                [QredoPrimitiveMarshallers stringMarshaller]([e dataType], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"summaryValues"];
                [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFIndexable marshaller]]([e summaryValues], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'VaultItemMetaDataLF'
            [reader readFieldStart]; // TODO assert that field name is 'accessLevel'
                int32_t accessLevel = (int32_t )[[QredoPrimitiveMarshallers int32Unmarshaller](reader) longValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'dataType'
                NSString *dataType = (NSString *)[QredoPrimitiveMarshallers stringUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'summaryValues'
                NSSet *summaryValues = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFIndexable unmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFVaultItemMetaDataLF vaultItemMetaDataLFWithDataType:dataType accessLevel:accessLevel summaryValues:summaryValues];
    };
}

- (instancetype)initWithDataType:(NSString *)dataType accessLevel:(int32_t)accessLevel summaryValues:(NSSet *)summaryValues
{

    self = [super init];
    if (self) {
        _dataType = dataType;
        _accessLevel = accessLevel;
        _summaryValues = summaryValues;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFVaultItemMetaDataLF *)other
{

    QREDO_COMPARE_OBJECT(dataType);
    QREDO_COMPARE_SCALAR(accessLevel);
    QREDO_COMPARE_OBJECT(summaryValues);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToVaultItemMetaDataLF:other];
       
}

- (BOOL)isEqualToVaultItemMetaDataLF:(QLFVaultItemMetaDataLF *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_dataType != other.dataType && ![_dataType isEqual:other.dataType])
        return NO;
    if (_accessLevel != other.accessLevel)
        return NO;
    if (_summaryValues != other.summaryValues && ![_summaryValues isEqual:other.summaryValues])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_dataType hash];
    hash = hash * 31u + _accessLevel;
    hash = hash * 31u + [_summaryValues hash];
    return hash;
       
}

@end

@implementation QLFVaultItemLF



+ (QLFVaultItemLF *)vaultItemLFWithMetadata:(QLFVaultItemMetaDataLF *)metadata value:(NSData *)value
{

    return [[QLFVaultItemLF alloc] initWithMetadata:metadata value:value];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFVaultItemLF *e = (QLFVaultItemLF *)element;
        [writer writeConstructorStartWithObjectName:@"VaultItemLF"];
            [writer writeFieldStartWithFieldName:@"metadata"];
                [QLFVaultItemMetaDataLF marshaller]([e metadata], writer);
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
        [reader readConstructorStart];// TODO assert that constructor name is 'VaultItemLF'
            [reader readFieldStart]; // TODO assert that field name is 'metadata'
                QLFVaultItemMetaDataLF *metadata = (QLFVaultItemMetaDataLF *)[QLFVaultItemMetaDataLF unmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'value'
                NSData *value = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFVaultItemLF vaultItemLFWithMetadata:metadata value:value];
    };
}

- (instancetype)initWithMetadata:(QLFVaultItemMetaDataLF *)metadata value:(NSData *)value
{

    self = [super init];
    if (self) {
        _metadata = metadata;
        _value = value;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFVaultItemLF *)other
{

    QREDO_COMPARE_OBJECT(metadata);
    QREDO_COMPARE_OBJECT(value);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToVaultItemLF:other];
       
}

- (BOOL)isEqualToVaultItemLF:(QLFVaultItemLF *)other
{

    if (other == self)
        return YES;
    if (!other || ![other.class isEqual:self.class])
        return NO;
    if (_metadata != other.metadata && ![_metadata isEqual:other.metadata])
        return NO;
    if (_value != other.value && ![_value isEqual:other.value])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_metadata hash];
    hash = hash * 31u + [_value hash];
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
    hash = hash * 31u + _maxAccessLevel;
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
    hash = hash * 31u + _accessLevel;
    hash = hash * 31u + _credentialType;
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
    hash = hash * 31u + _credentialType;
    hash = hash * 31u + [_operatorInfo hash];
    hash = hash * 31u + [_vaultInfo hash];
    hash = hash * 31u + [_encryptedRecoveryInfo hash];
    return hash;
       
}

@end

@implementation QLFEncryptedVaultItemMetaData



+ (QLFEncryptedVaultItemMetaData *)encryptedVaultItemMetaDataWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QLFVaultItemId *)itemId encryptedHeaders:(NSData *)encryptedHeaders
{

    return [[QLFEncryptedVaultItemMetaData alloc] initWithVaultId:vaultId sequenceId:sequenceId sequenceValue:sequenceValue itemId:itemId encryptedHeaders:encryptedHeaders];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFEncryptedVaultItemMetaData *e = (QLFEncryptedVaultItemMetaData *)element;
        [writer writeConstructorStartWithObjectName:@"EncryptedVaultItemMetaData"];
            [writer writeFieldStartWithFieldName:@"encryptedHeaders"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e encryptedHeaders], writer);
            [writer writeEnd];

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
        [reader readConstructorStart];// TODO assert that constructor name is 'EncryptedVaultItemMetaData'
            [reader readFieldStart]; // TODO assert that field name is 'encryptedHeaders'
                NSData *encryptedHeaders = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
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
        return [QLFEncryptedVaultItemMetaData encryptedVaultItemMetaDataWithVaultId:vaultId sequenceId:sequenceId sequenceValue:sequenceValue itemId:itemId encryptedHeaders:encryptedHeaders];
    };
}

- (instancetype)initWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QLFVaultItemId *)itemId encryptedHeaders:(NSData *)encryptedHeaders
{

    self = [super init];
    if (self) {
        _vaultId = vaultId;
        _sequenceId = sequenceId;
        _sequenceValue = sequenceValue;
        _itemId = itemId;
        _encryptedHeaders = encryptedHeaders;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFEncryptedVaultItemMetaData *)other
{

    QREDO_COMPARE_OBJECT(vaultId);
    QREDO_COMPARE_OBJECT(sequenceId);
    QREDO_COMPARE_SCALAR(sequenceValue);
    QREDO_COMPARE_OBJECT(itemId);
    QREDO_COMPARE_OBJECT(encryptedHeaders);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToEncryptedVaultItemMetaData:other];
       
}

- (BOOL)isEqualToEncryptedVaultItemMetaData:(QLFEncryptedVaultItemMetaData *)other
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
    if (_encryptedHeaders != other.encryptedHeaders && ![_encryptedHeaders isEqual:other.encryptedHeaders])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_vaultId hash];
    hash = hash * 31u + [_sequenceId hash];
    hash = hash * 31u + _sequenceValue;
    hash = hash * 31u + [_itemId hash];
    hash = hash * 31u + [_encryptedHeaders hash];
    return hash;
       
}

@end

@implementation QLFEncryptedVaultItem



+ (QLFEncryptedVaultItem *)encryptedVaultItemWithMeta:(QLFEncryptedVaultItemMetaData *)meta encryptedValue:(NSData *)encryptedValue
{

    return [[QLFEncryptedVaultItem alloc] initWithMeta:meta encryptedValue:encryptedValue];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFEncryptedVaultItem *e = (QLFEncryptedVaultItem *)element;
        [writer writeConstructorStartWithObjectName:@"EncryptedVaultItem"];
            [writer writeFieldStartWithFieldName:@"encryptedValue"];
                [QredoPrimitiveMarshallers byteSequenceMarshaller]([e encryptedValue], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"meta"];
                [QLFEncryptedVaultItemMetaData marshaller]([e meta], writer);
            [writer writeEnd];

        [writer writeEnd];
    };
}

+ (QredoUnmarshaller)unmarshaller
{
    return ^id(QredoWireFormatReader *reader) {
        [reader readConstructorStart];// TODO assert that constructor name is 'EncryptedVaultItem'
            [reader readFieldStart]; // TODO assert that field name is 'encryptedValue'
                NSData *encryptedValue = (NSData *)[QredoPrimitiveMarshallers byteSequenceUnmarshaller](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'meta'
                QLFEncryptedVaultItemMetaData *meta = (QLFEncryptedVaultItemMetaData *)[QLFEncryptedVaultItemMetaData unmarshaller](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFEncryptedVaultItem encryptedVaultItemWithMeta:meta encryptedValue:encryptedValue];
    };
}

- (instancetype)initWithMeta:(QLFEncryptedVaultItemMetaData *)meta encryptedValue:(NSData *)encryptedValue
{

    self = [super init];
    if (self) {
        _meta = meta;
        _encryptedValue = encryptedValue;
    }
    return self;
       
}

- (NSComparisonResult)compare:(QLFEncryptedVaultItem *)other
{

    QREDO_COMPARE_OBJECT(meta);
    QREDO_COMPARE_OBJECT(encryptedValue);
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
    if (_meta != other.meta && ![_meta isEqual:other.meta])
        return NO;
    if (_encryptedValue != other.encryptedValue && ![_encryptedValue isEqual:other.encryptedValue])
        return NO;
    return YES;
       
}

- (NSUInteger)hash
{

    NSUInteger hash = 0;
    hash = hash * 31u + [_meta hash];
    hash = hash * 31u + [_encryptedValue hash];
    return hash;
       
}

@end

@implementation QLFVaultItemDescriptorLF



+ (QLFVaultItemDescriptorLF *)vaultItemDescriptorLFWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(QLFVaultSequenceValue)sequenceValue itemId:(QLFVaultItemId *)itemId
{

    return [[QLFVaultItemDescriptorLF alloc] initWithVaultId:vaultId sequenceId:sequenceId sequenceValue:sequenceValue itemId:itemId];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFVaultItemDescriptorLF *e = (QLFVaultItemDescriptorLF *)element;
        [writer writeConstructorStartWithObjectName:@"VaultItemDescriptorLF"];
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
        [reader readConstructorStart];// TODO assert that constructor name is 'VaultItemDescriptorLF'
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
        return [QLFVaultItemDescriptorLF vaultItemDescriptorLFWithVaultId:vaultId sequenceId:sequenceId sequenceValue:sequenceValue itemId:itemId];
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

- (NSComparisonResult)compare:(QLFVaultItemDescriptorLF *)other
{

    QREDO_COMPARE_OBJECT(vaultId);
    QREDO_COMPARE_OBJECT(sequenceId);
    QREDO_COMPARE_SCALAR(sequenceValue);
    QREDO_COMPARE_OBJECT(itemId);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToVaultItemDescriptorLF:other];
       
}

- (BOOL)isEqualToVaultItemDescriptorLF:(QLFVaultItemDescriptorLF *)other
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
    hash = hash * 31u + _sequenceValue;
    hash = hash * 31u + [_itemId hash];
    return hash;
       
}

@end

@implementation QLFVaultItemMetaDataResults



+ (QLFVaultItemMetaDataResults *)vaultItemMetaDataResultsWithResults:(NSArray *)results current:(BOOL)current sequenceIds:(NSSet *)sequenceIds
{

    return [[QLFVaultItemMetaDataResults alloc] initWithResults:results current:current sequenceIds:sequenceIds];
       
}

+ (QredoMarshaller)marshaller
{
    return ^(id element, QredoWireFormatWriter *writer) {
        QLFVaultItemMetaDataResults *e = (QLFVaultItemMetaDataResults *)element;
        [writer writeConstructorStartWithObjectName:@"VaultItemMetaDataResults"];
            [writer writeFieldStartWithFieldName:@"current"];
                [QredoPrimitiveMarshallers booleanMarshaller]([NSNumber numberWithBool: [e current]], writer);
            [writer writeEnd];

            [writer writeFieldStartWithFieldName:@"results"];
                [QredoPrimitiveMarshallers sequenceMarshallerWithElementMarshaller:[QLFEncryptedVaultItemMetaData marshaller]]([e results], writer);
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
        [reader readConstructorStart];// TODO assert that constructor name is 'VaultItemMetaDataResults'
            [reader readFieldStart]; // TODO assert that field name is 'current'
                BOOL current = (BOOL )[[QredoPrimitiveMarshallers booleanUnmarshaller](reader) boolValue];
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'results'
                NSArray *results = (NSArray *)[QredoPrimitiveMarshallers sequenceUnmarshallerWithElementUnmarshaller:[QLFEncryptedVaultItemMetaData unmarshaller]](reader);
            [reader readEnd];
            [reader readFieldStart]; // TODO assert that field name is 'sequenceIds'
                NSSet *sequenceIds = (NSSet *)[QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QredoPrimitiveMarshallers quidUnmarshaller]](reader);
            [reader readEnd];
        [reader readEnd];
        return [QLFVaultItemMetaDataResults vaultItemMetaDataResultsWithResults:results current:current sequenceIds:sequenceIds];
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

- (NSComparisonResult)compare:(QLFVaultItemMetaDataResults *)other
{

    QREDO_COMPARE_OBJECT(results);
    QREDO_COMPARE_SCALAR(current);
    QREDO_COMPARE_OBJECT(sequenceIds);
    return NSOrderedSame;
       
}

- (BOOL)isEqualTo:(id)other
{

    return [self isEqualToVaultItemMetaDataResults:other];
       
}

- (BOOL)isEqualToVaultItemMetaDataResults:(QLFVaultItemMetaDataResults *)other
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
    hash = hash * 31u + _current;
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
    hash = hash * 31u + _sequenceValue;
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

- (void)publishWithQueueId:(QLFConversationQueueId *)queueId item:(QLFConversationItem *)item signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFConversationPublishResult *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Conversations"
               operation:@"publish"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](queueId, writer);
                  [QredoPrimitiveMarshallers byteSequenceMarshaller](item, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFConversationPublishResult *result = [QLFConversationPublishResult unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }];
         
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
            }];
         
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
            }];
         
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
            }];
         
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
                 completionHandler(nil, error);
            }];
         
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
            }];
         
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
            }];
         
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
            }];
         
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
            }];
         
}

- (void)deleteWithHashedTag:(QLFRendezvousHashedTag *)hashedTag signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFRendezvousDeleteResult *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Rendezvous"
               operation:@"delete"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](hashedTag, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFRendezvousDeleteResult *result = [QLFRendezvousDeleteResult unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }];
         
}

@end

@implementation QLFAccess

{
QredoServiceInvoker *_invoker;
}

+ (QLFAccess *)accessWithServiceInvoker:(QredoServiceInvoker *)serviceInvoker
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

- (void)getKeySlotsWithCompletionHandler:(void(^)(QLFGetKeySlotsResponse *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Access"
               operation:@"getKeySlots"
           requestWriter:^(QredoWireFormatWriter *writer) {

           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFGetKeySlotsResponse *result = [QLFGetKeySlotsResponse unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }];
         
}

- (void)getAccessTokenWithAccountId:(QLFAccountId *)accountId accountCredential:(QLFAccountCredential *)accountCredential blindedToken:(QLFBlindedToken *)blindedToken slotNumber:(QLFKeySlotNumber)slotNumber completionHandler:(void(^)(QLFGetAccessTokenResponse *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Access"
               operation:@"getAccessToken"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers stringMarshaller](accountId, writer);
                  [QredoPrimitiveMarshallers stringMarshaller](accountCredential, writer);
                  [QredoPrimitiveMarshallers byteSequenceMarshaller](blindedToken, writer);
                  [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: slotNumber], writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFGetAccessTokenResponse *result = [QLFGetAccessTokenResponse unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }];
         
}

- (void)getNextAccessTokenWithAccountId:(QLFAccountId *)accountId accountCredential:(QLFAccountCredential *)accountCredential blindedToken:(QLFBlindedToken *)blindedToken slotNumber:(QLFKeySlotNumber)slotNumber completionHandler:(void(^)(QLFGetAccessTokenResponse *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Access"
               operation:@"getNextAccessToken"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers stringMarshaller](accountId, writer);
                  [QredoPrimitiveMarshallers stringMarshaller](accountCredential, writer);
                  [QredoPrimitiveMarshallers byteSequenceMarshaller](blindedToken, writer);
                  [QredoPrimitiveMarshallers int32Marshaller]([NSNumber numberWithLong: slotNumber], writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFGetAccessTokenResponse *result = [QLFGetAccessTokenResponse unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }];
         
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
                 completionHandler(nil, error);
            }];
         
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
            }];
         
}

- (void)getItemMetaDataWithVaultId:(QLFVaultId *)vaultId sequenceId:(QLFVaultSequenceId *)sequenceId sequenceValue:(NSSet *)sequenceValue itemId:(QLFVaultItemId *)itemId signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(NSSet *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Vault"
               operation:@"getItemMetaData"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](vaultId, writer);
                  [QredoPrimitiveMarshallers quidMarshaller](sequenceId, writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QredoPrimitiveMarshallers int64Marshaller]](sequenceValue, writer);
                  [QredoPrimitiveMarshallers quidMarshaller](itemId, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               NSSet *result = [QredoPrimitiveMarshallers setUnmarshallerWithElementUnmarshaller:[QLFEncryptedVaultItemMetaData unmarshaller]](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }];
         
}

- (void)queryItemMetaDataWithVaultId:(QLFVaultId *)vaultId sequenceStates:(NSSet *)sequenceStates signature:(QLFOwnershipSignature *)signature completionHandler:(void(^)(QLFVaultItemMetaDataResults *result, NSError *error))completionHandler
{

 [_invoker invokeService:@"Vault"
               operation:@"queryItemMetaData"
           requestWriter:^(QredoWireFormatWriter *writer) {
                  [QredoPrimitiveMarshallers quidMarshaller](vaultId, writer);
                  [QredoPrimitiveMarshallers setMarshallerWithElementMarshaller:[QLFVaultSequenceState marshaller]](sequenceStates, writer);
                  [QLFOwnershipSignature marshaller](signature, writer);
           }
          responseReader:^(QredoWireFormatReader *reader) {
               QLFVaultItemMetaDataResults *result = [QLFVaultItemMetaDataResults unmarshaller](reader);
               completionHandler(result, nil);
          }
            errorHandler:^(NSError *error) {
                 completionHandler(nil, error);
            }];
         
}

@end

#pragma clang diagnostic pop
