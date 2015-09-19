//
//  AboutViewController.swift
//  BluetoothDoorKey
//
//  Created by 李响 on 15/8/25.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var webView:UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.addBackButton()
        self.edgesForExtendedLayout = UIRectEdge.None
        AFHelpClient.sharedInstance.postHttpRequest(otherService, parameter: ["action":"detail","type":"1"], success: { (operation, responseData, message) -> Void in
            self.webView.loadHTMLString(responseData.objectForKey("intro") as! String, baseURL: NSURL())
        }) { (operation, error, message) -> Void in
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
