import Foundation

public protocol teneasySDKDelegate: AnyObject {
    func receivedMsg(msg: CommonMessage)
    func msgReceipt(msg: CommonMessage, payloadId: UInt64, errMsg: String?)
    func msgDeleted(msg: CommonMessage, payloadId: UInt64, errMsg: String?)
    func systemMsg(result: Result)
    func connected(c: Gateway_SCHi)
    func workChanged(msg: Gateway_SCWorkerChanged)
}

public extension teneasySDKDelegate {
    func receivedMsg(msg: CommonMessage) {}
    func msgReceipt(msg: CommonMessage, payloadId: UInt64, errMsg: String?) {}
    func msgDeleted(msg: CommonMessage, payloadId: UInt64, errMsg: String?) {}
    func systemMsg(result: Result) {}
    func connected(c: Gateway_SCHi) {}
    func workChanged(msg: Gateway_SCWorkerChanged) {}
}
