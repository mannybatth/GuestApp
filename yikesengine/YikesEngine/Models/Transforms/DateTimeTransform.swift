//
//  DateTimeTransform.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/23/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import ObjectMapper

open class DateTimeTransform: TransformType {
    public typealias Object = Date
    public typealias JSON = String
    
    public init() {}
    
    open func transformFromJSON(_ value: Any?) -> Date? {
        if let dateString = value as? String {
            return DateHelper.sharedInstance.simpleUTCDateFormatterWithTime.date(from: dateString)
        }
        return nil
    }
    
    open func transformToJSON(_ value: Date?) -> String? {
        if let date = value {
            return DateHelper.sharedInstance.simpleUTCDateFormatterWithTime.string(from: date)
        }
        return nil
    }
}
