//
//  YKSLogger.h
//  yikes sample
//
//  Created by Manny Singh on 4/27/15.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import <YikesSharedModel/YKSConstants.h>

@interface YKSLevelLogger : NSObject

+ (void)logAPIWithLevel:(YKSLoggerLevel)level format:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3);
//+ (void)logBLEWithLevel:(YKSLoggerLevel)level format:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3);
+ (NSString*)apiEnvToString:(YKSApiEnv)apiEnv;

@end
