//
//  MyPlugin.swift
//  Example MioIsland Plugin
//
//  Replace this with your own plugin. The principal class — the one
//  named in Info.plist's NSPrincipalClass — must conform to MioPlugin.
//

import AppKit
import SwiftUI

/// Principal class for the example plugin. The fully-qualified name
/// `MyPlugin.MyPlugin` (module.class) goes into Info.plist as
/// `NSPrincipalClass`.
final class MyPlugin: NSObject, MioPlugin {
    var id: String { "my-plugin" }
    var name: String { "My Plugin" }
    var icon: String { "puzzlepiece.extension.fill" }
    var version: String { "1.0.0" }

    func activate() {
        // Start background work here if you need it (timers, observers, etc.)
    }

    func deactivate() {
        // Stop whatever activate() started.
    }

    func makeView() -> NSView {
        NSHostingView(rootView: MyPluginView())
    }
}

// MARK: - SwiftUI View

/// The view shown in the expanded notch panel when the user taps your
/// plugin's icon. The host app gives you roughly 620x780 to work with.
private struct MyPluginView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundColor(Color(red: 0xCA / 255, green: 0xFF / 255, blue: 0x00 / 255))
            Text("Hello from MyPlugin")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            Text("Edit Sources/MyPlugin.swift to make it your own.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
