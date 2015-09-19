//
//  ClearPasswordTableViewController.swift
//  BluetoothDoorKey
//
//  Created by 李响 on 15/8/19.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class ClearPasswordTableViewController: UITableViewController {
    var keyObject: KeyDbObject = KeyDbObject()
    
    @IBOutlet weak var password:UITextField!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.bottomView.frame = CGRectMake(0, 0, kdScreenWidth, 170)
        self.setViewCornRadius(self.clearButton, cornerRadius: 4)
        self.addBackButton()    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func changePasswordAction(sender: UIButton) {
        self.view.endEditing(true)
        if (keyObject.password != "" && keyObject.password != self.password.text)
        {
            KVNProgress.showErrorWithStatus("旧密码错误")
            return
        }
        KVNProgress.showWithStatus("清除钥匙密码")
        self.keyObject.password = ""
        dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
            self.keyObject.updatetoDb()
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: "DBChange");
            NSUserDefaults.standardUserDefaults().synchronize()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                KVNProgress.showSuccessWithStatus("完成", completion: { () -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                })
            })
        })
        
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
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
