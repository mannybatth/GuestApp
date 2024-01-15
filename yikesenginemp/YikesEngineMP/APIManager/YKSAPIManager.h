//
//  YKSAPIManager.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

/**
 *  Master APIManager class
 *  Includes all api call methods that will be used in either yikes GA, yikes HA, or third-party app.
 */

#import "YKSSession.h"
#import "YKSUser.h"
#import "YKSHotel.h"
#import "YKSStay.h"
#import "YKSPrimaryYMan.h"
#import "YKSWeather.h"
#import "YKSAddress.h"
#import "YKSStayShare.h"
#import "YKSInternalConstants.h"

@import YikesSharedModel;

@class AFHTTPRequestOperation;

@interface YKSAPIManager : NSObject

@property (nonatomic, assign) YKSLoggerLevel loggingLevelForAPIManager;

+ (instancetype)sharedManager;

- (void)appDidBecomeActiveNotification:(NSNotification *)notification;
- (void)appWillEnterForegroundNotification:(NSNotification *)notification;
- (void)appDidEnterBackgroundNotification:(NSNotification *)notification;

+ (void)setupAPIManagerWithLogLevel:(YKSLoggerLevel)level apiEnv:(YKSApiEnv)apiEnv appName:(YKSAppName)appName;
+ (void)setupAPIManagerWithLogLevel:(YKSLoggerLevel)level apiEnv:(YKSApiEnv)apiEnv;

+ (void)loginRetryingNumberOfTimes:(NSUInteger)ntimes
                          username:(NSString *)username
                          password:(NSString *)password
                           success:(void (^)(YKSUser *user))successBlock
                           failure:(void (^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)loginWithKeychainCredentialsWithSuccess:(void (^)(YKSUser *user))successBlock
                                        failure:(void (^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)logoutWithSuccess:(void(^)())successBlock
                  failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)getCurrentUserAndStaysRetryingNumberOfTimes:(NSUInteger)ntimes
                                            success:(void (^)(YKSUser *user))successBlock
                                            failure:(void (^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)getHotelWithId:(NSNumber *)hotelId
               success:(void(^)(YKSHotel *hotel))successBlock
               failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)checkIfEmailIsRegistered:(NSString *)email
                         success:(void(^)(BOOL isAlreadyRegistered, NSNumber *userId))successBlock
                         failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)registerUserWithForm:(NSDictionary *)form
                     success:(void(^)())successBlock
                     failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)forgotPasswordForEmail:(NSString *)email
                       success:(void(^)())successBlock
                       failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)getCurrentUserStaySharesWithSuccess:(void(^)(NSArray *stayShares))successBlock
                                    failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)createStayShareForStayId:(NSNumber *)stayId
                           email:(NSString *)email
                         success:(void(^)(YKSStayShare *stayShare, NSNumber *inviteId))successBlock
                         failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)updateStatusForStayShareWithId:(NSNumber *)stayShareId
                                stayId:(NSNumber *)stayId
                                status:(NSString *)status
                               success:(void(^)())successBlock
                               failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)getCurrentUserInvitesWithSuccess:(void(^)(NSArray *userInvites))successBlock
                                 failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)deleteUserInviteWithId:(NSNumber *)inviteId
                       success:(void(^)())successBlock
                       failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)getRecentContactsWithSuccess:(void(^)(NSArray *contacts))successBlock
                             failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)deleteContactWithId:(NSNumber *)contactId
                    success:(void(^)())successBlock
                    failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)updateUserWithForm:(NSDictionary *)form
                   success:(void(^)())successBlock
                   failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)updatePasswordForUserId:(NSNumber *)userId
                    oldPassword:(NSString *)oldPwd
                    newPassword:(NSString *)newPwd
                        success:(void (^)())successBlock
                        failure:(void (^)(AFHTTPRequestOperation *))failureBlock;

@end
