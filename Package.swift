// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "swift-image-formats",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "ImageFormats",
            targets: ["ImageFormats"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/stackotter/swift-png", from: "4.4.4"),
        .package(url: "https://github.com/stackotter/jpeg", from: "1.0.2"),
        .package(url: "https://github.com/stackotter/swift-libwebp", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "ImageFormats",
            dependencies: [
                .product(name: "PNG", package: "swift-png"),
                .product(name: "JPEG", package: "jpeg"),
                .product(name: "WebP", package: "swift-libwebp"),
            ]
        ),
        .testTarget(
            name: "ImageFormatsTests",
            dependencies: ["ImageFormats"],
            resources: [.copy("test.png"), .copy("test.jpg"), .copy("test.webp")]
        ),
    ]
)
