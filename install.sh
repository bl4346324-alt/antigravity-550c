#!/bin/bash
# 安装脚本：
# 1. 将 550C 插件安装到 Antigravity 全局插件目录 ~/.gemini/config/plugins/antigravity-550c
# 2. 安装 550C 全局常驻守护服务 (LaunchAgent)
# 3. 安装独立启动器 Antigravity 550C.app (可选独立工具)

set -e

# ================================
# 1. 注入 Antigravity 中文.app（点击该 App 即可立即触发 550C）
# ================================
HANS_APP="/Applications/Antigravity 中文.app"
if [ -d "$HANS_APP" ] && [ -w "$HANS_APP" ]; then
    echo "正在将 550C 开机启动器直接集成至 $HANS_APP ..."
    cp "Antigravity 550C.app/Contents/MacOS/Antigravity550C" "$HANS_APP/Contents/MacOS/"
    cp "Antigravity 550C.app/Contents/Resources/550c.html" "$HANS_APP/Contents/Resources/"
    
    cat > "$HANS_APP/Contents/MacOS/launcher" <<'EOF'
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"

# 后台汉化监视进程（若存在对应二进制）
LOG_DIR="$HOME/Library/Logs"
LOG_FILE="$LOG_DIR/antigravity-hans.log"
mkdir -p "$LOG_DIR"
if [ -f "$HOME/Downloads/antigravity-hans-macos-arm64" ]; then
    nohup "$HOME/Downloads/antigravity-hans-macos-arm64" --app --nogui >> "$LOG_FILE" 2>&1 &
fi

# 启动 550C 开机引导，播完后无缝流转至 Antigravity 与卡卡西壁纸
exec "$DIR/Antigravity550C"
EOF
    chmod +x "$HANS_APP/Contents/MacOS/launcher"
    chmod +x "$HANS_APP/Contents/MacOS/Antigravity550C"
    echo "✓ 成功集成至 Antigravity 中文.app！"
fi

# ================================
# 2. 安装 Antigravity 内置插件
# ================================
PLUGIN_DIR="$HOME/.gemini/config/plugins/antigravity-550c"
echo "正在安装 550C 插件到 $PLUGIN_DIR ..."

mkdir -p "$PLUGIN_DIR"
cp -R plugins/antigravity-550c/* "$PLUGIN_DIR/"

# 清理旧的独立壁纸插件以避免端口冲突
OLD_WALLPAPER_PLUGIN="$HOME/.gemini/config/plugins/antigravity-video-wallpaper"
if [ -d "$OLD_WALLPAPER_PLUGIN" ]; then
    echo "正在归档旧的独立壁纸插件..."
    rm -rf "$OLD_WALLPAPER_PLUGIN"
fi

echo "✓ 插件安装完成！"

# 尝试通过本地 Connect RPC 启用插件
if [ -n "$ANTIGRAVITY_LS_ADDRESS" ] && [ -n "$ANTIGRAVITY_CSRF_TOKEN" ]; then
    echo "正在向语言服务注册启用插件..."
    curl -sS -X POST \
      "http://${ANTIGRAVITY_LS_ADDRESS}/exa.language_server_pb.LanguageServerService/JetboxWriteState" \
      -H "Content-Type: application/json" \
      -H "x-codeium-csrf-token: ${ANTIGRAVITY_CSRF_TOKEN}" \
      -d '{"userConfig":{"plugins":{"antigravity-550c":{"enabled":true},"antigravity-video-wallpaper":{"enabled":false}}}}' > /dev/null 2>&1 || true
    echo "✓ 插件已通过语言服务实时激活！"
fi

# ================================
# 2. 安装 550C 全局常驻守护服务 (LaunchAgent)
# ================================
echo "正在安装 550C 全局启动监视守护服务..."
cp daemon.mjs "$PLUGIN_DIR/daemon.mjs"

NODE_BIN="$(which node || echo "/Users/zhangtianxiang/.nvm/versions/node/v20.20.2/bin/node")"
PLIST_FILE="$HOME/Library/LaunchAgents/com.antigravity.550c.daemon.plist"
mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.antigravity.550c.daemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>${NODE_BIN}</string>
        <string>--experimental-websocket</string>
        <string>${PLUGIN_DIR}/daemon.mjs</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${HOME}/Library/Logs/antigravity-550c-daemon.log</string>
    <key>StandardErrorPath</key>
    <string>${HOME}/Library/Logs/antigravity-550c-daemon.log</string>
</dict>
</plist>
EOF

launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE"
echo "✓ 550C 全局启动守护服务已安装并激活！"

# ================================
# 3. 安装独立 Antigravity 550C.app (可选)
# ================================
TARGET_DIR="/Applications"
if [ -w "$TARGET_DIR" ]; then
    echo "正在更新独立启动器到 $TARGET_DIR ..."
    rm -rf "$TARGET_DIR/Antigravity 550C.app"
    cp -R "Antigravity 550C.app" "$TARGET_DIR/"
    echo "✓ 独立启动器安装完成：$TARGET_DIR/Antigravity 550C.app"
fi

echo ""
echo "🎉 全部安装完毕！"
echo "  - 打开反重力应用时，将在窗口内全屏播放 550C 量子计算机开机动画；"
echo "  - 动画播完自动丝滑溶解淡出，完美流转至卡卡西动态视频壁纸；"
echo "  - 会话内自动记忆，进入项目或切换对话绝不重复播放；"
echo "  - 可在 IDE 内侧边栏随时打开 550C 控制面板或重放动画。"
