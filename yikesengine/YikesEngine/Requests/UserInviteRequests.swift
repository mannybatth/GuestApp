//
//  UserInviteRequests.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/25/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import Alamofire
import AlamofireObjectMapper

extension UserInvite {
    
    class func getUserInvites(
        _ userId: Int,
        success: @escaping (_ userInvites: [UserInvite]?) -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        let userInvitesRequest = try! Router.getUserInvitesForUser(userId)
        
        let request = HTTPManager.sharedManager.request(userInvitesRequest)
        request.validate()
        
        _ = request.responseArray(keyPath: "response_body.invites") { (response: DataResponse<[UserInvite]>) -> Void in
            
            switch response.result {
            case .success(let userInvites):
                
                YKSSessionManager.sharedInstance.currentUser?.userInvites = userInvites
                StoreManager.sharedInstance.saveCurrentUser()
                
                success(userInvites)
                
            case .failure( _):
                failure(YKSError.errorFromResponse(response))
            }
        }
    }
    
    class func createUserInvite(
        _ stayId: Int,
        fromUserId: Int,
        toEmail: String,
        success: @escaping (_ inviteId: Int?) -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        let parameters : [String: AnyObject] = [
            "email": toEmail as AnyObject,
            "related_stay_id": stayId as AnyObject
        ]
        
        let createUserInviteRequest = try! Router.createUserInviteForUser(fromUserId, parameters)
        
        let request = HTTPManager.sharedManager.request(createUserInviteRequest)
        request.validate().responseJSON { response in
            
            switch response.result {
            case .success( _):
                
                if let userInviteLocation = response.response?.allHeaderFields["Location"] as? String,
                    let url = URL(string: userInviteLocation),
                    let userInviteId = Int(url.lastPathComponent) {
                    
                    success(userInviteId)
                    
                } else {
                    failure(YKSError.newWith(.unknown, errorDescription: "id for userInvite not found in headers"))
                }
                
            case .failure( _):
                failure(YKSError.errorFromResponse(response))
            }
            
        }
    }
    
    class func deleteUserInvite(
        _ inviteId: Int,
        userId: Int,
        success: @escaping () -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        let deleteUserInviteRequest = try! Router.deleteUserInvite(inviteId, userId)
        
        let request = HTTPManager.sharedManager.request(deleteUserInviteRequest)
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
