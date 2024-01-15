//
//  Messages.swift
//  YikesEngine
//
//  Created by Manny Singh on 12/8/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import ObjectMapper

class CL_AccessCredentials : Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x67 }
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    var initializationVector : [UInt8] = []
    var payload : [UInt8] = []
    
    var description: String {
        var desc = "Name: CL_AccessCredentials"
        if let mid = messageID, let mv = messageVersion {
            desc.append("\nID: \(String(format: "%02X", mid))")
            desc.append("\nMessageVersion: \(String(format: "%02X", mv))")
            desc.append("\nIV: \(Message.bytesToHexString(initializationVector))")
            desc.append("\nPayload: \(Message.bytesToHexString(payload))")
        }
        return desc
    }
    
    override func mapping(_ map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        initializationVector    <- map[start: 2, length: 16]
        payload                 <- map[toEndFrom: 18]
    }
    
}

class PL_AccessCredentials : Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x68 }
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    // see http://stackoverflow.com/questions/36160934/type-of-optionals-cannot-be-inferred-correctly-in-swift-2-2
    var PL_random : [UInt8] = []
    var initializationVector : [UInt8] = []
    var payload : [UInt8] = []
    
    var description: String {
        var desc = "Name: PL_AccessCredentials"
        if let mid = messageID, let mv = messageVersion {
            desc.append("\nID: \(String(format: "%02X", mid))")
            desc.append("\nMessageVersion: \(String(format: "%02X", mv))")
            desc.append("\nPL_Random: \(Message.bytesToHexString(PL_random))")
            desc.append("\nIV: \(Message.bytesToHexString(initializationVector))")
            desc.append("\nPayload: \(Message.bytesToHexString(payload))")
        }
        return desc
    }
    
    override func mapping(_ map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        PL_random               <- map[start: 2, length: 4]
        initializationVector    <- map[start: 6, length: 16]
        payload                 <- map[toEndFrom: 22]
    }
    
}

class LP_Verify : Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x69 }
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    var initializationVector : [UInt8] = []
    var payload : [UInt8] = []
    
    var description: String {
        var desc = "Name: LP_Verify"
        if let mid = messageID, let mv = messageVersion {
            desc.append("\nID: \(String(format: "%02X", mid))")
            desc.append("\nMessageVersion: \(String(format: "%02X", mv))")
            desc.append("\nIV: \(Message.bytesToHexString(initializationVector))")
            desc.append("\nPayload: \(Message.bytesToHexString(payload))")
        }
        return desc
    }
    
    static let decrypted_payload_length = 8
    
    override func mapping(_ map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        initializationVector    <- map[start: 2, length: 16]
        payload                 <- map[toEndFrom: 18]
    }
    
}

class PL_Verify : Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x6A }
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    var initializationVector : [UInt8] = []
    var payload : [UInt8] = []
    
    var description: String {
        var desc = "Name: PL_Verify"
        if let mid = messageID, let mv = messageVersion {
            desc.append("\nID: \(String(format: "%02X", mid))")
            desc.append("\nMessageVersion: \(String(format: "%02X", mv))")
            desc.append("\nIV: \(Message.bytesToHexString(initializationVector))")
            desc.append("\nPayload: \(Message.bytesToHexString(payload))")
        }
        return desc
    }
    
    override func mapping(_ map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        initializationVector    <- map[start: 2, length: 16]
        payload                 <- map[toEndFrom: 18]
    }
    
}

class LC_Report : Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x6E }
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    var payloadLength : UInt8?
    var initializationVector : [UInt8] = []
    var payload : [UInt8] = []
    
    var description: String {
        var desc = "Name: LC_Report"
        if let mid = messageID, let mv = messageVersion, let pll = payloadLength {
            desc.append("\nID: \(String(format: "%02X", mid))")
            desc.append("\nMessageVersion: \(String(format: "%02X", mv))")
            desc.append("\nMessageLength: \(String(format: "%02X", pll))")
            desc.append("\nInitializationVector: \(Message.bytesToHexString(initializationVector))")
            desc.append("\nPayload: \(Message.bytesToHexString(payload))")
        }
        return desc
    }
    
    override func mapping(_ map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        payloadLength           <- map[start: 2, length: 1]
        initializationVector    <- map[start: 3, length: 16]
        payload                 <- map[start:19, length: Int(payloadLength!)]
    }
    
}

class CL_ReportAck : Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x6F }
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    var initializationVector : [UInt8] = []
    var encryptedPayload : [UInt8] = []
    
    var description: String {
        var desc = "Name: LC_Report"
        if let mid = messageID, let mv = messageVersion {
            desc.append("\nID: \(String(format: "%02X", mid))")
            desc.append("\nMessageVersion: \(String(format: "%02X", mv))")
            desc.append("\nInitializationVector: \(Message.bytesToHexString(initializationVector))")
            desc.append("\nEncryptedPayload: \(Message.bytesToHexString(encryptedPayload))")
        }
        return desc
    }
    
    override func mapping(_ map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        initializationVector    <- map[start: 2, length: 16]
        encryptedPayload        <- map[start:18, length: 16]
    }
    
}

class LC_TimeSyncRequest : Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x6C }
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    var initializationVector : [UInt8] = []
    var payload : [UInt8] = []
    
    var description: String {
        var desc = "Name: LC_TimeSyncRequest"
        if let mid = messageID, let mv = messageVersion {
            desc.append("\nID: \(String(format: "%02X", mid))")
            desc.append("\nMessageVersion: \(String(format: "%02X", mv))")
            desc.append("\nIV: \(Message.bytesToHexString(initializationVector))")
            desc.append("\nPayload: \(Message.bytesToHexString(payload))")
        }
        return desc
    }
    
    override func mapping(_ map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        initializationVector    <- map[start: 2, length: 16]
        payload                 <- map[toEndFrom: 18]
    }
    
}

class CL_TimeSync : Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x6C }
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    var initializationVector : [UInt8] = []
    var payload : [UInt8] = []
    
    var description: String {
        var desc = "Name: CL_TimeSync"
        if let mid = messageID, let mv = messageVersion {
            desc.append("\nID: \(String(format: "%02X", mid))")
            desc.append("\nMessageVersion: \(String(format: "%02X", mv))")
            desc.append("\nIV: \(Message.bytesToHexString(initializationVector))")
            desc.append("\nPayload: \(Message.bytesToHexString(payload))")
        }
        return desc
    }
    
    override func mapping(_ map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        initializationVector    <- map[start: 2, length: 16]
        payload                 <- map[toEndFrom: 18]
    }
    
}

class LP_Disconnect : Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x6B }
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    
    /**
     1 = Proximity - the yLink determined that the connected phone was not within the RSSI limit for proximity
     
     2 = Inside - the yLink determined that the connected phone was inside relative to the yLink
     
     3 = Closed - based on the credentials it received, the yLink determined that it is closed hours for the room/amenity to which the yLink grants access
     
     4 = Not Active - based on the credentials it received, the yLink determined that the credentials are not yet active (i.e. the good-starting date/time is in the future)
     
     5= Expired - based on the credentials it received, the yLink determined that the credentials have expired (i.e. the good-until date/time has passed)
     
     6 = Superseded - based on the credentials it received and the previous valid credentials it received, the yLink determined that the credentials it just received are no longer valid
     
     7 = Fatal - a yLink that needs fixing will make an attempt to indicate a disconnect reason code of 7 for FATAL
     */
    
    var disconnectReason : UInt8?
    
    var description: String {
        var desc = "Name: LP_Disconnect"
        if let mid = messageID, let mv = messageVersion, let dr = disconnectReason {
            desc.append("\nID: \(String(format: "%02X", mid))")
            desc.append("\nMessageVersion: \(String(format: "%02X", mv))")
            desc.append("\nDisconnectReason Code: \(String(format: "%02X", dr))")
        }
        return desc
    }
    
    override func mapping(_ map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        disconnectReason        <- map[start: 2, length: 1]
    }
    
}


class LP_Debug : Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x78 }
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    var messageLength : UInt8?
    var debugMessage : [UInt8] = []
    
    var description: String {
        var desc = "Name: LP_Debug"
        if let mid = messageID, let mv = messageVersion, let ml = messageLength {
            desc.append("\nID: \(String(format: "%02X", mid))")
            desc.append("\nMessageVersion: \(String(format: "%02X", mv))")
            desc.append("\nMessageLength: \(String(format: "%02X", ml))")
            desc.append("\nDebugMessage: \(Message.bytesToHexString(debugMessage))")
        }
        return desc
    }
    
    override func mapping(_ map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        messageLength           <- map[start: 2, length: 1]
        debugMessage            <- map[start: 3, length: Int(messageLength!)]
    }
    
}

