# FolioReaderKit 单元测试完善计划 (Gemini CLI 执行指令)

## 🎯 角色与目标
你是一个资深的 iOS 测试工程师。你的目标是为 Swift 编写的 ePub 阅读器框架 `FolioReaderKit` 补充缺失的核心单元测试。
当前项目已存在基础的测试目录 `Tests/FolioReaderKitTests/`，你需要使用苹果原生的 `XCTest` 框架编写高覆盖率、无副作用的测试用例。

## ⚠️ 全局执行约束 (每次任务必读)
1. **独立性**：每个 Task 必须是自包含的，不允许依赖其他未执行的 Task。
2. **测试框架**：统一使用原生的 `XCTest`，不要引入额外的第三方测试库（如 Quick/Nimble），避免增加依赖复杂性。
3. **断言规范**：使用 `XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertNotNil` 等进行严格断言。如果是异步逻辑或 JS 注入，使用 `XCTestExpectation`。
4. **验证命令**：每次修改完代码后，必须通过 MCP 调用 Xcode 运行测试，或者直接执行 `swift test -Xswiftc -DTESTING` 确保编译通过且测试全绿。
5. **Mock 与依赖隔离**：对于涉及 `WKWebView` 或外部持久化 (Provider) 的测试，必须在测试 target 内创建 Mock 类（如 `MockScriptMessageHandler`, `MockHighlightProvider`），不可真实触发 UI 渲染或磁盘 I/O。

---

## 📋 测试任务队列 (请逐一读取并执行)

### TEST-TASK-001：核心数据模型 (Models) 测试
- **目标文件**：创建 `Tests/FolioReaderKitTests/FolioReaderHighlightTests.swift` 和 `Tests/FolioReaderKitTests/FolioReaderBookmarkTests.swift`
- **上下文背景**：高亮 (Highlight) 和 书签 (Bookmark) 的模型已与 Realm 解耦，变为了纯 Swift 类。我们需要确保它们的基础属性映射、Equatable / Comparable 逻辑正确。
- **具体指令**：
  1. 编写测试验证 `FolioReaderHighlight` 的初始化，并测试 `<` 操作符（基于 `page` 和 `startOffset` 进行比对）。
  2. 验证 `FolioReaderHighlight.matchHighlight(_:)` 的正则匹配逻辑，传入带有 HTML 标签的字符串，断言能否正确匹配。
  3. 编写测试验证 `FolioReaderBookmark` 遵循 `Comparable` 协议的逻辑，特别是 `cfiStart` 字符串的切分比对。
- **验收条件**：`swift test --filter FolioReaderHighlightTests` 以及 `FolioReaderBookmarkTests` 全部通过。

### TEST-TASK-002：解耦后的数据 Provider 协议集成测试
- **目标文件**：创建 `Tests/FolioReaderKitTests/MockProvidersTests.swift`
- **上下文背景**：为了替代 Realm，框架引入了 `FolioReaderHighlightProvider` 和 `FolioReaderBookmarkProvider` 协议。
- **具体指令**：
  1. 在测试文件中实现一个基于内存 `Array` 或 `Dictionary` 的 `MockHighlightProvider`。
  2. 编写测试用例：保存一条高亮数据 -> 根据 ID 查询该高亮 -> 断言内容一致 -> 根据 ID 移除高亮 -> 断言查询结果为 nil。
  3. 编写测试用例：验证 `allByBookId` 方法能够正确筛选出特定 `bookId` 且分页正确的记录。
- **验收条件**：所有针对 MockProvider 的 CRUD 操作断言全部通过，证明协议设计闭环。

### TEST-TASK-003：JS Bridge 消息处理逻辑测试 (核心)
- **目标文件**：创建 `Tests/FolioReaderKitTests/EpubJSBridgeTests.swift`
- **上下文背景**：Swift 与 JavaScript 通过 `WKScriptMessageHandler` 通信，需要验证发自 JS 的消息能否被正确解析为 `JSCommand` 枚举。
- **具体指令**：
  1. 针对 P1 重构中新增的 `EpubJSBridge` 类（或同等重构后的 Bridge 层），编写单元测试。
  2. 模拟构造包含不同指令的 `WKScriptMessage`（如注入 `"bridgeFinished"` 或带负载的 JSON 字符串）。
  3. 验证 Bridge 是否能正确地将这些字符串解析为对应的枚举，并通过 Delegate 或闭包准确回传给调用方。
- **验收条件**：覆盖所有已定义的 JS 到 Swift 通信指令（`bridgeFinished`, `writingMode`, `getComputedStyle` 等），并正确触发断言。

### TEST-TASK-004：排版与 ePub 核心解析测试补全 (EPUBCore)
- **目标文件**：修改 `Tests/FolioReaderKitTests/FolioReaderKitTests.swift` (或创建 `FREpubParserTests.swift`)
- **上下文背景**：原本的解析测试依赖 Quick 框架且存放在 Example 中。我们需要在原生 SPM Tests 中补全对 `FRBook` 和目录引用的测试。
- **具体指令**：
  1. 构建模拟的 `FRResource` 和 `FRTocReference` 对象。
  2. 测试 `FRBook` 中基于这些对象的组装逻辑，特别是 `flatTableOfContents` 的展平计算逻辑是否正确（测试多层级嵌套的 TOC 树）。
  3. 测试 `MediaType` 结构体：断言 `MediaType.epub.defaultExtension` 等常量映射正确，且等号 `==` 运算符重载计算准确无误。
- **验收条件**：不依赖真实的 `.epub` 磁盘文件，完全通过内存对象构建来测试 `EPUBCore` 的数据结构。


