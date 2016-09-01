/* HEADER GOES HERE */
#import <Foundation/Foundation.h>
#import <stdint.h>

@interface QredoDate : NSObject

@property (readonly) NSUInteger year;
@property (readonly) NSUInteger month;
@property (readonly) NSUInteger day;

+ (instancetype)dateWithYear:(NSUInteger)year month:(NSUInteger)month day:(NSUInteger)day;
+ (instancetype)dateWithDate:(NSDate *)date;
+ (instancetype)dateWithDateComponents:(NSDateComponents *)dateComponents;

- (instancetype)initWithYear:(NSUInteger)year month:(NSUInteger)month day:(NSUInteger)day;
- (instancetype)initWithDate:(NSDate *)date;
- (instancetype)initWithDateComponents:(NSDateComponents *)dateComponents;

- (NSComparisonResult)compare:(QredoDate *)object;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToDate:(QredoDate *)date;
- (NSUInteger)hash;

@end

@interface QredoTime : NSObject

@property (readonly) NSUInteger  millisSinceMidnight;
@property (readonly) NSUInteger hour;
@property (readonly) NSUInteger minute;
@property (readonly) NSUInteger second;
@property (readonly) NSUInteger milli;

+ (instancetype)timeWithHour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second;
+ (instancetype)timeWithMillisSinceMidnight:(NSUInteger)millisSinceMidnight;
+ (instancetype)timeWithDate:(NSDate *)date;
+ (instancetype)timeWithDateComponents:(NSDateComponents *)dateComponents;

- (instancetype)initWithHour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second;
- (instancetype)initWithMillisSinceMidnight:(NSUInteger)millisSinceMidnight;
- (instancetype)initWithDate:(NSDate *)date;
- (instancetype)initWithDateComponents:(NSDateComponents *)dateComponents;

- (NSComparisonResult)compare:(QredoTime *)object;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToTime:(QredoTime *)time;
- (NSUInteger)hash;

@end

@interface QredoDateTime : NSObject

@property (readonly) QredoDate *date;
@property (readonly) QredoTime *time;

+ (instancetype)dateTimeWithDate:(QredoDate *)date time:(QredoTime *)time isUTC:(bool)isUTC;
+ (instancetype)dateTimeWithDate:(NSDate *)date isUTC:(bool)isUTC;
+ (instancetype)dateTimeWithDateComponents:(NSDateComponents *)dateComponents;

- (instancetype)initWithDate:(QredoDate *)date time:(QredoTime *)time;
- (instancetype)initWithDate:(NSDate *)date;
- (instancetype)initWithDateComponents:(NSDateComponents *)dateComponents;

- (NSDate *)asDateInTimezone:(NSTimeZone *)timeZone;

- (NSComparisonResult)compare:(QredoDateTime *)object;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToTime:(QredoDateTime *)time;
- (NSUInteger)hash;

@end

@interface QredoLocalDateTime : QredoDateTime

@end

@interface QredoUTCDateTime : QredoDateTime

- (NSDate *)asDate;

@end