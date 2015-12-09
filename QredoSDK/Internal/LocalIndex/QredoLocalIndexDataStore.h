//
//  QredoLocalIndexDataStore.h
//  QredoSDK
//
//  Created by Christopher Morris on 09/12/2015.
//
//

#import <Foundation/Foundation.h>
@import CoreData;

@interface QredoLocalIndexDataStore : NSObject

@property (strong, readwrite) NSManagedObjectContext *managedObjectContext;

+(id)sharedQredoLocalIndexDataStore;
-(BOOL)save;

@end
