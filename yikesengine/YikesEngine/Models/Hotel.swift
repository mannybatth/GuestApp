//
//  Hotel.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/23/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import ObjectMapper

class Hotel: NSObject, Mappable {
    
    var hotelId: Int?
    var name: String?
    var hotelURL: URL?
    var contactPhone: String?
    var localTimezone: TimeZone?
    var maxSecondaryGuests: Int?
    var address: Address?
    var isSinglePath: Bool = true
    
    var dashboardImageURL1x: String?
    var dashboardImageURL2x: String?
    var dashboardImageURL3x: String?
    
    override init() {}
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        hotelId             <- map["id"]
        name                <- map["name"]
        hotelURL            <- (map["hotel_url"], URLTransform())
        contactPhone        <- map["contact_phone"]
        localTimezone       <- (map["local_tz"], TimeZoneTransform())
        maxSecondaryGuests  <- map["max_secondary_guests"]
        address             <- map["address"]
        dashboardImageURL1x <- map["assets.dashboard_images.1x"]
        dashboardImageURL2x <- map["assets.dashboard_images.2x"]
        dashboardImageURL3x <- map["assets.dashboard_images.3x"]
        isSinglePath        <- map["is_single_path"]
        
        if map.mappingType == MappingType.fromJSON {
            // Remove all non-numeric characters
            contactPhone = contactPhone?.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "")
        }
    }
    
}
