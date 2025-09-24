import Foundation

/// Runtime information about the active chat session.
struct SessionState {
    var sessionId: UInt64?
    var chatId: Int64
    var workerId: Int32
    var tokenId: Int32
    var welcomeMessage: String
    var isConnected: Bool

    init(sessionId: UInt64? = nil,
         chatId: Int64 = 0,
         workerId: Int32 = 0,
         tokenId: Int32 = 0,
         welcomeMessage: String = "你好，我是客服小福",
         isConnected: Bool = false) {
        self.sessionId = sessionId
        self.chatId = chatId
        self.workerId = workerId
        self.tokenId = tokenId
        self.welcomeMessage = welcomeMessage
        self.isConnected = isConnected
    }
}
