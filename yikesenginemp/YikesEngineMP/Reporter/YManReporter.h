//
//  YManReporter.h
//  Pods
//
//  Created by Alexandar Dimitrov on 2015-01-16.
//
//

#import <Foundation/Foundation.h>

@interface YManReporter : NSObject

@property (strong, nonatomic) NSData* macAddress;
@property (strong, nonatomic) NSNumber* failuresGAtoYMan;
@property (assign, nonatomic, getter=isInsideCycle) BOOL insideCycle;
@property (strong, nonatomic) NSMutableArray* startEndDates;

- (void)setNewYManStartDate:(NSDate *)newStartDate;
- (void)setNewYManEndDate:(NSDate *)newEndDate;

- (NSDate *)lastYManStartDate;
- (NSDate *)lastYManEndDate;

@end
