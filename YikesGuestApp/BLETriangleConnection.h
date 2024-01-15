//
//  BLETriangleConnection.h
//  yikes
//
//  Created by royksopp on 2015-02-04.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, YKSBLEConnectionYLinkStatus) {
    YKSBLEConnectionYLinkUnknown,
    YKSBLEConnectionYLinkStartedScan,
    YKSBLEConnectionYLinkDiscoveredDoor,
    YKSBLEConnectionYLinkConnected,
    YKSBLEConnectionYLinkDisconnected,
    YKSBLEConnectionYLinkExpired,
    YKSBLEConnectionYLinkFailed,
    YKSBLEConnectionYLinkReceivedWriteConf,
    YKSBLEConnectionYLinkProcessedAndFinished
};
#define valueForState(enum) [@[@"YKSBLEConnectionYLinkUnknown",@"YKSBLEConnectionYLinkStartedScan",@"YKSBLEConnectionYLinkDiscoveredDoor",@"YKSBLEConnectionYLinkConnected",@"YKSBLEConnectionYLinkDisconnected",@"YKSBLEConnectionYLinkExpired",@"YKSBLEConnectionYLinkFailed",@"YKSBLEConnectionYLinkReceivedWriteConf",@"YKSBLEConnectionYLinkProcessedAndFinished"] objectAtIndex:enum]



@interface BLETriangleConnection : NSObject

@property (nonatomic, strong) NSData* yManMacAddress;
@property (nonatomic, strong) NSData* yLinkTrackID;
@property (atomic, assign) NSTimeInterval totalTime;
@property (nonatomic, strong) NSString *roomNumber;
@property (nonatomic, strong) NSNumber *RSSI;
@property (nonatomic, strong) NSMutableArray *yLinkKnownStates;
@property (nonatomic, strong) NSMutableArray *yManKnownStates;
@property (nonatomic, strong) NSDate *yManStartTimeInBLEConnection;

@end
