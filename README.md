# 3D科技树 - Technology Tree

使用Godot 4.7引擎开发的3D科技树可视化游戏，展示人类近代科学发展历程。

许可：代码 **MIT**，文档、科技树数据与原创素材 **CC BY 4.0**。详见[授权范围](LICENSES.md)。

## 🎮 快速开始

1. 安装 [Godot 4.7+](https://godotengine.org/download/)
2. 双击 `project.godot` 或在Godot项目管理器中导入
3. 按 `F5` 运行游戏（主场景：`scenes/main.tscn`）

详细说明请查看 [快速开始.md](快速开始.md)

## ✨ 主要特性

- **32个科技节点**: 从文艺复兴到现代AI的完整科学发展脉络
- **🌀 立体圆盘布局**: 每一层形成真正的3D圆盘，彻底立体化
- **渐进式解锁**: 基于真实科学史的前置条件系统
- **时间加速**: 支持1x/2x/4x/8x四种速度
- **固定中轴浏览**: 分离控制绕轴翻滚和沿轴平移

## 🎯 操作方法

### 从上到下（默认）
| 操作 | 效果 |
|------|------|
| **左右拖动** | 绕垂直轴翻滚旋转 |
| **上下拖动** | 沿轴平移（看不同层） |
| 滚轮 | 缩放距离 |
| 点击节点 | 解锁科技 |

### 从左到右
| 操作 | 效果 |
|------|------|
| **上下拖动** | 绕水平轴翻滚旋转 |
| **左右拖动** | 沿轴平移（看不同期） |
| 滚轮 | 缩放距离 |
| 点击节点 | 解锁科技 |

**PageDown切换方向** | PageUp切换速度

1.3.0 的平移采用抓住画面拖动：纵向上拖时内容上移，横向右拖时内容右移。两个模式的默认观察角均为 30°。

## 🔀 固定中轴线系统

### 从上到下（默认）
- 垂直中轴线（Y轴）固定
- **左右拖动**：绕轴翻滚，环视圆盘
- **上下拖动**：沿轴平移，浏览层级
- 俯瞰整体层级结构

### 从左到右
- 水平中轴线（X轴）固定
- **上下拖动**：绕轴翻滚，调整仰俯
- **左右拖动**：沿轴平移，浏览时期
- 强调时间线发展

详见 [固定中轴操作说明.md](固定中轴操作说明.md)

## 📚 文档

- [快速开始.md](快速开始.md) - 新手入门指南
- [GAME_INSTRUCTIONS.md](GAME_INSTRUCTIONS.md) - 详细游戏说明
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - 项目技术总结
- [tech_tree.md](tech_tree.md) - 科技树内容说明

## 🗂️ 项目结构

```
├── scenes/          # Godot场景文件
│   ├── main.tscn           # 主场景
│   └── tech_node.tscn      # 科技节点预制体
├── scripts/         # GDScript脚本
│   ├── tech_tree_manager.gd    # 主管理器
│   ├── tech_node.gd            # 节点逻辑
│   ├── camera_controller.gd    # 相机控制
│   └── tooltip_ui.gd           # 提示框UI
├── tech_tree.json   # 科技树数据（32节点+69连接）
└── project.godot    # Godot项目配置
```

## 🎨 科技分类

- 🔵 **天文与物理** - 从开普勒到量子力学
- 🟠 **数学与信息** - 从微积分到人工智能
- 🟢 **化学与材料** - 从炼金术到纳米科技
- 🔴 **生物与医学** - 从解剖学到基因编辑
- 🟣 **地球科学** - 从地质学到气候动力学

## 🛠️ 技术栈

- **引擎**: Godot 4.7.2
- **语言**: GDScript
- **渲染**: OpenGL Compatibility（兼容更多显卡）
- **平台**: Windows / macOS / Linux

## 📝 开发说明

- 已启用 `addons/godot_mcp` 插件（版本 2026.10.15）
- 使用Compatibility渲染器以提高兼容性
- 科技树数据保存在 `tech_tree.json` 中，可自定义扩展

交互回归测试：

```powershell
& "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_interactions.gd
& "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_layout_modes.gd
& "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_prerequisite_unlocks.gd
& "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_prerequisite_unlocks.gd -- --vertical
& "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_drag_release.gd
& "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_fixed_axis.gd
& "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_drag_sampling.gd
```

测试覆盖双向缩放、相机稳定性、实际视口点击、点数和前置条件、提示状态与完整解锁流程。

当前 1.3.0 的七组共 689 项检查全部通过，包含快慢拖动一致性、内容跟随鼠标平移、新版 30° 视角与翻滚极点、开局可见性、布局连线同步、两种方向完整解锁及拖动与点击仲裁。初始视距自动适配科技树范围；点击在同一节点松开时确认，拖动、失焦、Esc 或切换方向会取消待购买。最新结果见 [1.3.0 修复与复测报告](V1_3_0_TEST_REPORT.md)。

---

**版本**: 1.3.0 | **更新**: 2026年10月

## 许可协议

- **代码、场景与工程配置**：[MIT](LICENSE)。
- **文档、科技树数据与原创素材**：[CC BY 4.0](LICENSE-CC-BY-4.0.txt)。
- **第三方内容**：沿用原有授权与署名，包括 `addons/godot_mcp/` 插件。

作者署名：**kanade-EdTech**。完整适用范围、来源及署名示例见 [LICENSES.md](LICENSES.md)。

