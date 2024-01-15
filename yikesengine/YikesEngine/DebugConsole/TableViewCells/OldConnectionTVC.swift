//
//  OldConnectionTVC.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/11/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

class OldConnectionTVC: UITableViewCell {
    
    @IBOutlet weak var startTimeLabel: UILabel?
    @IBOutlet weak var macAddressLabel: UILabel?
    @IBOutlet weak var reasonLabel: UILabel?
    @IBOutlet weak var roomNumberLabel: UILabel?
    @IBOutlet weak var timeLabel: UILabel?
    
    var connection : BLEConnection! {
        didSet {
            
            startTimeLabel?.text = DateHelper.sharedInstance.hourMinuteSecondFormatter.string(from: connection.start)
            macAddressLabel?.text = connection.yLink.macAddress
            reasonLabel?.text = connection.connectionEndReason.rawValue
            roomNumberLabel?.text = connection.yLink.roomNumber
            
            if connection.connectionEndReason == .Proximity {
                reasonLabel?.text = "prox \(connection.minConnectRSSI ?? 0)"
            }
            
            if let connectionStartedOn = connection.connectionStartedOn,
                let isSuccessfulOn = connection.isSuccessfulOn {
                timeLabel?.text = String(format: "%.01f", isSuccessfulOn.timeIntervalSince(connectionStartedOn as Date)) + " s"
            } else {
                timeLabel?.text = "0.0 s"
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
