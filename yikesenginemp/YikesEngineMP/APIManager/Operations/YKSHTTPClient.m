//
//  YKSHTTPClient.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSHTTPClient.h"
#import "YKSPRODRequestOperationManager.h"
#import "YKSQARequestOperationManager.h"
#import "YKSDEVRequestOperationManager.h"
#import "YKSInternalConstants.h"

@implementation YKSHTTPClient

+ (instancetype)sharedClient
{
    static YKSHTTPClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[YKSHTTPClient alloc] init];
        _sharedClient.currentApiEnv = [YKSHTTPClient getApiEnvFromUserDefaults];
    });
    
    return _sharedClient;
}

+ (AFHTTPRequestOperationManager *)operationManager
{
    YKSApiEnv currentApi = [YKSHTTPClient sharedClient].currentApiEnv;
    
    AFHTTPRequestOperationManager *manager;
    switch (currentApi) {
        case kYKSEnvPROD:
            manager = [YKSPRODRequestOperationManager sharedManager];
            break;
            
        case kYKSEnvQA:
            manager = [YKSQARequestOperationManager sharedManager];
            break;
            
        case kYKSEnvDEV:
            manager = [YKSDEVRequestOperationManager sharedManager];
            break;
            
        default:
            manager = [YKSPRODRequestOperationManager sharedManager];
            break;
    }
    return manager;
}

+ (YKSApiEnv)getApiEnvFromUserDefaults
{
    NSUInteger savedApiEnv = [[NSUserDefaults standardUserDefaults] integerForKey:yksCurrentApiEnvKey];
    return savedApiEnv;
}

- (void)setCurrentApiEnv:(YKSApiEnv)currentApiEnv
{
    _currentApiEnv = currentApiEnv;
    [[NSUserDefaults standardUserDefaults] setInteger:currentApiEnv forKey:yksCurrentApiEnvKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)cancelAllRequests
{
    [[[YKSPRODRequestOperationManager sharedManager] operationQueue] cancelAllOperations];
    [[[YKSQARequestOperationManager sharedManager] operationQueue] cancelAllOperations];
    [[[YKSDEVRequestOperationManager sharedManager] operationQueue] cancelAllOperations];
}

@end
