//
//  CentralManager.swift
//  YikesEngine
//
//  Created by Alexandar Dimitrov on 2016-01-14.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import YKSSPLocationManager

import SafariServices

class CentralManager: NSObject, Observer {
    
    static let sharedInstance = CentralManager()
    
    var alertC : UIAlertController?
    
    var refreshingUserStays = false
    
    override fileprivate init() {
        super.init()
        
        _ = YKSSPLocationManager.shared()
        _ = MotionManager.sharedInstance
        _ = ServicesManager.sharedInstance
        
        NotificationCenter.default.addObserver(self,
             selector: #selector(CentralManager.appWillEnterForegroundNotification(_:)),
             name: NSNotification.Name.UIApplicationWillEnterForeground,
             object: nil)
        
        NotificationCenter.default.addObserver(self,
             selector: #selector(CentralManager.appDidEnterBackgroundNotification(_:)),
             name: NSNotification.Name.UIApplicationDidEnterBackground,
             object: nil)
        
        NotificationCenter.default.addObserver(self,
             selector: #selector(CentralManager.appDidFinishLaunchingNotification(_:)),
             name: NSNotification.Name.UIApplicationDidFinishLaunching,
             object: nil)
        
        NotificationCenter.default.addObserver(self,
             selector: #selector(CentralManager.appDidBecomeActiveNotification(_:)),
             name: NSNotification.Name.UIApplicationDidBecomeActive,
             object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(CentralManager.appWillTerminate(_:)),
            name: NSNotification.Name.UIApplicationWillTerminate,
            object: nil)
        
        // Swift
        NotificationCenter.default.addObserver(self,
             selector: #selector(didChangePowerMode(notification:)),
             name: NSNotification.Name.NSProcessInfoPowerStateDidChange,
             object: nil)
        
    }
    
    deinit {
        unsubscribeFromObservables()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidFinishLaunching, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name.UIApplicationWillTerminate, object: nil)
    }
    
    func subscribeToObservables() {
        // Note: Location Manager is now using the delegate to call the CentralManager via the YikesEngineSP.sharedInstance
        StoreManager.sharedInstance.addObserver(self)
        MotionManager.sharedInstance.addObserver(self)
        ServicesManager.sharedInstance.addObserver(self)
        BLEEngine.sharedInstance.addObserver(self)
    }
    
    func unsubscribeFromObservables() {
        StoreManager.sharedInstance.removeObserver(self)
        MotionManager.sharedInstance.removeObserver(self)
        ServicesManager.sharedInstance.removeObserver(self)
        BLEEngine.sharedInstance.addObserver(self)
    }
    
    
    func switchToMP() {
       YikesEngineSP.sharedEngine().changeEngineBeaconMode?(YKSBeaconMode.yksmpForced)
    }
    
    func switchToSP() {
        YikesEngineSP.sharedEngine().changeEngineBeaconMode?(YKSBeaconMode.yksspForced)
    }
    
    func switchToBeaconBasedEngine() {
       YikesEngineSP.sharedEngine().changeEngineBeaconMode?(YKSBeaconMode.yksBeaconBased)
    }
    
    func isBeaconEnabled() -> Bool {
        if YikesEngineSP.sharedInstance.engineBeaconMode != nil {
            return YikesEngineSP.sharedInstance.engineBeaconMode() == YKSBeaconMode.yksBeaconBased
        }
        return false
        
    }
    
    func notify(_ notification: ObserverNotification) {
        switch notification.observableEvent {
            
        case .didBecomeActive:
            didBecomeActive()
            
        case .DeviceBecameStationary:
            deviceBecameStationary()
            
        case .LocationStateDidChange:
            if let state = notification.data as? YKSLocationState {
                currentLocationStateDidChange(state)
            }
            
        case .MissingServicesDidChange:
            if let missingServices = notification.data as? Set<NSNumber> {
                engineIsMissingServices(missingServices)
            }
            
        case .BLEEngineStartScanning: break
        case .BLEEngineStopScanning:
            DebugManager.sharedInstance.endAllConnections(BLEConnection.ConnectionEndReason.EngineStopped)
            break
            
        case .StoreManagerStaysAltered:
            break
        
        case .StoreManagerStaysRemoved:
            break
            
        case .YLinksAdded:
            if let addedYLinks = notification.data as? Set<YLink> {
                BLEEngine.sharedInstance.addYLinks(addedYLinks)
            }
            
        case .YLinksRemoved:
            if let removedYLinks = notification.data as? Set<YLink> {
                BLEEngine.sharedInstance.removeYLinks(removedYLinks)
            }
            
        case .UnassignedRoom:
            
            if let roomNumber = notification.data as? String {
                DispatchQueue.main.async {
                    YikesEngineSP.sharedEngine().delegate?.yikesEngineRoomConnectionStatusDidChange?(YKSConnectionStatus.disconnectedFromDoor, withRoom: roomNumber)
                }
            }
            
            
            
        default:
            break
        }
    }
    
    func appWillEnterForegroundNotification(_ notification: Notification) {
        
        yLog(LoggerLevel.debug, category: LoggerCategory.Engine, message: "App will enter FOREGROUND.")
        
        if YikesEngineSP.sharedEngine().engineState != .off {
            self.refreshUserInfoWithSuccess(nil, failure: {
                error in
                
                self.stopEngineAndLogOutWithInvalidCredentials(error!)
            })
            
            ServicesManager.sharedInstance.notifyMissingServices()
            
            self.checkIfLowPowerModeIsEnabled()
        }
    }
    
    func appDidEnterBackgroundNotification(_ notification: Notification) {
        
        if YikesEngineSP.sharedInstance.engineState == .off {
            yLog(message: "Engine state off - not forwarding appDidEnterBackgroundNotification")
            return
        }
        
        yLog(LoggerLevel.debug, category: LoggerCategory.Engine, message: "App did enter BACKGROUND.")
        StoreManager.sharedInstance.saveCurrentUser()
        BLEEngine.sharedInstance.restartScan()
        
    }
    
    func appDidFinishLaunchingNotification(_ notification: Notification) {
        
        yLog(LoggerLevel.debug, category: LoggerCategory.Engine, message: "App did finish LAUNCHING.")
        
    }
    
    func appDidBecomeActiveNotification(_ notification: Notification) {
        
        yLog(LoggerLevel.debug, category: LoggerCategory.Engine, message: "App did become ACTIVE.")
        
        // in case AirPlane mode was On, monitoring had failed, so we need to retry from time to time. This seems like a good place to do it:
        if YikesEngineSP.sharedInstance.engineState  == .on {
            //TODO: Request Authorization Status then wait for the callback to start monitoring:
            YKSSPLocationManager.shared().startMonitoringProcess()
            self.checkIfLowPowerModeIsEnabled()
        }
    }
    
    func appWillTerminate(_ notification:Notification) {
        yLog(LoggerLevel.debug, category: LoggerCategory.Engine, message: "App will TERMINATE.")
    }
    
}


extension CentralManager {
    
    func didChangePowerMode(notification: NSNotification) {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            self.lowPowerModeIsEnabled()
        }
        else {
            self.refreshUserInfoWithSuccess({ (userInfo) in
                yLog(message: "Successfully refreshed User info and stays after disabling Low Power Mode: \(userInfo)")
            }, failure: { (error) in
                
            })
        }
    }
    
    func checkIfLowPowerModeIsEnabled() {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            self.lowPowerModeIsEnabled()
        }
        else {
            if let alertC = self.alertC {
                if self.isAlreadyPresentingAlert(alertC) {
                    self.alertC?.dismiss(animated: false, completion: nil)
                }
            }
        }
    }
    
    func lowPowerModeIsEnabled() {
        self.informUser("Note about Low Power mode", message:"yikes is now reducing activity to conserve battery. You will need to open the app to unlock doors.")
        let error = YKSError.newWith(YKSErrorCode.engineLowPowerModeEnabled, errorDescription: "Low Power Mode was enabled and user has been informed.")
        error?.eventName = "Low Power Mode ON"
        if let user = YKSSessionManager.sharedInstance.currentUser {
            if let email = user.email, let userId = user.userId {
                error?.eventCustomAttributes = [
                    "User email": email,
                    "UserId": userId,
                    "API env": YikesEngineSP.sharedInstance.currentApiEnvString()
                ]
                error?.logEventOnCrashlytics = true
            }
        }
        yLog(.debug, message: "custom attributes for CLS Event:\n\(error?.eventCustomAttributes)")
        if let block = YikesEngineSP.sharedInstance.delegate?.yikesEngineErrorDidOccur {
            block(error)
        }
    }
    
    func fireLocalDebugNotification (_ message:String) {
//#if DEBUG
        
        if let email = YKSSessionManager.sharedInstance.currentUser?.email {
            if DebugManager.sharedInstance.hasAccessToDebugLevel(email) ||
                email == "benr@yikes.co" {
                let localNotif = UILocalNotification()
                localNotif.alertBody = String("\(message)");
                localNotif.alertAction = NSLocalizedString("Relaunch", comment: "Relaunch")
                localNotif.soundName = UILocalNotificationDefaultSoundName;
                UIApplication.shared.presentLocalNotificationNow(localNotif)
            }
        }
        
//#endif
    }
    
    func informUser (_ title:String = "Important information", message:String) {
        if UIApplication.shared.applicationState == .background {
            let localNotif = UILocalNotification()
            localNotif.alertTitle = title
            localNotif.alertBody = String("\(message)");
            localNotif.alertAction = NSLocalizedString("Relaunch", comment: "Relaunch")
            localNotif.soundName = UILocalNotificationDefaultSoundName;
            UIApplication.shared.presentLocalNotificationNow(localNotif)
        }
        else {
            if self.isAlreadyPresentingAlert(self.alertC) {
                yLog(message: "Already presenting Low Power Mode alert.")
            }
            else {
                
                if self.alertC == nil {
                    let alertC = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                    alertC.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: { (action) in
                        alertC.dismiss(animated: true, completion: nil)
                    }))
                    self.alertC = alertC
                }
                if let alertC = self.alertC {
                    UIApplication.shared.keyWindow?.rootViewController?.present(alertC, animated: true, completion:nil)
                }
            }
        }
    }
    
    func isAlreadyPresentingAlert(_ alertC:UIAlertController?) -> Bool {
        if let alert = alertC {
            if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
                let presentedVC = rootVC.presentedViewController
                if ((presentedVC != nil  && presentedVC == self.alertC) || presentedVC is SFSafariViewController) {
                    return true
                }
            }
            return false
        }
        else {
            return false
        }
    }
    
    func refreshUserInfoWithSuccess(_ successBlock: ((YKSUserInfo?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        guard let currentUser = YKSSessionManager.sharedInstance.currentUser,
            let userId = currentUser.userId
            else {
                failureBlock?(YKSError.newWith(YKSErrorCode.unknown, errorDescription: "Missing currentUser or userId"))
                return
        }
        
        self.refreshingUserStays = true
        
        User.getUserAndStaysRetryingNumberOfTimes(2, userId: userId, success: { newUser in
            
            self.refreshingUserStays = false
            
            StayShare.getStayShares(userId, success: { (stayShares) -> Void in
                
                let userInfo = YKSSessionManager.sharedInstance.currentUser?.userInfo
                
                yLog(LoggerLevel.info, category: LoggerCategory.System, message: "\(userInfo)")
                successBlock?(userInfo)
                
                DispatchQueue.main.async {
                    YikesEngineSP.sharedInstance.delegate?.yikesEngineUserInfoDidUpdate?(userInfo)
                }
                
            }, failure: { (error) -> Void in
                    
                failureBlock?(error)
            })
            
        }) { (error) -> Void in
            
            self.refreshingUserStays = false
            
            self.stopEngineAndLogOutWithInvalidCredentials(error)
            
            failureBlock?(error)
        }
    }
    
    func refreshCredentialsForStayInfo(_ stayInfo: YKSStayInfo) {
        
        if let stay = YKSSessionManager.sharedInstance.currentUser?.stays.filter({ $0.stayId == stayInfo.stayId.intValue }).first {
            self.refreshCredentialsForStay(stay)
        }
    }
    
    func refreshCredentialsForStay(_ stay: Stay) {
        
        if self.refreshingUserStays == true || stay.refreshingCredentials {
            yLog(.debug, category: .API, message: "Skipping refreshCredentialsForStay \(stay.roomNumber) - already refreshing")
            return
        }
        else {
            if let goodUntil = stay.credential?.goodUntilDate() {
                let secondsLeft = goodUntil.timeIntervalSinceNow
                yLog(.info, category: .API, message: String(format:"Refreshing Credentials For Stay \(stay.roomNumber) - %.2f seconds left for main room", secondsLeft))
            }
        }
        
        if let stayId = stay.stayId, let userId = stay.userId {
            
            stay.refreshingCredentials = true
            
            User.getUserStay(stayId, userId: userId, success:
            {(updatedStay) in
                
                updatedStay.refreshingCredentials = false
                
//                YKSSessionManager.sharedInstance.currentUser
                
                #if DEBUG
//                    self.fireLocalNotification("Refreshed credentials for \(updatedStay.roomNumber)\nGood for \(updatedStay.credentialLifeSpan()) seconds")
                #endif
                yLog(.info, category: .API, message: "Successfully refreshed credentials for \(updatedStay):\n\(updatedStay.credential)")
                
                // Make sure we are scanning for the most up to date yLinks:
                BLEEngine.sharedInstance.start()
                
                DispatchQueue.main.async {
                    let userInfo = YKSSessionManager.sharedInstance.currentUser?.userInfo
                    YikesEngineSP.sharedInstance.delegate?.yikesEngineUserInfoDidUpdate?(userInfo)
                }
                
            }) { (error) in
                
                stay.refreshingCredentials = false
                
                #if DEBUG
                    self.fireLocalDebugNotification("FAILED to refresh credentials for \(stay.roomNumber)\nError: \(error)")
                #endif
                
                yLog(.error, category: .API, message: "Error refreshing credentials for room \(stay.roomNumber):\n\(error)")
                
                if
                    stay.credentialsExpired()
                        && YikesEngineSP.sharedInstance.isInsideHotel
                        && !ServicesManager.sharedInstance.isReachable()
                {
                    #if DEBUG
                        self.fireLocalDebugNotification("CRITICAL: Credentials have expired and could NOT be refreshed while INSIDE SP Hotel!\nRoom \(stay.roomNumber)")
                    #endif
                    yLog(.critical, category: .API, message: "Could not refresh expired credentials while on site. Internet seems unreachable.")
                }
                
                self.stopEngineAndLogOutWithInvalidCredentials(error)
            }
        }
    }
    
    /**
     For each stay: this will first determine if the credentials are about to expire and if so, will refresh.
     */
    func checkCredentials () {
        if let stays = YKSSessionManager.sharedInstance.currentUser?.stays {
            for stay in stays {
                self.checkCredentialsForStay(stay)
            }
        }
        else {
            #if DEBUG
            self.fireLocalDebugNotification("No user stays...")
            #endif
        }
    }
    
    func checkCredentialsForConnection(_ connection:BLEConnection) {
        if let credentials = connection.yLink.credential {
            if credentials.credentialsExpireSoon() {
                self.refreshCredentialsForStay(connection.yLink.stay)
            }
        }
    }
    
    /**
     This will first determine if the credentials are about to expire and if so, will refresh for the specified stay.
     */
    func checkCredentialsForStay(_ stay:Stay) {
        if stay.credentialsExpireSoon() {
            self.refreshCredentialsForStay(stay)
        }
        else {
            if let goodUntil = stay.credential?.goodUntilDate() {
                let secondsLeft = goodUntil.timeIntervalSinceNow
                if stay.credentialsAboutToExpire() {
                    self.refreshCredentialsForStay(stay)
                }
                yLog(message: String(format:"Credentials for \(stay.roomNumber) still good for %.2f seconds", secondsLeft))
            }
        }
    }
    
    func getUserStayShareRequestsWithSuccess(_ successBlock: (([YKSStayShareInfo]?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.getUserStayShareRequestsWithSuccess(successBlock, failure: failureBlock)
    }
    
    func sendStayShareRequestForStayId(_ stayId: NSNumber!, toEmail email: String!, success successBlock: ((YKSStayShareInfo?, YKSUserInviteInfo?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.sendStayShareRequestForStayId(stayId, toEmail: email, success: successBlock, failure: failureBlock)
    }
    
    func acceptStayShareRequest(_ stayShare: YKSStayShareInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.acceptStayShareRequest(stayShare, success: successBlock, failure: failureBlock)
    }
    
    func declineStayShareRequest(_ stayShare: YKSStayShareInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.declineStayShareRequest(stayShare, success: successBlock, failure: failureBlock)
    }
    
    func cancelStayShareRequest(_ stayShare: YKSStayShareInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.cancelStayShareRequest(stayShare, success: successBlock, failure: failureBlock)
    }
    
    func getUserInvitesWithSuccess(_ successBlock: (([YKSUserInviteInfo]?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.getUserInvitesWithSuccess(successBlock, failure: failureBlock)
    }
    
    func cancelUserInviteRequest(_ userInvite: YKSUserInviteInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.cancelUserInviteRequest(userInvite, success: successBlock, failure: failureBlock)
    }
    
    func getRecentContactsWithSuccess(_ successBlock: (([YKSContactInfo]?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.getRecentContactsWithSuccess(successBlock, failure: failureBlock)
    }
    
    func removeRecentContact(_ contact: YKSContactInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.removeRecentContact(contact, success: successBlock, failure: failureBlock)
    }
    
    func checkIfEmailIsRegistered(_ email: String!, success successBlock: ((Bool) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.checkIfEmailIsRegistered(email, successBlock: successBlock, failure: failureBlock)
    }
    
    func registerUserWithFormIfNotAlreadyRegistered(_ form: [String : AnyObject]!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.registerUserWithFormIfNotAlreadyRegistered(form, success: successBlock, failure: failureBlock)
    }
    
    func forgotPasswordForEmail(_ email: String!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.forgotPasswordForEmail(email, success: successBlock, failure: failureBlock)
    }
    
    func updatePasswordForUserId(_ userId: Int, oldPassword: String!, newPassword: String!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.updatePasswordForUserId(userId, oldPassword: oldPassword, newPassword: newPassword, success: successBlock, failure: failureBlock)
    }
    
    func updateUserWithForm(_ form: [String : AnyObject]!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        guard let currentUser = YKSSessionManager.sharedInstance.currentUser,
            let userId = currentUser.userId
            else { return }
        
        User.updateUserWithForm(form, success: { () -> Void in
            
            User.getUserAndStaysRetryingNumberOfTimes(2, userId: userId, success: { (user) -> Void in
                
                let userInfo = YKSSessionManager.sharedInstance.currentUser?.userInfo
                
                successBlock?()
                
                DispatchQueue.main.async {
                    YikesEngineSP.sharedInstance.delegate?.yikesEngineUserInfoDidUpdate?(userInfo)
                }
                
            }, failure: failureBlock)
            
        }, failure: failureBlock)
    }
    
}

extension CentralManager {
    
    func currentLocationStateDidChange(_ state: YKSLocationState) {
        
        yLog(LoggerLevel.debug, category: LoggerCategory.Engine, message: "Did receive LocationStateDidChange via observer, state: \(state.rawValue)")
        
        DispatchQueue.main.async {
            if let delegate = YikesEngineSP.sharedInstance.delegate {
                delegate.yikesEngineLocationStateDidChange?(state)
            }
            else {
                yLog(LoggerLevel.critical, category: LoggerCategory.Engine, message: "Missing yikesEngineDelegate reference in CentralManager!")
            }
        }
        
        if (state == .enteredSPHotel) {
            
            YikesEngineSP.sharedInstance.engineState = .on
            // Start BLE Engine - will request permission to Engine Controller
            BLEEngine.sharedInstance.start()
            
        } else if (state == .leftSPHotel) {
            
            YikesEngineSP.sharedInstance.engineState = .paused
            // handle SP operations for region exit
            BLEEngine.sharedInstance.stop()
        }
    }
    
    func engineIsMissingServices(_ missingServices: Set<NSNumber>) {
        
        DispatchQueue.main.async {
            YikesEngineSP.sharedInstance.delegate?.yikesEngineRequiredServicesMissing?(missingServices)
        }
    }
    
    func didBecomeActive() {
        
        yLog(LoggerLevel.info, category: LoggerCategory.Device, message: "Device has moved, no longer stationary")
        
        BLEEngine.sharedInstance.start()
        
        DispatchQueue.main.async {
            YikesEngineSP.sharedInstance.delegate?.yikesEngineDeviceMotionStateDidChange?(.isMoving)
        }
    }
    
    func deviceBecameStationary() {
        
        yLog(LoggerLevel.info, category: LoggerCategory.Device, message: "Device is stationary")

        BLEEngine.sharedInstance.stop(.stationary)
        DebugManager.sharedInstance.endAllConnections(BLEConnection.ConnectionEndReason.Stationary)
        
        DispatchQueue.main.async {
            YikesEngineSP.sharedInstance.delegate?.yikesEngineDeviceMotionStateDidChange?(.didBecomeStationary)
        }
    }
    
    
    func stopEngineAndLogOutWithInvalidCredentials(_ error: YKSError) {
        if error.errorCode == .userNotAuthorized {
            DispatchQueue.main.async {
                
                if YikesEngineSP.sharedInstance.engineState != .off {
                    YikesEngineSP.sharedInstance.stopEngine(success: nil)
                }
                
                YikesEngineSP.sharedInstance.delegate?.yikesEngineErrorDidOccur!(YKSError.newWith(.invalidCredentials, errorDescription: kYKSErrorInvalidCredentialsDescription))
            }
        }
    }
    
}
