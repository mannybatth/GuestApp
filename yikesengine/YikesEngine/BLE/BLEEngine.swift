//
//  BLEEngine.swift
//  YikesEngine
//
//  Created by Manny Singh on 12/8/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import AVFoundation
import CoreBluetooth
import CryptoSwift

import YikesSharedModel
import YKSSPLocationManager

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class BLEEngine: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, Observable {
    
    static let sharedInstance = BLEEngine()
    
    enum SecureMode {
        case plainText
        case encrypted
    }
    
    enum StopReason {
        case none
        case stationary
        case noAccess
        case userForcedDisconnect
    }
    
    // Use this to switch between encrypted and unencrypted:
    static var secureMode: SecureMode = .encrypted
    
    var backgroundMinConnectRSSIRelaxing : Int = 5
    
    var connectionThresholdAdjuster : ConnectionThresholdAdjuster!

    var centralManager : CBCentralManager!
    
    var lastScanRestart: Date?
    var currentScanDelay: TimeInterval = 1
    
    let stationaryScanDelay: TimeInterval = 20
    
    override fileprivate init() {
        super.init()
        
        centralManager  = CBCentralManager.init(
            delegate: self,
            queue: self.bleEngineQueue,
            options: [
                CBCentralManagerOptionRestoreIdentifierKey: "centralManagerSP",
                CBCentralManagerOptionShowPowerAlertKey: true
            ])
        
        if let connectionThresholdAdjuster = StoreManager.sharedInstance.restoreYLinksThresholdsFromCache() {
            self.connectionThresholdAdjuster = connectionThresholdAdjuster
        } else {
            self.connectionThresholdAdjuster = ConnectionThresholdAdjuster()
        }
    }
    
    var observers : [Observer] = []
    
    var yLinksBlacklistedForReporting : [String: Date?] = [:]
    
    let bleEngineVersion = 0x01
    
    var state : YKSBLEEngineState = .off
    
    let bleEngineQueue = DispatchQueue(label: "com.yikesteam.BLEEngine", attributes: [])
    var currentPeripheral : CBPeripheral?
    
/**
     List of YLinks that the BLEE should be currently scanning for, assuming the BLEE state is On
*/
    var yLinksScanList:Set<YLink> = Set<YLink>()
    
/**
     This method makes a snapshot of the user current and valid stays then
     returns the list of yLinks based on the access for these stays.
     
     It can be called at any time to get the most updated list of YLinks to scan for.
*/
    func yLinksToScanFor() -> Set<YLink> {
        
        guard let user = YKSSessionManager.sharedInstance.currentUser else {
            yLog(.warning, message: "No current user - returning empty [] yLinksToScanFor")
            return []
        }
        
        return user.yLinksToScanFor
    }
    
/**
     Returns the list of raw UUIDs based on the internal list of yLinks Scan List
*/
    func uuidsToScanFor() -> Set<CBUUID> {
        
        var uuidsToScanFor = Set<CBUUID>()
        
        self.yLinksScanList = self.yLinksToScanFor()
        
        for yLink:YLink in self.yLinksScanList {
            
            if yLink.activeConnection == nil {
                yLink.startNewConnection()
            }
            
            if let peripheral = yLink.activeConnection?.peripheral {
                if peripheral.state == CBPeripheralState.disconnected {
                    if let uuid = yLink.uuid {
                        uuidsToScanFor.insert(uuid)
                    }
                }
            }
            else {
                if let uuid = yLink.uuid {
                    uuidsToScanFor.insert(uuid)
                }
            }
        }
        
        return uuidsToScanFor
    }
    
    func activeConnectionForYLinkUUID(_ UUIDToFind: CBUUID) -> BLEConnection? {
        
        for yLink in yLinksScanList {
            if yLink.uuid == UUIDToFind {
                return yLink.activeConnection
            }
        }
        return nil
    }
    
    func activeConnectionForPeripheral(_ peripheralToFind: CBPeripheral) -> BLEConnection? {
        
        guard let user = YKSSessionManager.sharedInstance.currentUser else {
            return nil
        }
        
        for yLink in user.yLinksToScanFor {
            
            guard let peripheral = yLink.activeConnection?.peripheral else {
                continue
            }
            
            if peripheral == peripheralToFind {
                return yLink.activeConnection
            }
        }
        return nil
    }
    
    internal func isYLinkConnected(_ yLink: YLink) -> Bool {
        return yLink.activeConnection?.peripheral?.state == CBPeripheralState.connected
    }
    
    func generateRandomBytes(_ length: Int) -> [UInt8] {
        
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return bytes
    }
    
    //MARK: Engine public calls
    
/**
    Starts the BLE Engine. Until Stop is called, it will make sure to handle all the BLE Activity.
*/
    func start() {
        
        yLog(.info, category: .BLE, message: "Starting SP BLE Engine")
        
        if YikesEngineSP.sharedInstance.engineState != .on {
            yLog(LoggerLevel.info, category: LoggerCategory.BLE, message: "Not starting SP BLE Engine - Engine state is not On")
            return
        }
        
        if YikesEngineSP.sharedInstance.shouldStartBLEActivity != nil && !YikesEngineSP.sharedInstance.shouldStartBLEActivity(YKSEngineArchitecture.singlePath) {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Not starting SP BLE Engine - Not authorized to start by engineController")
            // Play nice w/ other engines...
            return
        }
        
        if (self.state != .on) {
            // Making a read this time - while the engine is running it gets calls to add or remove YLink objects
            self.state = .on
        }
        else {
            yLog(LoggerLevel.warning, category: LoggerCategory.BLE, message: "Engine already started - Updating the scan filter")
        }
        
        CentralManager.sharedInstance.checkCredentials()
        
        self.startScanning()
        
    }
    
/**
     Stops all BLE Activity in the BLE Engine until next Start.
*/
    
    func stop(_ reason:StopReason = .none) {
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Stopping SP BLE Engine.")
        
        /**
         Here you'd expect the engine to stop scanning.
         However, this would delay discovery of doors in the background if the phone never leaves the iBeacon region.
         Keeping the scan engine up helps keep the engine active until it exits the iBeacon region.
         Also, in the BLE Engine, it won't connect until the phone stops being stationary and it won't notify the delegates of door discoveries.
        */
        
        self.disconnectAll(reason: reason)
        
        if (reason != .stationary) {
            self.stopScanning()
        }
        
        self.state = .off
    }
    
    func addYLinks(_ yLinks: Set<YLink>?) {
        if state != .on {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "BLE engine state is not ON, not updating scan list for new ylinks.")
            return
        }
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Adding ylinks: \(yLinks)")
        
        if let yLinks = yLinks {
            self.startScanningForYLinks(yLinks)
        }
        else {
            self .startScanning()
        }
    }
    
    func removeYLinks(_ yLinks: Set<YLink>) {
        if state != .on {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "BLE engine state is not ON, not updating scan list for removed ylinks.")
            return
        }
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Removing ylinks: \(yLinks)")
        
        self.stopConnectingToYLinks(yLinks)
    }
    
    //MARK: Internal stuff
    
/**
     This method is called whenever the engine starts up (it was Off), which means
     the local list of YLinks to scan for must be setup then used to setup the scan filter.
     
     NOTE: It only updates the filter of the uuids / peripherals w/ services to scan for.
     
     IMPORTANT: do not call this method to update the scan list
*/
    fileprivate func startScanning() {
        
        if (self.centralManager == nil) {
            yLog(LoggerLevel.critical, category: LoggerCategory.Engine, message: "Central Manager is nil - skipping startScanning() call")
            return
        }
        if (self.centralManager.state.rawValue != CBCentralManagerState.poweredOn.rawValue) {
            yLog(LoggerLevel.warning, category: LoggerCategory.BLE, message: "Bluetooth is Not PoweredOn - skipping startScanning() call")
            return
        }
        
        if (self.state == .off) {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "BLE Engine is Off - StartScanning is canceled / stopped")
            return
        }
        
        if YikesEngineSP.sharedEngine().engineState == .paused {
            self.stop()
            yLog(.warning, category: .BLE, message: "BLE Engine is paused, Stopping BLE Engine")
            return
        }
        
        if !ServicesManager.sharedInstance.isBluetoothEnabled() {
            
            yLog(.error, category: .BLE, message: "Bluetooth is off, not starting scan")
            return
        }
        
        self.notifyObservers(ObserverNotification(observableEvent: ObservableEvent.BLEEngineStartScanning, data: nil))
        
        self.restartScan()

        yLog(.info, category:.BLE, message: "Scanning for \(self.yLinksScanList.uuids())")
    }
    
/**
     Adds a YLink to the scan filter.
*/
    func startScanningForYLinks(_ yLinks:Set<YLink>) {
        if (self.state != .on) {
            self.start()
        }
        else {
            // Simply update the scan filter:
            self.yLinksScanList = self.yLinksScanList.union(yLinks)
            self.startScanning()
        }
    }
    
    fileprivate func stopScanning() {
        
        bleEngineQueue.async {
            
            self.notifyObservers(ObserverNotification(observableEvent: ObservableEvent.BLEEngineStopScanning, data: nil))
            
            if YikesEngineSP.sharedInstance.engineState == .off && YikesEngineSP.sharedInstance.isInsideHotel && MotionManager.sharedInstance.isStationary() {
                yLog(.critical, message: "Stopping scan when Stationary and INSIDE SP - bad!!!")
            }
            
            self.centralManager.stopScan()
            
            yLog(.info, category: .BLE, message: "Stopping SP Engine Scanning")
        }
    }
    
    fileprivate func refreshCredentialsForConnection(_ connection:BLEConnection) {
        self.stopConnectingToYLinks(Set(arrayLiteral: connection.yLink))
        CentralManager.sharedInstance.refreshCredentialsForStay(connection.yLink.stay)
    }
    
    fileprivate func stopConnectingToYLinks(_ yLinks:Set<YLink>) {
        
        for yLink in yLinks {
            
            yLink.shouldConnect = false
            disconnectYLink(yLink)
        }
        
        self.restartScan()
    }
    
    func restartScan() {
        
        guard YKSSPLocationManager.shared().isInsideYikesRegion() else {
            yLog(.warning, message: "Outside SP Hotel - restartScan is canceled.")
            return
        }
        
        let previousScanList = Set(self.yLinksScanList)
        let uuids = self.uuidsToScanFor()
        
        if uuids.count == 0 {
            yLog(LoggerLevel.info, category: .BLE, message: "Nothing to scan for - skipping scan this time around.");
            self.disconnect(yLinks: previousScanList, reason: .noAccess)
            self.stopScanning()
        }
        else {
            
            if previousScanList != self.yLinksScanList {
                yLog(.info, category:.BLE, message: "Scanning for \(uuids)")
                let removedScanList = previousScanList.subtracting(self.yLinksScanList)
                for yLink in removedScanList {
                    if let connection = yLink.activeConnection {
                        connection.roomConnectionStatusDidChange(YKSConnectionStatus.disconnectedFromDoor)
                    }
                }
            }
            
            // Note: The dispatch on the bleEngine queue helps getting vibrations in the background:
//            dispatch_async(self.bleEngineQueue) {
                self.centralManager.scanForPeripherals(withServices: Array(uuids), options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
//            }
        }
    }
    
    func disconnectYLink(_ yLink: YLink, reason: StopReason = .none) {
        
        guard let connection = yLink.activeConnection else {
            yLog(LoggerLevel.warning, category: LoggerCategory.BLE, message: "No connection reference found for yLink \(yLink)")
            // disconnecting did not work - reset the flag to connect to:
            yLink.shouldConnect = true
            return
        }
        defer {
            connection.endConnection()
        }
        
        switch reason {
        case .none:
            yLog(.debug, message: "Disconnecting yLink for reason None")
        case .stationary:
            connection.connectionEndReason = .Stationary
        case .noAccess:
            connection.connectionEndReason = .NoAccess
        case .userForcedDisconnect:
            connection.connectionEndReason = .UserForced
        }
        
        // Default if disconnected by yLink:
        if (connection.connectionEndReason == .Unknown) {
            connection.connectionEndReason = BLEConnection.ConnectionEndReason.EngineStopped
        }
        
        connection.roomConnectionStatusDidChange(.disconnectedFromDoor)
        
        guard let peripheral = connection.peripheral else {
            return
        }
        
        let state = peripheral.state
        if (state == CBPeripheralState.connecting || state == CBPeripheralState.connected) {
            self.centralManager .cancelPeripheralConnection(peripheral)
        }
    }
    
    fileprivate func forceRestartScanIn (_ delay:TimeInterval?) {
        
        var shouldRestart = true
        var delayChanged = false
        
        if self.currentScanDelay < delay {
            delayChanged = true
        }
        
        if let delay = delay {
            self.currentScanDelay = delay
        }
        
        self.bleEngineQueue.asyncAfter(
            deadline: DispatchTime.now() + self.currentScanDelay, execute: {
                
                if let lastScanRestart = self.lastScanRestart {
                    let now = Date()
                    let interval:TimeInterval = now.timeIntervalSince(lastScanRestart)
                    yLog(message: "\(String(format: "%.2f", interval)) seconds since last Scan Restart")
                    if interval < self.currentScanDelay && !delayChanged {
                        shouldRestart = false
                        yLog(message: "RestartScan() called before current scan delay of \(String(format: "%.2f", self.currentScanDelay)) - skipping")
                    }
                }
                if shouldRestart {
                    self.lastScanRestart = Date()
                    self.restartScan()
                }
        })
    }
    
    func initialDiscoveryTimedOut(_ connection:BLEConnection) {
        if discoveredConnections().count == 0 {
            yLog(message: "No more active connections to discover in the background")
        }
    }
    
    func discoveredConnections() -> Set<YLink> {
        var yLinks:Set<YLink> = Set()
        for yLink in self.yLinksScanList {
            if yLink.activeConnection?.initialDiscovery != nil {
                yLinks.insert(yLink)
            }
        }
        return yLinks
    }
    
    private func disconnect(yLinks:Set<YLink>, reason:StopReason = .none) {
        for yLink in yLinks {
            disconnectYLink(yLink, reason: reason)
        }
    }
    
    private func disconnectAll(reason:StopReason = .none) {
        
        for yLink in self.yLinksScanList {
            
            disconnectYLink(yLink, reason: reason)
            
        }
    }
    
    fileprivate func setYLinkDebugMode(_ connection:BLEConnection, advData:Data) {
        // Set the yLink debug mode:
        if (self.advertsDebug(advData)) {
            connection.yLink.debugMode = true
        }
        else {
            connection.yLink.debugMode = false
        }
    }
    
    //MARK: Inspection of BLE Messages
    fileprivate func advertsHaveKey(_ advManufacturerData: Data) -> Bool {
        //let manufacturerBytes : [UInt8] = [0x03]
        // 0x61 0x01 are for the Company Identifier from the Bluetooth SIG (0x01 0x61 byte flipped)
        // 0x01 is for the flag - 0x03 is for the "have key" flag, which means it isn't fully configured on yCentral, so don't connect here.
        // 0x01 or 0x02 for release or debug mode
        // 0x00 the last byte is to comply to the min adv. length of 4 for the 0xFF data type (MSD)
        // <6101030100> // for release mode
        let manufacturerBytes : [UInt8] = [0x61, 0x01, 0x03]
        let pertinentAdvData = advManufacturerData[start: 0, length: 3]
        
        let manufacturerData = Data(bytes: UnsafePointer<UInt8>(manufacturerBytes), count: manufacturerBytes.count)
        return pertinentAdvData == manufacturerData
    }
    
    fileprivate func advertsDebug(_ advManufacturerData: Data) -> Bool {
        let debugByte : [UInt8] = [0x02]
        let pertinentAdvData = advManufacturerData[start: 3, length: 1]
        
        let debugData = Data(bytes: UnsafePointer<UInt8>(debugByte), count: debugByte.count)
        return pertinentAdvData == debugData
    }
    
    fileprivate func advertsHaveReports(_ advManufacturerData: Data) -> Bool {
        let bytesToFind : [UInt8] = [0x61, 0x01, 0x02]
        let dataToFind = Data(bytes: bytesToFind, count: bytesToFind.count)
        let subdata = advManufacturerData[start: 0, length: 3]
        return subdata == dataToFind
    }
    
    //MARK: Creation of BLE Messages
    
    fileprivate func make_pl_access_credentials(_ connection: BLEConnection) -> Data? {
        
        guard let cl_accessCredentialHexString = connection.yLink.credential?.CL_AccessCredential else {
            yLog(.error, category:.BLE, message:"No credentials found for connection \(connection)")
            return nil
        }
        
        let cl_accessCredentialHexStringData = cl_accessCredentialHexString.dataFromHexadecimalString()
        
        let pl_random = generateRandomBytes(4)
        let iv = generateRandomBytes(16)
        
        let cl_access_credential = CL_AccessCredentials(rawData: cl_accessCredentialHexStringData! as Data)
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "\(cl_access_credential)")
        
        let pl_access_credential = PL_AccessCredentials()
        pl_access_credential.messageID = PL_AccessCredentials.identity
        pl_access_credential.messageVersion = 0x01
        pl_access_credential.PL_random = pl_random
        pl_access_credential.initializationVector = iv
        if let cl_AC = cl_access_credential?.rawData?.convertToBytes() {
            pl_access_credential.payload = cl_AC
        }
        
        connection.handshakeInfo = HandshakeInfo(PL_random: pl_random, initializationVector: iv)
        
        return pl_access_credential.rawData
    }
    
    fileprivate func make_pl_verify_unencrypted (_ connection: BLEConnection) -> Data? {
        
        let pl_verify = PL_Verify()
        pl_verify.messageID = PL_Verify.identity
        pl_verify.messageVersion = 0x01
        pl_verify.initializationVector = generateRandomBytes(16)
        //        pl_verify.initializationVector =
        //            [0x00, 0x00,
        //                0x00, 0x0F, 0xF1, 0xCE,
        //                0xCA, 0xFE, 0xD0, 0x0D,
        //                0xC0, 0xFF, 0xEE, 0xFA,
        //                0xCE, 0x12]
        let lp_random = connection.lp_random
        
        let hasDataConnection:UInt8 = ServicesManager.sharedInstance.isReachable() ? 0x01 : 0x00
        
        var payload = Data(bytes: lp_random!, count: 4)
        payload.append([hasDataConnection], count: 1)
        pl_verify.payload = payload.convertToBytes()
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "PL_Verify:\n\(pl_verify)")
        
        return pl_verify.rawData
    }
    
    fileprivate func make_pl_verify (_ connection: BLEConnection) -> Data? {
        
        let pl_verify = PL_Verify()
        pl_verify.messageID = PL_Verify.identity
        pl_verify.messageVersion = 0x01
        pl_verify.initializationVector = generateRandomBytes(16)
//        pl_verify.initializationVector =
//            [0x00, 0x00,
//                0x00, 0x0F, 0xF1, 0xCE,
//                0xCA, 0xFE, 0xD0, 0x0D,
//                0xC0, 0xFF, 0xEE, 0xFA,
//                0xCE, 0x12]
        let lp_random = connection.lp_random
        
        let hasDataConnection:UInt8 = ServicesManager.sharedInstance.isReachable() ? 0x01 : 0x00
        
        var payload = Data(bytes: lp_random!, count: 4)
        payload.append([hasDataConnection], count: 1)
        
        /**
         Encrypt the payload
         */
        
        var encryptedPayload: [UInt8]?
        
        guard let cpl_shared_key = connection.yLink.credential?.CPL_SharedEncryptionKey else {
            yLog(.critical, message: "cpl_shared_key is nil for connection to \(connection.yLink)")
            return nil
        }
        guard let key = cpl_shared_key.dataFromHexadecimalString()?.convertToBytes() else {
            yLog(.critical, message: "cpl_shared_key bytes is nil for connection to \(connection.yLink)")
            return nil
        }
        do {
            let aes = try AES(key:key, iv: pl_verify.initializationVector, blockMode: .CFB)
            let payloadBytes = payload.convertToBytes()
            do {
                encryptedPayload = try aes.encrypt(payloadBytes)
            } catch {
                yLog(.error, category: .Encryption, message: "Failed to encrypt PL_Verify payload")
            }
        } catch {
            yLog(.error, category: .Encryption, message: "Failed to initialize AES Encryption")
        }
        
        /**
         Set the payload
         */
        if let ep = encryptedPayload {
            pl_verify.payload = ep
        }
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "PL_Verify:\n\(pl_verify)")
        
        /**
         Return as Data
         */
        
        return pl_verify.rawData
    }
    
    //MARK: Processing of incoming BLE Messages
    
    fileprivate func process_incoming_message(_ characteristic:CBCharacteristic, connection:BLEConnection) {
        
        if (characteristic.uuid == CBUUID(string: EngineConstants.YLINK_WRITE_CHAR_UUID)) {
            
            guard let incoming_data = characteristic.value else {
                yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "No value on the characteristic: \(characteristic)")
                return
            }
            
            guard incoming_data.count > 0 else {
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Skipping characteristic update - value was empty")
                return
            }
            
            // YLink is either authenticated or sending the LP_Verify (edit: 2016-04-08: or LP_Disconnect)
            if LP_Verify.isThisMessageType(incoming_data) {
                self.process_lp_verify_message(incoming_data, connection:connection)
            }
               
            else if (LP_Disconnect.isThisMessageType(incoming_data)) {
                self.process_lp_disconnect_message(incoming_data, connection: connection)
            }
                
            else if (connection.isSuccessful) {
                self.process_authenticated_messages(incoming_data, connection:connection)
            }
            
            else {
                yLog(LoggerLevel.warning, category:LoggerCategory.BLE, message: "LP_Verify is incorrect.\n\nDropping the peripheral.")
                
                if let block = YikesEngineSP.sharedInstance.delegate?.yikesEngineErrorDidOccur {
                    block(YKSError.newWith(YKSErrorCode.engineLPVerifyDoesNotMatch, errorDescription: "LP_Verify is incorrect"))
                }
                
                if let peripheral = connection.peripheral {
                    // end the connection here since we might not be getting a disconnect callback if another app is still using the peripheral:
                    connection.connectionEndReason = .Fatal
                    connection.endConnection()
                    centralManager.cancelPeripheralConnection(peripheral)
                }
                else {
                    yLog(.warning, category:.BLE, message:"Cannot cancel the peripheral connection - Missing reference: \(connection)")
                }
            }
        }
            
        else if (characteristic.uuid == CBUUID(string: EngineConstants.YLINK_DEBUG_MESSAGE_UUID)) {
            
            guard let debug_message_data = characteristic.value else {
                yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "No value on the characteristic: \(characteristic)")
                return
            }
            
            guard debug_message_data.count > 0 else {
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Skipping characteristic update - value was empty")
                return
            }
            
            self.process_debug_message(debug_message_data, connection: connection)
        }
            
        else {
            yLog(LoggerLevel.critical, category: LoggerCategory.BLE, message: "Unrecognized characteristic: \(characteristic)")
        }
        
    }
    
    fileprivate func process_lp_verify_message(_ incoming_data:Data, connection:BLEConnection) {
        
        if (connection.charUpdateReceivedForLP_Verify) && (validate_lp_verify(incoming_data, connection: connection)) {
            
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "LP_Verify is correct.")
            
            connection.isSuccessfulOn = Date()
            connection.isSuccessful = true
            
//            connection.roomConnectionStatusDidChange(YKSConnectionStatus.ConnectedToDoor)
            
            var pl_verify_data:Data?
            
            if (BLEEngine.secureMode == .encrypted) {
                pl_verify_data = make_pl_verify(connection)
            }
            else {
                pl_verify_data = make_pl_verify_unencrypted(connection)
            }
            
            guard let pl_verify = pl_verify_data else {
                yLog(.warning, category:.BLE, message:"make_pl_verify - Failed to make pl_verify for connection \(connection) - data:\n\(pl_verify_data)")
                return
            }
            
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Writing back the PL_Verify:\n\(pl_verify)")
            
            if let peripheral = connection.peripheral, let writeCharacteristic = connection.yLink.writeCharacteristic {
                
                if (writeCharacteristic.properties .contains(CBCharacteristicProperties.write)) {
                    peripheral.writeValue(pl_verify, for: (writeCharacteristic), type: CBCharacteristicWriteType.withResponse)
                    connection.writingPLVerify = true
                }
                else if (writeCharacteristic.properties.contains(CBCharacteristicProperties.writeWithoutResponse)) {
                    peripheral.writeValue(pl_verify, for: (writeCharacteristic), type: CBCharacteristicWriteType.withoutResponse)
                    // we won't get a write confirmation, so let's start the connection reports timer
//                    connection.scheduleReportsTimer()
                }
                else {
                    yLog(LoggerLevel.critical, category: LoggerCategory.BLE, message: "The yLink Write Charasteristic does NOT ALLOW TO WRITE - Dropping")
                    self.centralManager .cancelPeripheralConnection(peripheral)
                }
                
            }
            else {
                yLog(.warning, category:.BLE, message:"process_lp_verify_message - Missing peripheral or writeCharacteristic reference to writeCharacteristic for connection \(connection)")
            }
        }
            
        else if (!connection.charUpdateReceivedForLP_Verify && validate_lp_verify_signature(incoming_data)) {
            
            connection.charUpdateReceivedForLP_Verify = true
            
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Detected incoming LP_Verify -> Sending a read request.")
            
            if let peripheral = connection.peripheral, let writeCharacteristic = connection.yLink.writeCharacteristic {
                peripheral.readValue(for: writeCharacteristic)
            }
            else {
                yLog(.warning, category:.BLE, message:"process_lp_verify_message - Missing peripheral reference to readValueForCharacteristic for connection \(connection)")
            }
        }
            
        else {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Error: Received an invalid or incomplete LP_Verify message: \(incoming_data)")
            if let peripheral = connection.peripheral {
                self.centralManager .cancelPeripheralConnection(peripheral)
            }
            else {
                yLog(message: "Could not drop the periperhal after PL_Random match failed or LP_Verify was invalid - no reference found in the BLEConnection object");
            }
        }
    }
    
    fileprivate func process_authenticated_messages(_ incoming_data:Data, connection:BLEConnection) {
        
        if (LC_TimeSyncRequest.isThisMessageType(incoming_data)) {
            
            if connection.lc_time_sync_request == nil {
                connection.lc_time_sync_request = incoming_data
                if let peripheral = connection.peripheral, let writeCharacteristic = connection.yLink.writeCharacteristic {
                    peripheral.readValue(for: writeCharacteristic)
                }
                else {
                    yLog(.warning, category:.BLE, message:"process_authenticated_messages - Missing peripheral or writeCharacteristic reference to readValueForCharacteristic for connection \(connection)")
                }
            }
                
            else {
                // Did read full value
                if let lc_time_sync_request = LC_TimeSyncRequest(rawData: incoming_data as Data) {
                    yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Acknowledging LC Time Sync Request:\n\n\(lc_time_sync_request)")
                    connection.lc_time_sync_request = nil
                    
                    self.process_lc_time_sync_request(lc_time_sync_request, connection: connection)
                }
            }
        }
            
        else if (LP_Disconnect.isThisMessageType(incoming_data)) {
            self.process_lp_disconnect_message(incoming_data, connection: connection)
        }
            
        else if (LC_Report.isThisMessageType(incoming_data)) {
            self.process_lc_report(incoming_data, connection:connection)
        }
            
        else if (LP_NoReport.isThisMessageType(incoming_data)) {
            // done with this report operation:
            connection.endReportOperation()
            yLog(message: "[Reporting] No reports for \(connection)")
        }
            
        else {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Received a message with an unkown ID:\n\(incoming_data)")
        }
    }
    
    fileprivate func process_debug_message(_ debug_message:Data, connection:BLEConnection) {
        
        if (DebugManager.sharedInstance.isYLinkDebuggingDisabled) {
            return
        }
        
        guard LP_Debug.isThisMessageType(debug_message) else {
            return
        }
        
//        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "Raw LP_Debug:\n\(debug_message)")
        
        guard let lp_debug = LP_Debug(rawData: debug_message as Data) else {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "LP_Debug mapping failed:\nRaw data was: \(debug_message)")
            return
        }
        
        // if message length is 17 bytes or less, the debug message will fit in the char.value and there is no need to make an explicit read.
        if lp_debug.messageLength <= 17 {
            
//            yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "Received a short debug message from yLink:\n\(lp_debug)")
            self.display_lp_debug(lp_debug.debugMessage, connection: connection)
            connection.lp_debug = nil
        }
        else if (connection.lp_debug == nil) {
            
            // didn't get the long message yet:
            connection.lp_debug = debug_message
            if let peripheral = connection.peripheral, let debugMessageCharacteristic = connection.yLink.debugMessageCharacteristic {
                peripheral.readValue(for: debugMessageCharacteristic)
            }
            else {
                yLog(.warning, category:.BLE, message:"process_debug_message - Missing peripheral or debugMessageCharacteristic reference to readValueForCharacteristic for connection \(connection)")
            }
        }
        else {
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Received a long debug message from yLink:\n\(lp_debug)")
            // ok, we got the long message:
            self.display_lp_debug(lp_debug.debugMessage, connection:connection)
            
            connection.lp_debug = nil
        }
    }
    
    //Mark: Output
    fileprivate func display_lp_debug(_ bytes:[UInt8], connection:BLEConnection) {
        
        guard let debugMessage = String(bytes: bytes, encoding:String.Encoding.utf8) else {
            return
        }
        
        connection.debugMessage = debugMessage
        
        if LPDebugParser.findInsideOutside(connection) {
            connection.updateConnection()
        }
        
        yLog(LoggerLevel.external,
            category: LoggerCategory.YLink,
            message: "[ \(connection.yLink.macAddress ?? "nil") ] DBG: [ \(debugMessage) ]")
    }
    
    fileprivate func process_lc_time_sync_request(_ lc_time_sync_request:LC_TimeSyncRequest, connection:BLEConnection) {
        
        self.notifyObservers(ObserverNotification(
            observableEvent: ObservableEvent.ReceivedTimeSyncNotificationFromYLink,
            data: nil))
        
        guard let lc_timeSyncHexString = lc_time_sync_request.rawData?.hexadecimalString() else {
            return
        }
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "The timeSync Hex String:\n\(lc_timeSyncHexString)")
        
        connection.yLink.sendTimeSyncRequest(lc_timeSyncHexString, success: { cl_timeSync in
            
            if let cl_timeSyncData = cl_timeSync?.dataFromHexadecimalString() {
                
                let cl_TS = CL_TimeSync(rawData: cl_timeSyncData)
                
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Received CL_TimeSync \(cl_TS) from yCentral - forwarding to yLink \(connection.yLink)")
                
                if let peripheral = connection.peripheral, let characteristic = connection.yLink.writeCharacteristic {
                    
                    if (characteristic.properties .contains(CBCharacteristicProperties.write)) {
                        peripheral.writeValue(cl_timeSyncData, for:characteristic, type:CBCharacteristicWriteType.withResponse)
                        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Writing WITH response CL_TimeSync back to yLink:\n\(cl_timeSyncData)")
                    }
                    else if (characteristic.properties .contains(CBCharacteristicProperties.writeWithoutResponse)) {
                        peripheral.writeValue(cl_timeSyncData, for:characteristic, type:CBCharacteristicWriteType.withoutResponse)
                        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Writing Without response CL_TimeSync back to yLink:\n\(cl_timeSyncData)")
                    }
                    else {
                        yLog(LoggerLevel.critical, category: LoggerCategory.BLE, message: "The yLink Write Charasteristic does NOT ALLOW TO WRITE - Dropping")
                        self.centralManager .cancelPeripheralConnection(peripheral)
                    }
                    
                }
                else {
                    yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "No peripheral or yLink found for that connection: \(connection)")
                }
            }
            
        }, failure: { error in
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Won't be able to respond to yLink Time Sync Request due to an API Error: \(error)")
        })
    }
    
    fileprivate func process_lc_report(_ incoming_data:Data, connection:BLEConnection) {
        
        if let macAddress = connection.yLink.macAddress {
            let now = Date()
            if let until = self.yLinksBlacklistedForReporting[macAddress] {
                if until != nil && until! > now {
                    // still blacklisted, don't report (yet):
                    // TODO: Write back to yLink about the non-report action:
                    yLog(.warning, message: "[Reporting] Ignoring incoming LC_Report - it is blacklisted until \(until) for connection \(connection)")
                    return
                }
                else {
                    yLog(.info, message: "[Reporting] Not blacklisted for reporting anymore: \(connection)")
                    self.yLinksBlacklistedForReporting.removeValue(forKey: macAddress)
                }
            }
        }
        
        if connection.lc_report == nil {
            connection.lc_report = incoming_data
            if let peripheral = connection.peripheral {
                if let writeCharacteristic = connection.yLink.writeCharacteristic {
                    peripheral.readValue(for: writeCharacteristic)
                }
                else {
                    yLog(.error, category:.BLE, message:"[Reporting] process_lc_report - missing writeCharacteristic reference for connection \(connection)")
                }
            }
        }
        else {
            if let lc_report = LC_Report(rawData: incoming_data as Data) {
                connection.lc_report = nil
                if let peripheral = connection.peripheral {
                    yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "[Reporting] Received an LC_Report for connection \(connection) - forwarding to yCentral.\n\n\(lc_report)")
                }
                guard let macAddress = connection.yLink.macAddress else {
                    yLog(.error, message: "[Reporting] Missing yLink macAddress to upload lc_report for connection \(connection)")
                    return
                }
                
                // Create a report operation to keep track of it:
                connection.startReportOperation()
                if let reportOperation = connection.reportOperation {
                    
                    connection.yLink.uploadReport(macAddress: macAddress, lc_report: lc_report, success: { (cl_reportAck) in
                        
                        yLog(message:
                            "\n\n############################### \n\n[Reporting] Successfully uploaded LC_Report \(lc_report)\nfor connection \(connection)\n\n###############################\n\n")
                        YLinkReporter.sharedInstance.writeCL_ReportAck(reportOperation, cl_reportAck: cl_reportAck)
                        // done w/ this
                        connection.endReportOperation()
                        
                        }, failure: { error, response in
                            yLog(.error, message:"[Reporting] Error uploading LC_Report - canceling reporting for connection \(connection):\n\(error)")
                            
                            // Grab the response status code - if 5XX blacklist the yLink for xx seconds
                            let statusCodes = Array(500..<600)
                            if let statusCode = response?.statusCode {
                                if statusCodes.contains(statusCode) {
                                    let until = Date().addingTimeInterval(BLEConnection.blacklistedReportingTimeInterval)
                                    yLog(message: "[Reporting] Blacklisting connection for reports until \(until):\n\(connection)")
                                    if let macAddress = connection.yLink.macAddress {
                                        self.yLinksBlacklistedForReporting[macAddress] = until
                                    }
                                }
                            }
                            
                            if let errorDidOccurBlock = YikesEngineSP.sharedInstance.delegate?.yikesEngineErrorDidOccur {
                                error.logEventOnCrashlytics = true
                                let statusCode = (response?.statusCode) ?? 0
                                error.eventName = "Upload LC_Report failed (\(statusCode))"
                                errorDidOccurBlock(error)
                            }
                            
                            connection.endReportOperation()
                    })
                }
            }
            else {
                yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "[Reporting] Failed to map LC_Report:\n\(incoming_data) for connection \(connection)")
            }
        }
    }
    
    fileprivate func process_lp_disconnect_message(_ incoming_data:Data, connection:BLEConnection) {
        
        // Only read the first lp_disconnect:
        if connection.lp_disconnect == nil {
            connection.lp_disconnect = incoming_data
            if let lp_disconnect = LP_Disconnect(rawData: incoming_data as Data) {
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Read LP Disconnect Code:\n\n\(lp_disconnect)")
                self.process_disconnect_reason_code(connection, lp_disconnect: lp_disconnect)
            }
        }
    }
    
    fileprivate func process_disconnect_reason_code (_ connection:BLEConnection, lp_disconnect:LP_Disconnect) {
        
        guard let disconnectReason = lp_disconnect.disconnectReason else { return }
        
        guard let reason = YKSDisconnectReasonCode(rawValue: UInt(disconnectReason)) else {
            yLog(LoggerLevel.critical, category: LoggerCategory.BLE, message: "Invalid disconnect reason: \(UInt(disconnectReason))")
            return
        }
        
        if let rn = connection.yLink.roomNumber {
            yLog(LoggerLevel.info, category: LoggerCategory.BLE, message: "\(rn): Disconnect reason was \(reason.description)")
        }
        
        connection.roomConnectionStatusDidChange(.disconnectedFromDoor, reason: reason)
        
        switch reason {
            
        case .closed:
            connection.connectionEndReason = BLEConnection.ConnectionEndReason.Closed
        
        case .expired:
            self.refreshCredentialsForConnection(connection)
            connection.connectionEndReason = BLEConnection.ConnectionEndReason.Expired
        
        case .inside:
            connection.connectionEndReason = BLEConnection.ConnectionEndReason.Inside
        
        case .notActive:
            self.refreshCredentialsForConnection(connection)
            connection.connectionEndReason = BLEConnection.ConnectionEndReason.NotActive
        
        case .proximity:
            connection.connectionEndReason = BLEConnection.ConnectionEndReason.Proximity
        
        case .superseded:
            self.refreshCredentialsForConnection(connection)
            connection.connectionEndReason = BLEConnection.ConnectionEndReason.Superseded
        
        case .fatal:
            connection.connectionEndReason = BLEConnection.ConnectionEndReason.Fatal
            
        case .unknown:
            connection.connectionEndReason = BLEConnection.ConnectionEndReason.Unknown
            
        default:
            connection.connectionEndReason = BLEConnection.ConnectionEndReason.Unknown
        }
        
        if connection.isSuccessful {
            // Dynamic RSSI tuning
            // Note: Disabling in 2.0.1 until it's proven efficient on both the Guest Experience and the Battery Life side.
//            self.connectionThresholdAdjuster.didDisconnectYLink(connection)
        }
    }
    
    //MARK: Reporting
    func pullReports(connection:BLEConnection) {
        if let peripheral = connection.peripheral, let macAddress = connection.yLink.macAddress, let writeCharacteristic = connection.yLink.writeCharacteristic {
            let reportOperation = YLinkReportOperation.init(connection:connection, writeCharacteristic:writeCharacteristic)
            if connection.reportOperation == nil {
                connection.reportOperation = reportOperation
                YLinkReporter.sharedInstance.writePL_GetReport(reportOperation)
            }
            else {
                yLog(message: "[Reporting] Another report is being process - skipping")
            }
        }
        
    }
    
    //MARK: Decryption
    
    fileprivate func decrypted_LP_Verify_payload(_ encrypted_lp_verify:LP_Verify, connection: BLEConnection) -> [UInt8]? {
        
        var decryptedPayload: [UInt8]?
        
        guard let cpl_shared_key = connection.yLink.credential?.CPL_SharedEncryptionKey else { return nil }
        guard let key = cpl_shared_key.dataFromHexadecimalString()?.convertToBytes() else { return nil }
        
        do {
            let aes = try AES(key:key, iv:encrypted_lp_verify.initializationVector, blockMode: .CFB)
            do {
                decryptedPayload = try aes.decrypt(encrypted_lp_verify.payload)
                
            } catch {
                yLog(.error, category: .Encryption, message: "Failed to decrypt LP_Verify payload")
            }
        } catch {
            yLog(.error, category: .Encryption, message: "Failed to initialize AES Encryption")
        }
        
        return decryptedPayload
    }
    
    //MARK: Validation of BLE Messages
    
    fileprivate func validate_lp_verify_signature(_ incoming_lp_verify:Data) -> Bool {
        
        let lp_verify = LP_Verify(rawData: incoming_lp_verify as Data)
        if lp_verify == nil || !LP_Verify.isThisMessageType(incoming_lp_verify) {
            return false
        }
        else {
            return true
        }
    }
    
    fileprivate func validate_lp_verify (_ incoming_lp_verify: Data, connection: BLEConnection) -> Bool {
        
//        if (incoming_lp_verify.length != LP_Verify.length_total_encrypted) {
//            return false
//        }
        
        guard let lp_verify = LP_Verify(rawData: (incoming_lp_verify as Data)) else {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "The mapping for LP_Verify failed: \(incoming_lp_verify)")
            return false
        }
        
        if !LP_Verify.isThisMessageType(incoming_lp_verify) {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "The incoming LP_Verify has the wrong identity: \(incoming_lp_verify.convertToBytes().first)")
            return false
        }
        
        var decryptedPayloadBytes: [UInt8]?
        
        /**
         Handle both secure modes:
         */
        if (BLEEngine.secureMode == .encrypted) {
            decryptedPayloadBytes = self.decrypted_LP_Verify_payload(lp_verify, connection: connection)
        }
        else {
            decryptedPayloadBytes = lp_verify.payload
        }
        
        guard let decryptedPayload = decryptedPayloadBytes else {
            yLog(.error, category: LoggerCategory.Encryption, message: "LP_Verify payload could not be decrypted for connection \(connection)")
            return false
        }
        
        let minCount = LP_Verify.decrypted_payload_length
        
        // the payload is at least 8 bytes - 4 bytes for the PL_Random and 4 bytes for the LP_Random.
        if decryptedPayload.count >= minCount {
            connection.lp_random = Array(decryptedPayload[4..<8])
            connection.pl_random = Array(decryptedPayload[0..<4])
        } else {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "payload length smaller than \(minCount):\npayload received and mapped: \(decryptedPayload) for connection \(connection)")
            return false
        }
        
        guard let pl_random = connection.pl_random else {
            yLog(.error, message: "No PL_Random in LP_Verify")
            return false
        }
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "LP_Verify:\nmsgV:\(lp_verify.messageVersion)")
        
        let pl_random_from_lp_verify = Data(bytes: pl_random)
        guard let pl_random_origin = connection.handshakeInfo?.PL_random else {
            yLog(message: "Original PL_Random not found")
            return false
        }
        
        let pl_random_from_pl_accessCredentials = Data(bytes:pl_random_origin)
        if pl_random_from_lp_verify == pl_random_from_pl_accessCredentials {
            yLog(message: "Success! Both PL Random match! for connection \(connection)")
            #if DEBUG
//            CentralManager.sharedInstance.fireLocalNotification("Success! Both PL Random match! Room: \(connection.yLink.roomNumber)")
            #endif
            return true
        }
        else {
            yLog(.error, message: "PL Random from PL_AccessCredentials and LP_Verify DON'T MATCH for connection: \(connection)")
            return false
        }
    }
}

// MARK: CBCentralManagerDelegate methods
extension BLEEngine {
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        yLog(LoggerLevel.info, category: LoggerCategory.Engine, message: "CBCentralManager willRestoreState: dict: \(dict)")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "centralManagerDidUpdateState called with state \(central.state.rawValue)")
        
        switch central.state {
        case .unknown:
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "centralManager.state updated: Unknown")
            break
            
        case .resetting:
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "centralManager.state updated: Resetting")
            break
            
        case .unsupported:
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "centralManager.state updated: Unsupported")
            break
            
        case .unauthorized:
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "centralManager.state updated: Unauthorized")
            break
            
        case .poweredOff:
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "centralManager.state updated: Powered off")
            BLEEngine.sharedInstance.stop()
            YKSSPLocationManager.shared().requestState(true)
            break
            
        case .poweredOn:
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "centralManager.state updated: Powered on")
            break
        }
        
        ServicesManager.sharedInstance.notifyMissingServices()
        
    }
    
    @objc(centralManager:didDiscoverPeripheral:advertisementData:RSSI:) func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if YikesEngineSP.sharedInstance.engineState == .off {
            self.stop()
            return
        }
        
        let backgrounded = UIApplication.shared.applicationState == .background
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Discovered \(peripheral.name ?? "nil") w/ RSSI \(RSSI)\nwhile Backgrounded: \(backgrounded ? "Yes" : "No")")
        
        // NOTE: Not using a guard to avoid early returns w/ yLink Sim:
        let advData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        
        if let advData = advData {
            if self.advertsHaveKey(advData) == true {
                yLog(LoggerLevel.warning, category: LoggerCategory.BLE, message: "Found the yLink but it is NOT CONFIGURED - adverts HAVE KEY in Manufacturer's Specific Data:\n\(advData)")
                return
            }
        }
        else {
            yLog(message: "No Advertisment Data found for peripheral (may be because the app is backgrounded) \(peripheral.name ?? "NoName")")
        }
        
        guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? NSArray else {
            yLog(.error, message: "No service UUIDs found in the advertisment - ignoring \(peripheral)")
            return
        }
        
        for objUUID in serviceUUIDs {
            
            guard let serviceUUID = objUUID as? CBUUID else {
                continue
            }
            
            // Used after analysing the scan data to schedule the next scan:
            let stationary = MotionManager.sharedInstance.isStationary()
            var message = ""
            var delay:TimeInterval = self.currentScanDelay
            
            if let connection = activeConnectionForYLinkUUID(serviceUUID) {
                
                if let advData = advData {
                    self.setYLinkDebugMode(connection, advData:advData)
                }
                
                if let credential = connection.yLink.credential {
                    
                    // relax the proximityRSSI by 5 to allow for faster connections - this could be a "perfomance" option at some point for the user to decide re: battery life...
                    
                    let backgrounded = UIApplication.shared.applicationState == .background
                    
                    var minConnectRSSI = -75
                    if let proxRSSI = credential.proximityRSSI {
                        minConnectRSSI = proxRSSI - 2
                    }
                    
                    #if DEBUG
//                    minConnectRSSI = -90
                    #endif
                    if backgrounded {
                        minConnectRSSI -= self.backgroundMinConnectRSSIRelaxing
                        yLog(category: .Device, message: "Backgrounded! Relaxing the Min Connect RSSI by \(self.backgroundMinConnectRSSIRelaxing)")
                    }
                    
                    // let minConnectRSSI = self.connectionThresholdAdjuster.minConnectRSSI(connection, credential: credential)
                    
                    yLog(category: .Device, message: "proximityRSSI is \(minConnectRSSI)")
                    
                    self.notifyObservers(ObserverNotification(observableEvent: ObservableEvent.DiscoveredYLink, data: connection.yLink))
                    
                    connection.didDiscoverPeripheral(peripheral, RSSI: RSSI)
                    
                    if abs(minConnectRSSI) < abs(RSSI.intValue) {
                        
                        // not connecting - too far
                        if !stationary {
                            connection.roomConnectionStatusDidChange(YKSConnectionStatus.scanningForDoor)
                        }
                        
                        if backgrounded {
                            message = "Restarting scan while backgrounded"
                            if !stationary {
                                delay = 0.5
                            }
                            else {
                                delay = self.stationaryScanDelay
                            }
                        }
                        else {
                            if stationary {
                                delay = self.stationaryScanDelay
                            }
                            else {
                                delay = 1
                            }
                        }
                    }
                    else {
                        
                        if connection.yLink.shouldConnect &&
                            !stationary && self.state == .on &&
                            !credential.credentialsExpired() {
                            
                            connection.roomConnectionStatusDidChange(YKSConnectionStatus.connectingToDoor)
                            self.notifyObservers(ObserverNotification(observableEvent: ObservableEvent.ConnectingWithYLink, data: connection.yLink))
                            connection.scheduleConnectionTimer()
                            self.centralManager.connect(peripheral, options: nil)
                            
                        } else {
                            
                            if (!connection.yLink.shouldConnect) {
                                yLog(.info, category: .BLE, message: "YLink \(connection.yLink.roomNumber) has been flagged to NOT connect to - only scanning")
                            }
                            else if connection.credentialsExpired() {
                                if let roomNumber = connection.yLink.roomNumber {
                                    yLog(.info, category: .BLE, message: "Credentials expired for \(roomNumber)")
                                }
                                self.removeYLinks(Set(arrayLiteral: connection.yLink))
                                CentralManager.sharedInstance.checkCredentialsForConnection(connection)
                            }
                            else {
                                yLog(message: "Device is stationary or BLEE is OFF - not connecting")
                            }
                            
                            // Force new BLE Adverts discovery calls to avoid "deep sleep" state.
                            delay = self.stationaryScanDelay
                        }
                    }
                    
                }
                else {
                    yLog(.critical, message: "No credentials found to connect to room \(connection.yLink.roomNumber) and yLink \(connection.yLink)")
                }
                
            }
            else {
                yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Not connecting with \(peripheral.name ?? "nil"), no active connection found")
            }
            
            // Always restart the scan while inside:
            message = "Restarting scan in \(String(format: "%.2f", delay))s"
            yLog(message: message)
            forceRestartScanIn(delay)
        }
    }
    
    
    @objc(centralManager:didConnectPeripheral:) func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        guard let connection = activeConnectionForPeripheral(peripheral) else {
            yLog(LoggerLevel.warning, category: LoggerCategory.BLE, message: "Received a connection with no BLEConnection reference - disconnecting...")
            self.centralManager .cancelPeripheralConnection(peripheral)
            return
        }
        
        self.notifyObservers(ObserverNotification(observableEvent: ObservableEvent.ConnectedWithYLink, data: connection.yLink))
        
        //TODO: Schedule Credential refresh while connected to yLink if credentials are about to expire to avoid delays if it gets dropped
        
        connection.peripheral = peripheral
        connection.peripheral?.delegate = self
        connection.connectionRequestCompletedOn = Date()
        connection.cancelConnectionTimer()
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Did connect to peripheral for connection \(connection)")
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Discovering services for connection \(connection)")
        
        peripheral.discoverServices([CBUUID(string: EngineConstants.YLINK_SERVICE_UUID)])
    }
    
    
    @objc(centralManager:didFailToConnectPeripheral:error:) func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Did fail to connect to \(peripheral)\nError: \(error)")
        
        guard let connection = activeConnectionForPeripheral(peripheral) else {
            return
        }
        
        self.notifyObservers(ObserverNotification(observableEvent: ObservableEvent.FailedToConnectWithYLink, data: connection.yLink))
        
        connection.connectionEndReason = BLEConnection.ConnectionEndReason.FailedToConnect
        connection.endConnection()
        
        // Note: if the connection fails, there is no restartScan until:
        // 1. the device goes stationary / moves again
        // 2. another yLink is discovered
        // 3. the app is backgrounded
        // 4. another yLink is disconnected
        // 5. BLE is toggled on the device
        // 6. Leaves / Enters yBeacon region
        // So it is important to restart the scan to push back this yLink in the scan loop:
        restartScan()
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        if error != nil {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Error on disconnect: \(error)")
        }
        
        guard let connection = activeConnectionForPeripheral(peripheral) else {
            yLog(LoggerLevel.warning, category: LoggerCategory.BLE, message: "Did disconnect from a peripheral with no referenced connection:\n\(peripheral)")
            // make sure we are still scanning for the right doors:
            restartScan()
            return
        }
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Did disconnect from peripheral for connection \(connection)")
        
        self.notifyObservers(ObserverNotification(observableEvent: ObservableEvent.DisconnectedFromYLink, data: connection.yLink))
        if let macAddress = connection.yLink.macAddress {
            self.yLinksBlacklistedForReporting.removeValue(forKey: macAddress)
        }
        connection.endConnection()
        
        restartScan()
    }
}

// MARK: CBPeripheralDelegate methods
extension BLEEngine {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let connection = activeConnectionForPeripheral(peripheral) else {
            yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "didDiscoverServices called with no connection reference - ignoring")
            self.centralManager .cancelPeripheralConnection(peripheral)
            return
        }
        
        if error != nil {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Failed to discover services for peripheral: \(peripheral)\nError: \(error)")
            self.centralManager .cancelPeripheralConnection(peripheral)
            return
        }
        
        connection.peripheral = peripheral
        
        guard let services = peripheral.services else {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "No services found on discovery")
            return
        }
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Found \(services.count) services [\(peripheral.name ?? "nil")]:\n\(services)")
        
        for service in services {
            
            if (service.uuid == CBUUID(string: EngineConstants.YLINK_SERVICE_UUID)) {
                
                peripheral.discoverCharacteristics([CBUUID(string: EngineConstants.YLINK_WRITE_CHAR_UUID), CBUUID(string: EngineConstants.YLINK_DEBUG_MESSAGE_UUID)], for: service)
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Started characteristics discovery for connection \(connection)...")
                break
            }
        }
    }
    
    
    @objc(peripheral:didDiscoverCharacteristicsForService:error:) func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let connection = activeConnectionForPeripheral(peripheral) else {
            yLog(LoggerLevel.warning, category: LoggerCategory.Engine, message: "Didn't find active connection for peripheral \(peripheral.name ?? "nil")")
            self.centralManager .cancelPeripheralConnection(peripheral)
            return
        }
        
        if error != nil {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Failed to discover characteristics for peripheral: \(peripheral) and service: \(service)\nError: \(error)")
            self.centralManager .cancelPeripheralConnection(peripheral)
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Found \(characteristics.count) characteristics for connection:\(connection)\nCharacterstics:\n\(characteristics)")
        
        var writeCharacteristicFound: Bool = false
        var debugCharacteristicFound: Bool = false
        
        // Find all characteristics that we are interested in:
        for characteristic in characteristics {
            
            if (characteristic.uuid == CBUUID(string: EngineConstants.YLINK_WRITE_CHAR_UUID)) {
                connection.yLink.writeCharacteristic = characteristic
                writeCharacteristicFound = true
            }
            else if (characteristic.uuid == CBUUID(string: EngineConstants.YLINK_DEBUG_MESSAGE_UUID)) {
                connection.yLink.debugMessageCharacteristic = characteristic
                debugCharacteristicFound = true
            }
            else {
                yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Unsupported Characteristic discoverd: \(characteristic.uuid)")
            }
        }
        
        // Subscribe first to the Debug char:
        if (debugCharacteristicFound && connection.yLink.debugMode) {
            if let peripheral = connection.peripheral, let characteristic = connection.yLink.debugMessageCharacteristic {
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Subscribing to the yLink Debug characteristic...")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        // Subscribe to the write char and send the PL_AC
        if (writeCharacteristicFound) {
            if let peripheral = connection.peripheral, let characteristic = connection.yLink.writeCharacteristic {
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Subscribing to the yLink Write characteristic...")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    @objc(peripheral:didUpdateNotificationStateForCharacteristic:error:) func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let connection = activeConnectionForPeripheral(peripheral) else {
            yLog(LoggerLevel.warning, category: LoggerCategory.Engine, message: "Didn't find active connection for peripheral \(peripheral.name ?? "nil")")
            self.centralManager .cancelPeripheralConnection(peripheral)
            return
        }
        
        if error != nil {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Failed to subscribe to characteristic \(characteristic.uuid)\n\nError: \(error?.localizedDescription)")
            self.centralManager .cancelPeripheralConnection(peripheral)
            return
        }
        
        if (characteristic.uuid == connection.yLink.writeCharacteristic?.uuid && characteristic.isNotifying) {
            
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Successfully subscribed to the yLink Write characteristic for \(connection)")
            
            guard let pl_accessCredential = self.make_pl_access_credentials(connection) else {
                yLog(LoggerLevel.error, category:.BLE, message:"no PL_AccessCredential found - cannot write back to yLink \(connection.yLink)")
                self.centralManager .cancelPeripheralConnection(peripheral)
                return
            }
            
            if (characteristic.properties.contains(CBCharacteristicProperties.write)) {
                peripheral.writeValue(pl_accessCredential, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Writing WITH Response: PL_AccessCredential:\n\(pl_accessCredential)\nto characteristic:\n\(characteristic)")
            }
            else if (characteristic.properties.contains(CBCharacteristicProperties.writeWithoutResponse)) {
                peripheral.writeValue(pl_accessCredential, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Writing Without Response: PL_AccessCredential:\n\(pl_accessCredential)\nto characteristic:\n\(characteristic)")
            }
            else {
                yLog(LoggerLevel.critical, category: LoggerCategory.BLE, message: "The yLink Write Charasteristic does NOT ALLOW TO WRITE - Dropping")
                self.centralManager .cancelPeripheralConnection(peripheral)
            }
            
        }
            
        else if (characteristic.uuid == connection.yLink.debugMessageCharacteristic?.uuid && characteristic.isNotifying) {
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Successfully subscribed to the yLink Debug characteristic")
        }
    }
    
    
    @objc(peripheral:didWriteValueForCharacteristic:error:) func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        //TODO: Make another attempt before dropping the peripheral:
        
        guard let connection = activeConnectionForPeripheral(peripheral) else {
            yLog(message: "No connection reference found in didWriteValueForCharacteristic - ignoring for peripheral \(peripheral)")
            return
        }
        
        if error != nil {
            
            if connection.writingPLVerify == true {
                // done writing:
                connection.writingPLVerify = false
                // cancel the current report operation and wait for the next round:
                connection.endReportOperation()
            }
            else if connection.writingLCReportAck == true {
                connection.writingLCReportAck = false
                connection.endReportOperation()
            }
            
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Error in didWriteValueForCharacteristic, characteristic: \(characteristic.uuid)\nError: \(error?.localizedDescription) for connection \(connection)")
        }
        else {
            if connection.writingPLVerify == true {
                // done writing:
                connection.writingPLVerify = false
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "[Reporting] Did receive write confirmation for PL_Verify for connection: \(connection)")
//                connection.scheduleReportsTimer()
            }
            else if connection.writingLCReportAck == true {
                // done writing:
                connection.writingLCReportAck = false
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "[Reporting] Did receive write confirmation for LC_ReportAck for connection: \(connection)")
                connection.endReportOperation()
            }
            else {
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Did receive write confirmation for characteristic: \(characteristic)")
            }
        }
    }
    
    
    @objc(peripheral:didUpdateValueForCharacteristic:error:) func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let connection = activeConnectionForPeripheral(peripheral) else {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Missing BLEConnection reference for this characteristic update: \(characteristic)")
            self.centralManager .cancelPeripheralConnection(peripheral)
            return
        }
        
        // dont log for ylink debug messages
        if (characteristic.uuid != CBUUID(string: EngineConstants.YLINK_DEBUG_MESSAGE_UUID)) {
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "Did receive update for characteristic: \(characteristic) for connection \(connection)")
        }
        
        let value = characteristic.value
        
        if error != nil {
            yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Error in didUpdateValueForCharacteristic for connection \(connection) and characteristic \(characteristic)\nError: \(error?.localizedDescription)")
            if let writeChar = connection.yLink.writeCharacteristic {
                // only disconnect if there is an issue with the main characteristic - do not drop the yLink for debug char errors:
                if value == nil {
                    if characteristic.uuid == writeChar.uuid {
                        yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Error for the yLink write char \(writeChar) - Dropping")
                        self.centralManager .cancelPeripheralConnection(peripheral)
                        return
                    }
                    else {
                        yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "Error for the yLink debug char - Ignoring")
                    }
                }
                else {
                    yLog(LoggerLevel.critical, category: LoggerCategory.BLE, message: "Error but char.value was not nil: \(value) for characteristic \(characteristic)")
                }
            }
        }
        
        self.process_incoming_message(characteristic, connection:connection)
    }
    
}



extension BLEEngine {
    
    func addObserver(_ observer: Observer) {
        let index = observers.index { $0 === observer }
        if index == nil {
            observers.append(observer)
        }
    }
    
    func removeObserver(_ observer: Observer) {
        let index = observers.index { $0 === observer }
        if index != nil {
            observers.remove(at: index!)
        }
    }
    
    func removeAllObservers() {
        observers = []
    }
    
    func notifyObservers(_ notification: ObserverNotification) {
        for observer in observers {
            observer.notify(notification)
        }
    }
    
    
}

