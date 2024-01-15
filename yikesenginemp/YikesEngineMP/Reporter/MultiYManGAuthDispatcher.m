//
//  GAuth.m
//  Pods
//
//  Created by Alexandar Dimitrov on 2014-12-12.
//
//

#import "MultiYManGAuthDispatcher.h"
#import "PrimaryYManDispatcher.h"
#import "YKSFileLogger.h"

#import "YManReporter.h"
#import "YLinkReporter.h"
#import "GuestAuth.h"

#import "YikesBLEConstants.h"

#import "YKSDebugManager.h"

@import YikesSharedModel;

static NSDateFormatter* csvDateFormatter;

@interface MultiYManGAuthDispatcher()

@end


@implementation MultiYManGAuthDispatcher

+ (MultiYManGAuthDispatcher *)sharedInstance {
    
    static MultiYManGAuthDispatcher *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}


- (id) init {
    
    self = [super init];
    if (self) {
    }
    
    return self;
}


#pragma mark - Monitoring

- (void)sendCriticalError:(NSError *)error {
    if (self.bleTriangleConsoleDelegate && [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleLogCriticalError:)]) {
        [self.bleTriangleConsoleDelegate consoleLogCriticalError:error];
    }
}

#pragma mark - stationary device

- (void) deviceIsNotMoving {
    if (self.bleStationaryAndMotionDelegate &&
        [self.bleStationaryAndMotionDelegate respondsToSelector:@selector(consoleDeviceBecameStationary)]) {
        
        [self.bleStationaryAndMotionDelegate consoleDeviceBecameStationary];
    }
}


- (void)deviceIsMoving {
    if (self.bleStationaryAndMotionDelegate &&
        [self.bleStationaryAndMotionDelegate respondsToSelector:@selector(consoleDeviceBecameToMove)]) {

        [self.bleStationaryAndMotionDelegate consoleDeviceBecameToMove];
    }
}


#pragma mark - iBeacon region

- (void) deviceIsInsideIBeaconRegion {
    if (self.bleStationaryAndMotionDelegate &&
        [self.bleStationaryAndMotionDelegate respondsToSelector:@selector(consoleDeviceEnteredIBeaconRegion)]) {
        
        [self.bleStationaryAndMotionDelegate consoleDeviceEnteredIBeaconRegion];
    }
}


- (void) deviceIsOutsideIBeaconRegion {
    if (self.bleStationaryAndMotionDelegate &&
        [self.bleStationaryAndMotionDelegate respondsToSelector:@selector(consoleDeviceExitedIBeaconRegion)]) {
        
        [self.bleStationaryAndMotionDelegate consoleDeviceExitedIBeaconRegion];
    }
}


#pragma mark - Primary yMAN events

- (void)startedScanForPrimaryYManList:(NSArray *)pYManList {
    
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleStartedScanForPrimaryYManList:)]) {
        
        [self.bleTriangleConsoleDelegate consoleStartedScanForPrimaryYManList:pYManList];
    }
    
    
}


- (void)stoppedScanForPrimaryYMan {
    
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleStoppedScanForPrimaryYMan)]) {
        
        [self.bleTriangleConsoleDelegate consoleStoppedScanForPrimaryYMan];
    }

}


- (void)startedScanForPYMan:(NSData *)mac_address{
    
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleStartedScanForPYMan:)]) {
        
        [self.bleTriangleConsoleDelegate consoleStartedScanForPYMan:mac_address];
    }
}


- (void)connectToYMan:(NSData *)mac_address {
    
    // Delegate call
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleConnectToYMan:)]) {
        
        [self.bleTriangleConsoleDelegate consoleConnectToYMan:mac_address];
    }

}


- (void)receivedStopMsgPYMan:(NSData *)mac_address{
    
    // Delegate call
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleReceivedStopMsgPYMan:)]) {
        
        [self.bleTriangleConsoleDelegate consoleReceivedStopMsgPYMan:mac_address];
    }
}


- (void)disconnectedPYMan:(NSData *)mac_address{
}


- (void)didEnterYManRegion:(NSData *)mac_address {
}


- (void)failedToConnectPYMan:(NSData *)mac_address {
    
    // Delegate call
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleFailedToConnectPYMan:)]) {
        
        [self.bleTriangleConsoleDelegate consoleFailedToConnectPYMan:mac_address];
    }
    
}


#pragma mark - yLink / GuestAuth

- (void)startedScanforGA:(NSData*)trackID
              roomNumber:(NSString*)roomNumber
                   pYMan:(NSData *)mac_address
           RSSIThreshold:(NSNumber *)rssiThreshold
                 timeout:(NSTimeInterval)timeout {

    // Delegate call
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleStartedScanforGA:roomNumber:pYMan:RSSIThreshold:timeout:)]) {
        
        [self.bleTriangleConsoleDelegate consoleStartedScanforGA:trackID
                                                      roomNumber:roomNumber
                                                           pYMan:mac_address
                                                   RSSIThreshold:rssiThreshold
                                                         timeout:timeout];
    }
    
}


- (void)discoveredDoorforGA:(NSData*)trackID roomNumber:(NSString*)roomNumber pYMan:(NSData *)mac_address RSSI:(NSNumber *)RSSI {
    
    
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleDiscoveredDoorforGA:roomNumber:pYMan:RSSI:)]) {
        
        [self.bleTriangleConsoleDelegate consoleDiscoveredDoorforGA:trackID roomNumber:roomNumber pYMan:mac_address RSSI:RSSI];
    }
}

- (void)discoveredGA:(NSData*)trackID pYMan:(NSData *)mac_address {
}


- (void)connectedGA:(NSData*)trackID pYMan:(NSData *)mac_address{
    
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleConnectedGA:pYMan:)]) {
        
        [self.bleTriangleConsoleDelegate consoleConnectedGA:trackID pYMan:mac_address];
    }
}


- (void)receivedWriteConfirmation:(NSData*)trackID pYMan:(NSData *)mac_address{
    
    // Delegate call
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleReceivedWriteConfirmation:pYMan:)]) {
        
        [self.bleTriangleConsoleDelegate consoleReceivedWriteConfirmation:trackID pYMan:mac_address];
    }
}


- (void)disconnectedGA:(NSData*)trackID pYMan:(NSData *)mac_address{
    
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleDisconnectedGA:pYMan:)]) {
        
        [self.bleTriangleConsoleDelegate consoleDisconnectedGA:trackID pYMan:mac_address];
    }
}


- (void)didFail:(NSData *)trackID pYman:(NSData *)mac_address {
    
    [self didFail:trackID pYman:mac_address updateStatusArea:YES];
}


- (void)didFail:(NSData *)trackID pYman:(NSData *)mac_address updateStatusArea:(BOOL)update {
    
    if (update) {
        // Delegate call
        if (self.bleTriangleConsoleDelegate &&
            [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleDidFail:pYman:)]) {
            
            [self.bleTriangleConsoleDelegate consoleDidFail:trackID pYman:mac_address];
        }
    }
    
}

- (void)expireAllGuestAuths {
    
    // Delegate call
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleExpiredAllGuestAuths)]) {
        
        [self.bleTriangleConsoleDelegate consoleExpiredAllGuestAuths];
    }
}


- (void)didExpire:(NSData *)trackID pYman:(NSData *)mac_address {
    
    // Delegate call
    if (self.bleTriangleConsoleDelegate &&
        [self.bleTriangleConsoleDelegate respondsToSelector:@selector(consoleDidExpire:pYman:)]) {
        
        [self.bleTriangleConsoleDelegate consoleDidExpire:trackID pYman:mac_address];
    }
}


#pragma mark - date formatters


- (NSString*) formattedDateFileStamp:(NSDate*)currentDate {
    
    if (currentDate) {
        NSTimeZone *localTimeZone = [NSTimeZone localTimeZone];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormat setTimeZone:localTimeZone];
        
        return [dateFormat stringFromDate:currentDate];
    } else {
        return @"Error: No current date!";
    }
}


- (NSString*) formattedDate:(NSDate*)currentDate {
    
    if (currentDate) {
        NSTimeZone *localTimeZone = [NSTimeZone localTimeZone];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        [dateFormat setTimeZone:localTimeZone];
        
        return [dateFormat stringFromDate:currentDate];
    } else {
        
        NSDate* now = [NSDate date];
        NSString* nowDateString = [self formattedDate:now];
        
        return [NSString stringWithFormat:@"Error: No current date at %@!", nowDateString];
    }
}


- (NSDateFormatter *)csvDateFormatter {
    if (!csvDateFormatter) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd@HH:mm:ss.SSS"];
        csvDateFormatter = dateFormatter;
    }
    
    return csvDateFormatter;
}

@end
