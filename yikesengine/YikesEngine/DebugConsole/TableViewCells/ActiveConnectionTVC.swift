//
//  ActiveConnectionTVC.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/11/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import CoreBluetooth

class ActiveConnectionTVC: UITableViewCell {
    
    @IBOutlet weak var macAddressLabel: UILabel?
    @IBOutlet weak var roomNumberLabel: UILabel?
    
    @IBOutlet weak var connectionStatusView: UIView?
    @IBOutlet weak var connectionStatusIndicatorView: UIActivityIndicatorView?
    @IBOutlet weak var connectionStatusDotImageView: UIImageView?
    @IBOutlet weak var connectionStatusRSSILabel: UILabel?
    
    @IBOutlet weak var statusLabel: UILabel?
    
    var connection : BLEConnection! {
        didSet {
            
            var roomNumber : String? = connection.yLink.roomNumber
            
            if let peripheralName = connection.peripheral?.name,
                let rn = roomNumber {
                roomNumber = rn + " (\(peripheralName))"
            }
            
            macAddressLabel?.text = connection.yLink.macAddress
            roomNumberLabel?.text = roomNumber
            
            connectionStatusRSSILabel?.isHidden = true
            connectionStatusDotImageView?.isHidden = true
            connectionStatusIndicatorView?.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            
            connectionStatusIndicatorView?.stopAnimating()
            
            if connection.isSuccessful {
                
                connectionStatusDotImageView?.isHidden = false
                
            } else {
                
                if connection.mostRecentRSSI != nil {
                    
                    connectionStatusRSSILabel?.isHidden = false
                    connectionStatusRSSILabel?.text = "\(connection.mostRecentRSSI!)"
                    
                } else {
                    connectionStatusIndicatorView?.startAnimating()
                }
                
            }
            
            if connection.inOutLocation == .inside {
                statusLabel?.text = "inside"

            } else if connection.inOutLocation == .outside {
                statusLabel?.text = "outside"
                
            } else if connection.inOutLocation == .unknown {
                statusLabel?.text = "--"
                
            }
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(rgba: "#3A3A3A")
        self.selectedBackgroundView = bgColorView
    }
}
