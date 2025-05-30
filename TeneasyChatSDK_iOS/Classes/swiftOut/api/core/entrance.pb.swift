// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: api/core/entrance.proto
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

public struct Api_Core_EntranceQueryResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var entrances: [Api_Common_Entrance] = []

  public var total: Int32 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

public struct Api_Core_DomainItem: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var domainName: String = String()

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

public struct Api_Core_DownloadDomainResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var domainItem: [Api_Core_DomainItem] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

public struct Api_Core_CreateEntranceRequest: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var entrances: Api_Common_Entrance {
    get {return _entrances ?? Api_Common_Entrance()}
    set {_entrances = newValue}
  }
  /// Returns true if `entrances` has been explicitly set.
  public var hasEntrances: Bool {return self._entrances != nil}
  /// Clears the value of `entrances`. Subsequent reads from it will return its default value.
  public mutating func clearEntrances() {self._entrances = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _entrances: Api_Common_Entrance? = nil
}

public struct Api_Core_CreateEntranceResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var id: UInt32 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

public struct Api_Core_UpdateEntranceRequest: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var entrances: Api_Common_Entrance {
    get {return _entrances ?? Api_Common_Entrance()}
    set {_entrances = newValue}
  }
  /// Returns true if `entrances` has been explicitly set.
  public var hasEntrances: Bool {return self._entrances != nil}
  /// Clears the value of `entrances`. Subsequent reads from it will return its default value.
  public mutating func clearEntrances() {self._entrances = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _entrances: Api_Common_Entrance? = nil
}

public struct Api_Core_DeleteEntranceRequest: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var id: UInt32 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

/// 禁用/启用入口
public struct Api_Core_DisableEntranceRequest: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var id: UInt32 = 0

  /// 禁用/启用
  public var disableStatus: CommonDisableStatus = .default

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

public struct Api_Core_GetDistributionResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var tenantID: Int32 = 0

  public var distributionType: String = String()

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

public struct Api_Core_SaveDistributionRequest: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var distributionType: [Api_Common_DistributionType] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

public struct Api_Core_EntranceExistsRequest: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var based: Api_Core_EntranceExistsRequest.OneOf_Based? = nil

  public var entranceID: Int32 {
    get {
      if case .entranceID(let v)? = based {return v}
      return 0
    }
    set {based = .entranceID(newValue)}
  }

  public var clientID: Int64 {
    get {
      if case .clientID(let v)? = based {return v}
      return 0
    }
    set {based = .clientID(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public enum OneOf_Based: Equatable, Sendable {
    case entranceID(Int32)
    case clientID(Int64)

  }

  public init() {}
}

public struct Api_Core_GetUnreadWorkerMessageCountRequest: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// 商户id
  public var tenantID: Int64 = 0

  /// 用户id
  public var uid: Int32 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

public struct Api_Core_GetUnreadWorkerMessageCountResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// 咨询组未读
  public var consultUnreads: [Api_Core_ConsultUnread] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

public struct Api_Core_ConsultUnread: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// 咨询id
  public var consultID: UInt32 = 0

  /// 未读统计
  public var unreadMessageCount: Int32 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "api.core"

extension Api_Core_EntranceQueryResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".EntranceQueryResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "entrances"),
    2: .same(proto: "total"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.entrances) }()
      case 2: try { try decoder.decodeSingularInt32Field(value: &self.total) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.entrances.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.entrances, fieldNumber: 1)
    }
    if self.total != 0 {
      try visitor.visitSingularInt32Field(value: self.total, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_EntranceQueryResponse, rhs: Api_Core_EntranceQueryResponse) -> Bool {
    if lhs.entrances != rhs.entrances {return false}
    if lhs.total != rhs.total {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_DomainItem: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".DomainItem"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "domain_name"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.domainName) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.domainName.isEmpty {
      try visitor.visitSingularStringField(value: self.domainName, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_DomainItem, rhs: Api_Core_DomainItem) -> Bool {
    if lhs.domainName != rhs.domainName {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_DownloadDomainResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".DownloadDomainResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "domain_item"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.domainItem) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.domainItem.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.domainItem, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_DownloadDomainResponse, rhs: Api_Core_DownloadDomainResponse) -> Bool {
    if lhs.domainItem != rhs.domainItem {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_CreateEntranceRequest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".CreateEntranceRequest"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "entrances"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._entrances) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._entrances {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_CreateEntranceRequest, rhs: Api_Core_CreateEntranceRequest) -> Bool {
    if lhs._entrances != rhs._entrances {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_CreateEntranceResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".CreateEntranceResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "id"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt32Field(value: &self.id) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.id != 0 {
      try visitor.visitSingularUInt32Field(value: self.id, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_CreateEntranceResponse, rhs: Api_Core_CreateEntranceResponse) -> Bool {
    if lhs.id != rhs.id {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_UpdateEntranceRequest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".UpdateEntranceRequest"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "entrances"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._entrances) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._entrances {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_UpdateEntranceRequest, rhs: Api_Core_UpdateEntranceRequest) -> Bool {
    if lhs._entrances != rhs._entrances {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_DeleteEntranceRequest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".DeleteEntranceRequest"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "id"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt32Field(value: &self.id) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.id != 0 {
      try visitor.visitSingularUInt32Field(value: self.id, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_DeleteEntranceRequest, rhs: Api_Core_DeleteEntranceRequest) -> Bool {
    if lhs.id != rhs.id {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_DisableEntranceRequest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".DisableEntranceRequest"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "id"),
    2: .standard(proto: "disable_status"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt32Field(value: &self.id) }()
      case 2: try { try decoder.decodeSingularEnumField(value: &self.disableStatus) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.id != 0 {
      try visitor.visitSingularUInt32Field(value: self.id, fieldNumber: 1)
    }
    if self.disableStatus != .default {
      try visitor.visitSingularEnumField(value: self.disableStatus, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_DisableEntranceRequest, rhs: Api_Core_DisableEntranceRequest) -> Bool {
    if lhs.id != rhs.id {return false}
    if lhs.disableStatus != rhs.disableStatus {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_GetDistributionResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".GetDistributionResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "tenant_id"),
    2: .standard(proto: "distribution_type"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self.tenantID) }()
      case 2: try { try decoder.decodeSingularStringField(value: &self.distributionType) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.tenantID != 0 {
      try visitor.visitSingularInt32Field(value: self.tenantID, fieldNumber: 1)
    }
    if !self.distributionType.isEmpty {
      try visitor.visitSingularStringField(value: self.distributionType, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_GetDistributionResponse, rhs: Api_Core_GetDistributionResponse) -> Bool {
    if lhs.tenantID != rhs.tenantID {return false}
    if lhs.distributionType != rhs.distributionType {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_SaveDistributionRequest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".SaveDistributionRequest"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    3: .standard(proto: "distribution_type"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 3: try { try decoder.decodeRepeatedEnumField(value: &self.distributionType) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.distributionType.isEmpty {
      try visitor.visitPackedEnumField(value: self.distributionType, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_SaveDistributionRequest, rhs: Api_Core_SaveDistributionRequest) -> Bool {
    if lhs.distributionType != rhs.distributionType {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_EntranceExistsRequest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".EntranceExistsRequest"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "entrance_id"),
    2: .standard(proto: "client_id"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try {
        var v: Int32?
        try decoder.decodeSingularInt32Field(value: &v)
        if let v = v {
          if self.based != nil {try decoder.handleConflictingOneOf()}
          self.based = .entranceID(v)
        }
      }()
      case 2: try {
        var v: Int64?
        try decoder.decodeSingularInt64Field(value: &v)
        if let v = v {
          if self.based != nil {try decoder.handleConflictingOneOf()}
          self.based = .clientID(v)
        }
      }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    switch self.based {
    case .entranceID?: try {
      guard case .entranceID(let v)? = self.based else { preconditionFailure() }
      try visitor.visitSingularInt32Field(value: v, fieldNumber: 1)
    }()
    case .clientID?: try {
      guard case .clientID(let v)? = self.based else { preconditionFailure() }
      try visitor.visitSingularInt64Field(value: v, fieldNumber: 2)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_EntranceExistsRequest, rhs: Api_Core_EntranceExistsRequest) -> Bool {
    if lhs.based != rhs.based {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_GetUnreadWorkerMessageCountRequest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".GetUnreadWorkerMessageCountRequest"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "tenant_id"),
    2: .same(proto: "uid"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt64Field(value: &self.tenantID) }()
      case 2: try { try decoder.decodeSingularInt32Field(value: &self.uid) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.tenantID != 0 {
      try visitor.visitSingularInt64Field(value: self.tenantID, fieldNumber: 1)
    }
    if self.uid != 0 {
      try visitor.visitSingularInt32Field(value: self.uid, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_GetUnreadWorkerMessageCountRequest, rhs: Api_Core_GetUnreadWorkerMessageCountRequest) -> Bool {
    if lhs.tenantID != rhs.tenantID {return false}
    if lhs.uid != rhs.uid {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_GetUnreadWorkerMessageCountResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".GetUnreadWorkerMessageCountResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "consult_unreads"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.consultUnreads) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.consultUnreads.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.consultUnreads, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_GetUnreadWorkerMessageCountResponse, rhs: Api_Core_GetUnreadWorkerMessageCountResponse) -> Bool {
    if lhs.consultUnreads != rhs.consultUnreads {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Api_Core_ConsultUnread: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ConsultUnread"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "consult_id"),
    2: .standard(proto: "unread_message_count"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt32Field(value: &self.consultID) }()
      case 2: try { try decoder.decodeSingularInt32Field(value: &self.unreadMessageCount) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.consultID != 0 {
      try visitor.visitSingularUInt32Field(value: self.consultID, fieldNumber: 1)
    }
    if self.unreadMessageCount != 0 {
      try visitor.visitSingularInt32Field(value: self.unreadMessageCount, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Api_Core_ConsultUnread, rhs: Api_Core_ConsultUnread) -> Bool {
    if lhs.consultID != rhs.consultID {return false}
    if lhs.unreadMessageCount != rhs.unreadMessageCount {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
