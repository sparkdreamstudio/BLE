//
//  KeyManager.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/3.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit
private let _shareInstance = KeyManager()
private let despassword = ""
class KeyManager: NSObject {
    
    var keyArray:NSMutableArray = NSMutableArray()
    var sensor:BLE = BLE()
    var serverDate = NSDate()
    class var sharedInstance: KeyManager {
        get {
            return _shareInstance
        }
    }

    class func descrpytKey(keyString:String, WithPassword passWord:String) -> NSData
    {
        
        let decryptData = Utility.parseHexToByteArray(keyString) //把16进制字符串转为nsdata对象
        return Crypto.SymmetricDecrypt(decryptData, withPassword: passWord, type: Crypto.SymmetricCryptType.DES)
    }

    
    func loadDbKeys()
    {
        let name: String? = NSUserDefaults.standardUserDefaults().objectForKey("UserName") as? String
        if(name == nil)
        {
            let array : NSMutableArray? = KeyDbObject.allDbObjects();
            if (array != nil)
            {
                self.keyArray = array!
            }
            self.sensor.setup()
        }
        else
        {
            let array : NSMutableArray? = KeyDbObject.dbObjectsWhere("userName='\(name!)'", orderby: nil);
            if (array != nil)
            {
                self.keyArray = array!
            }
            self.sensor.setup()
        }
    }
    func downloadKeys(success:(message:String) -> Void, failure:(error:NSError,message:String) -> Void)
    {
        AFHelpClient.sharedInstance.postHttpRequest(keyService, parameter: ["action":"list","sessionid":UserObject.sharedInstance.sessionId], success: { (operation, responseData, message) -> Void in
            self.parseFunc(responseData)
            success(message: message)
            }) { (operation, error, message) -> Void in
                failure(error: error, message: message)
        }
    }
    
    func parseFunc(object:AnyObject)
    {
        let array : NSArray = object as! NSArray
        if(array.count == 0)
        {
            return
        }
        for index in 0...array.count-1
        {
            let dic : NSDictionary = array.objectAtIndex(index) as! NSDictionary
            let keyDb : KeyDbObject = KeyDbObject()
            keyDb.__id__ = dic.objectForKey("id")?.stringValue
            keyDb.name = dic.objectForKey("name") as! String
            keyDb.validity = dic.objectForKey("validity") as! String
            keyDb.dataPackage = dic.objectForKey("dataPackage") as! String
            keyDb.userName = UserObject.sharedInstance.userName!
            if (KeyDbObject.existDbObjectsWhere("__id__='\(keyDb.__id__)'") == false)
            {
                NSUserDefaults.standardUserDefaults().setObject(true, forKey: "DBChange");
                NSUserDefaults.standardUserDefaults().synchronize()
                keyDb.replaceToDb()
                self.keyArray.addObject(keyDb)
            }
            
            
        }
    }
    
    func backUpKeyObject() -> Bool
    {
//        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//        NSString *path = [NSString stringWithFormat:@"%@/%@", document, autodb.sqlite]
        AutoDbHandle.closeDb()
        let documentPath : String = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] 
        let dbPath : String = "\(documentPath)/autodb.sqlite"
        let fileManager : NSFileManager = NSFileManager.defaultManager()
        if (fileManager.fileExistsAtPath(dbPath) == false)
        {
            return false
        }
        let backDic = "\(documentPath)/backUp"
        if (fileManager.fileExistsAtPath(backDic) == false)
        {
            do {
                try fileManager.createDirectoryAtPath(backDic, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
        }
        let nowDate:NSDate = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString : String = dateFormatter.stringFromDate(nowDate)
        let backFilePath : String = "\(backDic)/\(dateString)"
        return Utility.copyFileFrom(dbPath, toTargetPath: backFilePath)
    }
    
    func contentOfBackUp() -> NSArray
    {
        let documentPath : String = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] 
        let backDic = "\(documentPath)/backUp"
        let fileManager : NSFileManager = NSFileManager.defaultManager()
        var fileList : NSArray? = try? fileManager.contentsOfDirectoryAtPath(backDic)
        if fileList == nil
        {
            fileList = NSArray()
        }
        return fileList!
    }
    
}
