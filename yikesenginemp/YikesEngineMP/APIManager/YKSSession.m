//
//  YKSSession.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSSession.h"
#import "YKSUser.h"

@interface YKSSession()

@end

@implementation YKSSession

- (instancetype)initWithUser:(YKSUser *)user
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [self setCurrentUser:user];
    
    return self;
}

@end
