//
//  YKSTemporaryPwdVC.swift
//  YikesGuestApp
//
//  Created by Alexandar Dimitrov on 2016-02-15.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import YikesGenericEngine
import YikesSharedModel
import OnePasswordExtension
import SVProgressHUD

@objc class YKSTemporaryPwdVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var pwdInstructionsLabel: UILabel!
    @IBOutlet weak var onePasswordButton: UIButton!
    @IBOutlet weak var passwordTextFieldTrailingSpaceToSuperView: NSLayoutConstraint!
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confPasswordTextField: UITextField!
    @IBOutlet weak var setPasswordButton: UIButton!
    @IBOutlet weak var apiLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var scrollViewContentOffset: CGPoint!
    var currentPassword: String!
    var successBlock: (() -> Void)!
    var failureBlock: (() -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.passwordTextField.delegate = self
        self.confPasswordTextField.delegate = self
        self.passwordTextField.becomeFirstResponder()
        self.scrollViewContentOffset = self.scrollView.contentOffset
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "cancel", style: .plain, target: self, action: #selector(YKSTemporaryPwdVC.cancelButtonTap(_:)))

        showHideNewPasswordButton()
        NotificationCenter.default.addObserver(self, selector: #selector(YKSTemporaryPwdVC.keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(YKSTemporaryPwdVC.keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        YKSUtilities.hideShowApiLabel(self.apiLabel)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    
    func showHideNewPasswordButton() {
        
        let isOnePasswordExtensionAvailable: Bool = OnePasswordExtension.shared().isAppExtensionAvailable()
        
        if (!isOnePasswordExtensionAvailable) {
            self.onePasswordButton.isHidden = true
            
            self.passwordTextField.frame = self.confPasswordTextField.frame
            self.passwordTextFieldTrailingSpaceToSuperView.constant = 10;
        }
    }

    
    
    func checkPasswordRequirements() -> Bool {
        
        var errorMessages: Array<String> = []
        
        let proposedPwd = self.passwordTextField.text
        let confProposedPwd = self.confPasswordTextField.text
        let currentPwd = self.currentPassword
        
        if (!NSString.doesString(proposedPwd, hasLengthAtLeast: 8)) {
            errorMessages.append("Password must be at least 8 characters")
        }
        
        if (!NSString.doesStringContainLowerAndUpperCaseLetters(proposedPwd)) {
            errorMessages.append("Password must contain uppercase and lowercase characters")
        }
        
        if (!NSString.doesStringContainANumber(proposedPwd)) {
            errorMessages.append("Password must have at least one number")
        }
        
        if (!NSString.do(proposedPwd, andStringMatch:confProposedPwd)) {
            errorMessages.append("Passwords don't match")
        }
        
        if currentPwd == proposedPwd {
            errorMessages.append("The new password can not be the same as the temporary password")
        }
        
        if (0 == errorMessages.count) {
            return true
        }
        else {
            var alertMessage = ""
            
            for oneErrorMsg in errorMessages {
                alertMessage += "\n" + oneErrorMsg
            }
            
            YKSUtilities.showAlert(withTitle: "Please fix the following:\n", andMessage: alertMessage, in: self)
            
            return false
        }
    }

    //MARK: Actions
    @IBAction func setPassword(_ sender: AnyObject) {
        
        if(checkPasswordRequirements()) {
            
            if let userInfo: YKSUserInfo = YikesEngine.sharedInstance.userInfo {
                let userId = userInfo.userId.intValue
                let newPwd = self.passwordTextField.text
                let confNewPwd = self.confPasswordTextField.text
                let oldPwd = self.currentPassword
                
                SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.clear)
                SVProgressHUD.show(withStatus: "Updating your new password...")
                
                YikesEngine.sharedInstance.updatePassword(
                    forUserId: NSNumber.init(value: userId),
                    oldPassword: oldPwd,
                    newPassword: newPwd,
                    confNewPassword: confNewPwd,
                    success: { () -> Void in
                        
                        SVProgressHUD.dismiss()
                        if self.successBlock != nil {
                            self.successBlock()
                        }
                        
                    }, failure: { (error) -> Void in
                        
                        SVProgressHUD.showError(withStatus: error?.description)
                        
                        if self.failureBlock != nil {
                            self.failureBlock()
                        }
                })
            }
        }
    }
    

    func cancelButtonTap(_ sender: UIBarButtonItem) {
        let _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    
    //MARK: 1Password action
    @IBAction func onePasswordTap(_ sender: AnyObject) {
        
        if let userInfo: YKSUserInfo = YikesEngine.sharedInstance.userInfo {
            
            let password = self.passwordTextField.text ?? ""
            
            let newLoginDetails: Dictionary = [
            
                AppExtensionTitleKey: "y!kes",
                AppExtensionUsernameKey: userInfo.email,
                AppExtensionPasswordKey: password,
                AppExtensionNotesKey: "Saved with the y!kes Guest App",
                AppExtensionSectionTitleKey: "y!kes Guest App"
            ]
            
            let passwordGenerationOptions: Dictionary = [
                AppExtensionGeneratedPasswordMinLengthKey: 8
            ]
            
            OnePasswordExtension.shared().storeLogin(
                forURLString: "https://guest.yikes.co/ycentral/default/user/login",
                loginDetails: newLoginDetails as [AnyHashable: Any],
                passwordGenerationOptions: passwordGenerationOptions,
                for: self, sender: sender) { (loginDictionary, error) -> Void in
                    
                    if let loginDict = loginDictionary {
                        
                        if let generatedPwd = loginDict[AppExtensionPasswordKey] as? String {
                            print("1Password return password: \(generatedPwd)")
                            
                            self.passwordTextField.text = generatedPwd
                            self.confPasswordTextField.text = generatedPwd
                        }
                        else {
                            self.passwordTextField.text = ""
                            self.confPasswordTextField.text = ""
                        }
                    }
            }
        }
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        switch textField {
        case self.passwordTextField:
            self.confPasswordTextField.becomeFirstResponder()
        case self.confPasswordTextField:
            setPassword(textField)
        default:
            break
        }
        
        return true
    }
    
    
    //MARK: Scroll contents when keyboars shows/hides
    func keyboardWasShown(_ notif: Notification) {
        let info: Dictionary = (notif as NSNotification).userInfo! as Dictionary
        
        if info.keys.contains(UIKeyboardFrameBeginUserInfoKey) {
            
            let keyboardFrameBegin = (info[UIKeyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue
            let keyPadFrame = UIApplication.shared.keyWindow?.convert(keyboardFrameBegin!, from: self.view)
            let kbSize = keyPadFrame?.size
            let activeRect = self.view.convert(self.setPasswordButton.frame, from: self.setPasswordButton.superview)
            var aRect = self.view.bounds
            aRect.size.height -= (kbSize?.height)!
            var origin = activeRect.origin
            origin.y -= self.scrollView.contentOffset.y
            origin.y += 60.0
            self.scrollViewContentOffset = self.scrollView.contentOffset
            if (!aRect.contains(origin)) {
                let scrollPoint = CGPoint(x: 0.0, y: activeRect.maxY-(aRect.size.height))
                self.scrollView.setContentOffset(scrollPoint, animated: true)
            }
        }
    }
    
    
    func keyboardWillBeHidden(_ notif: Notification) {
        self.scrollView.setContentOffset(self.scrollViewContentOffset, animated: true)
    }
    
}
