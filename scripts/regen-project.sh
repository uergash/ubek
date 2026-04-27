#!/usr/bin/env bash
# Regenerates the Xcode project from project.yml using xcodegen 2.42, which
# generates the older project format (objectVersion=54 + compatibilityVersion)
# that Xcode 15.4 supports natively. The Homebrew-shipped xcodegen 2.45+
# generates the newer Xcode-16-only format that Xcode 15.4 cannot save.

set -euo pipefail
cd "$(dirname "$0")/.."

XCODEGEN_BIN="/tmp/xcodegen-old/xcodegen/bin/xcodegen"

if [ ! -x "$XCODEGEN_BIN" ]; then
  echo "Downloading xcodegen 2.42 (one-time)…"
  mkdir -p /tmp/xcodegen-old
  cd /tmp/xcodegen-old
  curl -sL "https://github.com/yonaskolb/XcodeGen/releases/download/2.42.0/xcodegen.zip" -o xcodegen.zip
  unzip -oq xcodegen.zip
  cd - >/dev/null
fi

rm -rf Friend.xcodeproj
"$XCODEGEN_BIN" generate
echo "✓ Project regenerated."
