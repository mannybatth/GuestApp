//
//  YLinkRequests.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/27/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import Alamofire
import AlamofireObjectMapper

extension YLink {
    
    class func uploadEncryptionKey(
        _ lc_keyInfo: String,
        success: @escaping (_ serialNumber: String?, _ cl_keyAccept: String?) -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        let parameters = [
            "lc_key_info": lc_keyInfo
        ]
        
        let uploadEncryptionKeyRequest = try! Router.updateYLinkEncryptionKey(parameters)
        
        let request = HTTPManager.sharedManager.request(uploadEncryptionKeyRequest)
        request.validate().responseJSON { response in
            
            switch response.result {
            case .success:
                if let JSON = response.result.value as? [String: AnyObject] {
                    if let serialNumber = JSON["serial_number"] as? String,
                        let cl_keyAccept = JSON["cl_key_accept"] as? String {
                        
                        success(serialNumber, cl_keyAccept)
                        return
                    }
                }
                
                success(nil, nil)
                
            case .failure:
                failure(YKSError.errorFromResponse(response))
            }
            
        }
    }
    
    func sendTimeSyncRequest(
        _ lc_timeSync: String,
        success: @escaping (_ cl_timeSync: String?) -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        let parameters = [
            "lc_time_sync": lc_timeSync
        ]
        
        yLog(LoggerLevel.debug, category: LoggerCategory.API, message: "sendTimeSyncRequest PUT parameters are:\n\(parameters)")
        
        guard let macAddress = self.macAddress else {
            return
        }
        
        let timeSyncRequestRequest = try! Router.yLinkTimeSyncRequest(macAddress, parameters)
        
        let request = HTTPManager.sharedManager.request(timeSyncRequestRequest)
        request.validate().responseJSON { response in
            
            switch response.result {
            case .success:
                
                if let data = response.result.value as? [String: Any],
                let response_body = data["response_body"] as? [String: Any],
                    let cl_timeSync = response_body["cl_time_sync"] as? String {
                    success(cl_timeSync)
                    return
                }
                
                success(nil)
                
            case .failure:
                failure(YKSError.errorFromResponse(response))
            }
            
        }
        
    }
    
    func uploadReport(
        macAddress : String,
        lc_report : LC_Report,
        success: @escaping (_ cl_reportAck: String) -> Void,
        failure: @escaping (_ error: YKSError, _ response: HTTPURLResponse?) -> Void) {
        
        guard let hexa_lc_report = lc_report.rawData?.hexadecimalString() else {
            yLog(message: "Could not get the hexadecimal String from the lc_report data")
            return
        }
        
        let parameters : [String: Any] = [
            "mac_address" : macAddress,
            "lc_report" : hexa_lc_report
        ]
        
        yLog(LoggerLevel.debug, category: LoggerCategory.API, message: "[\(macAddress)] Uploading LC_Report to server... \n\(parameters)")
        
        let uploadReportRequest = try! Router.uploadYLinkReport(parameters)
        
        let request = HTTPManager.sharedManager.request(uploadReportRequest)
            request.validate().responseJSON { response in
                
                switch response.result {
                case .success:
                    
                    if let value = response.result.value as? [String: Any], let cl_reportAck = value["cl_report_ack"] as? String {
                        success(cl_reportAck)
                        return
                    }
                    else {
                        let error = NSError.init(domain: YikesEngineSP.sharedInstance.bundleIdentifier, code: (YKSErrorCode.failureConnectingToYikesServer) as! Int, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("No CL_ReportAck returned from server", comment: "")])
                        failure(YKSError.newWith(YKSErrorCode.serverSidePayloadValidation, errorDescription: "No CL_ReportAck returned from server", nsError: error), response.response)
                    }
                    
                case .failure (let error):
                        //TODO: Reconsider retry logic eventually:
//                    User.reloginIfUserForbidden(response.response, success: {
//                        self.uploadReport(macAddress, lc_report: lc_report, success: success, failure: failure)
//                        }, failure: {
//                            failure(error: response.result.error)
//                    })
                    
                    let error = NSError.init(domain: YikesEngineSP.sharedInstance.bundleIdentifier, code: Int(YKSErrorCode.failureConnectingToYikesServer.rawValue), userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("No CL_ReportAck returned from server", comment: "")])
                    failure(YKSError.newWith(.unknown, errorDescription: "Error: \(error).\nFailed to upload the yLink report:\n\(lc_report)", nsError: error), response.response)
                }
        }
    }
    
}
