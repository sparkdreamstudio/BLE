//
//  TableViewController.swift
//  BluetoothDoorKey
//
//  Created by leexiang on 15/7/12.
//  Copyright (c) 2015年 leexiang. All rights reserved.
//

import UIKit

let baseUrlString = "http://www.yaokaimen.com:8899/api/"

let kdScreenWidth : CGFloat = UIScreen.mainScreen().bounds.width
let kdScreenHeight : CGFloat = UIScreen.mainScreen().bounds.height


//API
let memberService = "memberservice.do"
let smsService = "smsservice.do"
let cellService = "cellservice.do"
let applyService = "applyservice.do"
let feedbackService = "feedbackservice.do"
let keyService = "keyservice.do"
let messageService = "messageservice.do"
let newsService = "newsservice.do"
let familyService = "familyservice.do"
let otherService = "otherservice.do"
//ntf Name
let ntf_log_in = "ntf_log_in"
let ntf_time_out = "ntf_time_out"
let ntf_select_district = "ntf_select_district"
let ntf_delete_message = "ntf_delete_message"
let ntf_serverdate_refresh = "ntf_serverdate_refresh"
let nft_keymanager_reload = "nft_keymanager_reload"