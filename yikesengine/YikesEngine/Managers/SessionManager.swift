//
//  SessionManager.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/18/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import YKSSPLocationManager

class YKSSessionManager {
    
    static let sharedInstance = YKSSessionManager()
    
	var currentUser : User? {
        
        willSet(newUser) {
            StoreManager.sharedInstance.copyUserBeacons(newUser, oldUser: currentUser)
            StoreManager.sharedInstance.notifyOfYLinksRemoved(newUser?.stays, oldStays: currentUser?.stays)
            StoreManager.sharedInstance.copyTempPasswordValues(newUser, oldUser: currentUser)
        }
        
        didSet {
            if (currentUser != nil) {
                StoreManager.sharedInstance.verifyYLinkConnectionStatuses()
                StoreManager.sharedInstance.copyConnectionStatuses(currentUser?.stays, oldStays: oldValue?.stays)
                StoreManager.sharedInstance.copyYLinkConnections(currentUser?.stays, oldStays: oldValue?.stays)
                StoreManager.sharedInstance.notifyOfYLinksAdded(currentUser?.stays, oldStays: oldValue?.stays)
                StoreManager.sharedInstance.saveCurrentUser()
                
                YKSSPLocationManager.shared().hoteliBeaconUUID = currentUser?.beacon?.uuid
                YKSSPLocationManager.shared().hoteliBeaconIdentifier = EngineConstants.YIKES_SP_BEACON_IDENTIFIER
                YKSSPLocationManager.shared().delegate = YikesEngineSP.sharedInstance
            }
        }
    }
    
    var isSessionActive : Bool { return currentUser != nil ? true : false }
    
    func destroySession() {
        yLog(LoggerLevel.info, category: LoggerCategory.System, message: "Destroying current user session.")
        
        currentUser = nil
        deleteAllCookies()
        
        StoreManager.sharedInstance.removeGuestAppSessionCookieAndObject()
    }
    
    func getSessionCookie() -> HTTPCookie? {
        
        let baseURL = Router.baseURLString
        let allCookies = HTTPCookieStorage.shared.cookies(for: URL(string: baseURL)!)
        
        for cookie : HTTPCookie in allCookies! {
            if cookie.name == EngineConstants.sessionCookieName {
                return cookie
            }
        }
        
        yLog(LoggerLevel.info, category: LoggerCategory.System, message: "Session cookie was not found in HTTPCookieStorage.")
        return nil
    }
    
    func deleteAllCookies() {
        
        let baseURL = Router.baseURLString
        let allCookies = HTTPCookieStorage.shared.cookies(for: URL(string: baseURL)!)
        
        for cookie : HTTPCookie in allCookies! {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
    
}
