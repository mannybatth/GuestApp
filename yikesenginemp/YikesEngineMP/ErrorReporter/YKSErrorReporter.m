//
//  YKSErrorReporter.m
//  Pods
//
//  Created by Elliot Sinyor on 2015-03-24.
//
//

#import "YKSErrorReporter.h"
#import "YKSErrorDetector.h"
#import "YKSLogger.h"
#import "YikesEngineMP.h"
#import "YKSBinaryHelper.h"
#import "YKSDeviceHelper.h"

@import YikesSharedModel;

@interface YKSErrorReporter ()

@property (nonatomic, strong) NSMutableDictionary * possibleErrors; //Holds an instance of each error object, which stores its own occurences

@end



@implementation YKSErrorReporter


- (instancetype)init {
    
    self = [super init];
    
    if (self) {
        
        _possibleErrors = [NSMutableDictionary dictionary];
        _errorQueue = dispatch_queue_create("com.yikes.yikes.ERROR_QUEUE", DISPATCH_QUEUE_SERIAL);
        
        [self initializeErrorDetectors];
        
    }
   
    return self;
    
}


+ (instancetype)sharedReporter
{
    static YKSErrorReporter *_sharedReporter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedReporter = [[YKSErrorReporter alloc] init];
    });
    
    return _sharedReporter;
}

-(void)initializeErrorDetectors {

    YKSErrorDetector * code0 = [[YKSErrorDetector alloc] initWithType:kBLEErrorCode0 andErrorcode:kYKSBluetoothUnknownError withDescription:@"Repeated connection failures" withMaxOccurences:6 inPeriodOfTime:4 shouldSendToYCentral:YES shouldTriggerEngineError:YES andErrorDetector:self];
    
    YKSErrorDetector * code10 = [[YKSErrorDetector alloc] initWithType:kBLEErrorCode10 andErrorcode:kYKSBluetoothConnectionError withDescription:@"Repeated connection failures" withMaxOccurences:4 inPeriodOfTime:6 shouldSendToYCentral:YES shouldTriggerEngineError:YES andErrorDetector:self];
   
    YKSErrorDetector * code3 = [[YKSErrorDetector alloc] initWithType:kBLEErrorCode3 andErrorcode:kYKSBluetoothServiceDiscoveryError withDescription:@"Error discovering services on bluetooth device" withMaxOccurences:1 inPeriodOfTime:6 shouldSendToYCentral:YES shouldTriggerEngineError:NO andErrorDetector:self];
   
    YKSErrorDetector * nonMatching = [[YKSErrorDetector alloc] initWithType:kBLEErrorNonMatchingAuth andErrorcode:kYKSBluetoothAuthDoesNotMatchAnyRooms withDescription:@"yMAN auth does not match any rooms" withMaxOccurences:2 inPeriodOfTime:10 shouldSendToYCentral:YES shouldTriggerEngineError:YES andErrorDetector:self];
    
    [self addErrorDetector:code0];
    [self addErrorDetector:code10];
    [self addErrorDetector:code3];
    [self addErrorDetector:nonMatching];
    
}

- (void)addErrorDetector:(YKSErrorDetector *)errorDetector {

    NSNumber * key = [NSNumber numberWithInteger:errorDetector.errorType];

    [_possibleErrors setObject:errorDetector forKey:key];
    
}


//Called by clients of error reporter
-(void)reportErrorWithType:(YBLEErrorType)errorType {

    YKSErrorDetector * detector = [_possibleErrors objectForKey:[NSNumber numberWithInteger:errorType]];
   
    if (detector) {
        [detector detected];
    }
    
}

//Called by error detector that has detected too many errors
-(void)errorsOverAcceptableRate:(YKSErrorDetector *)detector {
    
    NSString * message = [NSString stringWithFormat:@"ErrorReporter: Error Detected: (%@) Occured more than %li times in %.01f seconds", detector.errorName, (long)detector.maxAcceptableOccurences, detector.period];
    
    [[YKSLogger sharedLogger] logMessage:message withErrorLevel:YKSErrorLevelError andType:YKSLogMessageTypeBLE];
   
    if (detector.shouldTriggerExternalEngineError) {
    
        if ([self.delegate respondsToSelector:@selector(errorOccurredOverAcceptableRate:)]) {
       
            NSString * device = [YKSDeviceHelper phoneModel];
            NSString * os = [YKSDeviceHelper osVersion];
            NSString * engine = [YKSDeviceHelper engineVersion];
            NSString * guestAppVersion = [YKSDeviceHelper fullGuestAppVersion];
            NSString * email = [YikesEngineMP sharedEngine].userInfo.email;
            
            NSDictionary * userInfo = @{@"device":device? device : @"unknown",
                                        @"os":os? os : @"unknown",
                                        @"engine_v":engine? engine : @"unknown",
                                        @"app_v":guestAppVersion? guestAppVersion : @"unknown",
                                        @"email":email? email : @"unknown"};
            
            detector.error.userInfo = userInfo;
            
            [self.delegate errorOccurredOverAcceptableRate:detector];
        }
    }
    
}


@end

