// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "QiChatKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "QiChatKit",
            targets: ["QiChatKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.4"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.27.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.0")
    ],
    targets: [
        .target(
            name: "QiChatKit",
            dependencies: [
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "Alamofire", package: "Alamofire")
            ]
        ),
        .testTarget(
            name: "QiChatKitTests",
            dependencies: ["QiChatKit"]
        )
    ]
)
