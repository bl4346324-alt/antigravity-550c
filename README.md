# Antigravity 550C (流浪地球 550C 启动器与量子终端插件)

<p align="center">
  <img src="AppIcon.icns" width="128" height="128" alt="Antigravity 550C Icon" />
</p>

<p align="center">
  专为 <b>Google Antigravity 中文版</b> 打造的《流浪地球2》550C 量子计算机开机动画启动器与内置终端插件。<br/>
  支持 <b>macOS 原生独立启动器</b> 与 <b>Antigravity 内部 Sidecar 插件面板</b> 双模式！
</p>

---

## 🌟 核心特性

- 🎬 **完整 550C 覆写序列（约 16 秒）**：
  - 550C 矢量 Logo 逐路径笔画描边书写与辉光脉冲；
  - 复古 CRT 监控面板、系统遥测与真实时钟同步；
  - 47 个集群智能体节点（Agent Swarm Matrix）逐点覆写变绿；
  - 汇编固件流式注入与实时 CRC32 校验；
  - 终末中央通告：`SYSTEM IS REWRITTEN · ANTIGRAVITY READY`。
- 🎨 **原版琥珀金 CRT 配色**：极致还原电影中 550C 终端特有的暖黄/琥珀荧光色阶与等宽字符质感。
- 🚀 **全入口自动触发（无需选择项目即可享受）**：
  1. **全局启动守护 (LaunchAgent)**：通过 macOS 用户守护服务监听 Antigravity 启动，无论通过 Dock、Spotlight、Finder 打开官方 `Antigravity.app` 还是 `Antigravity 中文.app`，均在**点击打开 App 的第一时间自动全屏播放 550C 动画**，随后**丝滑淡出过渡至卡卡西 2K 动态视频壁纸**！
  2. **项目选择页无需等待**：打开 App 进入欢迎与项目选择界面时，卡卡西壁纸已全屏就绪，再也不需要「先点击一个具体项目才渲染壁纸」；
  3. **独立启动器 (`Antigravity 550C.app`) / 注入启动器 (`Antigravity 中文.app`)**：支持原生悬浮小窗预热引导；
  4. **Antigravity 内置插件面板**：侧边栏实时调整毛玻璃不透明度、模糊度、壁纸预设，并支持一键重新播放 550C 开机动画。

---

## 🚀 安装与使用

### 一键安装全部（启动器 + 全局守护 + 插件）

在项目根目录下执行安装脚本：

```bash
./install.sh
```

该脚本会自动完成：
1. **安装 550C 全局常驻守护服务 (`~/Library/LaunchAgents/com.antigravity.550c.daemon.plist`)**：点击任意 Antigravity 图标即刻触发 550C 启动动画与卡卡西壁纸流转；
2. **将原生引导器注入 `/Applications/Antigravity 中文.app`** 并安装 `Antigravity 550C.app`；
3. **将插件安装到 `~/.gemini/config/plugins/antigravity-550c/`** 并配置为 Dark 模式（彻底根除原生启动白屏闪烁）。

---

### 使用方式

#### 1. 开机引导启动
- 直接双击平时使用的 **Antigravity.app** 或 **Antigravity 中文.app**（或通过 Spotlight / Dock 打开）；
- 立即全屏自动播放 550C 量子计算机开机覆写动效（按 <kbd>Esc</kbd> 或点击可随时跳过）；
- 动画播完平滑消散，丝滑流转至卡卡西写轮眼动态壁纸；在欢迎页与选择项目界面背景已完全渲染！

#### 2. 在 Antigravity 内部作为侧边栏面板使用
- 在对话中直接点击终端链接：
  - [550C Quantum Terminal](sidecar://antigravity-550c/terminal/)
- 或者在聊天框中输入 `/550c` 触发该技能面板。
- 在插件管理页面中亦可查看并管理：`[antigravity-550c](customization://antigravity-550c)`。

---

## 🛠️ 自行构建 (从源码构建)

如果对样式、文案或逻辑进行了修改，可以运行内置的一键构建脚本：

```bash
./build.sh
```

构建脚本会自动完成：
1. 组装最新的原生启动器页面 `550c.html`；
2. 构建并适配 Antigravity Sidecar 插件面板页面 `plugins/antigravity-550c/sidecars/terminal/index.html`；
3. 编译原生 `Antigravity550C` Mach-O arm64 二进制文件；
4. 打包生成 `Antigravity 550C.app` 并完成 Ad-hoc 签名。

---

## 📁 目录结构

```
antigravity-550c/
├── Antigravity 550C.app/                 # 🚀 macOS 原生启动器应用包（开箱即用）
│   └── Contents/
│       ├── Info.plist                    # 应用元数据
│       ├── MacOS/Antigravity550C         # 原生可执行文件 (Mach-O arm64)
│       └── Resources/                    # 550c.html 页面与 AppIcon.icns
├── plugins/antigravity-550c/             # 🧩 Antigravity 内置插件包
│   ├── plugin.json                       # 插件清单 (Manifest)
│   ├── assets/logo.png                   # 插件图标
│   ├── skills/550c/SKILL.md              # /550c 技能描述与快捷跳转
│   └── sidecars/terminal/                # 侧边栏 Web UI (Sidecar)
│       ├── sidecar.json                  # Sidecar 配置 (SIDECAR_UI_ENTRYPOINT_AUX_PANE)
│       ├── package.json                  # ESM 模块声明
│       ├── main.mjs                      # 轻量 Sidecar 服务端
│       └── index.html                    # 550C 响应式交互终端页面
├── main.m                                # ⚙️ 原生 Cocoa 启动器源码
├── 550c.html                             # 🎬 550C 原生启动器单页
├── AppIcon.icns                          # 🎨 1024x1024 高清视网膜图标
├── build_app_html.py                     # 📄 原生启动器 HTML 构建脚本
├── build_sidecar_html.py                 # 📄 Sidecar 插件 HTML 构建脚本
├── build.sh                              # 🛠️ 一键编译打包脚本
├── install.sh                            # 📦 一键安装脚本
├── .gitignore                            # Git 忽略配置
└── README.md                             # 📖 项目文档
```

---

## 🙏 致谢 / Credits

- **550C 动画与 SVG 矢量原稿**：由 [Voidpoket](https://github.com/Voidpoket) 创作设计。
- **工程化灵感**：参考了 [yannicksong0106/dsh-550c-boot](https://github.com/yannicksong0106/dsh-550c-boot) 的移植与增强架构。

---

## 📄 开源许可证

本项目基于 [MIT 许可证](LICENSE) 开源。
