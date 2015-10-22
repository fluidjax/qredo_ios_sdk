#import "QredoDateTime.h"
#import "QredoHelpers.h"

@implementation QredoDate : NSObject

+ (instancetype)dateWithYear:(NSUInteger)year month:(NSUInteger)month day:(NSUInteger)day {
    return [[self alloc] initWithYear:year month:month day:day];
}

+ (instancetype)dateWithDate:(NSDate *)date {
    return [[self alloc] initWithDate:date];
}

+ (instancetype)dateWithDateComponents:(NSDateComponents *)dateComponents {
    return [[self alloc] initWithDateComponents:dateComponents];
}

- (instancetype)initWithYear:(NSUInteger)year month:(NSUInteger)month day:(NSUInteger)day {
    self = [super init];
    _year  = year;
    _month = month;
    _day   = day;
    return self;
}

- (instancetype)initWithDate:(NSDate *)date {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [gregorian components:(NSCalendarUnitYear
                                                              | NSCalendarUnitMonth
                                                              | NSCalendarUnitDay)
                 fromDate:date];
    return [self initWithDateComponents:dateComponents];
}

- (instancetype)initWithDateComponents:(NSDateComponents *)dateComponents {
    self = [super init];
    _year  = [dateComponents year];
    _month = [dateComponents month];
    _day   = [dateComponents day];
    return self;
}

- (NSComparisonResult)compare:(QredoDate *)other {
    QREDO_COMPARE_SCALAR(year);
    QREDO_COMPARE_SCALAR(month);
    QREDO_COMPARE_SCALAR(day);
    return NSOrderedSame;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToDate:other];
}

- (BOOL)isEqualToDate:(QredoDate *)date {
    if (self == date)
        return YES;
    if (date == nil)
        return NO;
    if (self.year == date.year && self.month == date.month && self.day != date.day)
        return YES;
    return NO;
}

- (NSUInteger)hash {
    NSUInteger hash = (self.year & 4095) << 10;
    hash += (self.month & 31) << 5;
    hash += self.day & 31;
    return hash;
}


@end

@implementation QredoTime : NSObject

const int MILLIS_PER_SECOND = 1000;
const int MILLIS_PER_MINUTE = MILLIS_PER_SECOND * 60;
const int MILLIS_PER_HOUR   = MILLIS_PER_MINUTE * 60;

+ (instancetype)timeWithHour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second {
    return [[self alloc] initWithHour:hour minute:minute second:second];
}

+ (instancetype)timeWithMillisSinceMidnight:(NSUInteger)millisSinceMidnight {
    return [[self alloc] initWithMillisSinceMidnight:millisSinceMidnight];
}

+ (instancetype)timeWithDate:(NSDate *)date {
    return [[self alloc] initWithDate:date];
}

+ (instancetype)timeWithDateComponents:(NSDateComponents *)dateComponents {
    return [[self alloc] initWithDateComponents:dateComponents];
}

- (instancetype)initWithMillisSinceMidnight:(NSUInteger)millisSinceMidnight {
    
    self = [super init];
    
    _millisSinceMidnight = millisSinceMidnight;
    uint32_t timeMillis  = (uint32_t)millisSinceMidnight;
    uint32_t  hour   = timeMillis / MILLIS_PER_HOUR;
    timeMillis -= hour * MILLIS_PER_HOUR;
    uint32_t  minute = timeMillis / MILLIS_PER_MINUTE;
    timeMillis -= minute * MILLIS_PER_MINUTE;
    uint32_t  second = timeMillis / MILLIS_PER_SECOND;
    timeMillis -= second * MILLIS_PER_SECOND;
    uint32_t milli  = timeMillis;

    _hour   = hour;
    _minute = minute;
    _second = second;
    _milli  = milli;
    
    return self;
    
}

- (instancetype)initWithHour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second {
    NSDateComponents *dateComponents = [NSDateComponents new];
    [dateComponents setHour:hour];
    [dateComponents setMinute:minute];
    [dateComponents setSecond:second];
    return [self initWithDateComponents:dateComponents];
}

- (instancetype)initWithDate:(NSDate *)date {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [gregorian setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSDateComponents *dateComponents = [gregorian components:(NSCalendarUnitHour
                                                              | NSCalendarUnitMinute
                                                              | NSCalendarUnitSecond)
                                                    fromDate:date];
    return [self initWithDateComponents:dateComponents];
}

- (instancetype)initWithDateComponents:(NSDateComponents *)dateComponents {
    
    self = [super init];
    
    NSInteger hour   = [dateComponents hour];
    NSInteger minute = [dateComponents minute];
    NSInteger second = [dateComponents second];
    NSInteger milli  = 0;
    NSInteger millisSinceMidnight = (hour * MILLIS_PER_HOUR) + (minute * MILLIS_PER_MINUTE) + (second * MILLIS_PER_SECOND);
    
    _millisSinceMidnight = millisSinceMidnight;
    _hour   = hour;
    _minute = minute;
    _second = second;
    _milli  = milli;
    
    return self;
    
}

- (NSComparisonResult)compare:(QredoTime *)other {
    QREDO_COMPARE_SCALAR(hour);
    QREDO_COMPARE_SCALAR(minute);
    QREDO_COMPARE_SCALAR(second);
    QREDO_COMPARE_SCALAR(milli);
    return NSOrderedSame;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToTime:other];
}

- (BOOL)isEqualToTime:(QredoTime *)time {
    if (self == time)
        return YES;
    if (time == nil)
        return NO;
    
    if (_millisSinceMidnight == time.millisSinceMidnight &&
        _hour == time.hour &&
        _minute == time.minute &&
        _second == time.second &&
        _milli == time.milli)
        return YES;
    return NO;
}

- (NSUInteger)hash {
    // TODO: review. this impl is probably wrong. inital version was using [NSNumber hash], however, that might not be good either
    NSUInteger hash = self.millisSinceMidnight;
    hash = hash * 31u + self.hour;
    hash = hash * 31u + self.minute;
    hash = hash * 31u + self.second;
    hash = hash * 31u + self.milli;
    return hash;
}


@end

@implementation QredoDateTime : NSObject

+ (instancetype)dateTimeWithDate:(QredoDate *)date time:(QredoTime *)time isUTC:(bool)isUTC {
    if (isUTC) {
        return [[QredoUTCDateTime alloc] initWithDate:date time:time];
    } else {
        return [[QredoLocalDateTime alloc] initWithDate:date time:time];
    }
}

+ (instancetype)dateTimeWithDate:(NSDate *)date isUTC:(bool)isUTC {
    if (isUTC) {
        return [[QredoUTCDateTime alloc] initWithDate:date];
    } else {
        return [[QredoLocalDateTime alloc] initWithDate:date];
    }
}

+ (instancetype)dateTimeWithDateComponents:(NSDateComponents *)dateComponents {
    bool isUTC = [[dateComponents timeZone] isEqualToTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    if (isUTC) {
        return [[QredoUTCDateTime alloc] initWithDateComponents:dateComponents];
    } else {
        return [[QredoLocalDateTime alloc] initWithDateComponents:dateComponents];
    }
}

- (instancetype)initWithDate:(QredoDate *)date time:(QredoTime *)time {
    self = [super init];
    _date = date;
    _time = time;
    return self;
}

- (instancetype)initWithDate:(NSDate *)date {
    self = [super init];
    _date = [QredoDate dateWithDate:date];
    _time = [QredoTime timeWithDate:date];
    return self;
}

- (instancetype)initWithDateComponents:(NSDateComponents *)dateComponents {
    self = [super init];
    _date = [QredoDate dateWithDateComponents:dateComponents];
    _time = [QredoTime timeWithDateComponents:dateComponents];
    return self;
}

- (NSDate *)asDateInTimezone:(NSTimeZone *)timeZone {
    
    NSDateComponents *dateComponents = [NSDateComponents new];
    [dateComponents     setYear:_date.year];
    [dateComponents    setMonth:_date.month];
    [dateComponents      setDay:_date.day];
    [dateComponents     setHour:_time.hour];
    [dateComponents   setMinute:_time.minute];
    [dateComponents   setSecond:_time.second];
    [dateComponents setTimeZone:timeZone];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    return [calendar dateFromComponents:dateComponents];
    
}

- (NSComparisonResult)compare:(QredoDateTime *)object {
    QREDO_COMPARE_SCALAR2(_date.year, object.date.year);
    QREDO_COMPARE_SCALAR2(_date.month, object.date.month);
    QREDO_COMPARE_SCALAR2(_date.day, object.date.day);

    
    QREDO_COMPARE_SCALAR2(_time.hour, object.time.hour);
    QREDO_COMPARE_SCALAR2(_time.minute, object.time.minute);
    QREDO_COMPARE_SCALAR2(_time.second, object.time.second);
    QREDO_COMPARE_SCALAR2(_time.milli, object.time.milli);
    return NSOrderedSame;

}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToTime:other];
}

- (BOOL)isEqualToTime:(QredoDateTime *)time {
    if (self == time)
        return YES;
    if (time == nil)
        return NO;
    if (self.date != time.date && ![self.date isEqualToDate:time.date])
        return NO;
    if (self.time != time.time && ![self.time isEqualToTime:time.time])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.date hash];
    hash = hash * 31u + [self.time hash];
    return hash;
}

@end

@implementation QredoLocalDateTime : QredoDateTime

@end

@implementation QredoUTCDateTime : QredoDateTime

- (NSDate *)asDate {
    return [super asDateInTimezone:[NSTimeZone timeZoneWithName:@"UTC"]];
}


@end