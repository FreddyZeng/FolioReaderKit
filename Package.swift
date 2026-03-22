// swift-tools-version:5.3
import PackageDescription

let package = Package(
	name: "FolioReaderKit",
    platforms: [
            .iOS(.v13),
            .macOS(.v10_15)
    ],
	products: [
		.library(name: "FolioReaderKit", targets: ["FolioReaderKit"])
	],
	dependencies: [
        .package(url: "https://github.com/drearycold/ZipArchive.git", from: "2.2.5"),
        .package(url: "https://github.com/cxa/MenuItemKit.git", from: "3.0.0"),
        .package(url: "https://github.com/tadija/AEXML.git", from: "4.3.3"),
        .package(url: "https://github.com/ArtSabintsev/FontBlaster.git", from: "5.1.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.3.2"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.11"),
        .package(url: "https://github.com/SlaunchaMan/GCDWebServer.git", .branch("swift-package-manager")),
        // .Package(url: "https://github.com/fantim/JSQWebViewController.git", majorVersion: 6, minor: 1),
        ],
        targets: [
        .target(
            name: "FolioReaderKit",
            dependencies: ["AEXML", "ZipArchive", "FontBlaster", "MenuItemKit", "SwiftSoup", "ZIPFoundation", "GCDWebServer"],
            exclude: [],
            resources: [
                .process("Resources/Bridge.js"),
                .process("Resources/Style.css"),
                .process("Resources/readium-cfi.umd.js"),
                .process("Resources/Images.xcassets")
            ]
        ),
		.testTarget(
            name: "FolioReaderKitTests",
            dependencies: ["FolioReaderKit"],
            exclude: ["Info.plist"]
        )
	]
)
	
