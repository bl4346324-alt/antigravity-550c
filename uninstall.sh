#!/bin/bash
# ==============================================================================
# Antigravity 550C & 动态壁纸 卸载与清理脚本
# ==============================================================================

set -e

echo "🛑 正在卸载 Antigravity 550C 与动态壁纸..."

# 1. 停止并移除 LaunchAgent 守护服务
PLIST="$HOME/Library/LaunchAgents/com.antigravity.550c.daemon.plist"
if [ -f "$PLIST" ]; then
    echo "  -> 停止并移除后台守护进程 (LaunchAgent)..."
    launchctl unload "$PLIST" 2>/dev/null || true
    rm -f "$PLIST"
fi

# 2. 终止残留进程
pkill -f "daemon.mjs" 2>/dev/null || true
pkill -f "Antigravity550C" 2>/dev/null || true

# 3. 实时清除当前 Antigravity 窗口中已注入的壁纸和样式
PORT_FILE="$HOME/Library/Application Support/Antigravity/DevToolsActivePort"
if [ -f "$PORT_FILE" ]; then
    PORT=$(head -n 1 "$PORT_FILE" | tr -d '\r\n')
    if [ -n "$PORT" ]; then
        echo "  -> 正在实时清除 Antigravity 窗口中的壁纸图层与毛玻璃样式..."
        node --experimental-websocket -e "
          try {
            const res = await fetch('http://127.0.0.1:$PORT/json');
            const list = await res.json();
            const page = list.find(t => t.type === 'page');
            if (page && page.webSocketDebuggerUrl) {
              const ws = new WebSocket(page.webSocketDebuggerUrl);
              ws.onopen = () => {
                const cleanCode = \`
                  (function() {
                    ['ag-video-bg', 'ag-wallpaper-scrim', 'ag-video-style', 'ag-boot-overlay'].forEach(id => {
                      const el = document.getElementById(id);
                      if (el) el.remove();
                    });
                    sessionStorage.removeItem('__ag_550c_boot_played');
                  })();
                \`;
                ws.send(JSON.stringify({ id: 1, method: 'Runtime.evaluate', params: { expression: cleanCode } }));
                setTimeout(() => ws.close(), 300);
              };
            }
          } catch (e) {}
        " 2>/dev/null || true
    fi
fi

# 4. 还原 /Applications/Antigravity 中文.app 的原始启动器
HANS_APP="/Applications/Antigravity 中文.app"
HANS_BACKUP="/Applications/Antigravity 中文.backup.app"

if [ -d "$HANS_APP" ] && [ -w "$HANS_APP" ]; then
    echo "  -> 还原 $HANS_APP 原始启动入口..."
    if [ -d "$HANS_BACKUP" ] && [ -f "$HANS_BACKUP/Contents/MacOS/launcher" ]; then
        cp "$HANS_BACKUP/Contents/MacOS/launcher" "$HANS_APP/Contents/MacOS/launcher"
    else
        cat > "$HANS_APP/Contents/MacOS/launcher" <<'EOF'
#!/bin/bash
LOG_DIR="$HOME/Library/Logs"
LOG_FILE="$LOG_DIR/antigravity-hans.log"
mkdir -p "$LOG_DIR"
if [ -f "$HOME/Downloads/antigravity-hans-macos-arm64" ]; then
    nohup "$HOME/Downloads/antigravity-hans-macos-arm64" --app --nogui >> "$LOG_FILE" 2>&1 &
fi
EOF
    fi
    chmod +x "$HANS_APP/Contents/MacOS/launcher"
    rm -f "$HANS_APP/Contents/MacOS/Antigravity550C"
    rm -f "$HANS_APP/Contents/Resources/550c.html"
    echo "  ✓ 已还原 Antigravity 中文.app"
fi

# 5. 移除独立的 /Applications/Antigravity 550C.app
if [ -d "/Applications/Antigravity 550C.app" ]; then
    echo "  -> 移除 /Applications/Antigravity 550C.app..."
    rm -rf "/Applications/Antigravity 550C.app"
fi

# 6. 移除 Antigravity 插件目录
PLUGIN_DIR="$HOME/.gemini/config/plugins/antigravity-550c"
if [ -d "$PLUGIN_DIR" ]; then
    echo "  -> 移除插件目录 $PLUGIN_DIR..."
    rm -rf "$PLUGIN_DIR"
fi

# 7. 若语言服务正在运行，向其发送禁用通知
if [ -n "$ANTIGRAVITY_LS_ADDRESS" ] && [ -n "$ANTIGRAVITY_CSRF_TOKEN" ]; then
    curl -sS -X POST \
      "http://${ANTIGRAVITY_LS_ADDRESS}/exa.language_server_pb.LanguageServerService/JetboxWriteState" \
      -H "Content-Type: application/json" \
      -H "x-codeium-csrf-token: ${ANTIGRAVITY_CSRF_TOKEN}" \
      -d '{"userConfig":{"plugins":{"antigravity-550c":{"enabled":false}}}}' > /dev/null 2>&1 || true
fi

echo ""
echo "🎉 卸载与清理完成！"
echo "  - 背景壁纸与毛玻璃特效已移除，恢复原生默认外观；"
echo "  - 550C 启动动画与后台守护服务已彻底停止并卸载；"
echo "  - 原生 Antigravity 启动项已恢复。"
