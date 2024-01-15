//
//  StayShareRequests.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/25/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import Alamofire
import AlamofireObjectMapper

extension StayShare {
    
    class func getStayShares(
        _ userId: Int,
        success: @escaping (_ stayShares: [StayShare]?) -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        let stayShareRequest = try! Router.getStaySharesForUser(userId)
        
        let request = HTTPManager.sharedManager.request(stayShareRequest)
        request.validate()
        _ = request.responseArray(keyPath: "response_body.stay_shares") { (response:DataResponse<[StayShare]>) -> Void in
            
            switch response.result {
            case .success(let stayShares):
                
                YKSSessionManager.sharedInstance.currentUser?.stayShares = stayShares
                StoreManager.sharedInstance.saveCurrentUser()
                
                success(stayShares)
            case .failure( _):
                failure(YKSError.errorFromResponse(response))
            }
        }
    }
    
    class func createStayShare(
        _ stayId: Int,
        userId: Int,
        success: @escaping (_ stayShareId: Int?) -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
            
        let parameters:[String: AnyObject] = [
                "user_id": userId as AnyObject,
            ]
        
        let stayShareRequest = try! Router.createStaySharesForStay(stayId, parameters)
        
        let request = HTTPManager.sharedManager.request(stayShareRequest)
        request.validate().responseJSON { response in
            
            switch response.result {
            case .success( _):
                
                if let stayShareLocation = response.response?.allHeaderFields["Location"] as? String,
                    let url = URL(string: stayShareLocation),
                    let stayShareId = Int(url.lastPathComponent) {
                    
                    success(stayShareId)
                    
                } else {
                    failure(YKSError.newWith(.unknown, errorDescription: "id for stayshare not found in headers"))
                }
                
            case .failure( _):
                failure(YKSError.errorFromResponse(response))
            }
        }
    }
    
    class func updateStayShareStatus(
        _ stayShareId: Int,
        stayId: Int,
        status: String,
        success: @escaping () -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        let parameters = [
            "status": status,
            ]
        
        let updateStayShareRequest = try! Router.updateStayShare(stayShareId, stayId, parameters)
        let request = HTTPManager.sharedManager.request(updateStayShareRequest)
        request.validate().responseJSON { response in
            
            switch response.result {
            case .success( _):
                success()
            case .failure( _):
                failure(YKSError.errorFromResponse(response))
            }
        }
    }
    
}
