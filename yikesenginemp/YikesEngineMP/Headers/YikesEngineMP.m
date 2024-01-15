//
//  YikesEngineMP.m
//  YikesEngineMP
//
//  Created by Roger on 3/19/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YikesEngineMP.h"
#import "YKSAPIManager.h"
#import "YKSSessionManager.h"
#import "YBLEManager.h"
#import "YKSServicesManager.h"
#import "YKSDebugManager.h"
#import "YKSFileLogger.h"
#import "YKSRequiredHardwareNotificationCenter.h"
#import "YMotionManager.h"
#import "YKSLocationManager.h"
#import "YKSLogger.h"
#import "YKSHTTPClient.h"
#import "YKSError+Util.h"
#import "YKSErrorReporter.h"
#import "YKSErrorDetector.h"
#import "YKSLevelLogger.h"

@import YikesSharedModel;

@interface YikesEngineMP() <GenericEngineProtocol, YKSServicesManagerDelegate, YMotionManagerDelegate, YKSLocationManagerDelegate, YKSBLEManagerGuestEventDelegate, YKSErrorReporterDelegate>

@property (nonatomic, assign) YKSEngineState engineState;
@property (nonatomic, assign) YKSBLEEngineState bleEngineState;

@end

@implementation YikesEngineMP


+ (instancetype)sharedEngine
{
    static YikesEngineMP *_sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedEngine = [[YikesEngineMP alloc] init];
    });
    
    return _sharedEngine;
}


- (void)resumeEngine {
    
    YKSUser *user = [YKSSessionManager getCurrentUser];
    if (self.requiresEULA && user && !user.eulaAccepted) {
        [[YKSLogger sharedLogger] logMessage:@"EULA required and user has not yet accepted - canceling Engine Resume." withErrorLevel:YKSErrorLevelWarning andType:YKSLogMessageTypeEngine];
        return;
    }
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Resuming MP Engine"]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    
    if (self.engineState == kYKSEngineStateOff) {
        self.engineState = kYKSEngineStatePaused;
    }
    
    if (self.isInsideHotel) {
        self.engineState = kYKSEngineStateOn;
        
        if ([YKSSessionManager getCurrentUser]) {
            [[YKSLocationManager sharedManager] startMonitoringRegion];
            [[YBLEManager sharedManager] beginScanningForYikesHardware];
        }
    }
}

- (void)userAcceptedEULA:(NSString *)username {
    YKSUser *user = [YKSSessionManager getCurrentUser];
    if (user && [user.email isEqualToString:username]) {
        user.eulaAccepted = YES;
        [self resumeEngine];
    }
}


- (void)pauseEngine {
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Pausing MP Engine"]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    
    self.engineState = kYKSEngineStatePaused;
    [[YBLEManager sharedManager] stopBLEActivity];
}


- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    /* Default log level */
    [self setLoggingLevelForAPI:kYKSLoggerLevelInfo];
    [self setLoggingLevelForBLE:kYKSLoggerLevelInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForegroundNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackgroundNotification:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    // Try to get session from cache
    if ([YKSSessionManager getCurrentUser]) {
        
        self.engineState = kYKSEngineStateOn;
        
        [YBLEManager sharedManager].guestEventDelegate = self;
        [YKSServicesManager sharedManager].delegate = self;
        [YMotionManager sharedManager].delegate = self;
        [YKSLocationManager sharedManager].delegate = self;
        [YKSErrorReporter sharedReporter].delegate = self;
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Engine already running. Environment: %@",
                                              YKSApiEnvName([YKSHTTPClient sharedClient].currentApiEnv)]
                              withErrorLevel:YKSErrorLevelInfo
                                     andType:YKSLogMessageTypeAPI];
        
        YKSUserInfo *userInfo = self.userInfo;
        // If we have user info, make sure the BLEManager is running
        if (userInfo) {
            
            // Notify BLEManager about saved session
            [[YBLEManager sharedManager] handleUserInfoUpdatedWithRemovedStays:nil andRemovedAmenities:nil withNewRoomAssigned:NO];
            
        } else {
            
            YKSLogAPIError(@"Error finding userInfo. Keychain credentials could be missing.");
            [[YKSLogger sharedLogger] logMessage:@"Error finding userInfo. Keychain credentials could be missing."
                                  withErrorLevel:YKSErrorLevelError
                                         andType:YKSLogMessageTypeAPI];
        }
        
        // Get new userInfo (incase it was changed since last session save to cache)
        [self refreshUserInfoWithSuccess:^(YKSUserInfo *userInfo) {
            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Refreshed userInfo onload"]
                                  withErrorLevel:YKSErrorLevelInfo
                                         andType:YKSLogMessageTypeAPI];
        } failure:^(YKSError *error) {
            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Failed to refreshInfo onload"]
                                  withErrorLevel:YKSErrorLevelError
                                         andType:YKSLogMessageTypeAPI];
        }];
        
    } else {
        
        self.engineState = kYKSEngineStateOff;
        
        YKSLogAPIError(@"Could not find current user from cache. Not starting Engine.");
        [[YKSLogger sharedLogger] logMessage:@"Could not find current user from cache. Not starting Engine."
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeAPI];
    }
    
    return self;
}

- (void)checkIfLowPowerModeIsEnabled {
    NSLog(@"Not implemented");
}

- (void)appDidBecomeActiveNotification:(NSNotification *)notification
{
    [[YKSAPIManager sharedManager] appDidBecomeActiveNotification:notification];
    //[[YKSBLEManager sharedManager] appDidBecomeActiveNotification:notification];
}

- (void)appWillEnterForegroundNotification:(NSNotification *)notification
{
    [[YKSAPIManager sharedManager] appWillEnterForegroundNotification:notification];
    //[[YKSBLEManager sharedManager] appWillEnterForegroundNotification:notification];
    
    if (self.engineState != kYKSEngineStateOff) {
        [self refreshUserInfoWithSuccess:^(YKSUserInfo *userInfo) {
            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Refreshed userInfo onEnterForeground"]
                                  withErrorLevel:YKSErrorLevelInfo
                                         andType:YKSLogMessageTypeAPI];
        } failure:^(YKSError *error) {
            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Failed to refreshInfo onEnterForeground"]
                                  withErrorLevel:YKSErrorLevelError
                                         andType:YKSLogMessageTypeAPI];
        }];
    }
    
    [[YKSServicesManager sharedManager] checkForMissingServices];
}

- (void)appDidEnterBackgroundNotification:(NSNotification *)notification
{
    [[YKSAPIManager sharedManager] appDidEnterBackgroundNotification:notification];
    //[[YKSBLEManager sharedManager] appDidEnterBackgroundNotification:notification];
}

/**
 *  Initial setup for APIManager & BLEManager
 */
- (void)setupEngineWithApiEnvironment:(YKSApiEnv)apiEnv
{
    [YKSAPIManager setupAPIManagerWithLogLevel:self.loggingLevelForAPI apiEnv:apiEnv];
    //[YKSBLEManager setupBLEManagerWithLogLevel:self.loggingLevelForBLEManager];
}

#pragma mark: YikesGenericEngine Protocol
- (bool)userIsSignedIn {
    return [[YikesEngineMP sharedEngine] userInfo] != nil && [[YikesEngineMP sharedEngine] currentPassword] != nil;
}

- (void)handlePushNotificationMessage:(NSString *)message completionHandler:(void(^)())completionHandler {
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Handling push notification with message %@", message] withErrorLevel:YKSErrorLevelInfo andType:YKSLogMessageTypeEngine];
}

- (YKSApiEnv)currentApiEnv
{
    return [YKSHTTPClient sharedClient].currentApiEnv;
}

- (BOOL)changeCurrentApiEnv:(YKSApiEnv)currentApiEnv
{
    if (self.engineState != kYKSEngineStateOff) {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Could not change environment to: %@", YKSApiEnvName(currentApiEnv)]
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeAPI];
        
        return NO;
    }
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Changing environment to: %@", YKSApiEnvName(currentApiEnv)]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    
    [self setupEngineWithApiEnvironment:currentApiEnv];
    
    BOOL result = YES;
    return result;
}

- (NSString *)currentApiEnvString {
    // NOTE: Not used - the Generic Engine will return this value
    return @"";
}

- (void)logMessage:(NSString *)message level:(YKSLoggerLevel *)level {
    [[YKSLogger sharedLogger] logMessage:message withErrorLevel:level andType:YKSLogMessageTypeApp];
}

- (void)setLoggingLevelForAPI:(YKSLoggerLevel)level
{
    _loggingLevelForAPI = level;
    [[YKSAPIManager sharedManager] setLoggingLevelForAPIManager:_loggingLevelForAPI];
}

- (void)setLoggingLevelForBLE:(YKSLoggerLevel)level
{
    _loggingLevelForBLE = level;
    //[[YKSBLEManager sharedManager] setLoggingLevelForBLEManager:_loggingLevelForBLE];
}

- (void)setEngineState:(YKSEngineState)engineState
{
    [[NSUserDefaults standardUserDefaults] setInteger:engineState forKey:@"YKSEngineState"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (engineState == kYKSEngineStateOn) {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Engine state: on, Environment: %@",
                                              YKSApiEnvName([YKSHTTPClient sharedClient].currentApiEnv)]
                              withErrorLevel:YKSErrorLevelInfo
                                     andType:YKSLogMessageTypeAPI];
        
    } else if (engineState == kYKSEngineStateOff) {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Engine state: off, Environment: %@",
                                              YKSApiEnvName([YKSHTTPClient sharedClient].currentApiEnv)]
                              withErrorLevel:YKSErrorLevelInfo
                                     andType:YKSLogMessageTypeAPI];
        
    } else if (engineState == kYKSEngineStatePaused) {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Engine state: paused, Environment: %@",
                                              YKSApiEnvName([YKSHTTPClient sharedClient].currentApiEnv)]
                              withErrorLevel:YKSErrorLevelInfo
                                     andType:YKSLogMessageTypeAPI];
    }
    
    if (_engineState != engineState) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(yikesEngineStateDidChange:)]) {
                [self.delegate yikesEngineStateDidChange:engineState];
            }
        });
    } else {
        YKSLogAPIInfo(@"Engine state did not change, not invoking callback");
    }
    
    _engineState = engineState;
}


- (YKSBLEEngineState)bleEngineState {
    return [YBLEManager sharedManager].internalBleEngineState;
}

- (YKSUserInfo *)userInfo
{
    YKSUser *user = [YKSSessionManager getCurrentUser];
    
    BOOL hasSavedCredentials = [YKSSessionManager currentGuestUsernameFromKeychains].length > 0 && [YKSSessionManager currentGuestPasswordFromKeychains].length > 0;
    
    if (user && hasSavedCredentials) {
        YKSUserInfo *userInfo = [user newUserInfo];
        return userInfo;
    }
    return nil;
}

- (void)startEngineWithUsername:(NSString *)username
                       password:(NSString *)password
                        success:(void (^)(YKSUserInfo *))successBlock
                        failure:(void (^)(YKSError *))failureBlock {
    [self startEngineWithUsername:username password:password requiresEULA:NO success:successBlock failure:failureBlock];
}

- (void)startEngineWithUsername:(NSString *)username
                       password:(NSString *)password
                   requiresEULA:(BOOL)requiresEULA
                        success:(void (^)(YKSUserInfo *))successBlock
                        failure:(void (^)(YKSError *))failureBlock
{
    if (!username || !password) {
        if (failureBlock) failureBlock([YKSError newWithErrorCode:kYKSFormMissingRequiredParameters
                                                 errorDescription:kYKSErrorFormMissingRequiredParametersDescription]);
        return;
    }
    
    /* Dont start the engine again if its already on or standby */
//    if (self.engineState != kYKSEngineStateOff) {
//        if (failureBlock) failureBlock([YKSError newWithErrorCode:kYKSErrorEngineAlreadyRunning
//                                                 errorDescription:kYKSErrorEngineAlreadyRunningDescription]);
//        return;
//    }
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Starting yikesEngine"]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    
    [self loginWithUsername:username password:password success:successBlock failure:failureBlock];
}

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                  success:(void (^)(YKSUserInfo *))successBlock
                  failure:(void (^)(YKSError *))failureBlock
{
    [YKSAPIManager loginRetryingNumberOfTimes:1
                                     username:username
                                     password:password
                                      success:^(YKSUser *user)
     {
         
         [YBLEManager sharedManager].guestEventDelegate = self;
         [YKSServicesManager sharedManager].delegate = self;
         [YMotionManager sharedManager].delegate = self;
         [YKSLocationManager sharedManager].delegate = self;
         [YKSErrorReporter sharedReporter].delegate = self;
         
         [[YKSDebugManager sharedManager] clearConnections];
         
         [[YBLEManager sharedManager] handleLogin];
         
         [self refreshUserInfoWithSuccess:^(YKSUserInfo *userInfo) {
             
             /* Start the engine */
             self.engineState = kYKSEngineStateOn;
             
             if (successBlock) successBlock(userInfo);
             
         } failure:^(YKSError *error) {
             
             YKSLogAPIError(@"Failed to refresh userInfo after login.");
             [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Failed to refresh userInfo after login."]
                                   withErrorLevel:YKSErrorLevelError
                                          andType:YKSLogMessageTypeAPI];
             if (failureBlock) failureBlock(error);
         }];
         
     } failure:^(AFHTTPRequestOperation *operation) {
         YKSLogAPIError(@"Failed to login.");
         [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Failed to login."]
                               withErrorLevel:YKSErrorLevelError
                                      andType:YKSLogMessageTypeAPI];
         if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
     }];
}

- (void)stopEngineWithSuccess:(void (^)())successBlock
{
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Stopping Engine. Environment: %@",
                                          YKSApiEnvName([YKSHTTPClient sharedClient].currentApiEnv)]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    
    if (self.engineState == kYKSEngineStateOff) {
        
        [[YKSLogger sharedLogger] logMessage:@"Engine was already OFF, not proceeding to stop engine"
                              withErrorLevel:YKSErrorLevelInfo
                                     andType:YKSLogMessageTypeAPI];
        
        return;
    }
    
    self.engineState = kYKSEngineStateOff;
    
    [[YBLEManager sharedManager] handleLogout];
    [[YKSDebugManager sharedManager] handleLogout];
    [[YKSFileLogger sharedInstance] handleLogout];
    
    [YKSSessionManager destroySession];
    
    // Dont logout here since we still want to be logged into SP Engine
    
//    [YKSAPIManager logoutWithSuccess:^{
//        
//        if (successBlock) successBlock();
//        
//    } failure:^(AFHTTPRequestOperation *operation) {
//        
//        [YKSError yikesErrorFromOperation:operation];
//        if (successBlock) successBlock();
//        
//    }];
}

- (void)requestLocationAlwaysAuthorization {
    [[YKSLocationManager sharedManager].locationManager requestAlwaysAuthorization];
}

- (NSString *)currentGuestUsername {

    return [YKSSessionManager currentGuestUsernameFromKeychains];
}


- (NSString *)currentPassword {
    return [YKSSessionManager currentGuestPasswordFromKeychains];
}

- (NSURL *)bundleURL {
    NSBundle *podbundle = [NSBundle bundleForClass:self.classForCoder];
    NSURL *bundleURL = [podbundle URLForResource:@"YikesEngineMP" withExtension:@"bundle"];
    return bundleURL;
}

- (void)refreshUserInfoWithFailure:(void (^)(YKSError *))failureBlock
{
    [self refreshUserInfoWithSuccess:nil failure:failureBlock];
}

- (void)refreshUserInfoWithSuccess:(void (^)(YKSUserInfo *))successBlock
                           failure:(void (^)(YKSError *))failureBlock
{
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Refreshing userInfo"]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    
    if (![YKSSessionManager getCurrentUser]) {
        [[YBLEManager sharedManager] handleLogout];
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"No userdata to refresh"]
                              withErrorLevel:YKSErrorLevelWarning
                                     andType:YKSLogMessageTypeAPI];
        if (failureBlock) failureBlock([YKSError newWithErrorCode:kYKSUserNotAuthorized errorDescription:kYKSErrorUserNotAuthorizedDescription]);
        return;
    }
    
    [YKSAPIManager getCurrentUserAndStaysRetryingNumberOfTimes:2 success:^(YKSUser *user) {
        
        [self getUserStayShareRequestsWithSuccess:^(NSArray *stayShares) {
            
            YKSUserInfo *userInfo = self.userInfo;
            
            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Refreshed userInfo: %@", userInfo]
                                  withErrorLevel:YKSErrorLevelInfo
                                         andType:YKSLogMessageTypeAPI];
            
            if (successBlock) {
                successBlock(userInfo);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(yikesEngineUserInfoDidUpdate:)]) {
                    [self.delegate yikesEngineUserInfoDidUpdate:userInfo];
                }
            });
            
        } failure:^(YKSError *error) {
            if (failureBlock) failureBlock(error);
        }];
        
    } failure:^(AFHTTPRequestOperation *operation) {
        
        YKSLogAPIError(@"Failed to refresh userInfo: %@", operation.error.localizedDescription);
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Failed to refresh userInfo %@", operation.error.localizedDescription]
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeAPI];
        
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
}

- (void)getUserStayShareRequestsWithSuccess:(void (^)(NSArray *))successBlock
                                    failure:(void (^)(YKSError *))failureBlock
{
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Refreshing user stay shares"]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    
    [YKSAPIManager getCurrentUserStaySharesWithSuccess:^(NSArray *stayShares) {
        
        NSError *error = nil;
        NSArray *stayShareJSONArray = [MTLJSONAdapter JSONArrayFromModels:stayShares error:&error];
        if (!error) {
            
            NSArray *stayShareInfos = [YKSStayShareInfo newStaySharesWithJSONArray:stayShareJSONArray];
            
            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Done refreshing user stay shares"]
                                  withErrorLevel:YKSErrorLevelInfo
                                         andType:YKSLogMessageTypeAPI];
            
            if (successBlock) {
                successBlock(stayShareInfos);
            }
            
        } else {
            if (failureBlock) failureBlock([YKSError newWithErrorCode:kYKSServerSidePayloadValidation errorDescription:@"Failed to create models."]);
        }
        
    } failure:^(AFHTTPRequestOperation *operation) {
        
        YKSLogAPIError(@"Failed to refresh user stay shares: %@", operation.error.localizedDescription);
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Failed to refresh user stay shares %@", operation.error.localizedDescription]
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeAPI];
        
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
}

- (void)sendStayShareRequestForStayId:(NSNumber *)stayId
                              toEmail:(NSString *)email
                              success:(void (^)(YKSStayShareInfo *, YKSUserInviteInfo *))successBlock
                              failure:(void (^)(YKSError *))failureBlock
{
    [YKSAPIManager createStayShareForStayId:stayId email:email success:^(YKSStayShare *stayShare, NSNumber *inviteId) {
        
        if (stayShare) {
            
            [[YikesEngineMP sharedEngine] getUserStayShareRequestsWithSuccess:^(NSArray *stayShares) {
                
                [stayShares enumerateObjectsUsingBlock:^(YKSStayShareInfo *stayShareInfo, NSUInteger idx, BOOL *stop) {
                    
                    if ([stayShare.stayShareId isEqualToNumber:stayShareInfo.stayShareId]) {
                        
                        if (successBlock) {
                            successBlock(stayShareInfo, nil);
                        }
                        *stop = YES;
                    }
                    
                }];
                
            } failure:^(YKSError *error) {
                if (failureBlock) failureBlock(error);
            }];
            
        } else if (inviteId) {
            
            [[YikesEngineMP sharedEngine] getUserInvitesWithSuccess:^(NSArray *userInvites) {
                
                [userInvites enumerateObjectsUsingBlock:^(YKSUserInviteInfo * _Nonnull userInvite, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    if ([userInvite.relatedStayId isEqualToNumber:stayId] && [userInvite.email isEqualToString:email]) {
                        
                        if (successBlock) {
                            successBlock(nil, userInvite);
                        }
                        *stop = YES;
                    }
                    
                }];
                
            } failure:^(YKSError *error) {
                if (failureBlock) failureBlock(error);
            }];
            
        } else {
            
            successBlock(nil, nil);
        }
        
    } failure:^(AFHTTPRequestOperation *operation) {
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
}

- (void)acceptStayShareRequest:(YKSStayShareInfo *)stayShare
                       success:(void (^)())successBlock
                       failure:(void (^)(YKSError *))failureBlock
{
    [YKSAPIManager updateStatusForStayShareWithId:stayShare.stayShareId stayId:stayShare.stay.stayId status:@"accepted" success:^{
        
        [[YikesEngineMP sharedEngine] refreshUserInfoWithSuccess:^(YKSUserInfo *user) {
            
            if (successBlock) {
                successBlock();
            }
            
        } failure:^(YKSError *error) {
            if (failureBlock) failureBlock(error);
        }];
        
    } failure:^(AFHTTPRequestOperation *operation) {
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
}

- (void)declineStayShareRequest:(YKSStayShareInfo *)stayShare
                        success:(void (^)())successBlock
                        failure:(void (^)(YKSError *))failureBlock
{
    [YKSAPIManager updateStatusForStayShareWithId:stayShare.stayShareId stayId:stayShare.stay.stayId status:@"declined" success:^{
        
        [[YikesEngineMP sharedEngine] refreshUserInfoWithSuccess:^(YKSUserInfo *user) {
            
            if (successBlock) {
                successBlock();
            }
            
        } failure:^(YKSError *error) {
            if (failureBlock) failureBlock(error);
        }];
        
    } failure:^(AFHTTPRequestOperation *operation) {
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
}

- (void)cancelStayShareRequest:(YKSStayShareInfo *)stayShare
                       success:(void (^)())successBlock
                       failure:(void (^)(YKSError *))failureBlock
{
    [YKSAPIManager updateStatusForStayShareWithId:stayShare.stayShareId stayId:stayShare.stay.stayId status:@"cancelled" success:^{
        
        [[YikesEngineMP sharedEngine] getUserStayShareRequestsWithSuccess:^(NSArray *stayShares) {
            
            if (successBlock) {
                successBlock();
            }
            
        } failure:^(YKSError *error) {
            if (failureBlock) failureBlock(error);
        }];
        
    } failure:^(AFHTTPRequestOperation *operation) {
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
}

- (void)cancelUserInviteRequest:(YKSUserInviteInfo *)userInvite
                        success:(void (^)())successBlock
                        failure:(void (^)(YKSError *))failureBlock
{
    [YKSAPIManager deleteUserInviteWithId:userInvite.inviteId success:^{
        
        [[YikesEngineMP sharedEngine] getUserInvitesWithSuccess:^(NSArray *userInvites) {
            
            if (successBlock) {
                successBlock();
            }
            
        } failure:^(YKSError *error) {
            if (failureBlock) failureBlock(error);
        }];
        
    } failure:^(AFHTTPRequestOperation *operation) {
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
}

- (void)getUserInvitesWithSuccess:(void (^)(NSArray *))successBlock
                          failure:(void (^)(YKSError *))failureBlock
{
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Refreshing user invites"]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    
    [YKSAPIManager getCurrentUserInvitesWithSuccess:^(NSArray *userInvites) {
        
        NSError *error = nil;
        NSArray *userInvitesJSONArray = [MTLJSONAdapter JSONArrayFromModels:userInvites error:&error];
        if (!error) {
            
            NSArray *userInviteInfos = [YKSUserInviteInfo newUserInvitesWithJSONArray:userInvitesJSONArray];
            
            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Done refreshing user invites"]
                                  withErrorLevel:YKSErrorLevelInfo
                                         andType:YKSLogMessageTypeAPI];
            
            if (successBlock) {
                successBlock(userInviteInfos);
            }
            
        } else {
            if (failureBlock) failureBlock([YKSError newWithErrorCode:kYKSServerSidePayloadValidation errorDescription:@"Failed to create models."]);
        }
        
    } failure:^(AFHTTPRequestOperation *operation) {
        
        YKSLogAPIError(@"Failed to refresh user invites: %@", operation.error.localizedDescription);
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Failed to refresh user invites %@", operation.error.localizedDescription]
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeAPI];
        
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
}

- (void)getRecentContactsWithSuccess:(void (^)(NSArray *))successBlock
                             failure:(void (^)(YKSError *))failureBlock
{
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Refreshing user contacts"]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    
    [YKSAPIManager getRecentContactsWithSuccess:^(NSArray *contacts) {
        
        NSError *error = nil;
        NSArray *contactsJSONArray = [MTLJSONAdapter JSONArrayFromModels:contacts error:&error];
        if (!error) {
            
            NSArray *contactsInfos = [YKSContactInfo newContactsWithJSONArray:contactsJSONArray];
            
            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Done refreshing user contacts"]
                                  withErrorLevel:YKSErrorLevelInfo
                                         andType:YKSLogMessageTypeAPI];
            
            if (successBlock) {
                successBlock(contactsInfos);
            }
            
        } else {
            if (failureBlock) failureBlock([YKSError newWithErrorCode:kYKSServerSidePayloadValidation errorDescription:@"Failed to create models."]);
        }
        
    } failure:^(AFHTTPRequestOperation *operation) {
        
        YKSLogAPIError(@"Failed to refresh user contacts: %@", operation.error.localizedDescription);
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Failed to refresh user contacts %@", operation.error.localizedDescription]
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeAPI];
        
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
        
    }];
}

- (void)removeRecentContact:(YKSContactInfo *)contact
                    success:(void (^)())successBlock
                    failure:(void (^)(YKSError *))failureBlock
{
    [YKSAPIManager deleteContactWithId:contact.contactId success:^{
        
        [[YikesEngineMP sharedEngine] getRecentContactsWithSuccess:^(NSArray *contacts) {
            
            if (successBlock) {
                successBlock();
            }
            
        } failure:^(YKSError *error) {
            if (failureBlock) failureBlock(error);
        }];
        
    } failure:^(AFHTTPRequestOperation *operation) {
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
}

/*
 * Fetch the most up-to-date user info and stays from yC after receiving a PN
 * Should call userInfoUpdated delegate method afterwards
 *
 */
- (void)handlePushNotificationMessage:(NSString *)message
{
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Received a push notification"]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    [self refreshUserInfoWithSuccess:nil failure:nil];
}

- (void)checkIfEmailIsRegistered:(NSString *)email
                         success:(void (^)(BOOL))successBlock
                         failure:(void (^)(YKSError *))failureBlock
{
    if (!email) {
        if (failureBlock) failureBlock([YKSError newWithErrorCode:kYKSFormMissingRequiredParameters
                                                 errorDescription:kYKSErrorFormMissingRequiredParametersDescription]);
        return;
    }
    
    [YKSAPIManager checkIfEmailIsRegistered:email success:^(BOOL isAlreadyRegistered, NSNumber *userId) {
        if (successBlock) successBlock(isAlreadyRegistered);
    } failure:^(AFHTTPRequestOperation *operation) {
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
}

- (void)registerUserWithForm:(NSDictionary *)form
                     success:(void (^)())successBlock
                     failure:(void (^)(YKSError *))failureBlock
{
    if (!form || !form[@"email"]) {
        if (failureBlock) failureBlock([YKSError newWithErrorCode:kYKSFormMissingRequiredParameters
                                                 errorDescription:kYKSErrorFormMissingRequiredParametersDescription]);
        return;
    }
    
    [YKSAPIManager checkIfEmailIsRegistered:form[@"email"] success:^(BOOL isAlreadyRegistered, NSNumber *userId) {
        
        if (!isAlreadyRegistered) {
            
            [YKSAPIManager registerUserWithForm:form success:^() {
                if (successBlock) successBlock();
            } failure:^(AFHTTPRequestOperation *operation) {
                if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
            }];
            
        } else {
            
            /* Email already registered */
            if (failureBlock) failureBlock([YKSError newWithErrorCode:kYKSUserEmailAlreadyRegistered
                                                     errorDescription:kYKSErrorUserEmailAlreadyRegisteredDescription]);
        }
        
    } failure:^(AFHTTPRequestOperation *operation) {
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
    
}


- (void)updatePasswordForUserId:(NSNumber *)userId
                    oldPassword:(NSString *)oldPassword
                    newPassword:(NSString *)newPassword
                confNewPassword:(NSString *)confNewPassword
                        success:(void (^)())successBlock
                        failure:(void (^)(YKSError *))failureBlock {
    
    [[YKSLogger sharedLogger]
     logMessage:@"updatePasswordForUserId was called in MultiPath, method not implemented! Should be called on Single Path only"
     withErrorLevel:YKSErrorLevelError
     andType:YKSLogMessageTypeAPI];
    
    [YKSAPIManager updatePasswordForUserId:userId oldPassword:oldPassword newPassword:newPassword success:^{
        if (successBlock) {
            successBlock();
        }
    } failure:^(AFHTTPRequestOperation *operation) {
        if (failureBlock) {
            failureBlock([YKSError yikesErrorFromOperation:operation]);
        }
    }];
}


- (void)forgotPasswordForEmail:(NSString *)email
                       success:(void (^)())successBlock
                       failure:(void (^)(YKSError *error))failureBlock
{
    [YKSAPIManager forgotPasswordForEmail:email success:^{
        if (successBlock) successBlock();
    } failure:^(AFHTTPRequestOperation *operation) {
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
}

- (void)updateUserWithForm:(NSDictionary<NSString *,id> *)form
                   success:(void (^)())successBlock
                   failure:(void (^)(YKSError *error))failureBlock {
    
    [YKSAPIManager updateUserWithForm:form success:^{
        
        [YKSAPIManager getCurrentUserAndStaysRetryingNumberOfTimes:2 success:^(YKSUser *user) {
            
            YKSUserInfo *userInfo = self.userInfo;
            
            if (successBlock) successBlock();
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(yikesEngineUserInfoDidUpdate:)]) {
                    [self.delegate yikesEngineUserInfoDidUpdate:userInfo];
                }
            });
            
        } failure:^(AFHTTPRequestOperation *operation) {
            if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
        }];
        
    } failure:^(AFHTTPRequestOperation *operation) {
        if (failureBlock) failureBlock([YKSError yikesErrorFromOperation:operation]);
    }];
}

- (void)setBackgroundCompletionHandler:(void (^)())completionHandler {
    // TODO: currently doing nothing
}

- (void)requestBeaconState {
    
    [[YKSLogger sharedLogger] logMessage:@"Requesting MP beacon state."
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    
    [[YKSLocationManager sharedManager] requestState:YES];
}

- (void)missingServices:(void (^)(NSSet *missingServices))completion {
    
    [[YKSServicesManager sharedManager] missingServices:^(NSSet *missingServices) {
        completion(missingServices);
    }];
}

- (BOOL)isInsideHotel {
    return [[YKSLocationManager sharedManager] isInsideYikesRegion];
}

- (YKSLocationState)currentLocationState {
    return [YKSLocationManager sharedManager].currentMPLocationState;
}

- (void)engineIsMissingServices:(NSSet *)missingServices {
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Missing services: %@", missingServices]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeService];
    
    [[YKSRequiredHardwareNotificationCenter sharedCenter] callFromEngineIsMissingServices:missingServices];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(yikesEngineRequiredServicesMissing:)]) {
            [self.delegate yikesEngineRequiredServicesMissing:missingServices];
        }
    });
    
}


#pragma mark YMotionManagerDelegate methods

- (void)deviceBecameStationary {
    
    if (self.engineState != kYKSEngineStateOff) {
        self.engineState = kYKSEngineStatePaused;
    }
    
    [[YKSLogger sharedLogger] logMessage:@"Device is stationary"
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeBLE];
    
    [[YBLEManager sharedManager] handleDeviceBecameStationary];
    
    [[MultiYManGAuthDispatcher sharedInstance] deviceIsNotMoving];
    
    [self callDeviceMotionStateDelegateMethod:kYKSDeviceMotionStateDidBecomeStationary];
    
}

- (void)deviceBecameActive {
    
    if (self.engineState != kYKSEngineStateOff) {
        self.engineState = kYKSEngineStateOn;
    }
    
    [[YKSLogger sharedLogger] logMessage:@"Device has moved, no longer stationary"
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeBLE];
    
    [[YBLEManager sharedManager] handleDeviceBecameActive];
    
    [[MultiYManGAuthDispatcher sharedInstance] deviceIsMoving];
    
    [self callDeviceMotionStateDelegateMethod:kYKSDeviceMotionStateIsMoving];
    
    // Refresh userInfo when device becomes active
    [self refreshUserInfoWithFailure:nil];
    
}

#pragma mark YKSLocationManagerDelegate methods

- (void)didEnterBeaconRegion {
    
    self.engineState = kYKSEngineStateOn;
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"[Location] Did enter beacon region"]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeBLE];
    
    [[YBLEManager sharedManager] handleEnteredRegion];
    
    [YKSSessionManager defaultAllConnectionStatuses];
    
    [[MultiYManGAuthDispatcher sharedInstance] deviceIsInsideIBeaconRegion];
    
    [[YKSServicesManager sharedManager] checkForMissingServices];
    
    [self callLocationStateDelegateMethod:kYKSLocationStateEnteredMPHotel];
}

- (void)didExitBeaconRegion {
    
    self.engineState = kYKSEngineStatePaused;
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"[Location] Did exit beacon region"]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeBLE];
    
    [[YBLEManager sharedManager] handleExitedRegion];
    
    [YKSSessionManager defaultAllConnectionStatuses];
    
    [[MultiYManGAuthDispatcher sharedInstance] deviceIsOutsideIBeaconRegion];
    
    [self callLocationStateDelegateMethod:kYKSLocationStateLeftMPHotel];
}


#pragma mark YikesEngineDelegate convenience methods

- (void)callLocationStateDelegateMethod:(YKSLocationState)state {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(yikesEngineLocationStateDidChange:)]) {
            [self.delegate yikesEngineLocationStateDidChange:state];
        }
        else {
            [[YKSLogger sharedLogger] logMessage:@"YikesEngineMP is missing a reference to the yikesEngineDelegate!" withErrorLevel:YKSErrorLevelCriticalError andType:YKSLogMessageTypeBLE];
        }
    });
    
}

- (void)callDeviceMotionStateDelegateMethod:(YKSDeviceMotionState)state {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(yikesEngineDeviceMotionStateDidChange:)]) {
            [self.delegate yikesEngineDeviceMotionStateDidChange:state];
        }
    });
    
}

- (void)callRoomEventDelegateMethod:(YKSConnectionStatus)newStatus withRoomNumber:(NSString *)roomNumber {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(yikesEngineRoomConnectionStatusDidChange:withRoom:)]) {
            [self.delegate yikesEngineRoomConnectionStatusDidChange:newStatus withRoom:roomNumber];
        }
    });
    
}

- (void)callCriticalErrorDelegateMethod:(YKSError *)error {
   
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(yikesEngineErrorDidOccur:)]) {
            [self.delegate yikesEngineErrorDidOccur:error];
        }
    });
    
}

#pragma mark YKSBLEManagerGuestEventDelegate methods

- (void)connectedToDoor:(NSString *)roomNumber {
    
    [self callRoomEventDelegateMethod:kYKSConnectionStatusConnectedToDoor withRoomNumber:roomNumber];
}

- (void)connectingToDoor:(NSString *)roomNumber {
    
    [self callRoomEventDelegateMethod:kYKSConnectionStatusConnectingToDoor withRoomNumber:roomNumber];
}

- (void)disconnectedFromDoor:(NSString *)roomNumber {
    
    [self callRoomEventDelegateMethod:kYKSConnectionStatusDisconnectedFromDoor withRoomNumber:roomNumber];
}

- (void)receivedAuthorization:(NSString *)roomNumber {
    
    [self callRoomEventDelegateMethod:kYKSConnectionStatusScanningForDoor withRoomNumber:roomNumber];
}

#pragma mark YKSErrorReporterDelegate methods

- (void)errorOccurredOverAcceptableRate:(YKSErrorDetector *)detector {
  
    if (detector.shouldTriggerExternalEngineError)  {
        [self callCriticalErrorDelegateMethod:detector.error];
    }
}

#pragma mark Debugging options

- (NSDictionary *)debugInformation {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:[YKSSessionManager getCurrentUser] forKey:@"CurrentUser"];
    return dictionary;
}

- (void)setDebugMode:(BOOL)on {
    [[YKSDebugManager sharedManager] setDebugMode:on];
}

- (void)showDebugViewInView:(UIView *)view {
    [[YKSDebugManager sharedManager] showDebugViewInView:view];
}

- (void)handleDebugToolsLogin {
    [[YKSDebugManager sharedManager] handleLogin];
    [[YKSFileLogger sharedInstance] handleLogin];
}


- (void)handleDebugToolsLogout {
    [[YKSDebugManager sharedManager] handleLogout];
    [[YKSFileLogger sharedInstance] handleLogout];
}


+ (void)initEngineWithDelegate:(id<YikesEngineDelegate>)yikesEngineDelegate {
    YikesEngineMP.sharedEngine.delegate = yikesEngineDelegate;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

@end
