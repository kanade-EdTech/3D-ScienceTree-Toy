# B站 Toy Web 导出

版本：1.3.0。导出日期：2026-10-24。Godot 4.7.2 正式单线程 Web 模板，Compatibility / WebGL 2。

可上传文件：`dist/3D-TechnologyTree-1.3.0-Toy-Web.zip`，10,430,330 字节（9.95 MiB）。ZIP 根目录直接包含 `index.html`，入口 5,265 字节。上传 ZIP 整包即可，不能只上传 HTML。

## 已完成的适配

- 关闭线程、GDExtension 和 PWA/Service Worker，不依赖 COOP/COEP 响应头。
- 入口与引擎资源使用相对路径，适用于 Toy 子目录。科技数据与点位数据均打入 PCK。
- 嵌入 Noto Sans SC 中文字形子集（约 249 KB），界面和 3D 标签共用，不依赖访客电脑上的中文字体。字体授权随 ZIP 的 `FONT-LICENSE.txt` 分发。
- 提供切换方向、速度、放大、缩小、全屏按钮；手机窄屏时按钮放在底部。开启触摸模拟鼠标，支持点击和拖动。
- Web 使用 expand 显示适配，避免手机竖屏保留横屏画幅和大面积黑边。横屏适合查看完整横向科技树；竖屏可拖动与缩放浏览。
- 导出包不含测试、编辑器插件、源码工具或浏览器测试截图。

## 验证结果

- 最终 Godot 导出成功，日志无错误或警告；ZIP 完整性检查通过，10 个根目录文件。
- Toy doctor 通过，无 ERROR；唯一 WARN 为三个引擎 JS 文件名不含内容指纹。它不影响上传或运行，但以后更新时访客可能需重新下载全部资源。保留 Godot 原生配套文件命名。
- 在本地 `/toy/technology-tree/index.html` 子路径及 iframe 中成功加载，运行时 `crossOriginIsolated=false`、`GODOT_THREADS_ENABLED=false`。最终浏览器控制台无脚本/资源错误。
- 桌面 1280×720：中文界面、实际鼠标购买（已解锁 1/32）、方向切换、速度和缩放按钮正常。
- Chromium 移动设备模拟：触屏点选成功购买（已解锁 1/32），触屏拖动改变视角且不误购买，触屏方向与缩放按钮正常；另检查 390×844 竖屏和 844×390 横屏。
- 相关 Godot 回归：交互 35 项、点位避让 1,433 项，全部通过。

另已通过 Toy 线上平台预览验证，并于 2026-10-24 提交审核（ID：47517110632448，状态 auditing）。未进行实体手机浏览器验证。全屏按钮受浏览器及宿主页授权控制。

## 上传与本地预览

已提交「3D 科学科技树」1.3.0，地址为 `https://www.bilibili.com/toy/3D-ScienceTree/index.html`，分类 GAME，仅链接可见。审核通过后生效。首次提交返回“缺少必要文件”，补充实际运行画面封面并改用新版官方 CLI 后提交成功。

审核预览：<https://www.bilibili.com/toy/preview/author_5fZDfYbn/index.html>。结果记录见 `dist/toy-submission-result.json`。

本地预览服务启动后访问：<http://127.0.0.1:8876/preview.html>。

```powershell
python tools/serve_toy_web.py
```

不要双击 `index.html` 用 file:// 打开，WebAssembly 和资源包需要通过 HTTP/HTTPS 加载。

## 再次导出

```powershell
powershell -ExecutionPolicy Bypass -File tools/export_toy.ps1
```

导出脚本使用已安装的 Godot 4.7.2，生成 Web 文件并打包 ZIP。缺少正式单线程模板时，会从 Godot 官方模板包按字节范围下载所需模板。

新增中文游戏文案时，应先更新字体子集：使用 `tools/subset_web_font.py`，依赖 fonttools 和 `tools/font-source/NotoSansSC.ttf`；常规重复导出直接使用已提交的字体即可。字体原文件来自 Google Fonts 的 Noto Sans SC，授权为 SIL OFL 1.1。

包文件清单及 SHA-256 见 `dist/toy-web-manifest.json`；Toy 预检结果见 `dist/toy-doctor.json`；浏览器截图在 `output/playwright/`。

参考：[Godot Web 导出文档](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)、[Toy 创作指南](https://www.bilibili.com/toy/publish/guide)、[Noto Sans SC 字体来源](https://github.com/google/fonts/tree/main/ofl/notosanssc)。本次 Toy 创作指南未能通过网页读取工具访问，包检查依据已安装 Toy 技能的预检规则及实际 doctor 结果。
