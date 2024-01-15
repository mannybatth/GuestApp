//
//  UserRequests.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/18/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import YKSSPLocationManager

import Alamofire
import AlamofireObjectMapper
import ObjectMapper


extension User {
    
    class func loginWithKeychainCredentials(
        _ success: @escaping (_ user: User?) -> Void,
        failure: @escaping (_ error: YKSError) -> Void)  {
        
        yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "Attempting to login with saved credentials.")
        
        if let (username, password) = StoreManager.sharedInstance.currentGuestUsernameAndPasswordFromKeychains() {
            User.loginRetryingNumberOfTimes(1,
                                            username: username,
                                            password: password,
                                            success: success,
                                            failure: failure)
        }
        else {
            YikesEngineSP.sharedInstance.stopEngine(success: {
                yLog(message: "Had to logout - missing user email or password: \(StoreManager.sharedInstance.currentGuestUsernameAndPasswordFromKeychains())")
            })
        }
        
    }
    
    class func loginRetryingNumberOfTimes(
        _ ntimes: Int,
        username: String,
        password: String,
        success: @escaping (_ user: User?) -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
            
            User.login(username, password: password, success: { user in
                
                success(user)
                
            }) { (error) -> Void in
                    
                if (ntimes > 0) {
                    User.loginRetryingNumberOfTimes(ntimes-1,
                        username: username,
                        password: password,
                        success: success,
                        failure: failure)
                    
                    return
                }
                failure(error)
            }
    }
    
    class func login(
        _ username: String,
        password: String,
        success: @escaping (_ user: User?) -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        let parameters:[String:Any] = [
            "user_name": username,
            "password": password
        ]
        
        let loginRouter = try! Router.login(parameters)
        
        let request = HTTPManager.sharedManager.request(loginRouter)
        request.validate().responseJSON { response in
                
                switch response.result {
                    
                case .success:
                    
                    yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "LOGIN SUCCESS")
                    
                    yLog(.debug, message: "yC JSON data: \(response)")
                    
                    if let JSON = response.result.value as? [String: Any],
                    let response_body = JSON["response_body"] as? [String: Any],
                        let userDict = response_body["user"] as? [String: Any] {
                        
                        yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "LOGIN SUCCESS")
                        
                        if let user = Mapper<User>().map(JSON: userDict) {
                            
                            if let beaconDict = response_body["beacon"] as? [String: Any] {
                                user.beacon = Mapper<Beacon>().map(JSON: beaconDict)
                            }
                            
                            // copy stays from the old User object if this is an attempt to relogin after a 401
                            if HTTPManager.sharedManager.reloginInProgress == true {
                                if let stays = YKSSessionManager.sharedInstance.currentUser?.stays {
                                    user.stays = stays
                                }
                            }
                            
                            YKSSessionManager.sharedInstance.currentUser = user
                            _ = StoreManager.sharedInstance.storeCurrentGuestAppUserEmail(username, password: password)
                            StoreManager.sharedInstance.storeGuestAppSessionCookieToKeychain()
                            
                            // Start monitoring process is handled by resumeEngine()
                            
                            success(user)
                            return
                        }
                    }
                    
                    failure(YKSError.newWith(.unknown, errorDescription: kYKSErrorFailedToTransformDataDescription))
                    
                case .failure:
                    failure(YKSError.errorFromResponse(response))
                }
        }
    }
    
    class func logout(
        _ success: @escaping () -> Void) {
        
        let urlRequest = try! Router.logout()
        let request = HTTPManager.sharedManager.request(urlRequest)
        request.responseJSON { response in
            success()
        }
    }

    class func checkIfEmailIsRegistered(
        _ email: String,
        success: @escaping (_ isRegistered: Bool, _ user: User?) -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        var codes = [Int](200..<300)
        codes.append(404)
        
        let checkEmailIsRegisteredRequest = try! Router.verifyEmail(email)
        
        let request = HTTPManager.sharedManager.request(checkEmailIsRegisteredRequest)
        request.validate(statusCode: codes).responseJSON { (response: DataResponse<Any>) -> Void in
            
            switch response.result {
            case .success:
                
                if (response.response?.statusCode == 404) {
                    success(false, nil)
                    return
                }
                
                guard let data = response.result.value as? [String: AnyObject] else {
                    return
                }
                
                if let responseBody = data["response_body"],
                    let userJSON = responseBody["user"] as? [String: Any] {
                    
                    let user = Mapper<User>().map(JSON: userJSON)
                    success(true, user)
                    
                } else {
                    success(true, nil)
                }
                
            case .failure:
                failure(YKSError.errorFromResponse(response))
            }
        }
    }
    
    class func registerUserWithForm(
        _ form: [String: AnyObject],
        success: @escaping () -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        let registerWithFormRequest = try! Router.registerUser(form)
        
        let request = HTTPManager.sharedManager.request(registerWithFormRequest)
        request.validate().responseJSON { response in
            
            switch response.result {
            case .success( _):
                success()
            case .failure( _):
                failure(YKSError.errorFromResponse(response))
            }
        }
    }
    
    class func forgotPasswordForEmail(
        _ email: String,
        success: @escaping () -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        let forgotPasswordRequest = try! Router.passwordReset(email)
        
        let request = HTTPManager.sharedManager.request(forgotPasswordRequest)
        request.validate().responseJSON { response in
            
            switch response.result {
            case .success( _):
                success()
            case .failure( _):
                failure(YKSError.errorFromResponse(response))
            }
            
        }
        
    }
    
    class func updatePasswordForUserId(
        _ userId: Int,
        oldPassword: String!,
        newPassword: String!,
        success: (() -> Void)!,
        failure: ((YKSError?) -> Void)!) {
        
        yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "Updating Password for userId: \(userId) ...")
        
        let parameters = [
            "old_password": oldPassword,
            "new_password": newPassword,
            ]
        
        let updatePasswordRequest = try! Router.updatePassword(userId, parameters)
        
        let request = HTTPManager.sharedManager.request(updatePasswordRequest)
        request.validate().responseJSON { response in
            
            switch response.result {
            case .success( _):
                success()
                
            case .failure( _):
                failure(YKSError.errorFromResponse(response))
            }
        }
        
    }
    
    class func updateUserWithForm(
        _ form: [String: AnyObject],
        success: @escaping () -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        guard let currentUser = YKSSessionManager.sharedInstance.currentUser,
            let currentUserId = currentUser.userId
            else { return }
        
        let updateUserRequest = try! Router.updateUser(currentUserId, form)
        
        let request = HTTPManager.sharedManager.request(updateUserRequest)
        request.validate().responseJSON { response in
            
            switch response.result {
            case .success( _):
                success()
            case .failure( _):
                failure(YKSError.errorFromResponse(response))
            }
            
        }
    }


    class func getUserAndStaysRetryingNumberOfTimes(
        _ ntimes: Int,
        userId: Int,
        success: @escaping (_ user: User?) -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "Updating user stays...")
        
        User.getUserAndStaysWithUserId(userId, success: { (user) -> Void in
            
            if (user != nil) {
                
                yLog(LoggerLevel.debug, category: LoggerCategory.System, message: "STAYS UPDATED")
                
                YKSSessionManager.sharedInstance.currentUser = user
                
                success(user)
                
            } else {
                success(YKSSessionManager.sharedInstance.currentUser)
            }
            
            }, failure: { (error, response) -> Void in
                
                if response != nil && response?.statusCode == 401 || response?.statusCode == 403 {
                    yLog(.debug, category: LoggerCategory.API, message: "Attempt to get user stays failed w/ 401 or 403 - going to try and relogin first.")
                    HTTPManager.sharedManager.reloginIfUserForbidden(response, success: {
                        // login success handled in the User.loginWithKeychainCredentials
                        yLog(message: "Relogin success after failure to getUserAndStaysWithUserId")
                        }, failure: { error in
                            
                            if error.errorCode == .userNotAuthorized {
                                
                            }
                            
                            failure(error)
                            yLog(.debug, message: "Failed to relogin in getUserAndStaysRetryingNumberOfTimes")
                    })
                }
                else {
                    if (ntimes > 0) {
                        
                        User.getUserAndStaysRetryingNumberOfTimes(ntimes-1,
                                                                  userId: userId,
                                                                  success: success,
                                                                  failure: failure)
                        return
                    }
                }
                failure(error)
        })
    }
    
    class func getUserAndStaysWithUserId(
        _ userId: Int,
        success: @escaping (_ user: User?) -> Void,
        failure: @escaping (_ error: YKSError, _ response: HTTPURLResponse?) -> Void) {
            
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dateString = dateFormatter.string(from: Date())
        
        HTTPManager.sharedManager.beginBackgroundTask()
        
        let userAndStaysWithUserIDRequest = try! Router.getUserStays(userId, dateString)
        
        let request = HTTPManager.sharedManager.request(userAndStaysWithUserIDRequest)
        request.validate().responseJSON { response in
                
                switch response.result {
                case .success:
                    
                    if let data = response.result.value as? [String: Any],
                    let responseBody = data["response_body"] as? [String: Any],
                        var userJSON = responseBody["user"] as? [String: Any] {
                        
                        // move "stays" under "user"
                        userJSON["stays"] = responseBody["stay"]
                        
                        let user = Mapper<User>().map(JSON: userJSON)
                        success(user)
                        
                        return
                    }
                    
                    success(nil)
                    HTTPManager.sharedManager.endBackgroundTask()
                    
                case .failure:
                    
                    HTTPManager.sharedManager.reloginIfUserForbidden(response.response, success: {
                            // Do not retry here, it is already handled in the caller `getUserAndStaysRetryingNumberOfTimes`
                        failure(YKSError.newWith(.unknown, errorDescription: "Not retyring after successful login in getUserAndStaysWithUserId"), nil)
                        }, failure: { error in
                            failure(YKSError.errorFromResponse(response), response.response)
                            HTTPManager.sharedManager.endBackgroundTask()
                    })
                }
        }
    }
    
    /**
     This is executed w/ a background URL Session.
     */
    class func getUserStay(
        _ stayId: Int,
        userId: Int,
        success: @escaping (_ stay: Stay) -> Void,
        failure: @escaping (_ error: YKSError) -> Void) {
        
        HTTPManager.sharedManager.beginBackgroundTask()
        
        let userStayRequest = try! Router.getUserStay(userId, stayId)
        
        let request = HTTPManager.sharedManager.request(userStayRequest)
        request.validate().responseArray(keyPath: "response_body.stay") { (response: DataResponse<[Stay]>) -> Void in
            
            switch response.result {
            case .success(let stays):
                
                guard stays.count > 0 else {
                    failure(YKSError.newWith(.clientSidePayloadValidation, errorDescription: "No Stay returned in the GetUserStay request"))
                    return
                }
                
                let newStay = stays[0]
                
                // replace old stay with new one + copy over yLink connections & connection status
                if let currentUser = YKSSessionManager.sharedInstance.currentUser,
                    let indexOfOldStay = currentUser.stays.index(where: { $0.stayId == newStay.stayId }){
                    
                    let oldStay = currentUser.stays[indexOfOldStay]
                    
                    StoreManager.sharedInstance.copyYLinkConnections([newStay], oldStays: [oldStay])
                    StoreManager.sharedInstance.copyConnectionStatuses([newStay], oldStays: [oldStay])
                    
                    currentUser.stays[indexOfOldStay] = newStay
                    
                    StoreManager.sharedInstance.saveCurrentUser()
                } else {
                    
                    yLog(LoggerLevel.error, category: LoggerCategory.API, message: "Did not find an existing stay with id: \(newStay.stayId) in currentUser.")
                }
                
                success(newStay)
                HTTPManager.sharedManager.endBackgroundTask()
                
            case .failure:
                
                HTTPManager.sharedManager.reloginIfUserForbidden(response.response, success: {

                    // Do not handle the retry with a recursive call, handle it in the failure callback.
//                    User.getUserStay(stayId, userId: userId, success: success, failure: failure)
//                    }, failure: { error in
//                        failure(YKSError.errorFromResponse(response))
//                        HTTPManager.sharedManager.endBackgroundTask()
//                    }
                    
                    failure(YKSError.newWith(.unknown, errorDescription: ""))
                    
                    }, failure: { error in
                        failure(YKSError.newWith(.unknown, errorDescription: "Error trying to relogin: \(error)"))
                })
                
            }
        }
    }
    
    class func getUserStayShareRequestsWithSuccess(_ successBlock: (([YKSStayShareInfo]?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        guard let currentUser = YKSSessionManager.sharedInstance.currentUser,
            let currentUserId = currentUser.userId
            else { return }
        
        StayShare.getStayShares(currentUserId, success: { (stayShares) -> Void in
            
            successBlock?(stayShares?.infoObjects())
            
            }) { (error) -> Void in
                
                failureBlock?(error)
        }
        
    }
    
    class func sendStayShareRequestForStayId(_ stayId: NSNumber!, toEmail email: String!, success successBlock: ((YKSStayShareInfo?, YKSUserInviteInfo?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        guard let currentUser = YKSSessionManager.sharedInstance.currentUser,
            let currentUserId = currentUser.userId
            else { return }
        
        User.checkIfEmailIsRegistered(email, success: { (isRegistered, user) -> Void in
            
            if isRegistered {
                
                StayShare.createStayShare(stayId.intValue, userId: user!.userId!, success: { (stayShareId) -> Void in
                    
                    StayShare.getStayShares(currentUserId, success: { (stayShares) -> Void in
                        
                        let result = stayShares!.filter { $0.stayShareId == stayShareId }
                        if let stayShare = result.first {
                            successBlock?(stayShare.stayShareInfo, nil)
                        }
                        
                        }, failure: { (error) -> Void in
                            
                            failureBlock?(error)
                    })
                    
                    }, failure: { (error) -> Void in
                        
                        failureBlock?(error)
                })
                
            } else {
                
                UserInvite.createUserInvite(stayId.intValue, fromUserId: currentUserId, toEmail: email, success: { (inviteId) -> Void in
                    
                    UserInvite.getUserInvites(currentUserId, success: { (userInvites) -> Void in
                        
                        let result = userInvites!.filter { $0.inviteId == inviteId }
                        if let userInvite = result.first {
                            successBlock?(nil, userInvite.userInviteInfo)
                        }
                        
                        }, failure: { (error) -> Void in
                            
                            failureBlock?(error)
                    })
                    
                    }, failure: { (error) -> Void in
                        
                        failureBlock?(error)
                })
                
            }
            
            }) { (error) -> Void in
                
                failureBlock?(error)
        }
    }
    
    
    class func acceptStayShareRequest(_ stayShare: YKSStayShareInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        guard let _ = YKSSessionManager.sharedInstance.currentUser
            else { return }
        
        StayShare.updateStayShareStatus(stayShare.stayShareId.intValue, stayId: stayShare.stay.stayId.intValue, status: "accepted", success: { () -> Void in
            
            YikesEngineSP.sharedInstance.refreshUserInfo(success: { userInfo -> Void in
                
                successBlock?()
                
            }, failure: { (error) -> Void in
                    
                failureBlock?(error)
            })
            
        }) { (error) -> Void in
                
            failureBlock?(error)
        }
    }
    
    
    class func declineStayShareRequest(_ stayShare: YKSStayShareInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        guard let _ = YKSSessionManager.sharedInstance.currentUser
            else { return }
        
        StayShare.updateStayShareStatus(stayShare.stayShareId.intValue, stayId: stayShare.stay.stayId.intValue, status: "declined", success: { () -> Void in
            
            YikesEngineSP.sharedInstance.refreshUserInfo(success: { userInfo -> Void in
                
                successBlock?()
                
            }, failure: { (error) -> Void in
                    
                failureBlock?(error)
            })
            
        }) { (error) -> Void in
                
            failureBlock?(error)
        }
    }
    
    
    class func cancelStayShareRequest(_ stayShare: YKSStayShareInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        guard let currentUser = YKSSessionManager.sharedInstance.currentUser,
            let currentUserId = currentUser.userId
            else { return }
        
        StayShare.updateStayShareStatus(stayShare.stayShareId.intValue, stayId: stayShare.stay.stayId.intValue, status: "cancelled", success: { () -> Void in
            
            // Get new credentials to prevent removed SG from accessing room
            CentralManager.sharedInstance.refreshCredentialsForStayInfo(stayShare.stay)
            
            StayShare.getStayShares(currentUserId, success: { (stayShares) -> Void in
                
                successBlock?()
                
            }, failure: { (error) -> Void in
                    
                failureBlock?(error)
            })
            
        }) { (error) -> Void in
                
            failureBlock?(error)
        }
    }
    
    
    class func getUserInvitesWithSuccess(_ successBlock: (([YKSUserInviteInfo]?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        guard let currentUser = YKSSessionManager.sharedInstance.currentUser,
            let currentUserId = currentUser.userId
            else { return }
        
        UserInvite.getUserInvites(currentUserId, success: { (userInvites) -> Void in
            
            successBlock?(userInvites?.infoObjects())
            
            }) { (error) -> Void in
                
                failureBlock?(error)
        }
        
    }
    
    
    class func cancelUserInviteRequest(_ userInvite: YKSUserInviteInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        guard let currentUser = YKSSessionManager.sharedInstance.currentUser,
            let currentUserId = currentUser.userId
            else { return }
        
        UserInvite.deleteUserInvite(userInvite.inviteId.intValue, userId: currentUserId, success: { () -> Void in
            
            UserInvite.getUserInvites(currentUserId, success: { (userInvites) -> Void in
                
                successBlock?()
                
                }, failure: { (error) -> Void in
                    
                    failureBlock?(error)
            })
            
            }) { (error) -> Void in
                
                failureBlock?(error)
        }
    }
    
    
    class func getRecentContactsWithSuccess(_ successBlock: (([YKSContactInfo]?) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        guard let currentUser = YKSSessionManager.sharedInstance.currentUser,
            let currentUserId = currentUser.userId
            else { return }
        
        Contact.getUserContacts(currentUserId, success: { (contacts) -> Void in
            
            successBlock?(contacts?.infoObjects())
            
            }) { (error) -> Void in
                
                failureBlock?(error)
        }
        
    }
    
    
    class func removeRecentContact(_ contact: YKSContactInfo!, success successBlock: (() -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        guard let currentUser = YKSSessionManager.sharedInstance.currentUser,
            let currentUserId = currentUser.userId
            else { return }
        
        Contact.deleteUserContact(contact.contactId.intValue, userId: currentUserId, success: { () -> Void in
            
            Contact.getUserContacts(currentUserId, success: { (contacts) -> Void in
                
                successBlock?()
                
                }, failure: { (error) -> Void in
                    
                    failureBlock?(error)
            })
            
            }) { (error) -> Void in
                
                failureBlock?(error)
        }
    }
    
    
    class func registerUserWithFormIfNotAlreadyRegistered(
        _ form: [String : AnyObject]!,
        success successBlock: (() -> Void)!,
        failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.checkIfEmailIsRegistered(form["email"] as! String, successBlock: { (isRegistered) in
            if !isRegistered {
                
                User.registerUserWithForm(form, success: {
                    successBlock?()
                }, failure:
                    {(error) -> Void in
                        failureBlock?(error)
                })
            } else {
                failureBlock?(YKSError.newWith(YKSErrorCode.userEmailAlreadyRegistered, errorDescription: kYKSErrorUserEmailAlreadyRegisteredDescription))
            }
        }) { (error) in
            failureBlock?(error)
        }
    }
    
    
    class func checkIfEmailIsRegistered(_ email: String!, successBlock: ((Bool) -> Void)!, failure failureBlock: ((YKSError?) -> Void)!) {
        
        User.checkIfEmailIsRegistered(email, success: { (isRegistered, user) in
            successBlock(isRegistered)
            })
        { (error) in
                failureBlock?(error)
        }
    }
    
}
