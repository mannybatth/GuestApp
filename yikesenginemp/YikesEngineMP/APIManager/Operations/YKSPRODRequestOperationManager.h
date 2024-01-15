//
//  YKSPRODRequestOperationManager.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

/**
 *  Operation Manager used in PROD environment.
 */

@import AFNetworking;

@interface YKSPRODRequestOperationManager : AFHTTPRequestOperationManager

+ (instancetype)sharedManager;

@end
