import Foundation

enum ChatLogger {
    static func log(_ message: @autoclosure () -> String) {
#if DEBUG
        print("[QiChatKit] \(message())")
#endif
    }

    static func error(_ message: @autoclosure () -> String) {
        print("[QiChatKit][Error] \(message())")
    }
}
