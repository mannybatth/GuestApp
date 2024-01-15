//
//  PrimayYManReporter.m
//  Pods
//
//  Created by Alexandar Dimitrov on 2014-12-12.
//
//

#import "PrimaryYManDispatcher.h"

@interface PrimaryYManDispatcher()

@property (nonatomic, strong) NSDate* startTime;
@property (nonatomic, assign) NSTimeInterval totalElapsedTime;

@end

@implementation PrimaryYManDispatcher

- (id) init {
    
    self = [super init];
//    if (self) {
//        [self restartStats];
//    }
    
    return self;
}

- (void)startedScanForPYMan:(NSData *)mac_address {
    // start timer
    
}


- (void)discoveredPYMan:(NSData *)mac_address {
    // stop timer
}


- (void)receivedStopMsgPYMan:(NSData *)mac_address {
    
    // stop timer
}


- (void)disconnectedPYMan:(NSData *)mac_address {
    // stop timer
    
}


- (void)didEnterYManRegion:(NSData *)mac_address {
    
}


@end
