//
//  AccountDetailsCell.swift
//  YikesGuestApp
//
//  Created by Manny Singh on 2/29/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit

protocol AccountDetailsCellDelegate: class {
    func accountDetailsDidBeginEditing(_ cell: AccountDetailsCell)
    func accountDetailsDidEndEditing(_ cell: AccountDetailsCell)
    func accountDetailsCellHeightChanged()
}

class AccountDetailsCell: UITableViewCell {

    weak var delegate: AccountDetailsCellDelegate?
    
    @IBOutlet weak var textView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

extension AccountDetailsCell: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.delegate?.accountDetailsDidBeginEditing(self)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.delegate?.accountDetailsDidEndEditing(self)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.delegate?.accountDetailsCellHeightChanged()
    }
    
}
