//
//  HotelBeaconRegion.swift
//  YikesEngineSP
//
//  Created by Roger Mabillard on 2016-05-27.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import CoreLocation

class HotelBeaconRegion : CLBeaconRegion {
    
    var currentState: CLRegionState = .outside
    
    override init(proximityUUID: UUID, identifier: String) {
        super.init(proximityUUID: proximityUUID, identifier: identifier)
    }
    
    override init(proximityUUID: UUID, major: CLBeaconMajorValue, identifier: String) {
        super.init(proximityUUID: proximityUUID, major: major, identifier: identifier)
    }
    
    override init(proximityUUID: UUID, major: CLBeaconMajorValue, minor: CLBeaconMinorValue, identifier: String) {
        super.init(proximityUUID: proximityUUID, major: major, minor: minor, identifier: identifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var hashValue: Int {
        get {
            return self.identifier.hashValue
        }
    }
    
    override var description: String {
        return identifier
    }
    
}

func == (lhs: HotelBeaconRegion, rhs: HotelBeaconRegion) -> Bool {
    return (lhs.hashValue == rhs.hashValue)
}
