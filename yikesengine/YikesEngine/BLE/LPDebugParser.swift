//
//  LPDebugParser.swift
//  YikesEngineSP
//
//  Created by Manny Singh on 8/3/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

class LPDebugParser {
    
    class func findInsideOutside(_ connection:BLEConnection) -> Bool {
        
        guard let debugMessage = connection.debugMessage else {
            return false
        }
        
        let prevLocation = connection.inOutLocation
        
        if debugMessage.lowercased().range(of: ",outside") != nil {
            connection.inOutLocation = .outside
            
        } else if debugMessage.lowercased().range(of: ",inside") != nil {
            connection.inOutLocation = .inside
        }
        
        // only return true if location changed
        if prevLocation != connection.inOutLocation {
            return true
        }
        
        return false
    }
    
}
