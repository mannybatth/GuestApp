//
//  YKSDateHelper.m
//  yikes Hotel
//
//  Created by Roger on 4/29/14.
//  Copyright (c) 2014 Yamm Software Inc. All rights reserved.
//

#import "YKSDateHelper.h"

@interface YKSDateHelper ()

@property (nonatomic, strong) NSCalendar *calendar;

@end

@implementation YKSDateHelper

+ (YKSDateHelper *)sharedInstance {
    static YKSDateHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
        [_sharedInstance initDateFormatter];
        [_sharedInstance subscribeToNotifications];
    });
    return _sharedInstance;
}

- (void)initDateFormatter {
    
    _simpleDateFormatter = [[NSDateFormatter alloc] init];
    [_simpleDateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    _mediumDateFormatter = [[NSDateFormatter alloc] init];
    [self.mediumDateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [self.mediumDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    _simpleDateFormatterWithTime = [[NSDateFormatter alloc] init];
    [_simpleDateFormatterWithTime setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    _simpleDateFormatterWithTimeSSS = [[NSDateFormatter alloc] init];
    [_simpleDateFormatterWithTimeSSS setDateFormat:@"yyyy-MM-dd hh:mm:ss:sss"];
    
    _timeOnlyHHmmssDateFormatter = [[NSDateFormatter alloc] init];
    [_timeOnlyHHmmssDateFormatter setDateFormat:@"HH:mm:ss"];
    
    _timeOnlymmssDateFormatter = [[NSDateFormatter alloc] init];
    [_timeOnlymmssDateFormatter setDateFormat:@"mm:ss:sss"];
    
    [self setupDateFormatter];
}

//Called when time zone changed
- (void)setupDateFormatter {
    
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    
    self.mediumDateFormatter.timeZone = tz;
    self.simpleDateFormatter.timeZone = tz;
    self.simpleDateFormatterWithTime.timeZone = tz;
    self.simpleDateFormatterWithTimeSSS.timeZone = tz;
    self.timeOnlyHHmmssDateFormatter.timeZone = tz;
    self.timeOnlymmssDateFormatter.timeZone = tz;
    
    self.calendar = [NSCalendar currentCalendar];
    self.calendar.timeZone = tz;
}

- (void)subscribeToNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupDateFormatter) name:NSCurrentLocaleDidChangeNotification object:nil];
}


+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime {
    if (fromDateTime == nil || toDateTime == nil) {
        return NSNotFound;
    }
    
    NSDate *fromDate;
    NSDate *toDate;
    
    NSDate * adjustedFromDate = [fromDateTime dateByAddingTimeInterval:-3*3600];
    NSDate * adjustedToDate = [toDateTime dateByAddingTimeInterval:-3*3600];
    
    NSCalendar * calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                 interval:NULL forDate:adjustedFromDate];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                 interval:NULL forDate:adjustedToDate];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

+ (NSInteger)nightsRemainingFromNow:(NSDate *)now
                       toDepartDate:(NSDate *)departDate
                    withArrivalDate:(NSDate *)arrivalDate {
    
    //Add 12 hours to the depart date, (which will be at midnight), so that it passes
    //the "3AM" boundary and is counted as another night
    
    NSDate * adjustedDepartDate = [departDate dateByAddingTimeInterval:12*3600];
    
    //Doesn't use [self totalNights] for testing purposes, but uses the same method
    NSInteger totalNights = [YKSDateHelper daysBetweenDate:arrivalDate andDate:departDate];
    
    NSInteger nightsLeft;
    
    nightsLeft = [YKSDateHelper daysBetweenDate:now andDate:adjustedDepartDate];
    
    if (nightsLeft < 0) {
        nightsLeft = 0;
    } else if (nightsLeft > totalNights) {
        nightsLeft = totalNights;
    } else if (nightsLeft == NSNotFound) {
        nightsLeft = 0;
    }
    
    return nightsLeft;
}


+ (BOOL)isDate:(NSDate *)compareDate betweenDate:(NSDate *)earlierDate andDate:(NSDate *)laterDate
{
    // first check that we are later than the earlierDate.
    if ([compareDate compare:earlierDate] == NSOrderedDescending) {
        
        // next check that we are earlier than the laterData
        if ( [compareDate compare:laterDate] == NSOrderedAscending ) {
            return YES;
        }
    }
    // otherwise we are not
    return NO;
}

- (NSDate *)setDate:(NSDate *)date withTimeString:(NSString *)timeString andTimeZone:(NSTimeZone *)timezone {
    //    CLS_LOG(@"timeString is %@", timeString);
  
    if (!timezone) {
        timezone = [NSTimeZone localTimeZone];
    }
    
    NSArray *components = [timeString componentsSeparatedByString:@":"];
   
    NSString * minuteString;
    NSString * hourString;
   
    NSDate * dateWithTime;
    
    if (components.count >= 2) {
        hourString = [components objectAtIndex:0];
        minuteString = [components objectAtIndex:1];
       
        NSDateComponents *dateComps = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
        dateComps.timeZone = timezone;
       
        [dateComps setMinute:minuteString.integerValue];
        [dateComps setHour:hourString.integerValue];
        
       
        dateWithTime = [self.calendar dateFromComponents:dateComps];
        
    } else {
        return nil;
    }
    
    return dateWithTime;
}

- (void)testDateWithTime {
    
    NSDate * now = [NSDate date];
   
    NSArray * times = @[@"12:00", @"19:00:12", @"sdfkds", @"23:00:12:21:23", @"8:00", @"15:15:00"];
    
    for (NSString * timeString in times) {
        
        NSTimeZone * timezone = [[NSTimeZone alloc] initWithName:@"America/Los_Angeles"];
   
        NSDate * withTime = [self setDate:now withTimeString:timeString andTimeZone:timezone];
       
        //DLog(@"\nBefore: %@\nAfter: %@", timeString, [self.simpleDateFormatterWithTime stringFromDate:withTime]);
        NSLog(@"\nBefore: %@\nAfter: %@", timeString, withTime);
        
    }
    
//    DLog(@"DONE");
}


+ (NSString *)convertTo12HrTimeFrom24HrTime:(NSString *)time {
    
    NSString *hours = [time substringWithRange:NSMakeRange(0, 2)];
    NSString *minutes = [time substringWithRange:NSMakeRange(3, 2)];
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setHour:[hours integerValue]];
    [comps setMinute:[minutes integerValue]];
    NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:comps];
    NSString* dateString = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    
    return dateString;
}


@end
