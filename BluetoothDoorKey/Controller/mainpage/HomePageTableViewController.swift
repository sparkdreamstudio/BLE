//
//  HomePageTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/7/12.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit
import AVFoundation

class HomePageTableViewController: UITableViewController,BLEDelegate,OpenDoorTableViewCellDelegate,ImagePlayerViewDelegate,YQZCubeAnimationViewDelegate {

    
    var player:AVAudioPlayer?
    var select : Int = -1
    var openPassWord = "";
    var openKeyObject : KeyDbObject?
    var adArray : NSArray = NSArray()
    var textAdArray : NSArray = NSArray()
    var scanTimer : NSTimer?
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.sensor = BLE();
//        self.sensor?.delegate = self
//        self.sensor?.setup()
        let url = NSBundle.mainBundle().URLForResource("dd", withExtension: "mp3")
        var error:NSError? = nil
        do {
            self.player = try AVAudioPlayer(contentsOfURL: url!)
        } catch let error1 as NSError {
            error = error1
            self.player = nil
        }
        self.player!.prepareToPlay()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processNtf:", name: ntf_log_in, object: nil)
//        self.reloadAd()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.addMotionRecognizerWithAction("shakeAction:")
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        let tabBarController = (UIApplication.sharedApplication().delegate as! AppDelegate).tabBarController
        tabBarController?.tabBarHidden = false;
        KeyManager.sharedInstance.sensor.delegate = self
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeMotionRecognizer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func processNtf(ntf:NSNotification)
    {
        if ntf.name == ntf_log_in
        {
            self.reloadAd()
        }
    }
    
    func reloadAd()
    {
        AFHelpClient.sharedInstance.postHttpRequest(newsService, parameter: ["action":"list","currentPageNo":1,"pageSize":3,"type":1,"sessionid":UserObject.sharedInstance.sessionId], success: { (operation, responseData, message) -> Void in
            self.adArray = responseData as! NSArray
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
            }) { (operation, error, message) -> Void in
                
        }
        
        AFHelpClient.sharedInstance.postHttpRequest(newsService, parameter: ["action":"list","currentPageNo":1,"pageSize":3,"type":2,"sessionid":UserObject.sharedInstance.sessionId], success: { (operation, responseData, message) -> Void in
            self.textAdArray = responseData as! NSArray
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
            }) { (operation, error, message) -> Void in
                
        }
    }
    
    func shakeAction(ntf:NSNotification)
    {
        NSLog("shake")
        self.shakeOpenDoor()
    }
    
    func scanTimer(timer:NSTimer)
    {
        KVNProgress.showErrorWithStatus("未找到设备")
    }
    
    @IBAction func shakeButtonClick(sender: UIButton) {
        Utility.shakeView(sender)
        self.shakeOpenDoor()
    }
    
    func shakeOpenDoor()
    {
        AudioServicesPlaySystemSound(UInt32(kSystemSoundID_Vibrate))
        if KeyManager.sharedInstance.keyArray.count == 0
        {
            KVNProgress.showErrorWithStatus("没有钥匙")
            return
        }
        self.scanTimer =  NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "scanTimer:", userInfo: nil, repeats: false)
        if(KeyManager.sharedInstance.sensor.activePeripheral != nil)
        {
            if(KeyManager.sharedInstance.sensor.activePeripheral.state == CBPeripheralState.Connected)
            {
                KeyManager.sharedInstance.sensor.disconnect(KeyManager.sharedInstance.sensor.activePeripheral)
                KeyManager.sharedInstance.sensor.activePeripheral = nil
            }
        }
        if (KeyManager.sharedInstance.sensor.peripherals != nil)
        {
            KeyManager.sharedInstance.sensor.peripherals = nil
        }
        KeyManager.sharedInstance.sensor.delegate = self
        KVNProgress.showWithStatus("寻找设备中")
        KeyManager.sharedInstance.sensor.findBLEPeripherals(5)
        
    }
    
    
    func openDoorCell(cell:OpenDoorTableViewCell,ButtonClick button:UIButton)
    {
        let indexPath = self.tableView.indexPathForCell(cell)
        self.select = indexPath!.row
        self.shakeOpenDoor()
    }
    
    // MARK: - BLE delegate
    func peripheralFound(peripheral: CBPeripheral!, periphernalMac mac: String!) {
//        var alertView : UIAlertView = UIAlertView(title: "提示", message: "发现设备地址：\(mac)", delegate: nil, cancelButtonTitle: "知道了")
//        alertView.show()
        let lowerMacString = NSString(string: mac).lowercaseString
        for index in 0...KeyManager.sharedInstance.keyArray.count-1
        {
            let keyObject : KeyDbObject = KeyManager.sharedInstance.keyArray.objectAtIndex(index) as! KeyDbObject
            let keyData : NSData = KeyManager.descrpytKey(keyObject.dataPackage, WithPassword: keyObject.userName)
            let decryptedString = NSString(data: keyData, encoding: NSUTF8StringEncoding)!.lowercaseString
            
            if(lowerMacString == decryptedString)
            {
                if self.scanTimer != nil
                {
                    self.scanTimer?.invalidate()
                }
                KeyManager.sharedInstance.sensor.stopScan()
                self.openKeyObject = keyObject
                if (keyObject.isExpire(KeyManager.sharedInstance.serverDate)==false)
                {
                    if (keyObject.password != "")
                    {
                        KVNProgress.dismiss()
                        let alertView : SCLAlertView = SCLAlertView(newWindow: ())
                        let textField : UITextField = alertView.addTextField("输入开门密码");
                        var button : SCLButton = alertView.addButton("开门", actionBlock: { () -> Void in
                            if(keyObject.password == textField.text)
                            {
                                self.connectBLE(peripheral)
                            }
                            else
                            {
                                KVNProgress.showErrorWithStatus("密码错误")
                            }
                        })
                        button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                        button = alertView.addButton("取消", actionBlock: { () -> Void in
                            alertView.hideView()
                        })
                        button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                        alertView.showCustom(SCLAlertViewStyleKit.imageOfWarning(), color: UIColor(red: 0x0b/255, green: 0xd5/255, blue: 0xb6/255, alpha: 1), title: "需要开门密码", subTitle: nil, closeButtonTitle: nil, duration: 0)
                    }
                    else
                    {
                        self.connectBLE(peripheral)
                    }
                }
                else
                {
                    KVNProgress.showErrorWithStatus("钥匙过期")
                }
                return;
            }
            
        }
    }
    
    func connectBLE(peripheral: CBPeripheral!)
    {
        KVNProgress.showWithStatus("连接设备")
        if KeyManager.sharedInstance.sensor.activePeripheral != nil
        {
            KeyManager.sharedInstance.sensor.disconnect(KeyManager.sharedInstance.sensor.activePeripheral)
        }
        KeyManager.sharedInstance.sensor.activePeripheral = peripheral
        KeyManager.sharedInstance.sensor.connect(KeyManager.sharedInstance.sensor.activePeripheral)
    }
    
    func setConnect() {
        dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
            KeyManager.sharedInstance.sensor.write(KeyManager.sharedInstance.sensor.activePeripheral, data: Utility.parseHexToByteArray("C502345604AA"))
            KeyManager.sharedInstance.sensor.disconnect(KeyManager.sharedInstance.sensor.activePeripheral)
            KeyManager.sharedInstance.sensor.activePeripheral = nil
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.player!.play()
                KVNProgress.showSuccessWithStatus("开门成功")
                AFHelpClient.sharedInstance.postHttpRequest(messageService, parameter: ["action":"save","sessionid":UserObject.sharedInstance.sessionId,"content":self.openKeyObject!.name,"keyId":self.openKeyObject!.__id__], success: { (operation, responseData, message) -> Void in
                    
                    }, failure: { (operation, error, message) -> Void in
                        
                })
            })
        })
    }
    
    func setDisconnect() {
        KVNProgress.showErrorWithStatus("连接设备失败")
    }
    
    // MARK: - cubedelegate
    func cubeAnimationViewDelegateClick(index: Int) {
        self.performSegueWithIdentifier("show_webView_controller", sender: self.textAdArray.objectAtIndex(index))
    }
    
    // MARK: - image playerView delegate
    func numberOfItems() -> Int {
       return self.adArray.count
    }
    
    func imagePlayerView(imagePlayerView: ImagePlayerView!, loadImageForImageView imageView: UIImageView!, index: Int) {
        let dic : NSDictionary = self.adArray.objectAtIndex(index) as! NSDictionary
        imageView.setImageWithURL(NSURL(string: dic.objectForKey("img") as! String))
    }
    
    func imagePlayerView(imagePlayerView: ImagePlayerView!, didTapAtIndex index: Int) {
        self.performSegueWithIdentifier("show_webView_controller", sender: self.adArray.objectAtIndex(index))
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if(section == 0)
        {
            return 1
        }
        else
        {
            
            return 1
        }
    }

    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if(indexPath.section == 0)
        {

            return kdScreenWidth*0.389+53;
            
        }
        else
        {
            return kdScreenWidth
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if(indexPath.section == 0)
        {
            let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("cell0", forIndexPath: indexPath) ;
            cell.separatorInset = UIEdgeInsetsZero
            var textAdView : YQZCubeAnimationView
            if cell.viewWithTag(9999) == nil
            {
                textAdView = YQZCubeAnimationView(frame: CGRectMake(43, kdScreenWidth*0.389+18, kdScreenWidth-56, 16))
                textAdView.tag = 9999
                textAdView.delegate = self;
                cell.contentView.addSubview(textAdView)
//                let view = cell.viewWithTag(9999)
//                view?.removeFromSuperview()
            }
            else
            {
                textAdView = cell.viewWithTag(9999) as! YQZCubeAnimationView
            }

//            let textAdView : YQZCubeAnimationView = YQZCubeAnimationView(frame: CGRectMake(43, kdScreenWidth*0.389+18, kdScreenWidth-56, 16))
            
            let stringArray : NSMutableArray = NSMutableArray()
            if self.textAdArray.count > 0
            {
                for index in 0...self.textAdArray.count-1
                {
                    let string : String = (self.textAdArray.objectAtIndex(index) as! NSDictionary).objectForKey("title") as! String
                    stringArray.addObject("通知:\(string)")
                }
            }
            textAdView.loadData(stringArray)
            

            
            let adView : ImagePlayerView
            if cell.viewWithTag(9998) == nil
            {
                adView = ImagePlayerView()
                adView.backgroundColor = UIColor(red: 0xcd/255, green: 0xcd/255, blue: 0xcd/255, alpha: 1)
                adView.tag = 9998
                adView.imagePlayerViewDelegate = self
                adView.frame = CGRectMake(0, 0, kdScreenWidth, kdScreenWidth*0.389)
                cell.contentView.addSubview(adView)
            }
            else
            {
                adView = cell.viewWithTag(9998) as! ImagePlayerView
            }
            
            adView.reloadData()
            
            return cell
        }
        else
        {
//            var keyobject : KeyDbObject = KeyManager.sharedInstance.keyArray.objectAtIndex(indexPath.row) as! KeyDbObject
            let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("cell2", forIndexPath: indexPath) ;
            let button : UIButton = cell.viewWithTag(1) as! UIButton
            button.addTarget(self, action: "shakeButtonClick:", forControlEvents: UIControlEvents.TouchUpInside)
            return cell
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let tabBarController = (UIApplication.sharedApplication().delegate as! AppDelegate).tabBarController
        tabBarController?.tabBarHidden = true;
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        if segue.identifier == "show_webView_controller"
        {
            let webView : WebViewController = segue.destinationViewController as! WebViewController
            webView.adDic = sender as? NSDictionary
        }
    }

}
