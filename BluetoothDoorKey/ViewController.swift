//
//  ViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/7/11.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

extension UIViewController
{
    func addBackButton()
    {
        let backButton : UIButton = UIButton(frame: CGRectMake(0, 0, 60, 30))
        backButton.setImage(UIImage(named: "navbar_back"), forState: UIControlState.Normal)
        backButton.contentHorizontalAlignment=UIControlContentHorizontalAlignment.Left
        backButton.addTarget(self, action: "backFunc:", forControlEvents: UIControlEvents.TouchUpInside)
        let fixBar:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        fixBar.width = -9
        self.navigationItem.leftBarButtonItems = [fixBar,UIBarButtonItem(customView: backButton)]
    }
    
    func backFunc(sender:UIButton)
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func setViewCornRadius(view:UIView,cornerRadius:CGFloat)
    {
        view.layer.masksToBounds = true
        view.layer.cornerRadius = cornerRadius;
    }
    
    func disableEmptySeperator()
    {
        let tableViewController : UITableViewController = self as!UITableViewController
        tableViewController.tableView.tableFooterView = UIView(frame: CGRectMake(0, 0, kdScreenWidth, 1))
    }
}

extension UITableViewController
{
    private struct AssociatedKeys{
        static var dataArray = "nsh_dataArray"
        static var currentPageNo = "nsh_currentPageNo"
    }
    
    var dataArray:NSMutableArray?{
        get{
            return objc_getAssociatedObject(self, &AssociatedKeys.dataArray) as? NSMutableArray
        }
        set{
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.dataArray, newValue as NSMutableArray?, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    var currentPageNo : Int? {
        get{
            return objc_getAssociatedObject(self, &AssociatedKeys.currentPageNo) as? Int
        }
        set{
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.currentPageNo, newValue as Int?, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    func addPullFunc()
    {
        self.tableView.addPullToRefreshWithActionHandler { () -> Void in
            self.pullRefreshFunc()
        }
    }
    func addInfiniteRefresh()
    {
        self.tableView.addInfiniteScrollingWithActionHandler { () -> Void in
            self.infinitRefreshFunc()
        }
    }
    
    func pullRefreshFunc()
    {
        
    }
    
    func infinitRefreshFunc()
    {
        
    }
}

