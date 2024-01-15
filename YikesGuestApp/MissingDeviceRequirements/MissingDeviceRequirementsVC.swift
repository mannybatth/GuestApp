//
//  MissingDeviceRequirementsVC.swift
//  YikesGuestApp
//
//  Created by Manny Singh on 2/9/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import CoreLocation
import YikesGenericEngine
import YikesSharedModel

import PKAlertController

class MissingDeviceRequirementsVC: YKSBaseVC, CLLocationManagerDelegate {
    
    
    
    @IBOutlet weak var contentViewTop: NSLayoutConstraint!
    
    @IBOutlet weak var bgView: UIVisualEffectView!
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var internetConnectionStatusLabel: UILabel!
    @IBOutlet weak var bluetoothStatusLabel: UILabel!
    @IBOutlet weak var locationServicesStatusLabel: UILabel!
    @IBOutlet weak var pushNotificationsStatusLabel: UILabel!
    @IBOutlet weak var backgroundAppRefreshStatusLabel: UILabel!
    
    @IBOutlet weak var internetConnectionButton: UIButton!
    @IBOutlet weak var bluetoothButton: UIButton!
    @IBOutlet weak var locationServicesButton: UIButton!
    @IBOutlet weak var pushNotificationsButton: UIButton!
    @IBOutlet weak var backgroundAppRefreshButton: UIButton!

    @IBOutlet weak var ignoreForNowButton: UIButton!
    
    var locationManager: CLLocationManager?
    
    var missingServices : Set<NSObject> = []
    var updateOnceDone = false
    
    class func newMissingDeviceRequirementsVCWithMissingServices(_ missingServices: Set<NSObject>) -> MissingDeviceRequirementsVC {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MissingDeviceRequirementsVC") as! MissingDeviceRequirementsVC
        
        vc.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        vc.missingServices = missingServices
        
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.centerTextAndImageForButton(internetConnectionButton)
        self.centerTextAndImageForButton(bluetoothButton)
        self.centerTextAndImageForButton(locationServicesButton)
        self.centerTextAndImageForButton(pushNotificationsButton)
        self.centerTextAndImageForButton(backgroundAppRefreshButton)
        
        self.centerTextAndImageForButton(ignoreForNowButton)
        
        self.updateMissingServices(self.missingServices)
        
        let height = self.view.frame.size.height
        self.contentViewTop.constant = -height
        self.bgView.effect = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animatePresentation()
    }
    
    func updateMissingServices(_ missingServices: Set<NSObject>) {
        
        self.missingServices = missingServices
        
        if missingServices.contains(NSNumber(value: YKSServiceType.bluetoothService.rawValue as UInt)) {
            self.changeStatusLabelToOff(self.bluetoothStatusLabel)
            self.bluetoothButton.setImage(UIImage(named: "bluetooth2"), for: UIControlState())
            self.bluetoothButton.isUserInteractionEnabled = true
        } else {
            self.changeStatusLabelToOn(self.bluetoothStatusLabel)
            self.bluetoothButton.setImage(UIImage(named: "bluetooth1"), for: UIControlState())
            self.bluetoothButton.isUserInteractionEnabled = false
        }
        
        if missingServices.contains(NSNumber(value: YKSServiceType.locationService.rawValue as UInt)) {
            self.changeStatusLabelToOff(self.locationServicesStatusLabel)
            self.locationServicesButton.setImage(UIImage(named: "location2"), for: UIControlState())
            self.locationServicesButton.isUserInteractionEnabled = true
        } else {
            self.changeStatusLabelToOn(self.locationServicesStatusLabel)
            self.locationServicesButton.setImage(UIImage(named: "location1"), for: UIControlState())
            self.locationServicesButton.isUserInteractionEnabled = false
        }
        
        if missingServices.contains(NSNumber(value: YKSServiceType.internetConnectionService.rawValue as UInt)) {
            self.changeStatusLabelToOff(self.internetConnectionStatusLabel)
            self.internetConnectionButton.setImage(UIImage(named: "wifi2"), for: UIControlState())
            self.internetConnectionButton.isUserInteractionEnabled = true
        } else {
            self.changeStatusLabelToOn(self.internetConnectionStatusLabel)
            self.internetConnectionButton.setImage(UIImage(named: "wifi1"), for: UIControlState())
            self.internetConnectionButton.isUserInteractionEnabled = false
        }
        
        if missingServices.contains(NSNumber(value: YKSServiceType.pushNotificationService.rawValue as UInt)) {
            self.changeStatusLabelToOff(self.pushNotificationsStatusLabel)
            self.pushNotificationsButton.setImage(UIImage(named: "push2"), for: UIControlState())
            self.pushNotificationsButton.isUserInteractionEnabled = true
        } else {
            self.changeStatusLabelToOn(self.pushNotificationsStatusLabel)
            self.pushNotificationsButton.setImage(UIImage(named: "push1"), for: UIControlState())
            self.pushNotificationsButton.isUserInteractionEnabled = false
        }
        
        if missingServices.contains(NSNumber(value: YKSServiceType.backgroundAppRefreshService.rawValue as UInt)) {
            self.changeStatusLabelToOff(self.backgroundAppRefreshStatusLabel)
            self.backgroundAppRefreshButton.setImage(UIImage(named: "apprefresh2"), for: UIControlState())
            self.backgroundAppRefreshButton.isUserInteractionEnabled = true
        } else {
            self.changeStatusLabelToOn(self.backgroundAppRefreshStatusLabel)
            self.backgroundAppRefreshButton.setImage(UIImage(named: "apprefresh1"), for: UIControlState())
            self.backgroundAppRefreshButton.isUserInteractionEnabled = false
        }
    }
    
    func animatePresentation() {
        
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.4, delay:0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.contentViewTop.constant = -20
            self.bgView.effect = UIBlurEffect(style: .dark)
            self.view.layoutIfNeeded()
        })
        
    }
    
    func dismiss() {
        
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.4, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            let height = self.view.frame.size.height
            self.contentViewTop.constant = -height
            self.bgView.effect = nil
            self.view.layoutIfNeeded()
            
        }) { finished in
            
            self.updateOnceDone = false
            self.view.removeFromSuperview()
        }
    }
    
    func centerTextAndImageForButton(_ button: UIButton) {
        
        button.titleLabel?.textAlignment = NSTextAlignment.center
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.sizeToFit()
        
        button.contentVerticalAlignment = UIControlContentVerticalAlignment.top
        
        let spacing : CGFloat = 6
        
        if let imageSize = button.imageView?.image?.size,
            let titleLabel = button.titleLabel,
            let text = titleLabel.text {
            
            button.titleEdgeInsets = UIEdgeInsetsMake(imageSize.height + spacing, -imageSize.width, -(spacing), 0)
            
            let titleSize = (text as NSString).size(attributes: [ NSFontAttributeName: titleLabel.font ])
            button.imageEdgeInsets = UIEdgeInsetsMake( 0, 0, 0, -titleSize.width)
        }
    }
    
    func changeStatusLabelToOn(_ label: UILabel) {
        
        label.text = "ON"
        label.textColor = UIColor(hex6: 0x7CBE31)
    }
    
    func changeStatusLabelToOff(_ label: UILabel) {
        
        label.text = "OFF"
        label.textColor = UIColor(hex6: 0xD5001A)
    }
    
    @IBAction func bgViewTapped(_ sender: UITapGestureRecognizer) {
    
        self.dismiss()
    }
    
    @IBAction func viewSwipedUp(_ sender: UISwipeGestureRecognizer) {
    
        self.dismiss()
    }
    
    @IBAction func ignoreForNowButtonTouched(_ sender: UIButton) {
    
        self.dismiss()
    }
    
    @IBAction func internetConnectionButtonTouched(_ sender: UIButton) {
        
        let alert = PKAlertViewController.alert { configuration in
            
            configuration?.title = "Internet Connection Missing";
            configuration?.message = "Please open your iOS Control Center and enable wifi or turn on Cellular Data from Settings.";
            
            configuration?.addAction(PKAlertAction(title: "Ignore", handler: { (action, closed) -> Void in
                
            }))
            
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                configuration?.addAction(PKAlertAction(title: "yikes Settings", handler: { (action, closed) -> Void in
                    
                    if closed == true {
                        UIApplication.shared.openURL(settingsURL)
                    }
                }))
            }
            
        }
        self.present(alert!, animated: true, completion: nil)
    }
    
    @IBAction func bluetoothButtonTouched(_ sender: UIButton) {
        
        let alert = PKAlertViewController.alert { configuration in
            
            configuration?.title = "Bluetooth Disabled";
            configuration?.message = "Please open your iOS Control Center or go to Settings to enable Bluetooth.";
            
            configuration?.addAction(PKAlertAction(title: "Ok", handler: { (action, closed) -> Void in
                
            }))
            
        }
        self.present(alert!, animated: true, completion: nil)
    }
    
    @IBAction func locationServicesButtonTouched(_ sender: UIButton) {
        
        let alert = PKAlertViewController.alert { configuration in
            
            configuration?.title = "Location Services Disabled";
            configuration?.message = "To re-enable, please go to Settings and turn on Location Service for this app.";
            
            configuration?.addAction(PKAlertAction(title: "Ignore", handler: { (action, closed) -> Void in
                
            }))
            
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                configuration?.addAction(PKAlertAction(title: "yikes Settings", handler: { (action, closed) -> Void in
                    
                    if closed == true {
                        UIApplication.shared.openURL(settingsURL)
                    }
                }))
            }
            
        }
        self.present(alert!, animated: true, completion: nil)
    }
    
    @IBAction func pushNotificationsButtonTouched(_ sender: UIButton) {
        
        let alert = PKAlertViewController.alert { configuration in
            
            configuration?.title = "Push Notifications Disabled";
            configuration?.message = "To re-enable, please go to Settings and turn on Push Notifications for this app.";
            
            configuration?.addAction(PKAlertAction(title: "Ignore", handler: { (action, closed) -> Void in
                
            }))
            
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                configuration?.addAction(PKAlertAction(title: "yikes Settings", handler: { (action, closed) -> Void in
                    
                    if closed == true {
                        UIApplication.shared.openURL(settingsURL)
                    }
                }))
            }
            
        }
        self.present(alert!, animated: true, completion: nil)
    }
    
    @IBAction func backgroundAppRefreshButtonTouched(_ sender: UIButton) {
        
        let alert = PKAlertViewController.alert { configuration in
            
            configuration?.title = "Background App Refresh Disabled";
            configuration?.message = "To re-enable, please go to Settings and turn on Background App Refresh for this app.";
            
            configuration?.addAction(PKAlertAction(title: "Ignore", handler: { (action, closed) -> Void in
                
            }))
            
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                configuration?.addAction(PKAlertAction(title: "yikes Settings", handler: { (action, closed) -> Void in
                    
                    if closed == true {
                        UIApplication.shared.openURL(settingsURL)
                    }
                }))
            }
            
        }
        self.present(alert!, animated: true, completion: nil)
    }
    
    

}

