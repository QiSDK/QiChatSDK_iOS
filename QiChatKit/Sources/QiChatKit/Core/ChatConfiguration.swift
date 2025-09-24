import Foundation

public struct ChatConfiguration: Equatable {
    public struct Credentials: Equatable {
        public var token: String
        public var certificate: String
        public var sign: String

        public init(token: String, certificate: String, sign: String) {
            self.token = token
            self.certificate = certificate
            self.sign = sign
        }
    }

    public var gatewayURL: URL
    public var credentials: Credentials
    public var userId: Int32
    public var customPayload: String
    public var chatId: Int64
    public var workerId: Int32
    public var maxSessionDuration: TimeInterval
    public var heartbeatInterval: TimeInterval

    /// - Parameters:
    ///   - maxSessionDuration: In seconds. Defaults to "no timeout" (90000000 minutes) to match legacy behaviour.
    public init(gatewayURL: URL,
                credentials: Credentials,
                userId: Int32,
                customPayload: String = "",
                chatId: Int64 = 0,
                workerId: Int32 = 5,
                maxSessionDuration: TimeInterval = TimeInterval(90000000 * 60),
                heartbeatInterval: TimeInterval = 30) {
        self.gatewayURL = gatewayURL
        self.credentials = credentials
        self.userId = userId
        self.customPayload = customPayload
        self.chatId = chatId
        self.workerId = workerId
        self.maxSessionDuration = max(maxSessionDuration, heartbeatInterval)
        self.heartbeatInterval = heartbeatInterval
    }
}
