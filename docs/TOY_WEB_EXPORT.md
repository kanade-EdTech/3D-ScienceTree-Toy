# B站 Toy / Web 导出指南 (Web Export Guide)

版本：**1.3.0** | 导出环境：**Godot 4.7.2 正式单线程 Web 模板 (Compatibility / WebGL 2)**

可上传产物：`dist/3D-TechnologyTree-1.3.0-Toy-Web.zip`（约 9.95 MiB）。ZIP 根目录直接包含 `index.html`，上传时请直接上传整个 ZIP 包。

---

## 一、 已完成的 Web 与移动端适配

1. **单线程免隔离环境运行**：关闭线程（Threads）、GDExtension 和 PWA/Service Worker，不依赖 `COOP/COEP` 响应头，支持直接嵌入第三方平台 `iframe` 与子目录。
2. **相对路径与资源内嵌**：入口与引擎资源均使用相对路径；[`tech_tree.json`](../tech_tree.json) 与 [`tech_layout.json`](../tech_layout.json) 已打包入 `.pck`。
3. **内置中文字体子集**：嵌入 `Noto Sans SC` 精简中文字形子集（约 249 KB），UI 界面与 3D 空间标签共用，无需访客设备安装中文字体。字体遵循 SIL OFL 1.1 协议并随包附带 `FONT-LICENSE.txt`。
4. **桌面与移动端触屏双适配**：
   * 内置**方向切换、速度切换、放大、缩小、全屏**快捷按钮；手机窄屏下按钮自动停靠底部。
   * 开启触摸模拟鼠标，支持触屏点选解锁与单指拖动旋转/平移，且拖动松手不会误触发购买。
   * 采用 `expand` 画布适配策略，消除手机竖屏下的大面积黑边。

---

## 二、 本地预览与一键重新导出

### 1. 启动本地 HTTP 预览服务
> ⚠️ 请勿直接双击 `index.html` 通过 `file://` 协议打开，WebAssembly 与 `.pck` 资源包必须通过 HTTP/HTTPS 加载。

```powershell
python tools/serve_toy_web.py
```
启动后在浏览器访问：<http://127.0.0.1:8876/preview.html>

### 2. 一键重新导出并打包 ZIP
```powershell
powershell -ExecutionPolicy Bypass -File tools/export_toy.ps1
```
* 脚本会自动调用已安装的 Godot 4.7.2 导出至 `build/toy-web/index.html`，并调用 `tools/package_toy_web.py` 生成最终的 `dist/3D-TechnologyTree-1.3.0-Toy-Web.zip`。
* 若本地缺少单线程 Web 导出模板（`tools/export_templates/web_nothreads_release.zip`），脚本会通过 `tools/fetch_web_template.py` 自动从 Godot 官方发布包按需拉取。

### 3. 更新中文字体子集（仅在新增中文文案时执行）
若修改了 [`tech_tree.json`](../tech_tree.json) 或脚本中的中文文本，请先运行字体子集生成脚本，再执行导出：
```powershell
python tools/subset_web_font.py
```

---

## 三、 验证与预检记录

* **Godot 导出与 ZIP 校验**：导出零错误零警告，ZIP 根目录包含 10 个运行时文件。
* **Toy Doctor 预检**：0 ERROR（结果详见 `dist/toy-doctor.json`，文件 SHA-256 清单详见 `dist/toy-web-manifest.json`）。
* **多端实测**：通过桌面端 `1280×720` 及 Chromium 移动设备模拟（`390×844` 竖屏 / `844×390` 横屏）的触屏解锁、拖动、缩放与方向切换测试。
