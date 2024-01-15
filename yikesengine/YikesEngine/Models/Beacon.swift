//
//  Beacon.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

class Beacon: NSObject, Mappable {

    var regionCount: Int?
    var uuid: String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        regionCount     <- map["region_count"]
        uuid            <- map["uuid"]
        
//        uuid = "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5" // test SP Beacon
    }
    
}
