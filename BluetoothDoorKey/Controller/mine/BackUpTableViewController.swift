//
//  BackUpTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/23.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class BackUpTableViewController: UITableViewController,BackUpKeyTableViewCellDelegate,DZNEmptyDataSetDelegate,DZNEmptyDataSetSource {

    var fileList:NSArray! = KeyManager.sharedInstance.contentOfBackUp()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
        
            if #available(iOS 8.0, *) {
                self.tableView.layoutMargins = UIEdgeInsetsZero
            }
        if(self.tableView.respondsToSelector("setSeparatorInset:"))
        {
            self.tableView.separatorInset = UIEdgeInsetsMake(0, kdScreenWidth, 0, 0)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func reloadKey()
    {
        self.fileList = KeyManager.sharedInstance.contentOfBackUp()
        self.tableView.reloadData()
    }
    
    func backUpKeyTableViewCell(cell: BackUpKeyTableViewCell, ButtonClick button: UIButton) {
        let indexPath = self.tableView.indexPathForCell(cell)
        AutoDbHandle.closeDb()
        let documentPath : String = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        let dbPath : String = "\(documentPath)/autodb.sqlite"
        let fileManager : NSFileManager = NSFileManager.defaultManager()

        do {
            try fileManager.removeItemAtPath(dbPath)
        } catch  {
            KVNProgress.showErrorWithStatus("恢复失败")
        }
        let backDic = "\(documentPath)/backUp"
        let fileName:String = self.fileList.objectAtIndex(indexPath!.row) as! String
        let backPath = "\(backDic)/\(fileName)"
        Utility.copyFileFrom(backPath, toTargetPath: dbPath)
        KeyManager.sharedInstance.loadDbKeys()
        NSNotificationCenter.defaultCenter().postNotificationName(nft_keymanager_reload, object: nil)
        KVNProgress.showSuccessWithStatus("完成")
        NSUserDefaults.standardUserDefaults().setObject(false, forKey: "DBChange");
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    
    
    // MARK: - empty data
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text : String = "您还没有备份钥匙"
        let attributes : NSDictionary = [NSFontAttributeName:UIFont.boldSystemFontOfSize(15),NSForegroundColorAttributeName:UIColor.darkGrayColor()]
        return NSAttributedString(string: text, attributes: attributes as? [String : AnyObject])
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
        return self.fileList.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : BackUpKeyTableViewCell = tableView.dequeueReusableCellWithIdentifier("cell0", forIndexPath: indexPath) as! BackUpKeyTableViewCell
        cell.delegate = self
        // Configure the cell...
        var label : UILabel = cell.viewWithTag(1) as! UILabel
        label.text = self.fileList.objectAtIndex(indexPath.row) as? String
        return cell
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
