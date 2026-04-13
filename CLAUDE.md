# MioIsland Plugin — AI Build Guide

You are working in a MioIsland plugin repo. This file is your **contract**. Read it, then start coding. Do not read the README first — everything you need to ship is below.

## What you're building

A macOS `.bundle` directory loaded at runtime by the MioIsland host app (`/Applications/Code Island.app`). The host scans `~/.config/codeisland/plugins/*.bundle`, calls `Bundle.principalClass.init()`, and talks to your instance via `responds(to:)` / `perform(_:)`.

The bundle is one Swift module compiled to a single dylib + an `Info.plist`. **No Xcode project**, no SwiftPM manifest. You build it with one `swiftc` call wrapped in `build.sh`.

## Hard constraints — DO NOT CHANGE

These are the contract with the host. Breaking any of them = silent load failure.

1. **`Sources/MioPlugin.swift` is verbatim from the host app.** Do not edit it. Do not rename methods. Do not strip `@objc`. Selector matching is by name, not module identity, so any drift breaks loading.
2. **Your principal class must be `final class … : NSObject, MioPlugin`** (must inherit `NSObject` for `@objc` dispatch).
3. **`Info.plist NSPrincipalClass` is `<ModuleName>.<ClassName>`** — both PascalCase, dotted. The module name is whatever you pass to `swiftc -module-name`. Mismatch = host can't find the class.
4. **`Info.plist CFBundleExecutable` matches the dylib filename** in `Contents/MacOS/`. Mismatch = bundle won't load.
5. **Plugin `id` (the Swift `var id`) must be globally unique and stable.** Lowercase kebab-case. The marketplace dedupes on this.
6. **Version is semver** (`x.y.z`) and **must strictly increase** across submissions. Marketplace rejects equal-or-lower.
7. **macOS deployment target = 15.0.** The host links against macOS 15+ APIs.

## File layout

```
.
├── CLAUDE.md                 # this file
├── README.md                 # human-facing docs (you can ignore)
├── Info.plist                # bundle metadata
├── build.sh                  # swiftc + codesign + zip
└── Sources/
    ├── MioPlugin.swift       # protocol — frozen, do not touch
    └── MyPlugin.swift        # your code goes here
```

You can add more `.swift` files in `Sources/`. `build.sh` globs `Sources/*.swift`.

## The protocol you implement

```swift
@objc protocol MioPlugin: AnyObject {
    var id: String { get }              // "my-plugin" — kebab-case, stable
    var name: String { get }            // "My Plugin" — display name
    var icon: String { get }            // SF Symbol name, e.g. "music.note"
    var version: String { get }         // "1.0.0" — semver, must increase

    func activate()                     // one-shot init (timers, observers)
    func deactivate()                   // tear down whatever activate() started

    func makeView() -> NSView           // main view shown in the notch panel
                                        // wrap SwiftUI: NSHostingView(rootView: ...)

    @objc optional func viewForSlot(
        _ slot: String,
        context: [String: Any]
    ) -> NSView?                        // optional UI in named host slots
}
```

### viewForSlot slots

| Slot     | Size       | Purpose                                                |
|----------|------------|--------------------------------------------------------|
| `header` | 20×20 pts  | A small icon button next to other plugin icons in the notch header bar. Return a tightly-sized `NSHostingView`. Tap routing is automatic. |

Return `nil` for slots you don't handle. The optional method itself is optional — omit it if you don't need slot integration.

### Threading

- `activate()`, `deactivate()`, `makeView()`, `viewForSlot(_:context:)` are all called on the **main actor**.
- Anything async (timers, file watching, network) must explicitly hop with `Task { @MainActor in ... }` if it touches view state.
- See `mio-plugin-music`'s `MusicPlugin.activate()` for the canonical pattern.

### Layout budget

The host gives `makeView()` roughly **620×780 pts** in the expanded notch panel. Use `frame(maxWidth: .infinity, maxHeight: .infinity)` and let SwiftUI fill it. If you need scrolling for long content, use `ScrollView`.

## The four files you actually edit

To turn this template into your plugin, change these four things consistently:

1. **`Sources/MyPlugin.swift`**
   - Rename `class MyPlugin` to your class
   - Change `id`, `name`, `icon`, `version`
   - Implement `makeView()` to return your real view
2. **`Info.plist`**
   - `CFBundleIdentifier` → `com.mioisland.plugin.<your-id>`
   - `CFBundleName` → "Your Plugin"
   - `CFBundleExecutable` → `<YourModuleName>` (matches `build.sh` `MODULE_NAME`)
   - `NSPrincipalClass` → `<YourModuleName>.<YourClassName>`
3. **`build.sh`** (top of file)
   - `PLUGIN_NAME="your-id"` (kebab-case)
   - `MODULE_NAME="YourModuleName"` (PascalCase)
4. **(optional) Rename `Sources/MyPlugin.swift`** to match your class name. Not required — `swiftc` doesn't care.

These four must all line up: `id` ↔ `CFBundleIdentifier` suffix ↔ `<id>.bundle` filename, and `MODULE_NAME` ↔ `CFBundleExecutable` ↔ `NSPrincipalClass` prefix.

## Build commands

```bash
./build.sh              # build → ./build/<id>.bundle  +  ./build/<id>.zip
./build.sh install      # build, then copy to ~/.config/codeisland/plugins/
```

`build.sh` does:

```bash
swiftc \
    -emit-library \
    -module-name "${MODULE_NAME}" \
    -target arm64-apple-macos15.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -o "build/${PLUGIN_NAME}.bundle/Contents/MacOS/${MODULE_NAME}" \
    Sources/*.swift

cp Info.plist "build/${PLUGIN_NAME}.bundle/Contents/"
codesign --force --sign - "build/${PLUGIN_NAME}.bundle"
zip -qr "build/${PLUGIN_NAME}.zip" "${PLUGIN_NAME}.bundle"
```

Default target is **arm64 only**. For universal (Intel + Apple Silicon), compile twice with `-target arm64-apple-macos15.0` and `-target x86_64-apple-macos15.0`, then `lipo -create`.

Ad-hoc signing (`--sign -`) is intentional — no Apple Developer cert required, anyone can build.

## Test loop

```bash
./build.sh install                                  # rebuild + install
killall "Code Island" 2>/dev/null                   # quit running instance
open "/Applications/Code Island.app"                # restart to load fresh
```

Plugin appears in the header icon bar. Click your icon → expanded notch panel shows `makeView()`.

To verify the bundle loaded: System Settings → Plugins → look for your plugin name with the version number.

If it doesn't appear, check Console.app for `[NativePluginManager]` errors. Common causes:

- `principal class … missing MioPlugin methods` → your class doesn't conform, or you broke the protocol selectors
- `Failed to load bundle` → `swiftc` succeeded but the dylib references something macOS can't resolve (e.g. you imported a framework not available on the deployment target)
- `Duplicate plugin ID` → another plugin (or an older copy of yours) has the same `id` — `rm -rf ~/.config/codeisland/plugins/<id>.bundle` and reinstall

## Gotchas

- **Don't `import` modules from CodeIsland** (e.g. `import ClaudeIsland`). The host doesn't expose its modules. You only have `Foundation` / `AppKit` / `SwiftUI` / `Combine` / standard Apple SDKs.
- **Don't change `Sources/MioPlugin.swift`.** It must stay byte-identical to the host's protocol. If you need to update it, copy from the host repo's `ClaudeIsland/Services/Plugin/MioPlugin.swift`.
- **Use `final class`** for your principal class. Open classes confuse `@objc` dispatch in some toolchain versions.
- **`activate()` is called once and isn't re-entrant.** Idempotency is on you.
- **No emojis in code or strings unless the user specifically asks.** Project convention.
- **Brand color** if you want to match the host theme: `Color(red: 0xCA/255, green: 0xFF/255, blue: 0x00/255)` (lime `#CAFF00`).
- **System fonts only.** Don't bundle .ttf files — they won't load from a plain `.bundle`.

## Examples to learn from

Both are real, shipping plugins. Read them when stuck:

- **`mio-plugin-music`** — Now Playing controls, header slot integration, `Task { @MainActor }` pattern
- **`mio-plugin-stats`** — bigger SwiftUI view, internal services (`AnalyticsCollector`), persistence in `Application Support`, subprocess (`claude` CLI) invocation, full i18n

Both ship as `.bundle` plugins built with the exact same `swiftc + codesign` recipe in this template.

## Marketplace flow

Once your plugin works locally:

1. Push your repo to GitHub
2. Sign in to **https://miomio.chat/developer** with GitHub
3. Install the marketplace's GitHub App on your repo (so reviewers can mirror the source to a private Gitea instance for security audit)
4. Submit: name (zh + en), description (zh + en, supports Markdown — README auto-fetched), icon, screenshots, upload `build/<id>.zip`
5. Reviewer approves → users can install via `System Settings → Plugins → Install from URL` with the generated link

Updates: bump `version` to a strictly higher semver, rebuild, submit a new version. The marketplace keeps the old approved versions downloadable for rollback.

## What you should do right now

If the user just asked you to "build a plugin that does X":

1. Pick a kebab-case `id` and PascalCase `MODULE_NAME` (e.g. `git-watch` + `GitWatch`)
2. Rename / edit the four files listed above to match
3. Implement `MyPlugin.makeView()` to return your actual view
4. `./build.sh install`
5. Restart MioIsland, verify your plugin shows up
6. Iterate

Do not generate a Package.swift, Xcode project, or test target. This template is intentionally one-file-build. Adding scaffolding will break `build.sh` and confuse the user.
