# 自然与生活 · 验证记录

本轮新增连续植被工具、分块实例化、共享水面流动与可保存生活次数，保留既有房屋/道路/作品能力。参考 Tiny Glade 的资源/植被语义及局部生成，Foundation 的 Visit Building 到达→等待→完成需要；自制几何和规则。

## 命令与证据

项目根使用 `D:/GODOT/Godot_v4.7.2-stable_win64_console.exe`：

```powershell
--headless --path . --script tests/test_city_creation_state.gd
--headless --path . --script tests/test_city_creation_life.gd
--headless --path . --script tests/test_city_creation_play.gd -- --isolated-session
--path . --script tools/check_nature_performance.gd -- --isolated-session
```

三个合约与图形性能夹具均 exit 0，无脚本运行错误。

- 状态：弧长采样 dense/sparse 笔画同密度/种子/位置，整笔撤销/重做、擦除恢复、植物高水位、坏存档拒绝、旧版确定迁移、建设隐藏后撤销原树恢复。
- 生活：实际到达并驻留计数；无关编辑保留 node/位置/等待；断路取消待服务，恢复可达后继续；非零采购/小聚次数保存回读。
- 完整viewport输入：植被预览Esc零写、整笔事务、Shift擦除、同ID重做、精确保存；一笔只改相关植被块，不改房屋/道路，居民节点保持。输出revision15、采购9、小聚7，failures为空。
- 实窗实际鼠标笔画：新增3株，1块变化，房屋/道路变化均0，渲染重建1.379 ms。[最终笔刷界面](nature_03_final_ui.png)、[落地树群](nature_02_painted.png)。初始工具条/帮助卡重叠已修正，最终界面图复核通过。

## 性能

Godot4.7.2 GL Compatibility，本机RTX5070Ti Laptop，1440×900，6房/6路，500株合成混合小树/灌木，PCM完成后300帧测量：约180 FPS，delta p95 5.556 ms，710 draw calls。22块初次重建26.773 ms；单块变更2.290 ms，其他块实例保持。[原始结果](performance.json)、[压力场景图](500plants.png)。

夹具是批量渲染压力场景，网格密度不是自然画笔的审美布局，也不是500座建筑城市。低配、大城、长时操作仍未验证。初版重复查全体障碍导致单块约18ms，优化为按障碍签名/实例指纹复用可见性后降至2.29ms；旧原件保留在废弃验证目录。

## 持久边界

schema1兼容追加plants/plant高水位/life_progress；植物位置和缩放规范为引擎精度确保回读一致，非法版本/位置/类型/计数拒绝。生活次数由实际事件累计，撤销建设不会删掉发生过的生活；仅保存次数，重新开城行程从家开始。正常继续入口15秒保存生活变化，关闭也保存已发生事件。

水面流动依赖共享着色器TIME，不逐帧生成网格或等待音乐。水体形状编辑、地形高度、区域工具、完整经营与时代尚未完成。真人美术/听感/乐趣没有新的签核结论。
