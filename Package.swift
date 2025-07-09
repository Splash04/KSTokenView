// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KSTokenView",
    platforms: [
        .iOS(.v13)
    ],
    
    products: [
        .library(name: "KSTokenView", targets: ["KSTokenView"])
    ],
    
    targets: [
        .target(name: "KSTokenView", path: "KSTokenView", resources: [.process("PrivacyInfo.xcprivacy")])
    ]
)
