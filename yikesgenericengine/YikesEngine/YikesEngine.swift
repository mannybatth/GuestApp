//
//  YikesEngine.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/13/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import YikesEngineSP
import YikesEngineMP


public class YikesEngine: NSObject, GenericEngineProtocol {
    
    open static let sharedInstance = YikesEngine()
    
    weak public var delegate: YikesEngineDelegate?
    
    public static func sharedEngine() -> GenericEngineProtocol? {
        if YikesEngine.sharedInstance.delegate == nil {
            print("Error: YikesEngine delegate is nil!")
            return nil
        }
        return EngineController.sharedInstance.sharedEngine()
    }
    
    private override init() {
        super.init()
    }
    
    private func isSPAvailable() -> Bool {
        return EngineController.sharedInstance.isSPAvailable()
    }
    
    private func isMPAvailable() -> Bool {
        return EngineController.sharedInstance.isMPAvailable()
    }
    
    // Engine
    public class func initEngine(with yikesEngineDelegate: YikesEngineDelegate) {
        YikesEngine.sharedInstance.delegate = yikesEngineDelegate
        if YikesEngine.sharedInstance.isSPAvailable() {
            YikesEngineSP.initEngine(with: EngineController.sharedInstance)
        }
        if YikesEngine.sharedInstance.isMPAvailable() {
            YikesEngineMP.initEngine(with: EngineController.sharedInstance)
        }
    }
    
    public func checkIfLowPowerModeIsEnabled() {
        EngineController.sharedInstance.sharedEngine()?.checkIfLowPowerModeIsEnabled()
    }
    
    public func startEngine(withUsername username: String!, password: String!, success successBlock: ((YKSUserInfo?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        self.startEngine(withUsername: username, password: password, requiresEULA: false, success: successBlock, failure: failureBlock)
    }
    
    public func startEngine(withUsername username: String!, password: String!, requiresEULA: Bool, success successBlock: ((YKSUserInfo?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        if let spEngine = EngineController.sharedInstance.singlePathEngine {
            spEngine.startEngine(withUsername: username, password: password, success: { (userInfo) in
                
                EngineController.sharedInstance.multiPathEngine?.startEngine(withUsername: username, password: password, requiresEULA:requiresEULA, success: successBlock, failure: failureBlock)
            }, failure: { (error) in
                failureBlock(error)
            })
        }
            // Only MP Engine is active:
        else {
            EngineController.sharedInstance.multiPathEngine?.startEngine(withUsername: username, password: password, requiresEULA:requiresEULA, success: successBlock, failure: failureBlock)
        }
    }

    public func userAcceptedEULA(_ username: String) {
        if isSPAvailable() {
            YikesEngineSP.sharedEngine().userAcceptedEULA(username)
        }
        if isMPAvailable() {
            YikesEngineMP.sharedEngine().userAcceptedEULA(username)
        }
    }
    
    public func stopEngine(success successBlock: (() -> Void)!) {
        if let spEngine = EngineController.sharedInstance.singlePathEngine, let mpEngine = EngineController.sharedInstance.multiPathEngine {
            spEngine.stopEngine(success: {})
            mpEngine.stopEngine(success: successBlock)
        }
        else if let spEngine = EngineController.sharedInstance.singlePathEngine {
            spEngine.stopEngine(success: successBlock)
        }
        else if let mpEngine = EngineController.sharedInstance.multiPathEngine {
            mpEngine.stopEngine(success: successBlock)
        }
        else {
            self.logMessage("No Engine found - Cannot Stop", level: YKSLoggerLevel.error)
        }
    }
    
    public func debugInformation() -> Dictionary<AnyHashable, Any>? {
        return EngineController.sharedInstance.sharedEngine()?.debugInformation()
    }
    
    public func requestLocationAlwaysAuthorization() {
        EngineController.sharedInstance.singlePathEngine?.requestLocationAlwaysAuthorization()
        EngineController.sharedInstance.multiPathEngine?.requestLocationAlwaysAuthorization()
    }
    
    public func pauseEngine() {
        EngineController.sharedInstance.singlePathEngine?.pauseEngine()
        EngineController.sharedInstance.multiPathEngine?.pauseEngine()
    }
    
    public func resumeEngine() {
        EngineController.sharedInstance.singlePathEngine?.resumeEngine()
        EngineController.sharedInstance.multiPathEngine?.resumeEngine()
    }
    
    //MARK: GenericEngineProtocol
    public var currentApiEnv: YKSApiEnv {
        if let sharedEngine = EngineController.sharedInstance.sharedEngine() {
            return sharedEngine.currentApiEnv
        }
        else {
            return .envPROD
        }
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
    
    public var engineState: YKSEngineState {
        if let engine = EngineController.sharedInstance.sharedEngine() {
            return engine.engineState
        }
        else {
            return .off
        }
    }
    
    public var bleEngineState: YKSBLEEngineState {
        if let engine = EngineController.sharedInstance.sharedEngine() {
            return engine.bleEngineState
        }
        else {
            return .off
        }
    }
    
    public var userInfo: YKSUserInfo? {
        return EngineController.sharedInstance.sharedEngine()?.userInfo
    }
    
    public func userIsSignedIn() -> Bool {
        if let engine = EngineController.sharedInstance.sharedEngine() {
            return engine.userIsSignedIn()
        }
        else {
            return false
        }
    }
    
    public var isInsideHotel: Bool {
        if let engine = EngineController.sharedInstance.sharedEngine() {
            return engine.isInsideHotel
        }
        else {
            return false
        }
    }
    
    public var currentLocationState: YKSLocationState {
        if let engine = EngineController.sharedInstance.sharedEngine() {
            return engine.currentLocationState
        }
        else {
            return .unknown
        }
    }
    
    // API Env
    public func changeCurrentApiEnv(_ currentApiEnv: YKSApiEnv) -> Bool {
        var changed:Bool = false
        if let spEngine = EngineController.sharedInstance.singlePathEngine {
            changed = spEngine.changeCurrentApiEnv(currentApiEnv)
        }
        if let mpEngine = EngineController.sharedInstance.multiPathEngine {
            changed = changed && mpEngine.changeCurrentApiEnv(currentApiEnv)
        }
        return changed
    }
    
    // Credentials
    public func currentGuestUsername() -> String? {
        return EngineController.sharedInstance.sharedEngine()?.currentGuestUsername()
    }
    
    public func currentPassword() -> String? {
        return EngineController.sharedInstance.sharedEngine()?.currentPassword()
    }
    
    // API
    public func refreshUserInfo(failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.refreshUserInfo(failure: failureBlock)
    }
    
    public func refreshUserInfo(success successBlock: ((YKSUserInfo?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.refreshUserInfo(success: successBlock, failure: failureBlock)
    }
    
    public func getUserStayShareRequests(success successBlock: (([YKSStayShareInfo]?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.getUserStayShareRequests(success: successBlock, failure: failureBlock)
    }
    
    public func sendStayShareRequest(forStayId stayId: NSNumber!, toEmail email: String!, success successBlock: ((YKSStayShareInfo?, YKSUserInviteInfo?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.sendStayShareRequest(forStayId: stayId, toEmail: email, success: successBlock, failure: failureBlock)
    }
    
    public func acceptStayShareRequest(_ stayShare: YKSStayShareInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.acceptStayShareRequest(stayShare, success: successBlock, failure: failureBlock)
    }
    
    public func declineStayShareRequest(_ stayShare: YKSStayShareInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.declineStayShareRequest(stayShare, success: successBlock, failure: failureBlock)
    }
    
    public func cancelStayShareRequest(_ stayShare: YKSStayShareInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.cancelStayShareRequest(stayShare, success: successBlock, failure: failureBlock)
    }
    
    public func getUserInvites(success successBlock: (([YKSUserInviteInfo]?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.getUserInvites(success: successBlock, failure: failureBlock)
    }
    
    public func cancelUserInviteRequest(_ userInvite: YKSUserInviteInfo, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.cancelUserInviteRequest(userInvite, success: successBlock, failure: failureBlock)
    }
    
    public func getRecentContacts(success successBlock: (([YKSContactInfo]?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.getRecentContacts(success: successBlock, failure: failureBlock)
    }
    
    public func removeRecentContact(_ contact: YKSContactInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.removeRecentContact(contact, success: successBlock, failure: failureBlock)
    }
    
    //TODO: Should probably be sent to both engines:
    public func handlePushNotificationMessage(message: String!) {
        EngineController.sharedInstance.sharedEngine()?.handlePushNotificationMessage(message, completionHandler: {})
    }
    
    public func handlePushNotificationMessage(_ message: String!, completionHandler: (() -> Void)!) {
        if self.isMPAvailable() {
            EngineController.sharedInstance.multiPathEngine?.handlePushNotificationMessage(message, completionHandler: nil)
        }
        if self.isSPAvailable() {
            EngineController.sharedInstance.singlePathEngine?.handlePushNotificationMessage(message, completionHandler: nil)
        }
    }
    
    public func checkIfEmailIsRegistered(_ email: String!, success successBlock: ((Bool) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.checkIfEmailIsRegistered(email, success: successBlock, failure: failureBlock)
    }
    
    public func registerUser(withForm form: [String : Any]!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.registerUser(withForm: form, success: successBlock, failure: failureBlock)
    }
    
    public func updatePassword(forUserId userId: NSNumber!, oldPassword: String!, newPassword: String!, confNewPassword: String!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        // updatePasswordForUserId is only implemented in Single Path engine
        EngineController.sharedInstance.singlePathEngine?.updatePassword(forUserId: userId, oldPassword: oldPassword, newPassword: newPassword, confNewPassword: confNewPassword, success: successBlock, failure: failureBlock)
    }
    
    public func forgotPassword(forEmail email: String!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.forgotPassword(forEmail: email, success: successBlock, failure: failureBlock)
    }
    
    public func updateUser(withForm form: [String : Any]!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.updateUser(withForm: form, success: successBlock, failure: failureBlock)
    }
    
    public func setBackgroundCompletionHandler(_ completionHandler: (() -> Void)!) {
        EngineController.sharedInstance.singlePathEngine?.setBackgroundCompletionHandler(completionHandler)
        EngineController.sharedInstance.multiPathEngine?.setBackgroundCompletionHandler(completionHandler)
    }
    
    public func missingServices(_ completion: ((Set<AnyHashable>?) -> Void)!) {
        EngineController.sharedInstance.sharedEngine()?.missingServices(completion)
    }
    
    // Debuging
    public func setDebugMode(_ on: Bool) {
        EngineController.sharedInstance.multiPathEngine?.setDebugMode(on)
        EngineController.sharedInstance.singlePathEngine?.setDebugMode(on)
    }
    
    public func showDebugView(in view: UIView!) {
        EngineController.sharedInstance.sharedEngine()?.showDebugView(in: view)
    }
    
    public func handleDebugToolsLogin() {
        EngineController.sharedInstance.sharedEngine()?.handleDebugToolsLogin()
    }
    
    public func handleDebugToolsLogout() {
        EngineController.sharedInstance.sharedEngine()?.handleDebugToolsLogout()
    }
    
    public func logMessage(_ message: String!) {
        EngineController.sharedInstance.singlePathEngine?.logMessage(message, level: .info)
        EngineController.sharedInstance.multiPathEngine?.logMessage(message, level: .info)
    }
    
    public func logMessage(_ message: String!, level: YKSLoggerLevel) {
        // Log to both engines:
        EngineController.sharedInstance.singlePathEngine?.logMessage(message, level: level)
        EngineController.sharedInstance.multiPathEngine?.logMessage(message, level: level)
    }
    
}

//MARK: Engine Controller - private
private class EngineController: NSObject, YikesEngineDelegate {
    
    static let sharedInstance = EngineController()
    
    var singlePathEngine: YikesEngineSP?
    var multiPathEngine: YikesEngineMP?
    
    var currentSPState: YKSLocationState = .unknown
    var currentMPState: YKSLocationState = .unknown
    
    
    var beaconMode: YKSBeaconMode {
        get {
            return YKSBeaconMode(rawValue: UInt(UserDefaults.standard.integer(forKey: EngineConstants.beaconModeKey)))!
        }
        set {
            UserDefaults.standard.set(Int(newValue.rawValue), forKey: EngineConstants.beaconModeKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    
    var currentArchitecture: YKSEngineArchitecture = YKSEngineArchitecture.singlePath {
        didSet {
            print("Just set to current Architecture \(EngineController.sharedInstance.currentArchitecture.stringValue)")
            UserDefaults.standard.set(Int(EngineController.sharedInstance.currentArchitecture.rawValue), forKey: EngineConstants.architectureKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    
    private override init() {
        
        super.init()
        
        currentArchitecture = YKSEngineArchitecture(rawValue: UInt(UserDefaults.standard.integer(forKey:EngineConstants.architectureKey)))!
        
        setSPEngine()
        setMPEngine()
    }
    
    func setSPEngine() {
        if (self.isSPAvailable()) {
            singlePathEngine = YikesEngineSP.sharedEngine() as? YikesEngineSP
            
            singlePathEngine?.changeEngineBeaconMode = self.changeEngineBeaconMode
            singlePathEngine?.engineBeaconMode = self.engineBeaconMode
            singlePathEngine?.shouldStartBLEActivity = self.shouldStartBLEActivity
            
            YikesEngineSP.initEngine(with: self)
        }
        else {
            print("SPEngine is NOT available")
        }
    }
    
    func setMPEngine() {
        if (self.isMPAvailable()) {
            multiPathEngine = YikesEngineMP.sharedEngine() as YikesEngineMP
            
            multiPathEngine?.changeEngineBeaconMode = self.changeEngineBeaconMode
            multiPathEngine?.engineBeaconMode = self.engineBeaconMode
            multiPathEngine?.shouldStartBLEActivity = self.shouldStartBLEActivity
            
            YikesEngineMP.initEngine(with: self)
        }
        else {
            print("MPEngine is NOT available")
        }
    }
    
    func isMPAvailable() -> Bool {
        return NSClassFromString("YikesEngineMP") != nil
    }
    
    func isSPAvailable() -> Bool {
        return NSClassFromString("YikesEngineSP.YikesEngineSP") != nil
    }
    
    let changeEngineBeaconMode: ((YKSBeaconMode) -> Void) = { beaconMode in
        if EngineController.switchEngineBeaconMode(newBeaconMode: beaconMode) {
            EngineController.sharedInstance.beaconMode = beaconMode
        }
    }
    
    let engineBeaconMode: (() -> YKSBeaconMode) = {
        return EngineController.sharedInstance.beaconMode
    }
    
    let shouldStartBLEActivity: ((YKSEngineArchitecture) -> Bool) = { arch in
        
        if arch == YKSEngineArchitecture.singlePath {
            // Only return true if no other engine is scanning and the calling engine is On
            var should = true
            if EngineController.sharedInstance.singlePathEngine?.engineState == .on {
                
                if EngineController.sharedInstance.isMPAvailable() {
                    return should && EngineController.sharedInstance.multiPathEngine?.bleEngineState != .on
                }
                else {
                    return should
                }
            }
            else {
                return false
            }
        }
        else if (arch == YKSEngineArchitecture.multiPath) {
            if EngineController.sharedInstance.multiPathEngine?.engineState == .on &&
                EngineController.sharedInstance.singlePathEngine?.bleEngineState != .on {
                    return true
            }
            else {
                return false
            }
        }
        else {
            //Unknown architecture...
            return false
        }
    }
    
    //MARK:
    func sharedEngine() -> GenericEngineProtocol? {
        
        switch currentArchitecture {
            
        case .singlePath:
            return singlePathEngine
            
        case .multiPath:
            return multiPathEngine
        }
    }
    
    //MARK: Static func
    static func loggedInUserInfo() -> YKSUserInfo? {
        
        if let user = EngineController.sharedInstance.singlePathEngine?.userInfo {
            return user
        }
        else if let user = EngineController.sharedInstance.multiPathEngine?.userInfo {
            return user
        }
        else {
            return nil
        }
        
    }
    
    static func switchEngineBeaconMode(newBeaconMode:YKSBeaconMode) -> Bool {
        //        if EngineController.beaconMode == newBeaconMode {
        //            return false
        //        }
        //        else {
        switch newBeaconMode {
        case YKSBeaconMode.yksspForced:
            EngineController.sharedInstance.currentArchitecture = .singlePath
            EngineController.sharedInstance.multiPathEngine?.pauseEngine()
            EngineController.sharedInstance.singlePathEngine?.resumeEngine()
            return true
        case YKSBeaconMode.yksmpForced:
            EngineController.sharedInstance.currentArchitecture = .multiPath
            EngineController.sharedInstance.singlePathEngine?.pauseEngine()
            EngineController.sharedInstance.multiPathEngine?.resumeEngine()
            return true
        case YKSBeaconMode.yksBeaconBased:
            if EngineController.loggedInUserInfo() != nil {
                EngineController.sharedInstance.multiPathEngine?.resumeEngine()
                EngineController.sharedInstance.singlePathEngine?.resumeEngine()
                return true
            }
            else {
                return false
            }
        }
        //        }
    }
    
    @objc func yikesEngineStateDidChange(_ state: YKSEngineState) {
        YikesEngine.sharedInstance.delegate?.yikesEngineStateDidChange?(state)
    }
    
    //MARK: YikesEngineDelegate
    @objc func yikesEngineLocationStateDidChange(_ newState: YKSLocationState) {
        
        if currentSPState == .enteredSPHotel && newState == .enteredMPHotel && beaconMode == .yksBeaconBased {
            
            // Ignore location change if already inside SP region (GAD-1325)
            currentMPState = .enteredMPHotel
            return
        }
        
        if ( (newState == .leftMPHotel && currentSPState == .leftSPHotel) || (newState == .leftSPHotel && currentMPState == .leftMPHotel) ) {
            // only notify the GA if outside of BOTH yikes regions:
            YikesEngine.sharedInstance.delegate?.yikesEngineLocationStateDidChange?(newState)
        }
        else if ( (newState == .enteredSPHotel && currentMPState == .leftMPHotel) || (newState == .enteredMPHotel && currentSPState == .leftSPHotel) ) {
            // only notify the GA on the first of both region entries:
            YikesEngine.sharedInstance.delegate?.yikesEngineLocationStateDidChange?(newState)
        }
        
        switch newState {
            
        case YKSLocationState.enteredMPHotel:
            
            if beaconMode == .yksmpForced || beaconMode == .yksBeaconBased {
                
                singlePathEngine?.pauseEngine()
                
                currentMPState = newState
                
                YikesEngine.sharedInstance.delegate?.yikesEngineLocationStateDidChange?(newState)
                
                self.switchToMultiPath()
            }
            
        case YKSLocationState.leftMPHotel:

            if beaconMode == .yksmpForced || beaconMode == .yksBeaconBased {
                
                currentMPState = newState
                
                YikesEngine.sharedInstance.delegate?.yikesEngineLocationStateDidChange?(newState)
                
                // IMPORTANT: Turn off MP mode before we stop MP engine
                // If reversed, SP Engine will stop as well in yikesEngineStateDidChange()
                // ensure we initialized engine to set default values
                multiPathEngine?.pauseEngine()
                
                
                if beaconMode == .yksBeaconBased {
                    
                    // Previously entered SP, switch engines
                    self.switchToSinglePath()
                    
                }
//                else {
//                    
//                    // If not forcing MP, check if inside SP
//                    if beaconMode != .yksmpForced {
//                        singlePathEngine?.requestBeaconState()
//                    }
//                }
            }
            
        case YKSLocationState.enteredSPHotel:
            
            if beaconMode == .yksspForced || beaconMode == .yksBeaconBased {
                
                multiPathEngine?.pauseEngine()
                
                currentSPState = newState
                
                YikesEngine.sharedInstance.delegate?.yikesEngineLocationStateDidChange?(newState)
                
                self.switchToSinglePath()
            }
            
        case YKSLocationState.leftSPHotel:
            
            if beaconMode == .yksspForced || beaconMode == .yksBeaconBased {
                
                currentSPState = newState
                
                YikesEngine.sharedInstance.delegate?.yikesEngineLocationStateDidChange?(newState)
                
                singlePathEngine?.pauseEngine()
                
                if currentMPState == YKSLocationState.enteredMPHotel && beaconMode == .yksBeaconBased {
                    
                    // Previously entered MP, switch engines
                    self.switchToMultiPath()
                    
                }
//                else {
//                    
//                    // If not forcing SP, check if inside MP
//                    if beaconMode != .yksspForced {
//                        multiPathEngine?.requestBeaconState()
//                    }
//                }

            }

            
        case YKSLocationState.unknown:
            
            break
        }
        
    }
    
    func switchToMultiPath() {
        currentArchitecture = .multiPath
        
        if (multiPathEngine?.bleEngineState != .on) {
            multiPathEngine?.resumeEngine()
        }
    }
    
    func switchToSinglePath() {
        currentArchitecture = .singlePath
        
        if (singlePathEngine?.bleEngineState != .on) {
            singlePathEngine?.resumeEngine()
        }
    }
    
    
    //MARK: Calls from GA -> Engine ==> use sharedEngine (vs. sharedInstance)
    @objc func yikesEngineUserInfoDidUpdate(_ yikesUser: YKSUserInfo!) {
        YikesEngine.sharedInstance.delegate?.yikesEngineUserInfoDidUpdate?(yikesUser)
    }
    
    //MARK: Calls from Engine -> GA ==> use sharedInstance (vs. sharedEngine)
    @objc func yikesEngineDeviceMotionStateDidChange(_ state: YKSDeviceMotionState) {
        YikesEngine.sharedInstance.delegate?.yikesEngineDeviceMotionStateDidChange?(state)
    }
    
    @objc func yikesEngineRoomConnectionStatusDidChange(_ newStatus: YKSConnectionStatus, withRoom room: String!) {
        YikesEngine.sharedInstance.delegate?.yikesEngineRoomConnectionStatusDidChange?(newStatus, withRoom: room)
    }
    
    @objc func yikesEngineRoomConnectionStatusDidChange(_ newStatus: YKSConnectionStatus, withRoom room: String!, disconnectReasonCode code: YKSDisconnectReasonCode) {
        YikesEngine.sharedInstance.delegate?.yikesEngineRoomConnectionStatusDidChange?(newStatus, withRoom: room, disconnectReasonCode: code)
    }
    
    @objc func yikesEngineRequiredServicesMissing(_ missingServices: Set<AnyHashable>!) {
        YikesEngine.sharedInstance.delegate?.yikesEngineRequiredServicesMissing?(missingServices)
    }
    
    @objc func yikesEngineErrorDidOccur(_ yikesError: YKSError!) {
        YikesEngine.sharedInstance.delegate?.yikesEngineErrorDidOccur?(yikesError)
    }
    
}
