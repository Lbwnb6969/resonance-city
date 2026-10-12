# 第一时代连续石街与门前接地

玩家可在根目录 `启动Demo.cmd` 看真实主路/支路上的连续暖灰石面、错缝石块和低路沿；按 P 规划、试听并确认暖庭，下一句真正听见时，新屋的外台阶接地出现。古典四向窗洞、门向与真实道路关系沿既有资源，未改 World、道路拓扑、用途、声音、存档或玩家作品。

街面13/13 Dummy合同：9块连续石床、237石块、252路沿，保持主路/支路真实0.25/0.18半宽；0.014路沿高、15种±0.035局部色调。927/927真实已铺纵向外沿采样覆盖，最差单路长度比98.729%、最高100.226%；交叉口整块路沿裁开，水域与真实占地覆盖面积0。实际第25屋听见前不重建/提前铺装，听见后一次刷新；构建13.757ms，缓存查0.132ms。见[几何合同](../round212_古典街面几何/surface_contract.json)。初版输出被覆盖后据完整工具输出恢复，明确来源在[归档说明](../../废弃/验证记录/round212_古典街面/路沿共边修正前/来源.txt)；后续51.26%覆盖失败原件也保留。

门前11/11 Dummy合同：24栋真实外台阶的24薄阈/24短磨损片裁入原占地，不填真实地块到道路的空隙，避开水、道路、邻屋、公共组件/洞与预留。实际出生且完整揭示后才出现；同源render-ahead World fork替换与返回不重建、不新增空间查询。原10/10对象引用版逐文件SHA256确认原样归档。见[接地合同](../round212_门前接地/frontage_contract.json)。

Root最终Windows/OpenGL 3.3 NVIDIA RTX5070Ti + WASAPI实窗 **23/23，exit0**，无script/geometry诊断。证据[run_2026-10-12T19-05-12/live.json](run_2026-10-12T19-05-12/live.json)，截图00/01为同城同镜头旧/新材质，02是真实24栋开局，03为原生800×600暖庭点击试听，04是Enter确认后的真实building-00025，05检查同城夜色。实际新屋石面构建13.06ms；开局48门前片到实际落成49片。未来门控、相机/昼夜几何复用、真实面板356×474与落点完整净空通过。四秒设备输入22050Hz/88200样本，峰值0.2950408161、0削波、0新增underrun；WAV为实际送入设备的城市合奏。

首个实窗探针刚打开原生Container时立即点击旧坐标，未启动PCM，随后读空stream中断；前三张图、progress、原日志/脚本保留于[布局等待修正前](../../废弃/验证记录/round212_古典石街/菜单布局等待修正前/README.md)。只修探针等待0.7秒，随后完成当前受影响实窗；生产输入未改。未重跑历史总链或1511栋性能。技术通过、截图审阅与真人认可分别记录；尚无真人审美、乐趣或听感结论。大片单一黄地、街坊到自然地貌的衔接与石铺渐退端头仍待细化。

验证命令：

```powershell
& 'D:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --audio-driver Dummy --script tests/round212_classical_street_surface.gd
& 'D:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --audio-driver Dummy --script tests/round212_frontage_ground.gd
& 'D:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --check-only --script tests/round212_classical_streets_live.gd
& 'D:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --path . --rendering-method gl_compatibility --audio-driver WASAPI --resolution 1440x900 --log-file '验证记录/round212_古典石街/live_20261012_layout.log' --script tests/round212_classical_streets_live.gd
```

Git备份`codex/backup-before-round212`指向`c989fd5`。Root负责Ground/生产实窗；两个子Agent各自拥有新只读世界几何与Dummy合同，独立截图Agent审阅实际GPU图。

Root与独立截图Agent实际复核六张图，没有曲路/路口裂隙、整段漂高、侵屋或800界面净空阻碍。石铺只随真正住人街段出现，不是整城铺满。下一项优先改善石面暖冷/磨损层次与均匀缝线：中景仍像窄网格带，材质完成度低于建筑贴图；之后处理大面积空地与街坊边缘。此判断来自截图，不是用户美术签核。
