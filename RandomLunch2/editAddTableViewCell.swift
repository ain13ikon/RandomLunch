//
//  editAddTableViewCell.swift
//  RandomLunch2
//
//  Created by きたむら on 2018/10/16.
//  Copyright © 2018年 ain13ikon. All rights reserved.
//

import UIKit

class editAddTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var addButton: UIButton!
    
    @IBAction func tapAddButton(_ sender: Any) {
        print(#function)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
