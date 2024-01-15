//
//  YLinkReporter.swift
//  Pods
//
//  Created by Roger Mabillard on 2016-09-22.
//
//

import Foundation
import CoreBluetooth

class PL_GetReport: Message {
    override class var identity : UInt8 { return 0x70 } // 112
}

class LP_NoReport: Message {
    override class var identity : UInt8 { return 0x71 } // 113
}

class YLinkReportOperation {
    
    var connection: BLEConnection
    var writeCharacteristic: CBCharacteristic
    
    var readingFullLC_Report: Bool = false
    var lastTimeReceivedLP_NoReport: Date?
    
    var pendingLC_ReportUploads: Int = 0
    var unwrittenCL_ReportAcks: [String] = []
    
    init(connection: BLEConnection, writeCharacteristic:CBCharacteristic) {
        self.connection = connection
        self.writeCharacteristic = writeCharacteristic
    }
}

class YLinkReporter: NSObject {
    
    static let sharedInstance = YLinkReporter()
    
    fileprivate let yLinkServiceUUID = CBUUID(string: EngineConstants.YLINK_SERVICE_UUID)
    fileprivate let writeCharactertisticUUID = CBUUID(string: EngineConstants.YLINK_WRITE_CHAR_UUID)
    
    fileprivate override init() {
        super.init()
    }
    
    func writePL_GetReport(_ operation: YLinkReportOperation) {
        
        let writeChar = operation.writeCharacteristic
        guard let peripheral = operation.connection.peripheral else {
            return
        }
        
        let data = Data(bytes: UnsafePointer<UInt8>([PL_GetReport.identity] as [UInt8]), count: 1)
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "[\(operation.connection.yLink.macAddress)] Writing PL_GetReport...")
        
        if writeChar.properties.contains(CBCharacteristicProperties.write) {
            peripheral.writeValue(data, for: writeChar, type: CBCharacteristicWriteType.withResponse)
        }
        else if writeChar.properties.contains(CBCharacteristicProperties.writeWithoutResponse) {
            peripheral.writeValue(data, for: writeChar, type: CBCharacteristicWriteType.withoutResponse)
        }
        else {
            //TODO: Log / Show error to user
        }
    }
    
    func writeCL_ReportAck(_ operation: YLinkReportOperation, cl_reportAck: String?) {
        
        guard let peripheral = operation.connection.peripheral,
            let cl_reportAck = cl_reportAck else {
                
                yLog(LoggerLevel.error, category: LoggerCategory.BLE, message: "[\(operation.connection.yLink.macAddress)] Could not write CL_ReportAck, something went missing.")
                return
        }
        
        guard let data = cl_reportAck.dataFromHexadecimalString() else {
            return
        }
        
        
        // If we are not connected with ylink, store this CL_ReportAck for later
        if peripheral.state != .connected {
            
            if !operation.unwrittenCL_ReportAcks.contains(cl_reportAck) {
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "[\(operation.connection.yLink.macAddress)] Received a CL_ReportAck, but not writing because not connected. Queuing CL_ReportAck..")
                
                operation.unwrittenCL_ReportAcks.append(cl_reportAck)
            } else {
                yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "[\(operation.connection.yLink.macAddress)] Received a CL_ReportAck, but not writing because not connected. CL_ReportAck already in queue.")
            }
            return
        }
        
        yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "[\(operation.connection.yLink.macAddress)] Writing CL_ReportAck:\n\(cl_reportAck)")
        
        // Remove this CL_ReportAck from list if it exists
        if let index = operation.unwrittenCL_ReportAcks.index(of: cl_reportAck) {
            yLog(LoggerLevel.debug, category: LoggerCategory.BLE, message: "[\(operation.connection.yLink.macAddress)] Popping this CL_ReportAck from queue")
            operation.unwrittenCL_ReportAcks.remove(at: index)
        }
        
        let writeChar = operation.writeCharacteristic
        
        if writeChar.properties.contains(CBCharacteristicProperties.write) {
            peripheral.writeValue(data as Data, for: writeChar, type: CBCharacteristicWriteType.withResponse)
            operation.connection.writingLCReportAck = true
        }
        else if writeChar.properties.contains(CBCharacteristicProperties.writeWithoutResponse) {
            peripheral.writeValue(data as Data, for: writeChar, type: CBCharacteristicWriteType.withoutResponse)
            // there won't be any write confirmation, so this operation is complete:
            if let connection = BLEEngine.sharedInstance.activeConnectionForPeripheral(peripheral) {
                connection.endReportOperation()
            }
        }
        else {
            //TODO: Log / Show error to user
        }
    }
    
}
