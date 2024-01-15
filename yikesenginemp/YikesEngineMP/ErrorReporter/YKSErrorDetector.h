//
//  YKSErrorDetector.h
//  Pods
//
//  Created by Elliot Sinyor on 2015-03-26.
//
//

#import <Foundation/Foundation.h>
#import "YKSErrorReporter.h"

@import YikesSharedModel;

@interface YKSErrorDetector : NSObject

-(instancetype)initWithType:(YBLEErrorType)type
               andErrorcode:(YKSErrorCode)code
            withDescription:(NSString *)errorName
          withMaxOccurences:(NSUInteger)maxOccurences
             inPeriodOfTime:(NSTimeInterval)period
       shouldSendToYCentral:(BOOL)shouldSendYC
   shouldTriggerEngineError:(BOOL)shouldEngineError
           andErrorDetector:(YKSErrorReporter *)reporter;

-(void)detected;

@property (nonatomic, readonly) YBLEErrorType errorType;
@property (nonatomic, readonly) NSString * errorName;
@property (nonatomic, weak) YKSErrorReporter * errorReporter;
@property (nonatomic, copy) NSString * errorShortDescription;
@property (nonatomic, readonly) NSMutableArray * errorOccurences; //Array of timestamps, from which we can calculate delta times between errors
@property (nonatomic, readonly) NSMutableArray * deltasBetweenOccurences;
@property (nonatomic, strong, readonly) YKSError * error;

@property (nonatomic, readonly) BOOL shouldReportToYCentral;
@property (nonatomic, readonly) BOOL shouldTriggerExternalEngineError;

/* These are to be used in conjunction with each other. For example setting 
 *    maxAcceptableOccurences to 5 and
 *    period to 2 means "raise an alarm if this error occurs more than 5 times in 2 seconds"
 */
@property (nonatomic, assign) NSUInteger maxAcceptableOccurences;
@property (nonatomic, assign) NSTimeInterval period;

@end
