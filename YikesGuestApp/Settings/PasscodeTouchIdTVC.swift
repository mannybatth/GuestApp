//
//  PasscodeTouchIdTVC.swift
//  YikesGuestApp
//
//  Created by Manny Singh on 2/1/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit

class PasscodeTouchIdTVC: YKSBaseTVC, YKSPasscodeScreenVCDelegate {
    
    @IBOutlet weak var passcodeSwitch: UISwitch!
    @IBOutlet weak var changePasscodeButton: UIButton!
    @IBOutlet weak var touchIdSwitch: UISwitch!
    @IBOutlet weak var touchIdDescriptionLabel: UILabel!
    
    var passcodeScreenVC : YKSPasscodeScreenVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 90
        
        reloadPage()
    }
    
    func reloadPage() {
        
        passcodeSwitch.isOn = YKSPasscodeScreenVC.isPasscodeSet()
        changePasscodeButton.isHidden = !YKSPasscodeScreenVC.isPasscodeSet()
        touchIdSwitch.isOn = UserDefaults.standard.bool(forKey: "passcodeTouchIdEnabled")
        
        tableView.reloadData()
    }
    
    func dismissPasscodeSreenVC() {
        
        passcodeScreenVC?.dismiss()
        passcodeScreenVC = nil
    }
    
    @IBAction func changePasscodeButtonTouched(_ sender: UIButton) {
        
        passcodeScreenVC = YKSPasscodeScreenVC.passcodeScreen(with: YKSPasscodeViewMode.change)
        passcodeScreenVC?.delegate = self
        passcodeScreenVC?.presentOverViewController(self.mm_drawerController)
    }
    
    @IBAction func passcodeSwitchToggled(_ sender: UISwitch) {
        
        if sender.isOn {
            passcodeScreenVC = YKSPasscodeScreenVC.passcodeScreen(with: YKSPasscodeViewMode.create)
        } else {
            passcodeScreenVC = YKSPasscodeScreenVC.passcodeScreen(with: YKSPasscodeViewMode.delete)
        }
        
        passcodeScreenVC?.delegate = self
        passcodeScreenVC?.presentOverViewController(self.mm_drawerController)
    }
    
    @IBAction func touchIdSwitchToggled(_ sender: UISwitch) {
        
        if sender.isOn {
            UserDefaults.standard.set(true, forKey: "passcodeTouchIdEnabled")
        } else {
            UserDefaults.standard.set(false, forKey: "passcodeTouchIdEnabled")
        }
        UserDefaults.standard.synchronize()
    }
    
    func successfullyCreatedPasscode(for passcodeScreenVC: YKSPasscodeScreenVC!) {
        
        UserDefaults.standard.set(true, forKey: "passcodeTouchIdEnabled")
        UserDefaults.standard.synchronize()
        
        dismissPasscodeSreenVC()
        reloadPage()
    }
    
    func successfullyDeletedPasscode(for passcodeScreenVC: YKSPasscodeScreenVC!) {
        
        UserDefaults.standard.set(false, forKey: "passcodeTouchIdEnabled")
        UserDefaults.standard.synchronize()
        
        dismissPasscodeSreenVC()
        reloadPage()
    }
    
    func successfullyChangedPasscode(for passcodeScreenVC: YKSPasscodeScreenVC!) {
        
        dismissPasscodeSreenVC()
        reloadPage()
    }
    
    func passcodeEntryWasCancelled(for passcodeScreenVC: YKSPasscodeScreenVC!) {
        
        dismissPasscodeSreenVC()
        reloadPage()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if YKSPasscodeScreenVC.userHasTouchID() {
            return 2
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if (indexPath as NSIndexPath).row == 1 {
            
            if !YKSPasscodeScreenVC.isPasscodeSet() {
                cell.isUserInteractionEnabled = false
                cell.alpha = 0.5
            } else {
                cell.isUserInteractionEnabled = true
                cell.alpha = 1.0
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if (indexPath as NSIndexPath).row == 0 {
            
            if YKSPasscodeScreenVC.isPasscodeSet() {
                return 90
            } else {
                return 66
            }
            
        } else if (indexPath as NSIndexPath).row == 1 {
            
            let screenWidth = UIScreen.main.bounds.width
            
            let height = touchIdDescriptionLabel.text!.boundingRect(
                with: CGSize(width: screenWidth-145.5, height: CGFloat.infinity),
                options: NSStringDrawingOptions.usesLineFragmentOrigin,
                attributes: [NSFontAttributeName: UIFont(name:"HelveticaNeue-Light", size:12.0)!],
                context: nil).size.height + 60
            
            return height
            
        }
        
        return 90
    }
    
}
