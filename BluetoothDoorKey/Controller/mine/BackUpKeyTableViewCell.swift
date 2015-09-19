//
//  BackUpKeyTableViewCell.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/23.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit


protocol BackUpKeyTableViewCellDelegate
{
    func backUpKeyTableViewCell(cell:BackUpKeyTableViewCell,ButtonClick button:UIButton)
}
class BackUpKeyTableViewCell: UITableViewCell {
    var delegate : BackUpKeyTableViewCellDelegate?
    @IBOutlet weak var button:UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.button.layer.masksToBounds = true
        self.button.layer.cornerRadius = 4
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func buttonClick(sender: UIButton) {
        self.delegate!.backUpKeyTableViewCell(self, ButtonClick: sender)
    }
}
