# 声音反馈执行规格

输入：已提交来源事件、可见范围/镜头关注、音乐区域/连接、风格和声音控制。输出：AudioPlan、受预算管理的 RenderVoice、PCM 和真实可听活动标记。

默认视野内优先，远处偶发，特殊时刻全城区域参与；分组/轮换限制密度和响度。视野选择带淡化与迟滞，显式静音优先于自动调度。

连接影响配器与过渡，不改变空间合法性。试听持隔离状态，来源 ID 可追溯；未知/消失来源结束相关声音，不认领另一栋。逻辑声音身份不因几何连排消失。

维持音频帧和固定校准增益、无递归应答及签名一致才共享波形的合同。生产事件与实际可听帧对齐；不要求建造等乐句。旧 70 预算复现旧代码，后续预算按实测更新。

验证关闭音频仍可建设、视野进退、远端/全城来源、区域连断、试听隔离、取消/撤销接缝、削波/欠载与声音控制范围。

完整旧参数、公式和合约 ID 见 [迁移前 spec.audio](../../废弃/文档/2026-10-14_综合优化前/文档/01_执行规格/spec.audio.md)。

## 现有实现兼容参数

以下表仅用于复现当前代码/生成配置。保留数值不恢复旧玩法语义；新建造不受这些音乐/额度/自动生长参数限制。

## 表 A2 · 时钟、增益与响度

| 参数 | 值 / 约束 |
|---|---|
| BPM / 拍号 / 小节 / 乐句 | 120 / 4/4 / 2 s / 8小节=16 s |
| ducking 白名单 | Rhythm / Environment / UI；非 drone 目标−6 dB，300 ms回弹 |
| 总混音 | 初始完整混音校准−16 LUFS后固定公共增益；后续报告实际响度，真峰值余量3 dB；见A9用户裁定 |
| 进出淡化 | equal-power，2–4拍；试听状态比较是否去强调见 U04 |

## 表 A4 · P0时钟实现参数（本次工程轮）

| 参数 | 值 / 规则 |
|---|---|
| PCM采样率 | 22050 Hz；显式CUSTOM模式，所有时间换算使用实际生成率 |
| 生成缓冲长度 | 0.12 s；占用帧数使用启动后实际get_frames_available容量，不假定等于秒数乘采样率 |
| 边界帧 | round(单位序号 × 每单位拍数 × 60 × 采样率 / BPM)，不得累加取整后的单拍长度 |
| 可听帧 | rendered_frames − queued_frames + (time_since_last_mix − output_latency) × 采样率；限制在0…rendered_frames并保持单调 |
| 未渲染区 | rendered_frames是首个可写样本；它恰在乐句边界可落定，否则排到下个边界 |
| 下溢 | 记录AudioStreamGeneratorPlayback.get_skips；发生下溢的运行不能作为同步或真人正式验收证据 |

## 表 A26 · 河谷社区合奏与两层落定参数

| 参数 | 值 |
|---|---|
| control_fade_beats | 2 |
| pitch_glide_seconds | 0.04 |
| pad_gain | 0.075 |
| rhythm_gain | 0.032 |
| theme_gain | 0.040 |
| response_gain | 0.022 |
| bed_gain | 0.006 |
| background_gain | 0.125892541 |
| pad_group_limit | 30 |
| pad_reference_communities | 3 |
| rhythm_slot_limit | 2 |
| theme_slot_limit | 1 |
| response_slot_limit | 1 |
| theme_rotate_phrases | 4 |
| theme_rest_phrases | 7 |
| render_voice_limit | 70 |
