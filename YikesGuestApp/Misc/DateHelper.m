//
//  YKSDateHelper.m
//  YikesGuestApp
//
//  Created by Manny Singh on 10/21/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "DateHelper.h"

@implementation DateHelper

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
