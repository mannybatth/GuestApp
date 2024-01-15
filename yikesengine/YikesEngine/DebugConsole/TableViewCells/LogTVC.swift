//
//  LogTVC.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/11/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

class LogTVC: UITableViewCell {
    
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var messageLabel: UILabel?
    
    var logMessage : LogMessage! {
        didSet {
            
            self.timeLabel?.text = DateHelper.sharedInstance.minuteSecondMilliSecondFormatter.string(from: logMessage.timestamp)
            self.messageLabel?.text = logMessage.message
            
            if logMessage.isFatal {
                self.messageLabel?.textColor = UIColor.red
            } else {
                self.messageLabel?.textColor = UIColor.white
                
                if logMessage.category == .Device {
                    self.contentView.backgroundColor = UIColor(hex6: 0x690562, alpha: 0.8)
                }
                else if logMessage.category == .Location {
                }
                else if logMessage.category == .BLE && logMessage.level == LoggerLevel.critical {
                    self.contentView.backgroundColor = UIColor.red
                }
                else if logMessage.level == LoggerLevel.critical {
                    self.contentView.backgroundColor = UIColor.purple
                }
                else if logMessage.level == LoggerLevel.error {
                    self.contentView.backgroundColor = UIColor.red
                }
                else {
                    self.contentView.backgroundColor = UIColor.black
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(hex6: 0x3A3A3A)
        self.selectedBackgroundView = bgColorView
    }
    
    class func heightOfCellWithLogMessage(_ logMessage: LogMessage) -> CGFloat {
        
        let screenWidth = UIScreen.main.bounds.width
        
        return logMessage.message.boundingRect(
            with: CGSize(width: screenWidth-73, height: CGFloat.infinity),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 11)],
            context: nil).size.height + 8
    }
    
}
