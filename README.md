# Antigravity 550C 启动器 (流浪地球 550C 开机动画)

专为 **Antigravity 中文版** 定制的《流浪地球2》550C 量子计算机开机引导启动器。

---

## 🌟 特性

- 🎬 **完整覆写流程（约 16 秒）**：
  - 550C 矢量 Logo 逐笔绘制与辉光脉冲；
  - 复古 CRT 遥测终端与实时时钟同步；
  - 47 个集群智能体节点（Agent Swarm Matrix）逐点覆写变绿；
  - 汇编固件流式注入与真实 CRC32 校验；
  - 中央通告：`SYSTEM IS REWRITTEN · ANTIGRAVITY READY`。
- 🎨 **原版琥珀金 CRT 配色**：极致还原电影中 550C 终端特有的暖黄/琥珀荧光色阶。
- ⚡ **无感预热与无缝衔接**：
  - 点击启动时，立即弹出全屏无边框 550C 开机动画；
  - 后台同时静默预热唤起 `/Applications/Antigravity 中文.app`；
  - 动画播完或跳过时，窗口优雅淡出，焦点直接切换到 Antigravity 中文版，**零等待时间**！
- ⏭️ **随时即时跳过**：按下 <kbd>Esc</kbd> 键或点击屏幕任意位置，立即打断动画淡出并进入主程序。
- 🛡️ **原生轻量与零破坏**：
  - 原生 Objective-C + Cocoa + WKWebView 构建，编译产物仅 ~75 KB，极速秒开；
  - 完全不篡改 Antigravity 原版程序文件，不影响代码签名，官方升级更新不失效；
  - 配备高清 1024x1024 专属 550C 视网膜应用图标（`AppIcon.icns`）。

---

## 🚀 安装与使用

### 1. 运行体验
在当前目录中即可直接运行：
```bash
open "Antigravity 550C.app"
```

### 2. 安装到系统应用程序
运行配套的安装脚本：
```bash
./install.sh
```
或者直接将 `Antigravity 550C.app` 拖入访达的 **应用程序 (Applications)** 文件夹。

### 3. 固定到程序坞 (Dock)
将安装好的 `Antigravity 550C.app` 从访达或启动台拖到屏幕下方的程序坞 (Dock) 中。以后点击该图标，即可享受 550C 开机仪式感！

---

## 📁 目录结构

```
antigravity-550c/
├── Antigravity 550C.app/       # 构建好的 macOS 原生应用程序包
│   └── Contents/
│       ├── Info.plist          # 应用程序元数据
│       ├── MacOS/              # 原生可执行文件 (Mach-O arm64)
│       └── Resources/          # 550c.html 页面与 AppIcon.icns 图标
├── main.m                      # 原生 Cocoa 启动器源码
├── 550c.html                   # 定制版 550C 完整模式动画页面
├── preview.html                # 独立的浏览器全功能预览播放器
├── install.sh                  # 一键安装脚本
└── repo-dsh-550c-boot/         # 参考的 GitHub 开源项目归档
```
