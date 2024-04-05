//
//  ViewController.swift
//  TeneasyChatSDK_iOS
//
//  Created by 7938813 on 01/19/2023.
//  Copyright (c) 2023 7938813. All rights reserved.
//

import UIKit
import TeneasyChatSDK_iOS
import SwiftDate

class ViewController: UIViewController, teneasySDKDelegate {
    @IBOutlet weak var tvChatView: UITextView!
    var lib = ChatLib()
    var payLoadId: UInt64 = 0
    var lastMessage: CommonMessage? = nil
    
    var send = false
    
    func connected(c: Gateway_SCHi) {
        print("token:\(c.token)")
        let autoMsg = lib.composeALocalMessage(textMsg: "你好，我是客服小福")
        appendMsg(msg: autoMsg.content.data)
        
        if c.workerID != 0{
            tvChatView.text.append("\n已连接上！ WorkId:\(c.workerID)\n\n")

        }else{
            //tvChatView.text.append("\n已断开连接\n\n")
            //tvChatView.text.append("\n重新连接\n")
            lib.reConnect()
        }
        tvChatView.text.append("\n发送图片！ ImageUrl: https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQQKV-3KPDbUgVdqjfEb3HK_SvGjcPYVl7n7KGCwBL6&s\n\n")
        lib.sendMessage(msg: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQQKV-3KPDbUgVdqjfEb3HK_SvGjcPYVl7n7KGCwBL6&s", type: .msgImg)
        print(c.workerID)
        
    }
    
    //收到对方的消息
    func receivedMsg(msg: CommonMessage) {
        print(msg)
        
        //let time = displayLocalTime(from: msg.msgTime.timeIntervalSince1970)
        let time = displayLocalTime(from: msg.msgTime.date)
        print(time)

        switch msg.payload{
        case .content(msg.content):
            print("text")
            appendMsg(msg: msg.content.data)
        case .image(msg.image):
            print(msg.image)
            appendMsg(msg: "图片：" + msg.image.uri)
        case .video(msg.video):
            print("video")
        case .audio(msg.audio):
            print("audio")
        default:
            print("ddd")
        }
    }
    
    //发送的消息收到回执
    func msgReceipt(msg: CommonMessage, payloadId : UInt64 = 0, errMsg: String?){
        var myMsg = ""
        print("收到回执")
        switch msg.payload{
        case .content(msg.content):
            print("text")
            print(msg.msgTime.date)
            myMsg = msg.content.data
        case .image(msg.image):
            print(msg.image)
            myMsg = "图片：" + msg.image.uri
        case .video(msg.video):
            print(msg.video)
            myMsg = "视频：" + msg.video.uri
        case .audio(msg.audio):
            print(msg.audio)
            myMsg = "音频：" + msg.audio.uri
        case .file(msg.file):
            print(msg.file)
            myMsg = "file：" + msg.file.uri
        default:
            print(msg)
        }
        
        tvChatView.text.append("                       " +  myMsg + " " + (errMsg ?? ""))
        if msg.msgID == 0{
            tvChatView.text.append("                    发送失败")
        }else{
            tvChatView.text.append("                    发送成功\(msg.msgID)")
        }
      
        let time = displayLocalTime(from: msg.msgTime.date)
        print(time)
        
        tvChatView.text.append("                                         " +  time + "\n\n")
        self.payLoadId = payloadId
        lastMessage = msg
    }
    
    //收到的系统消息
    func systemMsg(result: Result){
        appendMsg(msg: result.Message)
    }
    
    func appendMsg(msg: String){
        tvChatView.text.append(msg + "\n" +  Date().getFormattedDate(format: "HH:mm") + "\n\n")
        //cpf
    }
    
    func workChanged(msg: Gateway_SCWorkerChanged){
        tvChatView.text.append(msg.workerName)
        
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tvChatView.text = "teneasy chat sdk 初始化\n正在连接。。。\n"
        tvChatView.isUserInteractionEnabled = true
        tvChatView.isScrollEnabled = true
        
        initSDK()
    }
    
    func initSDK(){
        //从网页端把chatId和token传进sdk,2692944494603
        /*
         老token，一直有效，很好
         CCcQARgOICIowqaSjeIw.9rO3unQwFrUUa-vJ6HvUQAbiAZN7XWBbaE_Oyd48C0Ae4xhzWWSriIGZZdVSvOajS1h_RFlQHZiFzadgBBuwDQ
         
        CH0QARiX9w4gogEo9MS-08wx.R07hSs5oXQxe9s0bV0WsaislYcvHDNYvUYT-2JNEo4wcBC1LNEHmHAFSjCoY8g60oW31zZiIs1kZhejQEaEhBQ

       CH0QARib9w4gogEo8_nL1cwx.gXxoS2IK7cv4JWQb8LRmGI-cSEFHwfyBmoyErwSw0h1BXdkotxH4OgoiHvi6B6CON8LX7ei5AKwn3v1epXB9Cg
         */
        /*
               1125324  1125397 1125417
                */
        lib = ChatLib(userId: 1125397, cert: "CH0QARib9w4gogEo8_nL1cwx.gXxoS2IK7cv4JWQb8LRmGI-cSEFHwfyBmoyErwSw0h1BXdkotxH4OgoiHvi6B6CON8LX7ei5AKwn3v1epXB9Cg", baseUrl: "wss://csapi.xdev.stream/v1/gateway/h5?token=", sign: "")
        lib.callWebsocket()
        lib.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let btSend = UIButton()
        btSend.frame = CGRect(x: 100, y: 200, width: 200, height: 200)
        btSend.setTitleColor(UIColor.systemRed, for: UIControlState.normal)
        btSend.setTitle("Send", for: UIControlState.normal)
        self.view.addSubview(btSend)
        btSend.addTarget(self, action:#selector(btSendAction), for:.touchUpInside)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
       // lib.sendHeartBeat()
    }
    
    @objc func btSendAction3(){
        
        //tvChatView.text.append("\n发送一个视频！ VideoUrl: https://www.youtube.com/watch?v=wbFHmblw9J8\n\n")
        //lib.sendMessage(msg: "https://www.youtube.com/watch?v=wbFHmblw9J8", type: .msgVideo)
//        tvChatView.text.append("\n回复信息:")
        //lib.sendMessage(msg: "https://www.youtube.com/watch?v=wbFHmblw9J8", type: .msgVideo, replyMsgId: lastMessage?.msgID ?? 0)
        
        tvChatView.text.append("\n删除信息:")
        lib.deleteMessage(msgId: lastMessage?.msgID ?? 0)//493660676493934594
    }
    
    @objc func btSendAction(){
        
//        if !send && lastMessage != nil{
//            lib.operateMsg(msg: lastMessage!, payloadId: payLoadId, act: .csdeleteMsg)
//            return
//        }else{
            let txtMsg = "你好！需要什么帮助？\n"
            //lib.sendMessage(msg: txtMsg, type: .msgText)
            //lib.sendHeartBeat()
            
            if let cMSG = lib.sendingMsg{
                var time = displayLocalTime(from: cMSG.msgTime.date)
                print(time)
                time = displayLocalTime(from:  Double(cMSG.msgTime.seconds))
                print(time)
            }
        
                tvChatView.text.append("\n发送一个视频！ VideoUrl: https://www.youtube.com/watch?v=wbFHmblw9J8\n\n")
                lib.sendMessage(msg: "https://www.youtube.com/watch?v=wbFHmblw9J8", type: .msgVideo)
        
        if let msg = lastMessage{
            lib.resendMsg(msg: msg, payloadId: payLoadId)
        }
        
            //Send Image
            //lib.sendMessageImage(url: "https://www.bing.com/th?id=OHR.ZebraTrio_ROW8661058210_1920x1080.jpg&rf=LaDigue_1920x1080.jpg")
        //}
        send = false
    }
    
    //用于转换服务器的时间是GMT+0
    func displayLocalTime(from timestamp: TimeInterval) -> String {
        let gmtDate = Date(timeIntervalSince1970: timestamp)
        let zone = NSTimeZone.system // 获得系统的时区
        let time = zone.secondsFromGMT(for: gmtDate)// 以秒为单位返回当前时间与系统格林尼治时间的差
        let msgDate = gmtDate.addingTimeInterval(TimeInterval(time))// 然后把差的时间加上,就是当前系统准确的时间
        
        if Calendar.current.isDateInToday(gmtDate) {
            return String(format: "%.2d", msgDate.hour) + ":" + String(format: "%.2d", msgDate.minute)
        }
        else if Calendar.current.isDateInYesterday(msgDate) {
            return "昨天 " + String(format: "%.2d", msgDate.hour) + ":" + String(format: "%.2d", msgDate.minute)
        }
        else if msgDate.isThisYear() {
            return "\(msgDate.month)月\(msgDate.day)日"
        }
        else {
            return "\(msgDate.year)/\(msgDate.month)/\(msgDate.day)"
        }
    }
    
    //把任何服务器时间转换为本地时间，很神奇的一个方案
    func displayLocalTime(from msgDate: Date) -> String {
         let calendar = Calendar.current
         let hour = calendar.component(.hour, from: msgDate)
         let minutes = calendar.component(.minute, from: msgDate)
         
        if Calendar.current.isDateInToday(msgDate) {
            return String(format: "%.2d", hour) + ":" + String(format: "%.2d", minutes)
        }
        else if Calendar.current.isDateInYesterday(msgDate) {
            return "昨天 " + String(format: "%.2d", msgDate.hour) + ":" + String(format: "%.2d", msgDate.minute)
        }
        else if msgDate.isThisYear() {
            return "\(msgDate.month)月\(msgDate.day)日"
        }
        else {
            return "\(msgDate.year)/\(msgDate.month)/\(msgDate.day)"
        }
    }
    
    deinit {
        lib.disConnect()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        //lib.sendHeartBeat()
    }
}

