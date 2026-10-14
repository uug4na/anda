#!/bin/sh
# Exports every platform and packs the itch.io uploads into build/itch/.
# Run from anywhere: tools/package_itch.sh
set -e
cd "$(dirname "$0")/.."
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
rm -rf build
mkdir -p build/windows build/linux build/web build/itch
"$GODOT" --headless --path . --export-release "macOS" build/Anda-macOS.zip
"$GODOT" --headless --path . --export-release "Windows" build/windows/Anda.exe
"$GODOT" --headless --path . --export-release "Linux" build/linux/Anda.x86_64
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
cp build/Anda-macOS.zip build/itch/Anda-macOS.zip
(cd build/windows && zip -q ../itch/Anda-Windows.zip Anda.exe)
(cd build/linux && zip -q ../itch/Anda-Linux.zip Anda.x86_64)
(cd build/web && zip -q -r ../itch/Anda-Web.zip .)
echo "itch uploads:"
ls -la build/itch
