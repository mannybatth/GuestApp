//
//  AccountDetailsTVC.swift
//  YikesGuestApp
//
//  Created by Manny Singh on 2/29/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesGenericEngine
import YikesSharedModel
import PKAlertController
import SVProgressHUD

class AccountDetailsTVC: UITableViewController {

    var details: [String] = []
    
    var formDictionary: [String: Any] {
        return [
            "first_name" : details[0] as Any,
            "last_name" : details[1] as Any,
            "phone" : [
                "phone_number" : details[2]
            ]
        ]
    }
    
    var lastActiveIndexPath: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = YikesEngine.sharedInstance.userInfo {
            
            details = [
                user.firstName,
                user.lastName,
                self.formatPhone(user.phone),
                user.email
            ]
            
            self.tableView.setNeedsLayout()
            self.tableView.layoutIfNeeded()
            self.tableView.rowHeight = UITableViewAutomaticDimension;
            self.tableView.reloadData()
        }
    }
    
    fileprivate func formatPhone(_ phoneNumber: String?) -> String {
        
        guard let number = phoneNumber else {
            return ""
        }
        
        let phoneHelper = YKSPhoneHelper.init(regionCode: "US")        
        if let formattedPhone = phoneHelper?.formatNumber(number) {
            return formattedPhone
        }
        else {
            return number
        }
    }
    
    
    func saveAccountDetails() {
        
        let firstName = details[0]
        let lastName = details[1]
        var errorMessage: String = ""
        var areEmptyStringPresent: Bool = false
        
        if firstName.characters.count == 0 {
            errorMessage += "First name is required"
            areEmptyStringPresent = true
        }
        
        if lastName.characters.count == 0 {
            if errorMessage.characters.count != 0 {
                errorMessage += "\n"
            }
            
            errorMessage += "Last name is required"
            areEmptyStringPresent = true
        }
        
        if areEmptyStringPresent {

            let emptyStringAlert = PKAlertViewController.alert { configuration in

                configuration?.title = "Please fix the following"
                configuration?.message = errorMessage
                
                configuration?.addAction(PKAlertAction(title: "Ok", handler: { (action, closed) -> Void in
                    if let cell = self.tableView.cellForRow(at: self.lastActiveIndexPath) as? AccountDetailsCell {
                        cell.textView.becomeFirstResponder()
                    }
                }))
                
            }
            self.present(emptyStringAlert!, animated: true, completion: nil)
        }
        else {
            SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.clear)
            SVProgressHUD.show(withStatus: "Saving account details...")
            
            YikesEngine.sharedInstance.updateUser(withForm: formDictionary, success: { () -> Void in
                
                SVProgressHUD.showSuccess(withStatus: "Account details saved!")
                
                }) { (error) -> Void in
                    
                    if error?.errorCode == YKSErrorCode.resourceConflict {
                        SVProgressHUD.showError(withStatus: "New first/last name not supported.")
                    }
                    else {
                        SVProgressHUD.showError(withStatus: error?.description)
                    }
            }

        }
    }
    
    @IBAction func leftBarButtonItemTouched(_ sender: UIBarButtonItem) {
        
        if sender.title == "edit" {
            
            sender.title = "save"
            
            if self.lastActiveIndexPath == nil {
                self.lastActiveIndexPath = IndexPath.init(row: 0, section: 0)
            }
            
            if let cell = tableView.cellForRow(at: self.lastActiveIndexPath) as? AccountDetailsCell {
                cell.textView.becomeFirstResponder()
            }
            
        } else {
            
            sender.title = "edit"
            self.view.endEditing(true)
            saveAccountDetails()
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let cell = cell as? AccountDetailsCell {
            cell.delegate = self
            cell.textView.text = details[(indexPath as NSIndexPath).row]
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
    }

}

extension AccountDetailsTVC: AccountDetailsCellDelegate {
    
    func accountDetailsDidBeginEditing(_ cell: AccountDetailsCell) {
        
        if self.navigationItem.rightBarButtonItem?.title == "edit" {
            self.leftBarButtonItemTouched(self.navigationItem.rightBarButtonItem!)
        }
        self.lastActiveIndexPath = tableView.indexPath(for: cell)
        cell.textView.becomeFirstResponder()
    }
    
    func accountDetailsDidEndEditing(_ cell: AccountDetailsCell) {
        
        if let indexPath = tableView.indexPath(for: cell) {
            details[(indexPath as NSIndexPath).row] = cell.textView.text
        }
        self.lastActiveIndexPath = tableView.indexPath(for: cell)
        cell.textView.resignFirstResponder()
    }

    func accountDetailsCellHeightChanged() {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
}
