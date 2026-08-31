// swift-tools-version: 5.9
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
        ),
        .executable(
            name: "fold-kernel-example",
            targets: ["FoldKernelExample"]
        ),
        .executable(
            name: "fold-kernel-integration",
            targets: ["FoldKernelIntegration"]
        )
    ],
    targets: [
        .target(
            name: "FoldKernel",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "FoldKernelExample",
            dependencies: ["FoldKernel"]
        ),
        .executableTarget(
            name: "FoldKernelIntegration",
            dependencies: ["FoldKernel"]
        ),
        .testTarget(
            name: "FoldKernelTests",
            dependencies: ["FoldKernel"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
