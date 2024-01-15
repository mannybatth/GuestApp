//
//  BLETriangleConnection.m
//  yikes
//
//  Created by royksopp on 2015-02-04.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import "BLETriangleConnection.h"

@implementation BLETriangleConnection

@synthesize yManMacAddress,
yLinkTrackID,
roomNumber,
lastScannedRSSIValue,
yLinkKnownStates,
yLinkStartDate,
yLinkEndDate,
yLinkTimeInterval;


- (id) init {
    
    self = [super init];
    if (self) {
        self.yLinkKnownStates = [NSMutableArray array];
        self.rssiValues = [NSMutableArray array];
    }
    
    return self;
}


- (id)copyWithZone:(NSZone *)zone {
    
    id copy = [[[self class] alloc] init];
    
    if (copy) {
        
        [copy setYManMacAddress:[self.yManMacAddress copyWithZone:zone]];
        [copy setYLinkTrackID:[self.yLinkTrackID copyWithZone:zone]];
        [copy setRoomNumber:[self.roomNumber copyWithZone:zone]];
        [copy setLastScannedRSSIValue:[self.lastScannedRSSIValue copyWithZone:zone]];
        
        [copy setYLinkKnownStates:[[NSMutableArray alloc] initWithArray:self.yLinkKnownStates copyItems:YES]];
        [copy setRssiValues:[[NSMutableArray alloc] initWithArray:self.rssiValues copyItems:YES]];
        
        [copy setRssiThreshold:[self.rssiThreshold copyWithZone:zone]];
        [copy setTimeout:self.timeout];
        [copy setHasBadRSSIReading:self.hasBadRSSIReading];
        [copy setHasReceivedWriteConfirmation:self.hasReceivedWriteConfirmation];
        [copy setYLinkTimeInterval:self.yLinkTimeInterval];
        
        [copy setYLinkStartDate:[self.yLinkStartDate copyWithZone:zone]];
        [copy setYLinkEndDate:[self.yLinkEndDate copyWithZone:zone]];
    }
    
    return copy;
}


@end
