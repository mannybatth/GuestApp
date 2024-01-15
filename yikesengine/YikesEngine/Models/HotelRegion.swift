//
//  HotelRegion.swift
//  YikesEngineSP
//
//  Created by Roger Mabillard on 2016-05-27.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import CoreLocation

class HotelRegion {
    
    var majorNumber : Int?
    var globalRegion : HotelBeaconRegion                // global region with no major/minor
    var subRegionSet : Set <HotelBeaconRegion> = Set()  // sub regions with major number + incrementing minor number
    
    init(globalRegion: HotelBeaconRegion) {
        self.globalRegion = globalRegion
    }
    
    func updateLocationState(_ newState: CLRegionState, beaconRegion: CLRegion) {
        
        for subRegion in subRegionSet {
            if subRegion == beaconRegion {
                subRegion.currentState = newState
                return
            }
        }
        
        if globalRegion == beaconRegion {
            globalRegion.currentState = newState
        }
    }
    
    func isInside() -> Bool {
        return globalRegion.currentState == .inside
    }
    
    func initSubRegionsWithMajorNumber(_ majorNumber : Int) {
        
        self.majorNumber = majorNumber
        
        var subRegions = Set<HotelBeaconRegion>()
        let identifier = EngineConstants.YIKES_SP_BEACON_IDENTIFIER
        
        guard let beacon = YKSSessionManager.sharedInstance.currentUser?.beacon,
            let beaconUUID = beacon.uuid,
            let proximityUUID = UUID(uuidString: beaconUUID) else {
            
                yLog(LoggerLevel.error, category: LoggerCategory.Location, message: "[Location] Not creating sub regions. Required pieces are missing.")
                return
        }
        
        let region_count = beacon.regionCount ?? 0
        
        yLog(LoggerLevel.debug, category: LoggerCategory.Location, message: "[Location] Creating \(region_count) sub-regions")
        
        for i in 1...region_count {
            
            // each sub-regions MUST have it's own unique identifier so the app gets notified correctly of entry and exit events.
            let subIdentifier = identifier + "\(i)"
            let subRegion = HotelBeaconRegion(proximityUUID: proximityUUID as UUID, major: UInt16(majorNumber), minor: UInt16(i), identifier: subIdentifier)
            
            // This should allow us to not exit if it's a subregion (we are tracking the Global region, which doesn't care about major / minor values.
            subRegion.notifyOnExit = false
            subRegion.notifyEntryStateOnDisplay = false
            
            subRegions.insert(subRegion)
        }
        
        self.subRegionSet = subRegions
    }
}
