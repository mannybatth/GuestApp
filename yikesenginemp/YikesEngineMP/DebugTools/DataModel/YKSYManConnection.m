//
//  YKSYManConnection.m
//  yikes
//
//  Created by royksopp on 2015-05-11.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import "YKSYManConnection.h"

@implementation YKSYManConnection

- (id) init {
    
    self = [super init];
    if (self) {
        self.macAddress = nil;
        self.connected = NO;
    }
    
    return self;
}


- (id)initWithMacAddress:(NSData *)macAddress andConnected:(BOOL)connected {
    self = [super init];
    if (self) {
        self.macAddress = macAddress;
        self.connected = connected;
    }
    
    return self;
}

@end
