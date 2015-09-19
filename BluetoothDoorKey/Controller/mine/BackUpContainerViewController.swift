//
//  BackUpContainerViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/25.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class BackUpContainerViewController: UIViewController {

    @IBOutlet weak var backUpBtn:UIButton!
    var keyTableVC:BackUpTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.addBackButton()
        self.setViewCornRadius(self.backUpBtn, cornerRadius: 4)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backKey(sender: AnyObject)
    {
        if(NSUserDefaults.standardUserDefaults().objectForKey("DBChange") == nil)
        {
            KVNProgress.showErrorWithStatus("不需要备份")
            return;
        }
        if(NSUserDefaults.standardUserDefaults().objectForKey("DBChange")as!Bool == false)
        {
            KVNProgress.showErrorWithStatus("不需要备份")
            return;
        }
        NSUserDefaults.standardUserDefaults().setObject(false, forKey: "DBChange");
        NSUserDefaults.standardUserDefaults().synchronize()
        KVNProgress.showWithStatus("备份钥匙中")
        dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
            if(KeyManager.sharedInstance.backUpKeyObject() == true)
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.keyTableVC?.reloadKey()
                    KVNProgress.showSuccessWithStatus("完成")
                })
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    KVNProgress.showErrorWithStatus("备份失败")
                })
            }
        })
    }

 
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "embbed_backUpKey_controller"
        {
            self.keyTableVC = segue.destinationViewController as? BackUpTableViewController
        }
    }


}
