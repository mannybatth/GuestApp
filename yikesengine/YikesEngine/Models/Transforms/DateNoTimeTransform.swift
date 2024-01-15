//
//  DateNoTimeTransform.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/23/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

open class DateNoTimeTransform: TransformType {
    public typealias Object = Date
    public typealias JSON = String
    
    public init() {}
    
    open func transformFromJSON(_ value: Any?) -> Date? {
        if let dateString = value as? String {
            return DateHelper.sharedInstance.simpleUTCDateFormatter.date(from: dateString)
        }
        return nil
    }
    
    open func transformToJSON(_ value: Date?) -> String? {
        if let date = value {
            return DateHelper.sharedInstance.simpleUTCDateFormatter.string(from: date)
        }
        return nil
    }
}
