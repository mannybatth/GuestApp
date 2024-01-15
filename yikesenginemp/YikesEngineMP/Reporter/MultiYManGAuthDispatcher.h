//
//  GAuth.h
//  Pods
//
//  Created by Alexandar Dimitrov on 2014-12-12.
//
//

#import <Foundation/Foundation.h>

@protocol YKSBLETriangleConsoleDelegate;
@protocol YKSBLEStationaryAndMotionDelegate;

@interface MultiYManGAuthDispatcher : NSObject

@property (nonatomic, weak) id<YKSBLETriangleConsoleDelegate> bleTriangleConsoleDelegate;
@property (nonatomic, weak) id<YKSBLEStationaryAndMotionDelegate> bleStationaryAndMotionDelegate;

+ (MultiYManGAuthDispatcher *)sharedInstance;

// stationary device, iBeacon region
- (void)deviceIsNotMoving;
- (void)deviceIsMoving;
- (void)deviceIsInsideIBeaconRegion;
- (void)deviceIsOutsideIBeaconRegion;

// primary yMan
- (void)startedScanForPYMan:(NSData *)mac_address;
- (void)receivedStopMsgPYMan:(NSData *)mac_address;
- (void)disconnectedPYMan:(NSData *)mac_address;
- (void)failedToConnectPYMan:(NSData *)mac_address;
- (void)connectToYMan:(NSData *)mac_address;

// not used
- (void)didEnterYManRegion:(NSData *)mac_address;

// Guest Auth
- (void)startedScanforGA:(NSData*)trackID
              roomNumber:(NSString*)roomNumber
                   pYMan:(NSData *)mac_address
           RSSIThreshold:(NSNumber *)rssiThreshold
                 timeout:(NSTimeInterval)timeout;

- (void)discoveredDoorforGA:(NSData*)trackID
                 roomNumber:(NSString*)roomNumber
                      pYMan:(NSData *)mac_address
                       RSSI:(NSNumber *)RSSI;

- (void)discoveredGA:(NSData*)trackID pYMan:(NSData *)mac_address;
- (void)connectedGA:(NSData*)trackID pYMan:(NSData *)mac_address;
- (void)receivedWriteConfirmation:(NSData*)trackID pYMan:(NSData *)mac_address;
- (void)disconnectedGA:(NSData*)trackID pYMan:(NSData *)mac_address;
- (void)didFail:(NSData*)trackID pYman:(NSData *)mac_address;
- (void)didExpire:(NSData*)trackID pYman:(NSData*)mac_address;

- (void)startedScanForPrimaryYManList:(NSArray *)pYManList;
- (void)stoppedScanForPrimaryYMan;

- (void)expireAllGuestAuths;

// Monitoring
- (void)sendCriticalError:(NSError *)error;

@end




@protocol YKSBLETriangleConsoleDelegate <NSObject>

// Same methods like in this class, but for the delegate
// To be refactored
@optional
- (void)bleConnectionsWithYMen:(NSMutableArray*) yMen andYLinks:(NSMutableArray*) yLinks;
- (void)consoleLogCriticalError;

@required

- (void)consoleStartedScanForPrimaryYManList:(NSArray *)pYManList;
- (void)consoleStoppedScanForPrimaryYMan;

- (void)consoleStartedScanForPYMan:(NSData *)mac_address;
- (void)consoleConnectToYMan:(NSData *)mac_address;
- (void)consoleDiscoveredPYMan:(NSData *)mac_address;
- (void)consoleReceivedStopMsgPYMan:(NSData *)mac_address;
- (void)consoleDisconnectedPYMan:(NSData *)mac_address;
- (void)consoleFailedToConnectPYMan:(NSData *)mac_address;
- (void)consoleExpiredAllGuestAuths;
- (void)consoleLogCriticalError:(NSError *)error;

- (void)consoleStartedScanforGA:(NSData*)trackID
                     roomNumber:(NSString *)roomNumber
                          pYMan:(NSData *)mac_address
                  RSSIThreshold:(NSNumber *)rssiThreshold
                        timeout:(NSTimeInterval)timeout;

- (void)consoleDiscoveredDoorforGA:(NSData*)trackID
                        roomNumber:(NSString*)roomNumber
                             pYMan:(NSData *)mac_address
                              RSSI:(NSNumber *)RSSI;

- (void)consoleDiscoveredGA:(NSData*)trackID pYMan:(NSData *)mac_address;
- (void)consoleConnectedGA:(NSData*)trackID pYMan:(NSData *)mac_address;
- (void)consoleReceivedWriteConfirmation:(NSData*)trackID pYMan:(NSData *)mac_address;
- (void)consoleDisconnectedGA:(NSData*)trackID pYMan:(NSData *)mac_address;
- (void)consoleDidFail:(NSData*)trackID pYman:(NSData *)mac_address;
- (void)consoleDidExpire:(NSData*)trackID pYman:(NSData *)mac_address;

@end




@protocol YKSBLEStationaryAndMotionDelegate <NSObject>

@optional

- (void)consoleDeviceBecameStationary;
- (void)consoleDeviceBecameToMove;

// iBeacon region
- (void)consoleDeviceEnteredIBeaconRegion;
- (void)consoleDeviceExitedIBeaconRegion;

@end
