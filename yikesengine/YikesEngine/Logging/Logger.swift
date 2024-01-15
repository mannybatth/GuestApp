//
//  Logger.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/5/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import AudioToolbox

import Alamofire

import YikesSharedModel

enum LoggerLevel : Int {
    
    
    case external = -1
    case critical = 1
    case error
    case warning
    case info
    case debug
    
    var description : String {
        get {
            switch (self) {
            case .external:
                return "EXTRN"
            case .critical:
                return "CRITI"
            case .error:
                return "ERROR"
            case .warning:
                return "WARN "
            case .info:
                return "INFO "
            case .debug:
                return "DEBUG"
            }
        }
    }
}

enum LoggerCategory : String {
    
    case System     = "SYS"
    case BLE        = "BLE"
    case API        = "API"
    case Device     = "DVC"
    case Service    = "SVC"
    case YLink      = "YLK"
    case Engine     = "ENG"
    case Encryption = "ENC"
    case Location   = "LOC"
    case App        = "APP"
}

class LogMessage {
    
    var level : LoggerLevel
    var category : LoggerCategory
    var timestamp : Date
    var message : String
    
    var filePath: String
    var functionName : String
    var lineNumber: Int
    var isFatal: Bool
    
    var tableViewCellHeight : CGFloat?
    
    init(level: LoggerLevel, category: LoggerCategory, timestamp: Date, message: String, filePath: String, functionName: String, lineNumber: Int) {
        self.level = level
        self.category = category
        self.timestamp = timestamp
        self.message = message
        self.filePath = filePath
        self.functionName = functionName
        self.lineNumber = lineNumber
        self.isFatal = false
    }

    init(level: LoggerLevel, category: LoggerCategory, timestamp: Date, message: String, filePath: String, functionName: String, lineNumber: Int, isFatal: Bool) {
        self.level = level
        self.category = category
        self.timestamp = timestamp
        self.message = message
        self.filePath = filePath
        self.functionName = functionName
        self.lineNumber = lineNumber
        self.isFatal = isFatal
    }
    
}

func fireLocalNotification (_ message:String) {
//    #if DEBUG
    if let user = YKSSessionManager.sharedInstance.currentUser, let email = user.email {
        let show = (email.contains("@yamm.ca") || email.contains("@yikes.co"))
        if show {
            let localNotif = UILocalNotification()
            localNotif.alertBody = String("\(message)");
            localNotif.alertAction = NSLocalizedString("Relaunch", comment: "Relaunch")
            localNotif.soundName = UILocalNotificationDefaultSoundName;
            UIApplication.shared.presentLocalNotificationNow(localNotif)
            yLog(message: message)
        }
    }
//    #endif
}

func yLog(_ level: LoggerLevel = .debug, category: LoggerCategory = .System, message: String, filePath: String = #file, functionName: String = #function, lineNumber: Int = #line, isFatal: Bool = false) {
    
    let now = Date()
    let logMessage = LogMessage(level: level, category: category, timestamp: now, message: message, filePath: filePath, functionName: functionName, lineNumber: lineNumber, isFatal: isFatal)
    
    if let email = YKSSessionManager.sharedInstance.currentUser?.email {
        
        if (DebugManager.sharedInstance.hasAccessToDebugLevel(email)) {
            
            if isFatal {
                AudioServicesPlayAlertSound(1116);  // 1006 is good too
            }
            
            if let slackRemoteLoggingChannel = DebugManager.sharedInstance.slackRemoteLoggingChannel {
                if logMessage.level.rawValue <= LoggerLevel.info.rawValue && logMessage.level.rawValue != LoggerLevel.external.rawValue {
                    SlackLogger.sharedInstance.sendLogMessage(logMessage, channel: slackRemoteLoggingChannel)
                }
            }
        }
    }
    
    FileLogger.sharedInstance.logMessage(logMessage)
    DebugManager.sharedInstance.logMessage(logMessage)
    
//    #if DEBUG
//    if (category == .Location) {
//        yPrint(logMessage.message, level: logMessage.level, timestamp: now, filePath: logMessage.filePath, functionName: logMessage.functionName, lineNumber: logMessage.lineNumber)
//    }
//    #else
    
    yPrint(logMessage.message, level: logMessage.level, timestamp: now, filePath: logMessage.filePath, functionName: logMessage.functionName, lineNumber: logMessage.lineNumber)
    
//    #endif
    
}


func yPrint(_ message: String, level: LoggerLevel = .debug, timestamp: Date = Date(), filePath: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    
    let dateString = DateHelper.sharedInstance.simpleDateFormatterWithMilliSec.string(from: timestamp)
    if let fileName = NSURL(string: filePath)?.deletingPathExtension?.lastPathComponent {
        print("\(dateString) [\(level)][\(fileName) \(functionName): \(lineNumber)] \(message)")
    } else {
        print("\(dateString) [\(level)][\(functionName): \(lineNumber)] \(message)")
    }
}


class NetworkLogger {
    
    class func logDivider() {
        print("---------------------")
    }
    
    class func logError(_ error: NSError) {
        logDivider()
        
        yLog(LoggerLevel.debug, category: LoggerCategory.API, message: "Error: \(error.localizedDescription)")
        
        if HTTPManager.networkLogStyle == .verbose {
            if let reason = error.localizedFailureReason {
                print("Reason: \(reason)")
            }
            
            if let suggestion = error.localizedRecoverySuggestion {
                print("Suggestion: \(suggestion)")
            }
        }
    }
    
    class func logRequest(_ request: Request) {
        logDivider()
        
        guard let req = request.request else {
            return
        }
        
        if let url = req.url?.absoluteString {
            let currentReachability = ServicesManager.sharedInstance.reachabilityManager?.networkReachabilityStatus
            yLog(LoggerLevel.debug, category: LoggerCategory.API, message: "[\(request.task!.taskIdentifier)] + \(req.httpMethod!) \(url) [cookie: \(YKSSessionManager.sharedInstance.getSessionCookie()?.value ?? "nil")] [type: \(currentReachability)]")
        }
        
        if HTTPManager.networkLogStyle == .verbose {
            if let headers = req.allHTTPHeaderFields {
                self.logHeaders(headers as [String : AnyObject])
            }
        }
    }
    
    class func logResponse(_ response: URLResponse, dataTask: URLSessionTask, data: Data? = nil) {
        logDivider()
        
        if let url = response.url?.absoluteString,
            let httpResponse = response as? HTTPURLResponse {
            let currentReachability = ServicesManager.sharedInstance.reachabilityManager?.networkReachabilityStatus
            yLog(LoggerLevel.debug, category: LoggerCategory.API, message: "[\(dataTask.taskIdentifier)] - \(httpResponse.statusCode) \(url) [cookie: \(YKSSessionManager.sharedInstance.getSessionCookie()?.value ?? "nil")] [type: \(currentReachability)]")
        }
        
        if HTTPManager.networkLogStyle == .verbose {
            if let headers = (response as? HTTPURLResponse)?.allHeaderFields {
                self.logHeaders(headers)
            }
            
            guard let data = data else { return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                let pretty = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                
                if let string = NSString(data: pretty, encoding: String.Encoding.utf8.rawValue) {
                    print("JSON: \(string)")
                }
            }
                
            catch {
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    print("Data: \(string)")
                }
            }
        }
    }
    
    class func logHeaders(_ headers: [AnyHashable: Any]) {
        print("Headers: [")
        for (key, value) in headers {
            print("  \(key) : \(value)")
        }
        print("]")
    }
}
