// swift-tools-version: 6.0
import PackageDescription

// Domain checks only. The iPhone app itself is built with Pulso.xcodeproj.
let package = Package(
    name: "PulsoDomain",
    platforms: [.macOS(.v13), .iOS("26.0")],
    products: [.library(name: "PulsoDomain", targets: ["PulsoDomain"])],
    targets: [
        .target(name: "PulsoDomain", path: "Sources/Pulso/Models"),
        .testTarget(name: "PulsoDomainTests", dependencies: ["PulsoDomain"], path: "Tests/PulsoDomainTests")
    ]
)
