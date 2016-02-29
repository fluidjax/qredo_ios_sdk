/*
 *  Copyright (c) 2011-2015 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */



#import "_QredoIndexVaultItemMetaData.h"

@class QredoVaultItemMetadata;
@class QredoVaultItemDescriptor;

@interface QredoIndexVaultItemMetadata : _QredoIndexVaultItemMetadata {}

+(instancetype)createWithMetadata:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;

-(QredoVaultItemMetadata *)buildQredoVaultItemMetadata;
-(BOOL)hasSameSequenceIdAs:(QredoVaultItemMetadata*)metadata;
-(BOOL)hasSmallerSequenceNumberThan:(QredoVaultItemMetadata*)metadata;
-(BOOL)hasCreatedTimeStampBefore:(QredoVaultItemMetadata*)metadata;
-(BOOL)hasSameSequenceNumberAs:(QredoVaultItemMetadata*)metadata;
@end
