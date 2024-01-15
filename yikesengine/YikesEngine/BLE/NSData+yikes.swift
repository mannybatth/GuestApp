//
//  Data+yikes.swift
//  yDependencies
//
//  Created by Roger Mabillard on 2016-02-23.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

public extension Data {
    public subscript(start start: Int, length length: Int) -> Data {
        
        var len = length
        
        if start > self.count-1 {
            return Data()
        }
        
        if start + len > self.count {
            len = self.count - start
        }
        return self.subdata(in: start..<start+len)
    }
    
    public func hexadecimalString() -> String {
        var string = ""
        var byte: UInt8 = 0
        
        for i in 0 ..< self.count {
            copyBytes(to: &byte, from: i..<i+1)
            string += String(format: "%02x", byte)
        }
        
        return string
    }
    
    public func convertToBytes() -> [UInt8] {
        
        let count = self.count / MemoryLayout<UInt8>.size
        var bytes = [UInt8](repeating: 0, count: count)
        (self as Data).copyBytes(to: &bytes, count: count * MemoryLayout<UInt8>.size)
        return bytes
    }
    
    public func convertToSignedBytes() -> [Int8] {
        
        let count = self.count / MemoryLayout<Int8>.size
        var bytes = [UInt8](repeating: 0, count: count)
        (self as Data).copyBytes(to: &bytes, count:count * MemoryLayout<Int8>.size)
        
        let signedBytes = bytes.map { signed in Int8(signed) }
        
        return signedBytes
    }
}
