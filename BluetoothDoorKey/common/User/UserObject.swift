//
//  UserObject.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/7/26.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit
private let _shareInstance = UserObject()
class UserObject: NSObject {
    
    var userName:String?
    var passWord:String?
    var usrImgURLString:String?
    var sessionId:String! = ""
    class var sharedInstance: UserObject {
        get {
            return _shareInstance
        }
    }
    
    func changepassword(newpassword:String,WitholdPassword oldPassword:String,resultBlock:(result:Bool,message:String)->Void) -> Void
    {
        AFHelpClient.sharedInstance.postHttpRequest(memberService, parameter: ["action":"change","sessionid":self.sessionId,"oriPassword":oldPassword,"newPassword":newpassword], success: { (operation, responseData, message) -> Void in
            resultBlock(result: true, message: message)
        }) { (operation, error, message) -> Void in
            resultBlock(result: false, message: message)
        }
    }
    
    func logInWith(name: String,password:String,resultBlock:(result:Bool,message:String)->Void)->Void
    {
        AFHelpClient.sharedInstance.postHttpRequest(memberService, parameter: ["action":"login","userName":name,"password":password], success: { (operation, responseData, message) -> Void in
            resultBlock(result: true, message: message)
            self.userName = name
            self.passWord = password
            NSUserDefaults.standardUserDefaults().setObject(self.userName, forKey: "UserName");
            NSUserDefaults.standardUserDefaults().setObject(self.passWord, forKey: "PassWord");
            NSUserDefaults.standardUserDefaults().synchronize()
            self.sessionId = (responseData as! NSDictionary).objectForKey("sessionid") as? String
            self.usrImgURLString = (responseData as! NSDictionary).objectForKey("img") as? String
            NSNotificationCenter.defaultCenter().postNotificationName(ntf_log_in, object: nil)
            
        }) { (operation, error, message) -> Void in
            resultBlock(result: false, message: message)
        }
    }
    
    func autoLogIn(resultBlock:(result:Bool,message:String)->Void)->Void
    {
        var name: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey("UserName")
        var pwd: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey("PassWord")
        if(name == nil || pwd == nil)
        {
            resultBlock(result: false, message: "")
        }
        else
        {
            logInWith(name as! String, password: pwd as! String) { (result, message) -> Void in
                resultBlock(result: result, message: message)
            }
        }
    }
    
    func logOut()->Void
    {
        self.userName = nil
        self.passWord = nil
        self.sessionId = ""
        NSUserDefaults.standardUserDefaults().removeObjectForKey("UserName")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("PassWord")
    }
    
    
}
