// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ag-navigator",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "AGNavigator",
            targets: ["AGNavigator"]
        ),
    ],
    targets: [
        .target(
            name: "AGNavigator"
        ),
        .testTarget(
            name: "AGNavigatorTests",
            dependencies: ["AGNavigator"]
        ),
    ]
)
