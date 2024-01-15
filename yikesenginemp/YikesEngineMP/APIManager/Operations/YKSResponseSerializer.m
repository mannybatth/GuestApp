//
//  YKSResponseSerializer.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSResponseSerializer.h"

@implementation YKSResponseSerializer

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"application/json", @"text/plain", @"text/json", nil];
    
    return self;
}

@end
