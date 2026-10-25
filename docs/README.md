# 项目文档导航 (Documentation Index)

欢迎查阅 **3D-ScienceTree-Toy**（人类近代科学交叉科技树 3D 微型严肃游戏）项目文档。本项目文档已按**核心图谱、使用与开发指南、测试报告、历史归档**进行结构化整理。

---

## 1. 根目录核心文件 (Root Documents)

| 文件 | 语言 | 说明 |
| :--- | :---: | :--- |
| [README.md](../README.md) | 中 / EN | 项目总览、快速上手、双视角操作、项目结构与开源署名说明 |
| [LICENSES.md](../LICENSES.md) | 中文 | **MIT + CC BY 4.0** 双协议适用范围、第三方组件说明与标准署名模板 |
| [COPYRIGHT.md](../COPYRIGHT.md) | 中文 / 原文 | **全项目版权与署名总表**：32 个模型和纹理、字体、插件、引擎依赖及完整许可原文 |
| [tech_tree.md](../tech_tree.md) | 中文 | 人类近代科学交叉科技树（DAG）Mermaid 全景拓扑图与世代演进矩阵 |
| [tech_tree_en.md](../tech_tree_en.md) | English | Cross-Disciplinary Technology Tree of Modern Science (DAG) — 1-to-1 English Edition |
| [tech_tree.json](../tech_tree.json) | 中文 | 32 节点 + 69 条跨学科连线的结构化 DAG 数据源（运行时主数据） |
| [tech_tree_en.json](../tech_tree_en.json) | English | 1-to-1 English structured DAG dataset (32 nodes + 69 links) |
| [tech_layout.json](../tech_layout.json) | JSON | 固定节点立体高度与双布局（纵向/横向）点位避让微调配置 |

---

## 2. 使用与开发指南 (`docs/`)

| 文档 | 内容概述 |
| :--- | :--- |
| **[快速开始指南 (QUICK_START.md)](QUICK_START.md)** | 30 秒上手指南：Godot 运行、Web 本地预览、操作速查卡与常见问题 |
| **[玩法与固定中轴操作手册 (GAME_GUIDE.md)](GAME_GUIDE.md)** | 科技点与前置解锁机制、固定中轴线（从上到下 / 从左到右）分离式操控详解 |
| **[技术架构与数据规范 (ARCHITECTURE.md)](ARCHITECTURE.md)** | Godot 4.7 场景与脚本架构、立体圆盘点位算法、JSON 数据字段规范与回归测试矩阵 |
| **[Web / B站 Toy 导出指南 (TOY_WEB_EXPORT.md)](TOY_WEB_EXPORT.md)** | 单线程 WebGL2 导出、中文字体子集化（Noto Sans SC）、触屏适配与打包流水线 |

---

## 3. 质量验证与测试报告 (`docs/reports/`)

当前版本 **v1.3.0** 共通过 **8 组自动化测试（2,122 项断言检查，0 项失败）** 及真实 GPU / 浏览器渲染验证：

* **[1.3.0 修复与复测报告 (V1_3_0_TEST_REPORT.md)](reports/V1_3_0_TEST_REPORT.md)**：涵盖通用交互、双方向布局切换、完整 32 节点前置解锁、单击与拖动仲裁、30° 默认视角与极点稳定性、快慢拖动一致性（共 7 组 689 项检查）。
* **[1.3.0 点位避让修复报告 (POINT_CLEARANCE_REPORT.md)](reports/POINT_CLEARANCE_REPORT.md)**：涵盖全部 32 个节点与 69 条连线的空间距离与屏幕投影留白检测、固定高度与点位避让微调（新增 1,433 项检查，合计 2,122 项通过）。

---

## 4. 历史迭代归档 (`docs/archive/`)

项目从早期 v1.0 线性布局、双视图切换、立体圆盘演进至 v1.3.0 固定中轴系统的过程文档与阶段测试记录保存在 [`docs/archive/`](archive/) 目录中，供回溯参考。
