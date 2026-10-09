# Definition of Done：规格、命令与反例

> 2026-10-09 重构版。文档修订之后已开始逐轮工程实现，实际进度以 `../../PROJECT.md` 与执行日志为准。
> 下面接口是交付要求；**存在命令不代表已实现或通过**。不能用历史 PASS 冒充重构后的验收。

---

## §0 引擎与约定

- 引擎：`D:\GODOT\Godot_v4.7.2-stable_win64.exe`
- 组件：1440×900、Compatibility、GL Compatibility
- 新版连续世界读`数据/world_v2.json`；旧合成器与旧场景暂读保留的`数据/spec_values.json`。生成器只写新版配置，不覆盖旧数据
- 每个 case 输出 `<规格ID> PASS/FAIL` + 证据路径；成功 exit 0，失败 exit 1

**重构后必须先做**：`python tools/build_spec_data.py`，因为新增了 `spec.space.md` 与 `spec.terrain.md`，表结构已变。

---

## §1 文档自检

| 断言 | 内容 |
|---|---|
| 规格文件 | `spec.*.md` 恰好 **9** 份（新增 space、terrain） |
| 规则 ID | 全局唯一 |
| 每条字段 | 含 `状态/意图/规则/数据/验收/反例` 六段 |
| 废弃隔离 | `../废弃/2026-10-09_重构前/` 不被任何现行规格引用 |

输出：`DOC_CONTRACT PASS specs=9 rules=<N>`

---

## §2 P0 空间地基（重构新增）

| ID | 脚本 / case | 判定 | 反例 |
|---|---|---|---|
| SPACE-001 | `tests/space_contract.gd -- --case coupling` | 表SP9已闭合fixture容差1e-6；含M独立生产样例；A(d) 采样点；d>4 不参与 R；`c(i,j)=c(j,i)` 含山地 σ 不对称构造；`O=0` 不进 R | 把 d>4 算进 R；工业系数在封顶前乘；用格子距离；声称 c 封顶 2.0/2.6 |
| **SPACE-001b（新）** | `-- --case neighbour_sets` | **六方密堆积下全对集合 ≥100 与 `\|N₁₂\| = 12`**；`occ` 用 `N₁₂` | 用全对集合判阶段/碴（会使密集区整体冻结） |
| SPACE-002 | `-- --case projection` | 正反变换往返 < 1e-4；已知投影值 | 投影结果四舍五入回整数格 |
| SPACE-003 | `-- --case community` | 规划图连通/分叉；41栋分裂、81栋至少3区；调音ID稳定 | 用声学删边拆社区；按音级重编号 |

---

## §3 和声（保留 + 修订）

| ID | 脚本 / case | 判定 | 反例 |
|---|---|---|---|
| HARM-001 | `tests/harmony_contract.gd -- --case resonance` | 表 H3 三 fixture **仍通过**；表SP9给定边的多配对项通过 | 每格邻接重复计为多对 |
| HARM-002 | `-- --case vitality` | fixture、上限、下限、R=60 | 按百分比复利 |
| HARM-003 | `-- --case hysteresis` | 39/40/48/49 及连续/中断 | R=48 退出；累计不连续低 R |

---

## §4 城市与生长（重构修订）

| ID | 脚本 / case | 判定 | 反例 |
|---|---|---|---|
| CITY-G1 | `tests/city_contract.gd -- --case continuous_growth` | 连续 5 乐句落点；无格子对齐、无叠置、碴剔除、阶段按原阈值 | 限制在四向/八向；落在不可建地形 |
| CITY-G2 | `-- --case ring_continuous` | 6/7/8 成员环；极角序；n 边；轮唱圈长；等功率交叉 | 要求严格 8 方向；极角不均误判 |
| CITY-G3 | `-- --case landmark_continuous` | 半径占地不重叠；距离核一致；吸收后动机含被吸收音级 | 重造权重公式；吸收丢失音高 |
| CITY-001/002/003 | 沿用旧 case | 三层与初始 MIDI；初始 R≥65；叛离 fixture | 见旧反例 |
| CITY-004/005/006 | 沿用旧 case + 连续版 | 见 P1/P2 | — |

---

## §5 声音（保留 + 规模）

| ID | 脚本 / case | 判定 | 反例 |
|---|---|---|---|
| AUDIO-G1 | `tests/audio_contract.gd -- --case voice_group` | 精确共享PCM/功率相对误差≤2e-5；保留相位；Solo按组 | 用√k声称相干原声等价；重置相位；合并装饰事件 |
| AUDIO-G2 | `-- --case arrangement` | 旋律 ≤1；留白乐句存在；槽位轮换 | 多个旋律满音量；取消留白 |
| AUDIO-G3 | `-- --case density_budget` | 27/40/55/70 阶梯真峰值与 LUFS | 响度随规模升；一次跳到 70 |
| AUDIO-G4 | `-- --case pan_continuous` | 等功率曲线；移动时连续；P0 三题不受影响 | 改正式听测协议 |
| **AUDIO-G5（新）** | `-- --case candidate_types` | 一次候选 ≥3 个不同类型；三类预览音在**音域/时值/律动**上可区分；不含推荐分 | 全部同类型候选；预览音只差音高；显示排序分数 |
| **AUDIO-009（新）** | `-- --case isolation` | 跨河无桥：两岸**不共享**旋律/节奏槽；社区尺度下非聚焦侧 −18 dB；有桥恢复正常 | 由 `c=0` 断言"听觉隔绝"；把跨河声部直接静音 |
| ACOUSTIC-001/002/003 | 沿用旧 case | 小二 7.78±0.5 Hz 峰 ≥6 dB；三全音无慢峰；协和波动 <1.5 dB | — |
| AUDIO-006/007/008 | 沿用旧 case | 阶段声音/等距声像/生产合并 | — |

---

## §6 地形（重构新增）

| ID | 脚本 / case | 判定 | 反例 |
|---|---|---|---|
| TERRAIN-001 | `tests/terrain_contract.gd -- --case generation` | 同种子同地形；可建 ≥45%；不可建 O=0；5 地形族各生成一次 | 全山/全水；破坏 R≥65；非 terrain 子流 |
| TERRAIN-002 | `-- --case acoustics` | 跨河 O=0；建桥 ≠0；对唱 +2 活力与 2 拍延迟；跨林高频下降 | 跨河默认有耦合；延迟改音高 |
| TERRAIN-003 | `-- --case verbs` | 引水/植树/挖湖/平整/建桥；预览与实际一致 | 绕过介入槽；免费无限改地形 |

---

## §7 介入与动词（重构修订）

| ID | 脚本 / case | 判定 | 反例 |
|---|---|---|---|
| PROPOSAL-001/002/003 | 沿用旧 case | 两动词、试听 PCM、主副轨 | — |
| PROPOSAL-G1 | `tests/proposal_contract.gd -- --case community_verbs` | 选中整社区；社区调音全成员 MIDI + 每栋 −5；失去轮唱有预览 | 免除 −5；破坏逐栋音高不提示 |
| PROPOSAL-G2 | `-- --case terrain_verbs` | 五个地形动词；额度耗尽拒绝 | 绕过额度 |
| PROPOSAL-G3 | `-- --case remedies` | 成路后建桥恢复耦合；移除树的成本与效果 | 免费无限桥 |

---

## §8 运行、模式与时代（重构修订）

| ID | 脚本 / case | 判定 | 反例 |
|---|---|---|---|
| RUN-001..005 | 沿用旧 case | 短局、种子、保底、债务、记忆 | — |
| RUN-G1 | `tests/run_contract.gd -- --case three_paths` | 三条路径各构造一局并断言跨越 | 要求三条全满足；三全音计入修复者 |
| RUN-G2 | `-- --case modes` | 终章后转自由共鸣状态连续；崩盘后继续；导出生成 | 切换时重置城市/种子 |
| RUN-G3 | `-- --case terrain_seed` | 同种子同地形；地形族分布；跨越新土地按地形 | 非 terrain 子流；破坏可建下限 |

---

## §9 界面（重构修订）

| ID | 脚本 / case | 判定 | 反例 |
|---|---|---|---|
| UI-G1 | `tests/ui_contract.gd -- --case minimal` | 常驻元素 **≤ 4**；悬停出卡时序；环形菜单；B 黑屏全隐藏 | 恢复常驻右栏；缺口主动弹窗 |
| UI-G2 | `-- --case feedback` | 悬停预影与预览音；点击涟漪；**L2 拍点改声 ≤ 0.5 s**；L3 结构落定；无系统提示音 | Tween 秒数控制落定；系统提示音；把一切真实变化都拖到 16 s |
| UI-G3 | `-- --case listening_scale` | 三档缩放联动；连线颜色/线型/线宽 | 连线改几何；需菜单切换 |
| UI-001..006 | 沿用旧 case | 推子/HUD/等价视觉/换色/光影/通知轨 | — |

---

## §10 资产（重构修订）

| ID | 脚本 / case | 判定 | 反例 |
|---|---|---|---|
| ASSET-G1 | `tests/asset_contract.gd -- --case terrain_assets` | 五类地形资产入库；manifest terrain 字段完整 | 降低质量红线 |
| ASSET-G2 | `-- --case manifest_v2` | 字段完整性；schema_version=2 | 扫描图片目录推断 |

---

## §11 性能

| ID | 判定 |
|---|---|
| PERF-001 | 700 栋 fixture ≥60 fps、p95 ≤16.67 ms（保留） |
| **PERF-G1（新）** | **声部组 40 → 55 → 70 阶梯**：真峰值余量 ≥3 dB、无下溢 skips；**必须小步验证** |
| **PERF-G2（新）** | **大城整城尺度**：600 栋时 ≥25% 留白、≥60 fps |

---

## §12 真人验收（用户组织）

| ID | 内容 |
|---|---|
| HUMAN-AUDIO | 黑屏、3 人、各 10 次、每人 ≥7/10 |
| HUMAN-SPEAKER | 内置扬声器，同协议 |
| HUMAN-VISUAL | 关音频、等价布局题、≥7/10 |
| HUMAN-ART | 壁纸/30 秒放置/三格测试，主观逐条登记 |
| **HUMAN-TERRAIN（新）** | **河对岸声音明显不同于同岸** |
| **HUMAN-DIFF（新）** | **两条路线的 30 秒录音盲听可辨**（回答 Q29） |

记录字段：tester_id / trial_id / seed / layout_id / device / assist_state / truth_* / answer_* / correct / notes。

---

## §13 通过与停工记录

只记 PASS / PENDING / BLOCKED。**不改评审数字迎合测试结果。**

历史 PASS（第 55–61 轮）**不自动重跑**；压力矩阵不作为新玩法开工前置。

---

## §14 最小充分验证原则

每轮只做：
1. 本次变化的 case
2. 一次实际启动 + 截图/录音
3. 音频相关加一次真峰值与 skips

**不重跑历史全套，不建庞大矩阵。**

## 当前执行方式（第62轮）

按交付切片选择最低充分验证：一次针对变更的合约探针，加一次真实GPU操作；旧矩阵仅在旧声学合同发生变化时补跑。先验证可玩的操作链，不把尚不存在的case全量补齐当作开工前置。当前命令、证据和未完成项以PROJECT及第62轮报告为准，当前针对性检查通过不等于完整P0或大城通过。
