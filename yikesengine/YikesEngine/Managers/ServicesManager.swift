//
//  ServicesManager.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/30/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire

import YikesSharedModel

class ServicesManager: NSObject {
    
    static let sharedInstance = ServicesManager()
    
    var observers : [Observer] = []
    
    var reachabilityManager: NetworkReachabilityManager?
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(ServicesManager.backgroundRefreshStatusDidChange(_:)),
            name: NSNotification.Name.UIApplicationBackgroundRefreshStatusDidChange,
            object: nil)
        
        // Ensure centralManager is initialized to get centralManager.state
        _ = BLEEngine.sharedInstance
        reachabilityManager = NetworkReachabilityManager(host: "www.google.com")
        
        self.startReachabilityNotifier()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationBackgroundRefreshStatusDidChange, object: nil)
        self.stopReachabilityNotifier()
    }
    
    var missingServices : Set<NSNumber> {
        
        var missingServices = Set<NSNumber>()
        
        if !self.isReachable() {
            missingServices.insert(NSNumber(value: YKSServiceType.internetConnectionService.rawValue))
        }
        
        if !self.areLocationServicesEnabled() {
            missingServices.insert(NSNumber(value: YKSServiceType.locationService.rawValue))
        }
        
        if !self.arePushNotificationsEnabled() {
            missingServices.insert(NSNumber(value: YKSServiceType.pushNotificationService.rawValue))
        }
        
        if !self.isBackgroundRefreshEnabled() {
            missingServices.insert(NSNumber(value: YKSServiceType.backgroundAppRefreshService.rawValue))
        }
        
        if !self.isBluetoothEnabled() {
            missingServices.insert(NSNumber(value: YKSServiceType.bluetoothService.rawValue))
        }
        
        let services = missingServices.map{ YKSServiceType(rawValue: $0.uintValue)!.stringValue }
        if (services.count > 0) {
            yLog(LoggerLevel.warning, category: LoggerCategory.Service, message: "Missing services: \(services)")
        }
        else {
            yLog(.info, category: .Service, message: "No missing services")
        }
        
        return missingServices
    }
    
    func notifyMissingServices() {
        
        yLog(.debug, category: .Service, message: "Notifying of missing services..")
        notifyObservers(ObserverNotification(
            observableEvent: ObservableEvent.MissingServicesDidChange,
            data: missingServices))
    }
    
    func isReachable() -> Bool {
        return (reachabilityManager?.isReachable)!
    }
    
    func areLocationServicesEnabled() -> Bool {
        
        return CLLocationManager.locationServicesEnabled() &&
            (CLLocationManager.authorizationStatus() != .denied &&
                CLLocationManager.authorizationStatus() != .notDetermined)
    }
    
    func arePushNotificationsEnabled() -> Bool {
        let settings = UIApplication.shared.currentUserNotificationSettings
        return (settings?.types.contains(.alert) == true)
    }
    
    func isBackgroundRefreshEnabled() -> Bool {
        
        if (UIApplication.shared.backgroundRefreshStatus == .available) {
            return true;
        }
        return false;
    }
    
    func isBluetoothEnabled() -> Bool {
        return BLEEngine.sharedInstance.centralManager.state == .poweredOn ||
            BLEEngine.sharedInstance.centralManager.state == .resetting
    }
    
    func startReachabilityNotifier() {
        self.reachabilityManager?.listener = { status in
            if status == . notReachable {
                yLog(LoggerLevel.debug, category: LoggerCategory.Service, message: "Internet connection became UNREACHABLE.")
            }
            else if status == .reachable(.ethernetOrWiFi) {
                yLog(LoggerLevel.debug, category: LoggerCategory.Service, message: "Internet connection became REACHABLE via WiFi.")
            } else if status == .reachable(.wwan) {
                yLog(LoggerLevel.debug, category: LoggerCategory.Service, message: "Internet connection became REACHABLE via Cellular.")
            }
            
            self.notifyMissingServices()
        }
        
        self.reachabilityManager?.startListening()
    }
    
    func stopReachabilityNotifier() {
        self.reachabilityManager?.stopListening()
    }
    
    func backgroundRefreshStatusDidChange(_ notification: Notification) {
        self.notifyMissingServices()
    }
    
}

extension ServicesManager: Observable {
    
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
