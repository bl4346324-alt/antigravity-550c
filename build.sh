#!/bin/bash
set -e

echo "==> 正在编译 Antigravity 550C 启动器与插件..."
if [ -d "repo-dsh-550c-boot" ]; then
    python3 build_app_html.py
fi
python3 build_sidecar_html.py

mkdir -p "Antigravity 550C.app/Contents/MacOS" "Antigravity 550C.app/Contents/Resources"

clang -fobjc-arc -framework Cocoa -framework WebKit -framework QuartzCore main.m -o "Antigravity 550C.app/Contents/MacOS/Antigravity550C"
cp 550c.html "Antigravity 550C.app/Contents/Resources/"
cp AppIcon.icns "Antigravity 550C.app/Contents/Resources/"
codesign --force --deep --sign - "Antigravity 550C.app"

echo "✓ 构建完成！"
echo "  - 原生启动器：Antigravity 550C.app"
echo "  - Antigravity 插件：plugins/antigravity-550c"
