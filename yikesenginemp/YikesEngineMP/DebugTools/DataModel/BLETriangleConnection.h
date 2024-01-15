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

@interface BLETriangleConnection : NSObject <NSCopying>

@property (nonatomic, strong) NSData* yManMacAddress;
@property (nonatomic, strong) NSData* yLinkTrackID;
@property (nonatomic, strong) NSString *roomNumber;
@property (nonatomic, strong) NSNumber *lastScannedRSSIValue;
@property (nonatomic, strong) NSMutableArray *yLinkKnownStates;
@property (nonatomic, strong) NSMutableArray *rssiValues;
@property (nonatomic, strong) NSNumber *rssiThreshold;
@property (atomic, assign) NSTimeInterval timeout;

@property (atomic, assign) BOOL hasBadRSSIReading;
@property (atomic, assign) BOOL hasReceivedWriteConfirmation;

@property (nonatomic, strong) NSDate* yLinkStartDate;
@property (nonatomic, strong) NSDate* yLinkEndDate;

@property (atomic, assign) NSTimeInterval yLinkTimeInterval;

@end
