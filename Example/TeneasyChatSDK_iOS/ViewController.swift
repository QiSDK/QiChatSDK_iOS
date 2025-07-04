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

class ViewController: UIViewController, teneasySDKDelegate, LineDetectDelegate, readTextDelegate, UploadListener {
    func uploadSuccess(paths: TeneasyChatSDK_iOS.Urls, filePath: String, size: Int) {
        print("uploadSuccess")
    }
    
    func updateProgress(progress: Int) {
        print("upload \(progress)%")
    }
    
    func uploadFailed(msg: String) {
       // print("upload failed")
    }
    
    func receivedText(msg: String) {
        tvChatView.text.append(msg)
        appendMsgScroll()
    }
    
    
    @IBOutlet weak var tvChatView: UITextView!
    @IBOutlet weak var tvInputText: UITextView!
    @IBOutlet weak var etShangHu: UITextField!
    
    var lib = ChatLib.shared
    var payLoadId: UInt64 = 0
    var lastMessage: CommonMessage? = nil
    var baseUrl: String? = ""
    
    var send = false
    func connected(c: Gateway_SCHi) {
        print("token:\(c.token)")
        let autoMsg = lib.composeALocalMessage(textMsg: "你好，我是客服小福")
        appendMsg(msg: autoMsg.content.data)
        
        if c.workerID != 0{
            tvChatView.text.append("\n已连接上！ WorkId:\(c.workerID)\n\n")

        }
       // tvChatView.text.append("\n发送图片！ ImageUrl: https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQQKV-3KPDbUgVdqjfEb3HK_SvGjcPYVl7n7KGCwBL6&s\n\n")
       // lib.sendMessage(msg: "/230/session11253244/1716645412_39864.png", type: .msgImg, consultId: 1)
        print(c.workerID)
        
        appendMsgScroll()
    }
    
    //收到对方的消息
    func receivedMsg(msg: CommonMessage) {
        print(msg)
        if (msg.msgSourceType == CommonMsgSourceType.mstAi){
            print("AI消息")
        }
        
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
        
        appendMsgScroll()
    }
    
    //消息删除成功
    func msgDeleted(msg: CommonMessage, payloadId : UInt64 = 0, errMsg: String?){
        print("消息删除成功\(msg.msgID)")
        appendMsg(msg: "消息删除成功\(msg.msgID)")
    }
    
    //发送的消息收到回执
    func msgReceipt(msg: CommonMessage, payloadId : UInt64 = 0, errMsg: String?){
        var myMsg = ""
        print("收到回执\(payloadId)")
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
        appendMsgScroll()
    }
    
    //收到的系统消息
    func systemMsg(result: Result){
        appendMsg(msg: result.Message)
    }
    
    func appendMsg(msg: String){
        tvChatView.text.append(msg + "\n" +  Date().getFormattedDate(format: "HH:mm") + "\n\n")
        //cpf
    }
    
    func appendMsgScroll(){
        let bottomOffset = CGPoint(x: 0, y: tvChatView.contentSize.height - tvChatView.bounds.height)
        tvChatView.setContentOffset(bottomOffset, animated: true) // Scroll to the bottom
    }
    
    func workChanged(msg: Gateway_SCWorkerChanged){
        tvChatView.text.append(msg.workerName)
    }
    
    @IBAction public func readText(){
        tvChatView.text = ""
        let lines = tvInputText.text.split(separator: ",").map { String($0) }
        //let lines = ["https://qlqiniu.quyou.tech/gw3config.txt","https://ydqlacc.weletter05.com/gw3config.txt"]
        let lib = ReadTxtLib(lines, delegate: self)
        lib.readText()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        tvInputText.isEditable = true
        tvInputText.isUserInteractionEnabled = true
        
        tvChatView.isUserInteractionEnabled = true
        tvChatView.isScrollEnabled = true
        
             let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

            //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
            //tap.cancelsTouchesInView = false

            view.addGestureRecognizer(tap)
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func TestLine(){
        
        if ((etShangHu.text ?? "").isEmpty){
            tvChatView.text.append("请输入商户号\n\n")
            appendMsgScroll()
            return;
        }

        
        let shangHu: Int? = Int(etShangHu.text ?? "0")
        
        //https://qlqiniu.quyou.tech/gw3config.txt
    //https://ydqlacc.weletter05.com/gw3config.txt
        //let lines = ["https://dtest/gw3config.txt", "https://qlqiniu.quyou.tech/gw3config.txt", "https://ddtest/gw3config.txt",  "https://ydqlacc.weletter05.com/gw3config.txt", "https://ddtest/gw3config.txt", "https://ddtest.com/gw3config.txt", "https://qlqiniu.quyou.tech/gw3config.txt","https://ydqlacc.weletter05.com/gw3config.txt", "https://ddtest.net/gw3config.txt"]
        
        //"https://ydqlacc.weletter05.com/gw3config.txt",
        //生产的线路
        //let lines = ["https://qlqiniu.quyou.tech/gw1config.txt","https://ydqlacc.weletter05.com/gw1config.txt"]
        
        //测试的线路
        //let lines = ["https://qlqiniu.quyou.tech/gw3config.txt","https://ydqlacc.weletter05.com/gw3config.txt","https://sdf.tvlimufz.com/gw3config.txt"]
        
        //let lines = tvInputText.text.split(separator: ",").map { String($0) }
    //httos://csh5.hfxg.xyz,https://csapi.xdev.stream
        let lines = "https://wcsapi.qixin14.xyz,https://csapi.hfxg.xyz"
        
        //let lines = "https://61.184.8.23:7040,https://csapi.hfxg.xyz,https://csapi04.yxvtyk.com,https://ikeapi.qlbig29.xyz,https://csapi.qlbig29.xyz,https://csapi.qlbig30.xyz"
        //let lines = "https://61.184.8.23:7040"
        let lineLib = LineDetectLib(lines, delegate: self, tenantId: shangHu ?? 0)
        
        lineLib.getLine()
    }
    
    func useTheLine(line: String){
        tvChatView.text.append("wss " + line + "\n")
        appendMsgScroll()
        initSDK(baseUrl: line)
    }
    
    func lineError(error: Result){
        tvChatView.text.append(error.Message + "\n")
    }
    
    func initSDK(baseUrl: String){
        tvChatView.text.append("teneasy chat sdk 初始化\n正在连接。。。\n")
        let wssUrl = "wss://" + baseUrl + "/v1/gateway/h5?"
        if lib.payloadId == 0{
            print("initSDK 初始化SDK")
            lib.myinit(userId: 666688, cert: "COYBEAUYASDyASiG2piD9zE.te46qua5ha2r-Caz03Vx2JXH5OLSRRV2GqdYcn9UslwibsxBSP98GhUKSGEI0Z84FRMkp16ZK8eS-y72QVE2AQ", token: "", baseUrl: wssUrl, sign: "9zgd9YUc", custom: "{\"username\":\"xiaoming\"}", maxSessionMinutes: 20)
            
            lib.callWebsocket()
            lib.delegate = self
        }else{
            print("initSDK 重新连接")
            lib.reConnect()
            lib.delegate = self
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        let btSend = UIButton()
//        btSend.frame = CGRect(x: 100, y: 200, width: 200, height: 200)
//        btSend.setTitleColor(UIColor.systemRed, for: UIControlState.normal)
//        btSend.setTitle("Send", for: UIControlState.normal)
//        self.view.addSubview(btSend)
//        btSend.addTarget(self, action:#selector(btSendAction), for:.touchUpInside)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
       // lib.sendHeartBeat()
    }
    
    @objc func btSendAction(){
        
        //tvChatView.text.append("\n发送一个视频！ VideoUrl: https://www.youtube.com/watch?v=wbFHmblw9J8\n\n")
        //lib.sendMessage(msg: "https://www.youtube.com/watch?v=wbFHmblw9J8", type: .msgVideo)
//        tvChatView.text.append("\n回复信息:")
        //lib.sendMessage(msg: "https://www.youtube.com/watch?v=wbFHmblw9J8", type: .msgVideo, replyMsgId: lastMessage?.msgID ?? 0)
        
        tvChatView.text.append("how are u!")
        //lib.sendMessage(msg: "how are u!", type: .msgText, consultId: 1)
        lib.sendMessage(msg: "/session/tenant_230/20250304/Documents/3137343130393736323137353066696c65d41d8cd98f00b204e9800998ecf8427e_1741097622234561429.pdf", type: .msgFile, consultId: 1, fileSize: 1989, fileName: "123.pdf")
        
        //UploadUtil(listener: self, filePath: "dd", fileData: Data(), xToken: "dd", baseUrl: "").upload()
        
        let d = uploadProgress;
  
        
        //tvChatView.text.append("\n删除信息:\(lastMessage?.msgID ?? 0)")
        //lib.deleteMessage(msgId: lastMessage?.msgID ?? 0)//493660676493934594
    }
    
    @IBAction func btSendAction3(){
        
//        if !send && lastMessage != nil{
//            lib.operateMsg(msg: lastMessage!, payloadId: payLoadId, act: .csdeleteMsg)
//            return
//        }else{
            //let txtMsg = "你好！需要什么帮助？\n"
            //lib.sendMessage(msg: txtMsg, type: .msgText, consultId: 1)
            
            if let cMSG = lib.sendingMsg{
                var time = displayLocalTime(from: cMSG.msgTime.date)
                print(time)
                time = displayLocalTime(from:  Double(cMSG.msgTime.seconds))
                print(time)
            }
        
                //tvChatView.text.append("\n发送一个视频！ VideoUrl: https://www.youtube.com/watch?v=wbFHmblw9J8\n\n")
                //lib.sendMessage(msg: "https://www.youtube.com/watch?v=wbFHmblw9J8", type: .msgVideo, consultId: 1)
        
//        if let msg = lastMessage{
//            lib.resendMsg(msg: msg, payloadId: payLoadId)
//        }
        //Send Image
        lib.sendMessage(msg: "/230/session11253244/1716645412_39864.png", type: .msgImg, consultId: 1)
    
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

