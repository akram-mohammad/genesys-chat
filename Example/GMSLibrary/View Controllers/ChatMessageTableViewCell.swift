//
// ChatMessageTableViewCell.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-23
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import UIKit

class ChatMessageTableViewCell : UITableViewCell {
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
}

extension UILabel {
    var optimalHeight : CGFloat
    {
        get
        {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: CGFloat.greatestFiniteMagnitude))
            label.numberOfLines = 0
            label.lineBreakMode = self.lineBreakMode
            label.font = self.font
            label.text = self.text
            label.sizeToFit()
            return label.frame.height
        }
    }
}
