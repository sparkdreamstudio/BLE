//
//  MineTableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/7/19.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class MineTableViewController: UITableViewController,UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    @IBOutlet weak var memberHeadImage: UIImageView!
    @IBOutlet weak var memberName: UILabel!
    @IBOutlet weak var memberText: UILabel!
    @IBOutlet weak var bottomView:UIView!
    @IBOutlet weak var logoutButton:UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 8.0, *) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
        if(self.tableView.respondsToSelector("setSeparatorInset:"))
        {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        self.bottomView.frame = CGRectMake(0, 0, kdScreenWidth, 100)
        self.setViewCornRadius(self.logoutButton, cornerRadius: 4)
        self.memberHeadImage.layer.masksToBounds = true
        self.memberHeadImage.layer.cornerRadius = 37.5
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    
    func loadMemberInfo()
    {
        self.memberHeadImage.setImageWithURL(NSURL(string: UserObject.sharedInstance.usrImgURLString!), placeholderImage: UIImage(named: "user_default_icon"))
        var userName : String? = UserObject.sharedInstance.userName
        
        if userName == nil
        {
            self.memberName.text = "未登录"
            self.memberText.hidden = true
            self.bottomView.hidden = true
        }
        else
        {
            let userNameString : NSString = NSString(string: userName!)
            userName = userNameString.stringByReplacingCharactersInRange(NSMakeRange(3, 4), withString: "****")
            self.memberName.text = userName
            self.memberText.hidden = false
            self.bottomView.hidden = false
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        let tabBarController = (UIApplication.sharedApplication().delegate as! AppDelegate).tabBarController
        tabBarController?.tabBarHidden = false;
        self.loadMemberInfo()
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != actionSheet.cancelButtonIndex
        {
            let imageVC : UIImagePickerController = UIImagePickerController()
            if buttonIndex == 1
            {
                imageVC.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            }
            else
            {
                imageVC.sourceType = UIImagePickerControllerSourceType.Camera
            }
            imageVC.delegate = self
            self.presentViewController(imageVC, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        picker.dismissViewControllerAnimated(true, completion: { () -> Void in
            KVNProgress.showWithStatus("上传头像")
            AFHelpClient.sharedInstance.postImageRequest(memberService, data: UIImageJPEGRepresentation(image.fixOrientation(), 0.3), parameter: ["action":"modify","sessionid":UserObject.sharedInstance.sessionId], success: { (operation, responseData, message) -> Void in
                UserObject.sharedInstance.usrImgURLString = responseData.objectForKey("img") as? String
                self.loadMemberInfo()
                KVNProgress.showSuccessWithStatus(message)
                }) { (operation, error, message) -> Void in
                KVNProgress.showErrorWithStatus(message)
            }
        })
        
    }
    
    @IBAction func logOutBtnClick(sender:UIButton)
    {
        UserObject.sharedInstance.logOut()
        NSNotificationCenter.defaultCenter().postNotificationName(ntf_time_out, object: nil)
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "downloadedkeys")
        NSUserDefaults.standardUserDefaults().synchronize()
        
    }
    
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
                cell.separatorInset = UIEdgeInsetsMake(0, 9, 0, 9)
            }
            
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.row == 0 && UserObject.sharedInstance.sessionId != "")
        {
            let actionSheet:UIActionSheet = UIActionSheet(title: "修改头像", delegate: self, cancelButtonTitle: "取消", destructiveButtonTitle: nil, otherButtonTitles: "照片","相机")
            actionSheet.showInView(self.view)
        }
    }
    
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        switch indexPath.row
//        {
//        case 0:
//            return kdScreenWidth*0.42
//        case 1,2,3,4,6,7:
//            return 52;
//        case 5:
//            return 6;
//        default:
//            return 0;
//        }
        switch indexPath.row
        {
        case 0:
            return kdScreenWidth*0.42
        case 1,2,3,5,6:
            return 52;
        case 4:
            return 6;
        default:
            return 0;
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let tabBarController = (UIApplication.sharedApplication().delegate as! AppDelegate).tabBarController
        tabBarController?.tabBarHidden = true;
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    
}
