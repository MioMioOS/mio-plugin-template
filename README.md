# MioIsland Plugin Template

[![macOS](https://img.shields.io/badge/macOS-15%2B-black?style=flat-square&logo=apple)](https://github.com/MioMioOS/MioIsland)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)

Template for creating native [MioIsland](https://github.com/MioMioOS/MioIsland) plugins. MioIsland is a macOS notch app that puts your AI agent activity in the hardware notch.

This template is a **Swift `.bundle` plugin** — the format MioIsland actually loads at runtime. (The old JSON-based template was deprecated when v2.0 shipped the native plugin system.)

[中文文档](README.zh-CN.md)

---

## Quick start

```bash
# Use this template, then:
git clone https://github.com/YOUR_USERNAME/YOUR_PLUGIN.git
cd YOUR_PLUGIN

# Build and install locally
./build.sh install

# Restart MioIsland — your plugin appears in the header bar.
```

Then edit `Sources/MyPlugin.swift` and rebuild.

## What's in the box

```
.
├── Sources/
│   ├── MioPlugin.swift       # The protocol — DO NOT change selectors
│   └── MyPlugin.swift        # ← edit this
├── Info.plist                # Bundle metadata (id / version / principal class)
├── build.sh                  # Build + sign + package + optional install
└── README.md
```

## How a MioIsland plugin works

A plugin is a macOS `.bundle` directory containing:

1. A compiled dynamic library at `Contents/MacOS/<ModuleName>`
2. An `Info.plist` whose `NSPrincipalClass` points to a Swift class
3. That class **must conform to the `MioPlugin` `@objc` protocol**

When MioIsland starts it scans `~/.config/codeisland/plugins/*.bundle`, calls `Bundle.principalClass.init()`, then talks to your instance via `responds(to:)` + `perform(_:)`. So:

- The protocol must be `@objc`
- Selectors must match the host's exactly (the `MioPlugin.swift` in this template is a verbatim copy of the host's protocol — leave it alone)
- Your principal class is named `<ModuleName>.<ClassName>` in `Info.plist`

The protocol is small:

```swift
@objc protocol MioPlugin: AnyObject {
    var id: String { get }              // stable identifier
    var name: String { get }            // human-readable
    var icon: String { get }            // SF Symbol name
    var version: String { get }         // semver
    func activate()                     // called once when loaded
    func deactivate()                   // called when unloaded
    func makeView() -> NSView           // your main view
    @objc optional func viewForSlot(_ slot: String, context: [String: Any]) -> NSView?
}
```

## Renaming the template to your plugin

You'll need to edit four things consistently:

1. **`Sources/MyPlugin.swift`** — rename the class, change `id` / `name` / `icon` / `version`
2. **`Info.plist`** — change `CFBundleIdentifier` / `CFBundleName` / `CFBundleExecutable` / `NSPrincipalClass`
3. **`build.sh`** — update `PLUGIN_NAME` (kebab-case) and `MODULE_NAME` (PascalCase) at the top
4. **(optional) Rename `Sources/MyPlugin.swift`** to match your class name

The `id` in your Swift class **must match** the `<plugin-id>` part of `CFBundleIdentifier` (`com.mioisland.plugin.<id>`) and the `<plugin-id>.bundle` filename produced by build.sh.

## Build flags reference

The template builds **arm64-only** (Apple Silicon). For universal binaries, change `build.sh` to:

```bash
swiftc \
    -emit-library \
    -module-name "${MODULE_NAME}" \
    -target arm64-apple-macos15.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -o build/arm64.dylib \
    ${SOURCES}

swiftc \
    -emit-library \
    -module-name "${MODULE_NAME}" \
    -target x86_64-apple-macos15.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -o build/x86_64.dylib \
    ${SOURCES}

lipo -create build/arm64.dylib build/x86_64.dylib \
    -output "${BUILD_DIR}/${BUNDLE_NAME}/Contents/MacOS/${MODULE_NAME}"
```

## Publishing to the marketplace

1. Push your plugin source to a GitHub repo
2. Sign in to the [MioIsland Developer Portal](https://miomio.chat/developer) with GitHub
3. Install our GitHub App on your repo so the marketplace can mirror the source for review
4. Submit your plugin: name, description, icon, screenshots, and upload `build/<plugin-id>.zip`
5. We review the source code (mirrored to a private Gitea instance) and approve

After approval users can install your plugin in two ways:

- One-click install URL pasted into MioIsland's `System Settings → Plugins → Install from URL`
- Direct download of the .zip

You can ship updates by bumping `version` (must be strictly greater than the previous approved version, semver format) and submitting a new build.

## Examples

Working plugins to study:

- [mio-plugin-music](https://github.com/MioMioOS/mio-plugin-music) — Now Playing (Spotify / Apple Music) controls in the notch, with header slot
- [mio-plugin-stats](https://github.com/MioMioOS/mio-plugin-stats) — Editorial-style daily/weekly stats with i18n and a Claude-powered editor's note

## License

MIT for the template itself. Your plugin can choose any license you want.
