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
| 窄带辅助 | 每街区 Assist → Master | A8派生伴音；跟随自身mute/solo/迁移，非ducking白名单；不算原始drone |
| 试听 | Preview（隔离渲染状态）→ 以上同构路由 | 与落定同一混音器；不能叠上原版造成额外失谐 |

命名是路由接口，实际 bus 数量/合并策略须满足独立静音与隔离测试；不能把同类街区合为一个不可单独诊断的输出。新功能若改变此表必须先改规格。

## 表 A2 · 时钟、增益与响度

| 参数 | 值 / 约束 |
|---|---|
| BPM / 拍号 / 小节 / 乐句 | 120 / 4/4 / 2 s / 8小节=16 s |
| 试听长度 | 3 s，至少完整一个3–16 Hz周期，且≥300 ms有效信号 |
| 副轨卡拍窗口 | 距可听乐句边界≤±80 ms；成功+5活力 |
| ducking 白名单 | Rhythm / Environment / UI；非 drone 目标−6 dB，300 ms回弹 |
| 试听被改动声部强调 | +3 dB，仅非drone（本次用户裁定U04）；标准PCM对照关闭强调 |
| 总混音 | 初始完整混音校准−16 LUFS后固定公共增益；后续报告实际响度，真峰值余量3 dB；见A9用户裁定 |
| drone 技术下限 | drone RMS ≥ 总混音 RMS 的25%；不足自动补偿 |
| 进出淡化 | equal-power，2–4拍；试听状态比较是否去强调见 U04 |
| 诊断标准路径 | beat_assist OFF；真实持续波形叠加 |
| beat_assist 开关 | 默认开；仅手动窄带模式实际激活，伴音−6 dB；其他模式无伴音；设备自动探测不做 |

响度冲突已由用户裁定，LUFS测量与固定校准见A9；RMS补偿窗与曲线仍待技术补齐，不宣称已完成。

## 表 A3 · 拍频辅助

beat_assist 对参与失谐的两条 drone 在上方一个八度复制一对伴音（C4 261.63 / C♯4 277.18），施加与原拍频同频的振幅调制。只有设备不能重现原拍频时才启用补偿；提供手动选择，不自动探测。用户已裁定：开关默认ON，仅手动窄带设备模式激活，伴音−6dB；其他模式不产生伴音，不自动探测。具体调制技术见A8。原路径测试必须关闭辅助并记录设备模式；不能用辅助掩盖原路径失败。

### [AUDIO-001] 「抖」与「刺」的可闻性

状态：实验目标；本次用户授权补齐P0技术协议，见A6；真人可闻性仍须实际记录。

意图：让玩家区分张力性质，而不是只听到一个警报音。

规则：drone 的真实叠加承载诊断。评审目标：Δf∈[3,16] Hz 为慢包络波动；Δf>16 Hz且窄音程可呈粗糙；C3–F♯3 的基频差不产生该慢拍频。复合音色是否产生其他慢包络须实测，不能作为普适声学定理。律动层负责节奏对比。

数据：spec.harmony.md 表 H2；表 A1；DOD ACOUSTIC-001/002/003原样标准。

验收：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/acoustic_contract.gd`；标准路径合成8秒，RMS包络50 Hz→FFT。P0测量定义已按用户授权补齐，见A6；自动合约仅证明技术信号，真人可闻性须另按A11记录。

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

## 表 A5 · P0持续音色与空间实现（授权技术方案）

固定drone无LFO/警报/随机失谐，叠加真实波形。三谐波加法合成后按权重和归一化；住宅为暖拨弦pad、商业为明亮键盘、工业为截断锯齿pad。相位逐样本连续累积，改音高不重置相位。装饰接口保留，P0默认不触发事件。

| 类型 | drone谐波权重（基音/二次/三次） | 16格小节律动落点（0起） |
|---|---|---|
| residential | 1.0,0.08,0.03 | 0,4,8,12 |
| commercial | 1.0,0.12,0.06 | 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 |
| industrial | 1.0,0.20,0.10 | 0,3,6,10,13 |

| 参数 | 值 / 规则 |
|---|---|
| 波表大小 | 4096，周期线性插值；第n谐波为sin(n×phase) |
| 标准drone / rhythm增益 | 0.07 / 0.025；后续响度校准使用固定公共标量，不随mute/solo重算 |
| rhythm音高 | drone上方12半音；工业单极高通300Hz |
| rhythm起振 / 尾音 / 衰减常数 | 0.005 s / 0.25 s / 0.075 s；尾音末0.005s收束 |
| 方位 | 地图x列0–4左、5–10中、11–15右，pan为−0.6/0/+0.6；equal-power，每个声部仍同时存在双声道 |
| 初始/参考音高 | MIDI48/49/50/52/54/55使用C3/C♯3/D3/E3/F♯3/G3参考频率；其他音级按A4=440Hz十二平均律 |
| 移调 | MIDI每12半音频率倍增；不改变街区类型或权重 |

这些是可复现音色起点，尚需HUMAN-IDENTITY与声学测试，不把合成存在等同于音色观感通过。

## 表 A6 · P0声学测量协议（授权技术方案U05）

固定8秒PCM，仅两个居中drone，rhythm/ornament/beat_assist/ducking/监听强调全部关闭；三对分别C3–C♯3（两住宅）、C3–F♯3（住宅+工业）、C3–G3（两住宅，协和能量参考）。相位从0开始，信号由真实_mix_frame叠加。

| 参数 | 值 / 方法 |
|---|---|
| 原PCM / 包络采样率 | 22050 / 50 Hz；测量使用AudioStreamGenerator实际接收的float32双声道PCM，PCM16 WAV仅作试听/量化对照 |
| 合成长度 / 稳态裁剪 | 8 s；抗混叠滤波两端各裁1 s，分析中间6 s；原波形8 s留证 |
| RMS功率窗 | 20 ms矩形均值；之后在功率域低通，再开平方 |
| 抗混叠滤波 | 20Hz低通，Kaiser窗beta=8.6；奇数FIR长度2×采样率+1；FFT线性卷积，中心对齐，之后插值到50Hz |
| 包络频谱 | 去均值，Hann窗，rFFT；记录完整频轴/幅度，分辨率约1/6Hz |
| 显著峰邻域 | 峰两侧距离0.5–2Hz的幅度均值；峰值幅度/邻域幅度转20log10(dB) |
| 噪底 | 幅度低于包络均值的1e-6（−120dB）的bin不判显著峰；邻域至少此噪底 |
| 小二目标 | 7.78±0.5Hz峰高≥6dB，保留DOD原阈值 |
| 无慢峰 | 3–16Hz有效bin最大显著度<3dB，保留DOD原阈值；没有高于噪底bin记无峰 |
| 协和RMS波动 | 稳态包络最大/最小转20log10，<1.5dB，保留DOD原阈值 |
| 高频能量参考 | 8s原波形200–2000Hz FFT能量，C–F♯须高于C–G住宅对；报告比值dB，不能单凭此证明听觉粗糙度 |

这个协议先公开定义再执行，不按实验结果更改阈值。与正式HUMAN-AUDIO分开；若某音色失败，保留失败证据并继续分析，不把辅助或测量混叠当通过。
抗混叠原则参考[Scipy resample_poly](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.resample_poly.html)的低通再抽样描述；FFT接口参考[NumPy rfft](https://numpy.org/doc/stable/reference/generated/numpy.fft.rfft.html)。本项目直接用NumPy实现线性FIR卷积，无需安装Scipy。

测量输入澄清：试验01用PCM16导出产生约1.8e-7包络谱量化噪声，超过原1e-6×包络均值噪底，造成两个无峰case失败。试验02改测同一实时PackedVector2Array的原始float32字节；原6/3/1.5dB及1e-6噪底不变，PCM16失败报告保存在验证记录/P0/声学/试验01_PCM16/。正式WAV听感仍需独立人测。

### [AUDIO-003] ducking 与持续 drone

状态：P0已裁定并实现，监听参数见A7；环境/UI声层及完整形态演出不属于本切片。

意图：在试听方案时保护诊断信号。

规则：白名单只含律动/环境/UI；drone不ducking，形态演出全城淡出为表现例外。drone只能由玩家推子或迁移临时静音；迁移静音1乐句后恢复。本次用户裁定试听+3dB仅强调非drone，工业300Hz高通仅律动；P0单solo、mute优先且不被补偿抵消。

数据：表 A1、A2；spec.proposal.md 表 P2；用户2026-10-08后续裁定。

验收：DOD AUDIO-003：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/mix_contract.gd -- --case ducking`；检查Drone轨与白名单前后PCM/能量。

反例：不得对父级Music bus整体压低而间接压低Drone；不得把迁移恢复交给画面Tween。

### [AUDIO-004] 小扬声器辅助与响度

状态：P0辅助、初始校准与测量技术已裁定，见A6、A8–A10；设备上的真人可闻性仍待实际记录。

意图：在窄带设备上保留可用信息。

规则：按A2/A3提供辅助与手动窄带模式；标准声学合约OFF，小扬声器测试记录ON与窄带电平。按A9仅初始完整混音校准到−16LUFS，后续固定公共增益并报告实际响度；真峰值余量3dB，drone RMS比例≥25%；明确静音例外不能误触补偿。

数据：表 A2、A3。

验收：DOD AUDIO-004：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/mix_contract.gd -- --case beat_assist`；真人狼牙音箱测试存档仍待用户组织；技术响度/保护报告见mix_contract的loudness与guard用例，不以自动报告代替人测。

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

## 表 A7 · P0试听监听处理（授权技术方案）

标准PCM合约关闭监听处理；实际监听的独立副本可开启下表处理。用户已授权补齐P0音频技术方案，本表不改A2白名单/电平/回弹时长。

| 参数 | 值 / 方法 |
|---|---|
| ducking进入 | 白名单Rhythm/Environment/UI即时到−6dB；P0后两层不存在时为零，不增造声床 |
| ducking退出 | 从当前−6dB振幅线性回到1，300ms；按样本帧，不使用画面Tween |
| 改动声部强调 | 仅所选街区的非drone输出再乘+3dB；drone不duck、不强调 |
| 试听路由 | 只播放独立预览；原城静音输出但时钟/相位继续，不叠加旧城产生额外失谐 |
| 取消与恢复 | 停止预览输出；原城仅非drone按300ms回弹；不修改城市/RNG/已渲染PCM |

AUDIO-003验收仍为`tests/mix_contract.gd -- --case ducking`，检查Drone逐样本不变、Rhythm电平、非目标声部、回弹时间、实际监听与标准PCM区分。所有DSP控制状态纳入音频模型快照。

## 表 A8 · P0窄带辅助实现（用户授权技术补齐）

| 参数 | 值 / 方法 |
|---|---|
| 开关 / 设备模式 | 开关默认ON、模式默认standard；仅narrowband且开关ON时产生伴音 |
| 合法音对 | 当前四向共享边邻居；音程类1或11，基频差3–16Hz；三全音不得伪造慢调制 |
| 伴音 | 原街区波表、连续原相位乘2，高八度；原drone增益再乘−6dB |
| 调制深度 | 0.5；包络为(1+0.5×cos(2π×原相位差))/(1+0.5)，非高八度频差 |
| 多邻居 | 每声部只复制一次；多个合法邻居时按district_id字典序选首个，避免叠加放大 |
| 控制隔离 | 每街区Assist软件轨跟随自身mute/solo/迁移；邻居玩家推子不改变本轨，原相位持续推进 |
| 拓扑变化 | 乐句落定更新邻接和音对；没有合法音对即无辅助 |
| 快照 | 开关、设备模式进入模型快照；相位沿用原PCM状态，不另启LFO时钟 |

辅助关闭或非窄带模式时，主混音与原路径逐样本一致；辅助轨不进入Drone RMS分子。自动合约验证开关、原频差AM、高八度波表、三全音排除、推子隔离与分块PCM，真人扬声器可闻性仍PENDING。

## 表 A9 · P0初始响度校准（用户裁定与授权技术补齐）

2026-10-08用户选择：初始完整混音校准到−16 LUFS后固定公共增益；改调/迁移后的实际响度允许变化，报告其值并验证真峰值余量≥3dB。静音/solo、辅助、试听不能重算公共增益。原始测量−14.85→−12.85 LUFS证明两个状态不能同时服从同一−16标量；证据保留响度探针目录。

| 参数 | 值 / 方法 |
|---|---|
| 校准输入 | 初始完整城市、drone+rhythm、8 s float32 stereo；相位0、standard、辅助OFF、无duck/强调/推子；在实际声音启动前离线计算 |
| K-weighting高架 | fc=1681.9744509555319Hz，Q=0.7071752369554193，G=3.99984385397dB，Vb指数0.499666774155；DeMan双二阶系数按实际采样率计算 |
| K-weighting高通 | fc=38.13547087613982Hz，Q=0.5003270373253953；DeMan，b=[1,−2,1] |
| 积分门控 | 400 ms块、75%重叠；绝对门−70 LUFS，相对门−10 LU；偏移−0.691，两声道能量权重均1 |
| 公共校准 | gain=10^((−16−测得LUFS)/20)，仅初始计算一次；保存实际LUFS、gain、时长与种子，快照携带gain |
| 独立验收 | FFmpeg loudnorm的input_i/input_tp（读取输入，丢弃滤镜输出）；初始目标允许测量差±0.10 LU，真峰值≤−3 dBTP |
| 对照状态 | 同一公共gain下的初始、工业全部C、九声部同音、真实小二窄带辅助；后续只验峰值并报告LUFS，不强行再次−16 |

游戏内无FFmpeg/Python依赖；GDScript双精度滤波和积分完成初始校准。开发验收用FFmpeg独立仪表，保存命令和原始JSON。算法参考作者源文件[DeMan系数](https://github.com/csteinmetz1/pyloudnorm/blob/master/pyloudnorm/iirfilter.py)、[BS.1770积分与门控](https://github.com/csteinmetz1/pyloudnorm/blob/master/pyloudnorm/meter.py)；独立仪表参考[FFmpeg loudnorm](https://ffmpeg.org/ffmpeg-filters.html#loudnorm)。本轮只完成响度校准，不将其等同于RMS自动补偿或真人可闻性。

## 表 A10 · P0 Drone RMS保护（授权技术补齐）

| 参数 | 值 / 方法 |
|---|---|
| 统计窗 | 400 ms、不重叠，按音频样本；启动第一窗为测量预热，验收稳态及完整8秒报告 |
| 参考分母 | 当前完整城市、正常rhythm及Assist；忽略玩家mute/solo/迁移临时静音和监听duck/强调，避免控制推子改变其他轨补偿；无声层不编造信号 |
| 最低比例 / 补偿目标 | 最低25%，补偿目标30%作反应余量；标准声音不触发时输出逐样本不变 |
| 求解 | D=mean(drone平方)，N=mean(其他平方)，C=mean(drone·其他)；解f使f²D/(f²D+2fC+N)=0.30²，f至少1 |
| 曲线 | 每窗结束即时提升全体drone系数；本局保持已需最大值，不因试听或玩家推子下降/泵动；公共校准gain不重算 |
| 状态 | 累计计数、D/N/C、补偿factor保存在PCM渲染状态；快照/分块/取消预览须精确保持 |
| 静音例外 | 实际输出先按玩家推子/迁移归零，再乘保护系数；所有声部mute时严格零，不用另生drone恢复分子 |
| Drone不存在 | D=0时不补偿、不合成替代警报；报告不可补偿，不能据此声称达标 |

这是有400ms反应时间的RMS保护，不是逐样本限幅器。现有生产声音完整8秒比例约0.97、不触发补偿；压力合约以显式提高律动/降低drone验证不足时触发、稳态≥25%、玩家控制不反向影响其他轨、ducking不改变参考、真实相位与块PCM一致。校准/辅助/人测保持各自独立验收。

## 表 A11 · P0正式听测工具（已批准协议的技术落实）

| 参数 | 值 / 方法 |
|---|---|
| 协议版本 / 固定种子 | human-p0-v1 / 2026100800000005；SHA-256确定题序/布局，独立于游戏真实五子流 |
| 练习 / 正式 / 每题 | 6题练习覆盖左右中×抖刺；10题正式、抖刺各5；每题8s，练习有真值反馈、正式不在结束前反馈 |
| 题型与方位计数 | 正式抖：左2/中2/右1；刺：左2/中1/右2，合计左4/中3/右3；分别固定种子哈希打乱 |
| 城市声部 | 9街区，每类3，真实drone+rhythm；其他声部MIDI48，目标相邻住宅MIDI48与工业MIDI49（抖）或54（刺）；目标两条同方位，其他街区不贴目标工业格 |
| 布局 | 16×16内无重叠；目标同列、上下相邻，列范围取A5左/中/右；其余格固定种子重排；全部显式fixture，不添加正式叛离机制 |
| 进出淡化 | 2拍equal-power，每题开头/结尾各1s，含在8秒内；仅整体听测切换，6s稳态真实波形 |
| 监听条件 | headphones_standard / speaker_standard辅助OFF、standard；speaker_narrowband为单独补充条件，ON/narrowband；设备型号与实际使用设备人工填写 |
| 校准 / 控制 | 每题初始按A9同一技术校准；固定声部，不允许答题前solo/重放；播放期间纯黑、隐藏鼠标与全部UI，结束后答方位+类型 |
| 有效记录 | 标注tester_id、stage、trial、seed/layout、设备、辅助/模式、两真值/两答案、skips、origin；真人origin=human，自动工具检查origin=automation，不能纳入真人成绩 |
| 人数 / 判定 | 每设备条件恰好3人，每人10正式题，方位和类型同时正确才计1，至少7/10；下溢、重复、缺答、混条件或自动记录不得PASS |

正式听测输入固定为九声部诊断fixture，不用两声部简化测量冒充整城定位。所有类型都有相同目标工业音色，避免仅凭替换音色答题。其余同音声部是和声背景，唯一偏离MIDI48的声部定义目标。此难度协议先锁定；结果失败要留证分析，不降低70%阈值或更换题型制造PASS。


## 表 A12 · P0声音褪色技术（沿用户授权音频技术方案）

仅实现已裁定HARM-003灰噪化状态的声音表现，不加入叛离触发、奖励事件/装饰玩法。

| 参数 | 值 / 规则 |
|---|---|
| 作用域 | P0现有Rhythm；固定诊断Drone及其窄带辅助原PCM不变，不随机抖音高/不改相位。装饰目前为零，不宣称事件shimmer/round-robin已实现 |
| 低通 | 串联2个单极低通，900Hz；每级a=1−exp(−2πfc/RATE)，每次写入float32滤波状态 |
| 轻颗粒 | 低通后sample-and-hold，目标4410Hz、每round(RATE/4410)帧采一次；无附加白噪/警报/音高调制 |
| 完全灰态干湿 | 70%滤波/降采样 +30%原律动；滤波在推子/duck/强调之前，原音高不改 |
| 进入 / 退出 | 直接使用session.lifecycle.gray；乐句边界状态改变后以音频帧线性过渡1小节，不用画面delta/Tween；中途反向从当前比例继续 |
| 状态 | 每街区两个低通值/held样本进入PCM快照；灰态目标/起始比例/变化音频帧进入模型快照；mute/solo/迁移暂静不停止滤波或振荡相位 |
| RMS参考 | A10参考使用褪色后的律动、未改的drone/辅助，仍在控制旁路之前；不让补偿抵消mute |
| 正常旁路 | 灰态无效时保留原正常PCM路径与数值；新效果不改变正式标准听测fixture真值 |
| 验收边界 | 正常PCM与改动前基线逐样本一致；灰态drone逐样本一致/相位连续、律动有实际高频减弱；可逆/快照/块大小等价/静音隔离/实际9声部最坏辅助供音无下溢；主观“美/不遮蔽诊断”仍需真人作品测试 |

AUDIO-005事件反馈时序规则仍保留；P0仅装饰接口，不新增奖励触发或把该部分标已实现。低通/sample-and-hold仅是可复现技术起点，不以自动高频下降证明主观观感。
