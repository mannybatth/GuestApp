//
//  YKSErrorDetector.m
//  Pods
//
//  Created by Elliot Sinyor on 2015-03-26.
//
//

#import "YKSErrorDetector.h"
#import "YKSErrorReporter.h"

@implementation YKSErrorDetector

-(instancetype)initWithType:(YBLEErrorType)type
               andErrorcode:(YKSErrorCode)code
            withDescription:(NSString *)errorName
          withMaxOccurences:(NSUInteger)maxOccurences
             inPeriodOfTime:(NSTimeInterval)period
       shouldSendToYCentral:(BOOL)shouldSendYC
   shouldTriggerEngineError:(BOOL)shouldEngineError
           andErrorDetector:(YKSErrorReporter *)reporter {

    self = [super init];
    
    if (self) {
      
        YKSError * error = [YKSError newWithErrorCode:code errorDescription:errorName];
       
        _error = error;
        
        _errorType = type;
        
        _errorName = errorName;
       
        _shouldReportToYCentral = shouldSendYC;
        _shouldTriggerExternalEngineError = shouldEngineError;
        
        _maxAcceptableOccurences = maxOccurences;
        _period = period;
        
        _errorReporter = reporter;
        
        _errorOccurences = [NSMutableArray array];
        _deltasBetweenOccurences = [NSMutableArray array];
        
    }

    return self;
    
}


-(void)detected {

    dispatch_async(self.errorReporter.errorQueue, ^{
        
        NSDate * errorTime = [NSDate date];
        
        [_errorOccurences addObject:errorTime];
       
        //after the "acceptable" period has elapsed, remove the error
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((_period - 0.05)* NSEC_PER_SEC)), self.errorReporter.errorQueue, ^{
            [_errorOccurences removeObject:errorTime];
        });
   
        //If the number of errors exceeds the maximum acceptable number, call the error detector method (on main thread)
        if (_errorOccurences.count >= self.maxAcceptableOccurences) {
          
            [_errorOccurences removeAllObjects];
            
            dispatch_async(dispatch_get_main_queue(), ^{
            
                [self.errorReporter errorsOverAcceptableRate:self];
            
            });
            
        }
    
    });
    
}



@end
