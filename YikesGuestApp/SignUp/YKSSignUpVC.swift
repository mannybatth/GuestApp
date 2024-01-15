//
//  YKSSignUpVC.swift
//  YikesGuestApp
//
//  Created by Manny Singh on 7/12/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import YKSUIModuleSignup
import OnePasswordExtension

class YKSSignUpVC: UIViewController {
    
    @IBOutlet var signupView: UIView!
    
    var didSignUpUsing1Password : Bool = false
    
    var activeField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let signUpViewFrame = UIApplication.shared.keyWindow?.frame
        
        let onePasswordSupported = self.isOnePasswordExtensionAvailable()
        
        var showStatusMessageWithClearMask: (String?) -> ()
        
        let showErrorMessageBlock = { (isError: Bool, message: String?) in
            
            if isError {
                SVProgressHUD.showError(withStatus: message)
            }
            else {
                // success - the signup module is showing the registration confirmation screen.
                SVProgressHUD.dismiss()
            }
        }
        
        
        showStatusMessageWithClearMask = { (message: String?) in
            SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.clear)
            SVProgressHUD.show(withStatus: message)
        }
        
        let successRegistrationBlock = { (firstName: String?,
            lastName: String?,
            email: String?) in
            
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "YKSSignUpCompletedSID") as? YKSSignUpCompleted {
                
                vc.firstName = firstName
                vc.lastName = lastName
                vc.email = email
                vc.callback = {
                    if let loginVC = self.navigationController?.viewControllers.first as? YKSLoginVC {
                        _ = self.navigationController?.popToViewController(loginVC, animated: true)
                    }
                }
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        
        let registerUserWithFormBlock: (([String:String]) -> Void)! = { (form: [String:String]) in
            
            YikesEngine.sharedEngine()?.registerUser(withForm: form, success: {
                
                showErrorMessageBlock(false, "Registered!")
                
                let firstName = form["first_name"]
                let lastName = form["last_name"]
                let email = form["email"]
                
                
                successRegistrationBlock (firstName, lastName, email)
                
                let currentAPIString = YikesEngine.sharedEngine()!.currentApiEnv.stringValue
                //Answers.logSignUpWithMethod(self.didSignUpUsing1Password ? "1Password" : "None", success: true, customAttributes: ["username" : email, "yCentral Environment" : currentAPIString])
                
                }, failure: { error in
                    
                    self.didSignUpUsing1Password = false
                    
                    showErrorMessageBlock(true, "Error!\n\n\(error?.description)")
                    
                    let currentAPIString = YikesEngine.sharedEngine()!.currentApiEnv.stringValue
                  //Answers.logSignUpWithMethod(self.didSignUpUsing1Password ? "1Password" : "None", success: false, customAttributes: ["username" : email, "yCentral Environment" : currentAPIString])
                    
            })
        }
        
        let currentApi = YikesEngine.sharedEngine()?.currentApiEnv ?? YKSApiEnv.envPROD
        self.signupView = YKSSignupView(frame: signUpViewFrame!,
                                             onePasswordSupport: onePasswordSupported,
                                             showStatusBlock: showErrorMessageBlock,
                                             showStatusMessagesWithClearMaskBlock: showStatusMessageWithClearMask,
                                             parentViewController: self,
                                             registerUserWithFormBlock: registerUserWithFormBlock,
                                             successRegistrationBlock: successRegistrationBlock,
                                             currentApi: currentApi)
        self.view.addSubview(self.signupView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //        YKSUtilities.hideShowApiLabel(self.apiLabel)
    }
    
    deinit {
    }
    
    func isOnePasswordExtensionAvailable() -> Bool {
        // warning: this won't work in iOS 9 unless the URL used in canOpenURL: is white listed.
        return OnePasswordExtension.shared().isAppExtensionAvailable()
    }
    
}

