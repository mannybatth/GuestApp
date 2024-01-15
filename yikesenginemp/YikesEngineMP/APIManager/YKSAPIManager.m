//
//  YKSAPIManager.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSAPIManager.h"
#import "AFNetworkActivityLogger.h"
#import "YKSSessionRequest.h"
#import "YKSUserRequest.h"
#import "YKSHotelRequest.h"
#import "YKSSessionManager.h"
#import "YKSAmenity.h"
#import "YKSStay.h"
#import "YBLEManager.h"
#import "YKSLogger.h"
#import "YKSServicesManager.h"

@implementation YKSAPIManager

+ (instancetype)sharedManager
{
    static YKSAPIManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[YKSAPIManager alloc] init];
    });
    
    return _sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    
    return self;
}

+ (void)setupAPIManagerWithLogLevel:(YKSLoggerLevel)level apiEnv:(YKSApiEnv)apiEnv appName:(YKSAppName)appName
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:appName] forKey:yksAppNameKey];
    [YKSAPIManager setupAPIManagerWithLogLevel:level apiEnv:apiEnv];
}

+ (void)setupAPIManagerWithLogLevel:(YKSLoggerLevel)level apiEnv:(YKSApiEnv)apiEnv
{
    [YKSAPIManager sharedManager].loggingLevelForAPIManager = level;
    
    /* Override default API environment */
    [YKSHTTPClient sharedClient].currentApiEnv = apiEnv;
    
    /* Needed to restore session from cache */
    [YKSSessionManager sharedManager];
}

- (void)appDidBecomeActiveNotification:(NSNotification *)notification
{
    /* Needed to restore session from cache */
    [YKSSessionManager sharedManager];
}

- (void)appWillEnterForegroundNotification:(NSNotification *)notification
{
    
}

- (void)appDidEnterBackgroundNotification:(NSNotification *)notification
{
    /* Insure that Session is saved to cache */
    [YKSSessionManager saveActiveSessionToCache];
}

- (void)setLoggingLevelForAPIManager:(YKSLoggerLevel)level
{
    _loggingLevelForAPIManager = level;
    switch (_loggingLevelForAPIManager) {
        case kYKSLoggerLevelOff:
            [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelOff];
            break;
        
        case kYKSLoggerLevelError:
            [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelError];
            break;
            
        case kYKSLoggerLevelInfo:
            [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelInfo];
            break;
            
        case kYKSLoggerLevelDebug:
            [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
            break;
            
        default:
            break;
    }
}

+ (void)loginRetryingNumberOfTimes:(NSUInteger)ntimes
                          username:(NSString *)username
                          password:(NSString *)password
                           success:(void (^)(YKSUser *))successBlock
                           failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    [YKSSessionRequest loginWithUsername:username password:password success:^(YKSUser *user, AFHTTPRequestOperation *operation) {
        
        /* Start a new session */
        [YKSSessionManager newSessionWithUser:user];
        
        [YKSSessionManager storeCurrentGuestAppUserEmail:username andPassword:password];
        
        successBlock(user);
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (ntimes > 0) {
            if (operation.response) {
                NSInteger statusCode = operation.response.statusCode;
                
                if (statusCode == 409) {
                    
                    [YKSAPIManager logoutWithSuccess:^{
                        
                        [YKSAPIManager loginRetryingNumberOfTimes:ntimes-1
                                                         username:username
                                                         password:password
                                                          success:successBlock
                                                          failure:failureBlock];
                        
                    } failure:^(AFHTTPRequestOperation *operation) {
                        
                        [YKSAPIManager loginRetryingNumberOfTimes:ntimes-1
                                                         username:username
                                                         password:password
                                                          success:successBlock
                                                          failure:failureBlock];
                        
                    }];
                    
                    return;
                }
            }
            
            [YKSAPIManager loginRetryingNumberOfTimes:ntimes-1
                                             username:username
                                             password:password
                                              success:successBlock
                                              failure:failureBlock];
            return;
        }
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

+ (void)loginWithKeychainCredentialsWithSuccess:(void (^)(YKSUser *))successBlock
                                        failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Attempting to login with saved credentials."]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    
    if (![YKSSessionManager currentGuestUsernameFromKeychains] ||
        [[[YKSSessionManager currentGuestUsernameFromKeychains] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"No saved username was found."]
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeAPI];
        failureBlock(nil);
        return;
    }
    
    if (![YKSSessionManager currentGuestPasswordFromKeychains] ||
        [[[YKSSessionManager currentGuestPasswordFromKeychains] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"No saved password was found."]
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeAPI];
        failureBlock(nil);
        return;
    }
    
    [YKSAPIManager loginRetryingNumberOfTimes:1
                                     username:[YKSSessionManager currentGuestUsernameFromKeychains]
                                     password:[YKSSessionManager currentGuestPasswordFromKeychains]
                                      success:successBlock
                                      failure:^(AFHTTPRequestOperation *operation) {
                                          
                                          [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Failed to login with saved credentials."]
                                                                withErrorLevel:YKSErrorLevelError
                                                                       andType:YKSLogMessageTypeAPI];
                                          
                                          failureBlock(operation);
                                      }];
}

+ (void)logoutWithSuccess:(void (^)())successBlock
                  failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    [YKSHTTPClient cancelAllRequests];
    
    /* Destroy current session */
    [YKSSessionManager destroySession];
    [YKSSessionManager removeCurrentGuestCredentialsFromKeychains];
    
    [YKSSessionRequest logoutWithSuccess:^(AFHTTPRequestOperation *operation) {
        
        successBlock();
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

/**
 *  Equivalent to "updateUserStays()" in diagram
 *  Will fetch user & stays from yC and save to cache
 */
+ (void)getCurrentUserAndStaysRetryingNumberOfTimes:(NSUInteger)ntimes
                                            success:(void (^)(YKSUser *))successBlock
                                            failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    YKSUser *user = [YKSSessionManager getCurrentUser];
    
    [YKSUserRequest getUserAndStaysWithUserId:user.id success:^(YKSUser *newUser, AFHTTPRequestOperation *operation) {
        
        YKSUser *oldUser = [YKSSessionManager getCurrentUser];
        
        /* Save user to session */
        /* Need to check for stays first, API doesnt return a user object if there are no stays */
        if (newUser.stays && newUser.stays.count > 0) {
            
            [YKSSessionManager setCurrentUser:newUser];
            
            // Notify BLEManager about removed stays & amenities
            // Copy connection statuses from old stays to new stays
            [self handleUpdatedStays:newUser.stays withPreviousStays:oldUser.stays];
            [self handleUpdatedUser: newUser withPreviviousUser: oldUser];
            
            [YKSSessionManager saveActiveSessionToCache];
            
            successBlock(newUser);
            
        } else {
            
            /* Remove stays from session */
            YKSUser *currentUser = [YKSSessionManager getCurrentUser];
            currentUser.stays = nil;
            
            // Notify BLEManager about removed stays & amenities
            // Copy connection statuses from old stays to new stays
            [self handleUpdatedStays:currentUser.stays withPreviousStays:oldUser.stays];
            [self handleUpdatedUser: newUser withPreviviousUser: oldUser];
            
            [YKSSessionManager saveActiveSessionToCache];
            
            successBlock(currentUser);
        }
        
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (ntimes > 0) {
            if (operation.response) {
                NSInteger statusCode = operation.response.statusCode;
                
                if (statusCode == 403 || statusCode == 401) {
                    
                    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Received statusCode %li", (long)statusCode]
                                          withErrorLevel:YKSErrorLevelDebug
                                                 andType:YKSLogMessageTypeAPI];
                    
                    [YKSAPIManager loginWithKeychainCredentialsWithSuccess:^(YKSUser *user) {
                        
                        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Retrying get user stays after relogin. Tries left: %lu.", (unsigned long)ntimes-1]
                                              withErrorLevel:YKSErrorLevelDebug
                                                     andType:YKSLogMessageTypeAPI];
                        
                        [YKSAPIManager getCurrentUserAndStaysRetryingNumberOfTimes:ntimes-1
                                                                           success:successBlock
                                                                           failure:failureBlock];
                        
                    } failure:failureBlock];
                    
                    return;
                    
                } else if (statusCode == 400) {
                    
                    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Received 400 statusCode when trying to fetch user stays. Tries left: %lu.", (unsigned long)ntimes-1]
                                          withErrorLevel:YKSErrorLevelError
                                                 andType:YKSLogMessageTypeAPI];
                    
                    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"400 statusCode Response: %@", operation.responseObject]
                                          withErrorLevel:YKSErrorLevelDebug
                                                 andType:YKSLogMessageTypeAPI];
                    failure:failureBlock;
                    
                }
            }
            
            [YKSAPIManager getCurrentUserAndStaysRetryingNumberOfTimes:ntimes-1
                                                               success:successBlock
                                                               failure:failureBlock];
            return;
        }
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

+ (void)handleUpdatedStays:(NSArray *)newStays withPreviousStays:(NSArray *)oldStays {
    
    // create set of old stayIds & amenityIds
    NSMutableSet *oldAmenityIds = [[NSMutableSet alloc] init];
    NSMutableSet *oldStayIds = [[NSMutableSet alloc] init];
    for (YKSStay *stay in oldStays) {
        [oldStayIds addObject:stay.stayId];
        for (YKSAmenity *amenity in stay.amenities) {
            [oldAmenityIds addObject:amenity.amenityId];
        }
    }
    
    // create set of new stayIds & amenityIds
    NSMutableSet *newAmenityIds = [[NSMutableSet alloc] init];
    NSMutableSet *newStayIds = [[NSMutableSet alloc] init];
    for (YKSStay *stay in newStays) {
        [newStayIds addObject:stay.stayId];
        for (YKSAmenity *amenity in stay.amenities) {
            [newAmenityIds addObject:amenity.amenityId];
        }
    }
    
    // filter out stayIds that exist in both sets
    NSMutableSet *constantStayIds = [NSMutableSet setWithSet:oldStayIds];
    [constantStayIds intersectSet:newStayIds];
    
    // filter out stayIds that were added
    NSMutableSet *addedStayIds = [NSMutableSet setWithSet:newStayIds];
    [addedStayIds minusSet:oldStayIds];
    
    NSMutableSet *removedStayIds;
    NSMutableSet *removedAmenityIds;
    
    if (addedStayIds.count == 0) {
        // filter out stayIds that were removed
        removedStayIds = [NSMutableSet setWithSet:oldStayIds];
        [removedStayIds minusSet:newStayIds];
        
        // filter out amenityIds that were removed
        removedAmenityIds = [NSMutableSet setWithSet:oldAmenityIds];
        [removedAmenityIds minusSet:newAmenityIds];
        
        // add stays whose roomNumber was changed from room1 -> room2 or room -> nil
        for (NSNumber *stayId in constantStayIds) {
            YKSStay *oldStay = [YKSStay findStayById:stayId fromStays:oldStays];
            YKSStay *newStay = [YKSStay findStayById:stayId fromStays:newStays];
            
            if (oldStay.roomNumber) {
                
                if (newStay.roomNumber == nil) {
                    
                    // room was unassigned
                    [removedStayIds addObject:stayId];
                    
                } else if (![newStay.roomNumber isEqualToString:oldStay.roomNumber]) {
                    
                    // room was reassigned, treated as "added"
                    [addedStayIds addObject:stayId];
                    
                } else {
                    
                    // copy connection status of room because room number was the same
                    newStay.connectionStatus = oldStay.connectionStatus;
                    
                    // copy connection status of amenities
                    for (YKSAmenity *amenity in oldStay.amenities) {
                        YKSAmenity *newAmenity = [YKSStay findAmenityById:amenity.amenityId fromStays:newStays];
                        if (newAmenity) {
                            newAmenity.connectionStatus = amenity.connectionStatus;
                        }
                    }
                }
                
                // remove stay if current date is not within check-in/check-out datetime
                if (![newStay isCurrent]) {
                    [removedStayIds addObject:stayId];
                }
            }
        }
    }
    
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Calling [BLEManager handleUserInfoUpdatedWithRemovedStays andRemovedAmenities]"]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    
    // a room was reassigned or unassigned
    if (addedStayIds.count > 0) {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"A room was reassigned or unassigned"]
                              withErrorLevel:YKSErrorLevelInfo
                                     andType:YKSLogMessageTypeAPI];
        
        [[YBLEManager sharedManager] handleUserInfoUpdatedWithRemovedStays:nil andRemovedAmenities:nil withNewRoomAssigned:YES];
        return;
    }
    
    NSMutableSet *removedStays = [NSMutableSet set];
    for (NSNumber *stayId in removedStayIds) {
        YKSStay *stay = [YKSStay findStayById:stayId fromStays:oldStays];
        [removedStays addObject:stay];
    }
    
    NSMutableSet *removedAmenities = [NSMutableSet set];
    for (NSNumber *amenityId in removedAmenityIds) {
        YKSAmenity *amenity = [YKSStay findAmenityById:amenityId fromStays:oldStays];
        [removedAmenities addObject:amenity];
    }
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Removed Stays: %@", removedStays]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Removed Amenities: %@", removedAmenities]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeAPI];
   
    [[YBLEManager sharedManager] handleUserInfoUpdatedWithRemovedStays:removedStays andRemovedAmenities:removedAmenities  withNewRoomAssigned:NO];
    
}


+ (void)handleUpdatedUser: (YKSUser *)newUser withPreviviousUser: (YKSUser *)oldUser {
    
    newUser.hasTempPassword = oldUser.hasTempPassword;
}


+ (void)getHotelWithId:(NSNumber *)hotelId
               success:(void (^)(YKSHotel *))successBlock
               failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    [YKSHotelRequest getHotelWithId:hotelId success:^(YKSHotel *hotel, AFHTTPRequestOperation *operation) {
        
        successBlock(hotel);
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

+ (void)checkIfEmailIsRegistered:(NSString *)email
                         success:(void (^)(BOOL, NSNumber *))successBlock
                         failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    [YKSSessionRequest checkIfEmailIsRegistered:email success:^(BOOL isAlreadyRegistered, YKSUser *user, AFHTTPRequestOperation *operation) {
        
        if (user) {
            successBlock(isAlreadyRegistered, user.id);
        } else {
            successBlock(isAlreadyRegistered, nil);
        }
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

+ (void)registerUserWithForm:(NSDictionary *)form
                     success:(void (^)())successBlock
                     failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    [YKSSessionRequest registerUserWithForm:form success:^(AFHTTPRequestOperation *operation) {
        
        successBlock();
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

+ (void)forgotPasswordForEmail:(NSString *)email
                       success:(void (^)())successBlock
                       failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    [YKSSessionRequest forgotPasswordForEmail:email success:^(AFHTTPRequestOperation *operation) {
        
        successBlock();
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

+ (void)getCurrentUserStaySharesWithSuccess:(void (^)(NSArray *))successBlock failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    YKSUser *user = [YKSSessionManager getCurrentUser];
    
    [YKSUserRequest getStaySharesForUserId:user.id success:^(NSArray *stayShares, AFHTTPRequestOperation *operation) {
        
        YKSUser *currentUser = [YKSSessionManager getCurrentUser];
        currentUser.stayShares = stayShares;
        
        successBlock(stayShares);
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

+ (void)createStayShareForStayId:(NSNumber *)stayId
                           email:(NSString *)email
                         success:(void (^)(YKSStayShare *, NSNumber *))successBlock
                         failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    [YKSAPIManager checkIfEmailIsRegistered:email success:^(BOOL isAlreadyRegistered, NSNumber *userId) {
        
        if (isAlreadyRegistered) {
            
            [YKSUserRequest createStayShareForStayId:stayId userId:userId success:^(YKSStayShare *stayShare, AFHTTPRequestOperation *operation) {
                
                successBlock(stayShare, nil);
                [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
            
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
                failureBlock(operation);
                [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
                
            }];
            
        } else {
            
            YKSUser *user = [YKSSessionManager getCurrentUser];
            NSDictionary *form = @{
                                   @"email": email
                                   };
            
            [YKSUserRequest createUserInviteForStayId:stayId byUserId:user.id withUserForm:form success:^(NSNumber *inviteId, AFHTTPRequestOperation *operation) {
                
                successBlock(nil, inviteId);
                [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
                failureBlock(operation);
                [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
                
            }];
        }
        
    } failure:^(AFHTTPRequestOperation *operation) {
        
        failureBlock(operation);
        
    }];
}

+ (void)updateStatusForStayShareWithId:(NSNumber *)stayShareId
                                stayId:(NSNumber *)stayId
                                status:(NSString *)status
                               success:(void (^)())successBlock
                               failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    [YKSUserRequest updateStatusForStayShareWithId:stayShareId stayId:stayId status:status success:^(AFHTTPRequestOperation *operation) {
        
        successBlock();
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

+ (void)getCurrentUserInvitesWithSuccess:(void (^)(NSArray *))successBlock
                                 failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    YKSUser *user = [YKSSessionManager getCurrentUser];
    
    [YKSUserRequest getUserInvitesForUserId:user.id success:^(NSArray *userInvites, AFHTTPRequestOperation *operation) {
        
        YKSUser *currentUser = [YKSSessionManager getCurrentUser];
        currentUser.userInvites = userInvites;
        
        successBlock(userInvites);
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

+ (void)deleteUserInviteWithId:(NSNumber *)inviteId
                       success:(void (^)())successBlock
                       failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    YKSUser *user = [YKSSessionManager getCurrentUser];
    
    [YKSUserRequest deleteUserInviteWithId:inviteId userId:user.id success:^(AFHTTPRequestOperation *operation) {
        
        successBlock();
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

+ (void)getRecentContactsWithSuccess:(void (^)(NSArray *))successBlock failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    YKSUser *user = [YKSSessionManager getCurrentUser];
    
    [YKSUserRequest getContactsForUserId:user.id success:^(NSArray *contacts, AFHTTPRequestOperation *operation) {
        
        YKSUser *currentUser = [YKSSessionManager getCurrentUser];
        currentUser.recentContacts = contacts;
        
        successBlock(contacts);
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

+ (void)deleteContactWithId:(NSNumber *)contactId
                    success:(void (^)())successBlock
                    failure:(void (^)(AFHTTPRequestOperation *))failureBlock
{
    YKSUser *user = [YKSSessionManager getCurrentUser];
    
    [YKSUserRequest deleteContactWithId:contactId userId:user.id success:^(AFHTTPRequestOperation *operation) {
        
        successBlock();
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}


+ (void)updatePasswordForUserId:(NSNumber *)userId
                    oldPassword:(NSString *)oldPwd
                    newPassword:(NSString *)newPwd
                        success:(void (^)())successBlock
                        failure:(void (^)(AFHTTPRequestOperation *))failureBlock {
    
    [YKSUserRequest updatePasswordForUserId:userId oldPassword:oldPwd newPassword:newPwd success:^(AFHTTPRequestOperation *operation) {
        successBlock();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation);
    }];
    
    
}

+ (void)updateUserWithForm:(NSDictionary *)form
                   success:(void (^)())successBlock
                   failure:(void (^)(AFHTTPRequestOperation *))failureBlock {
    
    YKSUser *user = [YKSSessionManager getCurrentUser];
    
    [YKSUserRequest updateUserWithForm:form userId:user.id success:^(AFHTTPRequestOperation *operation) {
        
        successBlock();
        [[YKSServicesManager sharedManager] checkForMissingServicesOnlyIfInternetWasNotFound];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failureBlock(operation);
        [[YKSServicesManager sharedManager] checkForMissingServicesWithOperationError:operation.error];
        
    }];
}

@end
