/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "_QredoIndexVault.h"
@class QredoVault;

@interface QredoIndexVault :_QredoIndexVault {}

+(QredoIndexVault *)fetchOrCreateWith:(QredoVault *)vault inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
