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
        )
    ],
    targets: [
        .target(
            name: "FoldKernel"
        ),
        .executableTarget(
            name: "FoldKernelExample",
            dependencies: ["FoldKernel"]
        ),
        .testTarget(
            name: "FoldKernelTests",
            dependencies: ["FoldKernel"],
            resources: [
                .process("Resources")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
