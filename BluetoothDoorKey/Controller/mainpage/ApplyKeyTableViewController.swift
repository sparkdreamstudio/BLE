//
//  ApplyKeyTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/7/12.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class ApplyKeyTableViewController: UITableViewController {

    
    @IBOutlet weak var applyName: UITextField!
    @IBOutlet weak var mobile: UITextField!
    @IBOutlet weak var district: UITextField!
    @IBOutlet weak var otherInfo: UITextField!
    
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var bottomView:UIView!
    @IBOutlet weak var submitButtonWidth:NSLayoutConstraint!
    
    var districtInfo : NSDictionary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackButton()
        self.title = "申请钥匙"
        self.bottomView.frame = CGRectMake(0, 0, kdScreenWidth, 166)
//        self.bottomView.addConstraint(NSLayoutConstraint(item: self.submitButton, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.bottomView, attribute: NSLayoutAttribute.Width, multiplier: 0.71, constant: 0))
        self.submitButtonWidth.constant = kdScreenWidth*0.71
        self.submitButton.layer.masksToBounds = true
        self.submitButton.layer.cornerRadius = 4
        
        
        if #available(iOS 8.0, *) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
        if(self.tableView.respondsToSelector("setSeparatorInset:"))
        {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processNtf:", name: ntf_select_district, object: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func processNtf(ntf:NSNotification)
    {
        if ntf.name == ntf_select_district
        {
            var userInfo : Dictionary<String,NSDictionary!> = ntf.userInfo as! Dictionary<String,NSDictionary!>
            self.districtInfo = userInfo["district"]
            self.district.text = self.districtInfo?.objectForKey("name") as! String
        }
    }
    
    @IBAction func commit(sender: UIButton) {
        KVNProgress.showWithStatus("提交中")
        var cellId: AnyObject! = self.districtInfo?.objectForKey("id")
        if(cellId == nil)
        {
            KVNProgress.showErrorWithStatus("请先选择小区")
            return;
        }
        AFHelpClient.sharedInstance.postHttpRequest(applyService, parameter: ["action":"save","sessionid":UserObject.sharedInstance.sessionId,"name":self.applyName.text!,"tel":self.mobile.text!,"cellId":cellId,"floor":self.otherInfo.text!], success: { (operation, responseData, message) -> Void in
            KVNProgress.showSuccessWithStatus(message, completion: { () -> Void in
                self.navigationController?.popViewControllerAnimated(true)
            })
        }) { (operation, error, message) -> Void in
            KVNProgress.showErrorWithStatus(message)
        }
    }
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if #available(iOS 8.0, *) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        if(cell.respondsToSelector("setSeparatorInset:"))
        {
            cell.separatorInset = UIEdgeInsetsZero
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row
        {
        case 0:
            self.applyName.becomeFirstResponder()
        case 1:
            self.mobile.becomeFirstResponder()
        case 3:
            self.otherInfo.becomeFirstResponder()
        default:
            return
        }
    }
//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        // #warning Potentially incomplete method implementation.
//        // Return the number of sections.
//        return 0
//    }
//
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete method implementation.
//        // Return the number of rows in the section.
//        return 0
//    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...

        return cell
    }
    */

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

}
