//
//  PayLoadExt.swift
//  TeneasyChatSDK_iOS
//
//  Created by tian molin on 4/2/23.
//

import Foundation

public struct Session{
    var ID : UInt64? = 0//会用连接成功之后返回的第一个PayLoadId作为ID
    var ChatId = 0
    var WorkerId = 0
    var TokenId = 0
    var WelcomeMsg = "你好，我是客服小福"
    var Connected = false
}

public struct Result{
   public var Code = 0
    public var Message = ""
}
