// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let file = "WebRTC-128.0.6613.147/WebRTC.xcframework.zip"

let package = Package(
    name: "Dugon",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "Dugon", targets: ["Dugon"]),
    ],
    targets: [
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/0-u-0/dugon-ios-sdk-specs/releases/download/\(file)",
            checksum: "de37003be7d08d2d36b17bb9393c2159c3d40994becbd3234a471fd8c88d9527"
        ),
        .target(
            name: "Dugon",
            dependencies: [
                "WebRTC",
            ]
        ),
    ]
)


//
//import Foundation
//import PackageDescription
//
//
//let package = Package(
//    name: "Sora",
//    platforms: [.iOS(.v13)],
//    products: [
//        .library(name: "Sora", targets: ["Sora"]),
//        .library(name: "WebRTC", targets: ["WebRTC"]),
//    ],
//    targets: [
//        .binaryTarget(
//            name: "WebRTC",
//            url: "https://github.com/shiguredo/sora-ios-sdk-specs/releases/download/\(file)",
//            checksum: "b9242358b4d53cafdf19d75a731cea87c84205475f54816e3a5cfd99cdb03216"
//        ),
//        .target(
//            name: "Sora",
//            dependencies: ["WebRTC"],
//            path: "Sora",
//            exclude: ["Info.plist"],
//            resources: [.process("VideoView.xib")]
//        ),
//    ]
//)
