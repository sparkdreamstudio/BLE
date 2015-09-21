
//
//  KeyTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/3.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit
import AVFoundation

class KeyTableViewController: UITableViewController,KeyOpenTableViewCellDelegate,BLEDelegate {

    var openKey :KeyDbObject?
    var openPassWord = "";
    var scanTimer : NSTimer?
    var player:AVAudioPlayer?
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = NSBundle.mainBundle().URLForResource("dd", withExtension: "mp3")
        var error:NSError? = nil
        do {
            self.player = try AVAudioPlayer(contentsOfURL: url!)
        } catch let error1 as NSError {
            error = error1
            self.player = nil
        }
        self.player!.prepareToPlay()
        
        if #available(iOS 8.0, *) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
        if(self.tableView.respondsToSelector("setSeparatorInset:"))
        {
            self.tableView.separatorInset = UIEdgeInsetsMake(0, kdScreenWidth, 0, 0)
        }
        self.edgesForExtendedLayout = UIRectEdge.None
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processNtf:", name: ntf_serverdate_refresh, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        let tabBarController = (UIApplication.sharedApplication().delegate as! AppDelegate).tabBarController
        tabBarController?.tabBarHidden = false;
        self.tableView.reloadData()
        KeyManager.sharedInstance.sensor.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func processNtf(ntf:NSNotification)
    {
        if ntf.name == ntf_serverdate_refresh
        {
            self.tableView.reloadData()
        }
        else if ntf.name == nft_keymanager_reload
        {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - BLE delegate
    func peripheralFound(peripheral: CBPeripheral!, periphernalMac mac: String!) {
        let lowerMacString = NSString(string: mac).lowercaseString
        let keyData : NSData = KeyManager.descrpytKey(self.openKey!.dataPackage, WithPassword: self.openKey!.userName)
        let decryptedString : NSString = NSString(data: keyData, encoding: NSUTF8StringEncoding)!.lowercaseString
        if(lowerMacString == decryptedString)
        {
            if self.scanTimer != nil
            {
                self.scanTimer?.invalidate()
            }
            KeyManager.sharedInstance.sensor.stopScan()
            if (self.openKey!.password != "")
            {
                KVNProgress.dismiss()
                let alertView : SCLAlertView = SCLAlertView(newWindow: ())
                let textField : UITextField = alertView.addTextField("输入开门密码");
                var button : SCLButton = alertView.addButton("开门", actionBlock: { () -> Void in
                    if(self.openKey!.password == textField.text)
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
                AFHelpClient.sharedInstance.postHttpRequest(messageService, parameter: ["action":"save","sessionid":UserObject.sharedInstance.sessionId,"content":self.openKey!.name,"keyId":self.openKey!.__id__], success: { (operation, responseData, message) -> Void in
                    
                    }, failure: { (operation, error, message) -> Void in
                        
                })
            })
        })
    }
    
    func setDisconnect() {
        KVNProgress.showErrorWithStatus("连接设备失败")
    }
    
    func scanTimer(timer:NSTimer)
    {
        KVNProgress.showErrorWithStatus("未找到设备")
    }
    // MARK: - Table view data source

    @IBAction func downloadKey(sender: UIBarButtonItem) {
        KVNProgress.showWithStatus("下载钥匙")
        KeyManager.sharedInstance.downloadKeys({ (message) -> Void in
            KVNProgress.showSuccessWithStatus(message)
            self.tableView.reloadData()
        }, failure: { (error, message) -> Void in
            KVNProgress.showErrorWithStatus(message)
        })
        
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return KeyManager.sharedInstance.keyArray.count
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 71
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let key:KeyDbObject = KeyManager.sharedInstance.keyArray.objectAtIndex(indexPath.row) as!KeyDbObject
        var cell : KeyOpenTableViewCell? = nil
        if (key.isExpire(KeyManager.sharedInstance.serverDate))
        {
            cell = tableView.dequeueReusableCellWithIdentifier("cell1", forIndexPath: indexPath) as? KeyOpenTableViewCell
        }
        else
        {
            cell = tableView.dequeueReusableCellWithIdentifier("cell0", forIndexPath: indexPath) as? KeyOpenTableViewCell
            cell?.delegate = self
        }
        var label : UILabel = cell?.viewWithTag(1) as! UILabel
        label.text = key.name
        label = cell?.viewWithTag(2) as! UILabel
        label.text = "有效期截止\(key.validity)"

        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("key_detail_segue", sender: KeyManager.sharedInstance.keyArray.objectAtIndex(indexPath.row))
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if #available(iOS 8.0, *) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        if(cell.respondsToSelector("setSeparatorInset:"))
        {
            cell.separatorInset = UIEdgeInsetsMake(0, 12, 0, 12)
        }
    }

    func keyOpenTableViewCell(cell: KeyOpenTableViewCell, ButtonClick button: UIButton) {
        let indexPath : NSIndexPath = self.tableView.indexPathForCell(cell)!
        self.openKey = KeyManager.sharedInstance.keyArray.objectAtIndex(indexPath.row) as? KeyDbObject
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
    
    


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let tabBarController = (UIApplication.sharedApplication().delegate as! AppDelegate).tabBarController
        tabBarController?.tabBarHidden = true;
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        if segue.identifier == "key_detail_segue"
        {
            let keyDetailVC : KeyDetailViewController = segue.destinationViewController as! KeyDetailViewController
            keyDetailVC.keyObject = sender as? KeyDbObject
        }
    }


}
