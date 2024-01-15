//
//  ViewController.swift
//  YikesGuestAppSample
//
//  Created by Manny Singh on 11/20/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import UIKit
import YikesEngine
import CoreLocation

class ViewController: UIViewController {
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestAlwaysAuthorization()
        
        if let user = YikesEngine.sharedEngine()?.userInfo {
            
            print(user)
            
        } else {
            
            YikesEngine.sharedEngine()?.startEngineWithUsername(
                "manny.singh@yikes.co",
                password: "qwe123",
                success: { (user) -> Void in
                    
                    print(user)
                    
                }, failure: { (error) -> Void in
                    
                    
                    
            })
            
        }
        
    }
    
    @IBAction func showDebugConsoleButtonTouched(sender: AnyObject) {
        
        YikesEngine.sharedEngine()?.setDebugMode(true)
        YikesEngine.sharedEngine()?.showDebugViewInView(self.view)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
