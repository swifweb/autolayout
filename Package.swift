// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "autolayout",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Autolayout", type: .static, targets: ["Autolayout"])
    ],
    dependencies: [
        .package(url: "https://github.com/swifweb/web", from: "1.0.0-beta.1.22.2")
    ],
    targets: [
        .target(name: "Autolayout", dependencies: [
            .product(name: "Web", package: "web")
        ]),
        .testTarget(name: "AutolayoutTests", dependencies: ["Autolayout"])
    ]
)
