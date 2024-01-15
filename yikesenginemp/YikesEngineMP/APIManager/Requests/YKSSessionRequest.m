//
//  YKSSessionRequest.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSSessionRequest.h"
#import "YKSUser.h"


@implementation YKSSessionRequest

+ (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                  success:(void (^)(YKSUser *, AFHTTPRequestOperation *))successBlock
                  failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURLForLogin];
    NSDictionary *params = @{
                             @"user_name":username,
                             @"password":password,
                             @"_expand": @"user"
                             };
    
    [[YKSHTTPClient operationManager] POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *userJSON = responseObject[@"response_body"][@"user"];
        
        NSError *error = nil;
        YKSUser *user = [YKSUser newUserFromJSON:userJSON error:&error];
        
        if (!error) {
            successBlock(user, operation);
        } else {
            failureBlock(operation, error);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation, error);
        
    }];
    
}

+ (void)logoutWithSuccess:(void (^)(AFHTTPRequestOperation *))successBlock
                  failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURLForLogout];
    [[YKSHTTPClient operationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        successBlock(operation);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation, error);
    }];
}

+ (void)checkIfEmailIsRegistered:(NSString *)email
                         success:(void (^)(BOOL, YKSUser *, AFHTTPRequestOperation *))successBlock
                         failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURLForVerifyWithEmail:email];
    [[YKSHTTPClient operationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (operation.response.statusCode == 200) {
            
            if ([responseObject[@"response_body"] isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *userJSON = responseObject[@"response_body"][@"user"];
            
                NSError *error = nil;
                YKSUser *user = [YKSUser newUserFromJSON:userJSON error:&error];
            
                /* Email already registered */
                successBlock(YES, user, operation);
                
            } else {
                
                /* Email already registered */
                successBlock(YES, nil, operation);
            }
            
        } else {
            
            /* Email not registered yet */
            successBlock(NO, nil, operation);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (operation.response.statusCode == 404) {
            
            /* Email not registered yet */
            successBlock(NO, nil, operation);
        } else {
            failureBlock(operation, error);
        }
    }];
}

+ (void)registerUserWithForm:(NSDictionary *)form
                     success:(void (^)(AFHTTPRequestOperation *))successBlock
                     failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURLForUsers];
    [[YKSHTTPClient operationManager] POST:url parameters:form success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        DLog(@"responseObject for new Sign Up is:\n%@", responseObject);
        successBlock(operation);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation, error);
    }];
}

+ (void)forgotPasswordForEmail:(NSString *)email
                       success:(void (^)(AFHTTPRequestOperation *))successBlock
                       failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURlForPasswordResetWithEmail:email];
    [[YKSHTTPClient operationManager] POST:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        successBlock(operation);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation, error);
    }];
}

@end
