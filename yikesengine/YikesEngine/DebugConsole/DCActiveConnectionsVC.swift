//
//  DCActiveConnectionsVC.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/8/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

class DCActiveConnectionsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DebugManager.sharedInstance.activeConnectionsVCReference = self
        
        self.tableView.reloadData()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DebugManager.sharedInstance.activeConnectionsVCReference = nil
    }
    
    func insertConnection(_ atIndex: Int) {
        
        let indexPath = IndexPath(row: atIndex, section: 0)
        
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [indexPath], with: .none)
        self.tableView.endUpdates()
        
        self.scrollToBottom()
    }
    
    func updateConnection(_ atIndex: Int) {
        
        let indexPath = IndexPath(row: atIndex, section: 0)
        
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: [indexPath], with: .none)
        self.tableView.endUpdates()
    }
    
    func deleteConnection(_ atIndex: Int) {
        
        let indexPath = IndexPath(row: atIndex, section: 0)
        
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: [indexPath], with: .none)
        self.tableView.endUpdates()
    }
    
    func scrollToBottom() {
        
        let numberOfRows = self.tableView.numberOfRows(inSection: 0)
        if numberOfRows > 0 {
            let indexPath = IndexPath(row: numberOfRows-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    // MARK: UITableViewDataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DebugManager.sharedInstance.activeConnections.count
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 18
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActiveConnectionTVC") as! ActiveConnectionTVC
        
        cell.connection = DebugManager.sharedInstance.activeConnections[(indexPath as NSIndexPath).row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let connection: BLEConnection = DebugManager.sharedInstance.activeConnections[(indexPath as NSIndexPath).row]
        if BLEEngine.sharedInstance.isYLinkConnected(connection.yLink) {
            BLEEngine.sharedInstance.disconnectYLink(connection.yLink, reason: .userForcedDisconnect)
        }
    }
    
}
