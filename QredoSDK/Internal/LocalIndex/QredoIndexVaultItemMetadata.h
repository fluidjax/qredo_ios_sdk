/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "_QredoIndexVaultItemMetadata.h"

@class QredoVaultItemMetadata;
@class QredoVaultItemDescriptor;

@interface QredoIndexVaultItemMetadata :_QredoIndexVaultItemMetadata {}

+(instancetype)createWithMetadata:(QredoVaultItemMetadata *)metadata inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;

-(QredoVaultItemMetadata *)buildQredoVaultItemMetadata;
-(BOOL)hasSameSequenceIdAs:(QredoVaultItemMetadata *)metadata;
-(BOOL)hasSmallerSequenceNumberThan:(QredoVaultItemMetadata *)metadata;
-(BOOL)hasCreatedTimeStampBefore:(QredoVaultItemMetadata *)metadata;
-(BOOL)hasSameSequenceNumberAs:(QredoVaultItemMetadata *)metadata;
@end
