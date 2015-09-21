//
//  KeyDbObject.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/8/3.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

class KeyDbObject: AutoDbObject {
    var name : String = ""
    var validity : String = ""
    var dataPackage : String = ""
    var password:String = ""
    var userName:String = ""
    
    func isExpire(nowDate:NSDate) -> Bool
    {
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let expiredDate : NSDate = dateFormatter.dateFromString(self.validity)!
        return expiredDate.compare(nowDate) == NSComparisonResult.OrderedAscending
    }
}
