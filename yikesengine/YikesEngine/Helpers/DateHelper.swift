//
//  DateHelper.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/23/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

class DateHelper {
    
    static let sharedInstance = DateHelper()
    
    var calender : Calendar
    let simpleUTCDateFormatter = DateFormatter()
    let simpleUTCDateFormatterWithTime = DateFormatter()
    
    let simpleDateFormatterWithTime = DateFormatter()
    let simpleDateFormatterWithMilliSec = DateFormatter()
    let simpleDateFormatterWithTimeZone = DateFormatter()
    
    let dateFormatterWithMilliSec = DateFormatter()
    let minuteSecondMilliSecondFormatter = DateFormatter()
    let hourMinuteSecondFormatter = DateFormatter()
    
    init() {
        
        calender = Calendar.current
        
        simpleUTCDateFormatter.dateFormat = "yyyy-MM-dd"
        
        simpleUTCDateFormatterWithTime.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        simpleDateFormatterWithTime.dateFormat = "yyyy-MM-dd HH:mm:ss"
        simpleDateFormatterWithMilliSec.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        simpleDateFormatterWithTimeZone.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
        
        dateFormatterWithMilliSec.dateFormat = "MM-dd HH:mm:ss.SSS"
        minuteSecondMilliSecondFormatter.dateFormat = "mm:ss:SSS"
        hourMinuteSecondFormatter.dateFormat = "HH:mm:ss"
    }
    
    func daysBetweenDates(startDate: Date, endDate: Date) -> Int
    {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return components.day!
    }
    
    func isDate(date compareDate: Date, betweenDate earlierDate: Date, andDate laterDate: Date) -> Bool {
        
        if compareDate.compare(earlierDate) == .orderedDescending {
            
            if compareDate.compare(laterDate) == .orderedAscending {
                return true
            }
        }
        
        return false
    }
    
    func mergeTimeWithDate(_ date: Date, timeString: String, timezone: TimeZone? = TimeZone.autoupdatingCurrent) -> Date? {
        
        let timeComps = timeString.components(separatedBy: ":")
        
        if timeComps.count >= 2 {
            
            let hourString = timeComps[0]
            let minuteString = timeComps[1]
            
            var dateComps = DateComponents()
            dateComps.timeZone = timezone
            dateComps = self.calender.dateComponents([.year, .month, .day], from: date)
            
            dateComps.hour = Int(hourString)!
            dateComps.minute = Int(minuteString)!
            
            let dateWithTime = self.calender.date(from: dateComps)
            return dateWithTime
        }
        
        return nil
    }
    
}
