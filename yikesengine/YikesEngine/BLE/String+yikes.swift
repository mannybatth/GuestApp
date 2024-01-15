//
//  String+yikes.swift
//  yDependencies
//
//  Created by Roger Mabillard on 2016-02-23.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

public extension String {
    
    /// Create NSData from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a NSData object. Note, if the string has any spaces, those are removed. Also if the string started with a '<' or ended with a '>', those are removed, too. This does no validation of the string to ensure it's a valid hexadecimal string
    ///
    /// The use of `strtoul` inspired by Martin R at http://stackoverflow.com/a/26284562/1271826
    ///
    /// - returns: NSData represented by this hexadecimal string. Returns nil if string contains characters outside the 0-9 and a-f range.
    
    public func dataFromHexadecimalString() -> Data? {
        
        let trimmedString = self.trimmingCharacters(in: CharacterSet(charactersIn: "<> ")).replacingOccurrences(of: " ", with: "")
        
        // make sure the cleaned up string consists solely of hex digits, and that we have even number of them
        
        let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)
        
        let found = regex.firstMatch(in: trimmedString, options: [], range: NSMakeRange(0, trimmedString.characters.count))
        if found == nil || found?.range.location == NSNotFound || trimmedString.characters.count % 2 != 0 {
            return nil
        }
        
        // everything ok, so now let's build NSData
        
        var data = Data(capacity: trimmedString.characters.count / 2)
        
        var index = trimmedString.startIndex
        
        while index < trimmedString.endIndex {
            let newIndex = trimmedString.index(index, offsetBy: 2)
            let byteString = trimmedString.substring(with:Range<String.Index>(index..<newIndex))
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data.append([num] as [UInt8], count: 1)
            
            index = newIndex
        }
        
        return data
    }
}
