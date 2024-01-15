//
//  UnlockDoorTipVC.swift
//  YikesGuestApp
//
//  Created by Manny Singh on 7/27/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import MediaPlayer
import YikesSharedModel

class UnlockDoorTipVC: UIViewController {

    @IBOutlet weak var playerView: UIView!
    
    var moviePlayer : MPMoviePlayerController!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!)  {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.commonInit()
    }
    
    func commonInit() {
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer.cornerRadius = 8;
        self.view.layer.masksToBounds = true;
        
        let path = Bundle.main.path(forResource: "unlock_door", ofType:"mp4")
        let url = URL(fileURLWithPath: path!)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            
        }
        
        moviePlayer = MPMoviePlayerController(contentURL: url)
        
        moviePlayer.scalingMode = MPMovieScalingMode.aspectFit
        moviePlayer.controlStyle = MPMovieControlStyle.none
        moviePlayer.movieSourceType = MPMovieSourceType.file
        moviePlayer.repeatMode = MPMovieRepeatMode.one
        moviePlayer.view.translatesAutoresizingMaskIntoConstraints = false
        moviePlayer.play()
        
        self.playerView.addSubview(moviePlayer.view)
        
        let views = ["player" : moviePlayer.view]
        self.playerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[player]|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
        self.playerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[player]|", options: NSLayoutFormatOptions(), metrics: nil, views: views))
    }
    
    @IBAction func closeButtonTouched(_ sender: UIBarButtonItem) {
        
        self.dismiss(animated: true, completion: nil)
    }
 
}

extension UnlockDoorTipVC: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        if presented == self {
            return CustomPresentationController(presentedViewController: presented, presenting: presenting)
        }
        
        return nil
    }
}

class CustomPresentationController: UIPresentationController {
    
    lazy var dimmingView :UIView = {
        let view = UIView(frame: self.containerView!.bounds)
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        view.alpha = 0.0
        return view
    }()
    
    override func presentationTransitionWillBegin() {
        
        guard
            let containerView = containerView,
            let presentedView = presentedView
            else {
                return
        }
        
        // Add the dimming view and the presented view to the heirarchy
        dimmingView.frame = containerView.bounds
        containerView.addSubview(dimmingView)
        containerView.addSubview(presentedView)
        
        // Fade in the dimming view alongside the transition
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: {(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.dimmingView.alpha = 1.0
                }, completion:nil)
        }
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool)  {
        // If the presentation didn't complete, remove the dimming view
        if !completed {
            self.dimmingView.removeFromSuperview()
        }
    }
    
    override func dismissalTransitionWillBegin()  {
        // Fade out the dimming view alongside the transition
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: {(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.dimmingView.alpha  = 0.0
                }, completion:nil)
        }
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        // If the dismissal completed, remove the dimming view
        if completed {
            self.dimmingView.removeFromSuperview()
        }
    }
    
    override var frameOfPresentedViewInContainerView : CGRect {
        
        guard
            let containerView = containerView
            else {
                return CGRect()
        }
        
        var frame = CGRect(x: 0, y: 0, width: 310, height: 285)
        frame.origin.x = (containerView.frame.size.width / 2) - (frame.size.width / 2)
        frame.origin.y = (containerView.frame.size.height / 2) - (frame.size.height / 2)
        
        return frame
    }
    
    
    // ---- UIContentContainer protocol methods
    
    override func viewWillTransition(to size: CGSize, with transitionCoordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: transitionCoordinator)
        
        guard
            let containerView = containerView
            else {
                return
        }
        
        transitionCoordinator.animate(alongsideTransition: {(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.dimmingView.frame = containerView.bounds
            }, completion:nil)
    }
}

class UnlockDoorTipPresentationController : NSObject {
    
    weak var parent : UIViewController?
    
    static let tipsDisabledKey = "InAppTipsDisabled"
    static var areTipsDisabled : Bool {
        get {
            return UserDefaults.standard.bool(forKey: UnlockDoorTipPresentationController.tipsDisabledKey)
        }
        
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey:UnlockDoorTipPresentationController.tipsDisabledKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    var timer : DispatchSourceTimer?
    let secondsToWaitWhileConnected = 5.0
    
    var listOfRoomStatuses : [String:YKSConnectionStatus] = [:]
    
    init(parent: UIViewController) {
        self.parent = parent
    }
    
    func cancelTimer() {
        if let t = timer {
            t.cancel();
            timer = nil
        }
    }
    
    func presentPopup() {
        
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let unlockDoorTipVC = storyboard.instantiateViewController(withIdentifier: "UnlockDoorTipVC") as! UnlockDoorTipVC
            self.parent?.present(unlockDoorTipVC, animated: true, completion: nil)
        }
    }
    
    func dismissPopup() {
        
        DispatchQueue.main.async {
            self.parent?.presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func handleRoomConnectionStatusChange(_ roomNumber: String, newStatus: YKSConnectionStatus) {
        
        if UnlockDoorTipPresentationController.areTipsDisabled == true {
            return
        }
        
        listOfRoomStatuses[roomNumber] = newStatus
        
        var foundActiveConnection = false
        for (_, status) in listOfRoomStatuses {
            if status == YKSConnectionStatus.connectedToDoor {
                foundActiveConnection = true
                break
            }
        }
        
        if foundActiveConnection == false {
            cancelTimer()
            dismissPopup()
            return
        }
        
        // dont create a timer again if we didnt cancel it
        if timer != nil {
            return
        }
        
        timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default))
        timer?.scheduleOneshot(deadline: DispatchTime.now() + Double(Int64(secondsToWaitWhileConnected * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), leeway: DispatchTimeInterval.seconds(0))
        timer?.setEventHandler {
            self.presentPopup()
            self.cancelTimer()
            self.timer?.resume()
        }
        
    }
}

