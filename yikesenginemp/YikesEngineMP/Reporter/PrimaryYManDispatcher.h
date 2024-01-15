//
//  PrimayYManReporter.h
//  Pods
//
//  Created by Alexandar Dimitrov on 2014-12-12.
//
//

#import <Foundation/Foundation.h>

@interface PrimaryYManDispatcher : NSObject

@property (nonatomic, strong) NSMutableArray* activeGAuths;
@property (nonatomic, strong) NSData* mac_address;

- (void)startedScanForPYMan:(NSData *)mac_address;
- (void)discoveredPYMan:(NSData *)mac_address;  //Start of BLE cycle, start timer
- (void)receivedStopMsgPYMan:(NSData *)mac_address; // stop time of pYMan interaction
- (void)disconnectedPYMan:(NSData *)mac_address;
- (void)didEnterYManRegion:(NSData *)mac_address;

@end
