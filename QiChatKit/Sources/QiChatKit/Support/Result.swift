import Foundation

/// Lightweight result object used for delegate callbacks and error propagation.
public struct SDKResult: Equatable {
    public var code: Int
    public var message: String

    public init(code: Int = 0, message: String = "") {
        self.code = code
        self.message = message
    }
}
