//
//  YKSCentralizedLogger.h
//  YikesEnginePod
//
//  Created by royksopp on 2015-06-03.
//  Copyright (c) 2015 Elliot Sinyor. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, YKSErrorLevel) {
    YKSErrorLevelCriticalError,
    YKSErrorLevelError,
    YKSErrorLevelWarning,
    YKSErrorLevelInfo,
    YKSErrorLevelDebug
};

typedef NS_ENUM(NSUInteger, YKSLogMessageType) {
    YKSLogMessageTypeBLE,
    YKSLogMessageTypeAPI,
    YKSLogMessageTypeDevice,
    YKSLogMessageTypeService,
    YKSLogMessageTypeEngine,
    YKSLogMessageTypeLocation,
    YKSLogMessageTypeApp
};

@interface YKSLogger : NSObject

+ (YKSLogger *)sharedLogger;

- (void)logMessage:(NSString *)message withErrorLevel:(YKSErrorLevel)errorLevel andType:(YKSLogMessageType) type;

@end
