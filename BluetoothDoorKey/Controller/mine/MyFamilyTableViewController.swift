//
//  MyFamilyTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/10.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class MyFamilyTableViewController: UITableViewController,DZNEmptyDataSetDelegate,DZNEmptyDataSetSource{

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackButton()
        if #available(iOS 8.0, *) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
        if(self.tableView.respondsToSelector("setSeparatorInset:"))
        {
            self.tableView.separatorInset = UIEdgeInsetsMake(0, kdScreenWidth, 0, 0)
        }
        self.edgesForExtendedLayout = UIRectEdge.None
        self.addPullFunc()
        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
    
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.triggerPullToRefresh()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func pullRefreshFunc() {
        AFHelpClient.sharedInstance.postHttpRequest(familyService, parameter: ["action":"list","sessionid":UserObject.sharedInstance.sessionId], success: { (operation, responseData, message) -> Void in
            self.tableView.pullToRefreshView.stopAnimating()
            self.dataArray = NSMutableArray(array: responseData as! [AnyObject])
            self.tableView.reloadData()
        }) { (operation, error, message) -> Void in
            self.tableView.pullToRefreshView.stopAnimating()
        }
    }
    
    // MARK: - empty data 
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "您还没有添加任何家人"
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

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if #available(iOS 8.0, *) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        if(cell.respondsToSelector("setSeparatorInset:"))
        {
            if(indexPath.row == 0)
            {
                cell.separatorInset = UIEdgeInsetsZero
            }
            else
            {
                cell.separatorInset = UIEdgeInsetsMake(0, 11, 0, 11)
            }
            
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.dataArray != nil)
        {
            return self.dataArray!.count
        }
        else
        {
            return 0
        }
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell0", forIndexPath: indexPath) 
        let dic:NSDictionary = self.dataArray!.objectAtIndex(indexPath.row) as! NSDictionary
        var label : UILabel = cell.viewWithTag(1) as! UILabel
        label.text = dic.objectForKey("name") as? String
        label = cell.viewWithTag(2) as! UILabel
        label.text = dic.objectForKey("tel") as? String

        return cell
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
