// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: api/common/c_phonenumber.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

public struct CommonPhoneNumber: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// 默认中国区号 86
  public var countryCode: Int32 = 0

  /// International Telecommunication Union (ITU) Recommendation E.164,
  public var nationalNumber: Int64 = 0

  /// 隐去手机号码部分数字后的表现形式, 如:
  /// 133*****123
  /// 通常用作前端表现, 或消费方不应知道完整手机号码的场景
  public var maskedNationalNumber: String = String()

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "api.common"

extension CommonPhoneNumber: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".PhoneNumber"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "country_code"),
    2: .standard(proto: "national_number"),
    3: .standard(proto: "masked_national_number"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self.countryCode) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.nationalNumber) }()
      case 3: try { try decoder.decodeSingularStringField(value: &self.maskedNationalNumber) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.countryCode != 0 {
      try visitor.visitSingularInt32Field(value: self.countryCode, fieldNumber: 1)
    }
    if self.nationalNumber != 0 {
      try visitor.visitSingularInt64Field(value: self.nationalNumber, fieldNumber: 2)
    }
    if !self.maskedNationalNumber.isEmpty {
      try visitor.visitSingularStringField(value: self.maskedNationalNumber, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: CommonPhoneNumber, rhs: CommonPhoneNumber) -> Bool {
    if lhs.countryCode != rhs.countryCode {return false}
    if lhs.nationalNumber != rhs.nationalNumber {return false}
    if lhs.maskedNationalNumber != rhs.maskedNationalNumber {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
