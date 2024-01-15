//
//  YKSLogReporter.h
//  Pods
//
//  Created by Alexandar Dimitrov on 2014-10-03.
//
//

#import <Foundation/Foundation.h>
#import "YKSLogger.h"

FOUNDATION_EXPORT NSString *const YKSErrorLevelCriticalErrorString;
FOUNDATION_EXPORT NSString *const YKSErrorLevelErrorString;
FOUNDATION_EXPORT NSString *const YKSErrorLevelWarningString;
FOUNDATION_EXPORT NSString *const YKSErrorLevelInfoString;
FOUNDATION_EXPORT NSString *const YKSErrorLevelDebugString;

FOUNDATION_EXPORT NSString *const YKSLogMessageTypeBLEString;
FOUNDATION_EXPORT NSString *const YKSLogMessageTypeAPIString;
FOUNDATION_EXPORT NSString *const YKSLogMessageTypeDeviceString;
FOUNDATION_EXPORT NSString *const YKSLogMessageTypeServiceString;


@interface YKSFileLogger : NSObject


@property (nonatomic, strong) NSString* timeStampForAllFileTitles;

#pragma mark - Class methods
+ (YKSFileLogger *)sharedInstance;

#pragma mark - Reporter methods
- (void)restartStats;

#pragma mark - Logging
- (void)addCurrentFullSessionLogsToCurrentFile;
- (void)cleanBuffer;

- (void)handleLogin;
- (void)handleLogout;

- (void)logToFileAMessage:(NSString*)message withErrorLevel:(YKSErrorLevel)errorLevel andLogMessageType:(YKSLogMessageType)logMessageType;

- (void)writeIPhoneModelToFullLogs;
- (void)writeGAVersionToFullLogs;
- (void)writeiOSVersionToFullLogs;

#pragma mark - File paths
- (NSString *)completeFilePathForFullSessionLogs;

@end
