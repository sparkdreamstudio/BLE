//
//  WebViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/9.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class WebViewController: UIViewController,UIWebViewDelegate {
    
    var adDic : NSDictionary?
    
    @IBOutlet weak var webView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackButton()
        self.title = self.adDic?.objectForKey("title") as? String
        self.webView.loadHTMLString(self.adDic?.objectForKey("intro") as! String, baseURL: nil)
        // Do any additional setup after loading the view.
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
