//
//  Router.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/17/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation
import Alamofire

enum Router : URLRequestConvertible {
    
    static var baseURLString: String {
        return YikesEngineSP.sharedEngine().currentApiEnv.baseURLString
    }
    
    case login([String: Any])
    case logout()
    case getUserStay(Int, Int)
    case getUserStays(Int, String)
    
    case getStaySharesForUser(Int)
    case createStaySharesForStay(Int, [String: Any])
    case updateStayShare(Int, Int, [String: String])
    
    case getUserInvitesForUser(Int)
    case createUserInviteForUser(Int, [String: Any])
    case deleteUserInvite(Int, Int)
    
    case getContactsForUser(Int)
    case deleteContact(Int, Int)
    
    case verifyEmail(String)
    case registerUser([String: Any])
    case passwordReset(String)
    case updatePassword(Int, [String: Any])
    
    case updateUser(Int, [String: Any])
    
    case updateYLinkEncryptionKey([String: Any])
    case yLinkTimeSyncRequest(String, [String: Any])
    
    case uploadYLinkReport([String: Any])
    
    var methodWithPath: (HTTPMethod, String) {
        switch self {
        case .login:
            return (.post, "/ycentral/api/session/login?_expand=user,beacon")
            
        case .logout:
            return (.get, "/ycentral/api/session/logout")
            
        case .getUserStay(let userId, let stayId):
            return (.get, "/ycentral/api/users/\(userId)/stays/\(stayId)?_expand=hotel,credentials")
            
        case .getUserStays(let userId, let date):
            return (.get, "/ycentral/api/users/\(userId)/stays?_expand=user,hotel,credentials&is_active=true&current_for=\(date)")
            
        case .getStaySharesForUser(let userId):
            return (.get, "/ycentral/api/users/\(userId)/stay_shares")
            
        case .createStaySharesForStay(let stayId, _):
            return (.post, "/ycentral/api/stays/\(stayId)/shares")
            
        case .updateStayShare(let shareId, let stayId, _):
            return (.put, "/ycentral/api/stays/\(stayId)/shares/\(shareId)")
            
        case .getUserInvitesForUser(let userId):
            return (.get, "/ycentral/api/users/\(userId)/invites")
            
        case .createUserInviteForUser(let userId, _):
            return (.post, "/ycentral/api/users/\(userId)/invites")
            
        case .deleteUserInvite(let inviteId, let userId):
            return (.delete, "/ycentral/api/users/\(userId)/invites/\(inviteId)")
            
        case .getContactsForUser(let userId):
            return (.get, "/ycentral/api/users/\(userId)/contacts")
            
        case .deleteContact(let contactId, let userId):
            return (.delete, "/ycentral/api/users/\(userId)/contacts/\(contactId)")
            
        case .verifyEmail(let email):
            return (.get, "/ycentral/api/verify?email=\(email)")
            
        case .registerUser:
            return (.post, "/ycentral/api/users")
            
        case .passwordReset(let email):
            return (.post, "/ycentral/api/users/password_resets?email=\(email)")
        
        case .updatePassword(let userId, _):
            return (.post, "/ycentral/api/users/\(userId)/password_change")
            
        case .updateUser(let userId, _):
            return (.put, "/ycentral/api/users/\(userId)")
            
        case .updateYLinkEncryptionKey:
            return (.put, "/ycentral/api/hotel_equipments/encryption_key")
            
        case .yLinkTimeSyncRequest(let macAddress, _):
            return (.put, "/ycentral/api/ylinks/\(macAddress)/time_sync")
        
        case .uploadYLinkReport:
            return (.post, "/sp/v1/ylink_reports")
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        
        let (method, path) = methodWithPath
        
        let baseurl = Router.baseURLString
        
        let url = baseurl.appending(path)
        
        let r = try URLRequest (url: url, method: method, headers: ["Yikes-Client-Version": DeviceHelper.sharedInstance.clientVersionInfo])
        
        yLog(.debug, message: "url is: \(r.url)")
        
        switch self {
        case .login(let parameters):
            return try! JSONEncoding().encode(r, with: parameters)
        case .createStaySharesForStay(_, let parameters):
            return try JSONEncoding().encode(r, with: parameters)
        case .updateStayShare(_, _, let parameters):
            return try! JSONEncoding().encode(r, with: parameters)
        case .createUserInviteForUser(_, let parameters):
            return try! JSONEncoding().encode(r, with: parameters)
        case .registerUser(let parameters):
            return try! JSONEncoding().encode(r, with: parameters)
        case .updatePassword(_, let parameters):
            return try! JSONEncoding().encode(r, with: parameters)
        case .updateUser(_, let parameters):
            return try! JSONEncoding().encode(r, with: parameters)
        case .updateYLinkEncryptionKey(let parameters):
            return try! JSONEncoding().encode(r, with: parameters)
        case .yLinkTimeSyncRequest(_, let parameters):
            return try! JSONEncoding().encode(r, with: parameters)
        case .uploadYLinkReport(let parameters):
            return try! JSONEncoding().encode(r, with: parameters)
        default:
            return try! JSONEncoding().encode(r, with: nil)
        }
    }
}
