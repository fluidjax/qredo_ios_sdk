#import "QredoIndexVariableValue.h"

@interface QredoIndexVariableValue ()

@end

@implementation QredoIndexVariableValue

+(instancetype)createInManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    return [[self class] insertInManagedObjectContext:managedObjectContext];
}

@end
