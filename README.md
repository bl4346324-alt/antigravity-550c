# Antigravity 550C (流浪地球 550C 启动器与量子终端插件)

<p align="center">
  <img src="AppIcon.icns" width="128" height="128" alt="Antigravity 550C Icon" />
</p>

<p align="center">
  专为 <b>Google Antigravity</b> 打造的《流浪地球2》550C 量子计算机开机动画启动器、内置量子终端与动态视频壁纸插件。<br/>
  支持 <b>macOS 原生开机引导</b>、<b>卡卡西 2K 动态视频壁纸联轴流转</b> 与 <b>Antigravity 内部 Sidecar 插件面板</b>！
</p>

---

## 🌟 核心特性

- 🎬 **完整 550C 电影级覆写序列（约 16 秒）**：
  - **开机标志阶段**：黑底上 550C 矢量标志逐路径笔画描边书写、红色量子核心发光脉冲、开机文本打字显现；
  - **量子终端阶段**：标志平滑溶解展开至量子控制终端，时钟、系统遥测、47 个无人机/智能体节点逐点覆写变绿；
  - **交互弹窗与指令**：基站接入授权确认弹窗、双频链路监控波形、紧急动力切断指令；
  - **终幕通告**：倒计时完毕后中央金色通告 `SYSTEM IS REWRITTEN · ANTIGRAVITY READY` 闪耀展现。
- 🎨 **卡卡西写轮眼 2K 动态视频壁纸无缝联轴**：
  - 550C 终幕通告展示完毕后，全屏以 **0.7 秒电影级平滑溶解（Cross-Dissolve）** 淡出；
  - 焦点无缝流转至 Antigravity 主界面，此时卡卡西动态壁纸已在后台流畅运转，**告别灰屏/黑屏等待**！
  - 启动后进入项目欢迎页即自动全屏渲染壁纸，无需先点击具体项目。
- ⚡ **随时跳过支持**：播放途中可随时按下键盘 <kbd>Esc</kbd> 或鼠标点击任意位置，立即丝滑切入壁纸工作区。
- 🧩 **Antigravity 内部 Sidecar 双面板**：
  - `/550c`：在侧边栏辅助窗格 (Aux Pane) 随时回放 550C 动画或监控终端；
  - `/wallpaper`：实时调整卡卡西壁纸毛玻璃不透明度、背景模糊度、饱和度，并支持一键切换主题皮肤（蔚蓝幻想、晶莹琉璃、深海之歌、黑曜极客）。

---

## 📦 如何在 Antigravity 中安装此插件

本项目提供了多种灵活的安装方式，您可以选择最便捷的途径：

### 方式一：一键全自动安装（最推荐）

该方式会自动完成插件安装、向 Antigravity 语言服务热注册、配置全局开机守护服务，并无缝注入启动器。

1. **克隆或下载本仓库**到本地：
   ```bash
   git clone https://github.com/bl4346324-alt/antigravity-550c.git
   cd antigravity-550c
   ```

2. **运行一键安装脚本**：
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. **安装脚本自动完成的事项**：
   - 自动将插件同步至 Antigravity 全局插件目录：`~/.gemini/config/plugins/antigravity-550c/`；
   - 自动通过本地 Connect RPC 向 Antigravity 语言服务发送激活指令，**免重启实时生效**；
   - 自动配置并加载常驻守护服务（`~/Library/LaunchAgents/com.antigravity.550c.daemon.plist`），负责后台提供壁纸视频流与启动检测；
   - 自动将 550C 引导启动器集成至 `/Applications/Antigravity 中文.app` 与 `/Applications/Antigravity 550C.app`。

---

### 方式二：手动安装到 Antigravity 全局插件目录

如果您只想将它作为 Antigravity 内置插件使用：

1. **创建全局插件目录**：
   ```bash
   mkdir -p ~/.gemini/config/plugins/antigravity-550c
   ```

2. **复制插件文件**：
   在本项目根目录下执行：
   ```bash
   cp -R plugins/antigravity-550c/* ~/.gemini/config/plugins/antigravity-550c/
   ```

3. **在 Antigravity 中启用插件**：
   - **方式 A（界面管理）**：在 Antigravity 任意对话中点击或打开插件设置：
     [管理 antigravity-550c 插件](customization://antigravity-550c)
     在打开的插件面板中确保其状态切换为 **Enabled**（已启用）。
   - **方式 B（命令行 RPC 激活）**：在终端中运行以下命令实时热激活：
     ```bash
     curl -sS -X POST "http://${ANTIGRAVITY_LS_ADDRESS:-localhost:5387}/exa.language_server_pb.LanguageServerService/JetboxWriteState" \
       -H "Content-Type: application/json" \
       -H "x-codeium-csrf-token: ${ANTIGRAVITY_CSRF_TOKEN}" \
       -d '{"userConfig":{"plugins":{"antigravity-550c":{"enabled":true}}}}'
     ```

---

### 方式三：直接让 Antigravity 智能体助手安装

如果您正在使用 Antigravity 进行对话编程，可以直接在聊天框中向 AI 助手发送指令：

> *“请帮我安装并启用本工作区中的 antigravity-550c 插件”*

AI 助手将自动通过内置的 `plugin` 技能完成目录配置和插件的热重载。

---

## 🎮 使用指南

### 1. 点击图标享受开机 550C $\to$ 卡卡西壁纸流转
- 点击平时使用的 **Antigravity 中文.app**、**Antigravity.app** 或 **Antigravity 550C.app**；
- 屏幕中央立即全屏呈现 550C 电影质感开机画面；
- 播完后自动平滑溶解，无缝切入已渲染好卡卡西动态壁纸的 Antigravity 工作区！

### 2. 在 Antigravity 内打开 550C 量子终端面板
- 在对话中直接点击终端链接：
  - [550C Quantum Terminal](sidecar://antigravity-550c/terminal/)
- 或者在聊天框中直接发送 `/550c` 触发该技能面板，可随时重播完整动画或查看 47 节点覆写状态。

### 3. 打开动态视频壁纸与皮肤控制中心
- 在对话中点击壁纸控制面板：
  - [DSH Skin & Wallpaper Center](sidecar://antigravity-550c/controller/)
- 或者在聊天框中发送 `/wallpaper`：
  - 可自由调节毛玻璃的不透明度、模糊度和色彩饱和度；
  - 支持一键切换蔚蓝幻想、晶莹琉璃、深海之歌、黑曜极客主题；
  - 自动记忆您的偏好设置。

---

## 🛠️ 从源码重新构建

如果您自行修改了 HTML、CSS、Objective-C 源码或静态资源，可以运行一键构建脚本重新打包：

```bash
chmod +x build.sh
./build.sh
```

构建脚本会自动：
1. 更新组装启动器与 Sidecar 终端页面；
2. 使用 `clang` 编译原生 arm64 启动器二进制 `Antigravity550C`；
3. 更新打包 `Antigravity 550C.app` 并完成 Ad-hoc 代码签名。

构建完成后再次运行 `./install.sh` 即可同步至系统。

---

## 📁 目录结构

```
antigravity-550c/
├── Antigravity 550C.app/                 # 🚀 macOS 原生启动器应用包
│   └── Contents/
│       ├── Info.plist                    # 应用元数据
│       ├── MacOS/Antigravity550C         # 原生可执行文件 (Mach-O arm64)
│       └── Resources/                    # 550c.html 页面与 AppIcon.icns
├── plugins/antigravity-550c/             # 🧩 Antigravity 内置插件包
│   ├── plugin.json                       # 插件清单 (Manifest)
│   ├── assets/logo.png                   # 插件图标
│   ├── skills/
│   │   ├── 550c/SKILL.md                 # /550c 终端技能定义
│   │   └── wallpaper/SKILL.md            # /wallpaper 壁纸皮肤中心技能定义
│   ├── sidecars/
│   │   ├── terminal/                     # 550C 侧边栏量子终端 Web UI
│   │   └── controller/                   # 壁纸与皮肤毛玻璃控制台 Web UI
│   └── skins/                            # 4 款高品质毛玻璃主题预设
├── daemon.mjs                            # 🛰️ 全局守护服务 (提供壁纸流与启动检测)
├── main.m                                # ⚙️ 原生 Cocoa 启动器源码
├── 550c.html                             # 🎬 550C 原生启动器单页
├── AppIcon.icns                          # 🎨 1024x1024 高清图标
├── build.sh                              # 🛠️ 一键编译打包脚本
├── install.sh                            # 📦 一键安装与注入脚本
└── README.md                             # 📖 项目文档
```

---

## 🙏 致谢 / Credits

- **550C 动画与 SVG 矢量原稿**：由 [Voidpoket](https://github.com/Voidpoket) 创作设计。
- **工程化灵感**：参考了 [yannicksong0106/dsh-550c-boot](https://github.com/yannicksong0106/dsh-550c-boot) 的移植与增强架构。

---

## 📄 开源许可证

本项目基于 [MIT 许可证](LICENSE) 开源。
