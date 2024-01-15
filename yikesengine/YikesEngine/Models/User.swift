//
//  User.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/17/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import ObjectMapper

class User: NSObject, Mappable {
    
    var userId: Int?
    var firstName: String?
    var lastName: String?
    var email: String?
    var middleInitial: String?
    var phoneNumber: String?
    var primaryPhone: Bool?
    var deviceId: String?
    var createdOn: Date?
    var firstApiLoginOn: Date?
    var hasTempPassword: Bool?
    var eulaAccepted: Bool?
    
    var stays: [Stay] = []
    var stayShares: [StayShare] = []
    var userInvites: [UserInvite] = []
    var recentContacts: [Contact] = []
    
    var beacon: Beacon?
    
    override init() {}
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        userId              <- map["id"]
        firstName           <- map["first_name"]
        lastName            <- map["last_name"]
        email               <- map["email"]
        middleInitial       <- map["middle_initial"]
        phoneNumber         <- map["phone_number"]
        primaryPhone        <- map["primary_phone"]
        deviceId            <- map["device_id"]
        hasTempPassword     <- map["has_temp_password"]
        createdOn           <- (map["created_on"], DateTimeTransform())
        firstApiLoginOn     <- (map["first_api_login_on"], DateTimeTransform())
        stays               <- map["stays"]
        stayShares          <- map["stay_shares"]
        userInvites         <- map["user_invites"]
        recentContacts      <- map["recent_contacts"]
        beacon              <- map["beacon_data"]
    }
    
    override var description : String {
        if var desc = String("\nName: \(self.firstName ?? "") + \(self.lastName ?? "")\n" +
            "Email: \((self.email ?? ""))") {
            let stays = String(describing: dump(self.stays))
            desc = desc + stays
            return desc
        }
        return ""
    }
    
    var userInfo: YKSUserInfo? {
        
        let JSONDictionary = Mapper().toJSON(self)
        if let userInfo = YKSUserInfo.new(withJSONDictionary: JSONDictionary) {
            return userInfo
        }
        return nil
    }
    
    override var hashValue: Int {
        return userId!.hashValue
    }
    
    var yLinks : Set<YLink> {
        var yLinks : Set<YLink> = []
        
        for stay in stays {
            if let yLink = stay.yLink {
                yLinks.insert(yLink)
            }
            
            for amenity in stay.amenities {
                if let yLink = amenity.yLink {
                    yLinks.insert(yLink)
                }
            }
        }
        
        return yLinks
    }
    
    var yLinksToScanFor : Set<YLink> {
        
        var yLinks : Set<YLink> = []
        
        for stay in stays {
            if stay.stayStatus == .current {
                if let yLink = stay.yLink {
                    yLinks.insert(yLink)
                    for amenity in stay.amenities {
                        if amenity.isOpenNow {
                            if let yLink = amenity.yLink {
                                amenity.stay = stay
                                yLink.amenity = amenity
                                yLinks.insert(yLink)
                            }
                        }
                    }
                }
            }
            else {
                yLog(.debug, message: "Skipping stay in yLinksToScanFor: \(stay)")
            }
        }
        
        
        return yLinks
    }
    
}

func == (lhs: User, rhs: User) -> Bool {
    return (lhs.userId == rhs.userId)
}
