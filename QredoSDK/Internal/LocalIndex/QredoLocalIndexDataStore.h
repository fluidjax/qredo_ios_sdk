/*
 *  Copyright (c) 2011-2015 Qredo Ltd.  Strictly confidential.  All rights reserved.
 */

#import <Foundation/Foundation.h>
@import CoreData;

@interface QredoLocalIndexDataStore : NSObject

@property (strong, readonly) NSManagedObjectContext *managedObjectContext;

+(id)sharedQredoLocalIndexDataStore;
-(void)saveContext:(BOOL)wait;

@end
