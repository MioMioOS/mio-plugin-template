//
//  MioPlugin.swift
//  MioIsland Plugin SDK
//
//  Standalone copy of the MioPlugin protocol from the host CodeIsland app.
//  At runtime, @objc protocol conformance is matched by selector signatures
//  (not module identity), so this duplicate works for .bundle plugins
//  loaded by NativePluginManager.
//
//  DO NOT change the selectors or the @objc-ness — the host walks them
//  via responds(to:) / perform(_:) and any divergence will silently break
//  loading.
//

import AppKit

@objc protocol MioPlugin: AnyObject {
    /// Stable identifier — used as the dedupe key. Lowercase, kebab-case.
    var id: String { get }

    /// Human-readable name shown in the Plugins settings page.
    var name: String { get }

    /// SF Symbol name for the icon shown in the notch header bar.
    var icon: String { get }

    /// Semver version. Must increase across releases (the marketplace enforces this).
    var version: String { get }

    /// Called once after the plugin is loaded. Use this to start any background
    /// work (timers, observers, etc.). Runs on the main actor.
    func activate()

    /// Called when the plugin is unloaded (or the app is quitting). Stop everything.
    func deactivate()

    /// The main view shown when the user taps the plugin icon in the notch header.
    /// Wrap your SwiftUI view in NSHostingView.
    func makeView() -> NSView

    /// Optional: contribute small views into named UI slots in the host app.
    /// Slots: "header" (20x20 button next to other plugin icons), "footer", etc.
    @objc optional func viewForSlot(_ slot: String, context: [String: Any]) -> NSView?
}
