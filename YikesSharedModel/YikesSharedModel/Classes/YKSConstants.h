//
//  YKSConstants.h
//  YikesEngine
//
//  Created by Manny Singh on 4/11/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef _YKSConstants_h
#define _YKSConstants_h

#define NILIFNULL(foo) ((foo == [NSNull null]) ? nil : foo)

typedef NS_ENUM(NSUInteger, YKSBeaconMode) {
    kYKSBeaconBased,
    kYKSSPForced,
    kYKSMPForced
};


/**
 *  Current state of YikesEngine
 */
typedef NS_ENUM(NSUInteger, YKSEngineArchitecture) {
    kYKSEngineArchitectureSinglePath,
    kYKSEngineArchitectureMultiPath
};

/**
 *  Current state of YikesEngine
 */
typedef NS_ENUM(NSUInteger, YKSEngineState) {
    kYKSEngineStateOff,
    kYKSEngineStateOn,
    kYKSEngineStatePaused
};


typedef NS_ENUM(NSUInteger, YKSBLEEngineState) {
    kYKSBLEEngineStateOff,
    kYKSBLEEngineStateOn
};

/**
 *  Api enviroment types.
 */
typedef NS_ENUM(NSUInteger, YKSApiEnv) {
    kYKSEnvPROD,
    kYKSEnvQA,
    kYKSEnvDEV
};

/**
 *  LoggerLevel for APIManager & BLEManager, see Yikes.h for info.
 */
typedef NS_ENUM(NSUInteger, YKSLoggerLevel) {
    kYKSLoggerLevelOff,
    kYKSLoggerLevelError,
    kYKSLoggerLevelInfo,
    kYKSLoggerLevelDebug
};

/**
 *  Device services that are required by YikesKit.
 */
typedef NS_ENUM(NSUInteger, YKSServiceType) {
    kYKSUnknownService,
    kYKSBluetoothService,
    kYKSLocationService,
    kYKSInternetConnectionService,
    kYKSPushNotificationService,
    kYKSBackgroundAppRefreshService
};

typedef NS_ENUM(NSUInteger, YKSLocationState) {
    kYKSLocationStateUnknown,
    kYKSLocationStateEnteredSPHotel,
    kYKSLocationStateLeftSPHotel,
    kYKSLocationStateEnteredMPHotel,
    kYKSLocationStateLeftMPHotel,
};

typedef NS_ENUM(NSUInteger, YKSDeviceMotionState) {
    kYKSDeviceMotionStateIsMoving,
    kYKSDeviceMotionStateDidBecomeStationary,
};

typedef NS_ENUM(NSUInteger, YKSConnectionStatus) {
    kYKSConnectionStatusDisconnectedFromDoor,
    kYKSConnectionStatusScanningForDoor,
    kYKSConnectionStatusConnectingToDoor,
    kYKSConnectionStatusConnectedToDoor
};

typedef NS_ENUM(NSUInteger, YKSDisconnectReasonCode) {
    kYKSDisconnectReasonCodeUnknown,
    kYKSDisconnectReasonCodeProximity,
    kYKSDisconnectReasonCodeInside,
    kYKSDisconnectReasonCodeClosed,
    kYKSDisconnectReasonCodeNotActive,
    kYKSDisconnectReasonCodeExpired,
    kYKSDisconnectReasonCodeSuperseded,
    kYKSDisconnectReasonCodeFatal,
    // jumping to 100 to leave some space for eventual new yLink reason codes:
    kYKSDisconnectReasonCodeStationary = 100,
    kYKSDisconnectReasonCodeNoAccess
};

/**
 *  Errors for API & BLE.
 */
typedef NS_ENUM(NSUInteger, YKSErrorCode) {
    kYKSUnknown,
    kYKSFormMissingRequiredParameters,
    kYKSFormValidation,                    // Incorrect parameter format
    kYKSMissingRequiredServices,           // Only used when bluetooth & location services are missing
    kYKSUserEmailAlreadyRegistered,        // /api/verify?email
    kYKSUserNotAuthorized,                 // 401
    kYKSUserForbidden,                     // 403
    kYKSResourceConflict,                  // 409
    kYKSRequestFailedNoResponse,           // empty response, request timeout
    kYKSFailureConnectingToYikesServer,    // code: -1003
    kYKSEngineAlreadyRunning,              // Used when you try to start engine multiple times
    kYKSServerSidePayloadValidation,       // 400
    kYKSClientSidePayloadValidation,       // Invalid / unhandled payload
    kYKSBluetoothConnectionError,          // Repeated Code=10s. Requires bluetooth restart
    kYKSBluetoothServiceDiscoveryError,    // Code 3
    kYKSBluetoothUnknownError,
    kYKSBluetoothAuthDoesNotMatchAnyRooms,
    kYKSInvalidCredentials,
    kYKSMissingInputOutput,
    kYKSEngineLPVerifyDoesNotMatch,
    kYKSEngineLowPowerModeEnabled
    
};

static NSString *const kYKSErrorUnknownDescription                          = @"Unknown error occurred.";
static NSString *const kYKSErrorFormMissingRequiredParametersDescription    = @"Missing required parameters.";
static NSString *const kYKSErrorFormValidationDescription                   = @"Form validation error.";
static NSString *const kYKSErrorMissingRequiredServicesDescription          = @"Required device services are missing.";
static NSString *const kYKSErrorUserEmailAlreadyRegisteredDescription       = @"Email is already registered.";
static NSString *const kYKSErrorUserNotAuthorizedDescription                = @"Current user is not authorized.";
static NSString *const kYKSErrorRequestFailedNoResponseDescription          = @"The request timed out or the server did not return any response.";
static NSString *const kYKSErrorUserForbiddenDescription                    = @"Current user is forbidden.";
static NSString *const kYKSErrorResourceConflictDescription                 = @"Resource conflict occurred.";
static NSString *const kYKSErrorFailureConnectingToYikesServerDescription   = @"There was a problem connecting to yikes servers.";
static NSString *const kYKSErrorEngineAlreadyRunningDescription             = @"Engine is already running.";
static NSString *const kYKSErrorFailedToTransformDataDescription            = @"yikes failed to transform data.";
static NSString *const kYKSErrorServerSidePayloadValidationDescription      = @"The server denied the payload";
static NSString *const kYKSErrorInvalidCredentialsDescription               = @"Invalid credentials";



#endif
