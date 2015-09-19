//
//  OpenDoorTableViewCell.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/9.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

protocol OpenDoorTableViewCellDelegate
{
    func openDoorCell(cell:OpenDoorTableViewCell,ButtonClick button:UIButton)
}

class OpenDoorTableViewCell: UITableViewCell {

    var delegate : OpenDoorTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func openDoorClick(sender: UIButton) {
        self.delegate?.openDoorCell(self, ButtonClick: sender)
    }

}
