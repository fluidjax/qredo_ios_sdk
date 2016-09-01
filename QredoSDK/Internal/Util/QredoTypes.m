/* HEADER GOES HERE */
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
        
        self.vaultItemDescriptor
        = [QredoVaultItemDescriptor vaultItemDescriptorWithSequenceId:vaultItemRef.sequenceId
                                                               itemId:vaultItemRef.itemId];
        
        self.data = data;
        
        return self;
    } @catch (NSException *exception){
        return nil;
    }
}

-(instancetype)initWithVaultItemDescriptor:(QredoVaultItemDescriptor *)vaultItemDescriptor vault:(QredoVault *)vault {
    NSAssert(vaultItemDescriptor,@"Vault item descriptor can't be nil");
    self = [super init];
    
    if (!self)return nil;
    
    QLFVaultItemRef *vaultItemRef = [QLFVaultItemRef vaultItemRefWithVaultId:vault.vaultId
                                                                  sequenceId:vaultItemDescriptor.sequenceId
                                                               sequenceValue:vaultItemDescriptor.sequenceValue
                                                                      itemId:vaultItemDescriptor.itemId];
    
    self.vaultItemDescriptor = vaultItemDescriptor;
    
    self.data = [QredoPrimitiveMarshallers marshalObject:vaultItemRef includeHeader:YES];
    
    return self;
}

@end