//
//  YKSSessionRequest.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

/**
 *  Request class that includes session related API calls.
 */

#import "YKSRequest.h"

@class YKSUser;

@interface YKSSessionRequest : YKSRequest

+ (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                  success:(void(^)(YKSUser *user, AFHTTPRequestOperation *operation))successBlock
                  failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)logoutWithSuccess:(void(^)(AFHTTPRequestOperation *operation))successBlock
                  failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)checkIfEmailIsRegistered:(NSString *)email
                         success:(void(^)(BOOL isAlreadyRegistered, YKSUser *user, AFHTTPRequestOperation *operation))successBlock
                         failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)registerUserWithForm:(NSDictionary *)form
                     success:(void(^)(AFHTTPRequestOperation *operation))successBlock
                     failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)forgotPasswordForEmail:(NSString *)email
                       success:(void(^)(AFHTTPRequestOperation *operation))successBlock
                       failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

@end
