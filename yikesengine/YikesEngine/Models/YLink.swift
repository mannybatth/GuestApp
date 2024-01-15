//
//  YLink.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/23/15.
//  Copyright Â© 2015 yikes. All rights reserved.
//

import Foundation
import CoreBluetooth
import YikesSharedModel

class YLink: Hashable, Equatable, CustomStringConvertible {
    
    var stay : Stay
    var amenity : Amenity?
    var connections : [BLEConnection] = []
    
    var debugMode : Bool = false
    var shouldConnect : Bool = true
    
    var description : String {
        return String("\nyLink: \(self.macAddress)\nname: \((self.roomNumber != nil) ? self.roomNumber! : "?")")
    }
    
    var writeCharacteristic : CBCharacteristic?
    var debugMessageCharacteristic : CBCharacteristic?
    
    var isGuestRoom : Bool {
        return amenity == nil
    }
    
    var isAmenity : Bool {
        return amenity != nil
    }
    
    var uuid : CBUUID? {
        if let macAddress = macAddress {
            let data = macAddress.dataFromHexadecimalString()
            if macAddress.characters.count == 12 && data?.count == 6 {
                return CBUUID(string: "A249B350-F112-E988-2015-\(macAddress)")
            }
        }
        return nil
    }
    
    var macAddress : String? {
        if isAmenity {
            return amenity?.macAddress
        }
        return stay.macAddress
    }
    
    var activeConnection : BLEConnection? {
        
        for connection in connections.reversed() {
            if (connection.end == nil) {
                return connection
            }
        }
        
        return nil
    }
    
    var roomNumber : String? {
        if isGuestRoom {
            return stay.roomNumber
        } else if isAmenity {
            return amenity?.name
        }
        return nil
    }
    
    var roomWasRemoved : Bool = false
    
    var credential : Credential? {
        if self.isAmenity {
            if let amenity = self.amenity {
                return self.stay.credentialsForAmenity(amenity)
            }
            else {
                return nil
            }
        }
        else {
            return self.stay.credential
        }
    }
    
    init(stay: Stay) {
        self.stay = stay
    }
    
    init(stay: Stay, amenity: Amenity) {
        self.stay = stay
        self.amenity = amenity
    }
    
    var hashValue: Int {
        if let macAddress = macAddress{
            return macAddress.hashValue
        }
        else {
            return "nil".hashValue
        }
    }
    
    func startNewConnection() {
        
        let connection = BLEConnection(yLink: self)
        connection.startConnection()
        self.connections.append(connection)
    }
    
    func changeConnectionStatus(_ status: YKSConnectionStatus) {
        if isGuestRoom {
            
            // TODO: Investigate why YLink.stay is not the pointing to the same address as stay in SessionManager
            if let matchingStay = YKSSessionManager.sharedInstance.currentUser?.stays.filter({ $0.stayId == stay.stayId }).first {
                matchingStay.connectionStatus = status
                stay = matchingStay
            }
            
        } else if isAmenity {
            
            // Change connection status of all amenities with the same id
            if let stays = YKSSessionManager.sharedInstance.currentUser?.stays {
                for stay in stays {
                    
                    if let matchingAmenity = stay.amenities.filter({ $0.amenityId == amenity?.amenityId }).first {
                        matchingAmenity.connectionStatus = status
                        amenity = matchingAmenity
                    }
                }
            }
            
        }
    }
    
    func verifyConnectionStatus() {
        guard let activeConnection = activeConnection else {
            changeConnectionStatus(YKSConnectionStatus.disconnectedFromDoor)
            return
        }
        
        if activeConnection.peripheral?.state != CBPeripheralState.connected &&
            activeConnection.peripheral?.state != CBPeripheralState.connecting {
                changeConnectionStatus(YKSConnectionStatus.disconnectedFromDoor)
        }
    }
    
    func fireLocalNotification (_ message:String) {
        if YKSSessionManager.sharedInstance.currentUser?.email == "roger@yamm.ca" {
            let localNotif = UILocalNotification()
            localNotif.alertBody = String("\(message)");
            localNotif.alertAction = NSLocalizedString("Relaunch", comment: "Relaunch")
            localNotif.soundName = UILocalNotificationDefaultSoundName;
            UIApplication.shared.presentLocalNotificationNow(localNotif)
        }
    }
}

func == (lhs: YLink, rhs: YLink) -> Bool {
    
    return (lhs.macAddress == rhs.macAddress)
}

extension Set where Element:YLink {
    
    func uuids() -> [CBUUID] {
        return filter { $0.uuid != nil }.map { $0.uuid! }
    }
    
}
