# MioIsland 插件模板

[![macOS](https://img.shields.io/badge/macOS-15%2B-black?style=flat-square&logo=apple)](https://github.com/MioMioOS/MioIsland)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)

[MioIsland](https://github.com/MioMioOS/MioIsland) 原生插件开发模板。MioIsland 是把 AI 编程助手活动放进 macOS 刘海里的应用。

这是一个 **Swift `.bundle` 插件模板** —— MioIsland 真正在运行时加载的格式。（旧的 JSON 模板在 v2.0 切换到原生插件系统后已废弃。）

[English](README.md)

---

## 快速开始

```bash
# Use this template 后:
git clone https://github.com/YOUR_USERNAME/YOUR_PLUGIN.git
cd YOUR_PLUGIN

# 编译并安装到本地
./build.sh install

# 重启 MioIsland —— 你的插件会出现在头部图标条
```

之后编辑 `Sources/MyPlugin.swift` 重新构建即可。

## 目录结构

```
.
├── Sources/
│   ├── MioPlugin.swift       # 协议定义 — 不要改 selector
│   └── MyPlugin.swift        # ← 改这个
├── Info.plist                # bundle 元数据（id / 版本号 / principal class）
├── build.sh                  # 编译 + 签名 + 打包 + 可选安装
└── README.md
```

## 工作原理

一个 MioIsland 插件本质上是一个 macOS `.bundle` 目录，包含：

1. `Contents/MacOS/<ModuleName>` 处的动态库
2. `Info.plist`，其中 `NSPrincipalClass` 指向一个 Swift 类
3. 这个类**必须遵循 `MioPlugin` `@objc` 协议**

MioIsland 启动时会扫描 `~/.config/codeisland/plugins/*.bundle`，调用 `Bundle.principalClass.init()`，然后通过 `responds(to:)` + `perform(_:)` 与你的实例通讯。所以：

- 协议必须是 `@objc`
- selector 必须和宿主完全一致（模板里 `MioPlugin.swift` 是宿主协议的逐字拷贝 —— 不要改）
- principal class 在 `Info.plist` 里写成 `<ModuleName>.<ClassName>` 的形式

协议很小：

```swift
@objc protocol MioPlugin: AnyObject {
    var id: String { get }              // 稳定标识符
    var name: String { get }            // 显示名
    var icon: String { get }            // SF Symbol 名称
    var version: String { get }         // semver
    func activate()                     // 加载时调用一次
    func deactivate()                   // 卸载时调用
    func makeView() -> NSView           // 主视图
    @objc optional func viewForSlot(_ slot: String, context: [String: Any]) -> NSView?
}
```

## 把模板改成你自己的插件

需要一致地修改四个地方：

1. **`Sources/MyPlugin.swift`** —— 改类名、改 `id` / `name` / `icon` / `version`
2. **`Info.plist`** —— 改 `CFBundleIdentifier` / `CFBundleName` / `CFBundleExecutable` / `NSPrincipalClass`
3. **`build.sh`** —— 改文件顶部的 `PLUGIN_NAME`（kebab-case）和 `MODULE_NAME`（PascalCase）
4. **（可选）重命名 `Sources/MyPlugin.swift`** 与你的类名匹配

Swift 类里的 `id` **必须**和 `CFBundleIdentifier`（`com.mioisland.plugin.<id>`）的 `<id>` 部分以及 build.sh 输出的 `<id>.bundle` 文件名相同。

## 编译参数说明

模板默认只编译 **arm64**（Apple Silicon）。如果需要通用二进制（Intel + Apple Silicon），把 `build.sh` 改为：

```bash
swiftc -target arm64-apple-macos15.0 ... -o build/arm64.dylib
swiftc -target x86_64-apple-macos15.0 ... -o build/x86_64.dylib
lipo -create build/arm64.dylib build/x86_64.dylib \
    -output "${BUILD_DIR}/${BUNDLE_NAME}/Contents/MacOS/${MODULE_NAME}"
```

## 发布到插件市场

1. 把插件源码推送到 GitHub 仓库
2. 用 GitHub 登录 [MioIsland 开发者中心](https://miomio.chat/developer)
3. 在你的仓库上安装我们的 GitHub App，让市场可以镜像源码用于审核
4. 提交插件：填写名称、描述、图标、截图、上传 `build/<plugin-id>.zip`
5. 我们审核源码（镜像到内部 Gitea）后批准

通过审核后，用户有两种安装方式：

- 在 MioIsland 的 `系统设置 → Plugins → Install from URL` 粘贴一键安装链接
- 直接下载 .zip

发布更新时只需要把 `version` 改成更高的 semver 版本号（必须严格大于上一个已通过的版本），重新提交构建即可。

## 实际案例

可以参考的成熟插件源码：

- [mio-plugin-music](https://github.com/MioMioOS/mio-plugin-music) —— 系统 Now Playing（Spotify / Apple Music）控制，带 header slot
- [mio-plugin-stats](https://github.com/MioMioOS/mio-plugin-stats) —— 报纸式日/周统计，国际化 + Claude 编辑寄语

## 许可

模板本身使用 MIT 协议。你的插件可以选择任何许可。
