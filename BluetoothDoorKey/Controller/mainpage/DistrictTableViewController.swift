//
//  DistrictTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/7/26.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class DistrictTableViewController: UITableViewController {

//    var dataArray:NSArray?
    var loaded : Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackButton()
        
        
        self.edgesForExtendedLayout = UIRectEdge.None
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if loaded == false
        {
            self.addPullFunc()
            self.tableView.triggerPullToRefresh()
            self.loaded = true
        }
        
    }
    
    override func pullRefreshFunc() {
        AFHelpClient.sharedInstance.postHttpRequest(cellService, parameter: ["action":"list"], success: { (operation, responseData, message) -> Void in
            self.dataArray = NSMutableArray(array: responseData as! [AnyObject])
            self.tableView.reloadData()
            self.tableView.pullToRefreshView.stopAnimating()
        }) { (operation, error, message) -> Void in
            self.tableView.pullToRefreshView.stopAnimating()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        if(self.dataArray == nil)
        {
            return 0;
        }
        else
        {
            return (self.dataArray?.count)!
        }
        
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UITableViewCell
        var dic = self.dataArray?.objectAtIndex(indexPath.row) as! NSDictionary
        cell.textLabel?.text = dic.objectForKey("name") as? String
        cell.detailTextLabel?.text = ""//dic.objectForKey("tel") as? String
        // Configure the cell...

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        NSNotificationCenter.defaultCenter().postNotificationName(ntf_select_district, object: nil, userInfo:["district":self.dataArray!.objectAtIndex(indexPath.row)])
        self.navigationController?.popViewControllerAnimated(true)
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
