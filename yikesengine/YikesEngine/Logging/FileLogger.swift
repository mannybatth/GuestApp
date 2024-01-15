//
//  FileLogger.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/5/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

class FileLogger {

    static let sharedInstance = FileLogger()
    
    let loggerQueue = DispatchQueue(label: "com.yikesteam.filelogger", attributes: [])
    
    var _currentLogFileHandle : FileHandle?
    var _currentLogFileInfo : LogFileInfo?
    
    var fileSizeCheckCounter: Int = 0
    
    #if DEBUG
    static let fileSizeLimit: UInt64 = 1000000 // 1MB
    #else
    static let fileSizeLimit: UInt64 = 400000 // 400KB
    #endif
    
    static let fileSizeCheckInterval: Int = 100 // Check file size each 100 messages
    
    #if DEBUG
    static let maximumNumberOfLogFiles: Int = 30
    #else
    static let maximumNumberOfLogFiles: Int = 10
    #endif
    
    init() {
        
    }
    
    func logMessage(_ logMessage: LogMessage) {
        
        loggerQueue.async {
            
            if let logData = self.formattedLogMessage(logMessage).data(using: String.Encoding.utf8) {
                
                self.currentLogFileHandle().write(logData)
                
                if self.fileSizeCheckCounter > FileLogger.fileSizeCheckInterval {
                    self.fileSizeCheckCounter = 0
                    
                    let fileSize = self.currentLogFileHandle().offsetInFile
                    
                    if fileSize > FileLogger.fileSizeLimit {
                        
                        let message = LogMessage(level: LoggerLevel.info, category: LoggerCategory.Engine, timestamp: Date(), message: "Log file size reached maximum.", filePath: #file, functionName: #function, lineNumber: #line)
                        if let messageData = self.formattedLogMessage(message).data(using: String.Encoding.utf8) {
                            self.currentLogFileHandle().write(messageData)
                        }
                        
                        self.rollLogFileNowSync()
                    }
                }
                else {
                    self.fileSizeCheckCounter += 1
                }
                
            }
        }
    }
    
    func formattedLogMessage(_ logMessage: LogMessage) -> String {
        
        var message = String(logMessage.message)
        if !(message?.hasSuffix("\n"))! {
            message = message?.appending("\n")
        }
        
        let timeStampString = DateHelper.sharedInstance.dateFormatterWithMilliSec.string(from: logMessage.timestamp)
        let levelString = logMessage.level.description
        let categoryString = logMessage.category.rawValue
        
        return timeStampString + "  " + "[\(levelString) - \(categoryString)]" + "  " + message!
    }
    
    func addHeaderDataToCurrentLogFileIfNeeded() {
        
        // check if pointer is at position 0 (assume file is blank)
        if (currentLogFileHandle().offsetInFile == 0) {
            addHeaderDataToCurrentLogFile()
        }
    }
    
    func addHeaderDataToCurrentLogFile() {
        
        let headerString = FileLoggerHelper.logFileHeaderData(currentLogFileInfo())
        if let headerData = headerString.data(using: String.Encoding.utf8) {
            currentLogFileHandle().write(headerData)
        }
    }
    
    func currentLogFileInfo() -> LogFileInfo {
        
        if (_currentLogFileInfo == nil) {
            
            // get a list of logs files already on file
            let logFileInfos = FileLoggerHelper.sortedLogFileInfos()
            
            if (logFileInfos.count > 0) {
                
                // select the most recent file (only if it's not archived)
                
                let mostRecentFileInfo = logFileInfos[0]
                
                if (!mostRecentFileInfo.isArchived) {
                    _currentLogFileInfo = mostRecentFileInfo
                }
            }
            
            if (_currentLogFileInfo == nil) {
                
                let newLogFileURL = FileLoggerHelper.createNewLogFile()
                _currentLogFileInfo = LogFileInfo(filePathURL: newLogFileURL)
                
                // a new log file was created, see if we can remove old ones
                deleteOldLogFiles()
            }
        }
        
        return _currentLogFileInfo!
    }
    
    func currentLogFileHandle() -> FileHandle {
        
        if (_currentLogFileHandle == nil) {
            
            let logFilePathURL = currentLogFileInfo().filePathURL
            
            _currentLogFileHandle = try? FileHandle(forWritingTo: logFilePathURL as URL)
            _currentLogFileHandle?.seekToEndOfFile()
            
            addHeaderDataToCurrentLogFileIfNeeded()
        }
        
        return _currentLogFileHandle!
    }
    
    func rollLogFileNow() {
        
        loggerQueue.async {
            self.rollLogFileNowSync()
        }
    }
    
    func rollLogFileNowSync() {
        
        if (self._currentLogFileHandle == nil) {
            return
        }
        
        let message = LogMessage(level: LoggerLevel.info, category: LoggerCategory.Engine, timestamp: Date(), message: "Rolling log file now...", filePath: #file, functionName: #function, lineNumber: #line)
        if let messageData = self.formattedLogMessage(message).data(using: String.Encoding.utf8) {
            self.currentLogFileHandle().write(messageData)
        }
        
        self._currentLogFileHandle?.synchronizeFile()
        self._currentLogFileHandle?.closeFile()
        self._currentLogFileHandle = nil
        
        self._currentLogFileInfo?.isArchived = true
        
        self._currentLogFileInfo = nil
    }
    
    func deleteOldLogFiles() {
        
        let fileInfos = FileLoggerHelper.sortedLogFileInfos()
        let maximumNumberOfLogFiles = FileLogger.maximumNumberOfLogFiles
        
        if (fileInfos.count <= maximumNumberOfLogFiles) {
            return
        }
        
        let firstIndexToDelete = maximumNumberOfLogFiles
        
        for i in firstIndexToDelete..<fileInfos.count {
            
            let fileInfoToDelete = fileInfos[i]
            _ = try? FileManager.default.removeItem(at: fileInfoToDelete.filePathURL as URL)
        }
    }
    
}
