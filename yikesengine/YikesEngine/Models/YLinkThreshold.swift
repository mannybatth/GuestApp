//
//  YLinkThreshold.swift
//  YikesEngineSP
//
//  Created by Alexandar Dimitrov on 2016-04-06.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

class YLinkThreshold: Mappable, CustomStringConvertible {
    
    var macAddress: String?
    var defaultProximityRSSI: Int?
    var adjustedProximityRSSI: Int?
    var numOfConsecutiveDownTunning: Int = 0
    var lastReadRSSI: Int?
    
    let maxDownTuning = 10
    
    var description: String {
        return "YLinkThreshold, macAddress: \(self.macAddress), defaultProximityRSSI: " +
            " \(defaultProximityRSSI), adjustedProximityRSSI: \(adjustedProximityRSSI), " +
            " lastReadRssi: \(lastReadRSSI)"
    }
    
    init(macAddress: String, yLinkProximityRSSI: Int) {
        self.defaultProximityRSSI = yLinkProximityRSSI
        self.adjustedProximityRSSI = yLinkProximityRSSI
        self.macAddress = macAddress
        self.enforceMinDownTuning()
    }
    
    required init?(map: Map) {}
    
    func requireStrongerConnectRSSI() {
        
        if self.adjustedProximityRSSI != nil && self.defaultProximityRSSI != nil {
            // -55 < (-60 - 10) -50 == true => -54
            // -50 < -50 == false
            // -51 < -50 == true => -50
            if self.adjustedProximityRSSI! < self.defaultProximityRSSI! - (-maxDownTuning) {
                self.adjustedProximityRSSI! -= -1
            }
            else {
                yLog(LoggerLevel.info, category: LoggerCategory.BLE, message: "[\(self.macAddress ?? "nil")] NOT Tuning DOWN, staying at adjustedProximityRSSI: \(self.adjustedProximityRSSI)")
            }
        }
    }
    
    func enforceMinDownTuning() {
        if self.adjustedProximityRSSI != nil && self.defaultProximityRSSI != nil {
            // -55 > (-60-(-10)) -50 == false
            // -48 > -50 == true => -50
            if self.adjustedProximityRSSI! > self.defaultProximityRSSI! - (-maxDownTuning) {
                self.adjustedProximityRSSI = self.defaultProximityRSSI! - (-maxDownTuning)
            }
        }
    }
    
    func requireWeakerConnectRSSI() {
        
        if self.adjustedProximityRSSI != nil {
            self.adjustedProximityRSSI! += -1
        }
        
    }
    
    func mapping(map: Map) {
        macAddress                      <- map["macAddress"]
        defaultProximityRSSI            <- map["defaultProximityRSSI"]
        adjustedProximityRSSI           <- map["adjustedProximityRSSI"]
        numOfConsecutiveDownTunning     <- map["numOfConsecutiveDownTunning"]
        lastReadRSSI                    <- map["lastReadRSSI"]
        
        self.enforceMinDownTuning()
    }
    
}
