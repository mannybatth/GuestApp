//
//  StayShare.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/23/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import ObjectMapper

class StayShare: NSObject, Mappable {
    
    var stayShareId: Int?
    var status: String?
    var stay: Stay?
    var primaryGuest: User?
    var secondaryGuest: User?
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        stayShareId     <- map["id"]
        status          <- map["status"]
        stay            <- map["stay"]
        primaryGuest    <- map["primary_guest"]
        secondaryGuest  <- map["secondary_guest"]
    }
    
    var stayShareInfo: YKSStayShareInfo? {
        
        let JSONDictionary = Mapper().toJSON(self)
        if let stayShareInfo = YKSStayShareInfo.new(withJSONDictionary: JSONDictionary) {
            return stayShareInfo
        }
        return nil
    }
    
    override var hashValue: Int {
        return stayShareId!.hashValue
    }
    
}

func == (lhs: StayShare, rhs: StayShare) -> Bool {
    return (lhs.stayShareId == rhs.stayShareId)
}

extension Array where Element:StayShare {
    
    func infoObjects() -> [YKSStayShareInfo] {
        return map { $0.stayShareInfo! }
    }
    
}
