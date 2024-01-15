//
//  StoreManager.swift
//  YikesEngine
//
//  Created by Alexandar Dimitrov on 2016-01-11.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import YikesSharedModel
import KeychainAccess

class StoreManager {
    
    static let sharedInstance = StoreManager()
    
    let keychain = Keychain(service: EngineConstants.keychainGuestAppServiceName).accessibility(Accessibility.always)
    
    var observers : [Observer] = []
    
    func saveCurrentUser() {
        
        notifyObservers(ObserverNotification(observableEvent: ObservableEvent.StoreManagerUserWasUpdated, data: nil))
        
        if let user = YKSSessionManager.sharedInstance.currentUser {
            CacheHelper.saveObjectToCache(user, cacheName: YikesEngineSP.sharedEngine().currentApiEnv.currentUserCacheKey)
        } else {
            yLog(LoggerLevel.error, category: LoggerCategory.System, message: "No user found to save to cache.")
        }
    }
    
    func restoreCurrentUser() {
        
        if let user: User = CacheHelper.getObjectWithCacheName(YikesEngineSP.sharedEngine().currentApiEnv.currentUserCacheKey) {
            YKSSessionManager.sharedInstance.currentUser = user
            self.loadGuestAppSessionCookieFromKeychain()
            notifyObservers(ObserverNotification(observableEvent: ObservableEvent.StoreManagerUserWasUpdated, data: nil))
        }
    }
    
    func restoreYLinksThresholdsFromCache() -> ConnectionThresholdAdjuster? {
        
        yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "Trying to restore yLinks Thresholds from cache.")
        
        return CacheHelper.getObjectWithCacheName(YikesEngineSP.sharedEngine().currentApiEnv.yLinksDynamicRssiCacheKey)
    }
    
    func saveYLinksThresholdsToCache(_ connectionThresholdAdjuster: ConnectionThresholdAdjuster) {
        CacheHelper.saveObjectToCache(connectionThresholdAdjuster, cacheName: YikesEngineSP.sharedEngine().currentApiEnv.yLinksDynamicRssiCacheKey)
    }
    
    func notifyOfYLinksRemoved(_ newStays: [Stay]?, oldStays: [Stay]?) {
        
        guard let newStays = newStays, let oldStays = oldStays else {
            return
        }
        
        var newYLinksSet = Set<YLink>()
        var oldYLinksSet = Set<YLink>()
        
        
        for stay in newStays {
            if let yLink = stay.yLink {
                newYLinksSet.insert(yLink)
            }
            
            for amenity in stay.amenities {
                if let yLink = amenity.yLink {
                    newYLinksSet.insert(yLink)
                }
            }
        }
        
        for stay in oldStays {
            if let yLink = stay.yLink {
                oldYLinksSet.insert(yLink)
            }
            
            for amenity in stay.amenities {
                if let yLink = amenity.yLink {
                    oldYLinksSet.insert(yLink)
                }
            }
        }
        
        let removedYLinks = Set(oldYLinksSet).subtracting(newYLinksSet)
        
        if (removedYLinks.count > 0) {
            notifyObservers(ObserverNotification(observableEvent: ObservableEvent.YLinksRemoved, data: removedYLinks))
        }
    }
    
    func notifyOfYLinksAdded(_ newStays: [Stay]?, oldStays: [Stay]?) {
        
        guard let newStays = newStays, let oldStays = oldStays else {
            return
        }
        
        var newYLinksSet = Set<YLink>()
        var oldYLinksSet = Set<YLink>()
        
        for stay in newStays {
            if let yLink = stay.yLink {
                newYLinksSet.insert(yLink)
            }
            
            for amenity in stay.amenities {
                if let yLink = amenity.yLink {
                    newYLinksSet.insert(yLink)
                }
            }
        }
        
        for stay in oldStays {
            if let yLink = stay.yLink {
                oldYLinksSet.insert(yLink)
            }
            
            for amenity in stay.amenities {
                if let yLink = amenity.yLink {
                    oldYLinksSet.insert(yLink)
                }
            }
        }
        
        let addedYLinks = Set(newYLinksSet).subtracting(oldYLinksSet)
        
        
//        if (addedYLinks.count > 0) { // this used to cause an issue with stays that have been shortened or extended and it wouldn't notify the observers here
            notifyObservers(ObserverNotification(observableEvent: ObservableEvent.YLinksAdded, data: addedYLinks))
//        }
    }
    
    func copyYLinkConnections(_ newStays: [Stay]?, oldStays: [Stay]?) {
        
        guard let newStays = newStays, let oldStays = oldStays else {
            return
        }
        
        for stay in newStays {
            
            if let matchingStay = oldStays.filter({ $0.stayId == stay.stayId }).first,
                let oldConnections = matchingStay.yLink?.connections {
                    
                    stay.yLink?.connections = oldConnections
                
                    if let newConnections = stay.yLink?.connections {
                        for connection in newConnections {
                            if let yLink = stay.yLink {
                                connection.yLink = yLink
                            }
                        }
                    }
                    
                    for amenity in stay.amenities {
                        
                        if let matchingAmenity = matchingStay.amenities.filter({ $0.amenityId == amenity.amenityId }).first,
                            let oldConnections = matchingAmenity.yLink?.connections {
                                
                                amenity.yLink?.connections = oldConnections
                            
                                if let newConnections = amenity.yLink?.connections {
                                    for connection in newConnections {
                                        connection.yLink = amenity.yLink!
                                        connection.yLink.amenity = amenity
                                    }
                                }
                        }
                    }
            }
        }
    }
    
    func copyConnectionStatuses(_ newStays: [Stay]?, oldStays: [Stay]?) {
                
        guard let newStays = newStays, let oldStays = oldStays else {
            return
        }
        
        for newStay in newStays {
            
            if let oldMatchingStay = oldStays.filter({ $0.stayId == newStay.stayId }).first {
                
                if (newStay.roomNumber != nil) {
                    newStay.connectionStatus = oldMatchingStay.connectionStatus
                }
                else {
                    newStay.connectionStatus = .disconnectedFromDoor
                }
                
                for amenity in newStay.amenities {
                    
                    if let matchingAmenity = oldMatchingStay.amenities.filter({ $0.amenityId == amenity.amenityId }).first {
                        
                        amenity.connectionStatus = matchingAmenity.connectionStatus
                    }
                }
            }
        }
    }
    
    func copyTempPasswordValues(_ newUser: User?, oldUser: User?) {
        
        if let hasTempPassword = oldUser?.hasTempPassword {
            newUser?.hasTempPassword = hasTempPassword
        }
    }
    
    func verifyYLinkConnectionStatuses() {
        
        guard let yLinks = YKSSessionManager.sharedInstance.currentUser?.yLinks else {
            return
        }
        
        for yLink in yLinks {
            yLink.verifyConnectionStatus()
        }
    }
    
    func copyUserBeacons(_ newUser: User?, oldUser: User?) {
        
        // dont copy if we have a beacon UUID already
        if newUser?.beacon != nil {
            return
        }
        
        if let beacon = oldUser?.beacon {
            newUser?.beacon = beacon
        }
    }
    
    
    func storeGuestAppSessionCookieToKeychain() {
        yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "Storing session cookie to keychain.")
        
        let cookie = YKSSessionManager.sharedInstance.getSessionCookie()
        
        guard let cookieProperties = cookie?.properties else {
            yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Session cookie does not have any properties to store.")
            return
        }
        
        do {
            
            let cookiesPropertiesData = try JSONSerialization.data(withJSONObject: cookieProperties, options: JSONSerialization.WritingOptions(rawValue:0))
            
            do {
                try keychain.set(cookiesPropertiesData, key: EngineConstants.keychainSessionTokenAccountName)
            } catch let error {
                yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Failed to store session cookie to keychain. Error: \(error)")
            }
            
        } catch {
            yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Failed to serialize session cookie to data. Error: \(error)")
        }
    }
    
    
    func loadGuestAppSessionCookieFromKeychain() {
        yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "Loading session cookie from keychain.")
        
        let baseURL = Router.baseURLString
        
        do {
            
            guard let cookiesPropertiesData = try keychain.getData(EngineConstants.keychainSessionTokenAccountName) else {
                yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Cookie properties from keychain were nil.")
                return
            }
            
            do {
                
                let cookieProperties = try JSONSerialization.jsonObject(with: cookiesPropertiesData, options: JSONSerialization.ReadingOptions(rawValue: 0))
                
                if let cookieProperties = cookieProperties as? [HTTPCookiePropertyKey : Any],
                    let cookie = HTTPCookie(properties: cookieProperties) {
                        yLog(message: "Successfully retrieved session cookie from Keychain.")
                        HTTPCookieStorage.shared.setCookies([cookie], for: URL(string: baseURL), mainDocumentURL: nil)
                } else {
                    yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Failed to type cast sessionCookie.properties.")
                }
                
            } catch let error {
                yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Failed to serialize session cookie data from keychain. Error: \(error)")
            }
            
        } catch let error {
            yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Failed to get session cookie data from keychain. Error: \(error)")
        }
    }
    

    func storeCurrentGuestAppUserEmail(_ email: String, password: String) -> Bool {
        yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "Saving user credentials to keychains.")
        
        do {
            try keychain.set(email, key: EngineConstants.keychainGuestEmailAccountName)
            
            do {
                
                try keychain.set(password, key: EngineConstants.keychainGuestPasswordAccountName)
                return true
                
            } catch let error {
                yLog(LoggerLevel.error, category: LoggerCategory.System, message: "User password could not be stored in keychain. Error: \(error)")
            }
            
        } catch let error {
            yLog(LoggerLevel.error, category: LoggerCategory.System, message: "User email could not be stored in keychain. Error: \(error)")
        }
        
        return false
    }
    
    
    func currentGuestUsernameAndPasswordFromKeychains() -> (guestUsername: String, guestPassword: String)? {
        yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "Retrieving user credentials from keychains.")
        
        do {
            
            guard let username = try keychain.getString(EngineConstants.keychainGuestEmailAccountName) else {
                yLog(LoggerLevel.error, category: LoggerCategory.System, message: "User email found in keychain was nil.")
                return nil
            }
            
            do {
                
                guard let password = try keychain.getString(EngineConstants.keychainGuestPasswordAccountName) else {
                    yLog(LoggerLevel.error, category: LoggerCategory.System, message: "User password found in keychain was nil.")
                    return nil
                }
                
                return (username, password)
                
            } catch let error {
                yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Failed to get user password from keychain. Error: \(error)")
            }
            
        } catch let error {
            yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Failed to get user email from keychain. Error: \(error)")
        }
        
        return nil
    }
    
    
    func removeCurrentGuestCredentialsFromKeychains() {
        
        do {
            
            try keychain.remove(EngineConstants.keychainGuestEmailAccountName)
            try keychain.remove(EngineConstants.keychainGuestPasswordAccountName)
            
        } catch let error {
            yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Failed to remove user credentials from keychain. Error: \(error)")
        }
    }
    
    
    func removeGuestAppSessionCookieFromKeychain() {
        do {
            
            try keychain.remove(EngineConstants.keychainSessionTokenAccountName)
            
        } catch let error {
            yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Failed to remove session cookie from keychain. Error: \(error)")
        }
    }
    
    
    func removeObjectWithCurrentCacheName() {
        CacheHelper.removeObjectWithCacheName(YikesEngineSP.sharedEngine().currentApiEnv.currentUserCacheKey)
    }
    
    func removeObjectsFromAllCaches() {
        CacheHelper.removeObjectWithCacheName("currentUserDEV")
        CacheHelper.removeObjectWithCacheName("currentUserQA")
        CacheHelper.removeObjectWithCacheName("currentUserPROD")
    }
    
    
    func removeGuestAppSessionCookieAndObject() {
        removeGuestAppSessionCookieFromKeychain()
        removeObjectsFromAllCaches()
    }
    
}

extension StoreManager: Observable {
    
    func addObserver(_ observer: Observer) {
        let index = observers.index { $0 === observer }
        if index == nil {
            observers.append(observer)
        }
    }
    
    func removeObserver(_ observer: Observer) {
        let index = observers.index { $0 === observer }
        if index != nil {
            observers.remove(at: index!)
        }
    }
    
    func removeAllObservers() {
        observers = []
    }
    
    func notifyObservers(_ notification: ObserverNotification) {
        for observer in observers {
            observer.notify(notification)
        }
    }
}
