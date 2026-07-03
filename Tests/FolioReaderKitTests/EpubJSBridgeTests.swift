import XCTest
import WebKit
@testable import FolioReaderKit

class EpubJSBridgeTests: XCTestCase {
    
    class MockBridgeDelegate: EpubJSBridgeDelegate {
        var lastCommand: EpubJSBridge.JSCommand?
        var lastMessage: String?
        var expectation: XCTestExpectation?
        
        func epubJSBridge(_ bridge: EpubJSBridge, didReceiveCommand command: EpubJSBridge.JSCommand, message: String) {
            lastCommand = command
            lastMessage = message
            expectation?.fulfill()
        }
    }
    
    func testBridgeFinishedCommand() {
        let bridge = EpubJSBridge()
        let delegate = MockBridgeDelegate()
        bridge.delegate = delegate
        
        let expectation = XCTestExpectation(description: "Command received")
        delegate.expectation = expectation
        
        let message = MockWKScriptMessage(body: "bridgeFinished <html>body</html>")
        bridge.userContentController(WKUserContentController(), didReceive: message)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(delegate.lastCommand, EpubJSBridge.JSCommand.bridgeFinished)
        XCTAssertEqual(delegate.lastMessage, "<html>body</html>")
    }
    
    func testWritingModeCommand() {
        let bridge = EpubJSBridge()
        let delegate = MockBridgeDelegate()
        bridge.delegate = delegate
        
        let expectation = XCTestExpectation(description: "Command received")
        delegate.expectation = expectation
        
        let message = MockWKScriptMessage(body: "writingMode vertical-rl")
        bridge.userContentController(WKUserContentController(), didReceive: message)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(delegate.lastCommand, EpubJSBridge.JSCommand.writingMode)
        XCTAssertEqual(delegate.lastMessage, "vertical-rl")
    }

    func testGetComputedStyleCommand() {
        let bridge = EpubJSBridge()
        let delegate = MockBridgeDelegate()
        bridge.delegate = delegate
        
        let expectation = XCTestExpectation(description: "Command received")
        delegate.expectation = expectation
        
        let message = MockWKScriptMessage(body: "getComputedStyle font-size:16px")
        bridge.userContentController(WKUserContentController(), didReceive: message)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(delegate.lastCommand, EpubJSBridge.JSCommand.getComputedStyle)
        XCTAssertEqual(delegate.lastMessage, "font-size:16px")
    }
    
    func testUnknownCommand() {
        let bridge = EpubJSBridge()
        let delegate = MockBridgeDelegate()
        bridge.delegate = delegate
        
        let expectation = XCTestExpectation(description: "Command received")
        delegate.expectation = expectation
        
        let message = MockWKScriptMessage(body: "someRandomMethod someArgs")
        bridge.userContentController(WKUserContentController(), didReceive: message)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(delegate.lastCommand, EpubJSBridge.JSCommand.unknown)
        XCTAssertEqual(delegate.lastMessage, "someRandomMethod someArgs")
    }
    
    func testNonStringBodyCommand() {
        let bridge = EpubJSBridge()
        let delegate = MockBridgeDelegate()
        bridge.delegate = delegate
        
        // Non-string body (e.g. dictionary) should be ignored and delegate not called
        let message = MockWKScriptMessage(body: ["key": "value"])
        bridge.userContentController(WKUserContentController(), didReceive: message)
        
        XCTAssertNil(delegate.lastCommand)
        XCTAssertNil(delegate.lastMessage)
    }
}
