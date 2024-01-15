//
//  YKSDebugManager.m
//  yikes sample
//
//  Created by royksopp on 2015-04-14.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import "YKSDebugManager.h"
#import "YKSDebugConsoleViewController.h"
#import "YLinkReporter.h"
#import "YManReporter.h"
#import "BLETriangleConnection.h"
#import "YKSYManConnection.h"
#import "YKSLogger.h"
#import "YKSFileLogger.h"
#import <ReplayKit/ReplayKit.h>
#import "YikesEngineMP.h"
#import "YKSBinaryHelper.h"

@import YikesSharedModel;

#define MAX_NUMBER_OF_FINISHED_CONNECTIONS 60
#define NUMBER_OF_FINISHED_CONNECTIONS_TO_REMOVE 50

#define MAX_NUMBER_OF_CONSOLE_DEBUG_LINES 1000
#define MIN_NUMBER_OF_CONSOLE_DEBUG_LINES 800

#define MAX_CHARS_PER_LIGNE_IN_CONSOLE 50
//#define DEBUG_PREPEND_LINE_NUMBER

// Important: make sure engineSPEnabledKey and engineSPForceKey have the same
// values in SP engine framework

// key used by engine to tell whether singlepath mode is permitted
static NSString *const engineSPEnabledKey = @"yksEngineSPEnabledKey";
// key used by engine to force SP and ignore MP
static NSString *const engineSPForceKey = @"yksEngineSPForceKey";


@interface YKSDebugManager ()  <YKSBLETriangleConsoleDelegate>

@property (nonatomic, assign) BOOL isAnimatingDebugArea;
@property (nonatomic, assign) BOOL isDebugAreaVisible;
@property (nonatomic, weak) UIView *presentingView;
@property (nonatomic, strong) YKSDebugConsoleViewController *debugVC;

@property (nonatomic, strong) NSMutableArray *yMen;
@property (nonatomic, strong) NSMutableArray *yLinks;

// Connections that are moved from active to finished
@property (nonatomic, strong) NSMutableArray *transitionBLEConnections;

@property (strong, nonatomic) NSMutableArray* logMessagesBuffer;

@property (atomic, assign) NSUInteger eventNumber;
@property (nonatomic, strong) NSTimer *reduceFinishedConnectionsTimer;

@end


@implementation YKSDebugManager

@synthesize debugVC, isAnimatingDebugArea, isDebugAreaVisible, presentingView;

+ (YKSDebugManager *)sharedManager {
    static YKSDebugManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    [[MultiYManGAuthDispatcher sharedInstance] setBleTriangleConsoleDelegate:_sharedInstance];
    
    return _sharedInstance;
}


- (id) init {
    
    self = [super init];
    if (self) {
        
        self.isDebugModeEnabled = NO;
        
        self.serialQueueBleConnections = dispatch_queue_create("co.yamm.yikesengine.debugmngqueue", DISPATCH_QUEUE_SERIAL);
        self.serialQueueConsoleLogs = dispatch_queue_create("co.yamm.yikesengine.debugmngconsolelogsqueue", DISPATCH_QUEUE_SERIAL);
        self.isLogScrollingPausedInDebugConsoleViewController = NO;
        self.numberOfLinesOfLogMessagesBuffer = 0;
        self.eventNumber = 0;
        
        // Clear connections on self.serialQueueBleConnections
        [self clearConnections];
        
        // Clear console logs on self.serialQueueConsoleLogs
        [self clearConsoleLogs];
    }
    
    return self;
}


- (void)handleLogin {
    
    if (! self.isDebugModeEnabled) {
        if (self.reduceFinishedConnectionsTimer) {
            [self.reduceFinishedConnectionsTimer invalidate];
            self.reduceFinishedConnectionsTimer = nil;
        }
        
    } else {
        if (!self.reduceFinishedConnectionsTimer) {
            self.reduceFinishedConnectionsTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(cleanBLEConnections) userInfo:nil repeats:YES];
        }
    }
}


- (void)handleLogout {
    [self.reduceFinishedConnectionsTimer invalidate];
    self.reduceFinishedConnectionsTimer = nil;
}


- (void)setDebugMode:(BOOL)on {
    if (on) {
        self.isDebugModeEnabled = YES;
    }
    else {
        self.isDebugModeEnabled = NO;
    }
}

- (void)showDebugViewInView:(UIView *)view {
    
    if (! self.isDebugModeEnabled) {
        return;
    }
    
       
    presentingView = view;
    
    DLog(@"Called showDebugViewInView");
    
    if (!self.isDebugAreaVisible && !isAnimatingDebugArea) {
        
        // Grab the bundle inside the YikesEngineMP framework URL:
        NSBundle *mpbundle = [NSBundle bundleWithURL:[YikesEngineMP sharedEngine].bundleURL];
        // load the storyboard:
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DebugViewStoryboard" bundle:mpbundle];
        debugVC = [storyboard instantiateViewControllerWithIdentifier:@"YKSDebugVCId"];
        
        CGRect debugFrame;
        
        if (presentingView) {
            debugFrame = [self debugViewFrame];
        }
        else {
            debugFrame = [UIApplication sharedApplication].keyWindow.frame;
        }
        
        CGPoint center = CGPointMake(debugFrame.size.width/2.f, debugFrame.size.height/2.f);
        CGRect startDebugFrame = CGRectMake(center.x, center.y, 0, 0);
        
        // start point for the appearance animation:
        debugVC.view.frame = startDebugFrame;
        
        if (! CGRectEqualToRect(debugFrame, CGRectZero)) {
            
            UIWindow *mainW = [UIApplication sharedApplication].keyWindow;
            
            [mainW addSubview:debugVC.view];
            
            isAnimatingDebugArea = YES;
            [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.9 options:0 animations:^{
                
                // set the debug frame to it's full size
                debugVC.view.frame = debugFrame;
                
            } completion:^(BOOL finished) {
                isAnimatingDebugArea = NO;
                isDebugAreaVisible = YES;
                [presentingView layoutIfNeeded];
            }];
        }
    }
    else {
        DLog(@"Busy or Showing!");
    }
}

- (CGFloat)statusBarHeight {
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    return MIN(statusBarSize.width, statusBarSize.height);
}


- (CGRect)debugViewFrame {
    
    CGRect screenBounds = [UIApplication sharedApplication].keyWindow.frame;
    CGFloat minWidth = CGRectGetWidth(screenBounds);
    CGFloat minHeight = CGRectGetHeight(screenBounds) - [self statusBarHeight];

    CGRect frame = CGRectZero;
    
    if (debugVC && presentingView) {
        
//        CGRect debugFrame = debugVC.view.frame;
        
        CGRect presFrame = presentingView.frame;
        CGFloat originX = presFrame.origin.x;
        // the origin needs to be under the statusBar
        CGFloat originY = presFrame.origin.y + [self statusBarHeight];
        
        frame.size = CGSizeMake(minWidth, minHeight);
        frame.origin = CGPointMake(originX, originY);
    }
    
    return frame;
}


- (void)hideDebugView {
    DLog(@"Called hideDebugView");
    
    [debugVC.view removeFromSuperview];
    
    presentingView = nil;
    isDebugAreaVisible = NO;
    isAnimatingDebugArea = NO;
}


#pragma mark - Connections data methods

- (void)clearConnections {
    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        self.finishedBleTriangleConnections = [NSMutableArray array];
        self.activeBleTriangleConnections = [NSMutableArray array];
        self.primaryYManConnections = [NSMutableArray array];
        self.yMen = [NSMutableArray array];
        self.yLinks = [NSMutableArray array];
        
        [self copyConnectionsArrayAndCallDelegateOnMainThread];
        
    });
}


- (void)clearConsoleLogs {

    dispatch_async(self.serialQueueConsoleLogs, ^{
        
        self.logMessagesBuffer = [NSMutableArray array];
        
        [self copyLogsArrayAndCallDelegateOnMainThread];
    });
}


- (void)transferFinishedConnections {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        [self.finishedBleTriangleConnections addObjectsFromArray:self.transitionBLEConnections];
        
        for (BLETriangleConnection *oneConnection in self.transitionBLEConnections) {
            
            [self logRSSIValuesOfConnection:oneConnection];
            
            [self.activeBleTriangleConnections removeObject:oneConnection];
        }
        
        self.transitionBLEConnections = [NSMutableArray array];
    });
}

//TODO: START clean up
- (BOOL) isEngineMPForced {
    
    BOOL isSPEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"yksEngineSPEnabledKey"];
    BOOL isSPForced = [[NSUserDefaults standardUserDefaults] boolForKey:@"yksEngineSPForceKey"];
    BOOL isMPEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"yksEngineMPEnabledKey"];
    
    return !isSPEnabled && !isSPForced && isMPEnabled;
}


- (BOOL) isEngineBeaconEnabled {
    if ([YikesEngineMP sharedEngine].engineBeaconMode) {
        YKSBeaconMode bm = [YikesEngineMP sharedEngine].engineBeaconMode();
        return (bm == kYKSBeaconBased);
    }
    else {
        NSLog(@"The engineBeaconMode block is not defined - Likely no Generic Engine setup.");
        return NO;
    }
}

- (void)switchEngineToSP {
    if([YikesEngineMP sharedEngine].changeEngineBeaconMode) {
        [YikesEngineMP sharedEngine].changeEngineBeaconMode(kYKSSPForced);
    }
}

- (void)switchEngineBeaconBased {
    if ([YikesEngineMP sharedEngine].changeEngineBeaconMode) {
        [YikesEngineMP sharedEngine].changeEngineBeaconMode(kYKSBeaconBased);
    }
}

//TODO: STOP clean up


- (void)cleanBLEConnections {

    if (! self.isDebugModeEnabled) {
        return;
    }

    
    dispatch_async(self.serialQueueBleConnections, ^{
        BOOL isScrollingPaused = [YKSDebugManager sharedManager].isLogScrollingPausedInDebugConsoleViewController;
        
        if (! isScrollingPaused) {
            // Don't clean logs while scrolling is paused in order to
            // avoid logs vanishing from the
            // screen while the user is examining them
            
            if (MAX_NUMBER_OF_FINISHED_CONNECTIONS <= NUMBER_OF_FINISHED_CONNECTIONS_TO_REMOVE) {
                //        CLS_LOG(@"Defines for number of lines seem to be wrong!, YKSDebugConsoleViewController");
            }
            else{
                if (self.finishedBleTriangleConnections.count > MAX_NUMBER_OF_FINISHED_CONNECTIONS) {
                    
                    // clean the beginning of the array
                    [self.finishedBleTriangleConnections removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, NUMBER_OF_FINISHED_CONNECTIONS_TO_REMOVE)]];
                }
                
            }
        }
    });
}


#pragma mark -

- (void)copyLogsArrayAndCallDelegateOnMainThread {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    NSArray *copyOfLocalMessages = [NSArray arrayWithArray:self.logMessagesBuffer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
        if (self.availableLogsDataDelegate &&
            [self.availableLogsDataDelegate respondsToSelector:@selector(logsAvailable:)]) {
            [self.availableLogsDataDelegate logsAvailable:copyOfLocalMessages];
        }
    });
}


- (void)copyConnectionsArrayAndCallDelegateOnMainThread {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    NSMutableArray* activeConnectionsCopy = [[NSMutableArray alloc] initWithArray:self.activeBleTriangleConnections copyItems:YES];
    NSMutableArray* finishedConnectionsCopy = [[NSMutableArray alloc] initWithArray:self.finishedBleTriangleConnections copyItems:YES];

    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.availableBLEConnectionsDataDelegate &&
            [self.availableBLEConnectionsDataDelegate
             respondsToSelector:@selector(bleConnectionsDataAvailableWithActiveConnections:andFinishedConnections:)]) {
                
                [self.availableBLEConnectionsDataDelegate
                 bleConnectionsDataAvailableWithActiveConnections:activeConnectionsCopy
                 andFinishedConnections:finishedConnectionsCopy];
            }
    });
}

#pragma mark - YKSBLETriangleConsoleDelegate

- (void)consoleStartedScanForPrimaryYManList:(NSArray *)pYManList {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    //TODO: indicate number of primary yMan GA is scanning for
    // If user taps the number, show the list
    // When GA connects to a yMan from the list, indicate the event (show
    // green dot), whe GA disconnects, indicate the event
    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        [self.availableLogsDataDelegate startedScanningForPrimaryYMan];
        
        // All pYMan are disconnected in the beginning
        self.primaryYManConnections = [NSMutableArray array];
        
        for (NSData *pYManMacAddress in pYManList) {
            
            YKSYManConnection *yManConnection = [[YKSYManConnection alloc] initWithMacAddress:pYManMacAddress
                                                                                 andConnected:NO];
            [self.primaryYManConnections addObject:yManConnection];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.availableLogsDataDelegate numberOfPrimaryManAvailable:[pYManList count]];
            
            if (self.primaryYManStatusDelegate &&
                [self.primaryYManStatusDelegate respondsToSelector:@selector(primaryYManDataAvailable)]) {
                
                [self.primaryYManStatusDelegate primaryYManDataAvailable];
            }
        });
    });
}


- (void)consoleStoppedScanForPrimaryYMan {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    
    //TODO: indicate GA stopped scanning for primary yMan, show 0,
    // if user taps on the number, show empty list
    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        DLog(@"Stopped scan for pYMan");
        
        [self.availableLogsDataDelegate stoppedScanningForPrimaryYMan];
        
        self.primaryYManConnections = [NSMutableArray array];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.availableLogsDataDelegate numberOfPrimaryManAvailable:0];

            if (self.primaryYManStatusDelegate &&
                [self.primaryYManStatusDelegate respondsToSelector:@selector(primaryYManDataAvailable)]) {
                
                [self.primaryYManStatusDelegate primaryYManDataAvailable];
            }
        });
    });
}


// primary yMan
- (void)consoleConnectToYMan:(NSData *)mac_address {
    
    if (! self.isDebugModeEnabled) {
        return;
    }
    
    //    DLog(@"Called connect to yman with mac address: %@", [BinaryHelper hexStringFromBinary:mac_address]);
    
    NSDate* newStartDate = [NSDate date];
    
    dispatch_async(self.serialQueueBleConnections, ^{
        // primary yMan connections
        for (YKSYManConnection *onePYManConnection in self.primaryYManConnections) {
            
            if ([[onePYManConnection macAddress] isEqualToData:mac_address]) {
                onePYManConnection.connected = YES;
                
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.primaryYManStatusDelegate &&
                [self.primaryYManStatusDelegate respondsToSelector:@selector(primaryYManDataAvailable)]) {
                
                [self.primaryYManStatusDelegate primaryYManDataAvailable];
            }
            
        });
        
        
        // BLE connections
        
        BOOL foundYMan = NO;
        
        for (YManReporter* yMan in self.yMen) {
            if ([[yMan macAddress] isEqualToData:mac_address]) {
                foundYMan = YES;
                
                [yMan setNewYManStartDate:newStartDate];
                [yMan setFailuresGAtoYMan:@(0)];
            }
        }
        
        if (!foundYMan) {
            YManReporter* newYMan = [[YManReporter alloc] init];
            [newYMan setMacAddress:mac_address];
            [newYMan setNewYManStartDate:newStartDate];
            
            [self.yMen addObject:newYMan];
        }
    });
}



- (void)consoleStartedScanForPYMan:(NSData *)mac_address {
    if (! self.isDebugModeEnabled) {
        return;
    }

    //
}


- (void)consoleDiscoveredPYMan:(NSData *)mac_address {

    if (! self.isDebugModeEnabled) {
        return;
    }

    //
}


- (void)consoleReceivedStopMsgPYMan:(NSData *)mac_address{
    
    if (! self.isDebugModeEnabled) {
        return;
    }


    NSDate* newEndDate = [NSDate date];

    dispatch_async(self.serialQueueBleConnections, ^{
        
        for (YManReporter* yMan in self.yMen) {
            if ([[yMan macAddress] isEqualToData:mac_address]) {
                
                [yMan setNewYManEndDate:newEndDate];
                [yMan setInsideCycle:NO];
            }
            
            return;
        }
    });
}


- (void)consoleDisconnectedPYMan:(NSData *)mac_address {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        // primary yMan connections
        for (YKSYManConnection *onePYManConnection in self.primaryYManConnections) {
            
            if ([[onePYManConnection macAddress] isEqualToData:mac_address]) {
                onePYManConnection.connected = NO;
                
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.primaryYManStatusDelegate &&
                [self.primaryYManStatusDelegate respondsToSelector:@selector(primaryYManDataAvailable)]) {
                
                [self.primaryYManStatusDelegate primaryYManDataAvailable];
            }
        });
    });
}


- (void)consoleFailedToConnectPYMan:(NSData *)mac_address {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        for (YManReporter* yMan in self.yMen) {
            if ([[yMan macAddress] isEqualToData:mac_address]) {
                
                NSNumber *failures = [yMan failuresGAtoYMan];
                failures = @([failures intValue] + 1);
                [yMan setFailuresGAtoYMan:failures];
                
                return;
            }
        }
    });
}


- (void)cleanRoomsWithPYMan:(NSData *)mac_address andRoomNumber:(NSString *)roomNumber {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    dispatch_async(self.serialQueueBleConnections, ^{
                
        if (roomNumber && roomNumber.length) {
            
            BOOL foundFirstConnection = NO;
            
            for (BLETriangleConnection* oneConnection in [self.activeBleTriangleConnections reverseObjectEnumerator]) {
                
                if ([[oneConnection yManMacAddress] isEqualToData:mac_address]
                    && [[oneConnection roomNumber] isEqualToString:roomNumber]) {
                    
                    if (! foundFirstConnection) {
                        foundFirstConnection = YES;
                        continue;
                    }
                    else {
                        
                        const YKSBLEConnectionYLinkStatus lastStatus = [[oneConnection.yLinkKnownStates lastObject] intValue];
                        YKSBLEConnectionYLinkStatus secondToLast = -1;
                        
                        if ([oneConnection.yLinkKnownStates count] > 1) {
                            secondToLast = [[oneConnection.yLinkKnownStates objectAtIndex:(oneConnection.yLinkKnownStates.count - 2)] intValue];
                        }
                        
                        if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished) {
                            // Usually this case is impossible to happen except this code arrives before
                            // YKSBLEConnectionYLinkProcessedAndFinished is set
                            [self.transitionBLEConnections addObject:oneConnection];
                        }
                        else {
                            [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDisconnected)];
                            [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
                            [self.transitionBLEConnections addObject:oneConnection];
                        }
                        
                    }
                    
                }
            }
            
            // remove
            [self transferFinishedConnections];
        }
    });
    
}


- (void)consoleStartedScanforGA:(NSData*)trackID
                     roomNumber:(NSString *)roomNumber
                          pYMan:(NSData *)mac_address
                  RSSIThreshold:(NSNumber *)rssiThreshold
                        timeout:(NSTimeInterval)timeout {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    DLog(@"EVENT %lu, STARTED SCAN            YMAN: %@     TRACK ID: %@    ROOM: %@",
          (unsigned long)self.eventNumber++,
          [YKSBinaryHelper hexStringFromBinary:mac_address],
          [YKSBinaryHelper hexStringFromBinary:trackID],
          roomNumber);
    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        NSDate* yLinkStartDate = [[NSDate alloc] init];
        
        BOOL foundBleConnection = NO;
        BOOL foundYMan = NO;
        
        
        
        [self.finishedBleTriangleConnections addObjectsFromArray:self.transitionBLEConnections];
        for (BLETriangleConnection *oneConnection in self.transitionBLEConnections) {
            [self logRSSIValuesOfConnection:oneConnection];
            [self.activeBleTriangleConnections removeObject:oneConnection];
        }
        self.transitionBLEConnections = [NSMutableArray array];
        
        
        
        
        NSMutableArray* activeConnectionsCopy = [[NSMutableArray alloc] initWithArray:self.activeBleTriangleConnections copyItems:YES];
        NSMutableArray* finishedConnectionsCopy = [[NSMutableArray alloc] initWithArray:self.finishedBleTriangleConnections copyItems:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.availableBLEConnectionsDataDelegate &&
                [self.availableBLEConnectionsDataDelegate
                 respondsToSelector:@selector(bleConnectionsDataAvailableWithActiveConnections:andFinishedConnections:)]) {
                    [self.availableBLEConnectionsDataDelegate
                     bleConnectionsDataAvailableWithActiveConnections:activeConnectionsCopy
                     andFinishedConnections:finishedConnectionsCopy];
                }
        });
        
        
        
        
        for (YManReporter* yManReporter in self.yMen) {
            if ([[yManReporter macAddress] isEqualToData:mac_address]) {
                
                foundYMan = YES;
                
                for (YLinkReporter* yLinkReporter in self.yLinks) {
                    if ([[yLinkReporter trackID] isEqualToData:trackID]) {
                        
                        for (BLETriangleConnection* oneConnection in [self.activeBleTriangleConnections reverseObjectEnumerator]) {
                            
                            // Amenity doors case (since trackID is the same for some time)
                            if ([[oneConnection yManMacAddress] isEqualToData:[yLinkReporter yManMacAddress]]
                                && [[oneConnection yLinkTrackID] isEqualToData:[yLinkReporter trackID]] ) {
                                
                                if ([[oneConnection.yLinkKnownStates lastObject] isEqualToNumber:@(YKSBLEConnectionYLinkProcessedAndFinished)]) {
                                    
                                    [self.transitionBLEConnections addObject:oneConnection];
                                }
                                else {
                                    foundBleConnection = YES;
                                    
//                                    [yLinkReporter setFailuresGAtoYMan:[yManReporter failuresGAtoYMan]];
//                                    [yLinkReporter setYManMacAddress:mac_address];
//                                    
//                                    [oneConnection setYLinkStartDate:[yLinkStartDate dateByAddingTimeInterval:0]];
//                                    [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
//                                    
//                                    oneConnection.roomNumber = roomNumber;
//                                    oneConnection.rssiThreshold = rssiThreshold;
//                                    oneConnection.timeout = timeout;
//                                    
//                                    continue;
                                }
                                
                                if (foundBleConnection) {
//                                    if (! [[oneConnection.yLinkKnownStates lastObject] isEqualToNumber:@(YKSBLEConnectionYLinkProcessedAndFinished)]) {
//                                        
//                                        [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
//                                        
//                                        [self.transitionBLEConnections addObject:oneConnection];
//                                        
//                                    }
                                }
                            }
                        }
                        
                        [self transferFinishedConnections];
                        [self copyConnectionsArrayAndCallDelegateOnMainThread];
                    }
                }
                
                if (! foundBleConnection) {
                    
                    YLinkReporter* yLinkReporter = [[YLinkReporter alloc] init];
                    
                    [yLinkReporter setFailuresGAtoYMan:[yManReporter failuresGAtoYMan]];
                    
                    [yLinkReporter setYManMacAddress:mac_address];
                    
                    [yLinkReporter setTrackID:trackID];
                    
                    [self.yLinks addObject:yLinkReporter];
                    
                    // Creating BLE triangle connection row
                    BLETriangleConnection* connection = [[BLETriangleConnection alloc] init];

                    [connection setYManMacAddress:[yManReporter macAddress]];
                    [connection setYLinkTrackID:trackID];
                    [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
                    
                    connection.roomNumber = roomNumber;
                    connection.rssiThreshold = rssiThreshold;
                    connection.timeout = timeout;
                    
                    [connection setYLinkStartDate:yLinkStartDate];
                    
                    [self.activeBleTriangleConnections addObject:connection];
                    
                    [self transferFinishedConnections];
                    
                    [self copyConnectionsArrayAndCallDelegateOnMainThread];
                    
                    // This is useful to exit two nested loops, no need to add two BOOL vars
                    // (Just if you're afraid of goto)
                    goto cleanRoom;
                }
                
            }
        }
        
    cleanRoom:
        
        [self cleanRoomsWithPYMan:mac_address andRoomNumber:roomNumber];
        
        if (!foundYMan) {
            //        DLog(@"WARNING: Could not find the yManReporter in consoleStartedScanforGA: %@", mac_address);
        }
    });
}


- (void)consoleDiscoveredDoorforGA:(NSData*)trackID roomNumber:(NSString *)roomNumber pYMan:(NSData *)mac_address RSSI:(NSNumber*)RSSI {

    if (! self.isDebugModeEnabled) {
        return;
    }

    
    DLog(@"EVENT %lu, DISCOVERED DOOR         YMAN: %@     TRACK ID: %@    ROOM: %@",
          (unsigned long)self.eventNumber++,
          [YKSBinaryHelper hexStringFromBinary:mac_address],
          [YKSBinaryHelper hexStringFromBinary:trackID],
          roomNumber);
    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        for (YManReporter* yManReporter in self.yMen) {
            if ([[yManReporter macAddress] isEqualToData:mac_address]) {
                
                for (YLinkReporter* yLinkReporter in self.yLinks) {
                    if ([[yLinkReporter trackID] isEqualToData:trackID]) {
                        
                        // Searching for the right connection
                        
                        for (BLETriangleConnection* oneConnection in [self.activeBleTriangleConnections reverseObjectEnumerator]) {
                            if ([[oneConnection yManMacAddress] isEqualToData:[yLinkReporter yManMacAddress]]
                                && [[oneConnection yLinkTrackID] isEqualToData:[yLinkReporter trackID]]
                                && [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkStartedScan)]
                                ) {
                                // Allow to rediscover the door with different RSSI
                                //                                    && [oneConnection.yLinkKnownStates count] == 1) {
                                
                                if (! [[oneConnection.yLinkKnownStates lastObject] isEqualToNumber:@(YKSBLEConnectionYLinkDiscoveredDoor)]) {
                                    
                                    [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDiscoveredDoor)];
                                }
                                
                                oneConnection.lastScannedRSSIValue = RSSI;
                                [oneConnection.rssiValues addObject:RSSI];
                                
                                if ([RSSI isEqualToNumber:@127]) {
                                    oneConnection.hasBadRSSIReading = YES;
                                }
                                
                                [self transferFinishedConnections];
                                
                                [self copyConnectionsArrayAndCallDelegateOnMainThread];
                                
                                return;
                            }
                        }
                        
                    }
                }
                
            }
        }
    });
}


- (void)consoleDiscoveredGA:(NSData*)trackID pYMan:(NSData *)mac_address {

    if (! self.isDebugModeEnabled) {
        return;
    }
    
    //
}


- (void)consoleConnectedGA:(NSData*)trackID pYMan:(NSData *)mac_address{
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    DLog(@"EVENT %lu, CONNECTED GA            YMAN: %@     TRACK ID: %@",
          (unsigned long)self.eventNumber++,
          [YKSBinaryHelper hexStringFromBinary:mac_address],
          [YKSBinaryHelper hexStringFromBinary:trackID]);
    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        BOOL foundConnection = NO;
        
        for (YManReporter* yManReporter in self.yMen) {
            if ([[yManReporter macAddress] isEqualToData:mac_address]) {
                
                for (YLinkReporter* yLinkReporter in self.yLinks) {
                    if ([[yLinkReporter trackID] isEqualToData:trackID]) {
                        
                        // Searching for the right connection
                        
                        for (BLETriangleConnection* oneConnection in [self.activeBleTriangleConnections reverseObjectEnumerator]) {
                            if ([[oneConnection yManMacAddress] isEqualToData:[yLinkReporter yManMacAddress]]
                                && [[oneConnection yLinkTrackID] isEqualToData:[yLinkReporter trackID]]
                                && [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkStartedScan)]
                                && [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkDiscoveredDoor)]
                                && ! [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkReceivedWriteConf)]
                                && ! [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkProcessedAndFinished)]
                                ){
                                
                                foundConnection = YES;
                                
                                [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkConnected)];
                                
                                [self transferFinishedConnections];
                                
                                [self copyConnectionsArrayAndCallDelegateOnMainThread];
                                
                                return;
                            }
                        }
                        
                        if (!foundConnection) {
                            //
                            for (BLETriangleConnection* oneConnection in [self.finishedBleTriangleConnections reverseObjectEnumerator]) {
                                if ([[oneConnection yManMacAddress] isEqualToData:[yLinkReporter yManMacAddress]]
                                    && [[oneConnection yLinkTrackID] isEqualToData:[yLinkReporter trackID]]
                                    
                                    && [[oneConnection.yLinkKnownStates lastObject] isEqualToNumber:@(YKSBLEConnectionYLinkProcessedAndFinished)]
                                    )
                                {
                                    // Creating BLE triangle connection row
                                    BLETriangleConnection* connection = [[BLETriangleConnection alloc] init];

                                    [connection setYManMacAddress:oneConnection.yManMacAddress];
                                    [connection setYLinkTrackID:trackID];
                                    
                                    [connection setYLinkStartDate:[oneConnection.yLinkStartDate dateByAddingTimeInterval:0]];
                                    
                                    [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
                                    [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDiscoveredDoor)];
                                    
                                    connection.roomNumber = oneConnection.roomNumber;
                                    
                                    [self.activeBleTriangleConnections addObject:connection];
                                    
                                    [self copyConnectionsArrayAndCallDelegateOnMainThread];
                                    
                                    [self consoleConnectedGA:trackID pYMan:mac_address];
                                    
                                    return;
                                }
                            }
                        }
                        
                    }
                }
                
            }
        }
    });
}


// add total time + green for yLink/GAuth
- (void)consoleReceivedWriteConfirmation:(NSData*)trackID pYMan:(NSData *)mac_address{
    
    if (! self.isDebugModeEnabled) {
        return;
    }


    DLog(@"EVENT %lu, RECEIVED WRITE CONF     YMAN: %@     TRACK ID: %@",
          (unsigned long)self.eventNumber++,
          [YKSBinaryHelper hexStringFromBinary:mac_address],
          [YKSBinaryHelper hexStringFromBinary:trackID]);
    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        NSDate* yLinkEndDate = [NSDate date];
        
        for (YManReporter* yManReporter in self.yMen) {
            if ([[yManReporter macAddress] isEqualToData:mac_address]) {
                
                
                for (YLinkReporter* yLinkReporter in self.yLinks) {
                    
                    if ([[yLinkReporter trackID] isEqualToData:trackID]) {
                        
                        NSNumber* gaToYmanFailures = [yManReporter failuresGAtoYMan];

                        [yLinkReporter setFailuresGAtoYMan:gaToYmanFailures];
                        [yLinkReporter setCompleted:@1];
                        
                        // Searching for the right connection
                        for (BLETriangleConnection* oneConnection in [self.activeBleTriangleConnections reverseObjectEnumerator]) {
                            
                            if ([[oneConnection yManMacAddress] isEqualToData:[yManReporter macAddress]]
                                &&
                                [[oneConnection yLinkTrackID] isEqualToData:[yLinkReporter trackID]]
                                
                                && [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkConnected)]
                                
                                && [[oneConnection.yLinkKnownStates lastObject] isEqualToNumber:@(YKSBLEConnectionYLinkConnected)]
                                
                                ) {
                                
                                [oneConnection setYLinkEndDate:yLinkEndDate];
                                
                                NSTimeInterval yLinkTime = [oneConnection.yLinkEndDate timeIntervalSinceDate:oneConnection.yLinkStartDate];
                                
                                [oneConnection setYLinkTimeInterval:yLinkTime];
                                
                                [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkReceivedWriteConf)];
                                [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
                                
                                oneConnection.hasReceivedWriteConfirmation = YES;
                                
                                [self transferFinishedConnections];
                                
                                [self copyConnectionsArrayAndCallDelegateOnMainThread];
                                
                                return;
                            }
                        }
                        
                    }
                }
                
            }
        }
    });
}


- (void)consoleDisconnectedGA:(NSData*)trackID pYMan:(NSData *)mac_address{
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    DLog(@"EVENT %lu, DISCONNECTED GA         YMAN: %@     TRACK ID: %@",
          (unsigned long)self.eventNumber++,
          [YKSBinaryHelper hexStringFromBinary:mac_address],
          [YKSBinaryHelper hexStringFromBinary:trackID]);
    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        // First, get all matching yLink Reports
        NSMutableArray *yLinkReportersForTrackID = [NSMutableArray array];
        
        for (YLinkReporter* yLinkReporter in self.yLinks) {
            
            if ([yLinkReporter.trackID isEqualToData:trackID]) {
                [yLinkReportersForTrackID addObject:yLinkReporter];
            }
        }
        
        // Searching for the right connection
        for (BLETriangleConnection* oneConnection in [self.activeBleTriangleConnections reverseObjectEnumerator]) {
            if ([[oneConnection yManMacAddress] isEqualToData:mac_address]
                &&
                [[oneConnection yLinkTrackID] isEqualToData:trackID] ) {
                
                
                if ([oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkReceivedWriteConf)]) {
                    
                    [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDisconnected)];
                    [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
                    
                    [self.transitionBLEConnections addObject:oneConnection];
                }
                else if ([oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkConnected)]
                         && ! [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkProcessedAndFinished)]) {
                    
                    [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDisconnected)];
                }
                
                [self transferFinishedConnections];
                
                [self copyConnectionsArrayAndCallDelegateOnMainThread];
                
                //TODO: Clean self.yLinks after some time
                return;
            }
        }
    });
}


// BLE Triangle failure:
- (void)consoleDidFail:(NSData*)trackID pYman:(NSData *)mac_address{
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    DLog(@"EVENT %lu, DID FAIL                YMAN: %@     TRACK ID: %@",
          (unsigned long)self.eventNumber++,
          [YKSBinaryHelper hexStringFromBinary:mac_address],
          [YKSBinaryHelper hexStringFromBinary:trackID]);
    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        for (YManReporter* yManReporter in self.yMen) {
            if ([[yManReporter macAddress] isEqualToData:mac_address]) {
                
                for (YLinkReporter* yLinkReporter in self.yLinks) {
                    
                    if ([[yLinkReporter trackID] isEqualToData:trackID] && !yLinkReporter.completed.boolValue) {
                        
                        yLinkReporter.completed = @1;
                        
                        // Searching for the right connection
                        
                        BOOL foundConnection = NO;
                        
                        for (BLETriangleConnection* oneConnection in [self.activeBleTriangleConnections reverseObjectEnumerator]) {
                            if ([[oneConnection yManMacAddress] isEqualToData:[yLinkReporter yManMacAddress]]
                                &&
                                [[oneConnection yLinkTrackID] isEqualToData:[yLinkReporter trackID]] ) {
                                
                                foundConnection = YES;
                                
                                //TODO: inquire if the order is correct: first failed and then finished or viceversa
                                [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
                                [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkFailed)];
                                
                                [self.transitionBLEConnections addObject:oneConnection];
                                
                                [self transferFinishedConnections];
                                
                                [self copyConnectionsArrayAndCallDelegateOnMainThread];
                                
                                [self.yLinks removeObject:yLinkReporter];
                                
                                
                                return;
                            }
                        }
                        
                        
                        if (!foundConnection) {
                            //
                            for (BLETriangleConnection* oneConnection in [self.finishedBleTriangleConnections reverseObjectEnumerator]) {
                                if ([[oneConnection yManMacAddress] isEqualToData:[yLinkReporter yManMacAddress]]
                                    && [[oneConnection yLinkTrackID] isEqualToData:[yLinkReporter trackID]]
                                    
                                    && [[oneConnection.yLinkKnownStates lastObject] isEqualToNumber:@(YKSBLEConnectionYLinkProcessedAndFinished)]
                                    )
                                {
                                    
                                    
                                    // Creating BLE triangle connection row
                                    BLETriangleConnection* connection = [[BLETriangleConnection alloc] init];
                                    [connection setYManMacAddress:oneConnection.yManMacAddress];
                                    [connection setYLinkTrackID:trackID];
                                    
                                    [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
                                    [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDiscoveredDoor)];
                                    
                                    connection.roomNumber = oneConnection.roomNumber;
                                    
                                    [self.activeBleTriangleConnections addObject:connection];
                                    
                                    [self consoleDidFail:trackID pYman:mac_address];
                                    
                                    return;
                                }
                            }
                        }
                    }
                }
            }
        }
    });
}


// BLE Triangle expiration:
- (void)consoleDidExpire:(NSData *)trackID pYman:(NSData *)mac_address {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    DLog(@"EVENT %lu, DID EXPIRE              YMAN: %@     TRACK ID: %@",
          (unsigned long)self.eventNumber++,
          [YKSBinaryHelper hexStringFromBinary:mac_address],
          [YKSBinaryHelper hexStringFromBinary:trackID]);
    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        for (YManReporter* yManReporter in self.yMen) {
            if ([[yManReporter macAddress] isEqualToData:mac_address]) {
            }
        }
        
        
        for (YLinkReporter* yLinkReporter in self.yLinks) {
            
            if ([[yLinkReporter trackID] isEqualToData:trackID] && !yLinkReporter.completed.boolValue) {
                
                yLinkReporter.completed = @1;
                
                // Searching for the right connection
                BOOL foundConnection = NO;
                
                for (BLETriangleConnection* oneConnection in [self.activeBleTriangleConnections reverseObjectEnumerator]) {
                    
                    if ([[oneConnection yManMacAddress] isEqualToData:[yLinkReporter yManMacAddress]]
                        &&
                        [[oneConnection yLinkTrackID] isEqualToData:[yLinkReporter trackID]]
                        && ! [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkProcessedAndFinished)]) {
                        
                        [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkExpired)];
                        [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
                        
                        [self.transitionBLEConnections addObject:oneConnection];
                        
                        [self transferFinishedConnections];
                        
                        [self copyConnectionsArrayAndCallDelegateOnMainThread];
                        
                        [self.yLinks removeObject:yLinkReporter];
                        
                        
                        return;
                    }
                }
            
                
                
                if (!foundConnection) {
                    //
                    for (BLETriangleConnection* oneConnection in [self.finishedBleTriangleConnections reverseObjectEnumerator]) {
                        if ([[oneConnection yManMacAddress] isEqualToData:[yLinkReporter yManMacAddress]]
                            && [[oneConnection yLinkTrackID] isEqualToData:[yLinkReporter trackID]]
                            
                            && [[oneConnection.yLinkKnownStates lastObject] isEqualToNumber:@(YKSBLEConnectionYLinkProcessedAndFinished)]
                            )
                        {
                            
                            // Creating BLE triangle connection row
                            BLETriangleConnection* connection = [[BLETriangleConnection alloc] init];
                            [connection setYManMacAddress:oneConnection.yManMacAddress];
                            [connection setYLinkTrackID:trackID];
                            
                            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
                            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDiscoveredDoor)];
                            
                            connection.roomNumber = oneConnection.roomNumber;
                            
                            [self.activeBleTriangleConnections addObject:connection];
                            
                            [self consoleDidExpire:trackID pYman:mac_address];
                            
                            return;
                        }
                    }
                }

            
            
            }
        }
    });
}

- (void)consoleExpiredAllGuestAuths {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    dispatch_async(self.serialQueueBleConnections, ^{
        
        for (BLETriangleConnection* oneConnection in [self.activeBleTriangleConnections reverseObjectEnumerator]) {
            
            const YKSBLEConnectionYLinkStatus lastStatus = [[oneConnection.yLinkKnownStates lastObject] intValue];
            YKSBLEConnectionYLinkStatus secondToLast = -1;
            
            if ([oneConnection.yLinkKnownStates count] > 1) {
                secondToLast = [[oneConnection.yLinkKnownStates objectAtIndex:(oneConnection.yLinkKnownStates.count - 2)] intValue];
            }
            
            
            if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
                && secondToLast == YKSBLEConnectionYLinkReceivedWriteConf) {
                [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkExpired)];
                [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
                
                [self.transitionBLEConnections addObject:oneConnection];
            }
            
            if (lastStatus == YKSBLEConnectionYLinkStartedScan
                || lastStatus == YKSBLEConnectionYLinkDiscoveredDoor) {
                
                [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkExpired)];
                [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
                
                [self.transitionBLEConnections addObject:oneConnection];
            }
            
            if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
                && secondToLast == YKSBLEConnectionYLinkReceivedWriteConf) {
                [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDisconnected)];
                [oneConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
                
                [self.transitionBLEConnections addObject:oneConnection];
            }
            
            [self transferFinishedConnections];

            [self copyConnectionsArrayAndCallDelegateOnMainThread];
        }
    });
}

- (void)consoleLogCriticalError:(NSError *)error {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    //    [[AppManager sharedInstance] sendPushNotificationWithAlert:error.localizedDescription];
}

- (void)callConnectionsAndLogsDelegates {
    
    if (! self.isDebugModeEnabled) {
        return;
    }


    [self copyConnectionsArrayAndCallDelegateOnMainThread];
    
    [self copyLogsArrayAndCallDelegateOnMainThread];
}


- (void)logRSSIValuesOfConnection:(BLETriangleConnection *)oneConnection {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    NSMutableArray *rssiValues = [NSMutableArray arrayWithArray:oneConnection.rssiValues];
    NSMutableString *rssiValuesString = [NSMutableString string];
    NSString *yManMacAddressString = [NSString stringWithString:[YKSBinaryHelper hexStringFromBinary:oneConnection.yManMacAddress]];
    NSString *yLinkTrackId = [NSString stringWithString:[YKSBinaryHelper hexStringFromBinary:oneConnection.yLinkTrackID]];
    NSDateFormatter *formatter = [[YKSDateHelper sharedInstance] timeOnlyHHmmssDateFormatter];
    NSString *startTime = [formatter stringFromDate:oneConnection.yLinkStartDate];

    unsigned long rssiValuesCount = rssiValues.count;
    NSNumber *oneRssiValue;
    
    for (int i = 0; i < rssiValuesCount; i++) {

        oneRssiValue = [rssiValues objectAtIndex:i];
        NSString *rssiString;
        
        if (rssiValuesCount - 1 == i) {
            rssiString = [NSString stringWithFormat:@"%d", oneRssiValue.intValue];
        }
        else {
            rssiString = [NSString stringWithFormat:@"%d, ", oneRssiValue.intValue];
        }
        
        [rssiValuesString appendString:rssiString];
    }
    
    NSString *messageToLog = [NSString stringWithFormat:@"Connection started at %@, yMan: %@, track ID: %@ had RSSI values: %@",
                              startTime, yManMacAddressString, yLinkTrackId, rssiValuesString];
    
    [self logMessage:messageToLog withErrorLevel:YKSErrorLevelInfo andType:YKSLogMessageTypeBLE];
}


- (void)logMessage:(NSString *)message withErrorLevel:(YKSErrorLevel)errorLevel andType:(YKSLogMessageType)logMessageType {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    dispatch_async(self.serialQueueConsoleLogs, ^{
        
        NSCharacterSet *separatorsSet = [NSCharacterSet newlineCharacterSet];
        NSArray *list = [message componentsSeparatedByCharactersInSet:separatorsSet];
        NSMutableArray *formattedList = [NSMutableArray array];
        
        // In this for loop, if a string is longer than MAX_CHARS_PER_LIGNE_IN_CONSOLE,
        // we split it in shorter strings so it's displayed in a cell with same font size
        // as shorter strings
        for (NSString* __strong longString in list) {
            while (MAX_CHARS_PER_LIGNE_IN_CONSOLE < [longString length]) {
                
                NSInteger indexToCut = MAX_CHARS_PER_LIGNE_IN_CONSOLE;
                
                // make sure to wrap the words before breaking the lines:
                unichar space = ' ';
                while ([longString characterAtIndex:indexToCut] != space) {
                    indexToCut--;
                }
                
                if (indexToCut <= 0) {
                    // a space wasn't found, will cut the string anyway
                    indexToCut = MAX_CHARS_PER_LIGNE_IN_CONSOLE;
                }
                
                NSString* shortString = [longString substringToIndex:indexToCut];
                
                [formattedList addObject:shortString];
                
                // remove shortString from longString
                NSString* remainingLongString = [longString substringFromIndex:indexToCut];
                longString = remainingLongString;
            }
            
            if (0 < [longString length]) {
                [formattedList addObject:longString];
            }
        }
        
        
        for (NSString* logSubString in formattedList) {
            
            self.numberOfLinesOfLogMessagesBuffer++;
            NSString *logMessage;
            
            
#ifndef DEBUG_PREPEND_LINE_NUMBER
            [[YKSFileLogger sharedInstance] logToFileAMessage:logSubString withErrorLevel:errorLevel andLogMessageType:logMessageType];
#endif
            
            NSString *timestamp = [NSString stringWithFormat:@"%@:  ", [[[YKSDateHelper sharedInstance] timeOnlymmssDateFormatter] stringFromDate:[NSDate date]]];
            logMessage = [timestamp stringByAppendingString:logSubString];
            
#ifdef DEBUG_PREPEND_LINE_NUMBER
            logMessage = [NSString stringWithFormat:@"%lu  %@", self.numberOfLinesOfLogMessagesBuffer, logMessage];
            [[YKSFileLogger sharedInstance] logToFileAMessage:[NSString stringWithFormat:@"%lu %@", self.numberOfLinesOfLogMessagesBuffer, logSubString] withErrorLevel:errorLevel andLogMessageType:logMessageType];
#endif
            
            NSDictionary *encapsulatedMessage = @{
                                                  @"logMessage": logMessage,
                                                  @"YKSErrorLevel":[NSNumber numberWithInt:errorLevel],
                                                  @"YKSLogMessageType":[NSNumber numberWithInt:logMessageType]
                                                  };
            [self.logMessagesBuffer addObject:encapsulatedMessage];
        }
        
        
        // Remove some lines in order to keep buffer max size
        // Only if scrolling is not paused
        BOOL isScrollingPaused = [YKSDebugManager sharedManager].isLogScrollingPausedInDebugConsoleViewController;
        
        if (! isScrollingPaused) {
            if (MAX_NUMBER_OF_CONSOLE_DEBUG_LINES < [self.logMessagesBuffer count]) {
                
                [self.logMessagesBuffer removeObjectsAtIndexes:
                 [NSIndexSet indexSetWithIndexesInRange:
                  NSMakeRange(0,
                              MAX_NUMBER_OF_CONSOLE_DEBUG_LINES - MIN_NUMBER_OF_CONSOLE_DEBUG_LINES)
                  ]];
            }
        }
        
        [self copyLogsArrayAndCallDelegateOnMainThread];
    });
    
}



- (void)shouldPauseLogsToDebugConsole:(BOOL)shouldPause {
    
    if (! self.isDebugModeEnabled) {
        return;
    }

    
    dispatch_async(self.serialQueueConsoleLogs, ^{

        NSDictionary *encapsulatedMessage;
        
        if (shouldPause) {
            
            encapsulatedMessage = @{
                                    @"logMessage": @"### PAUSED LOGS AUTO SCROLL ###",
                                    @"YKSErrorLevel":[NSNumber numberWithInt:YKSErrorLevelInfo],
                                    @"YKSLogMessageType":[NSNumber numberWithInt:YKSLogMessageTypeService]
                                    };
        }
        else {
            encapsulatedMessage = @{
                                    @"logMessage": @"### RESUMED LOGS AUTO SCROLL ###",
                                    @"YKSErrorLevel":[NSNumber numberWithInt:YKSErrorLevelInfo],
                                    @"YKSLogMessageType":[NSNumber numberWithInt:YKSLogMessageTypeService]
                                    };
        }
        
        
        [self.logMessagesBuffer addObject:encapsulatedMessage];
        
        
        [self copyLogsArrayAndCallDelegateOnMainThread];
        
        self.isLogScrollingPausedInDebugConsoleViewController = shouldPause;
    });
}





#pragma mark - Debugging methods
// Call it at some breakpoint
- (void)printBleConnectionsState {
    
    for (BLETriangleConnection *oneConnection in self.activeBleTriangleConnections) {
        DLog(@">>>>>>>>>>>>>>>>>>>>>");
        DLog(@"yman :%@", oneConnection.yManMacAddress);
        DLog(@"ylink: %@", oneConnection.yLinkTrackID);
        DLog(@"Room number: %@", oneConnection.roomNumber);
        
        for (NSNumber *state in oneConnection.yLinkKnownStates) {
            DLog(@"State: %@", valueForState(state.intValue));
        }
        DLog(@"<<<<<<<<<<<\n");
    }
    
}

@end
