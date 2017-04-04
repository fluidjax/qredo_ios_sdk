/* HEADER GOES HERE */
#import "_QredoIndexSummaryValues.h"

typedef NS_ENUM (NSInteger,IndexSummaryValueDataType) {
    IndexSummaryValueDataType_NSString   = 0,
    IndexSummaryValueDataType_NSNumber   = 1,
    IndexSummaryValueDataType_QredoQUID  = 2,
    IndexSummaryValueDataType_NSDate     = 3
};


@interface QredoIndexSummaryValues :_QredoIndexSummaryValues {}

+(instancetype)createWithKey:(NSObject *)key value:(NSObject *)value inManageObjectContext:(NSManagedObjectContext *)managedObjectContext;

-(NSObject *)retrieveValue;

@end
