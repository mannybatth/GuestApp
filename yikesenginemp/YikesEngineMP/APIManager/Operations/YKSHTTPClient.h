//
//  YKSHTTPClient.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

/**
 *  Main yikes HTTPClient that handles api environments.
 */

@import AFNetworking;
@import YikesSharedModel;

@interface YKSHTTPClient : NSObject

@property (nonatomic) YKSApiEnv currentApiEnv;

+ (instancetype)sharedClient;

/**
 *  Returns the appropriate operation manager according to environment.
 */
+ (AFHTTPRequestOperationManager *)operationManager;

/**
 *  Returns the current environment from UserDefaults.
 */
+ (YKSApiEnv)getApiEnvFromUserDefaults;

+ (void)cancelAllRequests;

@end
