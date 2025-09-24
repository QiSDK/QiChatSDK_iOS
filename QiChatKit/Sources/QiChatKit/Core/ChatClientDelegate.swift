import Foundation

public protocol ChatClientDelegate: AnyObject {
    /// Incoming message from the remote party.
    func chatClient(_ client: ChatClient, didReceive message: CommonMessage)
    /// Message acknowledgement (success or failure) for a previously sent payload.
    func chatClient(_ client: ChatClient, didAcknowledge message: CommonMessage, payloadId: UInt64, errorMessage: String?)
    /// Message deletion acknowledgement from the server.
    func chatClient(_ client: ChatClient, didDelete message: CommonMessage, payloadId: UInt64, errorMessage: String?)
    /// System level notifications (e.g. connection state, errors).
    func chatClient(_ client: ChatClient, didReceiveSystem result: SDKResult)
    /// Connection metadata after a successful handshake.
    func chatClient(_ client: ChatClient, didConnect metadata: Gateway_SCHi)
    /// Worker change event notification.
    func chatClient(_ client: ChatClient, workerDidChange change: Gateway_SCWorkerChanged)
}

public extension ChatClientDelegate {
    func chatClient(_ client: ChatClient, didReceive message: CommonMessage) {}
    func chatClient(_ client: ChatClient, didAcknowledge message: CommonMessage, payloadId: UInt64, errorMessage: String?) {}
    func chatClient(_ client: ChatClient, didDelete message: CommonMessage, payloadId: UInt64, errorMessage: String?) {}
    func chatClient(_ client: ChatClient, didReceiveSystem result: SDKResult) {}
    func chatClient(_ client: ChatClient, didConnect metadata: Gateway_SCHi) {}
    func chatClient(_ client: ChatClient, workerDidChange change: Gateway_SCWorkerChanged) {}
}
