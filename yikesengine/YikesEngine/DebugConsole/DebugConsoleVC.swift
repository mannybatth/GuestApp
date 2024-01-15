//
//  DebugConsoleVC.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/8/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

import YikesSharedModel
import YKSSPLocationManager

class DebugConsoleVC: UIViewController, UIPopoverPresentationControllerDelegate, UIAlertViewDelegate {
    
    @IBOutlet weak var headerConstraint: NSLayoutConstraint!
    @IBOutlet weak var missingServicesButton: UIButton!
    
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var GAVersionLabel: UILabel!
    @IBOutlet weak var apiEnvLabel: UILabel!
    @IBOutlet weak var engineVersionLabel: UILabel!
    @IBOutlet weak var osVersionLabel: UILabel!
    @IBOutlet weak var BLEVersionLabel: UILabel!
    
    @IBOutlet weak var elevatorStatusView: UIView!
    @IBOutlet weak var elevatorStatusDotImageView: UIImageView!
    @IBOutlet weak var elevatorStatusIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var deviceStatusLabel: UILabel?
    @IBOutlet weak var engineSwitchButton: UIButton!
    @IBOutlet weak var shareLastLogImageView: UIImageView!
    
    
    var logsVC: DCLogsVC?
    var oldConnectionsVC: DCOldConnectionsVC?
    var activeConnectionsVC : DCActiveConnectionsVC?
    
    var isDebugConsolePresented : Bool = false
    var documentController : UIDocumentInteractionController?
    var errorLevelSelectorPopoverController : UIPopoverPresentationController?
    
    // For testing
    let loggerLevelArray: [LoggerLevel] = [.external, .critical, .error, .warning, .info, .debug]
    let loggerCategoryArray: [LoggerCategory] = [.System, .BLE, .API, .Device, .Service, .YLink, .Engine]
    var counter = 0
    
    
    func timerIsOver(_ timer:Timer!) {
        
        let diceRoll = Int(arc4random_uniform(6))
        let diceWithSevenSidesRoll = Int(arc4random_uniform(7))
        let luckyLoggerLevel = self.loggerLevelArray[diceRoll]
        let luckyLoggerCategory = self.loggerCategoryArray[diceWithSevenSidesRoll]
        
        yLog(luckyLoggerLevel, category: luckyLoggerCategory, message: "Msg \(counter+=1) is \(luckyLoggerLevel.description) - \(luckyLoggerCategory)")
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.view.superview?.layoutIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MotionManager.sharedInstance.addObserver(self)
        ServicesManager.sharedInstance.addObserver(self)
        
        DebugManager.sharedInstance.maxAllowedLoggerLevel = restoreDebugLevel()
        DebugManager.sharedInstance.isYLinkDebuggingDisabled = restoreIsDebugDisabled()
        DebugManager.sharedInstance.slackRemoteLoggingChannel = restoreSlackRemoteLoggingChannel()
        
        DebugManager.sharedInstance.filterOutLogs()
        
        
//        testTimers()
        
        let singleTap = UITapGestureRecognizer(target: self, action:#selector(DebugConsoleVC.shareLastLogs))
        singleTap.numberOfTapsRequired = 1
        self.shareLastLogImageView.isUserInteractionEnabled = true
        self.shareLastLogImageView.addGestureRecognizer(singleTap)
        
        if let attributedText = self.relaxMinConnectRSSI.titleLabel?.attributedText {
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            mutableAttributedString.mutableString.setString("Min Connect RSSI\nrelaxed by \(BLEEngine.sharedInstance.backgroundMinConnectRSSIRelaxing) in BG")
            self.relaxMinConnectRSSI.setAttributedTitle(mutableAttributedString, for: UIControlState())
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DebugManager.sharedInstance.debugConsoleVCReference = self
        
        userEmailLabel.text = YKSSessionManager.sharedInstance.currentUser?.email
        GAVersionLabel.text = "GA v" + DeviceHelper.sharedInstance.fullGuestAppVersion()
        apiEnvLabel.text = YikesEngineSP.sharedEngine().currentApiEnv.stringValue
        engineVersionLabel.text = "Engine v" + DeviceHelper.sharedInstance.info["EngineV"]!
        osVersionLabel.text = "iOS " + DeviceHelper.sharedInstance.info["osV"]!
        BLEVersionLabel.text = "BLE v\(BLEEngine.sharedInstance.bleEngineVersion)"

        engineSwitchButton.titleLabel?.lineBreakMode = .byWordWrapping
        engineSwitchButton.titleLabel?.textAlignment = .center
        
        engineSwitchButton.setTitle("SP active\nTap for more", for: UIControlState())
        
        deviceMotionStateDidChange(MotionManager.sharedInstance.motionState)
        currentLocationStateDidChange(YKSSPLocationManager.shared().currentSPLocationState)
        
        NotificationCenter.default.addObserver(self, selector: #selector(DebugConsoleVC.statusBarHeightDidChange(_:)), name: NSNotification.Name.UIApplicationDidChangeStatusBarFrame, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DebugManager.sharedInstance.debugConsoleVCReference = nil
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidChangeStatusBarFrame, object: nil)
        
    }
    
    deinit {
        MotionManager.sharedInstance.removeObserver(self)
        ServicesManager.sharedInstance.removeObserver(self)
        DebugManager.sharedInstance.debugConsoleVCReference = nil
    }
    
    func shareLastLogs() {
        self.shareLogFile(FileLoggerHelper.sortedLogFileInfos().first!)
    }
    
    func testTimers() {
        let timer = Timer(timeInterval: 0.5, target: self, selector: #selector(DebugConsoleVC.timerIsOver(_:)), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
        
        let timer2 = Timer(timeInterval: 0.2, target: self, selector: #selector(DebugConsoleVC.timerIsOver(_:)), userInfo: nil, repeats: true)
        RunLoop.current.add(timer2, forMode: RunLoopMode.commonModes)
        
        let timer3 = Timer(timeInterval: 0.333, target: self, selector: #selector(DebugConsoleVC.timerIsOver(_:)), userInfo: nil, repeats: true)
        RunLoop.current.add(timer3, forMode: RunLoopMode.commonModes)
    }
    
    
    func restoreDebugLevel() -> LoggerLevel {
        
        if let email = YKSSessionManager.sharedInstance.currentUser?.email {
            
            if (DebugManager.sharedInstance.hasAccessToDebugLevel(email)) {
                
                let restoredDebugLevel = UserDefaults.standard.integer(forKey: EngineConstants.maxAllowedLoggerLevelKey)
                
                if (restoredDebugLevel > 0) {
                    return LoggerLevel(rawValue: restoredDebugLevel)!
                } else {
                    return LoggerLevel.debug // If didn't find saved debug level, use Debug (highest)
                }
            }
        }
        
        return LoggerLevel.info
    }
    
    
    func restoreIsDebugDisabled() -> Bool {
        
        if let email = YKSSessionManager.sharedInstance.currentUser?.email {
            
            if (DebugManager.sharedInstance.hasAccessToYLinkLPDebug(email)) {
                
                return UserDefaults.standard.bool(forKey: EngineConstants.yLinkDebuggingDisabledKey)
            }
        }
        return false
    }
    
    func restoreSlackRemoteLoggingChannel() -> SlackChannel? {
        
        if let email = YKSSessionManager.sharedInstance.currentUser?.email {
            
            if (DebugManager.sharedInstance.hasAccessToDebugLevel(email)) {
                
                if let json = UserDefaults.standard.object(forKey: EngineConstants.slackRemoteLoggingChannelKey) as? [String: AnyObject] {
                    return SlackChannel(JSON: json)
                }
            }
        }
        return nil
    }
    
    func deviceMotionStateDidChange(_ status: YKSDeviceMotionState) {
        
        if YKSSPLocationManager.shared().currentSPLocationState == .leftSPHotel {
            return
        }
        
        DispatchQueue.main.async {
            
            if (status == .didBecomeStationary) {
                
                self.deviceStatusLabel?.text = "Device is stationary"
                self.deviceStatusLabel?.isHidden = false
                
            } else {
                
                self.deviceStatusLabel?.isHidden = true
                self.currentLocationStateDidChange(YKSSPLocationManager.shared().currentSPLocationState)
            }
        }
    }
    
    func currentLocationStateDidChange(_ state: YKSLocationState) {
        
        DispatchQueue.main.async {
            
            if (state == .leftSPHotel) {
                
                self.deviceStatusLabel?.text = "You are outside SP iBeacon range"
                self.deviceStatusLabel?.isHidden = false
                
            } else if (state == .enteredSPHotel) {
                
                if MotionManager.sharedInstance.isStationary() {
                    self.deviceStatusLabel?.text = "Device is stationary"
                    self.deviceStatusLabel?.isHidden = false
                }
                else {
                    self.deviceStatusLabel?.text = ""
                    self.deviceStatusLabel?.isHidden = true
                }
            }
        }
    }
    
    func shareLogFile(_ fileInfo: LogFileInfo) {
        
        documentController = UIDocumentInteractionController(url: fileInfo.filePathURL as URL)
        documentController?.presentOptionsMenu(from: self.view.frame, in: self.view, animated: true)
    }
    
    func reloadLogs() {
        DebugManager.sharedInstance.filterOutLogs()
    }
    
    func selectSlackRemoteLoggingChannel() {
        
        let slackChannelsAlertController = UIAlertController(title: "Select a Slack channel", message: nil, preferredStyle: .actionSheet)
        
        for channel in SlackLogger.channels {
            
            let channelAction = UIAlertAction(title: channel.channelName, style: .default) { (action: UIAlertAction) -> Void in
                DebugManager.sharedInstance.slackRemoteLoggingChannel = channel
            }
            slackChannelsAlertController.addAction(channelAction)
        }
        
        slackChannelsAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(slackChannelsAlertController, animated: true, completion: nil)
    }
    
    @IBAction func optionsButtonTouched(_ sender: UIButton) {
        
        let optionsAlertController = UIAlertController(title: "Debug Console Options", message: nil, preferredStyle: .actionSheet)
        
        // Restart session
        let restartSessionAction = UIAlertAction(title: "Restart session", style: .default) { (action: UIAlertAction) -> Void in
            FileLogger.sharedInstance.rollLogFileNow()
        }
        
        // Share full logs
        let shareLogsAction = UIAlertAction(title: "Share full logs", style: .default) { action in
            
            let logsAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            for fileInfo in FileLoggerHelper.sortedLogFileInfos() {
                
                let fileAction = UIAlertAction(title: fileInfo.fileName, style: .default) { action in
                    self.view.frame = self.debugEndFrame()
                    self.shareLogFile(fileInfo)
                }
                logsAlertController.addAction(fileAction)
                
            }
            
            logsAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                self.view.frame = self.debugEndFrame()
            }))
            
            self.present(logsAlertController, animated: true, completion: nil)
        }
        
        // Log level settings
        let selectDebugLevelAction = UIAlertAction(title: "Log level settings", style: .default) { (action) -> Void in
            
            if let url = YikesEngineSP.sharedInstance.bundleURL() {
                let bundle = Bundle(url: url)
                let storyboard = UIStoryboard(name: "DebugConsole", bundle: bundle)
                let debugLevelSelectorVC = storyboard.instantiateViewController(withIdentifier: "DebugLevelSelectorVC_SBID") as! DebugLevelSelectorVC
                
                debugLevelSelectorVC.preferredContentSize = CGSize(width: 400, height: 385)
                debugLevelSelectorVC.modalPresentationStyle = UIModalPresentationStyle.popover
                
                var startRect = CGRect.zero;
                startRect.origin.x = 0;
                startRect.origin.y = self.view.bounds.midY - self.view.frame.origin.y / 2.0;
                
                self.errorLevelSelectorPopoverController = debugLevelSelectorVC.popoverPresentationController
                self.errorLevelSelectorPopoverController?.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
                self.errorLevelSelectorPopoverController?.delegate = self
                self.errorLevelSelectorPopoverController?.sourceView = self.view;
                self.errorLevelSelectorPopoverController?.sourceRect = startRect
                
                self.present(debugLevelSelectorVC, animated: true, completion: nil)
            }
        }
        
        // LP_Debug
        let lpDebugTitle = DebugManager.sharedInstance.isYLinkDebuggingDisabled ? "Enable LP_Debug messages" : "Disable LP_Debug messages"
        let selectLP_DebugAction = UIAlertAction(title: lpDebugTitle, style: .default) { (action: UIAlertAction) -> Void in
            DebugManager.sharedInstance.isYLinkDebuggingDisabled = !DebugManager.sharedInstance.isYLinkDebuggingDisabled
            DebugManager.sharedInstance.filterOutLogs()
        }
        
        // Encryption
        let currentSecureMode = BLEEngine.secureMode
        let encryptionStatusTitle = currentSecureMode == .encrypted ? "Turn OFF encryption" : "Turn ON encryption"
        let changeEncryptionAction = UIAlertAction(title: encryptionStatusTitle, style: .default) { (action: UIAlertAction) -> Void in
            
            if currentSecureMode == .encrypted {
                BLEEngine.secureMode = .plainText
            }
            else {
                BLEEngine.secureMode = .encrypted
            }
            self.logsVC?.updateEncryptionLockButton()
        }
        
        // Remote Slack logging
        let remoteLoggingTitle = DebugManager.sharedInstance.slackRemoteLoggingChannel != nil ? "Disable remote logging" : "Enable remote logging"
        let remoteLoggingAction = UIAlertAction(title: remoteLoggingTitle, style: .default) { (action: UIAlertAction) -> Void in
            
            if (DebugManager.sharedInstance.slackRemoteLoggingChannel != nil) {
                DebugManager.sharedInstance.slackRemoteLoggingChannel = nil
            } else {
                self.selectSlackRemoteLoggingChannel()
            }
        }
        
        // Add actions
        optionsAlertController.addAction(restartSessionAction)
        optionsAlertController.addAction(shareLogsAction)
        optionsAlertController.addAction(changeEncryptionAction)
        
        if let email = YKSSessionManager.sharedInstance.currentUser?.email {
            
            if (DebugManager.sharedInstance.hasAccessToDebugLevel(email)) {
                optionsAlertController.addAction(selectDebugLevelAction)
            }
            
            if (DebugManager.sharedInstance.hasAccessToYLinkLPDebug(email)) {
                optionsAlertController.addAction(selectLP_DebugAction)
            }
            
            if (DebugManager.sharedInstance.hasAccessToDebugLevel(email)) {
                optionsAlertController.addAction(remoteLoggingAction)
            }
        }
        
        optionsAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { alert in
            print("Cancel pressed")
            self.view.frame = self.debugEndFrame()
        }))
        
        present(optionsAlertController, animated: true, completion: nil)
    }
    
    @IBAction func recordButtonTouched(_ sender: UIButton) {
        
    }
    
    @IBAction func closeButtonTouched(_ sender: UIButton) {
        
        self.dismiss(animated: false, completion: nil)
        self.view.removeFromSuperview()
        self.isDebugConsolePresented = false
    }
    
    @IBAction func missingServicesButtonTouched(_ sender: UIButton) {
        
    }
    
    
    @IBAction func switchEngine(_ sender: AnyObject) {
        
        var infoText : String = "Currently engine is: \n"
        
        if (CentralManager.sharedInstance.isBeaconEnabled()) {
            infoText += "Beacon-based SP\n"
        }
        else {
            infoText += "SP Engine Forced\n\n"
        }

        infoText += "Engine switch options:"
        
        let switchEngineAlertController = UIAlertController(title: infoText, message: nil, preferredStyle: .alert)
        
        switchEngineAlertController.addAction(UIAlertAction(title: "Force MP Engine", style: .default, handler: { action in
            print("OK pressed")
            CentralManager.sharedInstance.switchToMP()
            self.view.removeFromSuperview()
            self.isDebugConsolePresented = false
        }))
        
        switchEngineAlertController.addAction(UIAlertAction(title: "Beacon based Engine", style: .default, handler: { action in
            print("Beacon based Engine pressed")
            CentralManager.sharedInstance.switchToBeaconBasedEngine()
            self.view.removeFromSuperview()
            self.isDebugConsolePresented = true
        }))
        
        switchEngineAlertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { switchEngineAlertController in
            print("Cancel pressed")
            self.view.frame = self.debugEndFrame()
            self.view.superview?.setNeedsLayout()
            self.view.superview?.layoutIfNeeded()
        }))
        
        present(switchEngineAlertController, animated: true, completion: nil)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "DCLogsVC" {
            logsVC = segue.destination as? DCLogsVC
            logsVC?.debugConsoleVC = self
            
        } else if segue.identifier == "DCOldConnectionsVC" {
            oldConnectionsVC = segue.destination as? DCOldConnectionsVC

        } else if segue.identifier == "DCActiveConnectionsVC" {
            activeConnectionsVC = segue.destination as? DCActiveConnectionsVC
        }
    }
    
    func showInView(_ view: UIView) {
        
        let startFrame = CGRect(x: view.frame.size.width / 2.0, y: view.frame.size.height / 2.0, width: 0, height: 0)
        
        var endFrame = self.debugEndFrame()
        
        self.view.frame = startFrame
        
        if (self.view.superview != nil) {
            self.view.removeFromSuperview()
        }
        
        UIApplication.shared.keyWindow?.addSubview(self.view)
        
        UIView.animate(withDuration: 0.3, delay:0.0, usingSpringWithDamping:0.6, initialSpringVelocity:0.9, options:[], animations: { () -> Void in
            
            self.view.frame = endFrame
            
        }) { finished in
            
            if finished {
                
//                self.view.frame = self.debugEndFrame()
                
                self.view.superview?.setNeedsLayout()
                self.view.superview?.layoutIfNeeded()
                
                self.isDebugConsolePresented = true
                
                self.reloadLogs()
                self.oldConnectionsVC?.tableView.reloadData()
                self.activeConnectionsVC?.tableView.reloadData()
                
                self.logsVC?.scrollToBottom()
                self.oldConnectionsVC?.scrollToBottom()
                self.activeConnectionsVC?.scrollToBottom()
            }
        }
    }
    
    
    func statusBarHeightDidChange(_ notification:Notification) {
        
        DispatchQueue.main.async {
            
            var oldFrame:CGRect?
            // grab the frame from the notification:
            if let userInfo = (notification as NSNotification).userInfo {
                if let wrappedRect = userInfo[UIApplicationStatusBarFrameUserInfoKey] as? NSValue {
                    oldFrame = wrappedRect.cgRectValue
                }
            }
            
            // check if there was a height change and update the layout:
            if oldFrame != nil {
                let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
                if let statusBarHeightBefore = oldFrame?.size.height {
                    
                    // remove (bigger status bar) or add (smaller status bar) height from view frame:
                    let origin = self.view.frame.origin
                    let size = self.view.frame.size
                    self.view.frame = CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
                    self.headerConstraint.constant = -(40-statusBarHeight)
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                    self.view.superview?.setNeedsLayout()
                    self.view.superview?.layoutIfNeeded()
                }
            }
        }
    }
    
    func debugEndFrame () -> CGRect {
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        if let frame = UIApplication.shared.keyWindow?.frame {
            var endFrame = CGRect(x: 0, y: 20, width: frame.size.width, height: frame.size.height-20)
            if statusBarHeight > 20 {
                endFrame = CGRect(x: 0, y: 20, width: endFrame.size.width, height: endFrame.size.height)
                self.headerConstraint.constant = 0
            }
            return endFrame
        }
        return CGRect.null
    }
    
    // MARK: UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return false
    }
    
    @IBOutlet weak var relaxMinConnectRSSI: UIButton!
    @IBAction func relaxMinConnectRSSITap(_ sender: AnyObject) {
        let av = UIAlertView(title: "Min Connect RSSI - Background", message: "Will be relaxed by this value in the background", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Set")
        av.alertViewStyle = UIAlertViewStyle.plainTextInput
        av.tag = 100;
        av.textField(at: 0)?.keyboardType = UIKeyboardType.numberPad
        av.textField(at: 0)?.placeholder = "\(BLEEngine.sharedInstance.backgroundMinConnectRSSIRelaxing)"
        av.show()
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.tag == 100 {
            if buttonIndex != alertView.cancelButtonIndex {
                if let text = alertView.textField(at: 0)?.text {
                    if let value = Int(text) {
                        if value > 0 && value <= 20 {
                            yLog(category: .Device, message: "Now relaxing the Min Connect RSSI when Backgrounded by \(value)")
                            BLEEngine.sharedInstance.backgroundMinConnectRSSIRelaxing = value
                            if let attributedText = self.relaxMinConnectRSSI.titleLabel?.attributedText {
                                let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
                                mutableAttributedString.mutableString.setString("Min Connect RSSI\nrelaxed by \(value) in BG")
                                self.relaxMinConnectRSSI.setAttributedTitle(mutableAttributedString, for: UIControlState())
                            }
                        }
                        else {
                            UIAlertView(title: "Error", message: "Invalid input:\nMust be in range of\n0 < value <= 20", delegate: nil, cancelButtonTitle: "Ok").show()
                        }
                    }
                }
            }
        }
    }
    
}

extension DebugConsoleVC: Observer {
    
    func notify(_ notification: ObserverNotification) {
        switch notification.observableEvent {
            
        case .didBecomeActive:
            deviceMotionStateDidChange(.isMoving)
            
        case .DeviceBecameStationary:
            deviceMotionStateDidChange(.didBecomeStationary)
            
        case .LocationStateDidChange:
            if let state = notification.data as? YKSLocationState {
                currentLocationStateDidChange(state)
            }
            
        case .MissingServicesDidChange:
            break
            
        default:
            break
        }
    }
    
}

