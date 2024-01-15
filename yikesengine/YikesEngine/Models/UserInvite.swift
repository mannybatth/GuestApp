//
//  UserInvite.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/23/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import ObjectMapper

class UserInvite: NSObject, Mappable {
    
    var inviteId: Int?
    var firstName: String?
    var lastName: String?
    var email: String?
    var phoneNumber: String?
    var inviteeUserId: Int?
    var inviterUserId: Int?
    var relatedStayId: Int?
    var acceptedOn: Date?
    var declinedOn: Date?
    var createdOn: Date?
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        inviteId        <- map["id"]
        firstName       <- map["first_name"]
        lastName        <- map["last_name"]
        email           <- map["email"]
        phoneNumber     <- map["phone_number"]
        inviteeUserId   <- map["invitee_user_id"]
        inviterUserId   <- map["inviter_user_id"]
        relatedStayId   <- map["related_stay_id"]
        acceptedOn      <- (map["accepted_on"], DateTimeTransform())
        declinedOn      <- (map["declined_on"], DateTimeTransform())
        createdOn       <- (map["created_on"], DateTimeTransform())
    }
    
    var userInviteInfo: YKSUserInviteInfo? {
        
        let JSONDictionary = Mapper().toJSON(self)
        if let userInviteInfo = YKSUserInviteInfo.new(withJSONDictionary: JSONDictionary) {
            return userInviteInfo
        }
        return nil
    }
    
    override var hashValue: Int {
        return inviteId!.hashValue
    }
    
}

func == (lhs: UserInvite, rhs: UserInvite) -> Bool {
    return (lhs.inviteId == rhs.inviteId)
}

extension Array where Element:UserInvite {
    
    func infoObjects() -> [YKSUserInviteInfo] {
        return map { $0.userInviteInfo! }
    }
    
}
