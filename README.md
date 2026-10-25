# 3D-ScienceTree-Toy | 人类近代科学交叉科技树

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](docs/reports/V2_0_0_TEST_REPORT.md)
[![Engine](https://img.shields.io/badge/Godot-4.7.2%20(GL%20Compatibility)-478cbf.svg)](https://godotengine.org/)
[![Code License: MIT](https://img.shields.io/badge/Code%20License-MIT-green.svg)](LICENSE)
[![Data & Docs: CC BY 4.0](https://img.shields.io/badge/Data%20%26%20Docs-CC%20BY%204.0-orange.svg)](LICENSE-CC-BY-4.0.txt)

**完整版权、第三方作者与许可原文：[COPYRIGHT.md](COPYRIGHT.md)**（含 32 个模型、纹理、字体、插件及引擎依赖）。

> **A 3D Interactive DAG & Micro Serious Game of Modern Science History**  
> 使用 Godot 4.7 引擎开发的 **3D 跨学科科技树微型严肃游戏（Software Toy）**。以文艺复兴时期的**天文观测、大地测量、炼金冶金、人体解剖**四大经验技艺为源头，用立体圆盘与有向无环图（DAG）还原从 15 世纪到当代人工智能与量子信息科学的 32 个核心学科节点与 69 条跨学科赋能脉络。

---

## ✨ 核心特性

* **🔬 真实科学史交叉图谱 (DAG)**：打破单线树状演进，涵盖 **5 个历史世代（Tier 0–4）**、**5 大学科谱系**、**32 个细分学科节点** 与 **69 条演进/交叉连线**（区分本学科核心继承 `core`、跨学科仪器赋能 `cross_tool` 与方法论迁移 `cross_method`），提供中英双语一一对应数据集。
* **🌀 真 3D 立体圆盘与空间避让**：每一时代层级构成半径递增的三维立体圆盘；通过 [`tech_layout.json`](tech_layout.json) 固化节点起伏高度与双向避让微调，确保全部节点与无关连线在三维空间及默认观察角下零穿模。
* **🧭 固定中轴线 + 分离式操控**：独创“固定中轴线（垂直 Y 轴 / 水平 X 轴）”相机系统——**垂直于轴拖动 = 360° 翻滚环视，平行于轴拖动 = 抓住画面平移浏览**，彻底告别 3D 空间迷失与视角侧翻。
* **⏱️ 渐进式解锁与时间倍率**：严谨的多重前置依赖校验，支持 `1x / 2x / 4x / 8x` 四档时间流速切换与 0.8 秒双布局平滑过渡动画。
* **🧩 2.0.0 全节点模型与状态光晕**：Tier 0–4 的 32 个节点全部绑定模型，统一尺寸与点击范围；深绿色表示可用，深卡其色表示已解锁，光晕适用于当前 Compatibility/Web 渲染。
* **🌐 桌面与 Web / 触屏全端适配**：支持单线程 WebGL2 免隔离运行，内嵌 `Noto Sans SC` 精简中文字体子集（约 249 KB），自带触屏操控按钮与防抖点击仲裁。

---

## 🎮 快速开始

### 1. 使用 Godot 编辑器运行
1. 安装 [Godot 4.7+](https://godotengine.org/download/)（推荐 `4.7.2`）。
2. 导入项目根目录下的 [`project.godot`](project.godot)。
3. 按 `F5` 运行主场景（[`scenes/main.tscn`](scenes/main.tscn)）。

### 2. Web 导出包与本地预览
项目已配置免 `COOP/COEP` 的单线程 Web 导出流水线（包名跟随工程版本，当前为 `dist/3D-TechnologyTree-2.0.0-Toy-Web.zip`）：
```powershell
# 一键导出 Web 并打包 ZIP
powershell -ExecutionPolicy Bypass -File tools/export_toy.ps1

# 启动本地 HTTP 预览服务（访问 http://127.0.0.1:8876/preview.html）
python tools/serve_toy_web.py
```
> 详细入门说明请查阅 **[快速开始指南 (docs/QUICK_START.md)](docs/QUICK_START.md)** 与 **[Web 导出说明 (docs/TOY_WEB_EXPORT.md)](docs/TOY_WEB_EXPORT.md)**。

---

## 🎯 操控方式（固定中轴系统）

核心口诀：**垂直于中轴拖动 = 绕轴翻滚旋转 🔄 ｜ 平行于中轴拖动 = 抓住画面沿轴平移 ↕️↔️**

| 操控动作 | 📊 从上到下模式（默认，垂直 Y 轴） | 📊 从左到右模式（水平 X 轴） |
| :--- | :--- | :--- |
| **左右拖动 (`←` `→`)** | **绕垂直轴 360° 翻滚旋转**（环视圆盘） | **沿水平轴平移画面**（左拖向现代，右拖向起源） |
| **上下拖动 (`↑` `↓`)** | **沿垂直轴平移画面**（上拖向下层，下拖向上层） | **绕水平轴 360° 翻滚旋转**（调整仰俯角） |
| **鼠标滚轮 / `+` `-` 按钮** | 缩放观察视距（`10 ~ 70` 单位，开局自动全景适配） | 缩放观察视距（`10 ~ 70` 单位，开局自动全景适配） |
| **左键单击 / 触屏点按节点** | 消耗科技点解锁节点（拖动松手不会误触发购买） | 消耗科技点解锁节点（拖动松手不会误触发购买） |
| **`PageDown` / 方向按钮** | 切换为“从左到右”水平时间线布局（`0.8s` 平滑动画） | 切换为“从上到下”垂直层级布局（`0.8s` 平滑动画） |
| **`PageUp` / 速度按钮** | 循环切换科技点生成速度（`1x` → `2x` → `4x` → `8x`） | 循环切换科技点生成速度（`1x` → `2x` → `4x` → `8x`） |

> 完整物理模型与图解请查阅 **[玩法与固定中轴操作手册 (docs/GAME_GUIDE.md)](docs/GAME_GUIDE.md)**。

---

## 🧬 科学史知识图谱与五大学科谱系

本项目整理了从 15 世纪至当代的 5 个世代（Tier 0–4）科学演进网络，提供结构化 JSON 与 Mermaid 拓扑文档（中英双语一一对应）：

| 领域标识 | 学科谱系 | 演进主脉络（Tier 0 → Tier 4） |
| :--- | :--- | :--- |
| 🔵 `astronomy_physics` | **天文与物理** | 天文观测与航海历法 → 几何光学 / 经典力学 → 分析力学 / 热力学 / 电磁学 → 相对论 / 量子力学 / 固体半导体 → 现代天体物理 / 纳米与量子信息 |
| 🟠 `measurement_math` | **测量、数学与信息** | 大地测量与弹道工匠术 → 解析几何与微积分 → 概率统计、群论与非欧几何 → 电子工程、控制论与信息论 → 计算机科学与人工智能 |
| 🟢 `alchemy_chemistry` | **炼金、化学与材料** | 炼金术、冶金与医药蒸馏 → 气体实验与波义耳定律 → 近代定量化学 / 有机合成与元素周期律 → 物理化学与量子化学 / 高分子与现代材料 |
| 🔴 `anatomy_biology` | **解剖、生物与医学** | 人体解剖与博物志 → 血液循环生理学 / 显微解剖与细胞发现 → 细胞学说、微生物学与进化论 → 孟德尔遗传与生物化学 / 分子生物学 → 基因组与合成生物学 / 认知神经科学 |
| 🟣 `earth_science` | **地球与环境科学** | （由大地测量 × 博物解剖交叉衍生）→ 近代地质学与古生物学 → 地球系统科学与气候动力学 |

* **中文图谱与数据**：[tech_tree.md](tech_tree.md) ｜ [tech_tree.json](tech_tree.json)
* **English Graph & Data (1-to-1)**：[tech_tree_en.md](tech_tree_en.md) ｜ [tech_tree_en.json](tech_tree_en.json)

---

## 🗂️ 项目结构与文档导航

```text
3D-ScienceTree-Toy/
├── scenes/                     # Godot 3D 场景
│   ├── main.tscn               # 主场景（相机、光照、UI 与管理器）
│   └── tech_node.tscn          # 科技节点 3D 预制体
├── scripts/                    # GDScript 核心逻辑
│   ├── tech_tree_manager.gd    # 图谱加载、立体圆盘排布、连线同步与状态管理
│   ├── tech_node.gd            # 节点材质状态机、3D 标签与解锁动画
│   ├── camera_controller.gd    # 固定中轴旋转/平移分离控制與点击仲裁
│   └── tooltip_ui.gd           # 悬浮详情提示面板
├── assets/fonts/               # Web 内嵌 Noto Sans SC 中文字体子集与 OFL 协议
├── assets/models/poly_pizza/   # 32 个节点模型、对应表和第三方署名清单
├── web/                        # Web / B站 Toy 自定义 HTML 壳模板
├── tools/                      # Web 导出、字体子集化与本地预览脚本
├── tests/                      # 9 组 Headless 自动化回归测试脚本
├── docs/                       # 📚 项目文档中心
│   ├── README.md               # 文档总目录导航
│   ├── QUICK_START.md          # 30 秒快速开始与操作速查
│   ├── GAME_GUIDE.md           # 玩法机制与固定中轴操作详解
│   ├── ARCHITECTURE.md         # 技术架构与 JSON 数据结构规范
│   ├── TOY_WEB_EXPORT.md       # Web / Toy 导出与验证说明
│   ├── reports/                # v1.3.0 测试与点位避让验证报告
│   └── archive/                # 历史版本迭代过程文档归档
├── tech_tree.json              # 中文科技树 DAG 数据源
├── tech_tree_en.json           # 英文科技树 DAG 数据源（1:1 对应）
├── tech_layout.json            # 节点固定高度与双布局点位避让微调数据
├── tech_tree.md                # 中文科技树 Mermaid 拓扑图与世代演进矩阵
├── tech_tree_en.md             # 英文科技树 Mermaid 拓扑图与世代演进矩阵
├── LICENSES.md                 # MIT + CC BY 4.0 双协议适用范围与署名规范
├── COPYRIGHT.md                # 全项目版权与第三方署名总表、许可原文
└── project.godot               # Godot 4.7 工程配置文件
```

---

节点模型下载见 [Poly Pizza 模型对应表](assets/models/poly_pizza/README.md)；每个节点各有一个 GLB，作者与原授权见[模型署名清单](assets/models/poly_pizza/CREDITS.md)。

## 🧪 自动化回归测试

项目包含 8 组无头（Headless）自动化测试，覆盖双向滚轮缩放、30° 默认视角与极点稳定性、快慢拖动一致性、点击与拖动仲裁、双方向完整 32 节点前置解锁流程以及 2,070 对节点/无关连线空间避让检查，**共计 2,122 项检查全部通过（0 失败）**：

```powershell
$godot = "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --path . --script res://tests/test_interactions.gd
& $godot --headless --path . --script res://tests/test_layout_modes.gd
& $godot --headless --path . --script res://tests/test_prerequisite_unlocks.gd
& $godot --headless --path . --script res://tests/test_prerequisite_unlocks.gd -- --vertical
& $godot --headless --path . --script res://tests/test_drag_release.gd
& $godot --headless --path . --script res://tests/test_fixed_axis.gd
& $godot --headless --path . --script res://tests/test_drag_sampling.gd
& $godot --headless --path . --script res://tests/test_point_clearance.gd
& $godot --headless --path . --script res://tests/test_tier0_models.gd
```

详细测试数据请参阅：
* [2.0.0 修正与复测报告：2788 项检查全部通过](docs/reports/V2_0_0_TEST_REPORT.md)
* [1.6.0 修复与复测报告：2662 项检查全部通过](docs/reports/V1_6_0_TEST_REPORT.md)
* [1.5.0 修复与复测报告：2300 项检查全部通过](docs/reports/V1_5_0_TEST_REPORT.md)
* [1.3.0 修复与复测报告 (docs/reports/V1_3_0_TEST_REPORT.md)](docs/reports/V1_3_0_TEST_REPORT.md)
* [1.3.0 点位避让修复报告 (docs/reports/POINT_CLEARANCE_REPORT.md)](docs/reports/POINT_CLEARANCE_REPORT.md)

---

## 📜 开源协议与署名要求 (License & Attribution)

本项目原创内容采用 **代码 MIT + 数据/文档 CC BY 4.0** 授权，欢迎按对应许可证使用、修改与分发。**全部版权、第三方作者、来源和许可原文统一收录于 [COPYRIGHT.md](COPYRIGHT.md)**；原创内容适用范围见 [LICENSES.md](LICENSES.md)。第三方内容沿用各自原授权：

1. **项目代码、场景与工程配置**：采用 **[MIT License](LICENSE)**。二次分发代码或软件时请保留原版权与许可声明。
2. **科技树图谱数据、文档与原创素材**（包括 `tech_tree.json`、`tech_tree_en.json`、`tech_tree.md`、`tech_tree_en.md` 等）：采用 **[CC BY 4.0（知识共享 署名 4.0 国际）](LICENSE-CC-BY-4.0.txt)**。
3. **第三方插件与字体**：`addons/godot_mcp/` 沿用其上游 [MIT 协议](addons/godot_mcp/LICENSE)；`assets/fonts/` 下的 Noto Sans SC 字体子集沿用 [SIL OFL 1.1](assets/fonts/OFL.txt)。
4. **第三方模型、纹理及引擎**：32 个 Poly Pizza 模型与其导出纹理分别沿用 CC0-1.0 / CC-BY-3.0；Godot 引擎及内置组件保留各自版权和许可。逐项清单及原文见 [版权总表](COPYRIGHT.md)。

### 📌 标准署名格式 (Attribution Template)

使用或改编本项目的原创科技树图谱、数据与文档时，按 CC BY 4.0 提供合理署名、来源和许可链接，并标明修改；使用 MIT 代码时，保留其版权与许可声明。下面是便于复用的署名示例，不对 MIT 增加额外的界面署名要求。第三方内容的独立署名见 [COPYRIGHT.md](COPYRIGHT.md)。

* **中文署名示例**：
  > 基于 [3D-ScienceTree-Toy](https://github.com/kanade-EdTech/3D-ScienceTree-Toy)（作者：**kanade-EdTech**），代码采用 [MIT](https://opensource.org/license/mit) 协议，科技树数据与文档采用 [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) 协议。
* **English Attribution Example**:
  > Based on [3D-ScienceTree-Toy](https://github.com/kanade-EdTech/3D-ScienceTree-Toy) by **kanade-EdTech**, licensed under [MIT](https://opensource.org/license/mit) (code) and [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) (tech tree data & documentation).
