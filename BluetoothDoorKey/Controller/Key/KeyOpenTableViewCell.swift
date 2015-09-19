//
//  KeyOpenTableViewCell.swift
//  BluetoothDoorKey
//
//  Created by 李响 on 15/8/19.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

protocol KeyOpenTableViewCellDelegate
{
    func keyOpenTableViewCell(cell:KeyOpenTableViewCell,ButtonClick button:UIButton)
}

class KeyOpenTableViewCell: UITableViewCell {

    var delegate : KeyOpenTableViewCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func buttonClick(sender: UIButton) {
        self.delegate!.keyOpenTableViewCell(self, ButtonClick: sender)
    }
}
