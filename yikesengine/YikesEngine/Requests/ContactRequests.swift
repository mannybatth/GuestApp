//
//  ContactRequests.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/25/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import Alamofire
import AlamofireObjectMapper

extension Contact {
    
    class func getUserContacts(
        _ userId: Int,
        success: @escaping (_ contacts: [Contact]?) -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        let userContactRequest = try! Router.getContactsForUser(userId)
        
        let request = HTTPManager.sharedManager.request(userContactRequest)
        request.validate()
        _ = request.responseArray(keyPath: "response_body.contacts") { (response: DataResponse<[Contact]>) -> Void in
            
            switch response.result {
            case .success(let contacts):
                
                YKSSessionManager.sharedInstance.currentUser?.recentContacts = contacts
                StoreManager.sharedInstance.saveCurrentUser()
                
                success(contacts)
                
            case .failure:
                failure(YKSError.errorFromResponse(response))
            }
        }
        
    }
    
    class func deleteUserContact(
        _ contactId: Int,
        userId: Int,
        success: @escaping () -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        let deleteUserContactRequest = try! Router.deleteContact(contactId, userId)
            
        let request = HTTPManager.sharedManager.request(deleteUserContactRequest)
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
