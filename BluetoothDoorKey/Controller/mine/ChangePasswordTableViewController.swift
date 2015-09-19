//
//  ChangePasswordTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/4.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class ChangePasswordTableViewController: UITableViewController {

    @IBOutlet weak var oldPassWord: UITextField!
    
    @IBOutlet weak var newpassWord: UITextField!
    
    @IBOutlet weak var confirmNewPassword: UITextField!
    
    @IBOutlet weak var commitButton: UIButton!
    
    @IBOutlet weak var footerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackButton()
        self.footerView.frame = CGRectMake(0, 0, kdScreenWidth, 170)
        self.setViewCornRadius(self.commitButton, cornerRadius: 4)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func commitAction(sender: UIButton) {
        KVNProgress.showWithStatus("提交密码")
        if(self.newpassWord.text != self.confirmNewPassword.text)
        {
            KVNProgress.showErrorWithStatus("新密码和确认密码输入不一致")
        }
        UserObject.sharedInstance.changepassword(self.newpassWord.text!, WitholdPassword: self.oldPassWord.text!) { (result, message) -> Void in
            if(result == true)
            {
                KVNProgress.showSuccessWithStatus(message, completion: { () -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                })
            }
            else
            {
                KVNProgress.showErrorWithStatus(message)
            }
        }
    }

}
