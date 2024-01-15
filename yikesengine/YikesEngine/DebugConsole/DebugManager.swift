//
//  DebugManager.swift
//  YikesEngine
//
//  Created by Alexandar Dimitrov on 2016-02-23.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import YikesSharedModel

class DebugManager {
    
    static let sharedInstance = DebugManager()
    
    struct DbgConstants {
        static let maxNumberOfFilteredConsoleLines = 1000
        static let numberOfFilteredConsoleLinesToKeep = 600
        static let maxNumberOfConsoleLines = 2000
        static let numberOfConsoleLinesToKeep = 1000
    }
    
    
    var logs : [LogMessage] = []
    var filteredLogs : [LogMessage] = []
    var maxAllowedLoggerLevel : LoggerLevel = LoggerLevel.info {
        
        willSet(newValue) {
            UserDefaults.standard.set(newValue.rawValue, forKey: EngineConstants.maxAllowedLoggerLevelKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    
    var isYLinkDebuggingDisabled : Bool = false {
        
        willSet(newValue) {
            UserDefaults.standard.set(newValue, forKey: EngineConstants.yLinkDebuggingDisabledKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    var slackRemoteLoggingChannel : SlackChannel? {
        
        willSet(newValue) {
            let json = newValue?.toJSON()
            UserDefaults.standard.set(json, forKey: EngineConstants.slackRemoteLoggingChannelKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    var oldConnections : [BLEConnection] = []
    var activeConnections : [BLEConnection] = []
    
    var description : String {
        return "Logs: \(logs.count) oldConnections: \(oldConnections.count) activeConnections: \(activeConnections.count)"
    }
    
    var debugConsoleVCReference: DebugConsoleVC!
    var activeConnectionsVCReference: DCActiveConnectionsVC!
    var oldConnectionsVCReference: DCOldConnectionsVC!
    
    let serialQueueLogs = DispatchQueue(label: "co.yikesteam.DbgMngr.logsSerialQueue", attributes: [])
    
    func filterOutLogs() {
        self.serialQueueLogs.async {
            
            DispatchQueue.main.sync(execute: {
                
//                #if DEBUG
//                
//                    self.filteredLogs = self.logs.filter( { $0.level.rawValue <= self.maxAllowedLoggerLevel.rawValue && $0.category.rawValue == LoggerCategory.Location.rawValue } )
//                    
//                    #else
                self.filteredLogs = self.logs.filter( {$0.level.rawValue <= self.maxAllowedLoggerLevel.rawValue})
//                    #endif
                
                if (self.isYLinkDebuggingDisabled) {
                    self.filteredLogs = self.filteredLogs.filter({ $0.category != LoggerCategory.YLink })
                }
                
                self.debugConsoleVCReference?.logsVC?.tableView.reloadData()
            })
        }
    }

    
    func logMessage(_ logMessage: LogMessage) {
        
        self.serialQueueLogs.async {

            if self.logs.count > DbgConstants.maxNumberOfConsoleLines {
                self.logs = Array(self.logs.suffix(DbgConstants.numberOfConsoleLinesToKeep))
            }
            
            self.logs.append(logMessage)
            
            // Filtering
            if ((logMessage.category == LoggerCategory.YLink) && self.isYLinkDebuggingDisabled) {
                return
            }
//            
//            #if DEBUG
//                if logMessage.category != .Location {
//                    return
//                }
//            #endif
            
            if (logMessage.level.rawValue > self.maxAllowedLoggerLevel.rawValue) {
                return
            }
            
            if self.debugConsoleVCReference != nil {
                
                DispatchQueue.main.sync(execute: {
                    
                    self.filteredLogs.append(logMessage)
                    let filteredLogsCount = self.filteredLogs.count
                    
//                    if self.debugConsoleVCReference?.logsVC?.isAutoScrollPaused == false {
                    
                        if filteredLogsCount > DbgConstants.maxNumberOfFilteredConsoleLines {
                            self.filteredLogs = Array(self.filteredLogs.suffix(DbgConstants.numberOfFilteredConsoleLinesToKeep))
                            
                            self.debugConsoleVCReference?.logsVC?.tableView.reloadData()
                        }
                        else {
                            if filteredLogsCount > 0 {
                                self.debugConsoleVCReference?.logsVC?.insertLog(filteredLogsCount - 1)
                            }
                        }
//                    }
                })
            }
            
        }
    }
    
    
    func connectionDidStart(_ connection: BLEConnection) {
        
        DispatchQueue.main.async {
            
            var index : Int?
            
            repeat {
                index = DebugManager.sharedInstance.activeConnections.index { $0.yLink.roomNumber == connection.yLink.roomNumber }
                if (index != nil) {
                    self.activeConnections.remove(at: index!)
                    
                    if self.debugConsoleVCReference != nil {
                        self.debugConsoleVCReference?.activeConnectionsVC?.deleteConnection(index!)
                    }
                }
            } while index != nil
            
            self.activeConnections.append(connection)
            
            if self.debugConsoleVCReference != nil {
                
                if 0 == DebugManager.sharedInstance.activeConnections.count {
                    self.debugConsoleVCReference?.activeConnectionsVC?.insertConnection(0)
                }
                else {
                    self.debugConsoleVCReference?.activeConnectionsVC?.insertConnection(DebugManager.sharedInstance.activeConnections.count-1)
                }
            }
            
        }
    }
    
    func connectionDidUpdate(_ connection: BLEConnection) {
        
        DispatchQueue.main.async {
            
            if self.debugConsoleVCReference != nil {
                let index = self.activeConnections.index { $0 == connection }
                
                if (index != nil) {
                    self.debugConsoleVCReference?.activeConnectionsVC?.updateConnection(index!)
                }
                else {
                    // if connection is not found in self.activeConnections
                    // add it and then call again connectionDidUpdate
                    // This is because the engine doesn't call connectionDidStart when
                    // it passes from stationary to moving
                    self.connectionDidStart(connection)
                    self.connectionDidUpdate(connection)
                }
            }
        }
    }
    
    func connectionDidEnd(_ connection: BLEConnection) {
        
        DispatchQueue.main.async {
            
            let index = DebugManager.sharedInstance.activeConnections.index { $0 == connection }
            if (index != nil) {
                self.activeConnections.remove(at: index!)
                
                if self.debugConsoleVCReference != nil {
                    self.debugConsoleVCReference?.activeConnectionsVC?.deleteConnection(index!)
                }
            }
            
            self.oldConnections.append(connection)
            
            if self.debugConsoleVCReference != nil {
                
                if 0 == DebugManager.sharedInstance.oldConnections.count {
                    self.debugConsoleVCReference?.oldConnectionsVC?.insertConnection(0)
                }
                else {
                    self.debugConsoleVCReference?.oldConnectionsVC?.insertConnection(DebugManager.sharedInstance.oldConnections.count-1)
                }
            }
        }
    }
    
    func endAllConnections(_ reason: BLEConnection.ConnectionEndReason) -> () {
        
        for aConnection in self.activeConnections {
            aConnection.connectionEndReason = reason
            self.connectionDidEnd(aConnection)
        }
    }

    // MARK: Users access to debug tools
    func hasAccessToDebugLevel(_ email: String) -> Bool {
        
        let trimmedEmail = email.trimmingCharacters(in: CharacterSet.whitespaces)
        
        if (trimmedEmail.caseInsensitiveCompare("alexandar.dimitrov@yikes.co") == ComparisonResult.orderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("manny.singh@yikes.co") == ComparisonResult.orderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("richardm@yikes.co") == ComparisonResult.orderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("roger.mabillard@yikes.co") == ComparisonResult.orderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("chad.coons@yikes.co") == ComparisonResult.orderedSame) {
            return true
        }
        
        if (trimmedEmail.lowercased().hasSuffix("@yamm.ca")) {
            return true
        }
        
        return false
    }
    
    
    func hasAccessToYLinkLPDebug(_ email: String) -> Bool {
        
        let trimmedEmail = email.trimmingCharacters(in: CharacterSet.whitespaces)
        
        if (trimmedEmail.caseInsensitiveCompare("alexandar.dimitrov@yikes.co") == ComparisonResult.orderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("manny.singh@yikes.co") == ComparisonResult.orderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("richardm@yikes.co") == ComparisonResult.orderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("roger.mabillard@yikes.co") == ComparisonResult.orderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("chad.coons@yikes.co") == ComparisonResult.orderedSame) {
            return true
        }
        
        if (trimmedEmail.lowercased().hasSuffix("@yamm.ca")) {
            return true
        }
        
        return false
    }
    
}
