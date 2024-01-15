//
//  BLEConnection.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/10/16.
//  Copyright Â© 2016 yikes. All rights reserved.
//

import Foundation
import CoreBluetooth
import YikesSharedModel

struct HandshakeInfo {
    
    var PL_random : [UInt8]
    var initializationVector : [UInt8]
    
}

class BLEConnection: CustomStringConvertible {
    
    //MARK: ENUM & Properties
    
    enum ConnectionEndReason : String {
        case Unknown            = ""
        case Proximity          = "proximity"
        case Inside             = "inside"
        case Closed             = "closed"
        case NotActive          = "notActive"
        case Expired            = "expired"
        case Superseded         = "superseded"
        case EngineStopped      = "engineOff"
        case FailedToConnect    = "failConnect"
        case TimedOut           = "timedOut"
        case Fatal              = "fatal"
        case Stationary         = "stationary"
        case NoAccess           = "noAccess"
        case UserForced         = "UserForced"
    }
    
    var yLink : YLink
    var peripheral : CBPeripheral?
    var mostRecentRSSI : Int?
    var minConnectRSSI : Int?
    var lp_random : [UInt8]?
    var pl_random : [UInt8]?
    
    var timeOfLastAdvert : Date?
    var initialDiscovery: Bool = false
    var initialDiscoveryTimer: Timer?
    
    var connectionTimer: Timer?
    
    var writingPLVerify = false
    var writingLCReportAck = false
    
    var reportOperation: YLinkReportOperation?
    var reportsTimer: Timer?
    var reportsDelay: TimeInterval = 2.0
    static let blacklistedReportingTimeInterval:TimeInterval = 60
    
    // used to be 6.5s for yMan in MP:
    var connectionTimeAllowed: TimeInterval = 2.0
    var connectionRequestStartedOn: Date?
    var connectionRequestCompletedOn: Date?
    
    var charUpdateReceivedForLP_Verify: Bool = false
    
    var connectionStartedOn : Date?
    var isSuccessfulOn : Date?
    var isSuccessful : Bool = false {
        
        didSet {
            if (oldValue == false && isSuccessful) {
                // got connected to door:
                self.roomConnectionStatusDidChange(.connectedToDoor)
            }
            else if (oldValue == true && !isSuccessful){
                // got disconnected from door:
                self.roomConnectionStatusDidChange(.disconnectedFromDoor)
            }
            updateConnection()
        }
    }
    
    var start : Date!
    var end : Date?
    var connectionEndReason : ConnectionEndReason = .Unknown
    var handshakeInfo : HandshakeInfo?
    
    var lc_time_sync_request : Data?
    var lc_report : Data?
    var lp_disconnect : Data?
    var lp_debug : Data?
    var debugMessage : String?
    
    enum InOut {
        case unknown
        case inside
        case outside
    }
    
    var inOutLocation : InOut = .unknown
    
    var description: String {
        let peripheral = self.peripheral?.name ?? "Not Found"
        let desc = "Connection to \(self.yLink.description) peripheral: \(peripheral)"
        return desc
    }
    
    //MARK: Methods
    
    init(yLink: YLink) {
        self.yLink = yLink
    }
    
    func startConnection() {
        start = Date()
        DebugManager.sharedInstance.connectionDidStart(self)
    }
    
    func updateConnection() {
        DebugManager.sharedInstance.connectionDidUpdate(self)
    }
    
    func hasEnded() -> Bool {
        if self.end == nil {
            return false
        }
        else {
            return true
        }
    }
    
    func endConnection() {
        end = Date()
        isSuccessful = false
        writingPLVerify = false
        self.cancelConnectionTimer()
        self.cancelReportsTimer()
        DebugManager.sharedInstance.connectionDidEnd(self)
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Ending connection for \((yLink.description))")
    }
    
    func didDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber) {
        self.peripheral = peripheral
        self.mostRecentRSSI = RSSI.intValue
        self.initialDiscovery = true
        updateConnection()
        CentralManager.sharedInstance.checkCredentialsForConnection(self)
    }
    
    func startReportOperation() {
        if let writeCharacteristic = self.yLink.writeCharacteristic {
            self.reportOperation = YLinkReportOperation.init(connection:self, writeCharacteristic:writeCharacteristic)
        }
        else {
            yLog(.error, message:"No reference for the yLink writeCharacteristic - Cannot start a reportOperation for connection \(self)")
        }
    }
    
    /**
     Do not use in Guest App unless you want to pull reports periodically by sending PL_GetReport messages to the yLink.
     */
    func scheduleConnectionTimer() {
        connectionRequestStartedOn = Date()
        yLog(message: "Connection interval is \(self.connectionTimeAllowed) seconds")
        DispatchQueue.main.async {
            self.cancelConnectionTimer()
            self.connectionTimer = Timer.scheduledTimer(timeInterval: self.connectionTimeAllowed, target: self, selector: #selector(BLEConnection.cancelConnectionRequest), userInfo: nil, repeats: false)
        }
    }
    
    func cancelConnectionTimer() {
        if let startedOn = self.connectionRequestStartedOn,
            let completedOn = self.connectionRequestCompletedOn {
            let time = completedOn.timeIntervalSince(startedOn)
            yLog(message: "Connection request completed in \(time) seconds for connection \(self)")
        }
        self.connectionTimer?.invalidate()
        self.connectionTimer = nil
    }
    
    func scheduleReportsTimer() {
        DispatchQueue.main.async {
            self.cancelReportsTimer()
            // repeat pullReports every "reportsDelay" until the connection drops:
            self.reportsTimer = Timer.scheduledTimer(timeInterval: self.reportsDelay, target: self, selector: #selector(BLEConnection.pullReports), userInfo: nil, repeats: true)
        }
    }
    
    func cancelReportsTimer() {
        self.reportsTimer?.invalidate()
        self.reportsTimer = nil
    }
    
    @objc func pullReports() {
        yLog(message: "\n\n############################### \n\nPulling reports for \(self.yLink)\n\n###############################\n\n")
        if self.peripheral?.state == .connected {
            BLEEngine.sharedInstance.pullReports(connection:self)
        }
        else {
            yLog(.warning, message: "[Reporting] Cannot pull reports for connection \(self) - not connected.")
            self.cancelReportsTimer()
            self.endReportOperation()
        }
    }
    
    func endReportOperation() {
        self.reportOperation = nil
    }
    
    @objc func cancelConnectionRequest() {
        
        yLog(message: "\n\n############################### \n\ncancelConnectionRequest received for connection \(self)\n\n###############################\n\n")
        
        if self.peripheral?.state == .connecting {
            yLog(message: "Connection request started at \(self.connectionRequestStartedOn)")
            yLog(message: "Connection request being cancelled at \(Date())")
            if let startedOn = self.connectionRequestStartedOn {
                let interval = Date().timeIntervalSince(startedOn)
                yLog(message: "Connection request time allowed was \(interval) seconds")
            }
            self.cancelPeripheralConnection()
        }
    }
    
    func cancelPeripheralConnection() {
        if let peripheral = self.peripheral {
            if let rn = self.yLink.roomNumber, let stay = self.yLink.stay.stayId {
                yLog(message: "Canceling peripheral connection for \(stay):\(rn)")
            }
            BLEEngine.sharedInstance.centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func roomConnectionStatusDidChange(_ status:YKSConnectionStatus, reason: YKSDisconnectReasonCode = .unknown) {
        
        yLink.changeConnectionStatus(status)
        
        if let room = self.yLink.roomNumber {
            
            if status == YKSConnectionStatus.scanningForDoor {
                if self.connectionStartedOn == nil {
                    yLog(LoggerLevel.info, category: LoggerCategory.BLE, message: "[ConnectionStatus] Room: \(room), Status: \(status.description)")
                    self.connectionStartedOn = Date()
                }
            }
            else {
                yLog(LoggerLevel.info, category: LoggerCategory.BLE, message: "[ConnectionStatus] Room: \(room), Status: \(status.description)")
            }
            
            DispatchQueue.main.async {
                YikesEngineSP.sharedEngine().delegate?.yikesEngineRoomConnectionStatusDidChange?(status, withRoom: room, disconnectReasonCode: reason)
            }
        }
    }
    
    internal func credentialsExpired() -> Bool {
        return self.yLink.stay.credentialsExpired() 
    }
}


func == (lhs: BLEConnection, rhs: BLEConnection) -> Bool {
    return (lhs.yLink == rhs.yLink)
}
