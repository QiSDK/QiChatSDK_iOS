import Starscream


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
                    self.updateConnectionState(true)
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
                    self.updateConnectionState(false)
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
                    self.updateConnectionState(false)
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
                    self.updateConnectionState(false)
                    self.isConnecting = false
                }
                self.disConnected(code: 1007)
                debugPrint("ChatLib:cancelled")
            }
        }
    }
}
