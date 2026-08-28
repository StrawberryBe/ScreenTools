#!/bin/bash
# Builds a Release ScreenTools.app and packages it as dist/ScreenTools.dmg and
# dist/ScreenTools.zip for colleagues to install without building from source.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DERIVED_DATA="$ROOT/.package-build"
STAGE="$ROOT/dist/stage"
DIST="$ROOT/dist"

rm -rf "$DERIVED_DATA" "$STAGE"
mkdir -p "$STAGE" "$DIST"

xcodegen generate

xcodebuild -project ScreenTools.xcodeproj -scheme ScreenTools -configuration Release \
  -derivedDataPath "$DERIVED_DATA" build

APP_SRC="$DERIVED_DATA/Build/Products/Release/ScreenTools.app"
if [ ! -d "$APP_SRC" ]; then
  echo "error: built app not found at $APP_SRC" >&2
  exit 1
fi

cp -R "$APP_SRC" "$STAGE/ScreenTools.app"
ln -s /Applications "$STAGE/Applications"
cp "$ROOT/README.md" "$STAGE/README.md"

rm -f "$DIST/ScreenTools.dmg"
hdiutil create -volname "Screen Tools" -srcfolder "$STAGE" -ov -format UDZO "$DIST/ScreenTools.dmg"

rm -f "$DIST/ScreenTools.zip"
(cd "$STAGE" && zip -r -y -q "$DIST/ScreenTools.zip" "ScreenTools.app")

rm -rf "$DERIVED_DATA"

echo "Packaged:"
echo "  $DIST/ScreenTools.dmg"
echo "  $DIST/ScreenTools.zip"
