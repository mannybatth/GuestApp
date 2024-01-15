//
//  Amenity.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/23/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import ObjectMapper

class Amenity: NSObject, Mappable {
    
    var amenityId: Int?
    var name: String?
    var openTime: String?
    var closeTime: String?
    var doorType: String?
    var displayCategory: String?
    var credential : Credential?
    var macAddress : String?
    
    var connectionStatus: YKSConnectionStatus = .disconnectedFromDoor
    
    var hotel: Hotel?
    var yLink : YLink?
    var stay : Stay?
    
    var isOpenNow : Bool {
        
        guard let openTime = openTime, var closeTime = closeTime
            else { return false }
        
        if self.isAllDayAmenity(openTime, closetime: closeTime) {
            closeTime = openTime
        }
        
        let now = Date()
        
        if let openDateTime = DateHelper.sharedInstance.mergeTimeWithDate(now, timeString: openTime, timezone: hotel?.localTimezone),
            let closeDateTime = DateHelper.sharedInstance.mergeTimeWithDate(now, timeString: closeTime, timezone: hotel?.localTimezone) {
            
            //Note: if close time is 23:59 and open time is 00:00 then it should be considered always open.
            //print("\(name) opentime: \(openTime) closetime: \(closeTime)")
            
            if DateHelper.sharedInstance.isDate(date: now, betweenDate: openDateTime, andDate: closeDateTime) {
                return true
            } else if openTime == closeTime {
                return true
            }
            else {
                return false
            }
        
        } else {
            
            yLog(.critical, message: "Open and Close Date Time could not be parsed for stay \(self.stay) on amenity \(self.name)")
            return true
        }
    }
    
    override init() {}
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        amenityId           <- map["id"]
        name                <- map["name"]
        openTime            <- map["open_time"]
        closeTime           <- map["close_time"]
        doorType            <- map["door_type"]
        displayCategory     <- map["door_display_category"]
        credential          <- map["credentials"]
        macAddress          <- map["mac_address"]
        connectionStatus    <- map["connection_status"]
    }
    
    override var description : String {
        return "name: \(name ?? "nil") macAddress: \(macAddress ?? "nil")"
    }
    
    override var hashValue: Int {
        return amenityId!.hashValue
    }
    
    func isAllDayAmenity(_ opentime:String, closetime:String) -> Bool {
        if let opentime_components = openTime?.components(separatedBy: ":"),
        let closetime_components = closeTime?.components(separatedBy: ":") {
            guard opentime_components.count >= 2 && closetime_components.count >= 2 else {
                return false
            }
            let opentime_hs = String(opentime_components[0] + ":" + opentime_components[1])
            let closetime_hs = String(closetime_components[0] + ":" + closetime_components[1])
            if opentime_hs == "00:00" && closetime_hs == "23:59" {
               return true
            }
        }
        return false
    }
}

func == (lhs: Amenity, rhs: Amenity) -> Bool {
    return (lhs.amenityId == rhs.amenityId)
}
