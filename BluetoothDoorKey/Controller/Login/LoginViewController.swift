//
//  LoginViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/7/26.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var userNameBackView: UIView!
    @IBOutlet weak var passWordBackView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var userNameLabel: UITextField!
    @IBOutlet weak var passWordLabel: UITextField!
    
    @IBOutlet weak var seperatorConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var toTopConstraint: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if kdScreenHeight == 568
        {
            self.seperatorConstraint.constant = -50
        }
        self.toTopConstraint.constant = kdScreenHeight-38
        self.setViewCornRadius(self.userNameBackView, cornerRadius: 4);
        self.setViewCornRadius(self.passWordBackView, cornerRadius: 4);
        self.setViewCornRadius(self.loginButton, cornerRadius: 4);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        var name: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey("UserName")
        var pwd: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey("PassWord")
        if(name == nil || pwd == nil)
        {
            return
        }
        self.userNameLabel.text = name as! String
        self.passWordLabel.text = pwd  as! String
        self.LogIn(UIButton())
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @IBAction func LogIn(sender: UIButton) {
        KVNProgress.showWithStatus("登录中")
        self.view.endEditing(true)
        UserObject.sharedInstance.logInWith(self.userNameLabel.text!, password: self.passWordLabel.text!) { (result, message) -> Void in
            if result == true
            {
                KVNProgress.showSuccessWithStatus(message, completion: { () -> Void in
                    self.navigationController?.dismissViewControllerAnimated(true, completion: { () -> Void in
                        
                    })
                })
            }
            else
            {
                KVNProgress.showErrorWithStatus(message)
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
