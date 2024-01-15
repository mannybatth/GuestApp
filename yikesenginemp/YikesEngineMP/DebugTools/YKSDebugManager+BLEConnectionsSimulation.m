//
//  YKSDebugManager+BLEConnectionsSimulation.m
//  yEngine
//
//  Created by Alexandar Dimitrov on 2015-09-21.
//
//

#import "YKSDebugManager+BLEConnectionsSimulation.h"
#import "BLETriangleConnection.h"


@implementation YKSDebugManager (BLEConnectionsSimulation)

- (void)startAddingNewRSSIValues {
    
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(addNewRSSIValues) userInfo:nil repeats:YES];
}

- (void)addNewRSSIValues {
    dispatch_async(self.serialQueueBleConnections, ^{
        
        BLETriangleConnection *lastConnection = [self.activeBleTriangleConnections lastObject];
        
        int r = arc4random_uniform(30);
        r += 60;
        r *= -1;
        
        NSNumber *newRssiDiscovered = [NSNumber numberWithInt:r];
        
//        if (r < -64) {
//            [lastConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkReceivedWriteConf)];
//            [lastConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDisconnected)];
//            [lastConnection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
//            [self transferFinishedConnections];
//            
//        }
        
        [lastConnection.rssiValues addObject:newRssiDiscovered];
        lastConnection.lastScannedRSSIValue = newRssiDiscovered;
        
        [self callConnectionsAndLogsDelegates];
    });
}



- (void)createFakeConnection {
    dispatch_async(self.serialQueueBleConnections, ^{
        
        const char yManMacAddress[] = {
            0xc0,0xff,0xee,
            0x00,0xbe,0xef, };
        
        {
            // Creating BLE triangle connection row
            BLETriangleConnection* connection = [[BLETriangleConnection alloc] init];
            [connection setYManMacAddress:[NSData dataWithBytes:yManMacAddress length:6]];
            [connection setYLinkTrackID:[NSData dataWithBytes:yManMacAddress length:6]];
            
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDiscoveredDoor)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkConnected)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkReceivedWriteConf)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
            connection.hasReceivedWriteConfirmation = YES;
            connection.hasBadRSSIReading = NO;
            
            [connection.rssiValues addObject:@-112];
            [connection.rssiValues addObject:@-85];
            [connection.rssiValues addObject:@-80];
            [connection.rssiValues addObject:@-91];
            [connection.rssiValues addObject:@-20];
            
            connection.roomNumber = @"Stairwell_2";
            connection.yLinkStartDate = [NSDate date];
            connection.yLinkEndDate = [NSDate dateWithTimeInterval:3211 sinceDate:connection.yLinkStartDate];
            
            [self.finishedBleTriangleConnections addObject:connection];
        }

        
        
        
        {
            // Creating BLE triangle connection row
            BLETriangleConnection* connection = [[BLETriangleConnection alloc] init];
            [connection setYManMacAddress:[NSData dataWithBytes:yManMacAddress length:6]];
            [connection setYLinkTrackID:[NSData dataWithBytes:yManMacAddress length:6]];
            
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDiscoveredDoor)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkConnected)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkReceivedWriteConf)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
            connection.hasReceivedWriteConfirmation = YES;
            connection.hasBadRSSIReading = YES;
            
            [connection.rssiValues addObject:@-112];
            [connection.rssiValues addObject:@-85];
            [connection.rssiValues addObject:@127];
            [connection.rssiValues addObject:@-20];
            [connection.rssiValues addObject:@127];
            [connection.rssiValues addObject:@-20];

            connection.roomNumber = @"Stairwell_2";
            connection.yLinkStartDate = [NSDate date];
            connection.yLinkEndDate = [NSDate dateWithTimeInterval:3211 sinceDate:connection.yLinkStartDate];
            
            [self.finishedBleTriangleConnections addObject:connection];
        }
        
        
        
        
        {
            // Creating BLE triangle connection row
            BLETriangleConnection* connection = [[BLETriangleConnection alloc] init];
            [connection setYManMacAddress:[NSData dataWithBytes:yManMacAddress length:6]];
            [connection setYLinkTrackID:[NSData dataWithBytes:yManMacAddress length:6]];
            
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkExpired)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
            connection.hasReceivedWriteConfirmation = NO;
            connection.hasBadRSSIReading = NO;
            
            [connection.rssiValues addObject:@-112];
//            [connection.rssiValues addObject:@-85];
//            [connection.rssiValues addObject:@-80];
//            [connection.rssiValues addObject:@-20];
            
            connection.roomNumber = @"Stairwell_2";
            connection.yLinkStartDate = [NSDate date];
            connection.yLinkEndDate = [NSDate dateWithTimeInterval:3211 sinceDate:connection.yLinkStartDate];
            
            [self.finishedBleTriangleConnections addObject:connection];
        }
        
        {
            // Creating BLE triangle connection row
            BLETriangleConnection* connection = [[BLETriangleConnection alloc] init];
            [connection setYManMacAddress:[NSData dataWithBytes:yManMacAddress length:6]];
            [connection setYLinkTrackID:[NSData dataWithBytes:yManMacAddress length:6]];
            
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkFailed)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkProcessedAndFinished)];
            connection.hasReceivedWriteConfirmation = NO;
            connection.hasBadRSSIReading = NO;
            
            connection.roomNumber = @"Stairwell_2";
            connection.yLinkStartDate = [NSDate date];
            connection.yLinkEndDate = [NSDate dateWithTimeInterval:3211 sinceDate:connection.yLinkStartDate];
            
            [self.finishedBleTriangleConnections addObject:connection];
        }
        
        
        
        
        
        {
            // Creating BLE triangle connection row
            BLETriangleConnection* connection = [[BLETriangleConnection alloc] init];
            [connection setYManMacAddress:[NSData dataWithBytes:yManMacAddress length:6]];
            [connection setYLinkTrackID:[NSData dataWithBytes:yManMacAddress length:6]];
            
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDiscoveredDoor)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkConnected)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkReceivedWriteConf)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDisconnected)];
            
            connection.roomNumber = @"Stairwell_2";
            connection.yLinkStartDate = [NSDate date];
            connection.yLinkEndDate = [NSDate dateWithTimeInterval:3211 sinceDate:connection.yLinkStartDate];
            
            [self.activeBleTriangleConnections addObject:connection];
            
        }
        
        {
            
            // Creating BLE triangle connection row
            BLETriangleConnection* connection = [[BLETriangleConnection alloc] init];
            [connection setYManMacAddress:[NSData dataWithBytes:yManMacAddress length:6]];
            [connection setYLinkTrackID:[NSData dataWithBytes:yManMacAddress length:6]];
            
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
            //            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDiscoveredDoor)];
            //            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkConnected)];
            //            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkReceivedWriteConf)];
            //            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDisconnected)];
            
            connection.roomNumber = @"Stairwell_2";
            connection.yLinkStartDate = [NSDate date];
            connection.yLinkEndDate = [NSDate dateWithTimeInterval:3211 sinceDate:connection.yLinkStartDate];
            
            [self.activeBleTriangleConnections addObject:connection];
            
        }
        
        {
            // Creating BLE triangle connection row
            BLETriangleConnection* connection = [[BLETriangleConnection alloc] init];
            [connection setYManMacAddress:[NSData dataWithBytes:yManMacAddress length:6]];
            [connection setYLinkTrackID:[NSData dataWithBytes:yManMacAddress length:6]];
            
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDiscoveredDoor)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkConnected)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkReceivedWriteConf)];
            //            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDisconnected)];
            
            connection.roomNumber = @"Stairwell_2";
            connection.yLinkStartDate = [NSDate date];
            connection.yLinkEndDate = [NSDate dateWithTimeInterval:3211 sinceDate:connection.yLinkStartDate];
            
            [self.activeBleTriangleConnections addObject:connection];
            
        }
        
        {
            // Creating BLE triangle connection row
            BLETriangleConnection* connection = [[BLETriangleConnection alloc] init];
            [connection setYManMacAddress:[NSData dataWithBytes:yManMacAddress length:6]];
            [connection setYLinkTrackID:[NSData dataWithBytes:yManMacAddress length:6]];
            
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkStartedScan)];
            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDiscoveredDoor)];
            //            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkConnected)];
            //            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkReceivedWriteConf)];
            //            [connection.yLinkKnownStates addObject:@(YKSBLEConnectionYLinkDisconnected)];
            
            connection.roomNumber = @"Stairwell_2";
            connection.yLinkStartDate = [NSDate date];
            connection.yLinkEndDate = [NSDate dateWithTimeInterval:3211 sinceDate:connection.yLinkStartDate];
            
            [self.activeBleTriangleConnections addObject:connection];
            
        }

        
        
        
        
        
        
        
    });
}

@end
