# Round210 四面环柱文化馆

本轮只更新四个 `refined_civic_loggia` 朝向的实际模型、PNG/SVG、几何投影阴影/接触阴影、四张稀疏夜光与相关 manifest/validation/接触表。默认和作者住宅、商铺、两类树以及 28 张非文化馆夜光的条目与 296 文件哈希均保留。生产公共 World 占地、creator 入口、Catalog、Sprite、UI、声音和存档未由本任务修改。

文化馆从单正面六柱廊改成 20 根 Doric 环柱廊：正背各六柱，两侧各四柱；缩窄后的真实内厅宽 1.24、长 0.81，在柱与墙之间留出廊道。细节保留柱身凹槽/微鼓、柱头、四面连续 architrave、triglyph/metope、接角檐部、三阶石台与前后完整石山墙/浮雕。四向都由同一几何在模型 Y 轴旋转，随后按既有世界太阳方向照明、BSP 排序、PNG 烘焙与实际几何投地阴影；没有旋转 PNG 或添加屏幕身份描边。

主门仍位于原 +z 立面、模型门面约 `(0,0.135,0.410)`，World 朝向仍为 0 北、1 东、2 南、3 西。`plot_span=1`、最大地脚轴 2.12、世界缩放 18.678292、地面原点 `(0,0,0)`、最底石台的实际 contact footprint 与原资源完全一致。上两级石台调整后真正托住后排柱脚。每个新朝向 3029 面，原为 1507 面；PNG 的新 origin/ppu 由真实投影重新计算，夜光精确跟随它们。

入口：

- `python -B tools/build_refined_valley_art.py --civic-only` 定向生成四套文化馆及其四张夜光，更新相关清单/接触表。每次执行开始快照当前其他文件、条目和文化馆图像，执行结束校验它们不变；生成器不依赖历史废弃目录或旧 296 哈希。
- `python -B tools/build_refined_valley_art.py --emission-only --emission-role civic` 单独刷新四张文化馆夜光，保留现行 28 个其他夜光条目/PNG/import。完整 `--emission-only` 的既有入口继续保留。

四张夜光来自新真实门洞和最多一个可见新内厅凹窗，所有新柱廊、屋顶、框、百叶与墙面都作为黑色 BSP 遮挡，最后裁到底图 alpha。保留 `#FFC982` 直通 alpha、门峰值 0.56/窗 0.30、同父 Sprite 的原点与缩放合同。背面 o0/o3 的主门仍暗，正面 o1/o2 可见门光；不增加全亮窗格。四张夜光独立最近三角采样为 100% 一致。

`文化馆四向旧新对照.png` 展示四朝向同世界地脚尺度 x5 的旧/新白昼与新夜色；每格还包含真实 `.62 clearance / .7` 场地缩放后的约 46×40 像素样本。它是离线资产对照，不是实窗截图，也不是用户审美结论。独立三角深度/面身份在四向分别确认 13、14、14、13 根露出的真实柱、2300 以上像素的主要山墙与 2000 以上像素的连续檐部（参考长边 256）。世界光 RGB 与 BSP PNG 的最小一致率 94.1751%，使用 24 字节 RGB 容差并排除三角边缘；细柱、密集瓦和缩图抗锯齿包含在差异中。

验证命令与结果：

- 定向生成退出 0：`4 geometry + 4 emission / 296 noncivic files unchanged / PASS`。生成记录为 `civic_generation.json`、`emission_generation.json`、`geometry.json`。
- `D:/GODOT/Godot_v4.7.2-stable_win64_console.exe --headless --audio-driver Dummy --path . --editor --import --log-file 验证记录/round210_文化馆四向/import_dummy.log` 退出 0，四个 SVG、底图、夜光、物理阴影和资源接触表完成重新导入，无编译/加载错误。
- `D:/GODOT/Godot_v4.7.2-stable_win64_console.exe --headless --audio-driver Dummy --path . --script res://tests/round210_civic_art.gd --log-file 验证记录/round210_文化馆四向/civic_dummy.log` 最终退出 0，10/10：新四向、真实世界光/遮挡、原占地/接地/朝向、296 原文件及其他条目保留、四张夜光像素边界，以及 16 个实际已导入 Texture2D 的 mipmaps 均通过。共检查 3,594,240 夜光像素，最高 alpha 字节 143。

旧四套文化馆、四张夜光、generator、两 manifest、validation、接触表及原夜光证据共 49 文件完整复制至 `废弃/美术/round210_文化馆四向改造前/`，含 `.gdignore` 和复制 SHA256。首版 Dummy 为 9/10：JSON 数值解码为浮点，合同预期 cardinal 数组用了整数，严格 Array 比较失败；实际四方向正确。首版失败 JSON、raw log 与脚本保留于 `废弃/验证记录/round210_文化馆四向/首版合同类型断言/`。只修正夹具数值类型后补跑同一最小合同，没有重生住宅、商铺、树或其他夜光。

旧 round209 资产合同对当时 256 建筑文件及主 manifest 的固定哈希仍是历史证据；本轮有意替换四套文化馆后不重写旧证据或把它宣称为当前通过。本轮合同单独证明新四套和保留的其他文件。

Root 已完成唯一[生产实窗](../round210_古典公共建筑/README.md)，31/31：正常 UI 顺序在两岸合法位置建立文化馆，实际道路选择o3/o1，公共缩放约0.885714，暖庭真实试听/确认与作者根屋接续、院地、白昼/夜色遮挡和800窗口通过。四秒设备输入88200样本、0裁剪/0新增欠载；资产、截图和实际窗口分别记录，仍无真人审美、听感或乐趣认可。
