// swift-tools-version: 6.1
// This is a Skip (https://skip.tools) package.
import PackageDescription

let package = Package(
    name: "skip-revenue",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SkipRevenueUI", type: .dynamic, targets: ["SkipRevenueUI"]),
        .library(name: "SkipRevenue", type: .dynamic, targets: ["SkipRevenue"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.6.36"),
        .package(url: "https://source.skip.tools/skip-ui.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "4.43.0")
    ],
    targets: [
        .target(name: "SkipRevenue", dependencies: [
            .product(name: "SkipFoundation", package: "skip-foundation"),
            .product(name: "RevenueCat", package: "purchases-ios", condition: .when(platforms: [.iOS, .macOS]))
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipRevenueTests", dependencies: [
            "SkipRevenue",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "SkipRevenueUI", dependencies: [
            "SkipRevenue",
            .product(name: "SkipUI", package: "skip-ui"),
            .product(name: "RevenueCatUI", package: "purchases-ios", condition: .when(platforms: [.iOS, .macOS]))
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipRevenueUITests", dependencies: [
            "SkipRevenueUI",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)

if Context.environment["SKIP_BRIDGE"] ?? "0" != "0" {
    package.dependencies += [
        .package(url: "https://source.skip.tools/skip-bridge.git", "0.0.0"..<"2.0.0"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.0.0")
    ]
    package.targets.forEach({ target in
        target.dependencies += [
            .product(name: "SkipBridge", package: "skip-bridge"),
            .product(name: "SkipFuseUI", package: "skip-fuse-ui")
        ]
    })
    // all library types must be dynamic to support bridging
    package.products = package.products.map({ product in
        guard let libraryProduct = product as? Product.Library else { return product }
        return .library(name: libraryProduct.name, type: .dynamic, targets: libraryProduct.targets)
    })
}
