//
//  YKSDEVRequestOperationManager.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSDEVRequestOperationManager.h"
#import "YKSRequestSerializer.h"
#import "YKSResponseSerializer.h"
#import "YKSInternalConstants.h"

@import YikesSharedModel;

@implementation YKSDEVRequestOperationManager

+ (instancetype)sharedManager
{
    static YKSDEVRequestOperationManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[YKSDEVRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:yksDEVBaseURLString]];
        [_sharedManager setRequestSerializer:[YKSRequestSerializer serializer]];
        [_sharedManager setResponseSerializer:[YKSResponseSerializer serializer]];
    });
    
    return _sharedManager;
}

@end
