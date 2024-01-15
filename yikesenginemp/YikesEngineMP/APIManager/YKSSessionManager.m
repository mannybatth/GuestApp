//
//  YKSSessionManager.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/5/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSSessionManager.h"
#import "YKSHTTPClient.h"
#import "YKSUser.h"
#import "YKSStay.h"
#import "YKSSession.h"
#import "SSKeychain.h"
#import "YKSPrimaryYMan.h"
#import "YKSAmenity.h"
#import "YMan.h"
#import "YKSLogger.h"
#import "YKSInternalConstants.h"
#import "YKSBinaryHelper.h"

@import YikesSharedModel;

#import <SSKeychain/SSKeychain.h>

@interface YKSSessionManager()

@property (nonatomic, strong) YKSSession *currentSession;

@end

@implementation YKSSessionManager

+ (instancetype)sharedManager
{
    static YKSSessionManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[YKSSessionManager alloc] init];
        _sharedManager.currentSession = [_sharedManager restoreSessionFromCache];
    });
    
    return _sharedManager;
}

+ (void)newSessionWithUser:(YKSUser *)user
{
    YKSSession *newSession = [[YKSSession alloc] initWithUser:user];
    [YKSSessionManager sharedManager].currentSession = newSession;
    [[YKSSessionManager sharedManager] saveSessionToCache:newSession];
}

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAlways];
    
    return self;
}

+ (YKSUser *)getCurrentUser
{
    return [YKSSessionManager sharedManager].currentSession ? [YKSSessionManager sharedManager].currentSession.currentUser : nil;
}

+ (void)setCurrentUser:(YKSUser *)user
{
    YKSSession *session = [YKSSessionManager sharedManager].currentSession;
    session.currentUser = user;
}


//TODO: Rename to make clear that "current" really means "day" not specific time
+ (NSArray *)validUserStays
{
    if ([YKSSessionManager isSessionActive]) {
        NSArray *stays = [YKSSessionManager getCurrentUser].stays;
        NSMutableArray *validStays = [[NSMutableArray alloc] init];
        for (YKSStay *stay in stays) {
            if (stay.roomNumber) {
                [validStays addObject:stay];
            }
        }
        if (validStays.count > 0) {
            return validStays;
        }
    }
    return nil;
}


+ (BOOL)areThereCurrentStaysForYMan:(YMan *)yMan {
    
    for (YKSStay * stay in [self validUserStays]) {
        
        for (YKSPrimaryYMan * primaryYMan in stay.primaryYMen) {
          
            NSData * macAddress = [YKSBinaryHelper binaryFromHexString:primaryYMan.macAddress];
            
            if ([macAddress isEqual:yMan.macAddress] && [stay isCurrent]) {
                return YES;
            }
        }
    }
    
    return NO;
}


+ (NSSet *)allPrimaryYMen
{
    if ([YKSSessionManager isSessionActive]) {
        
        NSMutableSet *primaryYMen = [NSMutableSet set];
        
        NSArray *stays = [YKSSessionManager getCurrentUser].stays;
        
        for (YKSStay *stay in stays) {
            if (stay.primaryYMen && stay.primaryYMen.count > 0) {
                
                NSSet * stayPrimaryYMEN = [NSSet setWithArray:stay.primaryYMen];
                
                [primaryYMen unionSet:stayPrimaryYMEN];
            }
        }
        return [NSSet setWithSet:primaryYMen];
    }
    return nil;
}

+ (NSSet *)allAmenities {
   
    if (![YKSSessionManager isSessionActive]) {
        return nil;
    }
    
    NSMutableSet * amenities = [NSMutableSet set];
    
    NSArray * stays = [YKSSessionManager getCurrentUser].stays;

    for (YKSStay * stay in stays) {
       
        if (stay.amenities && stay.amenities.count > 0) {
           
            NSSet * stayAmenities = [NSSet setWithArray:stay.amenities];
            
            [amenities unionSet:stayAmenities];
            
        }
        
        
    }
   
    return [NSSet setWithSet:amenities];
    
}

+ (NSSet *)allRoomNames {
   
    if (![YKSSessionManager isSessionActive]) {
        return nil;
    }
    
    NSMutableSet * roomNames = [NSMutableSet set];
    
    NSArray * stays = [YKSSessionManager getCurrentUser].stays;
    
    for (YKSStay * stay in stays) {
      
        if (stay.roomNumber) {
            [roomNames addObject:stay.roomNumber];
        }
        
        if (stay.amenities && stay.amenities.count > 0) {
           
            for (YKSAmenity * amenity in stay.amenities) {
       
                if (amenity.name) {
                    [roomNames addObject:amenity.name];
                
                }
                
            }
            
        }
        
        
    }
    
    
    return [NSSet setWithSet:roomNames];
    
}

+ (BOOL)isRoomNameInStay:(NSString *)roomName {
   
    for (NSString * name in [YKSSessionManager allRoomNames]) {

        if ([name isEqualToString:roomName]) {
            return YES;
        }
        
    }
    
    return NO;
    
}



+ (id)stayOrAmenityForRoomNumber:(NSString *)roomNumber
{
    if ([YKSSessionManager isSessionActive]) {
        
        NSArray *stays = [YKSSessionManager getCurrentUser].stays;
        for (YKSStay *stay in stays) {
            if ([stay.roomNumber isEqualToString:roomNumber]) {
                return stay;
            }
            for (YKSAmenity *amenity in stay.amenities) {
                if ([amenity.name isEqualToString:roomNumber]) {
                    return amenity;
                }
            }
        }
    }
    return nil;
}

+ (void)defaultAllConnectionStatuses
{
    if ([YKSSessionManager isSessionActive]) {
        
        NSArray *stays = [YKSSessionManager getCurrentUser].stays;
        for (YKSStay *stay in stays) {
            stay.connectionStatus = kYKSConnectionStatusDisconnectedFromDoor;
            for (YKSAmenity *amenity in stay.amenities) {
                amenity.connectionStatus = kYKSConnectionStatusDisconnectedFromDoor;
            }
        }
    }
}

+ (BOOL)isSessionActive
{
    return [YKSSessionManager sharedManager].currentSession ? YES : NO;
}

+ (NSString *)sessionRootObjectNameForCurrentApiEnv
{
    YKSApiEnv apiEnv = [YKSHTTPClient sharedClient].currentApiEnv;
    if (apiEnv == kYKSEnvQA) {
        return [NSString stringWithFormat:@"%@_QA", [YKSSession class]];
    } else if (apiEnv == kYKSEnvDEV) {
        return [NSString stringWithFormat:@"%@_DEV", [YKSSession class]];
    }
    return [NSString stringWithFormat:@"%@", [YKSSession class]];
}

+ (void)saveActiveSessionToCache
{
    YKSSession *session = [YKSSessionManager sharedManager].currentSession;
    [[YKSSessionManager sharedManager] saveSessionToCache:session];
}

- (void)saveSessionToCache:(YKSSession *)session
{
    [YKSSessionManager storeGuestAppSessionCookieToKeychain];
    [YKSModel saveWithRootObject:session withCacheName:[YKSSessionManager sessionRootObjectNameForCurrentApiEnv]];
}

- (YKSSession *)restoreSessionFromCache
{
    YKSSession *session = [YKSModel rootObjectWithCacheName:[YKSSessionManager sessionRootObjectNameForCurrentApiEnv]];
    [YKSSessionManager loadGuestAppSessionCookieFromKeychain];
    return session;
}

+ (void)destroySession
{
    [YKSSessionManager setCurrentUser:nil];
    [YKSSessionManager sharedManager].currentSession = nil;
    [YKSSessionManager deleteAllCookies];
    [YKSSessionManager removeGuestAppSessionCookieFromKeychain];
    [YKSModel removeRootObjectWithCacheName:[YKSSessionManager sessionRootObjectNameForCurrentApiEnv]];
}

+ (NSHTTPCookie *)getSessionCookie
{
    NSURL *baseURL = [[YKSHTTPClient operationManager] baseURL];
    NSArray *allCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:baseURL];
    
    __block NSHTTPCookie *cookie = nil;
    [allCookies enumerateObjectsUsingBlock:^(NSHTTPCookie *cookieObj, NSUInteger idx, BOOL *stop) {
        if ([cookieObj.name isEqualToString:yksSessionCookieName]) {
            cookie = cookieObj;
            *stop = YES;
        }
    }];
    return cookie;
}

+ (void)deleteAllCookies
{
    NSURL *baseURL = [[YKSHTTPClient operationManager] baseURL];
    NSArray *allCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:baseURL];
    
    [allCookies enumerateObjectsUsingBlock:^(NSHTTPCookie *cookieObj, NSUInteger idx, BOOL *stop) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookieObj];
    }];
}

+ (BOOL)storeGuestAppSessionCookieToKeychain
{
    NSHTTPCookie *sessionCookie = [self getSessionCookie];
    if (sessionCookie && sessionCookie.properties) {
        NSData *cookiePropertiesData = [NSJSONSerialization dataWithJSONObject:sessionCookie.properties
                                                       options:0
                                                         error:nil];
        NSString *cookiePropertiesString = [[NSString alloc] initWithData:cookiePropertiesData
                                                                 encoding:NSUTF8StringEncoding];
        
        BOOL stored = YES;
        NSError *error = nil;
        if (![SSKeychain setPassword:cookiePropertiesString forService:yksKeychainGuestAppServiceName account:yksKeychainSessionTokenAccountName error:&error]) {
            stored = NO;
            DLog(@"User's session cookie could not be stored in keychain. %@", error);
            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"User's session cookie could not be stored in keychain. %@ %ld %@",
                                                  error.domain, (long)error.code, error.localizedDescription]
                                  withErrorLevel:YKSErrorLevelError
                                         andType:YKSLogMessageTypeAPI];
        }
        return stored;
    }
    return NO;
}

+ (void)loadGuestAppSessionCookieFromKeychain
{
    NSString *cookiePropertiesString = [SSKeychain passwordForService:yksKeychainGuestAppServiceName account:yksKeychainSessionTokenAccountName];
    if (cookiePropertiesString) {
        
        NSData *cookiePropertiesData = [cookiePropertiesString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSDictionary *cookieProperties = [NSJSONSerialization JSONObjectWithData:cookiePropertiesData
                                                                          options:0
                                                                            error:nil];
        NSHTTPCookie *sessionCookie = [[NSHTTPCookie alloc] initWithProperties:cookieProperties];
        
        NSArray *cookieArray = [NSArray arrayWithObject:sessionCookie];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookieArray
                                                           forURL:[YKSHTTPClient operationManager].baseURL
                                                  mainDocumentURL:nil];
    }
}

+ (void)removeGuestAppSessionCookieFromKeychain
{
    [SSKeychain deletePasswordForService:yksKeychainGuestAppServiceName account:yksKeychainSessionTokenAccountName];
}

// TODO: need an alternative way to extend session instead of saving guest password
+ (BOOL)storeCurrentGuestAppUserEmail:(NSString *)email
                          andPassword:(NSString *)password
{
    NSError *error = nil;
    BOOL stored = YES;
    if (![SSKeychain setPassword:email forService:yksKeychainGuestAppServiceName account:yksKeychainGuestEmailAccountName error:&error]) {
        stored = NO;
        DLog(@"User's email could not be stored in keychain. %@", error);
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"User's email could not be stored in keychain. %@ %ld %@",
                                              error.domain, (long)error.code, error.localizedDescription]
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeAPI];
    }
    if (![SSKeychain setPassword:password forService:yksKeychainGuestAppServiceName account:yksKeychainGuestPasswordAccountName error:&error]) {
        stored = NO;
        DLog(@"User's password could not be stored in keychain. %@", error);
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"User's password could not be stored in keychain. %@ %ld %@",
                                              error.domain, (long)error.code, error.localizedDescription]
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeAPI];
    }
    return stored;
}

+ (NSString *)currentGuestUsernameFromKeychains
{
    NSString *username = [SSKeychain passwordForService:yksKeychainGuestAppServiceName account:yksKeychainGuestEmailAccountName];
    return username ? username : @"";
}

+ (NSString *)currentGuestPasswordFromKeychains
{
    NSString *password = [SSKeychain passwordForService:yksKeychainGuestAppServiceName account:yksKeychainGuestPasswordAccountName];
    return password ? password : @"";
}

+ (void)removeCurrentGuestCredentialsFromKeychains
{
    [SSKeychain deletePasswordForService:yksKeychainGuestAppServiceName account:yksKeychainGuestEmailAccountName];
    [SSKeychain deletePasswordForService:yksKeychainGuestAppServiceName account:yksKeychainGuestPasswordAccountName];
}

//+ (BOOL)storeCurrentHotelAppUserEmail:(NSString *)email
//                          andPassword:(NSString *)password
//{
//    BOOL stored = YES;
//    if (![SSKeychain setPassword:email forService:yksKeychainHotelAppServiceName account:yksKeychainHotelEmailAccountName]) {
//        stored = NO;
//        DLog(@"Hotel user's email could not be stored in keychain");
//    }
//    if (![SSKeychain setPassword:password forService:yksKeychainHotelAppServiceName account:yksKeychainHotelPasswordAccountName]) {
//        stored = NO;
//        DLog(@"Hotel user's password could not be stored in keychain");
//    }
//    return stored;
//}

//+ (BOOL)storeHotelAppSessionToKeychain
//{
//    NSHTTPCookie *sessionCookie = [self getSessionCookie];
//    NSString *cookiePropertiesDesc = [NSString stringWithFormat:@"%@", sessionCookie.properties];
//    BOOL stored = YES;
//    if (![SSKeychain setPassword:cookiePropertiesDesc forService:yksKeychainHotelAppServiceName account:yksKeychainSessionTokenAccountName]) {
//        stored = NO;
//        DLog(@"User's session cookie could not be stored in keychain");
//    }
//    return stored;
//}

//+ (void)loadHotelAppSessionFromKeychain
//{
//    NSString *sessionToken = [SSKeychain passwordForService:yksKeychainGuestAppServiceName account:yksKeychainSessionTokenAccountName];
//}

@end
