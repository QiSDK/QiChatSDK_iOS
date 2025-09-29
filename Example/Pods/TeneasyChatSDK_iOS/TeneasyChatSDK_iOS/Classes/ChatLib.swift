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
    
    public private(set) var text = "Teneasy Chat SDK 启动" // SDK启动状态文本
    private var baseUrl = "wss://csapi.xdev.stream/v1/gateway/h5?token=" // WebSocket连接基础URL
    var websocket: WebSocket? // WebSocket连接实例
    var isConnected = false // 连接状态标识
    // weak var delegate: WebSocketDelegate?
    public weak var delegate: teneasySDKDelegate? // SDK回调代理
    open var payloadId: UInt64 = 0 // 消息载荷ID
    public var sendingMsg: CommonMessage? // 当前发送的消息
    var msgList: [UInt64: CommonMessage] = [:] // 消息列表缓存
    var chatId: Int64 = 0 // 聊天会话ID
    public var token: String = "" // 认证令牌
    var session = Session() // 会话信息
    
    var dispatchTimer: DispatchSourceTimer? // 定时器实例
    private var sessionTime: Int = 0 // 会话持续时间（秒）
    //var chooseImg: UIImage?
    var beatTimes = 0 // 心跳次数计数
    private var maxSessionMinutes = 90000000 // 最大会话时长（分钟）相当于不设置会话超时时间
    var workId: Int32 = 5 // 工作人员ID
    private var replyMsgId: Int64 = 0 // 回复消息ID
    private var userId: Int32 = 0 // 用户ID
    private var custom: String = "" // 自定义参数
    private var sign: String = "" // 签名
    private var cert: String = "" // 证书
    private var networkManager = NetworkManager() // 网络管理器
    public static let shared = ChatLib() // 单例实例
    private var withAutoReply: CommonWithAutoReply? // 自动回复配置
    
    // DispatchQueue for thread management 线程管理队列
    let websocketQueue = DispatchQueue(label: "com.teneasy.websocket", qos: .userInitiated) // WebSocket操作队列
    let messageQueue = DispatchQueue(label: "com.teneasy.message", qos: .userInitiated) // 消息处理队列
    let timerQueue = DispatchQueue(label: "com.teneasy.timer", qos: .utility) // 定时器队列
    let networkQueue = DispatchQueue(label: "com.teneasy.network", qos: .background) // 网络操作队列
    let stateQueue = DispatchQueue(label: "com.teneasy.state") // 状态管理队列

    var pendingPayloads: [(id: UInt64?, data: Data)] = [] // 待发送的数据队列
    var isConnecting = false // 正在连接状态标识

    var consultId: Int64 = 0 // 咨询会话ID
    private var fileSize: Int32 = 0 // 文件大小
    private var fileName: String = "" // 文件名称

    public init() {}

    // 初始化SDK配置参数
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

   // 建立WebSocket连接
   public func callWebsocket() {
        stateQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isConnecting || self.isConnected { return }
            self.isConnecting = true
            self.enqueueWebsocketConnection()
        }
    }

    // 将WebSocket连接加入队列
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
            debugPrint("wss：\(url) x-trace-id：\(uuid)")

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
    
    // 重新连接WebSocket
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
    
    // 启动定时器
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

    
    // 更新秒数计数器（DispatchSourceTimer 不需要 @objc，因为不使用 selector）
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

    // 停止定时器
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
    
    // 重置会话时间
    public func resetSessionTime(){
        timerQueue.async { [weak self] in
            guard let self = self else { return }
            self.sessionTime = 0
        }
    }
    
    // 发送消息（此接口不支持发视频）
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
    
    // 删除消息
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
    
    // 发送文本消息
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
    
    // 发送图片消息
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
    
    // 发送视频消息（此接口专门发视频）
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
    
    // 发送音频消息
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
    
    // 发送文件消息
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
    
    // 执行发送操作
    private func doSend(resendPayloadId: UInt64 = 0){
        guard var msg = sendingMsg else {
            return
        }
        
        if self.payloadId == 0{ //说明还没有被初始化成功
            delegate?.systemMsg(result: Result(Code: 1007, Message: "SDK尚未初始化"))
            debugPrint("SDK尚未初始化")
            return
        }

        if let w = self.withAutoReply {
            let withAutoReplies = Array(arrayLiteral: w)
            msg.withAutoReplies = withAutoReplies
        }

        var payloadIdentifier = resendPayloadId
        var shouldTrackMessage = false

        stateQueue.sync {
            if msg.msgOp == .msgOpPost && resendPayloadId == 0 {
                self.payloadId += 1
                payloadIdentifier = self.payloadId
                self.msgList[payloadIdentifier] = msg
                shouldTrackMessage = true
                debugPrint("ChatLib:payloadID + 1:" + String(self.payloadId))
            } else if resendPayloadId == 0 {
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
    
   // 重发消息
   public func resendMsg(msg: CommonMessage, payloadId: UInt64) {
        // 临时放到一个变量
        sendingMsg = msg
        doSend(resendPayloadId: payloadId)
    }
 
    // 发送心跳包
    private func sendHeartBeat() {
        let array: [UInt8] = [0]

        let myData = Data(bytes: array)
        send(binaryData: myData)
        //debugPrint("ChatLib:sending heart beat")
    }
    
    // 发送二进制数据
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

    // 写入Socket数据
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

     // 刷新待发送的数据队列
     func flushPendingPayloads() {
        let queuedItems: [(id: UInt64?, data: Data)] = stateQueue.sync {
            let items = self.pendingPayloads
            self.pendingPayloads.removeAll()
            return items
        }
        for item in queuedItems {
            writeToSocket(data: item.data, payloadId: item.id)
        }
    }

     // 处理断开连接事件
     func disConnected(code: Int = 1006, msg: String = "已断开通信") {
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
    
    // 手动断开连接、清理会话中所有数据
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





    
    // 创建本地文本消息，无需经过服务器
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
