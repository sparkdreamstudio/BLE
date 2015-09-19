//
//  KeyDetailViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/4.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class KeyDetailViewController: UIViewController {

    var keyObject: KeyDbObject?
    
    @IBOutlet weak var nameButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var passwordButton : UIButton!
    @IBOutlet weak var expiredButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackButton()
        self.edgesForExtendedLayout = UIRectEdge.None
        self.setViewCornRadius(self.expiredButton, cornerRadius: 4)
        self.timeLabel.text = "有效期:截止\(self.keyObject!.validity)"
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.nameButton.setTitle(self.keyObject?.name, forState: UIControlState.Normal)
        if keyObject?.password != ""
        {
            let clearPassword : UIBarButtonItem = UIBarButtonItem(title: "清除密码", style: UIBarButtonItemStyle.Plain, target: self, action: "showClearController:")
            self.navigationItem.rightBarButtonItem = clearPassword
            self.passwordButton.setTitle("******", forState: UIControlState.Normal)
        }
        else
        {
            self.navigationItem.rightBarButtonItem = nil
            self.passwordButton.setTitle("设置开门密码", forState: UIControlState.Normal);
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showClearController(sender: UIBarButtonItem)
    {
        self.performSegueWithIdentifier("show_clear_password", sender: nil)
    }
    
    @IBAction func deleteKey(sender: AnyObject) {
        self.keyObject?.removeFromDb()
        KeyManager.sharedInstance.keyArray.removeObject(self.keyObject!)
        NSNotificationCenter.defaultCenter().postNotificationName(nft_keymanager_reload, object: nil)
        NSUserDefaults.standardUserDefaults().setObject(true, forKey: "DBChange");
        NSUserDefaults.standardUserDefaults().synchronize()
        KVNProgress.showSuccessWithStatus("完成", completion: { () -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        })
    }
    @IBAction func expiredAction(sender: AnyObject) {
        KVNProgress.showWithStatus("")
        AFHelpClient.sharedInstance.postHttpRequest(keyService, parameter: ["action":"extend","sessionid":UserObject.sharedInstance.sessionId,"id":self.keyObject!.__id__], success: { (operation, responseData, message) -> Void in
            KVNProgress.showSuccessWithStatus(message)
        }) { (operation, error, message) -> Void in
            KVNProgress.showErrorWithStatus(message)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "change_keyname_controller"
        {
            let changeKeyNameVC : ChangeKeyNameTableViewController = segue.destinationViewController as! ChangeKeyNameTableViewController
            changeKeyNameVC.keyObject = self.keyObject!
        }
        else if segue.identifier == "set_key_password"
        {
            let setKeyPasswordVC : KayPasswordTableViewController = segue.destinationViewController as! KayPasswordTableViewController
            setKeyPasswordVC.keyObject = self.keyObject!
        }
        else if segue.identifier == "show_clear_password"
        {
            let clearkeyPasswordVC:ClearPasswordTableViewController = segue.destinationViewController as! ClearPasswordTableViewController
            clearkeyPasswordVC.keyObject = self.keyObject!
        }
    }

}
