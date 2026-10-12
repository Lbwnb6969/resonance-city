# 作者房屋回访卡：集成证据

玩家点击实际作者房屋或名牌，356px暖石卡显示该栋真实道路朝向缩图、明确玩家街坊名、当前已听音及下一可写拍的待播音；点击五音正式改音后收卡。下一段为主动作，真实家族留地、单栋初选命名为次级动作；旧工具仍可展开、滚动和返回。开卡/Esc/关闭/开卡时地图右键不改听前音控、不撤已提交操作。没有改World、音频公式或存档格式。

生产前阅读：16相关全部正文、17镜头与资产合同、11作者创作/继续段落、12声音/可听快照、spec.ui U4/U16–U22、audio A18/A20/A22/A26、proposal事务。Root分配组件和音频只读合同，亲自接共享菜单/镜头/输入与唯一实际GPU/WASAPI；未调用Blender或生图。

命令：

```
& 'D:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --headless --audio-driver Dummy --path . --script res://tests/round217_authored_card.gd
& 'D:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --headless --audio-driver Dummy --path . --script res://tests/round217_authored_retune_audio.gd
& 'D:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --path . --audio-driver WASAPI --script res://tests/round217_authored_house_live.gd
& 'D:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --path . --audio-driver WASAPI --script res://tests/round217_authored_house_handoff_live.gd
python tools/merge_docs_compact.py
python tools/check_doc_links.py
```

原生卡Dummy8/8，见相邻 `round217_作者回访_面板/card.json`。音频合同最终11/11，见相邻 `round217_作者回访_音频/contract.json`：两次真实作者事务，回访较早深流C2→E2；完整13072帧float32双声道与同源正式提交逐字节一致、最大误差0，拍后与未改源差0.0175477。原Solo/Focus/mute、另一作者、独立待播规划与RNG保留。render-ahead消费事件后仍旧音＋待播，越可听帧才新音，结构继续等乐句。

Root实际NVIDIA RTX5070Ti/OpenGL3.3、Windows/WASAPI：`live_2026-10-12T22-48-23/live.json`，31/31，exit0，无脚本/资源诊断。既有生产首声定位入口进入warm（不是重验整段规划），之后选音/确认/实际房屋回访/五音/Tab/Enter/留地/命名入口/更多工具/返回/下一段均为原生事件。街坊名“橄榄庭街”经生产作者容器确认作为夹具；命名编辑完整链继续由Round216证据承担。800×600与1440×900均356×381原生卡，真实缩图和完整屋顶/门面避让；改音C3→G3拍前/拍后标签正确。四秒88200设备输入，峰值0.274298131465912，0裁剪、0新增underrun；WAV是送设备的输入，不是扬声器回录。

Root及独立Agent审图通过该视口范围。独立代码复核发现开卡后地图右键仍沿旧通路撤待播、更多工具固定返回按钮未扣滚动高度，两处修正前源码/31项测试原件保存在`废弃/UI/round217_右键与旧工具预算修正前/`。只补受影响 `handoff_2026-10-12T22-57-05/handoff.json` 6/6，exit0：实际暖庭重新听到，长工具800窗口内596×506、固定返回和内容滚动可用，真实待播改音在原生右键关闭后完整状态不变。此项冻结输出以稳定检查取消前状态，不另宣称新增设备录音。JSON的scroll位置在返回后隐藏态读取，工具页布局以保存的panel和00截图为准。未重跑31项或历史矩阵。

失败保留：组件首次TextureRect枚举错误及源码/log在`废弃/验证记录/round217_作者回访_面板/枚举修正前/`；集成首次夹具继承重名在`废弃/验证记录/round217_作者回访_集成/夹具重名修正前/`；音频首跑10/11错误地把完整score当作不变音控，原件在音频废弃目录，改成只比listener/focus/muted后11/11，未改生产；补测误调用model.snapshot导致中止，源码/log/当时截图在`废弃/验证记录/round217_作者回访_集成/补测API修正前/`，改用实际capture_state后6/6。失败日志不改写全绿。

Git阶段前 `codex/backup-before-round217`→e0a6af1，6份相关原稿在`废弃/UI/round217_作者卡精修前/`，backup_check.json核对全部源码内容相同；原工作区字节保留，既有Git CRLF/BOM差异单列。合并29源，33文档386本地链接0错误。本轮未改spec/world_v2数值。

本阶段可收口。技术通过、截图检查与真人审美/听感/乐趣分开；尚无真人反馈。最重要的下一项是读取完整相关美术/地形文档后精修大片空地与河岸层次；近景联合浅石侧墙/瓦纹收边和玩家范围精确试听继续待做。用户作品和无关未提交UID未参与验证。
