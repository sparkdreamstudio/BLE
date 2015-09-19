//
//  MessageDetailViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/20.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class MessageDetailViewController: UIViewController {
    var dic:NSDictionary?
    @IBOutlet weak var timeLabel : UILabel!
    @IBOutlet weak var textLabel : UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackButton()
        timeLabel.text = dic?.objectForKey("createTime") as? String
        textLabel.text = dic?.objectForKey("content") as? String
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func deleteMessageClick(sender:UIBarButtonItem)
    {
        KVNProgress.showWithStatus("删除消息")
        AFHelpClient.sharedInstance.postHttpRequest(messageService, parameter: ["action":"delete","sessionid":UserObject.sharedInstance.sessionId,"id":self.dic!.objectForKey("id")!], success: { (operation, responseData, message) -> Void in
            KVNProgress.showSuccessWithStatus(message, completion: { () -> Void in
                self.navigationController?.popViewControllerAnimated(true)
                NSNotificationCenter.defaultCenter().postNotificationName(ntf_delete_message, object: self.dic)
            })
        }) { (operation, error, message) -> Void in
            KVNProgress.showErrorWithStatus(message)
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
