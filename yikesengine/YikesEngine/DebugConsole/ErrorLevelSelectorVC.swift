//
//  ErrorLevelSelectorVC.swift
//  YikesEngine
//
//  Created by Alexandar Dimitrov on 2016-02-09.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class DebugLevelSelectorVC: UIViewController {
    
    @IBOutlet weak var errorLevelSlider: UISlider! {
        didSet {
            errorLevelSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
        }
    }
    @IBOutlet weak var levelDebugLabel: UILabel!
    @IBOutlet weak var levelInfoLabel: UILabel!
    @IBOutlet weak var levelWarningLabel: UILabel!
    @IBOutlet weak var levelErrorLabel: UILabel!
    @IBOutlet weak var levelCriticalErrorLabel: UILabel!
    @IBOutlet weak var levelExternalLabel: UILabel!
    
    var errorLevelsArray : Array<UILabel> = []
    var errorLevelsEnumArray : [LoggerLevel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        errorLevelsArray = [levelExternalLabel,
            levelCriticalErrorLabel,
            levelErrorLabel,
            levelWarningLabel,
            levelInfoLabel,
            levelDebugLabel]
        
        errorLevelsEnumArray = [.external, .critical, .error, .warning, .info, .debug]
        
        let previouslySelectedErrorLevel = DebugManager.sharedInstance.maxAllowedLoggerLevel
        
        switch (previouslySelectedErrorLevel) {
        case .external:
            self.errorLevelSlider.setValue(0.0, animated: true)
            
        case .critical:
            self.errorLevelSlider.setValue(1.0, animated: true)
        
        case .error:
            self.errorLevelSlider.setValue(2.0, animated: true)
        
        case .warning:
            self.errorLevelSlider.setValue(3.0, animated: true)
            
        case .info:
            self.errorLevelSlider.setValue(4.0, animated: true)
        
        case .debug:
            self.errorLevelSlider.setValue(5.0, animated: true)
            
        }
        
        errorLevelChanged()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    deinit {
    }
    
    
    func errorLevelChanged() {
        let newSliderValue = lroundf(self.errorLevelSlider.value)
        
        self.errorLevelSlider.setValue(Float(newSliderValue), animated: true)
        
        _ = self.errorLevelsArray.filter { errorLevelsArray.index(of: $0) > newSliderValue }.map { $0.isEnabled = false }
        _ = self.errorLevelsArray.filter { errorLevelsArray.index(of: $0) <= newSliderValue }.map { $0.isEnabled = true }
        
        DebugManager.sharedInstance.maxAllowedLoggerLevel = errorLevelsEnumArray[newSliderValue]
    }
    
    
    @IBAction func errorLevelValueChanged(_ sender: AnyObject) {
        self.errorLevelChanged()
    }
    
    @IBAction func applyChanges(_ sender: AnyObject) {
        DebugManager.sharedInstance.filterOutLogs()
        self.dismiss(animated: true, completion: nil)
    }
    
}
