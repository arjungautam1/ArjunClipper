// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ArjunClipper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ArjunClipper", targets: ["ArjunClipper"]),
        .library(name: "ArjunClipperLib", targets: ["ArjunClipperLib"])
    ],
    targets: [
        .target(
            name: "ArjunClipperLib",
            path: "Sources/ArjunClipperLib"
        ),
        .executableTarget(
            name: "ArjunClipper",
            dependencies: ["ArjunClipperLib"],
            path: "Sources/ArjunClipper"
        ),
        .testTarget(
            name: "ArjunClipperTests",
            dependencies: ["ArjunClipperLib"],
            path: "Tests/ArjunClipperTests"
        )
    ]
)
