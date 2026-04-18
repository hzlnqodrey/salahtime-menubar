#!/bin/bash
# Build script for creating Salah Time DMG release
# Usage: ./scripts/build-dmg.sh

set -e

APP_NAME="SalahTime"
SCHEME="SalahTime"
BUILD_DIR="build"
DIST_DIR="dist"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
DMG_PATH="${DIST_DIR}/${APP_NAME}.dmg"

echo "🕌 Building Salah Time..."

# Clean previous builds
rm -rf "${BUILD_DIR}" "${DIST_DIR}"
mkdir -p "${BUILD_DIR}" "${DIST_DIR}"

# Build archive
echo "📦 Creating archive..."
xcodebuild archive \
    -project "${APP_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -archivePath "${ARCHIVE_PATH}" \
    -configuration Release \
    -quiet

# Export app
echo "📤 Exporting app..."
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist scripts/ExportOptions.plist \
    -quiet 2>/dev/null || {
    # Fallback: copy app directly from archive
    echo "⚠️  Export failed (no signing identity), copying .app directly..."
    cp -R "${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app" "${EXPORT_PATH}/${APP_NAME}.app" 2>/dev/null || {
        mkdir -p "${EXPORT_PATH}"
        cp -R "${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app" "${EXPORT_PATH}/"
    }
}

APP_PATH="${EXPORT_PATH}/${APP_NAME}.app"

if [ ! -d "${APP_PATH}" ]; then
    echo "❌ Build failed: ${APP_PATH} not found"
    exit 1
fi

# Create DMG
echo "💿 Creating DMG..."
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${APP_PATH}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

echo ""
echo "✅ Build complete!"
echo "📍 DMG: ${DMG_PATH}"
echo "📏 Size: $(du -h "${DMG_PATH}" | cut -f1)"
echo ""
echo "To notarize (requires Apple Developer account):"
echo "  xcrun notarytool submit ${DMG_PATH} --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID --password YOUR_APP_PASSWORD"
