// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FoldKernel",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "FoldKernel",
            targets: ["FoldKernel"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-testing.git",
            revision: "swift-6.1.2-RELEASE"
        )
    ],
    targets: [
        .target(
            name: "FoldKernel"
        ),
        .testTarget(
            name: "FoldKernelTests",
            dependencies: [
                "FoldKernel",
                .product(name: "Testing", package: "swift-testing")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
