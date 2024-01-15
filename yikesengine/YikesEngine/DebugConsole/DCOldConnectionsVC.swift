//
//  DCOldConnectionsVC.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/8/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

class DCOldConnectionsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    var lastContentOffset : CGFloat = 0
    var isAutoScrollEnabled : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DebugManager.sharedInstance.oldConnectionsVCReference = self
        isAutoScrollEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DebugManager.sharedInstance.oldConnectionsVCReference = nil
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
        if (!isAutoScrollEnabled) { return }
        
        let numberOfRows = self.tableView.numberOfRows(inSection: 0)
        if numberOfRows > 0 {
            let indexPath = IndexPath(row: numberOfRows-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    // MARK: UIScrollViewDelegate methods
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (lastContentOffset > scrollView.contentOffset.y + 30) {
            
            // scrolling up
            isAutoScrollEnabled = false
        }
        
        lastContentOffset = scrollView.contentOffset.y
    }
    
    // MARK: UITableViewDataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DebugManager.sharedInstance.oldConnections.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 18
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "OldConnectionTVC") as! OldConnectionTVC
        
        cell.connection = DebugManager.sharedInstance.oldConnections[(indexPath as NSIndexPath).row]
        
        return cell
        
    }
}
