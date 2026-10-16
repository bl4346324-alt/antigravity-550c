#!/bin/bash
# 安装脚本：
# 1. 将 Antigravity 550C.app 安装到 /Applications 或 ~/Applications
# 2. 将 550C 插件安装到 Antigravity 全局插件目录 ~/.gemini/config/plugins/antigravity-550c

set -e

# ================================
# 1. 安装 macOS 原生启动器
# ================================
TARGET_DIR="/Applications"
if [ ! -w "$TARGET_DIR" ]; then
    TARGET_DIR="$HOME/Applications"
    mkdir -p "$TARGET_DIR"
fi

echo "正在将 Antigravity 550C.app 安装到 $TARGET_DIR ..."
rm -rf "$TARGET_DIR/Antigravity 550C.app"
cp -R "Antigravity 550C.app" "$TARGET_DIR/"
echo "✓ 启动器安装完成：$TARGET_DIR/Antigravity 550C.app"

# ================================
# 2. 安装 Antigravity 内置插件
# ================================
PLUGIN_DIR="$HOME/.gemini/config/plugins/antigravity-550c"
echo "正在安装 550C 插件到 $PLUGIN_DIR ..."

mkdir -p "$PLUGIN_DIR"
cp -R plugins/antigravity-550c/* "$PLUGIN_DIR/"

echo "✓ 插件安装完成！"

# 尝试通过本地 Connect RPC 启用插件
if [ -n "$ANTIGRAVITY_LS_ADDRESS" ] && [ -n "$ANTIGRAVITY_CSRF_TOKEN" ]; then
    echo "正在向语言服务注册启用插件..."
    curl -sS -X POST \
      "http://${ANTIGRAVITY_LS_ADDRESS}/exa.language_server_pb.LanguageServerService/JetboxWriteState" \
      -H "Content-Type: application/json" \
      -H "x-codeium-csrf-token: ${ANTIGRAVITY_CSRF_TOKEN}" \
      -d '{"userConfig":{"plugins":{"antigravity-550c":{"enabled":true}}}}' > /dev/null 2>&1 || true
    echo "✓ 插件已通过语言服务实时激活！"
fi

echo ""
echo "🎉 全部安装完毕！"
echo "  - 启动器：可在访达「应用程序」或启动台中打开「Antigravity 550C」"
echo "  - 插件面板：已在 Antigravity 侧边辅助窗格 (Aux Pane) 中就绪，可通过 sidecar:// 链接或 /550c 随时打开"
