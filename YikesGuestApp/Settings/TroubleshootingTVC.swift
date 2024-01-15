//
//  TroubleshootingTVC.swift
//  YikesGuestApp
//
//  Created by Manny Singh on 2/1/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesGenericEngine
import YikesSharedModel

class TroubleshootingTVC: YKSBaseTVC, YikesEngineDelegate {

    var missingServices : Set<AnyHashable>?
    
    let appDelegate = UIApplication.shared.delegate as! YKSAppDelegate
    
    @IBOutlet weak var bluetoothStatusLabel: UILabel!
    @IBOutlet weak var locationServicesStatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50
        
        refreshMissingServices()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        appDelegate.addEngineObserver(self)
        sizeHeaderToFit()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        appDelegate.removeEngineObserver(self)
    }
    
    func refreshMissingServices() {
        YikesEngine.sharedInstance.missingServices { services -> Void in
            self.missingServices = services
            self.reloadPage()
        }
    }
    
    func setBluetoothStatusEnabled() {
        
        bluetoothStatusLabel.text = "enabled"
        bluetoothStatusLabel.textColor = UIColor(hex6: 0x5F9318)
    }
    
    func setBluetoothStatusDisabled() {
        
        bluetoothStatusLabel.text = "disabled"
        bluetoothStatusLabel.textColor = UIColor(hex6: 0xD84C43)
    }
    
    func setLocationStatusEnabled() {
        
        locationServicesStatusLabel.text = "enabled"
        locationServicesStatusLabel.textColor = UIColor(hex6: 0x5F9318)
    }
    
    func setLocationStatusDisabled() {
        
        locationServicesStatusLabel.text = "disabled"
        locationServicesStatusLabel.textColor = UIColor(hex6: 0xD84C43)
    }
    
    func reloadPage() {
        
        setBluetoothStatusEnabled()
        setLocationStatusEnabled()
        
        if let missingServices = missingServices {
            
            if missingServices.contains(NSNumber(value: YKSServiceType.bluetoothService.rawValue as UInt)) {
                setBluetoothStatusDisabled()
            }
            
            if missingServices.contains(NSNumber(value: YKSServiceType.locationService.rawValue as UInt)) {
                setLocationStatusDisabled()
            }
        }
        self.tableView.reloadData()
    }
    
    func sizeHeaderToFit() {
        tableView.tableHeaderView?.setNeedsLayout()
        tableView.tableHeaderView?.layoutIfNeeded()
        
        let height = tableView.tableHeaderView?.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        
        var frame = tableView.tableHeaderView?.frame
        frame?.size.height = height! + 10
        tableView.tableHeaderView?.frame = frame!
        
        self.tableView.tableHeaderView = self.tableView.tableHeaderView;
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = UIColor(hex6: 0x4A4A4A)
            header.textLabel?.font = UIFont(name: "HelveticaNeue", size: 13.0)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
        
    }
    
}

extension TroubleshootingTVC {
    
    func yikesEngineRequiredServicesMissing(_ missingServices: Set<AnyHashable>!) {
        self.missingServices = missingServices
        self.reloadPage()
    }
    
}
