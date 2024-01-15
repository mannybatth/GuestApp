//
//  HTTPManager.swift
//  YikesEngine
//
//  Created by Manny Singh on 12/12/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import Alamofire
import ObjectMapper

class YRequestCallback {
    let success: () -> Void
    let failure: () -> Void
    init (success: @escaping () -> Void, failure: @escaping () -> Void) {
        self.success = success
        self.failure = failure
    }
}

class HTTPManager: SessionManager {
    
    enum Style {
        case verbose
        case light
    }
    
    static var networkLogStyle: Style = .light
    
    var reloginInProgress : Bool = false
    var requestCallbacksAfterRelogin : [YRequestCallback] = []
    var requestsAwaitingRelogin : [Request] = []
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    static let sharedManager: HTTPManager = {
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        
        let manager = HTTPManager(configuration: configuration)
        manager.startRequestsImmediately = false
        
        manager.delegate.dataTaskDidReceiveResponse = {(session:URLSession, dataTask:URLSessionDataTask, response:URLResponse) -> URLSession.ResponseDisposition in
            NetworkLogger.logResponse(response, dataTask: dataTask)
            return URLSession.ResponseDisposition.allow
        }
        
        return manager
    }()
    
    override func request(_ urlRequest: URLRequestConvertible) -> DataRequest {
        
        let request = try! super.request(urlRequest.asURLRequest())
        
        NetworkLogger.logRequest(request)
        
        if reloginInProgress == true && !isLoginRequest(request) && !isLogoutRequest(request) {
            yLog(LoggerLevel.debug, category: LoggerCategory.API, message: "Adding taskid: \(request.task?.taskIdentifier) to pending relogin queue.")
            requestsAwaitingRelogin.append(request)
        } else {
            request.resume()
        }
        return request
    }
    
    func isLoginRequest(_ request: Request) -> Bool {
        
        if let path = request.request?.url?.path {
            if path == "/ycentral/api/session/login" {
                return true
            }
        }
        return false
    }
    
    func isLogoutRequest(_ request: Request) -> Bool {
        
        if let path = request.request?.url?.path {
            if path == "/ycentral/api/session/logout" {
                return true
            }
        }
        return false
    }
    
    func setBackgroundCompletionHandler( handler:@escaping (() -> Void)) {
        backgroundCompletionHandler = handler
    }
    
    func beginBackgroundTask() {
        
        if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
            return
        }
        
        yLog(LoggerLevel.debug, category: LoggerCategory.API, message: "Starting BACKGROUND TASK.")
        
        backgroundTaskIdentifier =
            UIApplication.shared.beginBackgroundTask(
                withName: nil,
                expirationHandler: {
                    
                    yLog(LoggerLevel.debug, category: LoggerCategory.API, message: "BACKGROUND TASK expirationHandler called.")
                    
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
                    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
            })
    }
    
    func endBackgroundTask() {
        
        if backgroundTaskIdentifier == UIBackgroundTaskInvalid {
            return
        }
        
        yLog(LoggerLevel.debug, category: LoggerCategory.API, message: "Ending BACKGROUND TASK.")
        
        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
        backgroundTaskIdentifier = UIBackgroundTaskInvalid
    }
    
    func reloginIfUserForbidden(_ response: HTTPURLResponse?, success: @escaping () -> Void, failure: @escaping (_ error:YKSError) -> Void) {
        
        if let resp = response {
            if resp.statusCode == 401 || resp.statusCode == 403 {
                
                if YikesEngineSP.sharedInstance.engineState == .off {
                    yLog(.warning, message: "Not reloging - engine state is off")
                    return
                }
                
                let yRequest = YRequestCallback(success: success, failure: {})
                requestCallbacksAfterRelogin.append(yRequest)
                
                if reloginInProgress == true {
                    return
                }
                
                reloginInProgress = true
                
                User.loginWithKeychainCredentials({ user in
                    
                    yLog(LoggerLevel.debug, category: LoggerCategory.API, message: "LOGIN SUCCESS (after a 401/403)")
                    
                    self.reloginInProgress = false
                    
                    // Delay to allow the remote session to become available on subsequent calls - see GAD-1377
                    let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: delayTime) {
                        self.handleReloginSuccess()
                    }
                    
                }, failure: { error in
                    yLog(message: "Failed to login with Keychain Credentials")
                    self.reloginInProgress = false
                    self.handleReloginFailure()
                    failure(error)
                })
                
                return
            }
        }
        
        failure(YKSError.newWith(.requestFailedNoResponse, errorDescription: kYKSErrorUserNotAuthorizedDescription))
    }
    
    func handleReloginSuccess() {
        
        for request in requestsAwaitingRelogin {
            yLog(LoggerLevel.debug, category: LoggerCategory.API, message: "Resuming taskid: \(request.task?.taskIdentifier) after relogin success.")
            request.resume()
        }
        requestsAwaitingRelogin.removeAll()
        
        for yRequest in requestCallbacksAfterRelogin {
            yRequest.success()
        }
        requestCallbacksAfterRelogin.removeAll()
    }
    
    func handleReloginFailure() {
        
        for request in requestsAwaitingRelogin {
            yLog(LoggerLevel.error, category: LoggerCategory.API, message: "Resuming taskid: \(request.task?.taskIdentifier) after relogin failure.")
            request.resume()
        }
        requestsAwaitingRelogin.removeAll()
        
        for yRequest in requestCallbacksAfterRelogin {
            yRequest.failure()
        }
        requestCallbacksAfterRelogin.removeAll()
    }
    
    func cancelAllTasks() {
        session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) in
            for dataTask in dataTasks {
                dataTask.suspend()
                dataTask.cancel()
            }
        }
    }
    
}

extension YKSError {
    
    class func errorFromResponse<T>(_ response: DataResponse<T>) -> YKSError {
        
        if let resp = response.response {
            
            yLog(LoggerLevel.error, category: LoggerCategory.API, message: "API error - \(resp.statusCode) \(resp.url!)")
            
            switch resp.statusCode {
                
            case 400:
                return YKSError.newWith(.serverSidePayloadValidation, errorDescription: kYKSErrorServerSidePayloadValidationDescription)
            
            case 401:
                return YKSError.newWith(.userNotAuthorized, errorDescription: kYKSErrorUserNotAuthorizedDescription)
                
            case 403:
                return YKSError.newWith(.userForbidden, errorDescription: kYKSErrorUserForbiddenDescription)
                
            case 409:
                return YKSError.newWith(.resourceConflict, errorDescription: kYKSErrorResourceConflictDescription)
                
            default:
                break;
                
            }
        }
        
        if let error = response.result.error,
           let yError = YKSError.errorFromNSError(error as NSError) {
            return yError
        }
        
        return YKSError.newWith(.unknown, errorDescription: kYKSErrorUnknownDescription)
        
    }
    
    class func errorFromNSError(_ error: NSError) -> YKSError? {
        
        // Alamofire domain
        if (error.domain == NSCocoaErrorDomain) {
            
            if let failureReason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String {
                return YKSError.newWith(.unknown, errorDescription: failureReason, nsError: error)
            }
            
        } else if (error.domain == NSURLErrorDomain) {
            
            switch (error.code) {
                
            case NSURLErrorCannotFindHost:
                return YKSError.newWith(.failureConnectingToYikesServer, errorDescription: kYKSErrorFailureConnectingToYikesServerDescription)
                
            default:
                let desc = "\(error.localizedDescription) URLErrorCode: \(error.code)"
                return YKSError.newWith(.unknown, errorDescription: desc)
            }
            
        } else if (error.domain == NSCocoaErrorDomain) {
            
            switch (error.code) {
                
            case NSPropertyListReadCorruptError:
                let desc = "JSON parsing error. CocoaErrorCode: \(error.code)"
                return YKSError.newWith(.unknown, errorDescription: desc)
                
            default:
                let desc = "\(error.localizedDescription) CocoaErrorCode: \(error.code)"
                return YKSError.newWith(.unknown, errorDescription: desc)
                
            }
            
        }
        
        return nil;
    }
    
}
