/*  Qredo Ltd - iOS SDK
    Copyright 2014-2017 Qredo Ltd.
    
    See file: LICENSE
*/


#import "QredoIndexSummaryValues.h"
#import "QredoIndexVariableValue.h"
#import "QredoQUID.h"
#import "QredoQUIDPrivate.h"
#import "QredoConversation.h"
#import "QredoTypes.h"

@interface QredoIndexSummaryValues ()
@end

@implementation QredoIndexSummaryValues


//Possible values are   string -> string | NSNumber | QredoQUID | NSDate


+(instancetype)createWithKey:(NSString *)key value:(NSObject *)value inManageObjectContext:(NSManagedObjectContext *)managedObjectContext {
    QredoIndexSummaryValues *qredoIndexSummaryValues = [[self class] insertInManagedObjectContext:managedObjectContext];
    
    qredoIndexSummaryValues.key = key;
    [qredoIndexSummaryValues assignValue:value];
    return qredoIndexSummaryValues;
}


-(void)assignValue:(NSObject *)value {
    QredoIndexVariableValue *qredoVariableValue = [QredoIndexVariableValue insertInManagedObjectContext:self.managedObjectContext];
    
    self.value = qredoVariableValue;
    
    if ([value isKindOfClass:[NSString class]]){
        qredoVariableValue.string = (NSString *)value;
        self.valueTypeValue = IndexSummaryValueDataType_NSString;
    } else if ([value isKindOfClass:[NSNumber class]]){
        qredoVariableValue.number = (NSNumber *)value;
        self.valueTypeValue = IndexSummaryValueDataType_NSNumber;
    } else if ([value isKindOfClass:[QredoQUID class]]){
        qredoVariableValue.qredoQUID = [(QredoQUID *)value data];
        self.valueTypeValue = IndexSummaryValueDataType_QredoQUID;
    } else if ([value isKindOfClass:[NSDate class]]){
        qredoVariableValue.date = (NSDate *)value;
        self.valueTypeValue = IndexSummaryValueDataType_NSDate;
    } else {
        @throw [NSException exceptionWithName:@"Invalid Type" reason:@"Unknown type in summaryValues value" userInfo:nil];
    }
}


-(NSObject *)retrieveValue {
    switch (self.valueTypeValue){
        case IndexSummaryValueDataType_NSString:
            return self.value.string;
            
            break;
            
        case IndexSummaryValueDataType_NSNumber:
            return self.value.number;
            
            break;
            
        case IndexSummaryValueDataType_QredoQUID:
            return [QredoQUID QUIDWithData:self.value.qredoQUID];
            
            break;
            
        case IndexSummaryValueDataType_NSDate:
            return self.value.date;
            
            break;
            
        default:
            @throw [NSException exceptionWithName:@"Invalid Type" reason:@"Unknown type retrieving value from index" userInfo:nil];
    }
}


@end
