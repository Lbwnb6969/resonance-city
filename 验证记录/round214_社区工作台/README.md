# 214：真实街坊工作台

本阶段补社区经营的直接入口，不宣称整社区调音或完整SP6已完成。默认24栋、三个各8栋已建街坊，仍有10个规划社区记录。成员、音级、公建、作者/留白只取真实已听World与音级；不把背景家族当作者作品，不读render-ahead未来房屋。UI主动作走既有规划和声音控制，未改World/存档格式。

## 最低充分验证

- `round214_community_state.gd`：Dummy17/17，真实公共/暖庭/留白/作者成长/下一拍音级/未来门控和只读；证据在相邻`round214_社区状态/`。
- `round214_community_focus.gd`：Dummy16/16，真实成员占地/地形、相机与等值World缓存、黑屏/关闭；证据在相邻`round214_社区成员焦点/`。
- `round214_community_panel.gd`：Dummy10/10，原生街坊切换、实际全部作者根、音级、800/1440和不改World；`panel_contract.json`。
- `round214_false_mute_map.gd`：Dummy单项1/1，回全城仅解除独听/聚焦，保留原静音；true/false静音map都不会孤立启用无效果按钮，最终disabled序列[true,true,false,false]；`false_mute_contract.json`。前1/1版本在废弃中保留，不改旧结果。
- `round214_community_live.gd`：NVIDIA/OpenGL3.3+WASAPI实窗12/12；C/8真实成员、原生规划/章程/卡牌/CID、800/1440、关闭不改World。`run_2026-10-12T20-20-10/live.json`与3张截图，日志`live_20261012.log`。
- `round214_community_followup_live.gd`：原生名字命中、下一可写拍真独听、原先静音的临时独听/关闭恢复、切街坊、同CID公共规划，原始计数14/16。两失败源于探针在反馈已自动打开时再次按P把它关闭，无法接到声音及作者回访；其中`new_author_house_reaches_device`在作者根为空、边界−1时仍误通过，不能用作作者落成证据，后续8/9项补测明确要求真实作者边界。没有改写原结果。源码/JSON/图/WAV/日志完整保留`废弃/验证记录/round214_社区工作台/反馈开关探针修正前/`。4秒真实设备输入88200样本，峰值0.132031723856926，0裁剪/0新增underrun。该波形是渲染器送入WASAPI的PCM，不是扬声器回录。
- `round214_community_revisit_live.gd`：仅补受影响公共→声音→回访路径8/8，`revisit_2026-10-12T20-31-32/live.json`。随后独立审查发现原先静音社区会在作者handoff恢复时再次静音，显式作者入口排在恢复后解除其真实CID静音。只补同一受影响实窗9/9，`revisit_2026-10-12T20-39-18/live.json`与2图，日志`revisit_muted_20261012.log`；原8/8证据不覆盖。确认building-00025、公建、暖庭真实4秒试听/确认/已听、9实际成员、1公共馆/1作者/1留白、作者回访清旧solo且已听mute=false。

命令采用以下入口，headless独立合同额外加`--headless --audio-driver Dummy`；Root实际窗口没有Dummy：

```powershell
& 'D:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/round214_community_live.gd --log-file 验证记录/round214_社区工作台/live_20261012.log
& 'D:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/round214_community_followup_live.gd --log-file <项目内日志>
& 'D:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/round214_community_revisit_live.gd --log-file 验证记录/round214_社区工作台/revisit_muted_20261012.log
```

## 画面与尚未证明的内容

Root实际审图，独立Agent只读审看基础3图及公共/作者回访2图：800工作台成员、用途、音级、公建、留白、作者按钮和主规划动作可读；左侧真实街坊留出操作空间。旧作者菜单596像素宽，遮部分目标房屋和首段Guide，能改音但不构成目标门面净空通过。该菜单后续细化。

没有真人操作/审美/听感/乐趣结论，没有重跑历史总链或1511栋性能。仍缺整社区原子调音（P7/P8真实成本与共享槽）和完整道路/地形加权社区扩张。用户新方向已将这两项降序：固定分组工作台保留为次级工具，优先真实联合房体与玩家自己界定街坊；本轮不冒称自定义范围或联合大房已完成。

## 备份与失败证据

`codex/backup-before-round214`指向`13b2f56`。原四共享UI源在`废弃/UI/round214_社区工作台前/`；原文档在`废弃/文档/round214_社区工作台接续前/`。false静音/作者静音交接改前源码分别在`废弃/UI/round214_回全城静音判定修正前/`、`round214_作者静音交接修正前/`。

最早followup10/16是窄按钮探针用旧+35px偏移点击相邻街坊，原证据在`废弃/验证记录/round214_社区工作台/原生窄按钮探针修正前/`；只修探针原生中心点击。面板原10项初次输出目录缺失没有可保存原日志，不伪造；false静音探针初次常量与原生类同名，源码/日志在`废弃/验证记录/round214_回全城/夹具原生类名修正前/`。成员焦点15/16原查询基线错误的日志/JSON保留其证据目录，最终16/16另有明确身份。
