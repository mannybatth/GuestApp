//
//  YKSRequestSerializer.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSRequestSerializer.h"
#import "YKSDeviceHelper.h"

@import YikesSharedModel;

@implementation YKSRequestSerializer

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [self setValue:[YKSDeviceHelper sharedHelper].clientVersionInfo forHTTPHeaderField:@"Yikes-Client-Version"];
    
    return self;
}

@end
