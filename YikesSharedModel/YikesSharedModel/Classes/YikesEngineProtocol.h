//
//  YikesEngineProtocol.h
//  YikesEngineMP
//
//  Created by Manny Singh on 11/20/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSStayInfo.h"
#import "YKSAddressInfo.h"
#import "YKSAmenityInfo.h"
#import "YKSStayShareInfo.h"
#import "YKSUserInviteInfo.h"
#import "YKSContactInfo.h"
#import "YKSError.h"
#import "YKSConstants.h"

@protocol YikesEngineDelegate;

@protocol GenericEngineProtocol

@optional
@property (readwrite, copy) void (^changeEngineBeaconMode)(YKSBeaconMode arch);
@property (readwrite, copy) YKSBeaconMode (^engineBeaconMode)(void);
@property (readwrite, copy) BOOL (^shouldStartBLEActivity)(YKSEngineArchitecture);

- (void)requestBeaconState;
- (void)logMessage:(NSString *)message;
- (void)logMessage:(NSString *)message level:(YKSLoggerLevel)level;

@required

@property (nonatomic, readonly) YKSApiEnv currentApiEnv;
@property (nonatomic, assign, readonly) YKSEngineState engineState;
@property (nonatomic, assign, readonly) YKSBLEEngineState bleEngineState;
@property (nonatomic, strong, readonly) YKSUserInfo *userInfo;

@property (nonatomic, readonly) BOOL isInsideHotel;
@property (nonatomic, assign, readonly) YKSLocationState currentLocationState;
@property (nonatomic, weak) id<YikesEngineDelegate> delegate;

- (NSString *)currentApiEnvString;

//API: Env
- (BOOL)changeCurrentApiEnv:(YKSApiEnv)currentApiEnv;

//MARK: Engine
+ (void)initEngineWithDelegate:(id<YikesEngineDelegate>)yikesEngineDelegate;
+ (id<GenericEngineProtocol>)sharedEngine;

- (void)startEngineWithUsername:(NSString *)username
                       password:(NSString *)password
                        success:(void(^)(YKSUserInfo *user))successBlock
                        failure:(void(^)(YKSError *error))failureBlock;

- (void)startEngineWithUsername:(NSString *)username
                       password:(NSString *)password
                   requiresEULA:(BOOL)requiresEULA
                        success:(void(^)(YKSUserInfo *user))successBlock
                        failure:(void(^)(YKSError *error))failureBlock;

- (void)checkIfLowPowerModeIsEnabled;

- (void)userAcceptedEULA:(NSString *)username;

- (void)stopEngineWithSuccess:(void(^)())successBlock;

- (void)requestLocationAlwaysAuthorization;

//TODO: [EXTERNAL] Remove these two methods when shipping with only one architecture
- (void)pauseEngine;
- (void)resumeEngine;

// MARK: Credentials
- (bool)userIsSignedIn;
- (NSString *)currentGuestUsername;
- (NSString *)currentPassword;

//MARK: API
- (void)refreshUserInfoWithFailure:(void(^)(YKSError *error))failureBlock;

- (void)refreshUserInfoWithSuccess:(void (^)(YKSUserInfo *user))successBlock
                           failure:(void (^)(YKSError *error))failureBlock;
- (void)getUserStayShareRequestsWithSuccess:(void (^)(NSArray<YKSStayShareInfo *> *stayShares))successBlock
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
- (void)getUserInvitesWithSuccess:(void (^)(NSArray<YKSUserInviteInfo *> *userInvites))successBlock
                          failure:(void (^)(YKSError *error))failureBlock;
- (void)cancelUserInviteRequest:(YKSUserInviteInfo *)userInvite
                        success:(void (^)())successBlock
                        failure:(void (^)(YKSError *error))failureBlock;
- (void)getRecentContactsWithSuccess:(void (^)(NSArray<YKSContactInfo *> *contacts))successBlock
                             failure:(void (^)(YKSError *error))failureBlock;
- (void)removeRecentContact:(YKSContactInfo *)contact
                    success:(void (^)())successBlock
                    failure:(void (^)(YKSError *error))failureBlock;
- (void)handlePushNotificationMessage:(NSString *)message completionHandler:(void(^)())completionHandler;
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
                        success:(void(^)())successBlock
                        failure:(void(^)(YKSError *error))failureBlock;

- (void)forgotPasswordForEmail:(NSString *)email
                       success:(void(^)())successBlock
                       failure:(void(^)(YKSError *error))failureBlock;

- (void)updateUserWithForm:(NSDictionary<NSString *,id> *)form
                   success:(void (^)())successBlock
                   failure:(void (^)(YKSError *error))failureBlock;

- (void)missingServices:(void (^)(NSSet *missingServices))completion;

- (void)setBackgroundCompletionHandler:(void(^)())completionHandler;


// Debuging
- (NSDictionary *)debugInformation;
- (void)setDebugMode:(BOOL)on;
- (void)showDebugViewInView:(UIView *)view;
- (void)handleDebugToolsLogin;
- (void)handleDebugToolsLogout;

@end



@protocol YikesEngineDelegate <NSObject>

@optional

- (void)yikesEngineStateDidChange:(YKSEngineState)state;
- (void)yikesEngineLocationStateDidChange:(YKSLocationState)state;
- (void)yikesEngineDeviceMotionStateDidChange:(YKSDeviceMotionState)state;
- (void)yikesEngineRoomConnectionStatusDidChange:(YKSConnectionStatus)newStatus withRoom:(NSString *)room;
- (void)yikesEngineRoomConnectionStatusDidChange:(YKSConnectionStatus)newStatus withRoom:(NSString *)room disconnectReasonCode:(YKSDisconnectReasonCode)code;

/**
 *  Called when Engine recognizes that certain devices requirments are missing
 *  Ex: Bluetooth is turned off
 */
- (void)yikesEngineRequiredServicesMissing:(NSSet *)missingServices;

/**
 *  Called when a critical error occurs in the Engine, resulting the Engine to turn off or be in standby
 */
- (void)yikesEngineErrorDidOccur:(YKSError *)yikesError;

/**
 *  Called when the Engine has fetched up-to-date user/stay info from yikes servers
 *  For instance, after refreshUserInfo is invoked and completed
 */
- (void)yikesEngineUserInfoDidUpdate:(YKSUserInfo *)yikesUser;

@end

