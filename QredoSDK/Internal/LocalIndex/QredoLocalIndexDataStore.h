/*
 *  Copyright (c) 2011-2015 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
@import CoreData;

@interface QredoLocalIndexDataStore :NSObject

@property (strong, readonly) NSManagedObjectContext *managedObjectContext;

+ (id)sharedQredoLocalIndexDataStore;
- (void)saveContext:(BOOL)wait;
- (long)persistentStoreFileSize;


/** Delete the coredata sqllite database, and rebuild the coredata stack 
    This ensures a clean start point, useful for errors and tests
    Use before any QredoClients are created
 */
- (void)deleteStore;

@end
