//
//  KayPasswordTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/9.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class KayPasswordTableViewController: UITableViewController {
    var keyObject: KeyDbObject = KeyDbObject()
    @IBOutlet weak var text1:UITextField!
    @IBOutlet weak var text2:UITextField!
    @IBOutlet weak var text3:UITextField!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.bottomView.frame = CGRectMake(0, 0, kdScreenWidth, 170)
        self.setViewCornRadius(self.changeButton, cornerRadius: 4)
        self.addBackButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func changePasswordAction(sender: UIButton) {
        self.view.endEditing(true)
        if (keyObject.password != "" && keyObject.password != self.text1.text)
        {
            KVNProgress.showErrorWithStatus("旧密码错误")
            return
        }
        if (self.text2.text == "")
        {
            KVNProgress.showErrorWithStatus("新密码不能为空")
            return
        }
        if (self.text3.text == "")
        {
            KVNProgress.showErrorWithStatus("请确认新密码")
            return
        }
        if self.text3.text != self.text2.text
        {
            KVNProgress.showErrorWithStatus("两次密码输入不一致")
            return
        }
        KVNProgress.showWithStatus("保存钥匙密码")
        self.keyObject.password = self.text2.text!
        dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
            self.keyObject.updatetoDb()
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: "DBChange");
            NSUserDefaults.standardUserDefaults().synchronize()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                KVNProgress.showSuccessWithStatus("完成", completion: { () -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                })
            })
        })

    }
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
