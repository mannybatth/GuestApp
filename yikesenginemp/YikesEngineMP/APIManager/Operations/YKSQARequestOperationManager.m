//
//  YKSQARequestOperationManager.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSQARequestOperationManager.h"
#import "YKSRequestSerializer.h"
#import "YKSResponseSerializer.h"
#import "YKSInternalConstants.h"

@import YikesSharedModel;

@implementation YKSQARequestOperationManager

+ (instancetype)sharedManager
{
    static YKSQARequestOperationManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[YKSQARequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:yksQABaseURLString]];
        [_sharedManager setRequestSerializer:[YKSRequestSerializer serializer]];
        [_sharedManager setResponseSerializer:[YKSResponseSerializer serializer]];
    });
    
    return _sharedManager;
}

@end
