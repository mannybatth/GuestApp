//
//  YikesEngineMP.h
//  YikesEngineMP
//
//  Created by Manny Singh on 4/8/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for YikesEngineMP.
FOUNDATION_EXPORT double YikesEngineMPVersionNumber;

//! Project version string for YikesEngineMP.
FOUNDATION_EXPORT const unsigned char YikesEngineMPVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <YikesEngineMP/PublicHeader.h>
#import "YikesSharedModel/YikesSharedModel.h"

@interface YikesEngineMP : NSObject<GenericEngineProtocol>

@property (nonatomic, assign) BOOL requiresEULA;

/**
 *  The level of logging detail for APIManager.
 *
 *  YKSLoggerLevelOff
 *      - Do not log anything from APIManager
 *
 *  YKSLoggerLevelError
 *      - Logs HTTP method & URL for requests, and status code, URL, & elapsed time for responses, but only for failed requests.
 *
 *  YKSLoggerLevelInfo  (default)
 *      - Logs HTTP method & URL for requests, and status code, URL, & elapsed time for all responses.
 *
 *  YKSLoggerLevelDebug
 *      - Logs HTTP method, URL, header fields, & request body for requests, and status code, URL, header fields, response string, & elapsed time for all responses.
 *
 */
@property (nonatomic, assign) YKSLoggerLevel loggingLevelForAPI;

/**
 *  The level of logging detail for BLEManager.
 *
 *  YKSLoggerLevelOff
 *      - Do not log anything from BLEManager
 *
 *  YKSLoggerLevelError
 *      - TODO: YKSLoggerLevelError
 *
 *  YKSLoggerLevelInfo  (default)
 *      - TODO: YKSLoggerLevelInfo
 *
 *  YKSLoggerLevelDebug
 *      - TODO: YKSLoggerLevelDebug
 *
 */
@property (nonatomic, assign) YKSLoggerLevel loggingLevelForBLE;

/**
 *  Current state of the Engine
 *  
 *  YKSEngineStateOff
 *      - Engine is shutdown and not scanning for doors
 *
 *  YKSEngineStateOn
 *      - Engine is running and actively scanning for doors
 *
 *  YKSEngineStateStandby
 *      - Engine is running, but not scanning for doors
 *
 */
@property (nonatomic, assign, readonly) YKSEngineState engineState;

@property (nonatomic, assign, readonly) YKSBLEEngineState bleEngineState;

@property (nonatomic, weak) id<YikesEngineDelegate> delegate;

@property (nonatomic, assign, readonly) YKSApiEnv currentApiEnv;

/**
 *  Current logged in user w/ stays
 */
@property (nonatomic, strong, readonly) YKSUserInfo *userInfo;

@property (nonatomic, readonly) BOOL isInsideHotel;
@property (nonatomic, assign, readonly) YKSLocationState currentLocationState;

@property (readwrite, copy) void (^changeEngineBeaconMode)(YKSBeaconMode);
@property (readwrite, copy) YKSBeaconMode (^engineBeaconMode)(void);
@property (readwrite, copy) BOOL (^shouldStartBLEActivity)(YKSEngineArchitecture);


+ (instancetype)sharedEngine;

+ (void)initEngineWithDelegate:(id<YikesEngineDelegate>)yikesEngineDelegate;

- (void)startEngineWithUsername:(NSString *)username
                       password:(NSString *)password
                        success:(void(^)(YKSUserInfo *user))successBlock
                        failure:(void(^)(YKSError *error))failureBlock;

- (void)stopEngineWithSuccess:(void(^)())successBlock;

- (void)checkIfLowPowerModeIsEnabled;

- (NSString *)currentGuestUsername;
- (NSString *)currentPassword;

- (NSURL *)bundleURL;

- (BOOL)changeCurrentApiEnv:(YKSApiEnv)currentApiEnv;

- (void)logMessage:(NSString *)message level:(YKSLoggerLevel)level;

/**
 *  Should be called when host app need to get most up-to-date user/stay info from yikes servers
 *  Result: see yikesEngineUserInfoUpdated delegate call
 */
- (void)refreshUserInfoWithFailure:(void(^)(YKSError *error))failureBlock;

- (void)refreshUserInfoWithSuccess:(void (^)(YKSUserInfo *user))successBlock
                           failure:(void (^)(YKSError *error))failureBlock;

/**
 *  Stay Shares & User Invites
 */
- (void)getUserStayShareRequestsWithSuccess:(void (^)(NSArray *stayShares))successBlock
                                    failure:(void (^)(YKSError *error))failureBlock;

- (void)sendStayShareRequestForStayId:(NSNumber *)stayId
                              toEmail:(NSString *)email
                              success:(void (^)(YKSStayShareInfo *stayShare, YKSUserInviteInfo *userInvite))successBlock
                              failure:(void (^)(YKSError *error))failureBlock;

- (void)acceptStayShareRequest:(YKSStayShareInfo *)stayShare
                       success:(void (^)())successBlock
                       failure:(void (^)(YKSError *error))failureBlock;

- (void)declineStayShareRequest:(YKSStayShareInfo *)stayShare
                        success:(void (^)())successBlock
                        failure:(void (^)(YKSError *error))failureBlock;

- (void)cancelStayShareRequest:(YKSStayShareInfo *)stayShare
                       success:(void (^)())successBlock
                       failure:(void (^)(YKSError *error))failureBlock;

- (void)getUserInvitesWithSuccess:(void (^)(NSArray *userInvites))successBlock
                          failure:(void (^)(YKSError *error))failureBlock;

- (void)cancelUserInviteRequest:(YKSUserInviteInfo *)userInvite
                        success:(void (^)())successBlock
                        failure:(void (^)(YKSError *error))failureBlock;

/**
 *  Recent contacts
 */
- (void)getRecentContactsWithSuccess:(void (^)(NSArray *contacts))successBlock
                             failure:(void (^)(YKSError *error))failureBlock;

- (void)removeRecentContact:(YKSContactInfo *)contact
                    success:(void (^)())successBlock
                    failure:(void (^)(YKSError *error))failureBlock;

/**
 *  Must be called by the host app when a PN message is recieved from yikes servers
 */
- (void)handlePushNotificationMessage:(NSString *)message;

- (void)checkIfEmailIsRegistered:(NSString *)email
                         success:(void (^)(BOOL isAlreadyRegistered))successBlock
                         failure:(void (^)(YKSError *error))failureBlock;

- (void)registerUserWithForm:(NSDictionary<NSString *, id> *)form
                     success:(void(^)())successBlock
                     failure:(void(^)(YKSError *error))failureBlock;

- (void)updatePasswordForUserId:(NSNumber *)userId
                    oldPassword:(NSString *)oldPassword
                    newPassword:(NSString *)newPassword
                confNewPassword:(NSString *)confNewPassword
                        success:(void (^)())successBlock
                        failure:(void (^)(YKSError *))failureBlock;

- (void)forgotPasswordForEmail:(NSString *)email
                       success:(void(^)())successBlock
                       failure:(void(^)(YKSError *error))failureBlock;

- (void)updateUserWithForm:(NSDictionary<NSString *,id> *)form
                   success:(void (^)())successBlock
                   failure:(void (^)(YKSError *error))failureBlock;

- (void)requestBeaconState;

- (void)missingServices:(void (^)(NSSet *missingServices))completion;

#pragma mark Debugging options

- (NSDictionary *)debugInformation;
- (void)setDebugMode:(BOOL)on;
- (void)showDebugViewInView:(UIView *)view;
- (void)handleDebugToolsLogin;
- (void)handleDebugToolsLogout;

@end
