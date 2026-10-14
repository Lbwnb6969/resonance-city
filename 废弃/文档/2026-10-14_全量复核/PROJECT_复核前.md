# 共鸣之城 · 项目状态

## 当前目标

综合后的目标是温暖、可编辑的城市创作游戏。社区房子点击后按局部墙格扩展房屋/露台；道路、特殊建筑、功能区和植被连续无格，由玩家输入意图后补细节。停手不新增建筑。声音只加强感官和正反馈，默认视野内、远处偶发、特殊时刻全城参与；区域音乐连接/风格可选。

五时代、历史街区、地标和后期强力建筑保留。强力建筑解锁建造/批量编辑机会，默认循环不使用 R/V 冻结、债务、音频修复或乐句额度。风格按 Tiny Glade 的自然接合 + 纪念碑谷的几何/色彩表达收敛。[开发入口](文档/README.md)

## 已有实现，可复用

- Godot 连续河谷、道路/桥/公共空间/留地/轻量交通、WorldSnapshot/WorldDelta 与后台结算。
- 默认 24 栋古典房屋；8 类×四向几何与两类树、文化馆、石街、夜光、连续自然地表和混型联合屋顶。
- 原生规划/作者卡、同源试听、逐栋选房/跨 CID 命名、输入隔离与小窗口避让。
- 稳定房屋/来源 ID、独立 authorship 保存、City DNA 与声音状态恢复。
- AudioPlan、区域主题/河岸 Reply、逻辑分组/RenderVoice/PCM、现有 70 RenderVoice 预算。

文档优化未改变代码行为。现有 Demo 仍有旧章程→选音流程、乐句自动成长、R/V 与音频同步限制；上述行为与新目标冲突，需在 P0 迁移。新墙格编辑、自由道路工具、功能区/植被画笔、统一撤销、视野声场和音乐网络尚未交付。技术/截图通过也未获得用户最终审美或乐趣认可。

## 入口与接口

根 `启动Demo.cmd` 开隔离河湾；主场景 `scenes/continuous_valley.tscn`。正常 F5 继续保存；Ctrl+S 保存、F9 恢复、Shift+R 先保存再开局。引擎现有路径 `D:/GODOT/Godot_v4.7.2-stable_win64_console.exe`，以本机实际工具为准。

| 工作 | 现有文件 |
|---|---|
| 输入/镜头/集成 | `scripts/ui/continuous_valley_demo.gd`、`planning_guide.gd`、`first_composition_guide.gd` |
| 玩家名字/成员 | `scripts/world/player_neighborhoods.gd`；独立 authorship 不随后台 World 交换丢失 |
| 联合房体 | `scripts/visual/joined_classical_roofs.gd`、`fabric_relations.gd` |
| 古典资产生产 | `tools/build_refined_valley_art.py`、`资源/精制河湾/manifest.json` |
| 作者/声音 | first_authored_work/continuation、authored_duet、city_voice_card、expression_audition_layer |
| 参数兼容 | `tools/build_spec_data.py`、`数据/world_v2.json`、`数据/spec_values.json` |

参数与来源哈希的维护见 [执行规格](文档/01_执行规格/README.md)。仅文档来源哈希可随此次整理刷新，运行参数保持不变。

## 下一步

1. P0：关闭测试切片中的无操作增殖和声音建造门槛，接房屋局部命中/增减/露台及可撤销事务。
2. 同一街坊做连续道路接门与混型/高差屋顶；比较 2.5D 和动态 3D/混合路线的成本与效果。
3. P1：连续区/植被/特殊建筑，视野声场与可选音乐网络；旧命名/作品数据继续可读。
4. P2：一座真实强力建筑、时代/历史保留，再扩到大城和作品导出。

## 验证与资料

旧 Round215 联合屋顶、216 玩家命名、217 作者回访、218 自然地表等结果保留在原 `验证记录/`。完整状态、失败原件与详细参数见 [迁移前 PROJECT](废弃/文档/2026-10-14_综合优化前/PROJECT.md)，不把旧 PASS 记为新墙格/新工具通过。

本轮文档完成标准：归档与独立备份逐文件哈希匹配、当前链接有效、合并稿同步、兼容生成数据除 sources 外不变。检查结果记录在 [整合记录](废弃/文档/2026-10-14_综合优化前/验证结果.json)。

## 未解决问题

局部格尺度/规则、最终渲染表现、音乐风格素材与并发预算需要原型和实测；用户审美/听感/乐趣尚未真人验证。按 [待实验与依赖](文档/待裁定与依赖.md) 做最小样例即可，不用再次申请架构或工具许可。
