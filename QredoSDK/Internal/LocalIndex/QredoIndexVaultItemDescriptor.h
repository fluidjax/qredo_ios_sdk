/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "_QredoIndexVaultItemDescriptor.h"

@class QredoVaultItemDescriptor;

@interface QredoIndexVaultItemDescriptor :_QredoIndexVaultItemDescriptor {}

+(instancetype)createWithDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
+(instancetype)searchForDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;

-(QredoVaultItemDescriptor *)buildQredoVaultItemDescriptor;

@end
