#!/bin/sh
# Uploads the builds to itch.io with butler. Needs a one-time "butler login" first.
# Usage: tools/push_itch.sh youruser/anda [version]
set -e
cd "$(dirname "$0")/.."
TARGET=$1
VERSION=${2:-1.0.0}
if [ -z "$TARGET" ]; then
	echo "usage: $0 user/game [version]"
	exit 1
fi
butler push build/web "$TARGET:html5" --userversion "$VERSION"
butler push build/itch/Anda-macOS.zip "$TARGET:mac" --userversion "$VERSION" --fix-permissions
butler push build/windows "$TARGET:windows" --userversion "$VERSION"
butler push build/linux "$TARGET:linux" --userversion "$VERSION" --fix-permissions
butler status "$TARGET"
