import Foundation
import Starscream
import SwiftProtobuf

public final class ChatClient: NSObject {
    public weak var delegate: ChatClientDelegate?

    private let workQueue = DispatchQueue(label: "com.qichatkit.chatclient", qos: .userInitiated)
    private let heartbeatQueue = DispatchQueue(label: "com.qichatkit.chatclient.heartbeat")

    private var configuration: ChatConfiguration
    private var socket: WebSocket?
    private var reachabilityMonitor = ReachabilityMonitor()

    private var heartbeatTimer: DispatchSourceTimer?
    private var elapsedSeconds: TimeInterval = 0
    private var heartbeatCount = 0
    private var sessionState = SessionState()

    private var nextPayloadId: UInt64 = 0

    private enum PendingKind {
        case post
        case delete
    }

    private struct PendingMessage {
        var message: CommonMessage
        var kind: PendingKind
    }

    private var pendingMessages: [UInt64: PendingMessage] = [:]

    private var isConnected: Bool = false

    // MARK: - Lifecycle

    public init(configuration: ChatConfiguration) {
        self.configuration = configuration
        super.init()
        sessionState.chatId = configuration.chatId
        reachabilityMonitor.delegate = self
        reachabilityMonitor.start()
    }

    deinit {
        disconnect()
    }

    // MARK: - Public API

    @discardableResult
    public func updateConfiguration(_ configuration: ChatConfiguration) -> ChatConfiguration {
        let previous = self.configuration
        self.configuration = configuration
        sessionState.chatId = configuration.chatId
        return previous
    }

    public func connect() {
        workQueue.async { [weak self] in
            guard let self else { return }
            guard self.socket?.isConnected != true else { return }
            self.reachabilityMonitor.start()
            guard let request = self.makeHandshakeRequest() else {
                self.notifySystem(code: 1001, message: "网关地址无效")
                return
            }
            self.socket?.delegate = nil
            self.socket = WebSocket(request: request)
            self.socket?.callbackQueue = self.workQueue
            self.socket?.delegate = self
            self.socket?.connect()
            self.startHeartbeatTimer()
            ChatLogger.log("WebSocket connecting to: \(request)")
        }
    }

    public func disconnect() {
        workQueue.async { [weak self] in
            guard let self else { return }
            self.stopHeartbeatTimer()
            self.socket?.delegate = nil
            self.socket?.disconnect()
            self.socket = nil
            self.isConnected = false
            self.pendingMessages.removeAll()
            self.nextPayloadId = 0
            self.elapsedSeconds = 0
            self.heartbeatCount = 0
            self.reachabilityMonitor.stop()
        }
    }

    public func sendText(_ text: String,
                         consultId: Int64,
                         replyTo replyMessageId: Int64 = 0,
                         withAutoReply: CommonWithAutoReply? = nil) {
        let outbound = OutboundMessage(consultId: consultId,
                                       replyMessageId: replyMessageId,
                                       workerId: configuration.workerId,
                                       withAutoReply: withAutoReply,
                                       content: .text(text))
        send(outbound: outbound)
    }

    public func sendImage(uri: String,
                          consultId: Int64,
                          replyTo replyMessageId: Int64 = 0,
                          withAutoReply: CommonWithAutoReply? = nil) {
        let outbound = OutboundMessage(consultId: consultId,
                                       replyMessageId: replyMessageId,
                                       workerId: configuration.workerId,
                                       withAutoReply: withAutoReply,
                                       content: .image(uri: uri))
        send(outbound: outbound)
    }

    public func sendFile(uri: String,
                         fileName: String,
                         fileSize: Int32,
                         consultId: Int64,
                         replyTo replyMessageId: Int64 = 0,
                         withAutoReply: CommonWithAutoReply? = nil) {
        let outbound = OutboundMessage(consultId: consultId,
                                       replyMessageId: replyMessageId,
                                       workerId: configuration.workerId,
                                       withAutoReply: withAutoReply,
                                       content: .file(uri: uri, size: fileSize, name: fileName))
        send(outbound: outbound)
    }

    public func sendAudio(uri: String,
                          consultId: Int64,
                          replyTo replyMessageId: Int64 = 0,
                          withAutoReply: CommonWithAutoReply? = nil) {
        let outbound = OutboundMessage(consultId: consultId,
                                       replyMessageId: replyMessageId,
                                       workerId: configuration.workerId,
                                       withAutoReply: withAutoReply,
                                       content: .audio(uri: uri))
        send(outbound: outbound)
    }

    public func sendVideo(uri: String,
                          thumbnailURI: String,
                          hlsURI: String,
                          consultId: Int64,
                          replyTo replyMessageId: Int64 = 0,
                          withAutoReply: CommonWithAutoReply? = nil) {
        let outbound = OutboundMessage(consultId: consultId,
                                       replyMessageId: replyMessageId,
                                       workerId: configuration.workerId,
                                       withAutoReply: withAutoReply,
                                       content: .video(uri: uri, thumbnailURI: thumbnailURI, hlsURI: hlsURI))
        send(outbound: outbound)
    }

    public func deleteMessage(id: Int64, consultId: Int64, chatId: Int64? = nil) {
        workQueue.async { [weak self] in
            guard let self else { return }
            self.ensureConnection()
            var message = CommonMessage()
            message.consultID = consultId
            message.chatID = chatId ?? self.sessionState.chatId
            message.msgID = id
            message.msgOp = .msgOpDelete
            message.worker = self.configuration.workerId
            self.send(message: message, kind: .delete)
        }
    }

    public func resend(_ message: CommonMessage, payloadId: UInt64) {
        workQueue.async { [weak self] in
            guard let self else { return }
            self.ensureConnection()
            self.serialiseAndSend(commonMessage: message,
                                  payloadId: payloadId,
                                  kind: .post)
        }
    }

    public var currentPayloadId: UInt64 {
        workQueue.sync { nextPayloadId }
    }

    public func composeLocalText(_ text: String) -> CommonMessage {
        MessageBuilder.makeCommonMessage(from: OutboundMessage(consultId: 0,
                                                               workerId: configuration.workerId,
                                                               content: .text(text)),
                                         chatId: sessionState.chatId)
    }

    // MARK: - Private helpers

    private func send(outbound: OutboundMessage) {
        workQueue.async { [weak self] in
            guard let self else { return }
            self.ensureConnection()
            var message = MessageBuilder.makeCommonMessage(from: outbound, chatId: self.sessionState.chatId)
            message.msgOp = .msgOpPost
            self.send(message: message, kind: .post)
        }
    }

    private func send(message: CommonMessage, kind: PendingKind) {
        serialiseAndSend(commonMessage: message, payloadId: 0, kind: kind)
    }

    private func serialiseAndSend(commonMessage: CommonMessage,
                                   payloadId: UInt64,
                                   kind: PendingKind) {
        do {
            var sendMessage = Gateway_CSSendMessage()
            sendMessage.msg = commonMessage
            let messageData = try sendMessage.serializedData()

            var payload = Gateway_Payload()
            payload.act = .cssendMsg
            payload.data = messageData

            let nextId = payloadId == 0 ? allocatePayloadId() : payloadId
            payload.id = nextId
            pendingMessages[nextId] = PendingMessage(message: commonMessage, kind: kind)

            let envelopeData = try payload.serializedData()
            write(binary: envelopeData)
        } catch {
            ChatLogger.error("消息序列化失败: \(error.localizedDescription)")
            notifySystem(code: 1004, message: "消息序列化失败")
        }
    }

    private func allocatePayloadId() -> UInt64 {
        nextPayloadId = max(nextPayloadId + 1, 1)
        ChatLogger.log("Payload +1 => \(nextPayloadId)")
        return nextPayloadId
    }

    private func write(binary data: Data) {
        guard let socket else {
            ChatLogger.error("Socket not ready, attempting reconnect")
            connect()
            return
        }

        if socket.isConnected {
            socket.write(data: data) {
                ChatLogger.log("Data sent")
            }
        } else {
            ChatLogger.log("Socket disconnected, reconnecting before send")
            connect()
        }
    }

    private func ensureConnection() {
        if socket == nil || socket?.isConnected == false {
            connect()
        }
    }

    private func startHeartbeatTimer() {
        guard heartbeatTimer == nil else { return }
        heartbeatTimer = DispatchSource.makeTimerSource(queue: heartbeatQueue)
        heartbeatTimer?.schedule(deadline: .now(), repeating: .seconds(1))
        heartbeatTimer?.setEventHandler { [weak self] in
            self?.heartbeatTick()
        }
        heartbeatTimer?.resume()
    }

    private func stopHeartbeatTimer() {
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
    }

    private func heartbeatTick() {
        elapsedSeconds += 1
        if elapsedSeconds.truncatingRemainder(dividingBy: configuration.heartbeatInterval) == 0 {
            heartbeatCount += 1
            sendHeartbeat()
        }
        if elapsedSeconds >= configuration.maxSessionDuration {
            notifySystem(code: 1005, message: "会话已超时")
            disconnect()
        }
    }

    private func sendHeartbeat() {
        let heartbeatData = Data([0])
        write(binary: heartbeatData)
    }

    private func resetSessionTime() {
        elapsedSeconds = 0
    }

    private func makeHandshakeRequest() -> URLRequest? {
        var components = URLComponents(url: configuration.gatewayURL, resolvingAgainstBaseURL: false)
        var query = components?.queryItems ?? []
        query.append(contentsOf: [
            URLQueryItem(name: "cert", value: configuration.credentials.certificate),
            URLQueryItem(name: "token", value: configuration.credentials.token),
            URLQueryItem(name: "userid", value: String(configuration.userId)),
            URLQueryItem(name: "custom", value: configuration.customPayload),
            URLQueryItem(name: "ty", value: String(Api_Common_ClientType.userAppIos.rawValue)),
            URLQueryItem(name: "dt", value: String(Int(Date().timeIntervalSince1970 * 1000))),
            URLQueryItem(name: "sign", value: configuration.credentials.sign),
            URLQueryItem(name: "rd", value: String(Int.random(in: 1_000_000..<9_999_999)))
        ])
        components?.queryItems = query
        guard let url = components?.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.setValue(UUID().uuidString, forHTTPHeaderField: "x-trace-id")
        return request
    }

    private func notifySystem(code: Int, message: String) {
        let result = SDKResult(code: code, message: message)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.chatClient(self, didReceiveSystem: result)
        }
    }

    private func notifyReceipt(for payloadId: UInt64,
                               update handler: (inout CommonMessage) -> Void,
                               errorMessage: String?) {
        guard var pending = pendingMessages.removeValue(forKey: payloadId) else { return }
        handler(&pending.message)
        sessionState.chatId = pending.message.chatID
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch pending.kind {
            case .post:
                self.delegate?.chatClient(self,
                                          didAcknowledge: pending.message,
                                          payloadId: payloadId,
                                          errorMessage: errorMessage)
            case .delete:
                self.delegate?.chatClient(self,
                                          didDelete: pending.message,
                                          payloadId: payloadId,
                                          errorMessage: errorMessage)
            }
        }
    }
}

// MARK: - WebSocketDelegate
extension ChatClient: WebSocketDelegate {
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected:
            isConnected = true
            notifySystem(code: 0, message: "已连接上")
        case .disconnected(let reason, let closeCode):
            isConnected = false
            ChatLogger.log("Disconnected: \(reason) code: \(closeCode)")
            notifySystem(code: Int(closeCode.rawValue), message: reason)
        case .text(let text):
            ChatLogger.log("Received text: \(text)")
        case .binary(let data):
            handleBinary(data)
        case .ping:
            ChatLogger.log("Received ping")
        case .pong:
            ChatLogger.log("Received pong")
        case .viabilityChanged(let viable):
            ChatLogger.log("Viability changed: \(viable)")
        case .reconnectSuggested(let suggested):
            ChatLogger.log("Reconnect suggested: \(suggested)")
            if suggested { connect() }
        case .cancelled:
            isConnected = false
            notifySystem(code: 1007, message: "连接已取消")
        case .error(let error):
            isConnected = false
            if let error {
                ChatLogger.error("Socket error: \(error.localizedDescription)")
                notifySystem(code: 1006, message: error.localizedDescription)
            }
        }
    }

    private func handleBinary(_ data: Data) {
        guard data.count > 1 else {
            handleControlFrame(data)
            return
        }
        do {
            let payload = try Gateway_Payload(serializedBytes: data)
            resetSessionTime()
            sessionState.sessionId = payload.id
            switch payload.act {
            case .screcvMsg:
                let message = try Gateway_SCRecvMessage(serializedBytes: payload.data)
                deliverReceived(message.msg, payloadId: payload.id)
            case .schi:
                let hi = try Gateway_SCHi(serializedBytes: payload.data)
                sessionState.chatId = hi.id
                nextPayloadId = payload.id
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.chatClient(self, didConnect: hi)
                }
            case .scworkerChanged:
                let change = try Gateway_SCWorkerChanged(serializedBytes: payload.data)
                sessionState.chatId = change.consultID
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.chatClient(self, workerDidChange: change)
                }
            case .scdeleteMsgAck:
                let ack = try Gateway_SCReadMessage(serializedBytes: payload.data)
                var message = CommonMessage()
                message.msgID = Int64(ack.msgID)
                message.chatID = ack.chatID
                message.msgOp = .msgOpDelete
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.chatClient(self,
                                              didDelete: message,
                                              payloadId: payload.id,
                                              errorMessage: nil)
                }
            case .scdeleteMsg:
                let ack = try Gateway_CSRecvMessage(serializedBytes: payload.data)
                var message = CommonMessage()
                message.msgID = Int64(ack.msgID)
                message.chatID = ack.chatID
                message.msgOp = .msgOpDelete
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.chatClient(self,
                                              didDelete: message,
                                              payloadId: payload.id,
                                              errorMessage: nil)
                }
            case .scsendMsgAck:
                let ack = try Gateway_SCSendMessage(serializedBytes: payload.data)
                notifyReceipt(for: payload.id, update: { message in
                    message.msgID = Int64(ack.msgID)
                    message.msgTime = ack.msgTime
                    message.chatID = ack.chatID
                }, errorMessage: ack.errMsg.isEmpty ? nil : ack.errMsg)
            default:
                ChatLogger.log("Unhandled payload action: \(payload.act)")
            }
        } catch {
            ChatLogger.error("Failed to parse payload: \(error.localizedDescription)")
        }
    }

    private func handleControlFrame(_ data: Data) {
        guard let character = data.first else { return }
        switch character {
        case 0:
            ChatLogger.log("心跳回执 #\(heartbeatCount)")
        case 1:
            notifySystem(code: 1010, message: "在别处登录了")
        case 2:
            notifySystem(code: 1002, message: "无效的Token")
        case 3:
            notifySystem(code: 1003, message: "权限已变更")
        default:
            ChatLogger.log("未知控制码: \(character)")
        }
    }

    private func deliverReceived(_ message: CommonMessage, payloadId: UInt64) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if message.msgOp == .msgOpDelete {
                self.delegate?.chatClient(self,
                                          didDelete: message,
                                          payloadId: payloadId,
                                          errorMessage: nil)
            } else {
                self.delegate?.chatClient(self, didReceive: message)
            }
        }
    }
}

// MARK: - ReachabilityMonitorDelegate
extension ChatClient: ReachabilityMonitorDelegate {
    func reachabilityMonitor(_ monitor: ReachabilityMonitor, didChange status: ReachabilityStatus) {
        switch status {
        case .notReachable:
            notifySystem(code: 1009, message: "网络中断了")
            disconnect()
        case .unknown:
            ChatLogger.log("Network reachability unknown")
        case .ethernetOrWiFi:
            ChatLogger.log("网络可用：Wi-Fi 或以太网")
        case .cellular:
            ChatLogger.log("网络可用：蜂窝")
        }
    }
}
