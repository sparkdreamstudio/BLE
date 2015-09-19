//
//  AppDelegate.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/7/11.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,EAIntroDelegate {

    var intro : EAIntroView?
    
    var window: UIWindow?
    
    var tabBarController : RDVTabBarController?

    var reachAbilityManager : AFNetworkReachabilityManager?
//    var navgationController : UINavigationController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.reachAbilityManager = AFNetworkReachabilityManager(forDomain: "http://www.yaokaimen.com")
        self.reachAbilityManager?.setReachabilityStatusChangeBlock({ (status:AFNetworkReachabilityStatus) -> Void in
            
        })
        // Override point for customization after application launch.
        KeyManager.sharedInstance.loadDbKeys()
        
        AFHelpClient.sharedInstance.postHttpRequest(otherService, parameter: ["action":"serverDate"], success: { (operation, responseData, message) -> Void in
            var dateString : String = responseData.objectForKey("date") as! String
            var dateFormatter:NSDateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            KeyManager.sharedInstance.serverDate = dateFormatter.dateFromString(dateString)!
            NSNotificationCenter.defaultCenter().postNotificationName(ntf_serverdate_refresh, object: nil)
        }) { (operation, error, message) -> Void in
            
        }
        
        self.initNavigationBarApperance()
        self.window = CPMotionRecognizingWindow(frame: UIScreen.mainScreen().bounds)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "ntfProcess:", name: ntf_time_out, object: nil)
        self.initControllers()
//        self.initControllers()
        
//        UserObject.sharedInstance.autoLogIn { (result, message) -> Void in
//            self.initControllers()
//        }
//        self.window?.rootViewController = self.navgationController
        self.window?.makeKeyAndVisible()
        
        
        var name : String = ""
        switch kdScreenHeight
        {
        case 480:
            name = "4"
        case 568:
            name = "5"
        case 667:
            name = "6"
        case 736:
            name = "plus"
        default:
            name = "plus"
            
        }
        var name1 = "yindaoye \(name)"
        var name2 = "yindaoye \(name)1"
        var page1 : EAIntroPage = EAIntroPage()
        page1.bgImage = UIImage(named: name1);
        var page2 : EAIntroPage = EAIntroPage()
        page2.bgImage = UIImage(named: name2);
        
        self.intro = EAIntroView(frame: CGRectMake(0, 0, kdScreenWidth, kdScreenHeight), andPages: [page1,page2])
        self.intro?.delegate = self;
        self.intro?.showFullscreen()
        
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        AFHelpClient.sharedInstance.postHttpRequest(otherService, parameter: ["action":"serverDate"], success: { (operation, responseData, message) -> Void in
            var dateString : String = responseData.objectForKey("date") as! String
            var dateFormatter:NSDateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            KeyManager.sharedInstance.serverDate = dateFormatter.dateFromString(dateString)!
            NSNotificationCenter.defaultCenter().postNotificationName(ntf_serverdate_refresh, object: nil)
            }) { (operation, error, message) -> Void in
                
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func introDidFinish(introView: EAIntroView!) {
        NSNotificationCenter.defaultCenter().postNotificationName(ntf_time_out, object: nil)
    }
    
    func initControllers()
    {
        self.tabBarController = RDVTabBarController();
        tabBarController!.edgesForExtendedLayout = UIRectEdge.None
        tabBarController!.viewControllers = [
            UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!,
            UIStoryboard(name: "Key", bundle: nil).instantiateInitialViewController()!,
            UIStoryboard(name: "Message", bundle: nil).instantiateInitialViewController()!,
            UIStoryboard(name: "Mine", bundle: nil).instantiateInitialViewController()!
        ];
        
        let tabBar : RDVTabBar = tabBarController!.tabBar;
        tabBar.translucent = false
        tabBar.backgroundView.backgroundColor = UIColor(red: 0x16/255, green: 0x16/255, blue: 0x16/255, alpha: 1)
        tabBar.frame = CGRectMake(CGRectGetMinX(tabBar.frame), CGRectGetMinY(tabBar.frame), CGRectGetWidth(tabBar.frame), 52);
        for index in 0...3
        {
            let item : RDVTabBarItem = tabBar.items[index] as! RDVTabBarItem
            item.setFinishedSelectedImage(UIImage(named: "tab_\(index)_selected"), withFinishedUnselectedImage: UIImage(named: "tab_\(index)"))
        }
        self.window?.rootViewController = tabBarController
        
        
    }
    
    func initNavigationBarApperance()
    {
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barTintColor = UIColor(red: 0x0b/255, green: 0xd5/255, blue: 0xb6/255, alpha: 1)
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        UIBarButtonItem.appearance().tintColor = UIColor.whiteColor()
    }
    
    func ntfProcess(ntf:NSNotification)
    {
        if ntf.name == ntf_time_out
        {
            if kdScreenHeight != 480
            {
                self.window?.rootViewController?.presentViewController(UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController()!, animated: true, completion: { () -> Void in
                })
            }
            else
            {
                self.window?.rootViewController?.presentViewController(UIStoryboard(name: "Login", bundle: nil).instantiateViewControllerWithIdentifier("initial_controller_4s"), animated: true, completion: { () -> Void in
                })
            }
        }
    }


}

