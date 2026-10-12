# 作者回访的声音提交

命令：`& 'D:\GODOT\Godot_v4.7.2-stable_win64_console.exe' --headless --audio-driver Dummy --path . --script res://tests/round217_authored_retune_audio.gd`。实际运行另以 `--log-file` 保存独立日志。

结果：11/11，exit 0；成功原件为 `run_3666331/contract.json`，目录根 `contract.json` 为同内容入口，日志 `dummy_20261012_224941_907.log`。未运行 GPU、WASAPI 或用户作品。

夹具从真实 24 栋开局，经正式事务生成较早深流 `building-00025` 与后来织机 `building-00026`。真实音控先独听/聚焦 west-1、静音 east-2，另保留待播 compact 章程。回访旧深流并按原生 E 按钮，C2→E2 的声音帧为 749700，结构帧为 1058400。打开与重复同步不写模型、相位、RNG、独立待播或听前音控。

完整 13072 帧 float32 双声道 PCM 与同源 `freeze()+submit(retune)` 逐字节相同，SHA-256 `3e1736fc1a73d53d64b983be5e2ed3e6185dfc2d1af9f5834e71aecb02b5b27d`，最大绝对误差 0；拍前与未改源相同，拍后 2048 帧与未改源最大绝对差 0.0175477275624871。设备可听帧未到时，即使事件已移入 sound_trace，仍显示“已听 · C2 / 待播 · E2”；越过声音帧后显示“已听 · E2”，World 音级仍为 C2 等待乐句。三阶段原始字段保存在 JSON evidence。

首跑 10/11 的 JSON、日志与当时测试源码原样保存在 `废弃/验证记录/round217_作者回访_音频/整体score误作听前音控/`。测试错误地要求整个 audible_score 改音后不变；主题音序应真实变化，因此仅将听前状态比较收紧为 listener/focus/muted，生产文件未改。原 JSON 内的运行路径是移动前的历史路径。

证据只覆盖本次回访改音路径、时间门控与同源 PCM，不代验长期预算、真人可辨或审美；现有主题连续交接规则仍由 Round173 合同承担。
