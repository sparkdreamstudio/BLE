//
//  RegisterTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/7/26.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class RegisterTableViewController: UITableViewController {

    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordNameTextField: UITextField!
    @IBOutlet weak var confirmCodeTextField: UITextField!
    @IBOutlet weak var confirmCodeButton: JKCountDownButton!
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var footerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()


        
        self.setViewCornRadius(self.confirmCodeButton, cornerRadius: 4)
        self.setViewCornRadius(self.registerButton, cornerRadius: 4)
        self.footerView.frame = CGRectMake(0, 0, kdScreenWidth, 170)
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

    @IBAction func buttonClick(sender: UIButton) {
        switch sender.tag
        {
        case 1:
            
            var jkButton : JKCountDownButton = sender as! JKCountDownButton
            jkButton.enabled = false
            jkButton.startWithSecond(60)
            jkButton.didChange({ (btn, second) -> String! in
                return "(\(second))"
            })
            jkButton.didFinished({ (btn, second) -> String! in
                jkButton.enabled = false
                return "点击重新获取"
            })
            KVNProgress.showWithStatus("获取验证码中")
            AFHelpClient.sharedInstance.postHttpRequest(smsService, parameter: ["action":"send","userName":self.userNameTextField.text!,"type":1], success: { (operation, responseData, message) -> Void in
                KVNProgress.showSuccessWithStatus(message)
            }, failure: { (operation, error, message) -> Void in
                KVNProgress.showErrorWithStatus(message)
            })
            
        case 2:
            KVNProgress.showWithStatus("注册中")
            AFHelpClient.sharedInstance.postHttpRequest(memberService, parameter: ["action":"reg","userName":self.userNameTextField.text!,"password":self.passwordNameTextField.text!,"code":self.confirmCodeTextField.text!], success: { (operation, responseData, message) -> Void in
                KVNProgress.showSuccessWithStatus(message, completion: { () -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                })
            }, failure: { (operation, error, message) -> Void in
                KVNProgress.showErrorWithStatus(message)
            })
        case 3:
            self.navigationController?.popViewControllerAnimated(true)
        default:
            break;
        }
    }
    
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



    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
