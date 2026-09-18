// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ManageYourDisplay",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ManageYourDisplay",
            targets: ["ManageYourDisplay"]
        ),
    ],
    targets: [
        .target(
            name: "MonikBridge",
            path: "Sources/MonikBridge",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "ManageYourDisplay",
            dependencies: ["MonikBridge"],
            path: "Sources/Monik",
            linkerSettings: [
                .linkedFramework("CoreDisplay", .when(platforms: [.macOS])),
                .linkedFramework("IOKit", .when(platforms: [.macOS])),
                .linkedFramework("ColorSync", .when(platforms: [.macOS])),
                .linkedFramework("ScreenCaptureKit", .when(platforms: [.macOS])),
                .unsafeFlags([
                    "-F/System/Library/PrivateFrameworks",
                    "-framework", "SkyLight"
                ])
            ]
        )
    ]
)
