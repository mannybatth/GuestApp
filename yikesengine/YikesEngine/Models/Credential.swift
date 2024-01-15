//
//  Credential.swift
//  YikesEngine
//
//  Created by Manny Singh on 12/11/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation
import YikesSharedModel
import ObjectMapper

class Credential: Mappable, CustomStringConvertible {
    
    var CL_AccessCredential : String?

    var proximityRSSI : Int?
    var goodStartingUTC : Double?
    var goodUntilUTC : Double?
    var CPL_SharedEncryptionKey : String?
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        CL_AccessCredential     <- map["cl_access_credential"]
        proximityRSSI           <- map["cp_access_credential.proximity_rssi"]
        goodStartingUTC         <- map["cp_access_credential.good_starting_utc"]
        goodUntilUTC            <- map["cp_access_credential.good_until_utc"]
        CPL_SharedEncryptionKey <- map["cp_access_credential.cpl_shared_encryption_key"]
    }
    
    var description: String {
        let goodStarting = goodStartingDate()?.description
        let goodUntil = goodUntilDate()?.description
        return "goodStarting: \(goodStarting != nil ? goodStarting! : "nil"), goodUntil: \(goodUntil != nil ? goodUntil! : "nil")"
    }
    
    func goodUntilDate () -> Date? {
        if let goodUntilTS = self.goodUntilUTC {
            let date = Date(timeIntervalSince1970: TimeInterval(goodUntilTS))
            return date
        }
        return nil
    }
    
    func goodStartingDate () -> Date? {
        if let goodStartingTS = self.goodStartingUTC {
            let date = Date(timeIntervalSince1970: TimeInterval(goodStartingTS))
            return date
        }
        return nil
    }
    
    func credentialsAboutToExpire () -> Bool {
        
        if let goodUntilDate = self.goodUntilDate() {
            
            let lifespan = self.credentialLifeSpan()
            
            if lifespan < 5*60 {
                // if only 60 seconds left, credentials are about to expire:
                if goodUntilDate.timeIntervalSinceNow <= 30 {
                    return true
                }
            }
            else {
                // if only 60 seconds left, credentials are about to expire:
                if goodUntilDate.timeIntervalSinceNow <= 60 {
                    return true
                }
            }
            
            
        }
        return false
    }
    
    func credentialsExpired () -> Bool {
        let now = Date()
        if let goodUntilDate = self.goodUntilDate() {
            // if the time interval since goodUntilDate until now is positive, the credentials have expired
            if now.timeIntervalSince(goodUntilDate) >= 0 {
                return true
            }
        }
        return false
    }
    
    func credentialLifeSpan() -> TimeInterval {
        
        guard let goodUntilDate = self.goodUntilDate(), let goodStartingDate = self.goodStartingDate() else {
            return 0
        }
        
        let lifeSpan = goodUntilDate.timeIntervalSince(goodStartingDate)
        
        return lifeSpan
    }
    
    func credentialsExpireSoon () -> Bool {
        
        let now = Date()
        var lifeSpan = self.credentialLifeSpan()
        if (lifeSpan < 60) {
            // protect against negative, 0 or less than 1 minute lifespan values:
            lifeSpan = 60
        }
        
        guard let goodUntilDate = self.goodUntilDate() else {
            return false
        }
        
        let interval15seconds = TimeInterval(15)
        let interval1minute = TimeInterval(60*1)
        let interval5minutes = TimeInterval(60*5)
        let interval15minutes = TimeInterval(60*15)
        let interval30minutes = TimeInterval(60*30)
        let interval1hour = TimeInterval(60*60*1)
        let interval4hours = TimeInterval(60*60*4)
        let interval24hours = TimeInterval(60*60*24)
        
        let expireTimeInterval = goodUntilDate.timeIntervalSince(now)
        // already expired...
        if expireTimeInterval <= 0 {
            return true
        }
            
        else {
            
            var expireSoon:Bool = false
            
            // min credential life span is 1 min in yC DB
            if lifeSpan <= interval1minute {
                if expireTimeInterval <= interval15seconds {
                    expireSoon = true
                }
            }
            else if lifeSpan <= interval5minutes {
                if expireTimeInterval <= interval1minute {
                    expireSoon = true
                }
            }
            else if lifeSpan <= interval30minutes {
                if expireTimeInterval <= interval5minutes {
                    expireSoon = true
                }
            }
            else if lifeSpan <= interval4hours {
                if expireTimeInterval <= interval15minutes {
                    expireSoon = true
                }
            }
            else if lifeSpan <= interval4hours*2 {
                // 8h is the default lifespan on yC, so let's optimize that...:
                if expireTimeInterval <= interval30minutes {
                    expireSoon = true
                }
            }
            else if lifeSpan <= interval24hours {
                if expireTimeInterval <= interval1hour {
                    expireSoon = true
                }
            }
            else {
                // default case - refresh 12h before expiration:
                if expireTimeInterval <= interval1hour*12 {
                    expireSoon = true
                }
            }
            
            return expireSoon
        }
    }
    
}
