//
//  TestSwift.swift
//  TestSwift
//
//  Created by lvlin on 15/4/27.
//  Copyright (c) 2015年 融信信息. All rights reserved.
//

import Foundation

private let _shareInstance = AFHelpClient()

public class AFHelpClient : NSObject {
    
    var reachAbilityManager : AFNetworkReachabilityManager = (UIApplication.sharedApplication().delegate as! AppDelegate).reachAbilityManager!
    class var sharedInstance: AFHelpClient {
        get {
            return _shareInstance
        }
    }
    
    private var currentManager = AFHTTPRequestOperationManager()
    
    override init() {
        super.init()
        currentManager = AFHTTPRequestOperationManager(baseURL: NSURL(string: baseUrlString))
        currentManager.responseSerializer.acceptableContentTypes = NSSet().setByAddingObject("text/plain");
    }

    
    func isOnline() -> Bool {
        return true
    }
    
    // MARK: - *** 请求 ***
    
    func cancelAllRequest() {
        currentManager.operationQueue.cancelAllOperations()
    }
    
    func getHttpRequest(path:String, parameter:[NSObject : AnyObject]?, success:(operation:AFHTTPRequestOperation, responseObject:AnyObject) -> Void, failure:(operation:AFHTTPRequestOperation?, error:NSError) -> Void) -> AFHTTPRequestOperation? {
        if(self.reachAbilityManager.networkReachabilityStatus == AFNetworkReachabilityStatus.NotReachable)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(NSEC_PER_SEC/4)), dispatch_get_main_queue(), { () -> Void in
                JDStatusBarNotification.showWithStatus("您的手机现在无法连接到服务器", dismissAfter: 2, styleName: "warning")
            })
            return nil
        }
        
        
        
        return currentManager.GET(path, parameters: parameter, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            self.printRequestLog(path, parameter: parameter)
            self.printResponseLog(responseObject)

            success(operation: operation, responseObject: responseObject)
            
            }, failure: { (operation: AFHTTPRequestOperation!, error:NSError!) -> Void in
                failure(operation: operation, error: error)
                print("Error: " + error.localizedDescription)
        })
    }
    
    func postHttpRequest(path:String, parameter:[NSObject : AnyObject]?, success:(operation:AFHTTPRequestOperation, responseData:AnyObject, message:String) -> Void, failure:(operation:AFHTTPRequestOperation?, error:NSError,message:String) -> Void) -> AFHTTPRequestOperation? {
        
        if(self.reachAbilityManager.networkReachabilityStatus == AFNetworkReachabilityStatus.NotReachable)
        {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(NSEC_PER_SEC/4)), dispatch_get_main_queue(), { () -> Void in
                JDStatusBarNotification.showWithStatus("您的手机现在无法连接到服务器", dismissAfter: 2, styleName: "warning")
            })
            return nil
        }
        
        
        return currentManager.POST(path, parameters: parameter, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            self.printRequestLog(path, parameter: parameter)
            self.printResponseLog(responseObject)
            if (responseObject == nil)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(NSEC_PER_SEC/4)), dispatch_get_main_queue(), { () -> Void in
                    failure(operation: operation, error: NSError(domain: "", code: 0, userInfo: nil), message: "服务器错误")
                    //                    failure(operation: operation, error: error)
                    //                    failure(operation: operation, error: nil, message: "")
                })
                return
            }
            let result: Bool = responseObject.objectForKey("result") as! Bool;
            let code : Int = responseObject.objectForKey("code")! as! Int
            if(code == 200 && result == true)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(NSEC_PER_SEC/4)), dispatch_get_main_queue(), { () -> Void in
                    success(operation: operation, responseData: responseObject.objectForKey("data")!, message: responseObject.objectForKey("message")as! String)
                })
                
            }
            else if (code == 202)
            {
                if path != memberService || path != smsService
                {
                    NSNotificationCenter.defaultCenter().postNotificationName(ntf_time_out, object: nil)
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(NSEC_PER_SEC/4)), dispatch_get_main_queue(), { () -> Void in
                    failure(operation: operation, error: NSError(domain: "", code: 0, userInfo: nil), message: responseObject.objectForKey("message")as! String)
                })
            }
            else
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(NSEC_PER_SEC/4)), dispatch_get_main_queue(), { () -> Void in
 
                    failure(operation: operation, error: NSError(domain: "", code: 0, userInfo: nil), message: responseObject.objectForKey("message")as! String)
                })
                
            }
            
            }, failure: { (operation: AFHTTPRequestOperation!, error:NSError!) -> Void in
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(NSEC_PER_SEC/4)), dispatch_get_main_queue(), { () -> Void in
                    failure(operation: operation, error: NSError(domain: "", code: 0, userInfo: nil), message: "")
//                    failure(operation: operation, error: error)
//                    failure(operation: operation, error: nil, message: "")
                })
                print("Error: " + error.localizedDescription)
        })
    }
    
    func postImageRequest(path:String!,data:NSData!, parameter:[NSObject : AnyObject]?, success:(operation:AFHTTPRequestOperation, responseData:AnyObject, message:String) -> Void, failure:(operation:AFHTTPRequestOperation?, error:NSError,message:String) -> Void) -> AFHTTPRequestOperation? {
        return currentManager.POST(path, parameters: parameter, constructingBodyWithBlock: { (formData) -> Void in
            formData.appendPartWithFileData(data, name: "imgFile", fileName: "imagehead.jpg", mimeType: "jpeg")
        }, success: { (operation, responseObject) -> Void in
            self.printRequestLog(path, parameter: parameter)
            self.printResponseLog(responseObject)
            if (responseObject == nil)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(NSEC_PER_SEC/4)), dispatch_get_main_queue(), { () -> Void in
                    failure(operation: operation, error: NSError(domain: "", code: 0, userInfo: nil), message: "服务器错误")
                    //                    failure(operation: operation, error: error)
                    //                    failure(operation: operation, error: nil, message: "")
                })
                return
            }
            let result: Bool = responseObject.objectForKey("result") as! Bool;
            let code : Int = responseObject.objectForKey("code")! as! Int
            if(code == 200 && result == true)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(NSEC_PER_SEC/4)), dispatch_get_main_queue(), { () -> Void in
                    success(operation: operation, responseData: responseObject.objectForKey("data")!, message: responseObject.objectForKey("message")as! String)
                })
                
            }
            else if (code == 202)
            {
                if path != memberService || path != smsService
                {
                    NSNotificationCenter.defaultCenter().postNotificationName(ntf_time_out, object: nil)
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(NSEC_PER_SEC/4)), dispatch_get_main_queue(), { () -> Void in
                    failure(operation: operation, error:NSError(domain: "", code: 0, userInfo: nil), message: responseObject.objectForKey("message")as! String)
                })
            }
            else
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(NSEC_PER_SEC/4)), dispatch_get_main_queue(), { () -> Void in
                    
                    failure(operation: operation, error: NSError(domain: "", code: 0, userInfo: nil), message: responseObject.objectForKey("message")as! String)
                })
                
            }
        }, failure: { (operation, error) -> Void in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(NSEC_PER_SEC/4)), dispatch_get_main_queue(), { () -> Void in
                failure(operation: operation, error: NSError(domain: "", code: 0, userInfo: nil), message: "")

            })
            print("Error: " + error.localizedDescription)
        })
    }
    
    func printRequestLog(path:String, parameter:[NSObject : AnyObject]?) {
//        #if DEBUG
            print("=========================================")
            print("请求：\n\(path) \n参数：\n\(parameter)\n")
//        #endif
    }
    
    func printResponseLog(responseObject:AnyObject?) {
//        #if DEBUG
            print("返回：\n\(responseObject)")
            print("=========================================")
//        #endif
    }
}




