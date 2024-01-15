//
//  CacheHelper.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/18/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import ObjectMapper

class CacheHelper {
    
    class func engineCacheDirectoryURL() -> URL {
        
        let cacheDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let engineCacheDirectoryURL = cacheDirectoryURL.appendingPathComponent(YikesEngineSP.sharedInstance.bundleIdentifier)
        
        if !(engineCacheDirectoryURL as NSURL).checkResourceIsReachableAndReturnError(nil) {
            _ = try? FileManager.default.createDirectory(at: engineCacheDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return engineCacheDirectoryURL
    }
    
    class func pathForRootObjectOfCacheName(_ cacheName: String) -> URL {
        return engineCacheDirectoryURL().appendingPathComponent(cacheName)
    }
    
    class func getObjectWithCacheName<T: Mappable>(_ cacheName: String) -> T? {
        if let JSONDictionary = NSKeyedUnarchiver.unarchiveObject(withFile: pathForRootObjectOfCacheName(cacheName).path) as? [String : Any] {
            return Mapper<T>().map(JSON: JSONDictionary)
        }
        else {
            return nil
        }
    }
    
    class func saveObjectToCache<T: Mappable>(_ obj: T, cacheName: String) {
        let JSONDictionary = Mapper().toJSON(obj)
        let saved = NSKeyedArchiver.archiveRootObject(JSONDictionary, toFile:pathForRootObjectOfCacheName(cacheName).path)
        if saved == true {
            yLog(.debug, message: "Successfully saved to cache")
        }
        else {
            yLog(message: "Failed to saved to cache object:\n\(JSONDictionary)")
        }
    }
    
    class func removeObjectWithCacheName(_ cacheName: String) {
        
        let path = pathForRootObjectOfCacheName(cacheName).path
        if (FileManager.default.fileExists(atPath: path)) {
            _ = try? FileManager.default.removeItem(atPath: path)
        }
    }
    
}
