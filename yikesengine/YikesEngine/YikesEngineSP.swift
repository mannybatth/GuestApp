//
//  YikesEngineSP.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/14/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel

import YKSSPLocationManager

open class YikesEngineSP : NSObject, GenericEngineProtocol, YKSSPLocationManagerDelegate {
    
    static public let sharedInstance = YikesEngineSP()
    
    fileprivate var isInitialized : Bool = false;
    open var requiresEULA : Bool = false;
    var bundleIdentifier : String {
        let bundle = Bundle(for:type(of: self))
        return bundle.bundleIdentifier ?? ""
    }
    
    open var changeEngineBeaconMode: ((YKSBeaconMode) -> Void)!
    open var engineBeaconMode: (() -> YKSBeaconMode)!
    open var shouldStartBLEActivity: ((YKSEngineArchitecture) -> Bool)!
    
    open var userInfo: YKSUserInfo? {
        
        if let user = YKSSessionManager.sharedInstance.currentUser {
            return user.userInfo
        }
        return nil
        
    }
    
    open var engineState : YKSEngineState = YKSEngineState.off {
        willSet(newValue) {
            
            if engineState != newValue {
                switch newValue {
                case .on:
                    yLog(LoggerLevel.info, category: LoggerCategory.System, message: "SP Engine state: ON")
                case .paused:
                    yLog(LoggerLevel.info, category: LoggerCategory.System, message: "SP Engine state: PAUSED")
                case .off:
                    yLog(LoggerLevel.info, category: LoggerCategory.System, message: "SP Engine state: OFF")
                }
            }
        }
        
        didSet {
            
            UserDefaults.standard.set(Int(engineState.rawValue), forKey: EngineConstants.engineStateKeySP)
            UserDefaults.standard.synchronize()
            
            DispatchQueue.main.async { () -> Void in
                self.delegate?.yikesEngineStateDidChange?(self.engineState)
            }
        }
    }
    
    open var bleEngineState: YKSBLEEngineState {
        return BLEEngine.sharedInstance.state
    }
    
    
    
    fileprivate var _currentApiEnv : YKSApiEnv = YKSApiEnv.envPROD {
        willSet(newValue) {
            
            if _currentApiEnv != newValue {
                yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "API env changed: \(newValue.stringValue)")
            }
        }
        
        didSet {
            
            UserDefaults.standard.set(Int(_currentApiEnv.rawValue), forKey: EngineConstants.currentApiEnvKey)
            UserDefaults.standard.synchronize()
        }
    }
    open var currentApiEnv: YKSApiEnv {
        return _currentApiEnv
    }
    
    public func currentApiEnvString() -> String {
        switch self.currentApiEnv {
        case .envDEV:
            return "DEV"
        case .envQA:
            return "QA"
        case .envPROD:
            return "PROD"
        }
    }
    
    open weak var delegate: YikesEngineDelegate?
    
    open var isInsideHotel: Bool {
        return self.locationState == .enteredSPHotel
    }
    
    open var locationState: YKSLocationState = .leftSPHotel
    
    open var currentLocationState: YKSLocationState {
        return YKSSPLocationManager.shared().currentSPLocationState
    }
    
    open static func sharedEngine() -> GenericEngineProtocol! {
        return YikesEngineSP.sharedInstance
    }
    
    fileprivate override init() {
        super.init()
        yLog(LoggerLevel.info, category: LoggerCategory.Engine, message: "Init SP Engine. Application state: \(UIApplication.shared.applicationState.rawValue)")
    }
    
    open class func initEngine(with yikesEngineDelegate: YikesEngineDelegate!) {
        
        YikesEngineSP.sharedInstance.delegate = yikesEngineDelegate
        
        if (YikesEngineSP.sharedInstance.isInitialized) { return }
        YikesEngineSP.sharedInstance.isInitialized = true
        
        // Initialize CentralManager (which will initialise rest of Managers - which will ensure notifications from them to update the engine state)
        
        DispatchQueue.main.async {
            // CLLocationManager needs to be initialized on the main run loop. iOS throws a warning otherwise:
            // "A location manager was created on a dispatch queue executing on a thread other than the main thread. It is the developer's responsibility to ensure that there is a run loop running on the thread on which the location manager object is allocated.  In particular, creating location managers in arbitrary dispatch queues (not attached to the main queue) is not supported and will result in callbacks not being received."
            _ = CentralManager.sharedInstance
        }
        
        // restore current api environment from user defaults
        let apiEnvRawValue = UserDefaults.standard.integer(forKey: EngineConstants.currentApiEnvKey)
        YikesEngineSP.sharedInstance._currentApiEnv = YKSApiEnv(rawValue: UInt(apiEnvRawValue))!
        
        StoreManager.sharedInstance.restoreCurrentUser()
        
        if let _ = YKSSessionManager.sharedInstance.currentUser {
            
            YikesEngineSP.sharedInstance.engineState = .on
            yLog(LoggerLevel.debug, category: LoggerCategory.Engine, message: "User found on Engine init. ApiEnv: \(YikesEngineSP.sharedInstance.currentApiEnv.stringValue)")
            
            YikesEngineSP.sharedInstance.refreshUserInfo(success: nil, failure: { error in
                yLog(LoggerLevel.debug, category: LoggerCategory.Engine, message: "Resuming engine on init..")
                
                
                // NOTE: Engine resuming should be handled by the host app
                YikesEngineSP.sharedInstance.resumeEngine()
                
                HTTPManager.sharedManager.beginBackgroundTask()
                HTTPManager.sharedManager.reloginInProgress = true
                
                User.loginWithKeychainCredentials({ user in
                    
                    yLog(LoggerLevel.debug, category: LoggerCategory.API, message: "LOGIN SUCCESS on engine init")
                    
                    HTTPManager.sharedManager.reloginInProgress = false
                    
                    YikesEngineSP.sharedInstance.refreshUserInfo(success:nil, failure: { error in
                        yLog(.debug, message: "User info is up-to-date")
                    })
                    
                }, failure: { error in
                    
                    yLog(message: "Failed to login with Keychain Credentials on init.")
                    
                    HTTPManager.sharedManager.reloginInProgress = false
                })
                
            })
            
        } else {
            
            YikesEngineSP.sharedInstance.engineState = .off
            yLog(LoggerLevel.debug, category: LoggerCategory.Engine, message: "User not found on Engine init.")
        }
    }
    
    open func checkIfLowPowerModeIsEnabled() {
        CentralManager.sharedInstance.checkIfLowPowerModeIsEnabled()
    }
    
    open func shouldDetermineLocationStateForAirplaneMode() -> Bool {
        if (MotionManager.sharedInstance.motionState != .didBecomeStationary &&
            BLEEngine.sharedInstance.centralManager.state == .poweredOn) {
            // We need to range for beacons if the BLE Engine is On (or Paused)
            // but the Engine is not Off and monitoring for the Global region failed:
            if (YikesEngineSP.sharedInstance.engineState != .off &&
                BLEEngine.sharedInstance.state == .off &&
                !YKSSPLocationManager.shared().isAlreadyMonitoring())
            {
                return true
            }
        }
        return false
    }
    
    open func checkCredentials() {
        CentralManager.sharedInstance.checkCredentials()
    }
    
    open func changeCurrentApiEnv(_ currentApiEnv: YKSApiEnv) -> Bool {
        
        if self.engineState != .off {
            yLog(LoggerLevel.error, category: LoggerCategory.Engine, message: "Engine is running, could not change environment to: \(currentApiEnv.stringValue).")
            return false
        }
        
        _currentApiEnv = currentApiEnv
        return true
    }
    
    func didStartMonitoring() {
        if self.engineState == .off {
            engineState = .paused
        }
    }
    
    open func startEngine(withUsername username: String!, password: String!, success successBlock: ((YKSUserInfo?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        self.startEngine(withUsername: username, password: password, requiresEULA: false, success: successBlock, failure: failureBlock)
    }
    
    open func startEngine(withUsername username: String!, password: String!, requiresEULA: Bool, success successBlock: ((YKSUserInfo?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        yLog(LoggerLevel.info, category: LoggerCategory.System, message: "STARTING SP engine - requires EULA is \(requiresEULA)")
        
        User.loginRetryingNumberOfTimes(1, username: username, password: password, success: { user in
            
            self.refreshUserInfo(success: { userInfo in
                
                yLog(LoggerLevel.debug, category: LoggerCategory.Engine, message: "Resuming engine after engine start..")
                
                if requiresEULA == true {
                    self.requiresEULA = true
                }
                
                self.resumeEngine()
                
                successBlock?(userInfo)
                
                FileLogger.sharedInstance.logMessage(LogMessage(level: LoggerLevel.info, category: LoggerCategory.API, timestamp: Date(), message: "### LOGIN Success ###", filePath: #file, functionName: #function, lineNumber: #line))
                FileLogger.sharedInstance.addHeaderDataToCurrentLogFile()
                
            }, failure: { error in
                
                yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Failed to start SP engine")
                failureBlock?(error)
            })
            
        }) { error in
            
            yLog(LoggerLevel.error, category: LoggerCategory.System, message: "Failed to start SP engine")
            failureBlock?(error)
        }
    }
    
    open func stopEngine(success successBlock: (() -> Void)!) {
        
        yLog(LoggerLevel.info, category: LoggerCategory.System, message: "STOPPING SP engine")
        
        if let email = YKSSessionManager.sharedInstance.currentUser?.email {
            if !DebugManager.sharedInstance.hasAccessToDebugLevel(email) {
                FileLogger.sharedInstance.rollLogFileNow()
            }
            else {
                yLog(message: "Not rolling log file for Debug user on stopEngineWithSuccess")
            }
        }
        else {
            FileLogger.sharedInstance.rollLogFileNow()
        }
        
        engineState = YKSEngineState.off
        
        self.stopEngineOperations()
        
        HTTPManager.sharedManager.cancelAllTasks()
        HTTPManager.sharedManager.requestsAwaitingRelogin.removeAll()
        HTTPManager.sharedManager.requestCallbacksAfterRelogin.removeAll()
        HTTPManager.sharedManager.reloginInProgress = false
        
        YKSSessionManager.sharedInstance.destroySession()
        StoreManager.sharedInstance.removeCurrentGuestCredentialsFromKeychains()
        
        User.logout {
            // Needed in case there were any pending requests that didnt get cancelled
            HTTPManager.sharedManager.requestsAwaitingRelogin.removeAll()
            HTTPManager.sharedManager.requestCallbacksAfterRelogin.removeAll()
            HTTPManager.sharedManager.reloginInProgress = false
        }
        
        // call successBlock immediately for faster logout response
        successBlock?()
    }
    
    fileprivate func stopEngineOperations() {
        
        yLog(LoggerLevel.info, category: LoggerCategory.System, message: "Stopping SP engine operations")
        
        YKSSPLocationManager.shared().stopMonitoringProcess()
        
        CentralManager.sharedInstance.unsubscribeFromObservables()
        
        BLEEngine.sharedInstance.stop()
    }
    
    open func bundleURL () -> URL? {
        let frameworkbundle = Bundle(for: type(of: self))
        return frameworkbundle.url(forResource: "com.yikesteam.YikesEngineSP", withExtension: "bundle")
    }
    
    open func requestLocationAlwaysAuthorization() {
        YKSSPLocationManager.shared().locationManager.requestAlwaysAuthorization()
    }
    
    open func pauseEngine() {
        
        yLog(LoggerLevel.info, category: LoggerCategory.System, message: "Pausing SP engine.")
        
        self.engineState = .paused
        BLEEngine.sharedInstance.stop()
    }
    
    open func userAcceptedEULA(_ username: String) {
        let user = YKSSessionManager.sharedInstance.currentUser
        if user != nil && user?.email == username {
            user?.eulaAccepted = true
//            self.resumeEngine()
        }
    }
    
    open func resumeEngine() {
        
        guard let userId = YKSSessionManager.sharedInstance.currentUser?.userId else {
            yLog(message: "No Current User found - stopping Engine")
            self.stopEngine(success: { 
                //
            })
            return
        }
        let eulaAcceptedAlready = UserDefaults.standard.bool(forKey:"EULAacceptedAlready_userid\(userId)");
        if self.requiresEULA && eulaAcceptedAlready == false  {
            yLog(.warning, category:.Engine, message: "EULA required and user has not yet accepted - canceling Engine Resume.")
            return
        }
        else {
            yLog(.info, category:.Engine, message: "EULA required and user has Accepted")
        }
        
        yLog(LoggerLevel.info, category: LoggerCategory.System, message: "Resuming SP engine")
        
        // Resume Engine:
        if (engineState == .off) {
            engineState = .paused
        }
        
        // Start if inside already:
        if self.isInsideHotel {
            engineState = YKSEngineState.on;
        }
        
        if YKSSessionManager.sharedInstance.currentUser != nil {
            
            CentralManager.sharedInstance.subscribeToObservables()
            
            YKSSPLocationManager.shared().hoteliBeaconUUID = YKSSessionManager.sharedInstance.currentUser?.beacon?.uuid
            YKSSPLocationManager.shared().hoteliBeaconIdentifier = EngineConstants.YIKES_SP_BEACON_IDENTIFIER
            YKSSPLocationManager.shared().startMonitoringProcess()
        }
        
    }
    
    
    open func userIsSignedIn() -> Bool {
        if let usernameAndPassword = StoreManager.sharedInstance.currentGuestUsernameAndPasswordFromKeychains() {
            if usernameAndPassword.guestPassword.characters.count > 0 {
                return true
            }
        }
        
        return false
    }
    
    
    open func currentGuestUsername() -> String {
        
        if let usernameAndPassword = StoreManager.sharedInstance.currentGuestUsernameAndPasswordFromKeychains() {
            return usernameAndPassword.guestUsername
        }
        
        return ""
    }
    
    
    open func currentPassword() -> String {
    
        if let usernameAndPassword = StoreManager.sharedInstance.currentGuestUsernameAndPasswordFromKeychains() {
            return usernameAndPassword.guestPassword
        }
        
        return ""
    }
    
    open func logMessage(_ message: String, level: YKSLoggerLevel) {
        // TODO: Use YKSLoggerLevel in yLog... they don't match. Using default value for now:
        yLog(.warning, category: LoggerCategory.App, message: message, isFatal: false)
    }
    
    // Mark: YKSSPLocationManagerDelegate
    public func didEnterBeaconRegion() {
        
        // Avoid dup entries:
        if locationState != .enteredSPHotel {
            
            locationState = .enteredSPHotel
            
            CentralManager.sharedInstance.fireLocalDebugNotification("Did ENTER SP Region")
            
            CentralManager.sharedInstance.checkCredentials()
            CentralManager.sharedInstance.currentLocationStateDidChange(YKSLocationState.enteredSPHotel)
            if let debugConsoleVC = DebugManager.sharedInstance.debugConsoleVCReference {
                debugConsoleVC.currentLocationStateDidChange(.enteredSPHotel)
            }
            
        }
        else {
            self.logMessage("Already Inside - NOT FIRING LOCAL DEBUG NOTIFICATION", level: YKSLoggerLevel.info)
        }
        
        // Calling start should only start if it's stopped:
        BLEEngine.sharedInstance.start()
    }
    
    public func didExitBeaconRegion() {
        
        if locationState != .leftSPHotel {
            
            locationState = .leftSPHotel
            
            if let locationStateBlock = YikesEngineSP.sharedInstance.delegate?.yikesEngineLocationStateDidChange {
                locationStateBlock(.leftSPHotel)
            }
            
            CentralManager.sharedInstance.fireLocalDebugNotification("Did EXIT SP Region")
            
            CentralManager.sharedInstance.checkCredentials()
            CentralManager.sharedInstance.currentLocationStateDidChange(.leftSPHotel)
            if let debugConsoleVC = DebugManager.sharedInstance.debugConsoleVCReference {
                debugConsoleVC.currentLocationStateDidChange(.leftSPHotel)
            }
        }
    }
    
    public func logLocationMessage(_ message: String!) {
        self.logMessage(message, level: YKSLoggerLevel.info)
    }
    
    public func notifyMissingServices() {
        ServicesManager.sharedInstance.notifyMissingServices()
    }
    

}

extension YikesEngineSP {
    
    public func requestBeaconState() {
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Requesting SP beacon state")

        YKSSPLocationManager.shared().requestState(true)
    }
    
    public func missingServices(_ completion: ((Set<AnyHashable>?) -> Void)!) {
        completion(ServicesManager.sharedInstance.missingServices)
    }
    
    public func handlePushNotificationMessage(_ message: String!, completionHandler: (() -> Void)!) {
        yLog(message: "[PN] Received a Remote Push Notification message - refreshing User Info...")
        completionHandler()
        self.refreshUserInfo(success: nil, failure: nil)
    }
    
    
    public func refreshUserInfo(failure failureBlock: ((YKSError?) -> Void)!) {
        
        refreshUserInfo(success: nil, failure: failureBlock)
    }
    
    
    public func refreshUserInfo(success successBlock: ((YKSUserInfo?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        CentralManager.sharedInstance.refreshUserInfoWithSuccess(successBlock, failure: failureBlock)
    }
    
    
    public func getUserStayShareRequests(
        success successBlock: (([YKSStayShareInfo]?) -> Void)!,
        failure failureBlock: ((YKSError?) -> Void)!) {
            
            CentralManager.sharedInstance.getUserStayShareRequestsWithSuccess(successBlock, failure: failureBlock)
    }
    
    
    public func sendStayShareRequest(
        forStayId stayId: NSNumber!,
        toEmail email: String!,
        success successBlock: ((YKSStayShareInfo?, YKSUserInviteInfo?) -> Void)!,
        failure failureBlock: ((YKSError?) -> Void)!) {
            
            CentralManager.sharedInstance.sendStayShareRequestForStayId(stayId, toEmail: email, success: successBlock, failure: failureBlock)
    }
    
    
    public func acceptStayShareRequest(_ stayShare: YKSStayShareInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        CentralManager.sharedInstance.acceptStayShareRequest(stayShare, success: successBlock, failure: failureBlock)
    }
    
    
    public func declineStayShareRequest(_ stayShare: YKSStayShareInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        CentralManager.sharedInstance.declineStayShareRequest(stayShare, success: successBlock, failure: failureBlock)
    }
    
    
    public func cancelStayShareRequest(_ stayShare: YKSStayShareInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        CentralManager.sharedInstance.cancelStayShareRequest(stayShare, success: successBlock, failure: failureBlock)
    }
    
    
    public func getUserInvites(success successBlock: (([YKSUserInviteInfo]?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        CentralManager.sharedInstance.getUserInvitesWithSuccess(successBlock, failure: failureBlock)
    }
    
    
    public func cancelUserInviteRequest(_ userInvite: YKSUserInviteInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        CentralManager.sharedInstance.cancelUserInviteRequest(userInvite, success: successBlock, failure: failureBlock)
    }
    
    
    public func getRecentContacts(success successBlock: (([YKSContactInfo]?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        CentralManager.sharedInstance.getRecentContactsWithSuccess(successBlock, failure: failureBlock)
    }
    
    
    public func removeRecentContact(_ contact: YKSContactInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        CentralManager.sharedInstance.removeRecentContact(contact, success: successBlock, failure: failureBlock)
    }
    
    
    public func checkIfEmailIsRegistered(_ email: String!, success successBlock: ((Bool) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        CentralManager.sharedInstance.checkIfEmailIsRegistered(email, success: successBlock, failure: failureBlock)
    }
    
    
    public func registerUser(withForm form: [String : Any]!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
//    public func registerUser(withForm form: [String : AnyObject]!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        CentralManager.sharedInstance.registerUserWithFormIfNotAlreadyRegistered(form as [String : AnyObject]!, success: successBlock, failure: failureBlock)
    }
    
    
    public func forgotPassword(forEmail email: String!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        CentralManager.sharedInstance.forgotPasswordForEmail(email, success: successBlock, failure: failureBlock)
    }
    
    public func updatePassword(forUserId userId: NSNumber!, oldPassword: String!, newPassword: String!, confNewPassword: String!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        let userIdInt = userId.intValue
        
        CentralManager.sharedInstance.updatePasswordForUserId(userIdInt, oldPassword: oldPassword, newPassword: newPassword, success: successBlock, failure: failureBlock)
    }
    
    public func updateUser(withForm form: [String : Any]!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        CentralManager.sharedInstance.updateUserWithForm(form as [String : AnyObject]!, success: successBlock, failure: failureBlock)
    }
    
    public func setBackgroundCompletionHandler(_ completionHandler: (() -> Void)!) {
        HTTPManager.sharedManager.setBackgroundCompletionHandler(handler: completionHandler)
    }
    
    public func debugInformation() -> Dictionary<AnyHashable, Any>? {
        if let user = YKSSessionManager.sharedInstance.currentUser {
            if let email = user.email, let userId = user.userId {
                return [
                    "User Email": email,
                    "UserId": String(userId),
                    "API env": YikesEngineSP.sharedInstance.currentApiEnvString()
                ]
            }
        }
        return nil
    }
    
    public func setDebugMode(_ on: Bool) {}

    @objc(showDebugViewInView:) public func showDebugView(in view: UIView!) {
        
        if let url = YikesEngineSP.sharedInstance.bundleURL() {
            if let spbundle = Bundle(url: url) {
                let storyboard = UIStoryboard(name: "DebugConsole", bundle: Bundle(url: spbundle.bundleURL))
                if let debugVC = storyboard.instantiateViewController(withIdentifier: "DebugConsoleVC") as? DebugConsoleVC {
                    debugVC.showInView(view)
                }
            }
        }
    }
    
    public func handleDebugToolsLogin() {}
    public func handleDebugToolsLogout() {}
}
