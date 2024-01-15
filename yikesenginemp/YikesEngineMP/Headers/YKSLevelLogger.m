//
//  YKSLogger.m
//  yikes sample
//
//  Created by Manny Singh on 4/27/15.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import "YKSLevelLogger.h"
#import "YKSAPIManager.h"


@implementation YKSLevelLogger

+ (void)logAPIWithLevel:(YKSLoggerLevel)level format:(NSString *)format, ...
{
    if (format) {
        va_list args;
        va_start(args, format);
        [self logWithLevel:level forSetLevel:[YKSAPIManager sharedManager].loggingLevelForAPIManager format:format arugments:args];
        va_end(args);
    }
}

//+ (void)logBLEWithLevel:(YKSLoggerLevel)level format:(NSString *)format, ...
//{
//    if (format) {
//        va_list args;
//        va_start(args, format);
//        [self logWithLevel:level forSetLevel:[YikesEngine sharedEngine].loggingLevelForBLE format:format arugments:args];
//        va_end(args);
//    }
//}

+ (void)logWithLevel:(YKSLoggerLevel)level
         forSetLevel:(YKSLoggerLevel)setLevel
              format:(NSString *)format
           arugments:(va_list)args
{
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    if (level <= setLevel) {
        switch (level) {
            case kYKSLoggerLevelDebug:
                DLog(@"[YikesDebug] %@", message);
                break;
            case kYKSLoggerLevelInfo:
                DLog(@"[YikesInfo] %@", message);
                break;
            case kYKSLoggerLevelError:
                DLog(@"[YikesError] %@", message);
                break;
                
            default:
                break;
        }
    }
}

+ (NSString *)apiEnvToString:(YKSApiEnv)apiEnv
{
    NSDictionary *apiEnvNames = @{
                                  @(kYKSEnvPROD):   @"PROD",
                                  @(kYKSEnvQA):     @"QA",
                                  @(kYKSEnvDEV):    @"DEV"
                                };
    return [apiEnvNames objectForKey:@(apiEnv)];
}

@end
