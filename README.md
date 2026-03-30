![FolioReader logo](https://raw.githubusercontent.com/FolioReader/FolioReaderKit/assets/folioreader.png)
FolioReaderKit is an ePub reader and parser framework for iOS written in Swift.

![Version](https://img.shields.io/badge/version-1.4.0-blue.svg)
![License](https://img.shields.io/badge/license-BSD-green.svg)

## Features

- [x] ePub 2 and ePub 3 support
- [x] Custom Fonts
- [x] Custom Text Size
- [x] Text Highlighting
- [x] List / Edit / Delete Highlights
- [x] Themes / Day mode / Night mode
- [x] Handle Internal and External Links
- [x] Portrait / Landscape
- [x] Reading Time Left / Pages left
- [x] In-App Dictionary
- [x] Media Overlays (Sync text rendering with audio playback)
- [x] TTS - Text to Speech Support
- [x] Parse epub cover image
- [x] RTL Support
- [x] Vertical or/and Horizontal scrolling
- [x] Share Custom Image Quotes **<sup>NEW</sup>**
- [x] Support multiple instances at same time, like parallel reading **<sup>NEW</sup>**
- [ ] Book Search
- [ ] Add Notes to a Highlight

## Installation

**FolioReaderKit** is available through Swift Package Manager (SPM).

### Swift Package Manager

In Xcode, go to **File > Add Packages...** and enter the repository URL:

```text
https://github.com/drearycold/FolioReaderKit.git
```

Choose the dependency rule that suits your needs (e.g., Up to Next Major Version) and click **Add Package**.

## Requirements

- iOS 13.0+
- macOS 11.0+ (Catalyst)
- Xcode 12.0+

## Basic Usage

To get started, this is a simple usage sample of using the integrated view controller. Note that you now need to provide a `ReadiumGCDWebServer` instance to serve the EPUB content locally.

```swift
import FolioReaderKit
import ReadiumGCDWebServer

let webServer = ReadiumGCDWebServer()

func open(sender: AnyObject) {
    let config = FolioReaderConfig()
    let bookPath = Bundle.main.path(forResource: "book", ofType: "epub")
    let folioReader = FolioReader()
    
    // Provide the webServer instance required for serving EPUB resources
    folioReader.presentReader(
        parentViewController: self, 
        withEpubPath: bookPath!, 
        andConfig: config,
        folioReaderCenterDelegate: nil,
        webServer: webServer
    )
}
```

For more usage examples check the `Example` folder.

## Architecture & Migration

This fork features a modernized architecture:
- **SPM First**: Migrated from CocoaPods/Carthage to Swift Package Manager.
- **Local WebServer**: Uses `GCDWebServer` to serve EPUB assets via `http://localhost`, resolving `file://` URL restrictions in modern `WKWebView`.
- **Concurrency**: Adopts Swift `async/await` for EPUB parsing and extraction using `ZIPFoundation`.
- **Persistence**: Removed the hard dependency on `Realm`. Integrators must now provide their own persistence via the `FolioReaderPreferenceProvider`, `FolioReaderHighlightProvider`, and `FolioReaderBookmarkProvider` protocols.

## Author
[**Heberti Almeida**](https://github.com/hebertialmeida)

- Follow me on **Twitter**: [**@hebertialmeida**](https://twitter.com/hebertialmeida)
- Contact me on **LinkedIn**: [**hebertialmeida**](http://linkedin.com/in/hebertialmeida)

## License
FolioReaderKit is available under the BSD license. See the [LICENSE](/LICENSE) file.