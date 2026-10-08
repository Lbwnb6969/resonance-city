# 音频执行规格

> 2026-10-08 · 音频时钟为所有同步变化的唯一时间源。未来自动化合约只测实现，不替代真人可闻性测试。

## 表 A1 · 总线与权限

| 输出层 | 路由 | 诊断 / ducking / mute |
|---|---|---|
| 每街区 drone | `District_<id>_Drone` → Drone → Master | 和声诊断；不在 ducking 白名单；持续；玩家推子及用户批准的迁移例外 |
| 每街区律动 | `District_<id>_Rhythm` → Rhythm → Master | 街区节奏身份；可 ducking |
| 每街区装饰 | `District_<id>_Ornament` → Ornament → Master | P0 接口，不扩展彩蛋内容；非白名单时不得自行 ducking |
| 环境 | Environment → Master | 可 ducking；P0 无环境声床依赖 |
| UI | UI → Master | 可 ducking |
| 介入反馈 | Intervention → Master | 反馈独立，不能生成伪造的诊断拍频 |
| 试听 | Preview（隔离渲染状态）→ 以上同构路由 | 与落定同一混音器；不能叠上原版造成额外失谐 |

命名是路由接口，实际 bus 数量/合并策略须满足独立静音与隔离测试；不能把同类街区合为一个不可单独诊断的输出。新功能若改变此表必须先改规格。

## 表 A2 · 时钟、增益与响度

| 参数 | 值 / 约束 |
|---|---|
| BPM / 拍号 / 小节 / 乐句 | 120 / 4/4 / 2 s / 8小节=16 s |
| 试听长度 | 3 s，至少完整一个3–16 Hz周期，且≥300 ms有效信号 |
| 副轨卡拍窗口 | 距可听乐句边界≤±80 ms；成功+5活力 |
| ducking 白名单 | Rhythm / Environment / UI；非 drone 目标−6 dB，300 ms回弹 |
| 试听被改动声部强调 | +3 dB；与“drone保持不变”的适用范围冲突，U04待定 |
| 总混音 | −16 LUFS，真峰值余量3 dB |
| drone 技术下限 | drone RMS ≥ 总混音 RMS 的25%；不足自动补偿 |
| 进出淡化 | equal-power，2–4拍；试听状态比较是否去强调见 U04 |
| 诊断标准路径 | beat_assist OFF；真实持续波形叠加 |
| beat_assist 开关 | 默认开；原始伴音−12 dB；手动窄带模式−6 dB；设备自动探测不做 |

RMS统计窗、LUFS测量时段、补偿曲线、静音例外期间分母处理未给出（U04）。禁止执行 AI 自定默认值。

## 表 A3 · 拍频辅助

beat_assist 对参与失谐的两条 drone 在上方一个八度复制一对伴音（C4 261.63 / C♯4 277.18），施加与原拍频同频的振幅调制。只有设备不能重现原拍频时才启用补偿；提供手动选择，不自动探测。开关默认开与“仅窄带启用”的激活状态、调制深度未裁定（U04）。原路径测试必须关闭辅助并记录设备模式；不能用辅助掩盖原路径失败。

### [AUDIO-001] 「抖」与「刺」的可闻性

状态：实验目标；测量细节待裁定U04、U05。

意图：让玩家区分张力性质，而不是只听到一个警报音。

规则：drone 的真实叠加承载诊断。评审目标：Δf∈[3,16] Hz 为慢包络波动；Δf>16 Hz且窄音程可呈粗糙；C3–F♯3 的基频差不产生该慢拍频。复合音色是否产生其他慢包络须实测，不能作为普适声学定理。律动层负责节奏对比。

数据：spec.harmony.md 表 H2；表 A1；DOD ACOUSTIC-001/002/003原样标准。

验收：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/acoustic_contract.gd`；标准路径合成8秒，RMS包络50 Hz→FFT。测量定义U05未定，不能宣布全项自动验收可执行。

反例：禁止独立警报音、滤波LFO或 beat_assist 伪造原路径拍频；关辅助后追踪 `_mix_frame()`。

### [AUDIO-002] 可听时钟与未来量化

状态：已裁定。

意图：防止画面帧率、输出延迟与预渲染使介入落点漂移。

规则：持续PCM样本帧计数；输入即时确认，状态事件量化到尚未渲染的下一个合法乐句边界。可听位置须补偿输出/缓冲延迟；禁止回写已渲染PCM。小节2s、乐句16s分别计数，提案仅乐句边界生效。和声保护根据街区类型、已批准提案及测试状态检查允许音高；必须允许工业初始F♯与叛离fixture，不能机械沿用遗产和弦池将其滤掉。

数据：表 A2；遗产 scripts/sound_engine.gd、tests/audio_contract.gd。

验收：DOD AUDIO-002：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/audio_contract.gd`；小节边界、乐句边界、未来量化、和声保护、PCM逐采样一致。

反例：遗产 STEP_FRAMES=5513是八分音符，不是一拍；不得直接沿用其四舍五入步长造成长期漂移，不得按画面delta累计声音。

## 表 A4 · P0时钟实现参数（本次工程轮）

用户已授权补齐P0音频技术方案。以下是实现参数，不修改A2的音乐时间单位。

| 参数 | 值 / 规则 |
|---|---|
| PCM采样率 | 22050 Hz；显式CUSTOM模式，所有时间换算使用实际生成率 |
| 生成缓冲长度 | 0.12 s；占用帧数使用启动后实际get_frames_available容量，不假定等于秒数乘采样率 |
| 边界帧 | round(单位序号 × 每单位拍数 × 60 × 采样率 / BPM)，不得累加取整后的单拍长度 |
| 可听帧 | rendered_frames − queued_frames + (time_since_last_mix − output_latency) × 采样率；限制在0…rendered_frames并保持单调 |
| 未渲染区 | rendered_frames是首个可写样本；它恰在乐句边界可落定，否则排到下个边界 |
| 下溢 | 记录AudioStreamGeneratorPlayback.get_skips；发生下溢的运行不能作为同步或真人正式验收证据 |

采样率选择依据Godot官方AudioStreamGenerator文档对GDScript的建议；只借用遗产PCM调度范式，不移植其乐理池/步长/混音参数。
来源：[AudioStreamGenerator](https://docs.godotengine.org/en/stable/classes/class_audiostreamgenerator.html)、[Playback容量/下溢](https://docs.godotengine.org/en/stable/classes/class_audiostreamgeneratorplayback.html)、[硬件混音时钟](https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html)。

### [AUDIO-003] ducking 与持续 drone

状态：部分待裁定U04。

意图：在试听方案时保护诊断信号。

规则：白名单只含律动/环境/UI；drone不 ducking，形态演出全城淡出为表现例外。drone只能由玩家推子或迁移临时静音；迁移静音1乐句后恢复。试听+3dB范围与持续层“不变”冲突待裁定。

数据：表 A1、A2；spec.proposal.md 表 P2；用户2026-10-08后续裁定。

验收：DOD AUDIO-003：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/mix_contract.gd -- --case ducking`；检查Drone轨与白名单前后PCM/能量。

反例：不得对父级Music bus整体压低而间接压低Drone；不得把迁移恢复交给画面Tween。

### [AUDIO-004] 小扬声器辅助与响度

状态：部分待裁定U04、U05。

意图：在窄带设备上保留可用信息。

规则：按A2/A3提供辅助与手动窄带模式；标准声学合约OFF，小扬声器测试记录ON与窄带电平。整体−16LUFS、真峰值余量3dB，drone RMS比例≥25%；明确静音例外不能误触补偿。

数据：表 A2、A3。

验收：DOD AUDIO-004：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/mix_contract.gd -- --case beat_assist`；真人狼牙音箱测试存档；响度报告待测量细节裁定。

反例：不得把上方八度的15.56Hz自然拍频误认作原7.78Hz；不得开启自动补偿使玩家 mute 失效。

### [AUDIO-005] 声音褪色与反馈边界

状态：已裁定。

意图：使衰败仍可聆听并保留辨识线索。

规则：灰噪化表现沿用保护条款，不用新增失谐警报；round-robin与±3%音高抖动只适用于事件/装饰，不得用于固定音高drone。事件尾音≥200ms；奖励基音+纯五+高八度shimmer，+10ms延迟，5ms内起振。

数据：本节保留条款；spec.harmony.md HARM-003。

验收：DOD AUDIO-005：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/mix_contract.gd -- --case signal_protection`；确认drone pitch不抖、灰噪化不遮蔽诊断；作品测试。

反例：不得把反馈round-robin规则施加于承载固定诊断频率的drone。

## 原文保护条款

- **灰噪化也要"美"**：衰败不是噪音污染，而是声音"褪色"——低通 + 降采样轻颗粒，像旧磁带。让玩家心疼而非烦躁。
