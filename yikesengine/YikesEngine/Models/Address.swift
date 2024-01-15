//
//  Address.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/23/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

class Address: NSObject, Mappable {
    
    var addressLine1: String?
    var addressLine2: String?
    var addressLine3: String?
    var city: String?
    var country: String?
    var postalCode: String?
    var stateCode: String?
    
    override init() {}
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        addressLine1    <- map["address_line_1"]
        addressLine2    <- map["address_line_2"]
        addressLine3    <- map["address_line_3"]
        city            <- map["city"]
        country         <- map["country"]
        postalCode      <- map["postal_code"]
        stateCode       <- map["state_code"]
    }
    
}
