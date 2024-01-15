//
//  Contact.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/23/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import ObjectMapper

class Contact: NSObject, Mappable {
    
    var contactId: Int?
    var user: User?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        contactId   <- map["id"]
        user        <- map["user"]
    }
    
    var contactInfo: YKSContactInfo? {
        
        let JSONDictionary = Mapper().toJSON(self)
        if let contactInfo = YKSContactInfo.new(withJSONDictionary: JSONDictionary) {
            return contactInfo
        }
        return nil
    }
    
    override var hashValue: Int {
        return contactId!.hashValue
    }
    
}

func == (lhs: Contact, rhs: Contact) -> Bool {
    return (lhs.contactId == rhs.contactId)
}

extension Array where Element:Contact {
    
    func infoObjects() -> [YKSContactInfo] {
        return map { $0.contactInfo! }
    }
    
}
