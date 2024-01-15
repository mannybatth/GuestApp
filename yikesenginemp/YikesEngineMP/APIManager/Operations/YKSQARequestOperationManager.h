//
//  YKSQARequestOperationManager.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

/**
 *  Operation Manager used in QA environment.
 */

@import AFNetworking;

@interface YKSQARequestOperationManager : AFHTTPRequestOperationManager

+ (instancetype)sharedManager;

@end
