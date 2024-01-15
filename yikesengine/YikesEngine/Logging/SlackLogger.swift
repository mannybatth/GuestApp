//
//  SlackLogger.swift
//  YikesEngineSP
//
//  Created by Manny Singh on 4/19/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

class SlackChannel: Mappable {
    var channelName : String!
    var channelHookURL : String!
    
    init(channelName: String, channelHookURL: String) {
        self.channelName = channelName
        self.channelHookURL = channelHookURL
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        channelName     <- map["channel_name"]
        channelHookURL  <- map["channel_hook_url"]
    }
}

class SlackLogger {
    
    static let sharedInstance = SlackLogger()
    
    let slackLoggerQueue = DispatchQueue(label: "com.yikesteam.slacklogger", attributes: [])
    
    static let channels : [SlackChannel] = [
        SlackChannel(channelName: "#mannys-ga-logs", channelHookURL: "https://hooks.slack.com/services/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"),
        SlackChannel(channelName: "#roger-ios-logs", channelHookURL: "https://hooks.slack.com/services/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")
    ]
    
    func sendLogMessage(_ logMessage: LogMessage, channel: SlackChannel) {
        
        slackLoggerQueue.async {
            
            let username = YKSSessionManager.sharedInstance.currentUser?.firstName ?? "guestapp"
            
            let parameters = [
                "channel" : channel.channelName,
                "username" : username,
                "text" : logMessage.message,
                "icon_emoji" : ":ghost:"
            ]
            
            HTTPManager.sharedManager.request(channel.channelHookURL, method: .post, parameters: parameters, encoding: JSONEncoding.default)
                .responseString { response in
                    
                    switch response.result {
                    case .success( _):
                        break
                        
                    case .failure( _):
                        break;
                        
                    }
            }
        }
    }
    
    class func uploadFile(_ fileURL: URL,
                          comment: String?,
                          success: @escaping () -> Void,
                          failure: @escaping (_ error: Error) -> Void) {
        
        HTTPManager.sharedManager.upload(multipartFormData: { (multipartFormData) in
            
            multipartFormData.append(fileURL, withName: "file")
            multipartFormData.append("xoxb-37533103366-cYu7hwnjfj9ipDFY887ucPUm".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "token")
            multipartFormData.append("text".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "filetype")
            multipartFormData.append(fileURL.lastPathComponent.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "filename")
            multipartFormData.append("#ios-ga-logs".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "channels")
            
            if let initialComment = comment {
                multipartFormData.append(initialComment.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "initial_comment")
            }
            
            }, to: "https://slack.com/api/files.upload") { (encodingResult) in
                
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON(completionHandler: { response in
                        
                        switch response.result {
                        case .success(let json):
                            guard let JSON = json as? [String: AnyObject] else {
                                failure(NSError(domain: YikesEngineSP.sharedInstance.bundleIdentifier, code: 0, userInfo: [NSLocalizedDescriptionKey : "Failed to upload logs to Slack. Error: Could not parse server JSON: \(json)"]))
                                return
                            }
                            if JSON["ok"] as? NSNumber == 1 {
                                success()
                            } else {
                                failure(NSError(domain: YikesEngineSP.sharedInstance.bundleIdentifier, code: 0, userInfo: [NSLocalizedDescriptionKey : "Failed to upload logs to Slack. Error: \(JSON["error"])"]))
                            }
                            
                        case .failure(let error):
                            failure(error)
                        }
                        
                    })
                    upload.resume()
                    
                case .failure(let encodingError):
                    failure(encodingError)
                }
                
        }
        
    }
    
}
