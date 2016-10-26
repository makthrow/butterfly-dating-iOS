//
//  ChatUserCell.swift
//  butterfly2
//
//  Created by Alan Jaw on 9/15/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import Foundation

class ChatUserCell: UITableViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        avatarImageView.layer.cornerRadius = avatarImageView.frame.height / 2
        avatarImageView.layer.masksToBounds = true // image doesn't exceed size of image view
        
    }
    
}
