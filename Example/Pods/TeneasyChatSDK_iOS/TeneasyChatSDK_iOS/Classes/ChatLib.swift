import Foundation
import Starscream
import SwiftProtobuf
import UIKit
// import Toast

// https://swiftpackageregistry.com/daltoniam/Starscream
// https://www.kodeco.com/861-websockets-on-ios-with-starscream
public protocol teneasySDKDelegate : AnyObject{
    //收到消息
    func receivedMsg(msg: CommonMessage)
    //消息回执
    func msgReceipt(msg: CommonMessage, payloadId: UInt64, errMsg: String?)
    //系统消息，用于显示Tip
    //func systemMsg(msg: String)
    func systemMsg(result: Result)
    //连接状态
    func connected(c: Gateway_SCHi)
    //客服更换回调
    func workChanged(msg: Gateway_SCWorkerChanged)
}

/*
 extension teneasySDKDelegate {
     func receivedMsg2(msg: EasyMessage) {
         /* return a default value or just leave empty */
     }
 }*/

open class ChatLib {
    public private(set) var text = "Teneasy Chat SDK 启动"
    private var baseUrl = "wss://csapi.xdev.stream/v1/gateway/h5?token="
    var websocket: WebSocket?
    var isConnected = false
    // weak var delegate: WebSocketDelegate?
    public weak var delegate: teneasySDKDelegate?
    open var payloadId: UInt64 = 0
    public var sendingMsg: CommonMessage?
    private var msgList: [UInt64: CommonMessage] = [:]
    var chatId: Int64 = 0
    var token: String = ""
    var session = Session()
    
    private var myTimer: Timer?
    private var sessionTime: Int = 0
    //var chooseImg: UIImage?
    private var beatTimes = 0
    private var maxSessionMinutes = 90
    var workId: Int32 = 5
    private var replyMsgId: Int64 = 0
    private var userId: Int32 = 0
    private var sign: String = ""
    private var cert: String = ""
    //wss://csapi.xdev.stream/v1/gateway/h5?token=CH0QARji9w4gogEor4i7mc0x.PKgbr4QAEspllbvDx7bg8RB_qDhkWozBKgWtoOPfVmlTfPbd8nyBZk9uyQvjj-3F6MXHyE9GmZvj0_PRTm_tDA&userid=1125324&ty=104&dt=1705583047601&sign=&rd=1019737
    
//   public enum MsgType{
//       case Text
//       case Image
//       case Video
//       case Audio
//    }
    
    public init() {}

    public init(userId:Int32, cert: String, baseUrl: String, sign: String, chatId: Int64 = 0) {
        self.chatId = chatId
        self.cert = cert
        self.baseUrl = baseUrl
        self.userId = userId
        self.sign = sign
        beatTimes = 0
        print(text)
    }
    
//    public init(session: Session) {
//        self.session = session
//    }

    public func callWebsocket() {
        let rd = Int.random(in: 1000000..<9999999)
        let date = Date()
        let dt = Int(date.timeIntervalSince1970 * 1000)
        let urlStr = "\(baseUrl + cert)&userid=\(self.userId)&ty=\(Api_Common_ClientType.userApp.rawValue)&dt=\(dt)&sign=\(self.sign)&rd=\(rd)"
        guard let url = URL(string: urlStr) else { return }
        let request = URLRequest(url: url)
        // request.setValue("chat,superchat", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        websocket = WebSocket(request: request)
        websocket?.request.timeoutInterval = 5 // Sets the timeout for the connection
        websocket?.delegate = self
        websocket?.connect()
        
        /* 添加header的办法
         request.setValue("someother protocols", forHTTPHeaderField: "Sec-WebSocket-Protocol")
         request.setValue("14", forHTTPHeaderField: "Sec-WebSocket-Version")
         request.setValue("chat,superchat", forHTTPHeaderField: "Sec-WebSocket-Protocol")
         request.setValue("Everything is Awesome!", forHTTPHeaderField: "My-Awesome-Header")
         */
        startTimer()
        print("call web socket")
    }
    
    public func reConnect(){
        if websocket != nil{
            websocket?.connect()
        }
    }
    
    deinit {
        disConnect()
    }
    
    func startTimer() {
       stopTimer()
        myTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updataSecond), userInfo: nil, repeats: true)
        myTimer!.fire()
    }

    
    @objc func updataSecond() {
        sessionTime += 1
        if sessionTime%5 == 0{//每隔8秒发送一个心跳
            beatTimes += 1
            //print("sending beat \( beatTimes)")
            sendHeartBeat()
        }
        
        if sessionTime > maxSessionMinutes * 60{//超过最大会话，停止发送心跳
            stopTimer()
        }
    }

    func stopTimer() {
        if myTimer != nil {
            myTimer!.invalidate() // 销毁timer
            myTimer = nil
        }
    }
    
    public func sendMessage(msg: String, type: CommonMessageFormat, replyMsgId: Int64? = 0) {
        self.replyMsgId = replyMsgId ?? 0
        // 发送信息的封装，有四层
        // payload -> CSSendMessage -> common message -> CommonMessageContent
        switch type{
        case .msgText:
            sendTextMessage(txt: msg)
        case .msgVoice:
            sendVideoMessage(url: msg)
        case .msgImg:
            sendImageMessage(url: msg)
        case .msgVideo:
            sendVideoMessage(url: msg)
        case .msgFile:
            sendFileMessage(url: msg)
        default:
            sendTextMessage(txt: msg)
        }

        
        doSend()
    }
    
    public func deleteMessage(msgId: Int64){
        // 第一层
        //var content = CommonMessageContent()
        //content.data = "d"
        
        var msg = CommonMessage()
        //msg.content = content
        msg.chatID = 0//2692944494609
        msg.msgID = msgId
        msg.msgOp = .msgOpDelete
        // 临时放到一个变量
        sendingMsg = msg
        
        doSend()
    }
    
    private func sendTextMessage(txt: String){
        // 第一层
        var content = CommonMessageContent()
        content.data = txt
        
        // 第二层, 消息主题
        var msg = CommonMessage()
        msg.content = content
        msg.sender = 0
        msg.replyMsgID = self.replyMsgId
        msg.chatID = chatId
        msg.payload = .content(content)
        msg.worker = workId
        
        msg.msgTime.seconds = Int64(Date().timeIntervalSince1970)
        
        // 临时放到一个变量
        sendingMsg = msg
    }
    
    private func sendImageMessage(url: String){
        // 第一层
        var content = CommonMessageImage()
        content.uri = url
        
        // 第二层, 消息主题
        var msg = CommonMessage()
        msg.image = content
        msg.sender = 0
        msg.replyMsgID = self.replyMsgId
        msg.chatID = chatId
        msg.payload = .image(content)
        msg.worker = workId
        msg.msgTime.seconds = Int64(Date().timeIntervalSince1970)
        
        // 临时放到一个变量
        sendingMsg = msg
    }
    
    private func sendVideoMessage(url: String){
        // 第一层
        var content = CommonMessageVideo()
        content.uri = url
        
        // 第二层, 消息主题
        var msg = CommonMessage()
        msg.video = content
        msg.sender = 0
        msg.replyMsgID = self.replyMsgId
        msg.chatID = chatId
        msg.payload = .video(content)
        msg.worker = workId
        msg.msgTime.seconds = Int64(Date().timeIntervalSince1970)
        
        // 临时放到一个变量
        sendingMsg = msg
    }
    
    private func sendAudioMessage(url: String){
        // 第一层
        var content = CommonMessageAudio()
        content.uri = url
        
        // 第二层, 消息主题
        var msg = CommonMessage()
        msg.audio = content
        msg.sender = 0
        msg.replyMsgID = self.replyMsgId
        msg.chatID = chatId
        msg.payload = .audio(content)
        msg.worker = 5
        msg.msgTime.seconds = Int64(Date().timeIntervalSince1970)
        
        // 临时放到一个变量
        sendingMsg = msg
    }
    
    private func sendFileMessage(url: String){
        // 第一层
        var content = CommonMessageFile()
        content.uri = url
        
        // 第二层, 消息主题
        var msg = CommonMessage()
        msg.file = content
        msg.sender = 0
        msg.replyMsgID = self.replyMsgId
        msg.chatID = chatId
        msg.payload = .file(content)
        msg.worker = 5
        msg.msgTime.seconds = Int64(Date().timeIntervalSince1970)
        
        // 临时放到一个变量
        sendingMsg = msg
    }
    
    private func doSend(payload_Id: UInt64 = 0){
       guard let msg = sendingMsg else {
            return
        }
        
        // 第三层
        var cSendMsg = Gateway_CSSendMessage()
        cSendMsg.msg = msg
        // Serialize to binary protobuf format:
        let cSendMsgData: Data = try! cSendMsg.serializedData()
        
        // 第四层
        var payLoad = Gateway_Payload()
        payLoad.data = cSendMsgData
        payLoad.act = .cssendMsg
        
        //payload_id != 0的时候，可能是重发，重发不需要+1
        if (sendingMsg?.msgOp == .msgOpPost && payload_Id == 0){
            payloadId += 1
            print("payloadID:" + String(payloadId))
            msgList[payloadId] = msg
        }
        
        if payload_Id != 0{
            payLoad.id = payload_Id
        }else{
            payLoad.id = payloadId
        }
        let binaryData: Data = try! payLoad.serializedData()
        send(binaryData: binaryData)
    }
    
   public func resendMsg(msg: CommonMessage, payloadId: UInt64) {
        // 临时放到一个变量
        sendingMsg = msg
        doSend(payload_Id: payloadId)
    }
    
    /// 对消息进行更新，删除，重发等操作
    /// - Parameters:
    ///   - msg: 是一个CommonMessage
    ///   - payloadId: 消息列表中的payloadId
    ///   - act: 操作动作枚举
    /*public func operateMsg(msg: CommonMessage, payloadId: UInt64, act: Gateway_Action){
        // 第三层
        var cSendMsg = Gateway_CSSendMessage()
        
        
        cSendMsg.msg = msg
        var cSendMsgData: Data? = nil
        do{
            cSendMsgData = try cSendMsg.serializedData()
        }catch{
            
        }
        guard let cMsg = cSendMsgData else { return }
        
        // 第四层
        var payLoad = Gateway_Payload()
        payLoad.data = cMsg
        payLoad.act = act
        self.payloadId += 1
        payLoad.id = payloadId
        
        var cbinaryData: Data? = nil
        do {
            cbinaryData = try payLoad.serializedData()
        }catch{
            
        }
        guard let binaryData = cbinaryData else { return }
        // 临时放到一个变量
        //sendingMsg = msg
        send(binaryData: binaryData)
    }*/
    
    /*private func resendMsg(msg: CommonMessage, payloadId: Int) {
        // 第三层
        var cSendMsg = Gateway_CSSendMessage()
        cSendMsg.msg = msg
        // Serialize to binary protobuf format:
        let cSendMsgData: Data = try! cSendMsg.serializedData()
        
        // 第四层
        var payLoad = Gateway_Payload()
        payLoad.data = cSendMsgData
        payLoad.act = .cssendMsg
        self.payloadId = UInt64(payloadId)
        payLoad.id = self.payloadId!
        let binaryData: Data = try! payLoad.serializedData()
        
        // 临时放到一个变量
        sendingMsg = msg
        
        send(binaryData: binaryData)
    }*/
    
    private func sendHeartBeat() {
        let array: [UInt8] = [0]

        let myData = Data(bytes: array)
        send(binaryData: myData)
        //print("sending heart beat")
    }
    
    private func send(binaryData: Data) {
        var result = Result()
        if !isConnected {
            print("断开了")
            if sessionTime > maxSessionMinutes * 60 {
                result.Code = 1005
                result.Message = "会话超过\(maxSessionMinutes)分钟，需要重新进入"
                delegate?.systemMsg(result: result)
                failedToSend()
            } else {
                callWebsocket()
                result.Code = 1004
                //result.Message = "会话超过\(maxSessionMinutes)分钟，需要重新进入"
                result.Message = "Socket 出错"
                delegate?.systemMsg(result: result)
                failedToSend()
            }
        } else {
            if sessionTime > maxSessionMinutes * 60 {
                result.Code = 1006
                result.Message = "会话超过\(maxSessionMinutes)分钟，需要重新进入"
                delegate?.systemMsg(result: result)
                failedToSend()
            } else {
                websocket?.write(data: binaryData, completion: ({
                    print("msg sent")
                }))
            }
        }
    }
    
    private func failedToSend(){
        if let msg = sendingMsg{
            delegate?.msgReceipt(msg: msg, payloadId: payloadId, errMsg: nil)
            sendingMsg = nil
        }
    }
    
    public func disConnect() {
        stopTimer()
        if let socket = websocket {
            socket.disconnect()
            socket.delegate = nil
            websocket = nil
        }
        print("通信SDK 断开连接")
    }
    
    private func serilizeSample() {
        var info = CommonPhoneNumber()
        info.countryCode = 65
        info.nationalNumber = 99999
        
        // Serialize to binary protobuf format:
        let binaryData: Data = try! info.serializedData()

        // Deserialize a received Data object from `binaryData`
        let decodedInfo = try? CommonPhoneNumber(serializedData: binaryData)

        // Serialize to JSON format as a Data object
        let jsonData: Data = try! info.jsonUTF8Data()

        // Deserialize from JSON format from `jsonData`
        let receivedFromJSON = try! CommonPhoneNumber(jsonUTF8Data: jsonData)
    }
}

// MARK: - WebSocketDelegate

extension ChatLib: WebSocketDelegate {
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("got some text: \(text)")
    }

    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        var result = Result()
        switch event {

        case .connected:
            // print("connected" + headers.description)
            var result = Result()
            result.Code = 0
            result.Message = "已连接上"
            delegate?.systemMsg(result: result)
            
            isConnected = true
        case .disconnected(let reason, let closeCode):
            print("disconnected \(reason) \(closeCode)")
            isConnected = false
            result.Code = 1001
            result.Message = "已断开通信"
            delegate?.systemMsg(result: result)
            failedToSend()
        case .text(let text):
            print("received text: \(text)")
        case .binary(let data):
            if data.count == 1 {
                print("在别处登录了 A")
                if let d = String(data: data, encoding: .utf8) {
                    // Attempt to convert the data to a UTF-8 string, and if successful, execute the block inside the 'if' statement.
     
                    if d.contains("2") {
                        // Check if the string contains the character "2".
                        result.Code = 1002
                        result.Message = "无效的Token"
                        delegate?.systemMsg(result: result) // Delegate a system message if the condition is true.
                    } else {
                        result.Code = 1003
                        result.Message = "在别处登录了 B"
                        delegate?.systemMsg(result: result) // Delegate a different system message if the condition is false.
                    }
                    
                    print(d.description) // Print the resulting string.
                    isConnected = false // Set the 'isConnected' variable to false.
                }
            } else {
                guard let payLoad = try? Gateway_Payload(serializedData: data) else { return }
                let msgData = payLoad.data
//                if sendingMsg?.msgOp != .msgOpDelete{
//                    payloadId = payLoad.id
//                }
                print("new payloadID:" + String(payloadId))
                if payLoad.act == .screcvMsg {
                    let scMsg = try? Gateway_SCRecvMessage(serializedData: msgData)
                    var msg = scMsg?.msg
                    if msg != nil {
                        if (msg!.msgOp == .msgOpDelete){
                            //msg?.msgID = -1
                            print("对方撤回了消息 payloadID:" + String(payLoad.id))
                            delegate?.msgReceipt(msg: msg!, payloadId: payLoad.id, errMsg: nil)
                        }else{
                            delegate?.receivedMsg(msg: msg!)
                        }
                    }
                } else if payLoad.act == .schi { // 连接成功后收到的信息，会返回clientId, Token
                    if let msg = try? Gateway_SCHi(serializedData: msgData) {
                        print("chatID:" + String(msg.id))
                        payloadId = payLoad.id
                        delegate?.connected(c: msg)
                        print("初始payloadId:" + String(payloadId))
                        print(msg)
                    }
                } else if payLoad.act == .scworkerChanged {
                    if let msg = try? Gateway_SCWorkerChanged(serializedData: msgData) {
                        delegate?.workChanged(msg: msg)
                        print(msg)
                    }
                }
                
                /*
                 else if(payLoad.act == GAction.Action.ActionSCDeleteMsgACK) {
                                 val msg = GGateway.SCSendMessage.parseFrom(msgData)
                                 Log.i(TAG, "删除回执收到：消息ID: ${msg.msgId}")
                             }  else if(payLoad.act == GAction.Action.ActionSCDeleteMsg) {
                                 val msg = GGateway.SCRecvMessage.parseFrom(msgData)
                                 Log.i(TAG, "对方删除了消息：消息ID: ${msg.msg.msgId}")
                             }
                 */
                else if payLoad.act == .scdeleteMsgAck {
                    let cMsg = try? Gateway_CSSendMessage(serializedData: msgData)
                    print("删除消息回执A，payloadId:\(payLoad.id) msgId:\(cMsg?.msg.msgID ?? 0)")
                    //cMsg?.msg.msgID = -1
                    if let msg = cMsg?.msg{
                        if msgList[payLoad.id] != nil{
                            print("删除成功");
                            
                            delegate?.msgReceipt(msg: msg, payloadId: payLoad.id, errMsg: nil)
                        }
                        print(msg)
                    }
                }
                else if payLoad.act == .scdeleteMsg {
                    let cMsg = try? Gateway_CSRecvMessage(serializedData: msgData)
                    if let cMsg = cMsg{
                        //delegate?.msgReceipt(msg: msg, payloadId: payLoad.id)
                        // 第二层, 消息主题
                        var msg = CommonMessage()
                        //msg.msgID = -1
                        msg.msgID = cMsg.msgID
                        msg.msgOp = .msgOpDelete
                        msg.chatID = cMsg.chatID
                        delegate?.msgReceipt(msg: msg, payloadId: payLoad.id, errMsg: nil)
                        print(msg)
                    }
                }
                else if payLoad.act == .forward {
                    let msg = try? Gateway_CSForward(serializedData: msgData)
                    print(msg!)
                } else if payLoad.act == .scsendMsgAck { // 服务器告诉此条信息是否发送成功
                    if let scMsg = try? Gateway_SCSendMessage(serializedData: msgData) {
                        print("消息回执B，payloadId:\(payLoad.id) msgId:\(scMsg.msgID)")
                        //if sendingMsg != nil {
                        // sendingMsg?.msgID = scMsg.msgID // 发送成功会得到消息ID
                        // sendingMsg?.msgTime = scMsg.msgTime
                        
                        if msgList[payLoad.id] != nil{
                            var cMsg = msgList[payLoad.id]
                            cMsg?.msgID = scMsg.msgID
                            cMsg?.msgTime = scMsg.msgTime
                        
                            if cMsg != nil{
                                if (sendingMsg?.msgOp == .msgOpDelete){
                                    //cMsg!.msgID = -1
                                    cMsg!.msgOp = .msgOpDelete
                                    print("删除消息成功");
                                }else if(!scMsg.errMsg.isEmpty){
                                    cMsg!.msgID = -2
                                }
                                delegate?.msgReceipt(msg: cMsg!, payloadId: payLoad.id, errMsg: scMsg.errMsg)
                            }
                            //print(scMsg)
                            //sendingMsg = nil
                            chatId = scMsg.chatID
                        }
                        //}
                    }
                } else {
                    print("received data: \(data)")
                }
            }

        case .pong(let pongData):
            print("received pong: \(String(describing: pongData))")
        case .ping(let pingData):
            print("received ping: \(String(describing: pingData))")
        case .error(let error):
            // self.delegate?.connected(c: false)
            print("socket error \(String(describing: error))")
            
            var result = Result()
            result.Code = 1004
            result.Message = "Socket 出错"
            delegate?.systemMsg(result: result)
            failedToSend()
            isConnected = false
        case .viabilityChanged:
            print("viabilityChanged")
        case .reconnectSuggested:
            print("reconnectSuggested")
        case .cancelled:
            var result = Result()
            result.Code = 1007
            result.Message = "已取消连接"
            delegate?.systemMsg(result: result)
            failedToSend()
            print("cancelled")
            isConnected = false
        }
    }
    
    ///显示一个文本消息，无需经过服务器
    public func composeALocalMessage(textMsg: String) -> CommonMessage {
        // 第一层
        var content = CommonMessageContent()
        content.data = textMsg
        
        // 第二层, 消息主题
        var msg = CommonMessage()
        msg.content = content
        msg.sender = 0
        msg.chatID = chatId
        msg.payload = .content(content)
        msg.worker = 5
        msg.msgTime.seconds = Int64(Date().timeIntervalSince1970)
        
        return msg
    }
    /* public func toastHello(vc : UIViewController){
         let alert = UIAlertController(title: "你好", message: "Message", preferredStyle: UIAlertController.Style.actionSheet)
         alert.addAction(UIAlertAction(title: "Click", style: UIAlertAction.Style.default, handler: { _ in
           
         }))
         vc.present(alert, animated: true, completion: nil)
     } */
}
