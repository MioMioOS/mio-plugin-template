#!/bin/bash
# Build the example plugin as a .bundle for MioIsland.
#
# Usage:
#   ./build.sh             # build to ./build/my-plugin.bundle
#   ./build.sh install     # also install to ~/.config/codeisland/plugins/
#
# After publishing your plugin, the user-facing flow is:
#   1. Marketplace generates a download URL
#   2. User pastes URL into MioIsland's Plugins settings
#   3. MioIsland downloads + extracts + loads the .bundle automatically
set -e

# ─── Edit these two lines to match your plugin ───────────────────────
PLUGIN_NAME="my-plugin"      # kebab-case, must match CFBundleIdentifier suffix
MODULE_NAME="MyPlugin"       # PascalCase, must match Info.plist NSPrincipalClass prefix
# ─────────────────────────────────────────────────────────────────────

BUNDLE_NAME="${PLUGIN_NAME}.bundle"
BUILD_DIR="build"
SOURCES="Sources/*.swift"

echo "Building ${PLUGIN_NAME} plugin..."

# Clean
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/${BUNDLE_NAME}/Contents/MacOS"

# Compile to dynamic library. arm64-only — most users are on Apple Silicon.
# Add x86_64 with `-target x86_64-apple-macos15.0` if you need Intel support
# and use `lipo` to fuse the two binaries.
swiftc \
    -emit-library \
    -module-name "${MODULE_NAME}" \
    -target arm64-apple-macos15.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -o "${BUILD_DIR}/${BUNDLE_NAME}/Contents/MacOS/${MODULE_NAME}" \
    ${SOURCES}

# Copy Info.plist
cp Info.plist "${BUILD_DIR}/${BUNDLE_NAME}/Contents/"

# Ad-hoc sign — required so macOS will load the bundle. No Apple Developer
# account needed; this works for everyone.
codesign --force --sign - "${BUILD_DIR}/${BUNDLE_NAME}"

echo "✓ Built ${BUILD_DIR}/${BUNDLE_NAME}"

# Package as .zip for marketplace upload. The marketplace expects a zip
# containing a single .bundle directory at the root.
cd "${BUILD_DIR}"
rm -f "${PLUGIN_NAME}.zip"
zip -qr "${PLUGIN_NAME}.zip" "${BUNDLE_NAME}"
cd ..

echo "✓ Created ${BUILD_DIR}/${PLUGIN_NAME}.zip (for marketplace upload)"
echo ""

if [ "${1:-}" = "install" ]; then
    DEST="${HOME}/.config/codeisland/plugins"
    mkdir -p "${DEST}"
    rm -rf "${DEST}/${BUNDLE_NAME}"
    cp -r "${BUILD_DIR}/${BUNDLE_NAME}" "${DEST}/"
    echo "✓ Installed to ${DEST}/${BUNDLE_NAME}"
    echo "  Restart MioIsland to load it."
else
    echo "Install locally:"
    echo "  ./build.sh install"
    echo ""
    echo "Or upload ${BUILD_DIR}/${PLUGIN_NAME}.zip via the marketplace at"
    echo "  https://miomio.chat/developer"
fi
