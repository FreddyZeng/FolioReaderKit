// swift-tools-version:5.3
import PackageDescription

let package = Package(
	name: "FolioReaderKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
	products: [
		.library(name: "FolioReaderKit", targets: ["FolioReaderKit"])
	],
	dependencies: [
        .package(url: "https://github.com/cxa/MenuItemKit.git", from: "3.0.0"),
        .package(url: "https://github.com/tadija/AEXML.git", from: "4.3.3"),
        .package(url: "https://github.com/ArtSabintsev/FontBlaster.git", from: "5.1.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0"),
        .package(url: "https://github.com/readium/ZIPFoundation.git", from: "3.0.0"),
        .package(url: "https://github.com/readium/GCDWebServer.git", from: "4.0.0"),
    ],
	targets: [
        .target(
            name: "FolioReaderKit",
            dependencies: [
                "AEXML",
                "FontBlaster",
                "MenuItemKit",
                "SwiftSoup",
                .product(name: "ReadiumZIPFoundation", package: "ZIPFoundation"),
                .product(name: "ReadiumGCDWebServer", package: "GCDWebServer"),
            ],
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
	
