#import "QredoIndexSummaryValues.h"
#import "QredoQUID.h"
@interface QredoIndexSummaryValues ()

// Private interface goes here.

@end

@implementation QredoIndexSummaryValues


// VALUES ARE:     string -> string | NSNumber | QredoQUID


+(instancetype)createWithKey:(NSString *)key value:(NSObject *)value inManageObjectContext:(NSManagedObjectContext *)managedObjectContext{
    QredoIndexSummaryValues *qredoIndexSummaryValues = [[self class] insertInManagedObjectContext:managedObjectContext];
    qredoIndexSummaryValues.key = key;
    [qredoIndexSummaryValues assignValue:value];
    
    return qredoIndexSummaryValues;
}


-(void)assignValue:(NSObject*)value{
    
    self.(date)value = nil;
    
    
    if ([value isKindOfClass:[NSString class]]){
        self.value = [(NSString*)value dataUsingEncoding:NSUTF8StringEncoding];
        self.valueTypeValue = IndexSummaryValueDataType_NSString;
        
    }else if ([value isKindOfClass:[NSNumber class]]){
       self.value = [NSKeyedArchiver archivedDataWithRootObject:value];
       self.valueTypeValue = IndexSummaryValueDataType_NSNumber;
        
    }else if ([value isKindOfClass:[NSString class]]){
        self.value = [(QredoQUID*)value data];
        self.valueTypeValue = IndexSummaryValueDataType_QredoQUID;

    }else if ([value isKindOfClass:[NSDate class]]){
        self.value = [NSKeyedArchiver archivedDataWithRootObject:value];
        self.valueTypeValue = IndexSummaryValueDataType_NSDate;
        
    }else{
         @throw [NSException exceptionWithName:@"Invalid Type" reason:@"Unknown type in summarydata value" userInfo:nil];
    }
}


-(NSObject*)retrieveValue{
    switch (self.valueTypeValue) {
        case IndexSummaryValueDataType_NSString:
            return [[NSString alloc] initWithData:self.value encoding:NSUTF8StringEncoding];
            break;
        case IndexSummaryValueDataType_NSNumber:
            return [NSKeyedUnarchiver unarchiveObjectWithData:self.value];
            break;
        case IndexSummaryValueDataType_QredoQUID:
            return [[QredoQUID alloc] initWithQUIDData:self.value];
            break;
        case IndexSummaryValueDataType_NSDate:
            return [NSKeyedUnarchiver unarchiveObjectWithData:self.value];
            break;
        default:
            @throw [NSException exceptionWithName:@"Invalid Type" reason:@"Unknown type retrieving value from index" userInfo:nil];
    }
}


@end
