//
//  YKSYManConnection.h
//  yikes
//
//  Created by royksopp on 2015-05-11.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YKSYManConnection : NSObject

@property (nonatomic, strong) NSData *macAddress;
@property (atomic, assign, getter=isConnected) BOOL connected;

- (id)initWithMacAddress:(NSData *)macAddress andConnected:(BOOL)connected;

@end
