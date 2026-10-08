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
assert (root / '资产/01_原始素材/已购素材/README.md').is_file()
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
| ASSET-001 | `tests/asset_contract.gd` / `license` | 来源/许可文件/白名单与构建依赖 | 转售包或派生图进入成品 |
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

资产脚本还需提供`--case packages`（四包版本/下载日期/许可证存在）和`--case palette`（基础1张24槽色板）。未下载不得填写已完成；原件禁入库声明完成不代表构建依赖审计已通过。

## 6. 通过与停工记录

每次执行：规格ID、实际命令、退出码、stdout摘要、证据路径、未确定项。测试文件尚不存在记PENDING；规格待裁定记BLOCKED并指Uxx；只有真实执行满足判定才记PASS。不改变评审数字来迎合测试结果，也不把有冲突的规则自动忽略。

## 7. 后续用户裁定与已实现验收补充

AUDIO-004初始响度使用spec.audio A9固定gain口径：`& D:/GODOT/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/loudness_contract.gd`。独立FFmpeg输入测量初始−16±0.10LUFS、所有已定义对照真峰值≤−3dBTP；后续状态报告响度，不再次归一化。该命令当前已实现，证据见PROJECT；不足时的RMS补偿与HUMAN-SPEAKER单独验收，技术PASS不能替代真人。

AUDIO-004不足时补偿入口：`& D:/GODOT/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/rms_guard_contract.gd`，按A10稳态/完整8秒RMS≥25%，不复活mute/不改变peer PCM，跨窗块与快照一致。实际最坏辅助供音另用`tests/live_audio_contract.gd -- --case assist_stress`，显式WASAPI，0skips才可用于正式听测供音门槛。

正式真人听测已可从F5按钮进入；操作与命令见`../P0真人听测操作.md`，协议A11。技术工具合约`tests/listening_contract.gd`只验fixture/8秒PCM/黑屏/记录隔离。真人统计使用`python tools/grade_listening.py <同条件3份真人CSV> --condition headphones_standard|speaker_standard|speaker_narrowband`；自动来源、下溢、缺题、重复/混条件会拒绝，不以工具PASS代替HUMAN-AUDIO/SPEAKER。


PERF-001入口已实现，P0固定条件以spec.ui U6为准：主场景 `-- --performance-fixture=700`，Compatibility实际1440×900、vsync禁用、35×20/700个单整图、9纹理种类、一个全屏additive窗光；预热10s后测60s、平均≥60fps并p95≤16.67ms。原每帧CSV/截图/硬件/驱动/JSON按日期写验证记录/P0/性能，最新汇总PERF-001_700.json。提前Esc/无真实显示/少实例/阈值不满足不能PASS。固定静态压力成绩不证明未来动态生长或完整声画同时运行。
