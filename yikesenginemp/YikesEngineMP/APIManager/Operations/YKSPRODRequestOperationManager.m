//
//  YKSPRODRequestOperationManager.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSPRODRequestOperationManager.h"
#import "YKSRequestSerializer.h"
#import "YKSResponseSerializer.h"
#import "YKSInternalConstants.h"

@import YikesSharedModel;

@implementation YKSPRODRequestOperationManager

+ (instancetype)sharedManager
{
    static YKSPRODRequestOperationManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[YKSPRODRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:yksPRODBaseURLString]];
        [_sharedManager setRequestSerializer:[YKSRequestSerializer serializer]];
        [_sharedManager setResponseSerializer:[YKSResponseSerializer serializer]];
    });
    
    return _sharedManager;
}

@end
