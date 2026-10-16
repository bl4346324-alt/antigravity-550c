#!/bin/bash
# 安装脚本：
# 1. 直接注入「Antigravity 中文.app」引导启动器
# 2. 将 Antigravity 550C.app 安装到 /Applications
# 3. 将 550C 插件安装到 Antigravity 全局插件目录 ~/.gemini/config/plugins/antigravity-550c

set -e

# ================================
# 1. 注入 Antigravity 中文.app
# ================================
HANS_APP="/Applications/Antigravity 中文.app"
if [ -d "$HANS_APP" ] && [ -w "$HANS_APP" ]; then
    echo "正在将 550C 开机启动器直接集成至 $HANS_APP ..."
    cp "Antigravity 550C.app/Contents/MacOS/Antigravity550C" "$HANS_APP/Contents/MacOS/"
    cp "Antigravity 550C.app/Contents/Resources/550c.html" "$HANS_APP/Contents/Resources/"
    
    cat > "$HANS_APP/Contents/MacOS/launcher" <<'EOF'
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"

# 后台汉化监视进程（若存在）
LOG_DIR="$HOME/Library/Logs"
LOG_FILE="$LOG_DIR/antigravity-hans.log"
mkdir -p "$LOG_DIR"
if [ -f "$HOME/Downloads/antigravity-hans-macos-arm64" ]; then
    nohup "$HOME/Downloads/antigravity-hans-macos-arm64" --app --nogui >> "$LOG_FILE" 2>&1 &
fi

# 启动 550C 开机引导，播完无缝切入 Antigravity
exec "$DIR/Antigravity550C"
EOF
    chmod +x "$HANS_APP/Contents/MacOS/launcher"
    chmod +x "$HANS_APP/Contents/MacOS/Antigravity550C"
    echo "✓ 成功集成至 Antigravity 中文.app！"
fi

# ================================
# 2. 安装独立 Antigravity 550C.app
# ================================
TARGET_DIR="/Applications"
if [ ! -w "$TARGET_DIR" ]; then
    TARGET_DIR="$HOME/Applications"
    mkdir -p "$TARGET_DIR"
fi

echo "正在将 Antigravity 550C.app 安装到 $TARGET_DIR ..."
rm -rf "$TARGET_DIR/Antigravity 550C.app"
cp -R "Antigravity 550C.app" "$TARGET_DIR/"
echo "✓ 独立启动器安装完成：$TARGET_DIR/Antigravity 550C.app"

# ================================
# 3. 安装 Antigravity 内置插件
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
echo "  - 现在无论您点击「Antigravity 中文」还是「Antigravity 550C」，都会先弹出 550C 引导画面并自动切入 Antigravity！"
echo "  - 插件面板亦已就绪，可在 IDE 内侧边栏随时打开查看。"
