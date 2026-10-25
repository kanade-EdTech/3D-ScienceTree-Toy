# 双视图修复与复测报告

历史记录：本报告的 607 项通过属于此前双视图版本。当前圆盘迭代的测试发现和阻断项见 [立体圆盘测试报告](DISC_TEST_REPORT.md)。

日期：2026-10-24。环境：Windows、Godot 4.7.2、OpenGL Compatibility。

状态：上轮发现的布局切换、WASD、失焦释放、连线同步及滚轮松开处理问题均已修复。四组共 **607 项检查通过，0 项失败**，日志没有脚本错误或警告。

## 修复内容

- 统一层级索引为整数；重建布局时以运行中节点的层级统计位置，消除 JSON 浮点数字典键与导出整数字段不匹配导致的 PageDown 报错。
- 用一个可取消的布局 Tween 同时更新节点位置和全部 69 条连线。动画进行中及完成后端点一致；连续切换会取消旧动画，从当前位置过渡到最新目标。切换保留节点深度，不再随机重排 Z 坐标。
- 更新连线几何时保留材质和状态颜色，避免重建网格后丢失显示状态。
- WASD 更新观察中心后立即更新镜头；Q/E 的两种浏览方向保留。
- 右键松开、Esc、应用失焦和场景退出时释放鼠标。普通点击及滚轮松开事件不再改变缩放。
- 按布局包围盒自动调整观察中心和距离；两种视图的 32 个节点中心都位于初始视口内，实际缩放距离继续限制为 5–50。

## 最终测试结果

| 测试 | 通过数 | 结果 |
| --- | ---: | --- |
| 交互回归 `tests/test_interactions.gd` | 35 | 全部通过 |
| 双视图专项 `tests/test_layout_modes.gd` | 62 | 全部通过 |
| 横向前置解锁 `tests/test_prerequisite_unlocks.gd` | 254 | 全部通过 |
| 纵向前置解锁，同脚本加 `--vertical` | 256 | 全部通过 |
| 合计 | 607 | 0 项失败 |

- 布局测试始终使用原始 JSON 数据，已移除排查时使用的整数层级替代夹具。
- 动画中、动画后，以及 10 次快速切换后，连线端点、材质和颜色一致。
- 横向和纵向都通过真实 Godot 视口事件，经 Area3D 拾取和节点信号逐步解锁全部 32 个节点；没有直接写入解锁状态。两次固定种子运行均消耗 198 点。
- 验证了缺少前置不解锁、不扣点；前置齐全立即可用；点数差 0.1 时不能购买；点数恰好够用时正确扣至零；重复点击不重复扣费或计数。
- 用实际显卡渲染检查横向、切换中和纵向画面；两种视图均有 32/32 个节点中心位于视口，纵向第四层的 Y 坐标为 -40。

## 复现命令

在项目目录中运行：

```powershell
& "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_interactions.gd
& "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_layout_modes.gd
& "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_prerequisite_unlocks.gd
& "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_prerequisite_unlocks.gd -- --vertical
```

## 验证范围

本轮验证当前主项目的业务交互与双视图。自动鼠标测试使用 Godot 视口事件，失焦测试使用 Godot 通知；没有执行操作系统级鼠标或 Alt+Tab 自动化。没有执行导出平台、长期稳定性或独立静态样片的视觉改版。
