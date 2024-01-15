//
//  DeviceHelper.swift
//  YikesEngine
//
//  Created by Manny Singh on 12/21/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

class DeviceHelper {
    
    static let sharedInstance = DeviceHelper()
    
    var clientVersionInfo : String {
        self.rebuildVersionInfo()
        
        var clientInfo : String = ""
        for (key, value) in info {
            clientInfo += "\(key):\(value);"
        }
        return clientInfo
    }
    
    var info : [String: String]!
    
    init() {
        
        info = [
            "os": "iOS",
            "osV": osVersion(),
            "EngineV": engineVersion(),
            "GAppV": guestAppVersion(),
            "GAppB": guestAppBuild(),
            "model": phoneModel(),
        ]
    }
    
    func rebuildVersionInfo() {
        
        info["osV"] = osVersion()
        info["EngineV"] = engineVersion()
        info["GAppV"] = guestAppVersion()
        info["GAppB"] = guestAppBuild()
    }
    
    func osVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    func engineVersion() -> String {
        if let url = YikesEngineSP.sharedInstance.bundleURL() {
            let bundle = Bundle(url: url)
            guard let infoDict = bundle?.infoDictionary,
                  let v = infoDict["CFBundleShortVersionString"] as? String,
                  let b = infoDict["CFBundleVersion"] as? String
                    else { return "" }
            
            return "\(v) b\(b)"
        }
        return ""
    }
    
    func guestAppVersion() -> String {
        guard let infoDict = Bundle.main.infoDictionary,
              let version = infoDict["CFBundleShortVersionString"] as? String
            else { return "" }
        
        return version
    }
    
    func guestAppBuild() -> String {
        guard let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
            else { return "" }
        return build
    }
    
    func fullGuestAppVersion() -> String {
        var fullVersion = "\(guestAppVersion()) (\(guestAppBuild()))"
        #if DEBUG
            fullVersion += " d"
        #endif
        return fullVersion
    }
    
    func guestAppBundleIdentifier() -> String {
        if let mainBundleString = Bundle.main.bundleIdentifier {
            return mainBundleString
        }
        else {
            return "[no bundle identifer]"
        }
    }
    
    func phoneModel() -> String {
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod1,1":                                 return "iPod Touch 1"
        case "iPod2,1":                                 return "iPod Touch 2"
        case "iPod3,1":                                 return "iPod Touch 3"
        case "iPod4,1":                                 return "iPod Touch 4"
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone1,2":                               return "iPhone 3g"
        case "iPhone2,1":                               return "iPhone 3gs"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPad1,1":                                 return "iPad 1"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
        
    }
    
}
