#import "_QredoIndexSummaryValues.h"

@interface QredoIndexSummaryValues : _QredoIndexSummaryValues {}


+(NSSet*)createSetWith:(NSDictionary *)summaryValues inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
