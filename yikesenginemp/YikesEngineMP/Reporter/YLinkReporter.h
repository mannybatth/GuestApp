//
//  YLinkReporter.h
//  Pods
//
//  Created by Alexandar Dimitrov on 2015-01-16.
//
//

#import <Foundation/Foundation.h>

@interface YLinkReporter : NSObject

//@property (strong, nonatomic) NSDate* yManStartDate;
//@property (strong, nonatomic) NSDate* yManEndDate;
@property (strong, nonatomic) NSData* yManMacAddress;
@property (strong, nonatomic) NSNumber* failuresGAtoYMan;

@property (strong, nonatomic) NSData* trackID;
//@property (strong, nonatomic) NSDate* yLinkStartDate;
//@property (strong, nonatomic) NSDate* yLinkEndDate;

@property (strong, nonatomic) NSNumber* completed;

@property (atomic, assign) BOOL writtenToFile;
@property (atomic, assign) int numberScansGA;

@end
