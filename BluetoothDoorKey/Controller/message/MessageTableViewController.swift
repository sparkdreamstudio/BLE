//
//  MessageTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/3.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class MessageTableViewController: UITableViewController,DZNEmptyDataSetDelegate,DZNEmptyDataSetSource {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addPullFunc()
        self.addInfiniteRefresh()
        self.tableView.showsInfiniteScrolling = false
        self.currentPageNo = 1
        self.tableView.triggerPullToRefresh()
        
        if #available(iOS 8.0, *) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
        if(self.tableView.respondsToSelector("setSeparatorInset:"))
        {
            self.tableView.separatorInset = UIEdgeInsetsMake(0, kdScreenWidth, 0, 0)
        }
        self.edgesForExtendedLayout = UIRectEdge.None
        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processNtf:", name: ntf_delete_message, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func processNtf(ntf:NSNotification)
    {
        if ntf.name == ntf_delete_message
        {
            let dic: AnyObject? = ntf.object
            let index = self.dataArray?.indexOfObject(dic!)
            if index != NSNotFound
            {
                self.dataArray?.removeObjectAtIndex(index!)
                self.tableView.beginUpdates()
                self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index!, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                self.tableView.endUpdates()
            }
        }
    }
    
    override func pullRefreshFunc() {
        self.currentPageNo = 1
        AFHelpClient.sharedInstance.postHttpRequest(messageService, parameter: ["action":"list","currentPageNo":self.currentPageNo!,"pageSize":"20","sessionid":UserObject.sharedInstance.sessionId], success: { (operation, responseData, message) -> Void in
            self.tableView.pullToRefreshView.stopAnimating()
            self.dataArray = NSMutableArray(array: self.convertToMutableDicArray((responseData as? NSArray)!) )
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
        AFHelpClient.sharedInstance.postHttpRequest(messageService, parameter: ["action":"list","currentPageNo":self.currentPageNo!,"pageSize":"20","sessionid":UserObject.sharedInstance.sessionId], success: { (operation, responseData, message) -> Void in
            self.tableView.infiniteScrollingView.stopAnimating()
            let array : NSArray = self.convertToMutableDicArray((responseData as? NSArray)!)
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
            self.tableView.insertRowsAtIndexPaths(indexPathArray , withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
            }) { (operation, error, message) -> Void in
                self.currentPageNo!--
                self.tableView.infiniteScrollingView.stopAnimating()
        }
    }
    
    func convertToMutableDicArray(array:NSArray) -> NSArray
    {
        let returnArray:NSMutableArray = NSMutableArray()
        if array.count != 0
        {
            for index in 0...array.count - 1
            {
                let dic : NSMutableDictionary = NSMutableDictionary(dictionary: array.objectAtIndex(index) as! [NSObject : AnyObject])
                returnArray.addObject(dic)
            }
        }
        
        return returnArray
    }
    
    // MAKR: - empty data
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "您暂时还没有任何消息"
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
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if (self.dataArray == nil)
        {
            return 0;
        }
        return self.dataArray!.count
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let dic:NSDictionary = self.dataArray!.objectAtIndex(indexPath.row) as! NSDictionary
        var cell : UITableViewCell?
        if (dic.objectForKey("isRead") as! Int == 0)
        {
            cell = tableView.dequeueReusableCellWithIdentifier("cell0", forIndexPath: indexPath)
            let view:UIView = cell!.viewWithTag(1)!
            view.layer.masksToBounds = true
            view.layer.cornerRadius = 5
        }
        else
        {
            cell = tableView.dequeueReusableCellWithIdentifier("cell1", forIndexPath: indexPath)
        }
        var label : UILabel = cell?.viewWithTag(2) as! UILabel
        label.text = dic.objectForKey("content") as? String
        label = cell?.viewWithTag(3) as! UILabel
        label.text = dic.objectForKey("createTime") as? String

        // Configure the cell...

        return cell!
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let dic:NSMutableDictionary = self.dataArray!.objectAtIndex(indexPath.row) as! NSMutableDictionary
        KVNProgress.showWithStatus("")
        AFHelpClient.sharedInstance.postHttpRequest(messageService, parameter: ["action":"view","sessionid":UserObject.sharedInstance.sessionId,"id":dic.objectForKey("id")!], success: { (operation, responseData, message) -> Void in
            KVNProgress.dismiss()
            dic.setValue(1, forKey: "isRead")
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            self.performSegueWithIdentifier("show_message_detail", sender: dic)
        }) { (operation, error, message) -> Void in
            KVNProgress.showErrorWithStatus(message)
        }
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


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if segue.identifier == "show_message_detail"
        {
            let controller : MessageDetailViewController = segue.destinationViewController as! MessageDetailViewController
            controller.dic = sender as? NSDictionary
        }
    }


}
