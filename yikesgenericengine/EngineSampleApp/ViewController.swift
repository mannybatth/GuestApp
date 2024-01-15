//
//  ViewController.swift
//  EngineSampleApp
//
//  Created by Roger Mabillard on 2016-05-12.
//  Copyright © 2016 Yikes. All rights reserved.
//

import UIKit
import YikesEngine

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let gr = UISwipeGestureRecognizer(target: self, action:#selector(ViewController.showDebugPanel(_:)))
        // default is right, we want up:
        gr.direction = UISwipeGestureRecognizerDirection.Up
        self.view.addGestureRecognizer(gr)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showDebugPanel(sender:UIView) {
        YikesEngine.sharedEngine()?.showDebugViewInView(self.view)
    }
}

