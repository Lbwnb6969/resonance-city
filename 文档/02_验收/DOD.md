# Definition of Done：规格、命令与反例

> 2026-10-08。文档修订之后已开始逐轮工程实现，实际进度以PROJECT.md、执行日志-P0.md与验证记录为准。下面接口是交付要求；存在命令不代表已实现或通过。不能用遗产项目的PASS冒充本项目验收。

## 1. 当前可运行的文档自检

在项目根目录PowerShell运行：

```powershell
@'
from pathlib import Path
import re
root = Path('.')
specs = sorted((root / '文档/01_执行规格').glob('spec.*.md'))
assert len(specs) == 7, 'Expected seven specification files'
seen = set()
for path in specs:
    content = path.read_text(encoding='utf-8-sig')
    sections = re.split(r'(?m)^### \[([A-Z]+-\d{3})\] ', content)
    assert len(sections) > 1, f'No rule in {path}'
    for i in range(1, len(sections), 2):
        rid, body = sections[i], sections[i+1]
        assert rid not in seen, f'Duplicate ID: {rid}'
        seen.add(rid)
        for field in ['状态：','意图：','规则：','数据：','验收：','反例：']:
            assert field in body, f'{rid} missing {field}'
assert not (root / '文档/游戏策划案v3-共鸣之城.md').exists()
assert (root / 'PROJECT.md').is_file()
assert (root / '资产/使用授权说明-2.5D素材.md').is_file()
print(f'DOC_CONTRACT PASS specs={len(specs)} rules={len(seen)}')
'@ | python -
git diff --check
```

这只证明七份规格结构/唯一ID与入口文件完整；不证明音频、玩法、许可入库或性能完成。裁定表逐字比对、原件SHA-256与受保护条款比对结果另存`../修订记录-2026-10-08.md`。

## 2. 游戏验收统一接口

执行工作目录为项目根；引擎固定路径`D:\GODOT\Godot_v4.7.2-stable_win64.exe`，不是PATH中的godot。每个脚本需自行读取规格生成的配置、固定fixture和`--case`，输出`<规格ID> PASS/FAIL`与证据路径，成功exit0，失败exit1。没有文件/未裁定/没听测不能记为通过。P0实现每条机制时同时交付对应最小有意义合约；不提前堆叠冗余测试。

`验证记录/`是未来证据目录。本轮只产出文档自检记录。测量阈值未给全的项目（例如“≈0”）先按Uxx提问，不自行填容差。

| 规格 | 计划脚本 / case | 判定 | 反例 |
|---|---|---|---|
| CITY-001 | `tests/city_contract.gd` / `layers` | 初始MIDI48/52/54；三层接口；drone持续 | 把断奏当持续层 |
| CITY-002 | `tests/city_contract.gd` / `initial_r` | R≥65、最多8次局部尝试；失败记录换种子 | 未算R即开局/未经裁定更改daily种子 |
| CITY-003 | `tests/city_contract.gd` / `rebellion_fixture` | +1半音、律动±5–12%、归拍；P0仅测试fixture | 在P0自行加入叛离触发阈值 |
| HARM-001 | `tests/harmony_contract.gd` / `resonance` | H3数值、共享格权重、工业系数；R纯函数 | 重复边或额外扣R |
| HARM-002 | `tests/harmony_contract.gd` / `vitality` | H3数值；±12与0–100；R=60 | 百分比复利 |
| HARM-003 | `tests/harmony_contract.gd` / `hysteresis` | 39/40/48/49、低R连续与间断序列 | 在阈值等号触发切换 |
| AUDIO-001 | `tests/acoustic_contract.gd` / `全部` | ACOUSTIC三条与无辅助源代码路径 | 用辅助/音效蒙混原路径 |
| AUDIO-002 | `tests/audio_contract.gd` / `全部` | 边界/未来量化/和声保护/逐样本PCM | 按画面delta或排进已渲染区 |
| AUDIO-003 | `tests/mix_contract.gd` / `ducking` | 逐轨验证白名单、drone不受父总线压低 | 只测Master响度 |
| AUDIO-004 | `tests/mix_contract.gd` / `beat_assist` | OFF/ON/手动窄带；LUFS/峰值/RMS报告 | 默认路径辅助未关却说真实拍频通过 |
| AUDIO-005 | `tests/mix_contract.gd` / `signal_protection` | 固定音高drone与衰败听感记录 | drone应用±3%随机音高 |
| ASSET-001 | `tests/asset_contract.gd` / `license` | 来源/许可文件/白名单与构建依赖 | 未登记来源/授权或运行时直接依赖原件 |
| ASSET-002 | `tests/asset_contract.gd` / `baked_sprite` | 1整图/栋、独立预览与主图、窗光统一 | 把512px预览当主图 |
| ASSET-003 | `tests/asset_contract.gd` / `import_scope` | 被忽略原件无导入记录、资源/成品可load | 运行时依赖被.gdignore隐藏 |
| ASSET-004 | `tests/asset_contract.gd` / `quality` | ≥2048px、边缘、抽检10%与三格人工记录 | 把尺寸通过当观感通过 |
| PROPOSAL-001 | `tests/proposal_contract.gd` / `verbs` | retune成本、工业可改、迁移静音1乐句恢复 | 旧工业锁音限制或迁移永不恢复 |
| PROPOSAL-002 | `tests/proposal_contract.gd` / `preview_pcm` | 相同相位增益下预览=落定逐样本PCM；取消无副作用 | 只验证两版不同 |
| PROPOSAL-003 | `tests/proposal_contract.gd` / `landing` | 1/0.7/0.4及±80ms边界；主副轨独立 | 所有量化提交自动被算卡拍 |
| RUN-001 | `tests/run_contract.gd` / `cadence` | 3次指定音程解决与末乐句R≥70 | 把任意失谐改善计入限定终止式 |
| RUN-002 | `tests/run_contract.gd` / `rng_replay` | 五子流隔离、DNA重放、UTC daily一致 | 预览消耗真实子流 |
| RUN-003 | `tests/run_contract.gd` / `boon_pity` | 固定输入验证权重/软保底/硬保底/重置 | 概率蒙特卡洛代替硬保底断言 |
| RUN-004 | `tests/run_contract.gd` / `debt` | E+1/上限6、N上限4、一次结算 | 自行填精度或加成对象 |
| RUN-005 | `tests/run_contract.gd` / `memory` | 来信引用真实事件、失败保底记录 | 虚构地点或忽略池耗尽 |
| UI-001 | `tests/mix_contract.gd` / `fader` | mute目标能量与未选轨PCM不变；solo隔离 | 只mute全部同类bus |
| UI-002 | `tests/ui_contract.gd` / `proposal_cost` | 显示的收益/成本/音程=同一预览结果 | 只显示收益或写死数字 |
| UI-003 | `tests/ui_contract.gd` / `visual_parity` | 方位/类型/E/提案信息同源；视觉真人验收 | 只有画面变灰 |
| UI-004 | `tests/visual_clock_contract.gd` / `全部` | 不同画面帧率下结束帧等于1拍；整图预算 | Tween秒数或遗产半拍单位 |

### 各case的可复制命令

```powershell
# CITY-001 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/city_contract.gd -- --case layers
# CITY-002 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/city_contract.gd -- --case initial_r
# CITY-003 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/city_contract.gd -- --case rebellion_fixture
# HARM-001 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/harmony_contract.gd -- --case resonance
# HARM-002 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/harmony_contract.gd -- --case vitality
# HARM-003 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/harmony_contract.gd -- --case hysteresis
# AUDIO-001 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/acoustic_contract.gd
# AUDIO-002 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/audio_contract.gd
# AUDIO-003 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/mix_contract.gd -- --case ducking
# AUDIO-004 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/mix_contract.gd -- --case beat_assist
# AUDIO-005 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/mix_contract.gd -- --case signal_protection
# ASSET-001 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/asset_contract.gd -- --case license
# ASSET-002 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/asset_contract.gd -- --case baked_sprite
# ASSET-003 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/asset_contract.gd -- --case import_scope
# ASSET-004 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/asset_contract.gd -- --case quality
# PROPOSAL-001 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/proposal_contract.gd -- --case verbs
# PROPOSAL-002 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/proposal_contract.gd -- --case preview_pcm
# PROPOSAL-003 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/proposal_contract.gd -- --case landing
# RUN-001 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/run_contract.gd -- --case cadence
# RUN-002 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/run_contract.gd -- --case rng_replay
# RUN-003 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/run_contract.gd -- --case boon_pity
# RUN-004 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/run_contract.gd -- --case debt
# RUN-005 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/run_contract.gd -- --case memory
# UI-001 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/mix_contract.gd -- --case fader
# UI-002 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/ui_contract.gd -- --case proposal_cost
# UI-003 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/ui_contract.gd -- --case visual_parity
# UI-004 — 当前待实现
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/visual_clock_contract.gd
```

## 3. 声学判定（原样保留评审阈值）

以下不是已经验证的声学定理。三条先作为实验目标保留；RMS窗口、降采样抗混叠、频谱邻域与参考基线缺失，详见U05。禁止改阈值以制造通过，也禁止在定义不全时造一个实现再声称符合。

```
[ACOUSTIC-001]「抖」可被测量
输入：C3 drone + C♯3 drone，两条同时持续，无其他声部，混音 8 秒
方法：对输出取 50 Hz 降采样 RMS 包络 → 对包络做 FFT
判定：7.78 Hz ± 0.5 Hz 处存在显著峰（高于邻域均值 ≥ 6 dB）→ PASS
反例：不得用独立音效伪造此效果。
      查代码路径：该包络脉动只能来自 _mix_frame() 的真实波形叠加。

[ACOUSTIC-002] 「刺」不产生慢拍频
输入：C3 drone + F♯3 drone，混音 8 秒
方法：同上
判定：3–16 Hz 区间内**无**显著峰（< 3 dB）→ PASS
      且需在 200 Hz–2 kHz 检出能量上升（谐波失配的粗糙特征）

[ACOUSTIC-003] 协和不出脉动
输入：C3 drone + G3 drone（纯五）
判定：3–16 Hz 区间无显著峰，且包络 RMS 起伏 < 1.5 dB → PASS
```

ACOUSTIC-001/002/003对应AUDIO-001。辅助OFF、无律动/装饰、同相位定义和实际音色/滤波需记录。50Hz降采样前若不定义抗混叠，C3–F♯3的54.184Hz分量可能折入4.184Hz，造成假慢拍频；不能以此替代真正听感。200Hz–2kHz能量上升不单独证明粗糙度。复合波形中近邻谐波也会产生慢差频，须先解决U04/U05。

## 4. 真人验收（独立于自动合约）

| ID | 协议 | PASS |
|---|---|---|
| HUMAN-AUDIO | 黑屏，画面全黑无UI；3名测试者，各10次随机布局；同时回答失谐方位与「抖/刺」类型 | 每名测试者≥7/10（≥70%），不拿合计分替代 |
| HUMAN-SPEAKER | 笔记本内置扬声器黑屏；记录beat_assist与手动窄带状态，沿用上方人数/题数/答题协议 | 每人≥7/10；不能用耳机结果替代 |
| HUMAN-VISUAL | 音频关闭，仅视觉优先模式，等价布局题；回答方位与类型 | 每人≥7/10；另以自动映射验证E与提案信息完整 |
| HUMAN-IDENTITY | 单独播放街区声部，听音指图，记录街区类型与实际音色 | 原文未给正确率阈值，待U12；不可写为自动PASS |
| HUMAN-ART | 壁纸/30秒放置/作品/过渡猎手/三格测试；留原方法并存观察记录 | 主观结果逐条登记，不假装“好看/好听”有自动证明 |

用户已批准6题练习/固定种子随机10题/抖刺各5/左右中均衡/每题8秒/标准辅助OFF，耳机与内置扬声器分别记录；技术落实锁定spec.audio A11。P0用显式fixture注入小二度，不加入完整叛离机制。正式记录必须无下溢、human来源、条件一致；辅助ON窄带作为单独补充条件，不混入标准成绩。

记录文件计划：`验证记录/P0/闭眼定位.csv`、`狼牙音箱.csv`、`验证记录/P1/视觉优先.csv`。字段：tester_id、trial_id、seed、layout_id、device、assist_state、truth_direction、truth_type、answer_direction、answer_type、correct、notes。correct仅在方位和类型同时正确时为真。

### 已填记录的可运行统计命令

记录必须各人恰好10题、恰好3人；文件未产出时此命令会失败，应记PENDING。

```powershell
@'
import csv
from collections import defaultdict
from pathlib import Path
p = Path('验证记录/P0/闭眼定位.csv')
assert p.is_file(), 'PENDING: no human test record'
groups = defaultdict(list)
for r in csv.DictReader(p.open(encoding='utf-8-sig', newline='')):
    groups[r['tester_id']].append(r)
assert len(groups) == 3
for tester, rows in groups.items():
    assert len(rows) == 10 and len({r['trial_id'] for r in rows}) == 10
    score = sum(r['answer_direction'] == r['truth_direction'] and r['answer_type'] == r['truth_type'] for r in rows)
    print(tester, score, '/10')
    assert score >= 7
print('HUMAN-AUDIO PASS')
'@ | python -
```

## 5. 性能与资产检验

PERF-001计划入口：

```powershell
& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --path . -- --performance-fixture=700
```

入口待实现，必须以有画面的实际Compatibility渲染测试；headless不能证明60fps。记录700栋整图、全屏窗光、粒子系统≤12、Y排序树深≤6；硬件/视口/缩放/统计时段固定后才裁定PASS（U12）。压力fixture独立于16×16声学地图。

资产脚本还需提供`--case packages`（四包版本/下载日期/许可证存在）和`--case palette`（基础1张24槽色板）。未下载不得填写已完成；使用授权说明完成不代表构建依赖审计已通过。

## 6. 通过与停工记录

每次执行：规格ID、实际命令、退出码、stdout摘要、证据路径、未确定项。测试文件尚不存在记PENDING；规格待裁定记BLOCKED并指Uxx；只有真实执行满足判定才记PASS。不改变评审数字来迎合测试结果，也不把有冲突的规则自动忽略。

## 7. 后续用户裁定与已实现验收补充

AUDIO-004初始响度使用spec.audio A9固定gain口径：`& D:/GODOT/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/loudness_contract.gd`。独立FFmpeg输入测量初始−16±0.10LUFS、所有已定义对照真峰值≤−3dBTP；后续状态报告响度，不再次归一化。该命令当前已实现，证据见PROJECT；不足时的RMS补偿与HUMAN-SPEAKER单独验收，技术PASS不能替代真人。

AUDIO-004不足时补偿入口：`& D:/GODOT/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/rms_guard_contract.gd`，按A10稳态/完整8秒RMS≥25%，不复活mute/不改变peer PCM，跨窗块与快照一致。实际最坏辅助供音另用`tests/live_audio_contract.gd -- --case assist_stress`，显式WASAPI，0skips才可用于正式听测供音门槛。

正式真人听测已可从F5按钮进入；操作与命令见`../P0真人听测操作.md`，协议A11。技术工具合约`tests/listening_contract.gd`只验fixture/8秒PCM/黑屏/记录隔离。真人统计使用`python tools/grade_listening.py <同条件3份真人CSV> --condition headphones_standard|speaker_standard|speaker_narrowband`；自动来源、下溢、缺题、重复/混条件会拒绝，不以工具PASS代替HUMAN-AUDIO/SPEAKER。


PERF-001入口已实现，P0固定条件以spec.ui U6为准：主场景 `-- --performance-fixture=700`，Compatibility实际1440×900、vsync禁用、35×20/700个单整图、9纹理种类、一个全屏additive窗光；预热10s后测60s、平均≥60fps并p95≤16.67ms。原每帧CSV/截图/硬件/驱动/JSON按日期写验证记录/P0/性能，最新汇总PERF-001_700.json。提前Esc/无真实显示/少实例/阈值不满足不能PASS。固定静态压力成绩不证明未来动态生长或完整声画同时运行。


UI-004 visual_clock_contract.gd入口已实现：headless验证可听音频帧/一拍11025帧/不同画面帧率/单Sprite结构；同脚本以有画面Compatibility运行另验真实shader alpha，并存闭合/半拍/一拍截图。它是显示原语的证据，不证明CITY-004城市生长玩法已获批或完成。

## CITY-004：Demo优先的最小运行入口

本次用户批准城市生长P1-α且要求减少检测。`& "D:/GODOT/Godot_v4.7.2-stable_win64_console.exe" --audio-driver Dummy --path . --script res://tests/growth_demo_smoke.gd` 只证明实际场景/合法release/乐句扩张与形态/声音路由/黑屏恢复可运行，不是人工体验或实时压力验收。F5/启动Demo.cmd直接游玩；操作见../Demo快速开始.md。稀有命名形态等未批准项继续待裁定；draft已于第32轮、tread已于第37轮按用户批准接入。

UI-004镜头操作复用上述场景入口追加`-- --camera`：实际放大→拖动→点选正确房屋→复位，城市状态不变；GPU截图留镜头推近.png。这只证明镜头/点击共用变换，不代替视觉优先等价性或压力验收。

PROPOSAL-004引力带：复用Demo入口追加`-- --draft`，受控位置变化/类别与音级不变/无直接R/V加成、快照/取消，以及实际地图拖动→边界生效→重划暂停1乐句→恢复/路由同步，截图引力带.png。不是踩路径或正式视觉优先验收。

CITY-004协调社区复用入口追加`-- --community --camera --draft`：实际整图配对、住宅模板变化、第二逻辑格独立点选、声部路由保留，同时验证镜头与引力操作。截图协调房群.png，日志房群运行检查.log。模拟乐句只验证场景行为，不证明真人观感或完整声画长期性能。

CITY-004释放反馈复用场景入口追加`-- --placement`：只读悬停及缩放不改快照、实际鼠标提交、非法位置保留旧pending、取消无残留与已结束限制。保存释放位置反馈.png及放置反馈运行检查.log；必须检查日志无Assertion/解析错误，单独exit0不足以证明场景检查通过。

PROPOSAL-005踩路径：复用实际GPU Demo入口追加`-- --tread`。必须验证真实拖动→只读预览→确认→未来边界落定；前两次保留邻接，第三次成路切边；反向归一、覆盖/取消、实际R/V同图一致、道路固定世界边界、家族断连保留成熟形态、跨边配对拆分保留声音、阻止跨边扩张与快照一致。日志必须无Assertion/脚本错误且exit0，截图踩路径足迹.png/踩路径成路预览.png/踩路径成路.png。有限模拟乐句/Dummy不证明物理音频、长期性能或人工体验；不要求重复压力/频谱/导出。

CITY-004/U17条件提示：复用实际GPU Demo入口追加`-- --conditions`。检验1乐句不强调/连续2乐句强调、只读真实缺口/快照、正常阶段计数推进不误报、升级清零、成熟和出生当乐句不计、道路断连/失谐说明、实际选中地图卡和B黑屏隐藏。日志条件缺口运行检查.log必须无Assertion/脚本错误且exit0，截图生长缺口提示.png/条件城市.png。仅证明这项场景行为，不替代真人体验或声音/压力验收。

UI-004风格小景：独立scenes/style_frame.tscn -- --capture-style-frame，实际GPU生成白网格/净画面/推近图，检查日志无Assertion/脚本错误且exit0；镜头鼠标定点、中键、Home及实际mips同场景检查。人工阅图另评接地/比例/遮挡/留白/整体色彩，不将技术运行当成v3-U21视觉冻结或全项目艺术批准。操作见../风格小景审阅.md。

ASSET-004历史SVG候选：style_frame.tscn -- --classical-frame --capture-style-frame实际Compatibility运行，检查四件SVG存在并加载、6纹理/6摆放、mipmaps、定点缩放/中键/Home，三图人工查看尺度/接地/遮挡；日志无Assertion/脚本错误且exit0。截图古典建筑小景_白网格/净画面/推近.png，日志古典建筑运行检查.log。此处技术/实现者画面检查不等于用户艺术定稿或时代音乐获批；轻微分面AA细线记录为待优化。

UI-004可听城市：真实GPU入口tests/audible_city_contract.gd，预填已结算而audible_frame<边界时保留旧地图/形态/列表/HUD/道路，到达精确边界后更新；核验下一拍一拍揭示、迁移/静音恢复、多预填历史、fork/只读/PCM一致、新pending取消、已生成PCM不可撤回提示与B黑屏。日志可听城市同步运行检查.log无Assertion/脚本错误且exit0；边界前/落定后两PNG人工查看。此入口不代替长期声音/性能或人工美感。

UI-003/U12获批边界切片：实际GPU入口`tests/boundary_diagnosis_contract.gd`，检查默认关闭、真实邻接和合成器基频差、抖/刺/其它张力分类、减弱运动静态形状、静音/Solo/长音关闭/迁移静音原因、可听边界道路断边及调音/迁移变化、未来试听来源提醒、实际滚轮/点选和B黑屏。开关/query前后城市/RNG快照及127样本PCM严格一致。日志边界诊断运行检查.log须无Assertion/脚本错误且exit0，动态与减弱运动两PNG人工查看；打印PASS但有脚本错误不能验收。当前33检查通过，仅覆盖spec.ui U10，不覆盖未实现E或HUMAN-VISUAL。

UI-004紧凑操作面板：实际GPU入口`tests/control_panel_contract.gd`。在1440×900核验默认/诊断展开时主要试听/确认/取消可见；真实原生下拉选择互斥工具、地图点击释放/拖引力/选足迹与确认取消，工具切换保留pending；完整收益/条件明细展开、实际滚动与收起不改变快照；可用方案下拉焦点空格不启动试听，B/Esc恢复工具和折叠状态。日志操作面板运行检查.log须无Assertion/脚本错误且exit0，默认/释放/诊断/明细四PNG人工查看。当前30检查PASS，不覆盖小窗口整套适配、长期音频/动态压力或真人体验。

UI-004可见轮廓点选：实际GPU入口`tests/picking_contract.gd`；真实PNG透明角落位于图片矩形内但落到空格时须收到empty_clicked且不抢街区选择，可见屋顶正确选择、生长半拍未揭示部分不抢点击/揭示后同一点可选、连宅两地块独立、缩放/平移与快照只读通过。日志轮廓点选运行检查.log无Assertion/脚本错误且exit0；当前12检查PASS。基线`-- --repro-only`有效FAIL及fixture失败保留废弃；实际截图＋为测试点击标注。仅验此次点选，不覆盖所有遮挡/触屏/小窗口或真人观感。

UI-004手动聚焦：复用实际GPU入口`tests/picking_contract.gd -- --focus`。真实FocusSelected按钮须启动缓动；连宅任一半以整张图在标题与条件卡之间居中且留边，保留所选逻辑ID；高楼同样完整取景。检查滚轮从当前镜头接管并保持鼠标定点、中键直接接管、同排ResetView恢复默认镜头、pending/城市/RNG快照不变。新增12项与原12项点选合计24检查，聚焦镜头运行检查.log须无Assertion/脚本错误且exit0；聚焦选中连宅.png查看整栋完整和主要操作可达。Dummy与受控场景不代表长期供音、所有小窗口布局或人工体验。

ASSET-001本地可携带Demo：`python tools/build_demo_bundle.py --engine <现有Godot.exe> --output <新运行目录> --evidence <新证据目录>`；旧目录拒绝覆盖。实际ZIP核对manifest/数据、源纹理SHA及ctex SHA、排除开发树；复制引擎从空目录挂载ZIP运行包外demo_bundle_contract.gd，检查AudioClock无MCP、三组全部纹理mips、最新控件、释放可见落定、聚焦只读、古典摆放。实际默认主入口/风格入口启动与日志错误检查、交付ZIP CRC及相对路径启动器另验。当前11隔离检查/44清单项通过，两PNG查看；--quit-after/Dummy的AudioStreamGeneratorPlayback残留警告单独保留定位，不称无警告或物理退出通过。证据本地运行包/构建记录.json，便携包不等同模板发行EXE、人测或长期压力。

UI-004完整柔和岛台：复用实际GPU入口`tests/growth_demo_smoke.gd -- --community --camera --terrain`；现有真实生长/配对/镜头/独立点选与城市不变检查，独立保存柔和岛台_全景/房群/推近.png。新增一次实际全屏黑屏RGB8字节全零检查和黑屏PNG，防止背景shader绕过B；最终日志须无Assertion/脚本/着色器错误且exit0。画面审阅完整地面承托、浅侧面/薄影、淡白网格和控件可读；不以本次模拟乐句证明长期性能/真人体验，不要求重复700栋/频谱/导出。

AUDIO-002满城Demo短时供音：`tests/demo_audio_supply.gd -- --seed=2026100800000001`配合实际GPU/WASAPI。合法release与17模拟乐句自然生成27实体后仅重置测试时钟，沿用初始9的固定校准gain。检查27路由/实际城市视图、一完整可听乐句、0下溢、真实边界落定与HUD第2乐句；最后等待自然绘制并正常释放主场景。最终9项PASS、exit0/日志无脚本错误或残留警告，证据AUDIO-002_demo_supply.json与满城连续播放运行检查.log/PNG。首次8项记录保留废弃，缩图字形误读原因已更正；不宣称生产HUD缺陷。此证据不覆盖长期实时生长、满城窄带辅助、人测或700栋性能，不要求重复其它全套检查。完整批准/未决/旧测试实际支持边界见Demo主线核对-第49轮.md。

UI-004社区绿化：复用实际GPU入口`tests/growth_demo_smoke.gd -- --community --camera --terrain --landscape --seed=2026100800000001`。新增只读候选/空格合法性/实际mipmaps、节点key稳定、release与hover清场、占格撤候选/锚点道路断连撤候选检查；复用已有家族/整图配对/独立点选/相机/B全像素黑屏。日志社区绿化运行检查.log全部PASS且无脚本错误/Assertion、exit0；社区绿化_全景/房群/推近PNG已看，黑屏RGB零。当前22实体2绿化，不以此扩大成最大6景观长期预算/新公园声部/完整自然动画/人工美感签核。原11整图源SHA不变、两新增树清单SHA/许可/alpha/origin及mipmaps已核对；参数新增landscape之外数值不变。

ASSET-001第51轮新版便携包：在第47轮隔离合同上增加成熟社区、软背景/完整岛台、装饰空格与B纯黑；固定种子真实release和12模拟边界，实际空目录GPU/Dummy15项PASS、46项纹理源/ctex SHA一致、171包文件，正常主/风格入口通过，日志无脚本错误/Assertion/WARNING。交付ZIP CRC和相对启动器已核验，两PNG查看（主图为聚焦初始房屋局部）。证据本地运行包_轮51/构建记录.json和隔离结果.json；保留47轮旧包/退出警告，未复现不等于修复，不把开发源WASAPI证据当包内物理供音验收。此为当前源画面里程碑交付，没有重跑其它全套或实现未裁定候选。

CITY-003第53轮人工叛离fixture：原计划`tests/city_contract.gd -- --case rebellion_fixture`现已可运行，实际headless/Dummy65项PASS、exit0/无SCRIPT ERROR/ERROR/Assertion。只证明人工指定渲染游标所在乐句边界+1音高、±5/±12%仅律动包络速率、显式恢复归拍与持续振荡相位；不是正式包围＋卡拍收服。两采样率、同偏移音高的drone逐样本一致/无关声部一致、实际律动不同、标量/分块/快照一致、恢复后的普通路径、真实前版本源码普通PCM/保护状态完全一致均通过。证据CITY-003_rebellion_fixture.json/log，首次64项不充分相位对照保留废弃并排除最终结论；tests/废弃/第53轮前混音基线.gd为归档对照依赖，不能删除或当运行游戏入口。未注入测试键的主城/正式听测不启用此切片；正式触发/包围仍待U05，人测/供音未由此验收。

## 2026-10-09批准切片的验收增补

设计吸收时没有运行下列新玩法验收。第55轮UI-006技术证据见下方补记，其余仍PENDING。实现时交付最小有意义入口与命令，脚本未创建前不写可复制的虚假命令；不要重复全套P0或700栋。数值取七份执行规格的新表，不再读取历史第一版。

| 规格 | 最低充分证据 | 不可冒充完成 |
|---|---|---|
| UI-006 / ASSET S8 | 同种子同镜头主城全景/推近、风格与古典小景前后图；贴图/实际地面origin/SHA；建筑树投影误差≤3°；组内重叠明度一致；影透明度跟可听进度；全RGB零；城市快照/PCM/RNG不变；27实体实测帧时 | 本轮审批示意图不是实际GPU新图；岛台承托薄影不能当太阳方向检查；实际资产人工审美仍未签核 |
| AUDIO-006 | 胚只有长音、群律动2拍渐入、央/腔成熟装饰、腔每乐句钟；原9与诊断drone保护；实际固定gain混音真峰值余量≥3dB、400ms窗drone比例≥25%；快照/分块一致、实际主场景短供音 | “更稀疏”不能证明峰值安全；没有事件钟包络参数前不偷用私有默认值 |
| UI-005 | 首次群/央/腔各1次、揭示后下一拍、稳定队列6秒+2秒/悬停、点击仅手动聚焦、×/OFF不补播、黑屏隐藏暂停阅读、试听不发真事件、重开清记录；快照/PCM/RNG只读，四行真实GPU图 | 不冻结城市或自动退出黑屏；不能把4秒第一版/2秒替换当第二版 |
| CITY-005 | 同音雏形/两音成形，缺格/跨家族/工业/未成熟/断路/不协和/迁移反例，2实际边界/预测/快照；每8拍成员i仅第i拍起音、MIDI序列正确，1小节交叉；mute/solo；实图与短音频，新混音峰值/RMS | 不把同音自动成形、两组呼应或图线动画当轮唱；自动证明时序不是证明好听 |
| AUDIO-007 | (15,15)居中、x−y左右反例、量化迁移、镜头平移/缩放不改路由；正式黑屏fixture/A5参数未变 | 本次代码核实仅证明缺陷与修正授权，未证明修复 |
| AUDIO-008 | 未合并压力基线、分组后真实CPU/下溢/峰值/RMS、相干同音反例、逐实体诊断/轮唱拍号保持；给出新的上限依据 | a·√k不保证同相位功率恒定；旧700静态成绩不能代表未来时代供音 |
| RUN-001 / RUN-006 | 固定12乐句与章首祝福；3条不同无向边/末R70、同边不刷分；最快4/最慢2完整路径、第7章不再跨；过门16秒城市冻结音乐连续、等候锚点/快照；Ⅰ→Ⅱ换装、扩音阶与遗产实图 | 第1次过时代不等于五时代完成；现代不能从不存在的新增音抽来客；切片约3章是演示范围而非把完整局改成3章 |
| CITY-006 | 六地标觉醒连续2边界/最多3合法落点、多格共享边不重复、单槽落成/吸收与轮唱失效、规则作用半径边界/失谐抑制/恢复、遗产音色与外观不替换、实际首批候选池 | 目录27座不等于27座实现；只有两可用候选全入选时不称完整随机；原始失谐与规则豁免分开显示 |

灰度目标沿批准方案：顶↔受光ΔL*≥5、受光↔背光≥10、底边↔地面≥8；相邻面HSL明度差≤30百分点。真实图尺寸/材质采样需记录，不能用几何示意图代替。声学更换用A6与实际混音检查；真人/人工保持原真实记录要求。P2-α至少3人每人一局与三问题，至少2人三项通过才能P2-β。


### UI-006第55轮技术结果

实际入口tests/lighting_contract.gd：固定种子真实17边界9→27、同层满/半进度重叠GPU字节一致、可听半拍、1296000像素RGB全零、城市/RNG及289帧边界PCM摘样对照不变、当前27实体120静态帧与30单栋生长帧。--style/--classical-frame保存同镜头小景；--asset-gray输出19件真实GPU512px图。tools/check_demo_lighting.py核验19件主/影/接触SHA与实际投影顶点、P0派生alpha/origin不变、15建筑同材质三面和底边采样。灰度操作口径见U14a，不能把白墙与陶土顶跨材质比较，也不把AA外缘/亚像素树干当完整竖面。

最终日志无Assertion/脚本错误、均exit0；完整记录光影统一-第55轮.md与验证记录/Demo/UI-006_第55轮。静态平均10.84ms/P9511.92ms，单栋动画重建平均1.63ms、场景P9514.20ms；一次成熟集合改变重建19.27ms。只证明当前受控GPU/Dummy切片，非长期音频供给/多栋同时生长/700性能。实际新图人工仍PENDING。最初快照JSON类型、CanvasGroup半透明复合、浅基座失败证据保留废弃，不以exit0/CAPTURE判PASS。
