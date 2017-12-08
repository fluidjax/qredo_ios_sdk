/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoTypes.h"
#import "QredoClient.h"
#import "Qredo.h"
#import "QredoTypesPrivate.h"
#import "QredoVaultPrivate.h"

@implementation QredoObjectRef

-(instancetype)initWithData:(NSData *)data {
    NSAssert(data,@"Data can't be nil");
    self = [super init];
    
    if (!self)return nil;
    
    @try {
        QLFVaultItemRef *vaultItemRef =
        [QredoPrimitiveMarshallers unmarshalObject:data
                                      unmarshaller:[QLFVaultItemRef unmarshaller]
                                       parseHeader:YES];
        
        _vaultItemDescriptor  = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vaultItemRef.sequenceId
                                                                                     itemId:vaultItemRef.itemId];
        
        _data = data;
        
        return self;
    } @catch (NSException *exception){
        return nil;
    }
}



-(NSData *)dataUsingEncoding:(NSStringEncoding)encoding{
   
    return nil;
}



- (NSString*)serializedString{
    NSData *data = [self data];
    return [data base64EncodedStringWithOptions:0];
}


-(instancetype)initWithSerializedString:(NSString*)string{
    NSAssert(string,@"String can't be nil");
    self = [super init];
    if (!self)return nil;
    NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:0];
    
    @try {
        QLFVaultItemRef *vaultItemRef =
        [QredoPrimitiveMarshallers unmarshalObject:data
                                      unmarshaller:[QLFVaultItemRef unmarshaller]
                                       parseHeader:YES];
        
        
        _vaultItemDescriptor  = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vaultItemRef.sequenceId
                                                                              sequenceValue:vaultItemRef.sequenceValue
                                                                                     itemId:vaultItemRef.itemId];
        
        _data = data;
        
        return self;
    } @catch (NSException *exception){
        return nil;
    }
}




-(BOOL)isEqual:(id)object{
    if (object==nil)return false;
    if ([object class]!=[self class])return false;
    
    QredoObjectRef *obRef = (QredoObjectRef*)object;
    
    return [self.vaultItemDescriptor isEqual:obRef.vaultItemDescriptor];
}



-(instancetype)initWithVaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor vault:(QredoVault *)vault {
    NSAssert(vaultItemDescriptor,@"Vault item descriptor can't be nil");
    self = [super init];
    
    if (!self)return nil;
    
    QLFVaultItemRef *vaultItemRef = [QLFVaultItemRef vaultItemRefWithVaultId:vault.vaultId
                                                                  sequenceId:vaultItemDescriptor.sequenceId
                                                               sequenceValue:vaultItemDescriptor.sequenceValue
                                                                      itemId:vaultItemDescriptor.itemId];
    
    _vaultItemDescriptor = vaultItemDescriptor;
    
    _data = [QredoPrimitiveMarshallers marshalObject:vaultItemRef includeHeader:YES];
    
    return self;
}






@end
