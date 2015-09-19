//
//  ForgetPasswordSecondTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/7/26.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class ForgetPasswordSecondTableViewController: UITableViewController {

    var userName : String?
    
    @IBOutlet weak var newPasswordTextField: UITextField!
    
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var postButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setViewCornRadius(self.postButton, cornerRadius: 4)
        self.footerView.frame = CGRectMake(0, 0, kdScreenWidth, 115)
        self.addBackButton()
        
        
        if #available(iOS 8.0, *) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
        if(self.tableView.respondsToSelector("setSeparatorInset:"))
        {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 80
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if #available(iOS 8.0, *) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        if(cell.respondsToSelector("setSeparatorInset:"))
        {
            cell.separatorInset = UIEdgeInsetsZero
        }
    }

    @IBAction func commit(sender: AnyObject) {
        if(self.newPasswordTextField.text == "")
        {
            KVNProgress.showErrorWithStatus("请输入您的新密码")
            return
        }
        if self.confirmPasswordTextField.text == ""
        {
            KVNProgress.showErrorWithStatus("请确认您的新密码")
            return
        }
        if self.confirmPasswordTextField.text != self.newPasswordTextField.text
        {
            KVNProgress.showErrorWithStatus("两次密码输入不一致")
            return
        }
        AFHelpClient.sharedInstance.postHttpRequest(memberService, parameter: ["action":"findPwdStep2","userName":self.userName!,"newPassword":self.newPasswordTextField.text!], success: { (operation, responseData, message) -> Void in
            KVNProgress.showSuccessWithStatus(message, completion: { () -> Void in
                self.navigationController?.popToRootViewControllerAnimated(true)
            })
            }, failure: { (operation, error, message) -> Void in
                KVNProgress.showErrorWithStatus(message)
        })
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
