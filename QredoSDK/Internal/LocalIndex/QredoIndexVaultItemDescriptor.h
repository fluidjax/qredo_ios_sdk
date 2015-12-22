/*
 *  Copyright (c) 2011-2015 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */


#import "_QredoIndexVaultItemDescriptor.h"

@class QredoVaultItemDescriptor;

@interface QredoIndexVaultItemDescriptor : _QredoIndexVaultItemDescriptor {}

+(instancetype)createWithDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;
+(instancetype)searchForDescriptor:(QredoVaultItemDescriptor *)descriptor inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;

-(QredoVaultItemDescriptor *)buildQredoVaultItemDescriptor;

@end
