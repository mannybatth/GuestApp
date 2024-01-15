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

@property (nonatomic, strong) NSMutableArray *finishedBleTriangleConnections;
@property (nonatomic, strong) NSMutableArray *activeBleTriangleConnections;
@property (nonatomic, strong) NSMutableArray *primaryYManConnections;

@property (nonatomic, weak) id<YKSDebugBLEConnectionsDataAvailableDelegate> availableBLEConnectionsDataDelegate;
@property (nonatomic, weak) id<YKSDebugConsoleNewLogsAvailableDelegate> availableLogsDataDelegate;
@property (nonatomic, weak) id<YKSDebugConsolePrimaryYmanStatusDelegate> primaryYManStatusDelegate;

@property (assign, atomic) BOOL isLogPausedInDebugConsoleViewController;

@property dispatch_queue_t serialQueueBleConnections;

+ (YKSDebugManager *)sharedManager;

- (void)clearConnections;
- (void)clearConsoleLogs;

- (void)logMessage:(NSString *)message withErrorLevel:(YKSErrorLevel)errorLevel andType:(YKSLogMessageType)logMessageType;

- (void)shouldPauseLogsToDebugConsole:(BOOL)shouldPause;
- (void)showDebugViewInView:(UIView *)view;
- (void)hideDebugView;
- (void)setDebugMode:(BOOL)on;

- (void)logMessagesArray:(void(^)(NSArray* logMessagesArray)) completition;
- (NSArray *)logMessagesArray;
- (void)callConnectionsAndLogsDelegates;

@end



@protocol YKSDebugBLEConnectionsDataAvailableDelegate <NSObject>

@required
- (void)bleConnectionsDataAvailable;

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

