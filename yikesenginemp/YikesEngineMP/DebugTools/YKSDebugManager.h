//
//  YKSDebugManager.h
//  yikes sample
//
//  Created by royksopp on 2015-04-14.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

@protocol YikesKitDebugViewDelegate;
@protocol YKSDebugBLEConnectionsDataAvailableDelegate;
@protocol YKSDebugConsoleNewLogsAvailableDelegate;
@protocol YKSDebugConsolePrimaryYmanStatusDelegate;

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YKSLogger.h"

@interface YKSDebugManager : NSObject

@property (nonatomic, assign) BOOL isDebugModeEnabled;

@property (nonatomic, strong) NSMutableArray *finishedBleTriangleConnections;
@property (nonatomic, strong) NSMutableArray *activeBleTriangleConnections;
@property (nonatomic, strong) NSMutableArray *primaryYManConnections;

@property (nonatomic, weak) id<YKSDebugBLEConnectionsDataAvailableDelegate> availableBLEConnectionsDataDelegate;
@property (nonatomic, weak) id<YKSDebugConsoleNewLogsAvailableDelegate> availableLogsDataDelegate;
@property (nonatomic, weak) id<YKSDebugConsolePrimaryYmanStatusDelegate> primaryYManStatusDelegate;

@property (assign, atomic) BOOL isLogScrollingPausedInDebugConsoleViewController;
@property (assign, atomic) BOOL isLogPausedInDebugConsoleViewController;

@property (atomic, assign) NSUInteger numberOfLinesOfLogMessagesBuffer;

@property dispatch_queue_t serialQueueBleConnections;
@property dispatch_queue_t serialQueueConsoleLogs;

+ (YKSDebugManager *)sharedManager;

- (void)clearConnections;
- (void)clearConsoleLogs;
- (void)handleLogin;
- (void)handleLogout;
- (void)logMessage:(NSString *)message withErrorLevel:(YKSErrorLevel)errorLevel andType:(YKSLogMessageType)logMessageType;

- (void)shouldPauseLogsToDebugConsole:(BOOL)shouldPause;
- (void)showDebugViewInView:(UIView *)view;
- (void)hideDebugView;
- (void)setDebugMode:(BOOL)on;

- (void)callConnectionsAndLogsDelegates;
- (void)transferFinishedConnections;
- (void)switchEngineToSP;
- (void)switchEngineBeaconBased;
- (BOOL) isEngineMPForced;
- (BOOL) isEngineBeaconEnabled;

@end



@protocol YKSDebugBLEConnectionsDataAvailableDelegate <NSObject>

@required
- (void)bleConnectionsDataAvailableWithActiveConnections:(NSArray *)activeConnections
                                  andFinishedConnections:(NSArray *)finishedConnections;
@end


@protocol YKSDebugConsoleNewLogsAvailableDelegate <NSObject>

@required
- (void)logsAvailable:(NSArray *)logs;
- (void)numberOfPrimaryManAvailable:(NSInteger)pYManCount;
- (void)startedScanningForPrimaryYMan;
- (void)stoppedScanningForPrimaryYMan;

@end


@protocol YKSDebugConsolePrimaryYmanStatusDelegate <NSObject>

- (void)primaryYManDataAvailable;

@end

