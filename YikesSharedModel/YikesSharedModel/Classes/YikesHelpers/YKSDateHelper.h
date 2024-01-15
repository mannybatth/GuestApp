//
//  YKSDateFormatter.h
//  yikes Hotel
//
//  Created by Roger on 4/29/14.
//  Copyright (c) 2014 Yamm Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YKSDateHelper : NSObject

+ (YKSDateHelper *)sharedInstance;

//Note: readonly doesn't seem to protect from caller modifying the format object...
@property (nonatomic, strong, readonly) NSDateFormatter *simpleDateFormatter;
@property (nonatomic, strong, readonly) NSDateFormatter *mediumDateFormatter;
@property (nonatomic, strong, readonly) NSDateFormatter *simpleDateFormatterWithTime;
@property (nonatomic, strong, readonly) NSDateFormatter *simpleDateFormatterWithTimeSSS;
@property (nonatomic, strong, readonly) NSDateFormatter *timeOnlyHHmmssDateFormatter;
@property (nonatomic, strong, readonly) NSDateFormatter *timeOnlymmssDateFormatter;

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;
+ (NSInteger)nightsRemainingFromNow:(NSDate *)now
                       toDepartDate:(NSDate *)departDate
                    withArrivalDate:(NSDate *)arrivalDate;
+ (BOOL)isDate:(NSDate *)compareDate betweenDate:(NSDate *)earlierDate andDate:(NSDate *)laterDate;
- (NSDate *)setDate:(NSDate *)date withTimeString:(NSString *)timeString andTimeZone:(NSTimeZone *)timezone;
+ (NSString *)convertTo12HrTimeFrom24HrTime:(NSString *)time;

@end
