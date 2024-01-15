//
//  DCLogsVC.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/8/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

import PKHUD

class DCLogsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct DCConstants {
        static let millisecondsForMaxNumberOfMessages: Double = 1000.0
        static let maxNumberOfMessages: Int = 50
        static let mSecPerSec: Double = 1000.0
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scrollToBottomButton: UIButton!
    @IBOutlet weak var encryptionButton: UIButton!
    
    var debugConsoleVC : DebugConsoleVC?
    
    var lastContentOffset : CGFloat = 0
    var isAutoScrollPaused : Bool = false {
        didSet {
            if let url = YikesEngineSP.sharedInstance.bundleURL() {
                let bundle = Bundle(url: url)
                if isAutoScrollPaused {
                    let image = UIImage(named: "ic_play_arrow_white", in: bundle, compatibleWith: nil)
                    scrollToBottomButton.setImage(image, for: UIControlState())
                } else {
                    let image = UIImage(named: "ic_pause_white", in: bundle, compatibleWith: nil)
                    scrollToBottomButton.setImage(image, for: UIControlState())
                }
            }
        }
    }
    
    var lastScrollTimeInterval = CACurrentMediaTime()
    var messageCounter = 0
//    var timer: NSTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateEncryptionLockButton()
        scrollToBottomButton.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
//        timer = NSTimer(timeInterval: 0.05, target: self, selector: "scrollTimerIsOver:", userInfo: nil, repeats: true)
//        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    

    func updateEncryptionLockButton() {
        
        if let url = YikesEngineSP.sharedInstance.bundleURL() {
            let bundle = Bundle(url: url)
            
            if BLEEngine.secureMode == BLEEngine.SecureMode.encrypted {
                let image = UIImage(named: "ic_lock_outline_white", in: bundle, compatibleWith: nil)
                image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                encryptionButton.tintColor = UIColor.green
                encryptionButton.setImage(image, for: UIControlState())
            }
            else {
                let image = UIImage(named: "ic_lock_open_white", in: bundle, compatibleWith: nil)
                image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                encryptionButton.tintColor = UIColor.red
                encryptionButton.setImage(image, for: UIControlState())
            }
        }
    }
    
    
    func insertLog(_ atIndex: Int) {
        messageCounter += 1
        
        let indexPath = IndexPath(row: atIndex, section: 0)
        
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [indexPath], with: .none)
        self.tableView.endUpdates()
        
        scrollToBottom()
    }
    
    func updateLog(_ atIndex: Int) {
        
        let indexPath = IndexPath(row: atIndex, section: 0)
        
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: [indexPath], with: .none)
        self.tableView.endUpdates()
    }
    
    func deleteLog(_ atIndex: Int) {
        
        let indexPath = IndexPath(row: atIndex, section: 0)
        
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: [indexPath], with: .none)
        self.tableView.endUpdates()
    }
    
    func scrollToBottom() {
        if isAutoScrollPaused { return }
        
        let numberOfRows = self.tableView.numberOfRows(inSection: 0)
        if numberOfRows > 0 {
            let indexPath = IndexPath(row: numberOfRows-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    func reportBug(_ comment: String?) {
        
        var fileURLsToUpload : [URL] = []
        
        let sortedLogFileInfos = FileLoggerHelper.sortedLogFileInfos()
        for fileInfo in sortedLogFileInfos {
            
            fileURLsToUpload.append(fileInfo.filePathURL as URL)
            
            if fileURLsToUpload.count >= 2 {
                break
            }
        }
        
        for fileURL in fileURLsToUpload {
            
            HUD.show(HUDContentType.labeledProgress(title: "Uploading...", subtitle: ""))
            
            SlackLogger.uploadFile(fileURL, comment: comment, success: {
                
                HUD.show(HUDContentType.labeledSuccess(title: "Success", subtitle: "Thank You!"))
                HUD.hide(afterDelay: 1.0)
                
            }) { (error) in
                yLog(.error, message: "Error uploading the bug report:\n\(error)")
                HUD.show(HUDContentType.labeledError(title: "Error", subtitle: "Please Try Again."))
                HUD.hide(afterDelay: 1.0)
            }
        }
    }
    
    @IBAction func reportBugButtonTouched(_ sender: UIButton) {
        
        var inputTextField: UITextField?
        
        let bugReportPrompt = UIAlertController(title: "Report Bug", message: "Pressing OK will send your most recent logs and provided description to the development team.", preferredStyle: UIAlertControllerStyle.alert)
        bugReportPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            // force the layout (seems to be a bug on iOS 10):
            if let debugFrame = self.debugConsoleVC?.debugEndFrame() {
                self.debugConsoleVC?.view.frame = debugFrame
                self.view.superview?.setNeedsLayout()
                self.view.superview?.layoutIfNeeded()
            }
        }))
        bugReportPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            
            self.reportBug(inputTextField?.text)
            
        }))
        bugReportPrompt.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Tell us what went wrong."
            textField.autocorrectionType = .yes
            textField.autocapitalizationType = .sentences
            inputTextField = textField
        })
        
        present(bugReportPrompt, animated: true, completion: {
            if let debugFrame = self.debugConsoleVC?.debugEndFrame() {
                self.debugConsoleVC?.view.frame = debugFrame
                self.view.superview?.setNeedsLayout()
                self.view.superview?.layoutIfNeeded()
            }
        })
        
    }
    
    @IBAction func scrollToBottomButtonTouched(_ sender: UIButton) {
        
        if isAutoScrollPaused {
            self.tableView.reloadData()
            scrollToBottom()
            isAutoScrollPaused = false
        }
        else {
            isAutoScrollPaused = true
        }
    }
    

    // MARK: UIScrollViewDelegate methods
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (lastContentOffset > scrollView.contentOffset.y + 30) {
            
            // scrolling up
//            isAutoScrollPaused = true
        }
        lastContentOffset = scrollView.contentOffset.y
    }
    
    // MARK: UITableViewDataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DebugManager.sharedInstance.filteredLogs.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let logMessage = DebugManager.sharedInstance.filteredLogs[(indexPath as NSIndexPath).row]
        
        if let height = logMessage.tableViewCellHeight {
            return height
        }
        
        let height = LogTVC.heightOfCellWithLogMessage(logMessage)
        logMessage.tableViewCellHeight = height
        
        return height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogTVC") as! LogTVC
        
        cell.logMessage = DebugManager.sharedInstance.filteredLogs[(indexPath as NSIndexPath).row]
        
        return cell
    }
}
