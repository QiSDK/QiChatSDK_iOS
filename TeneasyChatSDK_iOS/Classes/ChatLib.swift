import Foundation
import Starscream
import SwiftProtobuf
import UIKit
// import Toast

// https://swiftpackageregistry.com/daltoniam/Starscream
// https://www.kodeco.com/861-websockets-on-ios-with-starscream
open class ChatLib: NetworkManagerDelegate {
    func networkRechabilityStatus(status: NetworkManagerStatus) {
        networkQueue.async { [weak self] in
            guard let self = self else { return }
            switch status {
                        case .notReachable:
                            debugPrint("ChatLib:[RECHABILITY] The network is not reachable")
                            self.disConnected(code: 1009, msg: "网络中断了")
                        case .unknown :
                            debugPrint("ChatLib:[RECHABILITY] It is unknown whether the network is reachable")
                        case .ethernetOrWiFi:
                            debugPrint("ChatLib:[RECHABILITY] The network is reachable over the WiFi connection")
                        case .cellular:
                            debugPrint("ChatLib:[RECHABILITY] The network is reachable over the WWAN connection")
                    }
        }
    }
    
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
    public var token: String = ""
    var session = Session()
    
    private var dispatchTimer: DispatchSourceTimer?
    private var sessionTime: Int = 0
    //var chooseImg: UIImage?
    private var beatTimes = 0
    private var maxSessionMinutes = 90000000//相当于不设置会话超时时间 //90
    var workId: Int32 = 5
    private var replyMsgId: Int64 = 0
    private var userId: Int32 = 0
    private var custom: String = ""
    private var sign: String = ""
    private var cert: String = ""
    private var networkManager = NetworkManager()
    public static let shared = ChatLib()
    private var withAutoReply: CommonWithAutoReply?
    
    // DispatchQueue for thread management
    private let websocketQueue = DispatchQueue(label: "com.teneasy.websocket", qos: .userInitiated)
    private let messageQueue = DispatchQueue(label: "com.teneasy.message", qos: .userInitiated)
    private let timerQueue = DispatchQueue(label: "com.teneasy.timer", qos: .utility)
    private let networkQueue = DispatchQueue(label: "com.teneasy.network", qos: .background)
    private let stateQueue = DispatchQueue(label: "com.teneasy.state")

    private var pendingPayloads: [(id: UInt64?, data: Data)] = []
    private var isConnecting = false

    private var consultId: Int64 = 0
    private var fileSize: Int32 = 0
    private var fileName: String = ""

    public init() {}

    public func myinit(userId:Int32, cert: String, token: String, baseUrl: String, sign: String, chatId: Int64 = 0, custom: String = "", maxSessionMinutes: Int = 90000000) {
        self.chatId = chatId
        self.cert = cert
        self.baseUrl = baseUrl
        self.userId = userId
        self.sign = sign
        self.token = token
        self.custom = custom
        self.maxSessionMinutes = maxSessionMinutes
        beatTimes = 0
        debugPrint(text)
        
        networkManager.delegate = self
               networkManager.startNetworkReachabilityObserver()
    }

   public func callWebsocket() {
        stateQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isConnecting || self.isConnected { return }
            self.isConnecting = true
            self.enqueueWebsocketConnection()
        }
    }

    private func enqueueWebsocketConnection() {
        websocketQueue.async { [weak self] in
            guard let self = self else { return }

            let rd = Int.random(in: 1000000..<9999999)
            let date = Date()
            let dt = Int(date.timeIntervalSince1970 * 1000)
            
            // Safe URL construction using URLComponents to prevent injection
            guard var urlComponents = URLComponents(string: self.baseUrl) else {
                self.stateQueue.async { [weak self] in
                    self?.isConnecting = false
                }
                debugPrint("ChatLib: Invalid base URL")
                return
            }
            
            // Safely add query parameters
            var queryItems: [URLQueryItem] = []
            queryItems.append(URLQueryItem(name: "cert", value: self.cert))
            queryItems.append(URLQueryItem(name: "token", value: self.token))
            queryItems.append(URLQueryItem(name: "userid", value: String(self.userId)))
            queryItems.append(URLQueryItem(name: "custom", value: self.custom))
            queryItems.append(URLQueryItem(name: "ty", value: String(Api_Common_ClientType.userAppIos.rawValue)))
            queryItems.append(URLQueryItem(name: "dt", value: String(dt)))
            queryItems.append(URLQueryItem(name: "sign", value: self.sign))
            queryItems.append(URLQueryItem(name: "rd", value: String(rd)))
            
            urlComponents.queryItems = (urlComponents.queryItems ?? []) + queryItems
            
            guard let url = urlComponents.url else {
                self.stateQueue.async { [weak self] in
                    self?.isConnecting = false
                }
                debugPrint("ChatLib: Failed to construct URL")
                return
            }
            
            // Don't log the full URL to avoid exposing sensitive parameters
            debugPrint("ChatLib: WebSocket connection URL constructed")

            var request = URLRequest(url: url)
            let uuid = UUID().uuidString
            request.setValue(uuid, forHTTPHeaderField: "x-trace-id")
            debugPrint("x-trace-id：\(uuid)")

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.websocket = WebSocket(request: request)
                self.websocket?.request.timeoutInterval = 5
                self.websocket?.delegate = self
                self.websocket?.connect()

                self.startTimer()
                debugPrint("ChatLib:call web socket - \(Date())")
            }
        }
    }
    
    public func reConnect(){
        websocketQueue.async { [weak self] in
            self?.callWebsocket()
        }
    }
    
    deinit {
        debugPrint("ChatLib:deinit")
        if websocket != nil{
            disConnected()
        }
    }
    
    func startTimer() {
        timerQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 如果定时器已经存在，直接返回
            if self.dispatchTimer != nil {
                return
            }
            
            // 使用 DispatchSourceTimer 替代 Timer.scheduledTimer
            // 优势：不依赖 RunLoop，精度更高，性能更好
            self.dispatchTimer = DispatchSource.makeTimerSource(queue: self.timerQueue)
            
            // 设置定时器：立即开始，每1秒重复
            self.dispatchTimer?.schedule(deadline: .now(), repeating: 1.0)
            
            // 设置定时器事件处理
            self.dispatchTimer?.setEventHandler { [weak self] in
                if ((self?.isConnected ?? false)) {
                self?.updateSecond()
              }
            }
            
            // 启动定时器
            self.dispatchTimer?.resume()
            debugPrint("ChatLib: DispatchSourceTimer started - \(Date())")
        }
    }

    
    // DispatchSourceTimer 不需要 @objc，因为不使用 selector
    private func updateSecond() {
        sessionTime += 1
        
        // 每30秒发送心跳
        if sessionTime % 30 == 0 {
            beatTimes += 1
            debugPrint("ChatLib:心跳第 \(beatTimes) 次 \(Date())")
            sendHeartBeat()
        }
        
        // 检查会话超时
        if sessionTime > maxSessionMinutes * 60 {
            disConnected(code: 1005, msg: "会话已超时")
            disConnect()
        }
    }
    
    // 保留旧方法以防其他地方调用
    @objc func updataSecond() {
        updateSecond()
    }

    private func stopTimer() {
        timerQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.beatTimes = 0
            self.sessionTime = 0
            
            // 停止 DispatchSourceTimer
            if let timer = self.dispatchTimer {
                timer.cancel()
                self.dispatchTimer = nil
                debugPrint("ChatLib: DispatchSourceTimer stopped")
            }
        }
    }
    
    public func resetSessionTime(){
        timerQueue.async { [weak self] in
            guard let self = self else { return }
            self.sessionTime = 0
        }
    }
    
    ///此接口不支持发视频
    public func sendMessage(msg: String, type: CommonMessageFormat, consultId: Int64, replyMsgId: Int64? = 0, withAutoReply: CommonWithAutoReply? = nil, fileSize: Int32 = 0, fileName: String = "") {
        self.replyMsgId = replyMsgId ?? 0
        self.consultId = consultId;
        self.withAutoReply = withAutoReply
        self.fileName = fileName
        self.fileSize = fileSize
        // 发送信息的封装，有四层
        // payload -> CSSendMessage -> common message -> CommonMessageContent
        switch type{
        case .msgText:
            sendTextMessage(txt: msg)
        case .msgImg:
            sendImageMessage(url: msg)
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
        msg.consultID = self.consultId
        //msg.content = content
        msg.chatID = chatId//2692944494609
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
        msg.consultID = self.consultId
        msg.content = content
        msg.sender = 0
        msg.replyMsgID = self.replyMsgId
        msg.msgFmt = CommonMessageFormat.msgText
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
        msg.consultID = self.consultId
        msg.image = content
        msg.sender = 0
        msg.replyMsgID = self.replyMsgId
        msg.msgFmt = CommonMessageFormat.msgImg
        msg.chatID = chatId
        msg.payload = .image(content)
        msg.worker = workId
        msg.msgTime.seconds = Int64(Date().timeIntervalSince1970)
        
        // 临时放到一个变量
        sendingMsg = msg
    }
    
    ///此接口专门发视频
    public func sendVideoMessage(url: String, thumbnailUri: String = "", hlsUri: String = "", consultId: Int64, replyMsgId: Int64? = 0, withAutoReply: CommonWithAutoReply? = nil) {
        self.replyMsgId = replyMsgId ?? 0
        self.consultId = consultId;
        self.withAutoReply = withAutoReply
        // 第一层
        var content = CommonMessageVideo()
        content.hlsUri = hlsUri
        content.thumbnailUri = thumbnailUri
        content.uri = url
        
        // 第二层, 消息主题
        var msg = CommonMessage()
        msg.consultID = self.consultId
        msg.video = content
        msg.sender = 0
        msg.replyMsgID = self.replyMsgId
        msg.msgFmt = CommonMessageFormat.msgVideo
        msg.chatID = chatId
        msg.payload = .video(content)
        msg.worker = workId
        msg.msgTime.seconds = Int64(Date().timeIntervalSince1970)
        
        // 临时放到一个变量
        sendingMsg = msg
        doSend()
    }
    
    private func sendAudioMessage(url: String){
        // 第一层
        var content = CommonMessageAudio()
        content.uri = url
        
        // 第二层, 消息主题
        var msg = CommonMessage()
        msg.consultID = self.consultId
        msg.audio = content
        msg.sender = 0
        msg.replyMsgID = self.replyMsgId
        msg.chatID = chatId
        msg.msgFmt = CommonMessageFormat.msgVoice
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
        content.size = self.fileSize
        content.fileName = self.fileName
        
        // 第二层, 消息主题
        var msg = CommonMessage()
        msg.consultID = self.consultId
        msg.file = content
        msg.sender = 0
        msg.replyMsgID = self.replyMsgId
        msg.msgFmt = CommonMessageFormat.msgFile
        msg.chatID = chatId
        msg.payload = .file(content)
        msg.worker = 5
        msg.msgTime.seconds = Int64(Date().timeIntervalSince1970)
        
        // 临时放到一个变量
        sendingMsg = msg
    }
    
    private func doSend(payload_Id: UInt64 = 0){
        guard var msg = sendingMsg else {
            return
        }

        if let w = self.withAutoReply {
            let withAutoReplies = Array(arrayLiteral: w)
            msg.withAutoReplies = withAutoReplies
        }

        var payloadIdentifier = payload_Id
        var shouldTrackMessage = false

        stateQueue.sync {
            if msg.msgOp == .msgOpPost && payload_Id == 0 {
                self.payloadId += 1
                payloadIdentifier = self.payloadId
                self.msgList[payloadIdentifier] = msg
                shouldTrackMessage = true
                debugPrint("ChatLib:payloadID + 1:" + String(self.payloadId))
            } else if payload_Id == 0 {
                payloadIdentifier = self.payloadId
            } else if msg.msgOp == .msgOpPost {
                shouldTrackMessage = true
                self.msgList[payloadIdentifier] = msg
            }
        }


        var payLoad = Gateway_Payload()
        payLoad.act = .cssendMsg

        do {
            var cSendMsg = Gateway_CSSendMessage()
            cSendMsg.msg = msg
            payLoad.data = try cSendMsg.serializedData()
            payLoad.id = payloadIdentifier
            let binaryData = try payLoad.serializedData()
            send(binaryData: binaryData, payloadId: payloadIdentifier)
        } catch {
            if shouldTrackMessage {
                stateQueue.async { [weak self] in
                    self?.msgList.removeValue(forKey: payloadIdentifier)
                }
            }
            debugPrint("ChatLib: Failed to serialize message: \(error.localizedDescription)")
        }
    }
    
   public func resendMsg(msg: CommonMessage, payloadId: UInt64) {
        // 临时放到一个变量
        sendingMsg = msg
        doSend(payload_Id: payloadId)
    }
 
    private func sendHeartBeat() {
        let array: [UInt8] = [0]

        let myData = Data(bytes: array)
        send(binaryData: myData)
        //debugPrint("ChatLib:sending heart beat")
    }
    
    private func send(binaryData: Data, payloadId: UInt64? = nil) {
        var shouldSendNow = false
        var shouldConnect = false

        stateQueue.sync {
            if self.isConnected {
                shouldSendNow = true
            } else {
                self.pendingPayloads.append((payloadId, binaryData))
                if !self.isConnecting {
                    self.isConnecting = true
                    shouldConnect = true
                }
            }
        }

        if shouldSendNow {
            writeToSocket(data: binaryData, payloadId: payloadId)
        } else if shouldConnect {
            enqueueWebsocketConnection()
        }
    }

    private func writeToSocket(data: Data, payloadId: UInt64?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let socket = self.websocket else {
                var shouldConnect = false
                stateQueue.sync {
                    let exists = self.pendingPayloads.contains(where: { element in
                        if element.id != payloadId { return false }
                        return element.data == data
                    })
                    if !exists {
                        self.pendingPayloads.append((payloadId, data))
                    }
                    if !self.isConnecting {
                        self.isConnecting = true
                        shouldConnect = true
                    }
                    self.isConnected = false
                }
                if shouldConnect {
                    self.enqueueWebsocketConnection()
                }
                return
            }
            debugPrint("ChatLib:开始发送")
            socket.write(data: data) {
                debugPrint("ChatLib:msg sent")
            }
        }
    }

    private func flushPendingPayloads() {
        let queuedItems: [(id: UInt64?, data: Data)] = stateQueue.sync {
            let items = self.pendingPayloads
            self.pendingPayloads.removeAll()
            return items
        }
        for item in queuedItems {
            writeToSocket(data: item.data, payloadId: item.id)
        }
    }

    
    
    private func disConnected(code: Int = 1006, msg: String = "已断开通信") {
        messageQueue.async { [weak self] in
            guard let self = self else { return }
            
            var result = Result()
            result.Code = code
            result.Message = msg
            
            DispatchQueue.main.async {
                self.delegate?.systemMsg(result: result)
            }

            self.stateQueue.async { [weak self] in
                guard let self = self else { return }
                self.isConnected = false
                self.isConnecting = false
            }

            self.sendingMsg = nil
            debugPrint("ChatLib:\(code) \(msg))")
        }
    }
    
    public func disConnect() {
        websocketQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.stopTimer()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let socket = self.websocket {
                    socket.disconnect()
                    socket.delegate = nil
                    self.websocket = nil
                }

                self.stateQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.isConnected = false
                    self.isConnecting = false
                    self.pendingPayloads.removeAll()
                    self.msgList.removeAll()
                    self.payloadId = 0
                }

                self.sendingMsg = nil
                self.networkManager.stopNetworkReachabilityObserver()
                debugPrint("ChatLib:退出了Chat SDK")
            }
        }
    }
}



// MARK: - WebSocketDelegate
extension ChatLib: WebSocketDelegate {
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        debugPrint("ChatLib:got some text: \(text)")
    }

    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {

        case .connected:
            messageQueue.async { [weak self] in
                guard let self = self else { return }
                self.stateQueue.sync {
                    self.isConnected = true
                    self.isConnecting = false
                }
                var result = Result()
                result.Code = 0
                result.Message = "已连接上"
                DispatchQueue.main.async {
                    self.delegate?.systemMsg(result: result)
                }
                self.flushPendingPayloads()
            }
        case .disconnected(let reason, let closeCode):
            messageQueue.async { [weak self] in
                guard let self = self else { return }
                debugPrint("ChatLib:disconnected \(reason) \(closeCode)")
                self.stateQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.isConnected = false
                    self.isConnecting = false
                }
                self.disConnected()
            }
        case .text(let text):
            debugPrint("ChatLib:received text: \(text)")
        case .binary(let data):
            messageQueue.async { [weak self] in
                guard let self = self else { return }
                
                if data.count == 1 {
                    if let d = String(data: data, encoding: .utf8) {
                        if d.contains("\u{00}") {
                            debugPrint("ChatLib:收到心跳回执\(self.beatTimes)")
                        }  else if d.contains("\u{03}") {
                            debugPrint("ChatLib:收到1字节回执\(d) PermChangedFlag 0x3")
                        }else if d.contains("\u{02}") {
                            self.disConnected(code: 1002, msg: "无效的Token")
                            debugPrint("ChatLib:收到1字节回执\(d) 无效的Token 0x2")
                        } else if d.contains("\u{01}") {
                            self.disConnected(code: 1010, msg: "在别处登录了")
                            debugPrint("ChatLib:收到1字节回执\(d) 在别处登录了")
                        } else {
                            debugPrint("ChatLib:收到1字节回执\(d)")
                        }
                    }
                } else {
                    guard let payLoad = try? Gateway_Payload(serializedBytes: data) else { return }
                    let msgData = payLoad.data
                    debugPrint("ChatLib:new payloadID:" + String(payLoad.id))
                    
                    //有收到消息，就重设超时时间。
                    self.resetSessionTime()
                    
                    if payLoad.act == .screcvMsg {
                        let scMsg = try? Gateway_SCRecvMessage(serializedBytes: msgData)
                        let msg = scMsg?.msg
                        if msg != nil {
                            if (msg!.msgOp == .msgOpDelete){
                                debugPrint("ChatLib:对方撤回了消息 payloadID:" + String(payLoad.id))
                                DispatchQueue.main.async {
                                    self.delegate?.msgDeleted(msg: msg!, payloadId: payLoad.id, errMsg: nil)
                                }
                            }else{
                                DispatchQueue.main.async {
                                    self.delegate?.receivedMsg(msg: msg!)
                                }
                            }
                        }
                    } else if payLoad.act == .schi {
                        if let msg = try? Gateway_SCHi(serializedBytes: msgData) {
                            DispatchQueue.main.async {
                                self.delegate?.connected(c: msg)
                            }
                            self.stateQueue.async { [weak self] in
                                self?.payloadId = payLoad.id
                            }
                            debugPrint("ChatLib:初始payloadId:" + String(payLoad.id))
                        }
                    } else if payLoad.act == .scworkerChanged {
                        if let msg = try? Gateway_SCWorkerChanged(serializedBytes: msgData) {
                            self.consultId = msg.consultID
                            DispatchQueue.main.async {
                                self.delegate?.workChanged(msg: msg)
                            }
                            debugPrint(msg)
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
                        let cMsg = try? Gateway_SCReadMessage(serializedBytes: msgData)
                        debugPrint("ChatLib:删除消息回执A，payloadId:\(payLoad.id) msgId:\(cMsg?.msgID ?? 0)")
                        if let cMsg = cMsg{
                            var msg = CommonMessage()
                            msg.msgID = Int64(cMsg.msgID)
                            msg.msgOp = .msgOpDelete
                            msg.chatID = cMsg.chatID
                            DispatchQueue.main.async {
                                self.delegate?.msgDeleted(msg: msg, payloadId: payLoad.id, errMsg: nil)
                            }
                            debugPrint(msg)
                        }
                    }
                    else if payLoad.act == .scdeleteMsg {
                        let cMsg = try? Gateway_CSRecvMessage(serializedBytes: msgData)
                        if let cMsg = cMsg{
                            var msg = CommonMessage()
                            msg.msgID = Int64(cMsg.msgID)
                            msg.msgOp = .msgOpDelete
                            msg.chatID = cMsg.chatID
                            DispatchQueue.main.async {
                                self.delegate?.msgDeleted(msg: msg, payloadId: payLoad.id, errMsg: nil)
                            }
                            debugPrint(msg)
                        }
                    }
                    else if payLoad.act == .forward {
                        let msg = try? Gateway_CSForward(serializedBytes: msgData)
                        debugPrint(msg!)
                    } else if payLoad.act == .scsendMsgAck {
                        if let scMsg = try? Gateway_SCSendMessage(serializedBytes: msgData) {
                            debugPrint("ChatLib:消息回执Step 1，payloadId:\(payLoad.id) msgId:\(scMsg.msgID)")

                            var storedMessage: CommonMessage?
                            stateQueue.sync {
                                storedMessage = self.msgList[payLoad.id]
                            }

                            if var cMsg = storedMessage {
                                cMsg.msgID = Int64(scMsg.msgID)
                                cMsg.msgTime = scMsg.msgTime
                                self.chatId = scMsg.chatID
                                debugPrint("ChatLib:消息回执Step 2")
                                let errMessage = scMsg.errMsg.isEmpty ? nil : scMsg.errMsg
                                if errMessage != nil {
                                    cMsg.msgID = -2
                                }
                                DispatchQueue.main.async {
                                    self.delegate?.msgReceipt(msg: cMsg, payloadId: payLoad.id, errMsg: errMessage)
                                }
                                stateQueue.async { [weak self] in
                                    guard let self = self else { return }
                                    self.msgList.removeValue(forKey: payLoad.id)
                                }
                            } else if !scMsg.errMsg.isEmpty {
                                var result = Result()
                                result.Code = 1004
                                result.Message = scMsg.errMsg
                                DispatchQueue.main.async { [weak self] in
                                    guard let self = self else { return }
                                    self.delegate?.systemMsg(result: result)
                                }
                            }
                        }
                    } else {
                        debugPrint("ChatLib:received data: \(data)")
                    }
                }
            }

        case .pong(let pongData):
            debugPrint("ChatLib:received pong: \(String(describing: pongData))")
        case .ping(let pingData):
            debugPrint("ChatLib:received ping: \(String(describing: pingData))")
        case .error(let error):
            messageQueue.async { [weak self] in
                guard let self = self else { return }
                debugPrint("ChatLib:socket error \(String(describing: error))")
                self.stateQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.isConnected = false
                    self.isConnecting = false
                }
                self.disConnected()
            }
        case .viabilityChanged:
            debugPrint("ChatLib:viabilityChanged")
        case .reconnectSuggested:
            debugPrint("ChatLib:reconnectSuggested")
        case .cancelled:
            messageQueue.async { [weak self] in
                guard let self = self else { return }
                self.stateQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.isConnected = false
                    self.isConnecting = false
                }
                self.disConnected(code: 1007)
                debugPrint("ChatLib:cancelled")
            }
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
}
