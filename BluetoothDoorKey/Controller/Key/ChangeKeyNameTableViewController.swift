//
//  ChangeKeyNameTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/9.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class ChangeKeyNameTableViewController: UITableViewController {
    var keyObject: KeyDbObject = KeyDbObject()
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var keyNameTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bottomView.frame = CGRectMake(0, 0, kdScreenWidth, 170)
        self.setViewCornRadius(self.changeButton, cornerRadius: 4)
        self.addBackButton()
        self.keyNameTextField.text = self.keyObject.name
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func changeNameAction(sender: UIButton) {
        self.view.endEditing(true)
        if (self.keyNameTextField.text == "")
        {
            KVNProgress.showErrorWithStatus("钥匙名称不能空")
            return
        }
        KVNProgress.showWithStatus("保存钥匙名称")
        self.keyObject.name = self.keyNameTextField.text!
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
