//
//  FeedBackViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/3.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class FeedBackViewController: UIViewController {

    @IBOutlet weak var textView: PlaceholderTextView!
    @IBOutlet weak var feedBackButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackButton()
        self.edgesForExtendedLayout = UIRectEdge.None
        self.textView.layer.masksToBounds = true
        self.textView.layer.borderColor = UIColor(red: 0xcd/255, green: 0xcd/255, blue: 0xcd/255, alpha: 1).CGColor
        self.textView.layer.borderWidth = 1
        self.setViewCornRadius(self.feedBackButton, cornerRadius: 4)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func feedBackClick(sender: UIButton) {
        
        KVNProgress.showWithStatus("提交反馈中", onView: self.view)
        AFHelpClient.sharedInstance.postHttpRequest(feedbackService, parameter: ["action":"save","sessionid":UserObject.sharedInstance.sessionId,"content":self.textView.text], success: { (operation, responseData, message) -> Void in
            KVNProgress.showSuccessWithStatus(message, onView: self.view, completion: { () -> Void in
                self.navigationController?.popViewControllerAnimated(true)
            })
        }) { (operation, error, message) -> Void in
            KVNProgress.showErrorWithStatus(message, onView: self.view)
        }
    }

    

}
