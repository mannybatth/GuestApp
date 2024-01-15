//
//  YKSUserRequest.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

/**
 *  Request class that includes API calls involving a user.
 */

#import "YKSRequest.h"

@class YKSUser, YKSStayShare;

@interface YKSUserRequest : YKSRequest

+ (void)getUserAndStaysWithUserId:(NSNumber *)userId
                          success:(void(^)(YKSUser *user, AFHTTPRequestOperation *operation))successBlock
                          failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)getStaySharesForUserId:(NSNumber *)userId
                       success:(void(^)(NSArray *stayShares, AFHTTPRequestOperation *operation))successBlock
                       failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)createStayShareForStayId:(NSNumber *)stayId
                          userId:(NSNumber *)userId
                         success:(void(^)(YKSStayShare *stayShare, AFHTTPRequestOperation *operation))successBlock
                         failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)updateStatusForStayShareWithId:(NSNumber *)stayShareId
                                stayId:(NSNumber *)stayId
                                status:(NSString *)status
                               success:(void(^)(AFHTTPRequestOperation *operation))successBlock
                               failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)getUserInvitesForUserId:(NSNumber *)userId
                        success:(void(^)(NSArray *userInvites, AFHTTPRequestOperation *operation))successBlock
                        failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)createUserInviteForStayId:(NSNumber *)stayId
                         byUserId:(NSNumber *)userId
                     withUserForm:(NSDictionary *)form
                          success:(void(^)(NSNumber *inviteId, AFHTTPRequestOperation *operation))successBlock
                          failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)deleteUserInviteWithId:(NSNumber *)inviteId
                        userId:(NSNumber *)userId
                       success:(void(^)(AFHTTPRequestOperation *operation))successBlock
                       failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)getContactsForUserId:(NSNumber *)userId
                     success:(void(^)(NSArray *contacts, AFHTTPRequestOperation *operation))successBlock
                     failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)deleteContactWithId:(NSNumber *)contactId
                     userId:(NSNumber *)userId
                    success:(void(^)(AFHTTPRequestOperation *operation))successBlock
                    failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;

+ (void)updateUserWithForm:(NSDictionary *)form
                    userId:(NSNumber *)userId
                   success:(void(^)(AFHTTPRequestOperation *operation))successBlock
                   failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;


+ (void)updatePasswordForUserId:(NSNumber *)userId
                    oldPassword:(NSString *)oldPwd
                    newPassword:(NSString *)newPwd
                        success:(void (^)(AFHTTPRequestOperation *))successBlock
                        failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock;

@end
