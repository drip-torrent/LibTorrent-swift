// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LibTorrentSwift",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "LibTorrentSwift",
            targets: ["LibTorrentSwift"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LibTorrentSwift",
            dependencies: ["LibTorrentCxx"],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .unsafeFlags(["-enable-experimental-feature", "StrictConcurrency"]),
            ]
        ),
        .target(
            name: "LibTorrentCxx",
            dependencies: [],
            path: "Sources/LibTorrentCxx",
            sources: ["LibTorrentBridgeC.cpp"],
            publicHeadersPath: "include",
            cxxSettings: [
                .headerSearchPath("include"),
                .define("TORRENT_USE_LIBCRYPTO"),
                .define("TORRENT_USE_OPENSSL"),
                .define("BOOST_ASIO_HAS_STD_CHRONO"),
                .unsafeFlags([
                    "-std=c++20",
                    "-stdlib=libc++",
                    "-fmodules",
                    "-fcxx-modules"
                ], .when(platforms: [.macOS])),
                .unsafeFlags([
                    "-I/opt/homebrew/include",
                    "-I/usr/local/include"
                ], .when(platforms: [.macOS])),
            ],
            linkerSettings: [
                .linkedLibrary("torrent-rasterbar"),
                .linkedLibrary("boost_system"),
                .linkedLibrary("boost_filesystem"),
                .linkedLibrary("ssl"),
                .linkedLibrary("crypto"),
                .linkedLibrary("z"),
                .unsafeFlags([
                    "-L/opt/homebrew/lib",
                    "-L/usr/local/lib"
                ], .when(platforms: [.macOS]))
            ]
        ),
        .testTarget(
            name: "LibTorrentSwiftTests",
            dependencies: ["LibTorrentSwift"],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
    ],
    cxxLanguageStandard: .cxx20
)