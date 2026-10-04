#!/bin/bash
# 安装脚本：将 Antigravity 550C.app 安装到 /Applications 或 ~/Applications

TARGET_DIR="/Applications"

if [ ! -w "$TARGET_DIR" ]; then
    TARGET_DIR="$HOME/Applications"
    mkdir -p "$TARGET_DIR"
fi

echo "正在将 Antigravity 550C.app 安装到 $TARGET_DIR ..."
rm -rf "$TARGET_DIR/Antigravity 550C.app"
cp -R "Antigravity 550C.app" "$TARGET_DIR/"

echo "✓ 安装完成！应用位置：$TARGET_DIR/Antigravity 550C.app"
echo "你现在可以在 启动台 (Launchpad) 或访达的「应用程序」中找到它，也可以直接将其拖入程序坞 (Dock)。"
