//
//  DataMapper.swift
//  YikesEngine
//
//  Created by Manny Singh on 12/8/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import ObjectMapper

/**
 
 Sept 02, 2016:
 Note: Removed support for byte data types other than type UInt of size 8
 when the project was converted to Swift 3. Adding support for other types and sizes
 (like UInt16,etc.) wasnt' necessary and would require a different approach.
 Something similar to this should help if the requirement changes:
 http://stackoverflow.com/a/33225643/514845
 (Adapting the UnsafeBufferPointer type to the type wanted in the left operand will
 move the pointer as expected in the buffer)
 
 */

func copyValueTo<T>(_ field: inout T, object: T?) {
    if let value = object {
        field = value
    }
}

func copyValueTo<T>(_ field: inout T?, object: T?) {
    if let value = object {
        field = value
    }
}

func <- <T>(left: inout T, right: DataMap) {
    if right.dataMappingType == DataMappingType.fromData {
        
        // convert Data to values here
        
        let data: Data = right.currentDataValue!
        
        switch left {
            
        case is UInt8:
            
            copyValueTo(&left, object: data.convertToBytes().first! as? T)
            
        case is [UInt8]:
            
            copyValueTo(&left, object: data.convertToBytes() as? T)
            
        case is String:
            
            let string = String(data: data, encoding: String.Encoding.utf8)
            copyValueTo(&left, object: string as? T)
            
        default:
            copyValueTo(&left, object: right.currentDataValue as? T)
        }
        
    } else {
        
        // convert values to Data here
        
        var data: Data
        
        switch left {
        case let byte as UInt8:
            data = Data(bytes: UnsafePointer<UInt8>([byte] as [UInt8]), count: 1)
            
        case let bytes as [UInt8]:
            data = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
            
        case let str as String:
            data = str.data(using: String.Encoding.utf8)!
            
        default:
            data = left as! Data
        }
        
        right.rawData?.append(data)
    }
}



func <- <T>(left: inout T?, right: DataMap) {
    if right.dataMappingType == DataMappingType.fromData {
        
        // convert Data to values here
        
        let data: Data = right.currentDataValue!
        
        switch left {
        case is UInt8?:
            
            copyValueTo(&left, object: data.convertToBytes().first! as? T)
            
        case is [UInt8]?:
            
            copyValueTo(&left, object: data.convertToBytes() as? T)
            
        case is String?:
            
            let string = String(data: data, encoding: String.Encoding.utf8)
            copyValueTo(&left, object: string as? T)
            
        default:
            copyValueTo(&left, object: right.currentDataValue as? T)
        }
        
    } else {
        
        // convert values to Data here
        
        var data: Data
        
        if (left != nil) {
            
            switch left {
            case let byte as UInt8?:
                data = Data(bytes: UnsafePointer<UInt8>([byte!] as [UInt8]), count: 1)
                
            case let bytes as [UInt8]?:
                data = Data(bytes: UnsafePointer<UInt8>(bytes!), count: bytes!.count)
                
            case let str as String?:
                data = str!.data(using: String.Encoding.utf8)!
                
            default:
                data = left as! Data
            }
            
        } else {
            
            let bytes = [UInt8](repeating: 0, count: right.currentLength!)
            data = Data(bytes: UnsafePointer<UInt8>(bytes), count: right.currentLength!)
            
        }
        
        right.rawData?.append(data)
    }
}

enum DataMappingType {
    case fromData
    case toData
}

class DataMap {
    
    let dataMappingType: DataMappingType
    
    var rawData: Data?
    
    var currentStart: Int?
    var currentLength: Int?
    var currentDataValue: Data?
    
    init(mappingType: DataMappingType, rawData: Data) {
        self.dataMappingType = mappingType
        self.rawData = Data(bytes: rawData.bytes, count: rawData.count)
    }
    
    subscript(start start: Int, length length: Int) -> DataMap {
        currentStart = start
        currentLength = length
        if (dataMappingType == .fromData) {
            currentDataValue = rawData![start: start, length: length] as Data
        }
        return self
    }
    
    subscript(toEndFrom start: Int) -> DataMap {
        currentStart = start
        currentLength = rawData!.count
        if (dataMappingType == .fromData) {
            currentDataValue = rawData![start: start, length: rawData!.count] as Data
        }
        return self
    }
    
}

protocol DataMappable {
    init?(_ map: DataMap)
    mutating func mapping(_ map: DataMap)
}


class Message : DataMappable {
    
    class var identity : UInt8 { return 0x00 }
    class var version : UInt8 { return 0x01 }
    
    init() {}
    required init?(_ map: DataMap) {}
    func mapping(_ map: DataMap) {}
    
    var rawData : Data? {
        let dataMap = DataMap(mappingType: .toData, rawData: Data())
        self.mapping(dataMap)
        return dataMap.rawData
    }
    
    convenience init?(rawData: Data) {
        let dataMap = DataMap(mappingType: .fromData, rawData: rawData)
        self.init(dataMap)
        self.mapping(dataMap)
    }
    
    class func isThisMessageType(_ rawData: Data) -> Bool {
        
        if let firstByte = rawData.convertToBytes().first {
            if firstByte == self.identity {
                return true
            }
        }
        return false
    }
    
    class func bytesToHexString(_ bytes: [UInt8]) -> String {
        return bytes.map{String(format: "%02X", $0)}.joined(separator: "")
    }
    
    class func generateRandomBytes(_ length: Int) -> [UInt8] {
        
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return bytes
    }
    
}

