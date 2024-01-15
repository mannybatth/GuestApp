//
//  Constants.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/30/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation
import YikesSharedModel

public struct EngineConstants {
    
    // key used to select beacon mode
    public static let beaconModeKey = "yksEngineBeaconModeKey"
    public static let architectureKey   = "yksEngineCurrentArchitectureKey"
    
    // key used by engine to tell whether multipath mode is ON
    public static let engineMPEnabledKey   = "yksEngineMPEnabledKey"
    
    // key used by engine to tell whether singlepath mode is permitted
    public static let engineSPEnabledKey   = "yksEngineSPEnabledKey"

    // key used by engine to force SP and ignore MP
    public static let engineSPForceKey     = "yksEngineSPForceKey"
    
    // key used to store the engine state to user defaults
    public static let engineStateKeyMP     = "YKSEngineState"
    public static let engineStateKeySP     = "yksEngineStateSP"
    
    // key used to store the selected api environment to user defaults
    public static let currentApiEnvKey     = "yksCurrentApiEnvUserDefaultsKey"
    
    // name of the cookie we get from yC after login
    public static let sessionCookieName    = "session_id_ycentral";
    
    
    public static let maxAllowedLoggerLevelKey = "maxAllowedLoggerLevelKey"
    public static let yLinkDebuggingDisabledKey = "yLinkDebuggingDisabledKey"
    
    // Slack remote Logging
    public static let slackRemoteLoggingChannelKey = "slackRemoteLoggingChannelKey"
    
    // keychain account names for storing username & password
    public static let keychainGuestAppServiceName = "co.yikes.yikes"
    public static let keychainGuestEmailAccountName = "co.yikes.yikes.email"
    public static let keychainGuestPasswordAccountName = "co.yikes.yikes.password"
    
    // keychain account name for storing the session cookie
    public static let keychainSessionTokenAccountName = "co.yikes.session.token"
    
    public static let YIKES_SP_BEACON_IDENTIFIER = "YIKES SP BEACON"
    
    // CoreMotion / Inactivity
    #if DEBUG
    public static let INACTIVITY_TIMEOUT = 30 // in seconds
    #else
    public static let INACTIVITY_TIMEOUT = 30 // in seconds
    #endif
    public static let INACTIVITY_SENSITIVITY = 0.05 // 0.01 = even if held in hand, it's moving. if sitting on a desk, it's stationary
    
    
    public static let YLINK_SERVICE_UUID = "C3221178-2E83-40E2-9F12-F07B57A77E1F"
    public static let YLINK_READ_CHAR_UUID = "6795137C-F551-43AF-AC71-6340C5CFD080"
    public static let YLINK_WRITE_CHAR_UUID = "06F87DA4-6264-4C8F-9ADB-D077380CEFA9"
    public static let YLINK_DEBUG_MESSAGE_UUID = "AEBE81FE-BFB7-4BE3-B148-36BE2308AE57"
}

public extension YKSDisconnectReasonCode {
    
    var description : String {
        get {
            switch (self) {
            case .unknown:
                return "Unknown"
            case .proximity:
                return "Proximity"
            case .inside:
                return "Inside"
            case .closed:
                return "Closed"
            case .notActive:
                return "Not Active"
            case .expired:
                return "Expired"
            case .superseded:
                return "Superseded"
            case .fatal:
                return "Fatal"
            case .stationary:
                return "Stationary"
            case .noAccess:
                return "No Access"
            }
        }
    }
    
}

public extension YKSConnectionStatus {
    
    var description : String {
        switch self {
        case .disconnectedFromDoor:
            return "DisconnectedFromDoor"
        case .scanningForDoor:
            return "ScanningForDoor"
        case .connectingToDoor:
            return "ConnectingToDoor"
        case .connectedToDoor:
            return "ConnectedToDoor"
        }
    }
    
}


public extension YKSApiEnv {
    
    var stringValue : String {
        switch self {
        case .envDEV:
            return "DEV"
        case .envQA:
            return "QA"
        case .envPROD:
            return "PROD"
        }
    }
    
    var baseURLString : String {
        switch self {
        case .envDEV:
            return "https://dev-api.yikes.co"
        case .envQA:
            return "https://qa-api.yikes.co"
        case .envPROD:
            return "https://api.yikes.co"
        }
    }
    
    var currentUserCacheKey: String {
        switch self {
        case .envDEV:
            return "currentUserDEV"
        case .envQA:
            return "currentUserQA"
        default:
            return "currentUserPROD"
        }
    }
    
    var yLinksDynamicRssiCacheKey: String {
        switch self {
        case .envDEV:
            return "yLinksDynamicRssiDev_v2"
        case .envQA:
            return "yLinksDynamicRssiQA_v2"
        default:
            return "yLinksDynamicRssiPROD_v2"
        }
    }
    
    
    var old_currentUserCacheKey : String {
        switch self {
        case .envDEV:
            return "YKSSession_DEV.plist"
        case .envQA:
            return "YKSSession_QA.plist"
        default:
            return "YKSSession_PROD.plist"
        }
    }
    
}


public extension YKSServiceType {
    
    var stringValue : String {
        
        switch self {
        case .unknownService:
            return "Unknown"
        case .bluetoothService:
            return "Bluetooth"
        case .locationService:
            return "Location"
        case .internetConnectionService:
            return "InternetConnection"
        case .pushNotificationService:
            return "PushNotification"
        case .backgroundAppRefreshService:
            return "BackgroundAppRefresh"
        }
        
    }
}

public extension YKSEngineArchitecture {
    
    var stringValue : String {
        
        switch self {
        case .multiPath:
            return "MultiPath"
        case .singlePath:
            return "SinglePath"
        }
    }
}

public func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
