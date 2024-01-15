//
//  ConnectionThresholdAdjuster.swift
//  YikesEngineSP
//
//  Created by Alexandar Dimitrov on 2016-04-06.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import YikesSharedModel
import ObjectMapper

class ConnectionThresholdAdjuster: Mappable, CustomStringConvertible {

    var allYLinkThresholds = Array<YLinkThreshold>()
    
    init() { }
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        allYLinkThresholds  <- map["allYLinkThresholds"]
    }
    
    var description: String {
        
        var content: String = "All YLinkThreshold in allYLinkThresholds array:\n"
        
        for oneYLinkThreshold in self.allYLinkThresholds {
            content += oneYLinkThreshold.description + "\n"
        }
        
        return content
    }
    
    func yLinkThresholdForMacAddress(_ macAddress: String) -> YLinkThreshold? {
        
        for aYLinkThreshold in self.allYLinkThresholds {
            if macAddress == aYLinkThreshold.macAddress {
                return aYLinkThreshold
            }
        }
        return nil
    }
    
    func minConnectRSSI(_ connection: BLEConnection, credential:Credential) -> Int {
        
        // set default
        var minConnectRSSI = credential.proximityRSSI ?? -75
        
        guard let macAddress = connection.yLink.macAddress else {
            return minConnectRSSI
        }
        
        if let yLinkThreshold = self.yLinkThresholdForMacAddress(macAddress),
            let defaultProximityRSSI = yLinkThreshold.defaultProximityRSSI {
            
            // reset adjustedProximityRSSI & defaultProximityRSSI if proximityRSSI (or default) changed
            if minConnectRSSI != defaultProximityRSSI {
                
                yLog(LoggerLevel.info, category: LoggerCategory.BLE, message: "[\(yLinkThreshold.macAddress ?? nil)] Detected change in default proximity RSSI (was \(defaultProximityRSSI)), resetting tuning to \(minConnectRSSI)")
                
                yLinkThreshold.defaultProximityRSSI = minConnectRSSI
                yLinkThreshold.adjustedProximityRSSI = minConnectRSSI
            }
            
            minConnectRSSI = yLinkThreshold.adjustedProximityRSSI!
            
        } else {
            
            if let macAddress = connection.yLink.macAddress {
                self.addYLinkThreshold(macAddress, yLinkProximityRSSI: minConnectRSSI)
            }
        }
        
        connection.minConnectRSSI = minConnectRSSI
        
        return minConnectRSSI
    }
    
    func didDisconnectYLink(_ connection: BLEConnection) {
        
        guard let macAddress = connection.yLink.macAddress else {
            return
        }
        
        guard let isSuccessfulOn = connection.isSuccessfulOn,
            let yLinkThreshold = self.yLinkThresholdForMacAddress(macAddress) else {
            return
        }
        
        let now = Date()
        let secondsElasped = now.timeIntervalSince(isSuccessfulOn as Date)
        
        if secondsElasped > 2.5 {
            
            if yLinkThreshold.numOfConsecutiveDownTunning >= 5 {
                yLog(LoggerLevel.info, category: LoggerCategory.BLE, message: "[\(yLinkThreshold.macAddress ?? "nil")] Too many down tuning, keeping minConnectRSSI: \(yLinkThreshold.adjustedProximityRSSI)")
                return
            }
            
            yLinkThreshold.requireWeakerConnectRSSI()
            yLinkThreshold.numOfConsecutiveDownTunning += 1
            StoreManager.sharedInstance.saveYLinksThresholdsToCache(self)
            
            connection.minConnectRSSI = yLinkThreshold.adjustedProximityRSSI
            
            yLog(LoggerLevel.info, category: LoggerCategory.BLE, message: "[\(yLinkThreshold.macAddress ?? "nil")] Tuning DOWN, new minConnectRSSI: \(yLinkThreshold.adjustedProximityRSSI)")
            
        } else {
            
            if connection.connectionEndReason == .Proximity {
                
                yLinkThreshold.requireStrongerConnectRSSI()
                yLinkThreshold.numOfConsecutiveDownTunning = 0
                StoreManager.sharedInstance.saveYLinksThresholdsToCache(self)
                
                connection.minConnectRSSI = yLinkThreshold.adjustedProximityRSSI
                
                yLog(LoggerLevel.info, category: LoggerCategory.BLE, message: "[\(yLinkThreshold.macAddress ?? "nil")] Tuning UP, new minConnectRSSI: \(yLinkThreshold.adjustedProximityRSSI)")
            }
        }
    }
    
    
    func addYLinkThreshold(_ macAddress: String, yLinkProximityRSSI: Int) {
        
        let newYLinkThreshold = YLinkThreshold(macAddress: macAddress, yLinkProximityRSSI: yLinkProximityRSSI)
        self.allYLinkThresholds.append(newYLinkThreshold)
        
        StoreManager.sharedInstance.saveYLinksThresholdsToCache(self)
    }
}
