#!/bin/bash
set -e

echo "📦 Bundling Morph.app..."

# 1. Compile debug binary
swift build --disable-index-store

BINARY_PATH=".build/out/Products/Debug/morph"
if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Binary not found at $BINARY_PATH"
    exit 1
fi

# 2. Setup bundle structure
APP_BUNDLE="Morph.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Copy executable
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/morph"
chmod +x "$APP_BUNDLE/Contents/MacOS/morph"

# 4. Generate Info.plist
cat <<EOF > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>morph</string>
    <key>CFBundleIdentifier</key>
    <string>com.morph.utility</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Morph</string>
    <key>CFBundleDisplayName</key>
    <string>Morph</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
EOF

# 5. Ad-hoc codesign
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

echo "✨ Successfully bundled $APP_BUNDLE!"
