//
//  FileLoggerHelper.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/5/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

class LogFileInfo: CustomStringConvertible {
    
    var filePathURL : URL
    
    var fileName : String {
        return filePathURL.lastPathComponent
    }
    
    internal var description: String {
        let desc = "\nfilePathURL: \(filePathURL.absoluteString)"
        + "\nfileName: \(fileName)"
        + "\nisArchived: \(isArchived.description)"
        
        return desc
    }
    
    fileprivate var _fileAttributes : [FileAttributeKey : Any]?
    var fileAttributes : [FileAttributeKey : Any]? {
        
        if (_fileAttributes == nil) {
            _fileAttributes = try? FileManager.default.attributesOfItem(atPath: filePathURL.path)
        }
        
        return _fileAttributes
    }
    
    var creationDate : Date? {
        return fileAttributes?[FileAttributeKey.creationDate] as? Date
    }
    
    var modificationDate : Date? {
        return fileAttributes?[FileAttributeKey.modificationDate] as? Date
    }
    
    var fileSize : CUnsignedLongLong? {
        return (fileAttributes?[FileAttributeKey.size] as! NSNumber).uint64Value
    }
    
    var age: TimeInterval? {
        if let date = creationDate {
            return NSDate().timeIntervalSince(date)
        }
        else {
            return nil
        }
    }
    
    var isArchived: Bool {
        get {
            
            let fileName = filePathURL.deletingPathExtension().lastPathComponent
            
            if fileName.hasSuffix(FileLoggerHelper.logFileArchivedSuffix) {
                return true
            }
            return false
            
        }
        set(value) {
            
            let ext = filePathURL.pathExtension
            let pathWithoutExt = filePathURL.deletingPathExtension()
            var fileName = pathWithoutExt.lastPathComponent
            
            if value {
                
                // add .archived to filename
                if !fileName.hasSuffix(FileLoggerHelper.logFileArchivedSuffix) {
                    fileName += FileLoggerHelper.logFileArchivedSuffix
                    renameFile(fileName + "." + ext)
                }
            
            } else {
                
                // remove .archived from filename
                if fileName.hasSuffix(FileLoggerHelper.logFileArchivedSuffix) {
                    let pathWithoutSuffix = pathWithoutExt.deletingPathExtension()
                    renameFile(pathWithoutSuffix.lastPathComponent + "." + ext)
                }
            }
        }
    }
    
    init(filePathURL: URL) {
        
        self.filePathURL = filePathURL
    }
    
    func renameFile(_ newFileName: String) {
        
        if (newFileName != fileName) {
            
            let newFilePathURL = filePathURL.deletingLastPathComponent().appendingPathComponent(newFileName)
                
            if (newFilePathURL as NSURL).checkResourceIsReachableAndReturnError(nil) {
                _ = try? FileManager.default.removeItem(at: newFilePathURL)
            }
            
            _ = try? FileManager.default.moveItem(at: filePathURL, to: newFilePathURL)
            
            filePathURL = newFilePathURL
            _fileAttributes = nil
        }
        
    }
    
    func reverseCompareByCreationDate(_ another: LogFileInfo) -> ComparisonResult {
        
        let us = creationDate
        let them = another.creationDate
        
        let result = us?.compare(them!)
        
        if (result == .orderedAscending) {
            return .orderedDescending
        }
        
        if (result == .orderedDescending) {
            return .orderedAscending
        }
        
        return .orderedSame
    }
}


class FileLoggerHelper {
    
    static let logFileNamePrefix = "yikes"
    static let logFileNameExtension = "txt"
    static let logFileArchivedSuffix = ".archived"
    
    class func logsDirectory() -> URL {
        
        let engineDirectoryURL = CacheHelper.engineCacheDirectoryURL()
        let logsDirectoryURL = engineDirectoryURL.appendingPathComponent("SessionLogs")
        
        if !(logsDirectoryURL as NSURL).checkResourceIsReachableAndReturnError(nil) {
            _ = try? FileManager.default.createDirectory(at: logsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return logsDirectoryURL
    }
    
    class func newLogFileName() -> String {
        
        let timestamp = DateHelper.sharedInstance.simpleDateFormatterWithTime.string(from: Date())
        let name = "\(FileLoggerHelper.logFileNamePrefix) \(timestamp).\(FileLoggerHelper.logFileNameExtension)".replacingOccurrences(of: ":", with: "-")
        
        return name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    }
    
    class func createNewLogFile() -> URL {
        
        let fileURL = URL(string: newLogFileName())!
        let directory = logsDirectory()
        
        var attempt = 1
        
        repeat {
            
            var actualFileURL = fileURL
            
            if (attempt > 1) {
                let ext = actualFileURL.pathExtension
                actualFileURL = actualFileURL.deletingPathExtension()
                
                let newName = "\(actualFileURL.lastPathComponent) \(attempt)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                actualFileURL = URL(string: newName)!
                
                if (ext.characters.count > 0) {
                    actualFileURL = actualFileURL.appendingPathExtension(ext)
                }
            }
            
            let filePathURL = directory.appendingPathComponent(actualFileURL.path)
            
            if (!(filePathURL as NSURL).checkResourceIsReachableAndReturnError(nil)) {
                
                FileManager.default.createFile(atPath: filePathURL.path, contents: nil, attributes: nil)
                return filePathURL
                
            } else {
                attempt += 1
            }
            
        } while (true)
    }
    
    class func logFileHeaderData(_ fileInfo: LogFileInfo) -> String {
        
        var email = "No user found"
        if let user = YikesEngineSP.sharedEngine().userInfo {
            email = user.email
        }
        
        DeviceHelper.sharedInstance.rebuildVersionInfo()
        let info = DeviceHelper.sharedInstance.info
        
        let path            = "Full session logs path and filename: \(fileInfo.filePathURL.path)"
        
        let model           = "Device model:    \(info?["model"]!)"
        let appVersion      = "GA version:      v\(DeviceHelper.sharedInstance.fullGuestAppVersion())"
        let appBundleId     = "GA Bundle Id:    \(DeviceHelper.sharedInstance.guestAppBundleIdentifier())"
        let engineVersion   = "Engine version:  v\(info?["EngineV"]!)"
        let engineMode      = "Engine mode:     SinglePath"
        let osVersion       = "iOS version:     \(info?["osV"]!)"
        let userEmail       = "User email:      \(email)"
        let apiEnv          = "API env:         \(YikesEngineSP.sharedEngine().currentApiEnv.stringValue)"
        
        let creationDate    = "Full session logs started at \(DateHelper.sharedInstance.simpleDateFormatterWithTimeZone.string(from: fileInfo.creationDate!))"
        
        let header = path + "\n\n" +
            model + "\n" +
            appVersion + "\n" +
            appBundleId + "\n" +
            engineVersion + "\n" +
            engineMode + "\n" +
            osVersion + "\n" +
            userEmail + "\n" +
            apiEnv + "\n\n" +
            creationDate + "\n\n"
        
        return header
    }
    
    class func sortedLogFileInfos() -> [LogFileInfo] {
        
        let directory = FileLoggerHelper.logsDirectory()
        
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [], options: [.skipsHiddenFiles])
            else { return [] }
        
        var unsortedListOfFileInfos : [LogFileInfo] = []
        
        for fileURL in fileURLs {
            
            if (fileURL.lastPathComponent.hasPrefix(FileLoggerHelper.logFileNamePrefix)) {
                unsortedListOfFileInfos.append(LogFileInfo(filePathURL: fileURL))
            }
        }
        
        let sortedListOfFileInfos : [LogFileInfo] = unsortedListOfFileInfos.sorted {
            return $0.reverseCompareByCreationDate($1) == .orderedAscending
        }
        
        return sortedListOfFileInfos
    }
    
}
