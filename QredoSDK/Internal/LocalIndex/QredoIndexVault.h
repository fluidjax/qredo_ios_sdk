/*
 *  Copyright (c) 2011-2015 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import "_QredoIndexVault.h"
@class QredoVault;

@interface QredoIndexVault : _QredoIndexVault {}

+(QredoIndexVault *)fetchOrCreateWith:(QredoVault *)vault inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
