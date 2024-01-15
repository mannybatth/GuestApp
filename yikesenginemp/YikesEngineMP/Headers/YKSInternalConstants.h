//
//  YKSInternalConstants.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSLevelLogger.h"

#ifndef YKSApiKit_YKSInternalConstants_h
#define YKSApiKit_YKSInternalConstants_h


/**
 *  Macro used for logging in different YKSLoggerLevel's
 *
 *  YKSLogAPIDebug/YKSLogBLEDebug   will log Error, Info, & Debug messages
 *  YKSLogAPIInfo/YKSLogBLEInfo     will log Error & Info messages
 *  YKSLogAPIError/YKSLogAPIError   will log only Error messages
 *
 */
#define LOG_API_MACRO(lvl, frmt, ...)                           \
        [YKSLevelLogger logAPIWithLevel : lvl                        \
                            format : (frmt), ## __VA_ARGS__]

//#define LOG_BLE_MACRO(lvl, frmt, ...)                           \
//        [YKSLevelLogger logBLEWithLevel : lvl                        \
//                            format : (frmt), ## __VA_ARGS__]

#define YKSLogAPIError(frmt, ...)  LOG_API_MACRO(kYKSLoggerLevelError, frmt, ##__VA_ARGS__)
#define YKSLogAPIInfo(frmt, ...)   LOG_API_MACRO(kYKSLoggerLevelInfo, frmt, ##__VA_ARGS__)
#define YKSLogAPIDebug(frmt, ...)  LOG_API_MACRO(kYKSLoggerLevelDebug, frmt, ##__VA_ARGS__)

//#define YKSLogBLEError(frmt, ...)  LOG_BLE_MACRO(kYKSLoggerLevelError, frmt, ##__VA_ARGS__)
//#define YKSLogBLEInfo(frmt, ...)   LOG_BLE_MACRO(kYKSLoggerLevelInfo, frmt, ##__VA_ARGS__)
//#define YKSLogBLEDebug(frmt, ...)  LOG_BLE_MACRO(kYKSLoggerLevelDebug, frmt, ##__VA_ARGS__)

#define YKSApiEnvName(apiEnv) [YKSLevelLogger apiEnvToString:apiEnv]

/**
 *  Used to determine if using GuestApp or HotelApp.
 */
typedef NS_ENUM(NSUInteger, YKSAppName) {
    yksNoAppName,
    yksGuestApp,
    yksHotelApp
};

/**
 *  Base URLs for api environments.
 */
static NSString *const yksDEVBaseURLString  = @"https://dev-api.yikes.co";
static NSString *const yksQABaseURLString   = @"https://qa-api.yikes.co";
static NSString *const yksPRODBaseURLString = @"https://api.yikes.co";

/**
 *  NSUserDefaults key used to store appName.
 */
static NSString *const yksAppNameKey = @"yksAppNameUserDefaultsKey";

/**
 *  NSUserDefaults key used to store selected api environment.
 */
static NSString *const yksCurrentApiEnvKey = @"yksCurrentApiEnvUserDefaultsKey";


/**
 *  Name of cookie set by yCentral.
 */
static NSString *const yksSessionCookieName = @"session_id_ycentral";

/**
 *  Name of folder where yikes model cache is stored.
 */
static NSString *const yksModelCacheDirectoryFolderName     = @"yikesCache";

/**
 *  Keychain name used to store guest email, password, session token.
 */
static NSString *const yksKeychainGuestAppServiceName       = @"co.yikes.yikes";
static NSString *const yksKeychainGuestEmailAccountName     = @"co.yikes.yikes.email";
static NSString *const yksKeychainGuestPasswordAccountName  = @"co.yikes.yikes.password";

static NSString *const yksKeychainHotelAppServiceName       = @"co.yikes.yikes-Hotel";
static NSString *const yksKeychainHotelEmailAccountName     = @"co.yikes.yikes-Hotel.email";
static NSString *const yksKeychainHotelPasswordAccountName  = @"co.yikes.yikes-Hotel.password";

static NSString *const yksKeychainSessionTokenAccountName   = @"co.yikes.session.token";

/**
 *  iOS version check macros
 */
#define IS_OS_7_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
#define IS_OS_8_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)


#endif
