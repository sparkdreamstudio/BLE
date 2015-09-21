//
//  MyKeyApplyTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/7/27.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class MyKeyApplyTableViewController: UITableViewController,DZNEmptyDataSetDelegate,DZNEmptyDataSetSource,UIActionSheetDelegate {

    var currentSelectedIndexPath : NSIndexPath?
//    var dataArray : NSMutableArray?
//    var currentPageNo : Int = 1
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge.None
        self.addBackButton()
        
        self.addPullFunc()
        self.addInfiniteRefresh()
        self.tableView.triggerPullToRefresh()
        
        
        if #available(iOS 8.0, *) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
        if(self.tableView.respondsToSelector("setSeparatorInset:"))
        {
            self.tableView.separatorInset = UIEdgeInsetsMake(0, kdScreenWidth, 0, 0)
        }
        self.currentPageNo = 1
        
        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processNtf:", name: ntf_keyapplylist_refresh, object: nil)
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func processNtf(ntf:NSNotification)
    {
        if ntf.name == ntf_keyapplylist_refresh
        {
            self.tableView.triggerPullToRefresh()
        }
    }
    
    override func pullRefreshFunc() {
        self.currentPageNo = 1
        AFHelpClient.sharedInstance.postHttpRequest(applyService, parameter: ["action":"list","currentPageNo":self.currentPageNo!,"pageSize":"20","sessionid":UserObject.sharedInstance.sessionId], success: { (operation, responseData, message) -> Void in
            self.tableView.pullToRefreshView.stopAnimating()
            self.dataArray = NSMutableArray(array: (responseData as? NSArray)! )
            if(self.dataArray!.count == 0)
            {
                self.tableView.showsInfiniteScrolling = false
            }
            if (self.dataArray!.count < 20)
            {
                self.tableView.showsInfiniteScrolling = false
            }
            else
            {
                self.tableView.showsInfiniteScrolling = true
            }
            self.tableView.reloadData()
        }) { (operation, error, message) -> Void in
            self.tableView.pullToRefreshView.stopAnimating()
        }
    }
    
    override func infinitRefreshFunc() {
        self.currentPageNo!++
        AFHelpClient.sharedInstance.postHttpRequest(applyService, parameter: ["action":"list","currentPageNo":self.currentPageNo!,"pageSize":"20","sessionid":UserObject.sharedInstance.sessionId], success: { (operation, responseData, message) -> Void in
            self.tableView.infiniteScrollingView.stopAnimating()
            let array : NSArray = (responseData as? NSArray)!
            if(array.count == 0)
            {
                self.tableView.showsInfiniteScrolling = false
                return
            }
            if (array.count < 20)
            {
                self.tableView.showsInfiniteScrolling = false
            }
            else
            {
                self.tableView.showsInfiniteScrolling = true
            }
            self.dataArray?.addObjectsFromArray(array as [AnyObject])
            var indexPathArray = [NSIndexPath]()
            for index in 0...array.count-1
            {
                indexPathArray.append(NSIndexPath(forRow: self.dataArray!.count-array.count+index, inSection: 0))
            }
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths(indexPathArray, withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
            }) { (operation, error, message) -> Void in
                self.currentPageNo!--
                self.tableView.infiniteScrollingView.stopAnimating()
        }
    }
    
    // MARK: - empty data
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "您还没有任何钥匙申请"
        let attributes : NSDictionary = [NSFontAttributeName:UIFont.boldSystemFontOfSize(15),NSForegroundColorAttributeName:UIColor.darkGrayColor()]
        return NSAttributedString(string: text, attributes: attributes as? [String : AnyObject])
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let text = "点击刷新"
        let attributes : NSDictionary = [NSFontAttributeName:UIFont.boldSystemFontOfSize(14),NSForegroundColorAttributeName:UIColor.darkGrayColor()]
        return NSAttributedString(string: text, attributes: attributes as? [String : AnyObject])
    }
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        self.tableView.triggerPullToRefresh()
    }

    // MARK: - Table view data source & delegate

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if(self.dataArray != nil)
        {
            return (self.dataArray?.count)!
        }
        return 0
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let dic : NSDictionary = self.dataArray!.objectAtIndex(indexPath.row) as! NSDictionary
        if (dic.objectForKey("status") as! Int == 0)
        {
            let  cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("cell0", forIndexPath: indexPath)
            var label : UILabel = cell.viewWithTag(1) as! UILabel
            let cellName : String = dic.objectForKey("cell")!.objectForKey("name") as! String
            let floor : String = dic.objectForKey("floor") as! String
            label.text = "\(cellName) \(floor)"
            label = cell.viewWithTag(2) as! UILabel
            self.setViewCornRadius(label, cornerRadius: 2)
            return cell
        }
        else
        {
            let  cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("cell1", forIndexPath: indexPath)
            let label : UILabel = cell.viewWithTag(1) as! UILabel
            let cellName : String = dic.objectForKey("cell")!.objectForKey("name") as! String
            let floor : String = dic.objectForKey("floor") as! String
            label.text = "\(cellName) \(floor)"
            return cell
        }
    }

    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 56
    }

    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
       
        if #available(iOS 8.0, *) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        if(cell.respondsToSelector("setSeparatorInset:"))
        {
            cell.separatorInset = UIEdgeInsetsMake(0, 11, 0, 11)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let actionSheet : UIActionSheet = UIActionSheet(title: "是否删除该条申请", delegate: self, cancelButtonTitle: "取消", destructiveButtonTitle: "删除");
        actionSheet.showInView(self.view)
        self.currentSelectedIndexPath = indexPath
    }
    
    // MARK: actionSheet delegate
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if  buttonIndex == actionSheet.destructiveButtonIndex
        {
            KVNProgress.showWithStatus("删除中")
            let dic : NSDictionary = self.dataArray!.objectAtIndex(self.currentSelectedIndexPath!.row) as! NSDictionary
            AFHelpClient.sharedInstance.postHttpRequest(applyService, parameter: ["action":"delete","sessionid":UserObject.sharedInstance.sessionId,"id":dic.objectForKey("id")!], success: { (operation, responseData, message) -> Void in
                KVNProgress.showSuccessWithStatus(message)
                self.dataArray!.removeObjectAtIndex(self.currentSelectedIndexPath!.row)
                self.tableView.beginUpdates()
                self.tableView.deleteRowsAtIndexPaths([self.currentSelectedIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
                self.tableView.endUpdates()
                self.currentSelectedIndexPath = nil
                }, failure: { (operation, error, message) -> Void in
                    KVNProgress.showErrorWithStatus(message)
                    self.currentSelectedIndexPath = nil
            })
        }
        else
        {
            self.currentSelectedIndexPath = nil
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

}
