# 任务队列 (重构)

### TASK-001：移除包管理工具中的 Realm 依赖
- **目标文件**：`Package.swift`, `FolioReaderKit.podspec`, `Cartfile`
- **当前问题**：框架在包层级硬编码绑定了 Realm 数据库依赖，导致宿主 App 无法自由选择持久化方案 [3, 4]。
- **具体指令**：
  1. 在 `Package.swift` 中，移除 `dependencies` 里的 Realm 依赖项（`https://github.com/realm/realm-cocoa.git`）[4]。
  2. 在 `Package.swift` 的 `FolioReaderKit` target 中，移除 `.product(name: "RealmSwift", package: "Realm")` [4]。
  3. 在 `FolioReaderKit.podspec` 中，删除（或注释掉）遗留的 Realm 依赖（如果存在）[3]。
- **验收条件**：运行 `swift build` 能够成功下载依赖（不再包含 Realm）。
- **依赖任务**：无
- **预计改动行数**：10 行

### TASK-002：清理 FolioReaderConfig 中的 Realm 耦合
- **目标文件**：`Sources/FolioReaderKit/FolioReaderConfig.swift`
- **当前问题**：配置类持有了强依赖的三方 Realm 配置属性，违背依赖倒置原则 [12, 13]。
- **具体指令**：
  1. 删除 `FolioReaderConfig` 中 `realmConfiguration` 属性的声明和任何初始化代码 [12, 13]。
  2. 删除文件顶部可能存在的 `import RealmSwift`。
- **验收条件**：使用 `xcodebuild -scheme FolioReaderKit` 编译目标文件通过，确保无 Realm 符号错误。
- **依赖任务**：TASK-001
- **预计改动行数**：20 行

### TASK-003：拆分 FolioReaderCenter 分页逻辑 (引入 ReaderPaginationEngine)
- **目标文件**：`Sources/FolioReaderKit/Center/FolioReaderCenter.swift`, `Sources/FolioReaderKit/Center/ReaderPaginationEngine.swift` (新建)
- **当前问题**：`FolioReaderCenter` 类中充斥着复杂的页面跳转与进度计算逻辑，导致类极度臃肿 [14, 15]。
- **具体指令**：
  1. 创建 `ReaderPaginationEngine.swift` 文件，定义 `ReaderPaginationEngine` 类。
  2. 将 `FolioReaderCenter` 中的 `changePageWith(page:animated:completion:)` 等 10 多个翻页相关方法剪切到 `ReaderPaginationEngine` 中 [14]。
  3. 在 `FolioReaderCenter` 中添加 `let paginationEngine = ReaderPaginationEngine(center: self)`。
  4. 将原有的外部调用重定向至 `paginationEngine.changePageWith(...)`。
- **验收条件**：`xcodebuild` 编译无错，且 `FolioReaderCenter.swift` 文件行数显著下降。
- **依赖任务**：无
- **预计改动行数**：150 行

### TASK-004：统一 JS Bridge 消息处理器
- **目标文件**：`Sources/FolioReaderKit/FolioReaderPage.swift`, `Sources/FolioReaderKit/EpubJSBridge.swift` (新建)
- **当前问题**：JS 回调通过字符串硬编码（如 `"bridgeFinished "`、`"writingMode "`）直接在 View 的 `WKScriptMessageHandler` 中解析，极易出错且难以扩展 [16]。
- **具体指令**：
  1. 新建 `EpubJSBridge.swift`，创建遵循 `WKScriptMessageHandler` 的 `EpubJSBridge` 类。
  2. 在类中定义 `enum JSCommand: String`，包含 `bridgeFinished`, `getComputedStyle`, `writingMode` 等枚举。
  3. 将 `FolioReaderPage` 中的 `userContentController(_:didReceive:)` 逻辑移至 `EpubJSBridge` [17]，并通过闭包或 Delegate 将解析后的强类型事件回传给 `FolioReaderPage`。
  4. 替换 `FolioReaderPage` 中绑定的 messageHandler 为 `EpubJSBridge` 实例。
- **验收条件**：`xcodebuild` 编译通过，`FolioReaderPage` 成功实现与 `EpubJSBridge` 的解耦。
- **依赖任务**：无
- **预计改动行数**：120 行

### TASK-005：剥离 UICollectionView 的 ScrollDelegate 逻辑
- **目标文件**：`Sources/FolioReaderKit/Center/UIScrollViewDelegation.swift`, `Sources/FolioReaderKit/Center/FolioReaderCenter.swift`
- **当前问题**：虽然分布在独立扩展中，但 ScrollDelegate 的所有具体计算（包含 WebView 的滑动抵消补偿）仍依附在 Center 下 [18, 19]。
- **具体指令**：
  1. 在 `UIScrollViewDelegation.swift` 中创建一个独立的 `class ReaderScrollDelegateHandler: NSObject, UIScrollViewDelegate` [18]。
  2. 将 `FolioReaderCenter` 的 `UIScrollViewDelegate` 协议相关方法移入新类 [18]。
  3. 在 `FolioReaderCenter` 中持有 `scrollHandler` 实例，并将 `collectionView.delegate = scrollHandler`（如果与 UICollectionViewDelegate 冲突，请注意协议继承拆分）。
- **验收条件**：`FolioReaderCenter` 不再直接实现 `UIScrollViewDelegate` 方法，编译无警告。
- **依赖任务**：TASK-003
- **预计改动行数**：100 行

### 补充说明: 测试准备
在执行 TEST-TASK-002 和 TEST-TASK-003 时，请先在 Tests/FolioReaderKitTests/ 目录下创建 MockHelpers.swift 文件，并将MOCK_TEMPLATES.md中的模板代码写入其中。后续的 XCTest 测试用例请直接实例化 MockHighlightProvider 和 MockWKScriptMessage 来进行断言验证，绝对不要在 SPM 测试 target 中引入 Realm 或进行真实的 WebView 渲染。
在执行 TEST-TASK-004 时，请使用 MockEpubBuilder.createBookWithNestedTOC() 在内存中直接获取一个 FRBook 实例。针对 book.flatTableOfContents 属性编写断言。由于 Mock 数据中包含 Chapter 2.1 和 Chapter 2.2 作为子节点，展平后的数组 .count 应该严格等于 6，并且 flatTableOfContents.title 应该是 "Chapter 2.1"。针对 MediaType 测试，直接使用 MediaType.epub.defaultExtension 断言其值为 "epub"，并构造两个包含相同属性的 MediaType 结构体，验证 == 运算符是否返回 true。
