#!/bin/bash
set -e

echo "==> 正在编译 Antigravity 550C..."
python3 build_app_html.py

mkdir -p "Antigravity 550C.app/Contents/MacOS" "Antigravity 550C.app/Contents/Resources"

clang -fobjc-arc -framework Cocoa -framework WebKit -framework QuartzCore main.m -o "Antigravity 550C.app/Contents/MacOS/Antigravity550C"
cp 550c.html "Antigravity 550C.app/Contents/Resources/"
cp AppIcon.icns "Antigravity 550C.app/Contents/Resources/"
codesign --force --deep --sign - "Antigravity 550C.app"

echo "✓ 构建完成！产物：Antigravity 550C.app"
