//
//  TimeZoneTransform.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/25/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import ObjectMapper

open class TimeZoneTransform: TransformType {
    public typealias Object = TimeZone
    public typealias JSON = String
    
    public init() {}
    
    open func transformFromJSON(_ value: Any?) -> TimeZone? {
        if let timezoneString = value as? String {
            return TimeZone(identifier: timezoneString)
        }
        return nil
    }
    
    open func transformToJSON(_ value: TimeZone?) -> String? {
        if let timezone = value {
            return timezone.identifier
        }
        return nil
    }
}
