//
//  AddFamilyNumberTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/10.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class AddFamilyNumberTableViewController: UITableViewController {

    @IBOutlet weak var familyMemberName: UITextField!
    @IBOutlet weak var familyMemberMobile: UITextField!
    
    @IBOutlet weak var commitButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        if(self.tableView.respondsToSelector("setLayoutMargins:"))
        {
            if #available(iOS 8.0, *) {
                self.tableView.layoutMargins = UIEdgeInsetsZero
            } else {
                // Fallback on earlier versions
            }
        }
        if(self.tableView.respondsToSelector("setSeparatorInset:"))
        {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        self.edgesForExtendedLayout = UIRectEdge.None
        
        self.bottomView.frame = CGRectMake(0, 0, kdScreenWidth, 170)
        self.setViewCornRadius(self.commitButton, cornerRadius: 4)
        self.addBackButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func commitMemberAction(sender: UIButton) {
        AFHelpClient.sharedInstance.postHttpRequest(familyService, parameter: ["action":"save","sessionid":UserObject.sharedInstance.sessionId,"name":self.familyMemberName.text!,"tel":self.familyMemberMobile.text!], success: { (operation, responseData, message) -> Void in
            KVNProgress.showSuccessWithStatus(message, completion: { () -> Void in
                self.navigationController?.popViewControllerAnimated(true)
            })
            }) { (operation, error, message) -> Void in
            KVNProgress.showErrorWithStatus(message)
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
