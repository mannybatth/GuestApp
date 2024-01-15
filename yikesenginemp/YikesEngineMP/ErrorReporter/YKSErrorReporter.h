//
//  YKSErrorReporter.h
//  Pods
//
//  Created by Elliot Sinyor on 2015-03-24.
//
//

#import <Foundation/Foundation.h>
//#import "YKSErrorDetector.h"

@protocol YKSErrorReporterDelegate;

@class YKSErrorDetector;

typedef NS_ENUM(NSUInteger, YBLEErrorType) {
    kBLEErrorNoServices,
    kBLEErrorCode0,
    kBLEErrorCode10,
    kBLEErrorCode3,
    kBLEErrorZeroTrackID,
    kBLEErrorNonMatchingAuth,
};

@interface YKSErrorReporter : NSObject

-(void)reportErrorWithType:(YBLEErrorType)type;
-(void)errorsOverAcceptableRate:(YKSErrorDetector *)error;
+ (instancetype)sharedReporter;

    

@property (readonly) dispatch_queue_t errorQueue;
@property (weak, nonatomic) id<YKSErrorReporterDelegate> delegate;

@end

@protocol YKSErrorReporterDelegate <NSObject>

@required

-(void)errorOccurredOverAcceptableRate:(YKSErrorDetector *)error;
    
@end