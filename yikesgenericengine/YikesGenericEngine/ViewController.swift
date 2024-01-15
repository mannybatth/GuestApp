//
//  ViewController.swift
//  YikesGenericEngine
//
//  Created by Roger Mabillard on 2016-10-06.
//  Copyright © 2016 Yikes. All rights reserved.
//

import UIKit

import YikesEngine
import YikesSharedModel

class ViewController: UIViewController, YikesEngineDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        YikesEngine.initEngine(with: self)
        YikesEngine.sharedEngine()?.setDebugMode(true)
        YikesEngine.sharedEngine()?.stopEngine {}
        YikesEngine.sharedEngine()?.changeCurrentApiEnv(.envDEV)
        YikesEngine.sharedEngine()?.startEngine(withUsername: "roger@yamm.ca", password: "Y@mm159!", success: { (userInfo) in
            YikesEngine.sharedEngine()?.showDebugView(in: self.view)
            }) { (error) in
                print("Error starting the engine: \(error)")
        }
        
        self.addDebugConsoleTapGR()
    }
    
    func addDebugConsoleTapGR() {
        let tapGR = UITapGestureRecognizer.init(target: self, action: #selector(showDebugConsole))
        self.view.addGestureRecognizer(tapGR)
    }
    
    func showDebugConsole() {
        YikesEngine.sharedEngine()?.showDebugView(in: self.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

