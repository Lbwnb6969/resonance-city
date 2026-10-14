# 执行规格索引

先读 [PROJECT](../../PROJECT.md) 的当前状态，再按任务只读对应规格与 [DOD](../02_验收/DOD.md)。数值、接口和规则以本目录为准；00及10–19阅读稿解释设计意图。历史报告、旧工作稿与被替代片段位于废弃目录，不参与现行规则判定。

| 文件 | 管辖范围 |
|---|---|
| [spec.space](spec.space.md) | 连续坐标、距离核、R/V权重、E与N₁₂、稳定规划社区、数值fixture |
| [spec.fabric](spec.fabric.md) | **落点分层 L1/L2/L3、有机连片（共享山墙/连排/围合庭院）、街墙连续度与社区成形三档** |
| [spec.terrain](spec.terrain.md) | 地形生成、可建性、规则/声学/玩法三层、地形动词、首片模板 |
| [spec.harmony](spec.harmony.md) | 音程分、活力、灰噪化迟滞、崩盘；连续权重取space |
| [spec.city](spec.city.md) | 声部身份、生长E-grow、停滞E4、环形E5-b、叛离、地标E6/E6-b、河谷E7、规划锚点E8 |
| [spec.audio](spec.audio.md) | 路由、时钟、合成/校准/声学协议、声部组、编曲槽、连续声像、候选表达、首片A26、规划映射A27 |
| [spec.proposal](spec.proposal.md) | 介入、试听、成本、基础事务、社区工具、地形动作、破坏上限；P10 留地/释放/用途转换、P11 条件机会预览、P12 规划章程/锚点与首批变化卡（其他关键锚点与体验验证待实施） |
| [spec.run](spec.run.md) | 种子、乐章、祝福/债务/记忆、时代、三路径、三模式、章程/卡牌时代持续性R11 |
| [spec.ui](spec.ui.md) | 黑屏/诊断、同步/性能、光影/通知、U16–U22极简界面与首次规划引导 |
| [spec.asset](spec.asset.md) | 许可、色板、烘焙、质量红线、地形资产、manifest |

## 使用范围

切片不等于完整规格通过，历史测量不覆盖新版本。实现状态只在 [PROJECT](../../PROJECT.md) 维护，未闭合依赖见 [待裁定与依赖](../待裁定与依赖.md)。

跨系统合同由 [19·城市生成管线](../19_城市生成管线.md) 的 WorldSnapshot/WorldDelta/CityProfile、[12·声音架构](../12_声音架构.md) 的 AudioPlan/RenderVoice 和 spec.run R2b 的保存/回放边界共同定义。其他文档只解释或引用，不复制第二套参数。

## 数据生成

在项目根目录运行：

```powershell
python tools/build_spec_data.py
python tools/build_spec_data.py --check
```

生成器读取现行 spec（含 [spec.fabric](spec.fabric.md)），输出 `数据/world_v2.json` 并记录源文件哈希。旧 `数据/spec_values.json` 是独立P0音频合约，生成器不会覆盖它。只改文档作用域时，运行参数应逐项保持，更新的只有来源哈希。
