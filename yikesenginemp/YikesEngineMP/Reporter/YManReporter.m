//
//  YManReporter.m
//  Pods
//
//  Created by Alexandar Dimitrov on 2015-01-16.
//
//

#import "YManReporter.h"
#import "YKSYManReporterTimeInterval.h"

//@interface YManReporter ()
//
//
//@end


@implementation YManReporter

@synthesize macAddress, failuresGAtoYMan;

- (id)init {
    self = [super init];

    if (self) {
        self.startEndDates = [NSMutableArray array];
    }
    return self;
}


- (void)setNewYManStartDate:(NSDate *)newStartDate {
    
    if (self.startEndDates) {
        if (self.startEndDates.count > 0) {
            
            YKSYManReporterTimeInterval *yManTimeInterval = [self.startEndDates lastObject];
        
            if ([yManTimeInterval startDate] && [yManTimeInterval endDate]) {
                YKSYManReporterTimeInterval *newInterval = [[YKSYManReporterTimeInterval alloc] init];
                [newInterval setStartDate:newStartDate];
                [self.startEndDates addObject:newInterval];

            }
            else if ([yManTimeInterval startDate] && ![yManTimeInterval endDate]) {
                [yManTimeInterval setStartDate:newStartDate];
            }
            else {
                YKSYManReporterTimeInterval *newInterval = [[YKSYManReporterTimeInterval alloc] init];
                [newInterval setStartDate:newStartDate];
                [self.startEndDates addObject:newInterval];
            }
        }
        else {
            YKSYManReporterTimeInterval *newInterval = [[YKSYManReporterTimeInterval alloc] init];
            [newInterval setStartDate:newStartDate];
            [self.startEndDates addObject:newInterval];
        }
    }
}


- (void)setNewYManEndDate:(NSDate *)newEndDate {
 
    YKSYManReporterTimeInterval *yManTimeInterval = [self.startEndDates lastObject];
    
    if (! yManTimeInterval) {
        // this case is theoretically impossible, but added for protection
        YKSYManReporterTimeInterval *newYManTimeInteval = [[YKSYManReporterTimeInterval alloc] init];
        [newYManTimeInteval setStartDate:newEndDate];
        [newYManTimeInteval setEndDate:newEndDate];
        [self.startEndDates addObject:newYManTimeInteval];
    }
    else {
        [yManTimeInterval setEndDate:newEndDate];
    }
}


- (NSDate *)lastYManStartDate {
    
    for (YKSYManReporterTimeInterval *completeInterval in [self.startEndDates reverseObjectEnumerator]) {
        if ([completeInterval startDate] && [completeInterval endDate]) {
            return [completeInterval startDate];
        }
    }

    // Added in case there is no complete interval
    for (YKSYManReporterTimeInterval *incompleteInterval in [self.startEndDates reverseObjectEnumerator]) {
        if ([incompleteInterval startDate]) {
            return [incompleteInterval startDate];
        }
    }
    
    return nil;
}



- (NSDate *)lastYManEndDate {
    for (YKSYManReporterTimeInterval *completeInterval in [self.startEndDates reverseObjectEnumerator]) {
        if ([completeInterval startDate] && [completeInterval endDate]) {
            return [completeInterval endDate];
        }
    }
    
    // Added in case there is no complete interval
    for (YKSYManReporterTimeInterval *incompleteInterval in [self.startEndDates reverseObjectEnumerator]) {
        if ([incompleteInterval startDate]) {
            return [incompleteInterval endDate];
        }
    }
    
    return nil;
}


@end
