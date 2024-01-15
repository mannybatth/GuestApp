//
//  YKSCentralizedLogger.m
//  YikesEnginePod
//
//  Created by royksopp on 2015-06-03.
//  Copyright (c) 2015 Elliot Sinyor. All rights reserved.
//

#import "YKSLogger.h"
#import "YKSDebugManager.h"
#import "YKSFileLogger.h"
#import "YKSInternalConstants.h"

@interface YKSLogger ()

@end



@implementation YKSLogger

+ (YKSLogger *)sharedLogger {
    static YKSLogger *sharedLogger = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedLogger = [[self alloc] init];
    });
    
    return sharedLogger;
}


- (id) init {
    
    self = [super init];

    if (self) {
    }
    
    return self;
}

- (void)logMessage:(NSString *)message
    withErrorLevel:(YKSErrorLevel)errorLevel
           andType:(YKSLogMessageType)logMessageType {
    
    if (! [YKSDebugManager sharedManager].isDebugModeEnabled) {
        return;
    }
    
    YKSLogAPIInfo(@"%@", message);
    [[YKSDebugManager sharedManager] logMessage:message withErrorLevel:errorLevel andType:logMessageType];
}

@end
