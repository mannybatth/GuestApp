//
//  Stay.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/18/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import ObjectMapper

class Stay: NSObject, Mappable {
    
    var stayId: Int?
    var userId: Int?
    var roomNumber: String?
    var reservationNumber: String?
    var arrivalDate: Date?
    var departDate: Date?
    var checkInTime: String?
    var checkOutTime: String?
    var modifiedOn: Date?
    var createdOn: Date?
    var isActive: Bool?
    var amenities: [Amenity] = []
    var hotel : Hotel?
    var primaryGuest : User?
    var credential : Credential?
    var macAddress : String?
    var numberOfNights : Int?
    
    var connectionStatus: YKSConnectionStatus = .disconnectedFromDoor
    
    var yLink : YLink?
    
    var arrivalDateWithTime : Date? {
        guard let date = arrivalDate, let time = checkInTime
            else { return nil }
        
        return DateHelper.sharedInstance.mergeTimeWithDate(date, timeString: time, timezone: hotel?.localTimezone)
    }
    
    var departDateWithTime : Date? {
        guard let date = departDate, let time = checkOutTime
            else { return nil }
        
        return DateHelper.sharedInstance.mergeTimeWithDate(date, timeString: time, timezone: hotel?.localTimezone)
    }
    
    var stayStatus : YKSStayStatus {
        
        guard let arrivalDateWithTime = arrivalDateWithTime, let departDateWithTime = departDateWithTime
            else { return .unknown }
        
        let now = Date()
        
        if DateHelper.sharedInstance.isDate(date: now as Date, betweenDate: arrivalDateWithTime as Date, andDate: departDateWithTime as Date) {
            return .current
        }
        
        let secondsRemaining = departDateWithTime.timeIntervalSince(now)
        
        if secondsRemaining > 0 {
            return .notYetStarted
        } else {
            return .expired
        }
    }
    
    var refreshingCredentials:Bool = false
    
    override init() {}
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        stayId              <- map["id"]
        userId              <- map["user_id"]
        roomNumber          <- map["room_number"]
        reservationNumber   <- map["reservation_number"]
        arrivalDate         <- (map["arrival_date"], DateNoTimeTransform())
        departDate          <- (map["depart_date"], DateNoTimeTransform())
        checkInTime         <- map["check_in_time"]
        checkOutTime        <- map["check_out_time"]
        modifiedOn          <- (map["modified_on"], DateTimeTransform())
        createdOn           <- (map["created_on"], DateTimeTransform())
        isActive            <- map["is_active"]
        amenities           <- map["amenities"]
        hotel               <- map["hotel"]
        primaryGuest        <- map["primary_guest"]
        credential          <- map["credentials"]
        macAddress          <- map["mac_address"]
        numberOfNights      <- map["number_of_nights"]
        connectionStatus    <- map["connection_status"]
        
        if map.mappingType == MappingType.fromJSON {
            
            numberOfNights = DateHelper.sharedInstance.daysBetweenDates(startDate: arrivalDateWithTime!, endDate: departDateWithTime!)
            
            generateAmenityYLinks()
            
            if self.macAddress != nil
            && self.macAddress?.characters.count == 12
                && self.hotel?.isSinglePath == true
            {
            
                yLink = YLink(stay: self)
                
            }
        }
    }
    
    func credentialsForAmenity(_ theAmenity:Amenity) -> Credential? {
        for amenity in self.amenities {
            if amenity.amenityId == theAmenity.amenityId {
                return amenity.credential
            }
        }
        yLog(.debug, message: "no credentials found for amenity \(theAmenity)")
        return nil
    }
    
    func credentialsExpired () -> Bool {
        guard let credential = self.credential else {
            return false
        }
        let mainRoomCredentialsExpired = credential.credentialsExpired()
        if mainRoomCredentialsExpired {
            return true
        }
        else {
            for amenity in amenities {
                if let credential = amenity.credential {
                    if credential.credentialsExpired() {
                        return true
                    }
                }
                else {
                    yLog(.critical, message:"[Credentials][Expired] Amenity \(amenity) doesn't have any credentials")
                }
            }
            return false
        }
    }
    
    func credentialsAboutToExpire () -> Bool {
        guard let credential = self.credential else {
            return false
        }
        let mainRoomCredentialsAboutToExpire = credential.credentialsAboutToExpire()
        if mainRoomCredentialsAboutToExpire {
            return true
        }
        else {
            for amenity in amenities {
                if let credential = amenity.credential {
                    if credential.credentialsAboutToExpire(){
                        return true
                    }
                }
                else {
                    yLog(.critical, message:"[Credentials][AboutToExpire] Amenity \(amenity) doesn't have any credentials")
                }
            }
            return false
        }
    }
    
    func credentialsExpireSoon () -> Bool {
        guard let credential = self.credential else {
            return false
        }
        let roomCredentialsExpireSoon = credential.credentialsExpireSoon()
        if roomCredentialsExpireSoon {
            return true
        }
        else {
            for amenity in amenities {
                if let credential = amenity.credential {
                    if credential.credentialsExpireSoon() {
                        return true
                    }
                }
                else {
                    yLog(.critical, message:"[Credentials][ExpireSoon] Amenity \(amenity) doesn't have any credentials")
                }
            }
            return false
        }
    }
    
    func generateAmenityYLinks() {
        
        for amenity in amenities {
            amenity.hotel = hotel
            
            if amenity.macAddress != nil &&
                amenity.macAddress?.characters.count == 12 &&
                amenity.hotel?.isSinglePath == true {
                
                amenity.yLink = YLink(stay:self, amenity: amenity)
            }
        }
    }
    
    override var description : String {
        return "stayid: \(stayId ?? nil) roomNumber: \(roomNumber ?? "nil") macAddress: \(macAddress ?? "nil")"
    }
    
    override var hashValue: Int {
        return self.stayId!.hashValue &+ self.createdOn!.hashValue &+ self.modifiedOn!.hashValue
    }
    
    override func isEqual(_ object: Any?) -> Bool {

        if let rhs = object as? Stay {
            return self.stayId == rhs.stayId && self.createdOn == rhs.createdOn && self.modifiedOn == rhs.modifiedOn
        }
        
        return false
    }
    
}

func == (lhs: Stay, rhs: Stay) -> Bool {
    return (lhs.stayId == rhs.stayId)
}
