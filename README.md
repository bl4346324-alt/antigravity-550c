# Antigravity 550C 启动器 (流浪地球 550C 开机动画)

<p align="center">
  <img src="AppIcon.icns" width="128" height="128" alt="Antigravity 550C Icon" />
</p>

<p align="center">
  专为 <b>Google Antigravity 中文版</b> 定制的《流浪地球2》550C 量子计算机开机引导启动器。<br/>
  启动时全屏播放硬核科技感 550C 开机序列，后台并发预热主程序，播完无缝切入工作区。
</p>

---

## 🌟 特性

- 🎬 **完整 550C 覆写序列（约 16 秒）**：
  - 550C 矢量 Logo 逐路径笔画描边书写与辉光脉冲；
  - 复古 CRT 监控面板、系统遥测与真实时钟同步；
  - 47 个集群智能体节点（Agent Swarm Matrix）逐点覆写变绿；
  - 汇编固件流式注入与实时 CRC32 校验；
  - 终末中央通告：`SYSTEM IS REWRITTEN · ANTIGRAVITY READY`。
- 🎨 **原版琥珀金 CRT 配色**：极致还原电影中 550C 终端特有的暖黄/琥珀荧光色阶与等宽字符质感。
- ⚡ **无感预热与无缝衔接**：
  - 双击启动后立即展示 550C 启动画面；
  - 后台静默并发拉起 `/Applications/Antigravity 中文.app`（若无则回退到 `/Applications/Antigravity.app`）；
  - 动画播完或跳过时，窗口平滑淡出，焦点无缝切换到 Antigravity 中文版，**零等待时间**！
- ⏭️ **随时即时跳过**：按下 <kbd>Esc</kbd> 键或**点击屏幕任意位置**，立即打断动画淡出并激活主程序。
- 🛡️ **原生轻量与零侵入**：
  - 采用原生 Objective-C + Cocoa + WKWebView 编写，编译二进制仅 ~75 KB，毫秒级冷启动；
  - 零侵入独立启动器架构，完全不修改 Antigravity 官方安装包，代码签名完好，软件自动升级不失效；
  - 配备高清 1024x1024 专属 550C 视网膜图标（`AppIcon.icns`）。

---

## 🚀 安装与使用

### 1. 克隆仓库
```bash
git clone https://github.com/bl4346324-alt/antigravity-550c.git
cd antigravity-550c
```

### 2. 直接运行
仓库已内置预编译好的应用，直接运行：
```bash
open "Antigravity 550C.app"
```

### 3. 一键安装到应用程序目录
执行安装脚本：
```bash
./install.sh
```
该脚本会将 `Antigravity 550C.app` 安装到你的 `/Applications`（或 `~/Applications`）。

### 4. 固定到程序坞 (Dock)
从访达的「应用程序」或启动台 (Launchpad) 将 **Antigravity 550C** 拖入屏幕下方的 **程序坞 (Dock)**。以后直接点击它启动 Antigravity，尽享硬核科幻仪式感！

---

## 🛠️ 自行构建 (从源码构建)

如果对样式、文案或逻辑进行了修改，可以运行内置的一键构建脚本重新编译应用：

```bash
./build.sh
```

构建脚本会自动完成：
1. 组装最新的 `550c.html` 动画页面；
2. 编译原生 `Antigravity550C` 可执行文件；
3. 打包生成 `Antigravity 550C.app` 应用程序包并自动签名。

---

## 📁 目录结构

```
antigravity-550c/
├── Antigravity 550C.app/       # 🚀 构建好的 macOS 原生应用程序包（开箱即用）
│   └── Contents/
│       ├── Info.plist          # 应用元数据与权限声明
│       ├── MacOS/              # 原生可执行文件 (Mach-O arm64)
│       └── Resources/          # 550c.html 页面与 AppIcon.icns 图标
├── main.m                      # ⚙️ 原生 Cocoa 启动器源码
├── 550c.html                   # 🎬 550C 琥珀金完整开机动画文件
├── AppIcon.icns                # 🎨 1024x1024 高清 550C 视网膜应用图标
├── build.sh                    # 🛠️ 一键编译与打包脚本
├── build_app_html.py           # 📄 动画页面构建与定制脚本
├── install.sh                  # 📦 一键安装到应用程序目录脚本
├── .gitignore                  # Git 忽略配置
└── README.md                   # 📖 项目文档
```

---

## 🙏 致谢 / Credits

- **550C 动画与 SVG 矢量原稿**：由 [Voidpoket](https://github.com/Voidpoket) 创作设计。
- **工程化灵感**：参考了 [yannicksong0106/dsh-550c-boot](https://github.com/yannicksong0106/dsh-550c-boot) 的移植与增强架构。

---

## 📄 开源许可证

本项目基于 [MIT 许可证](LICENSE) 开源。
