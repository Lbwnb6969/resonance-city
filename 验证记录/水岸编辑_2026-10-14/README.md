# 水岸编辑 · 2026-10-14

Tiny Glade 优先的连续池塘/水渠与独立水层；Foundation 补充可达和居民生活。美术方向已明确以本地 Tiny Glade 参考库为基础，当前程序几何仍需改善光影与自然层次。

## 已验证

Godot 4.7.2，RTX 5070 Ti Laptop，OpenGL Compatibility，1440×900，有声。`tools/check_water_performance.gd` 使用6房、7路、4笔水域，包含主河交接、闭环岛洞、两次过水桥和植物隐藏。等PCM完成后取300帧：约180 FPS，delta p95 5.56 ms；591绘制调用、196776三角。

四笔水域合并水层28.062 ms，总重建30.281 ms；无关房/路/地景保持原实例，只4个植被块更新。无变化重建复用水面网格。三角覆盖查询证明河渠交接单层、不覆盖岛中央；法线向上。原数据见 [performance.json](performance.json)，实窗见 [water_island.png](water_island.png)。

实际拖鼠标画一笔池塘：水层2.738 ms、总重建4.162 ms，0房/0路重建、1植被块变化，树实例16→15。操作预览见 [water_preview](water_preview_20261014.png)，完成后的实窗见 [water_after](water_after_20261014.png)。当前实窗作品另存于 `user://city_water_live_review_20261014.json`，正常继续模式恢复自动保存。

下列最小合约均 PASS：

- `tests/test_city_creation_water.gd`：连续掩码、完整足迹、冲突零写入、ID/种子/历史、非法恢复、旧档迁移、隐藏植被、原河/新塘/新渠/多水桥。
- `tests/test_city_creation_water_life.gd`：回读后的实际跨桥，填水/撤销同节点同平面进度且桥高同步，驻留改水保留且计数一次。
- `tests/test_city_creation_state.gd` / `tests/test_city_creation_life.gd`：原状态与生活无回归。
- `tests/test_city_creation_play.gd`：1440×900真实viewport输入完整编辑、工具7、Esc、Shift填回、撤销重做、局部缓存、保存恢复及实际采购/小聚。revision20，采购9、小聚7，failures为空。

复跑使用 `Godot --headless --path . --script res://tests/<合约文件>`；图形性能使用 `Godot --path . --script res://tools/check_water_performance.gd`。夹具初始化前关闭持久模式，独立于个人作品。首个性能夹具因未声明动态调用的Array[Vector2]终止，已改为显式类型；一次测试桥起点落在水渠中被合法拒绝，已改为干地完整跨岸。

## 边界与下一步

当前证据覆盖本机小河湾；没有大城或低配结论。独立水层每次改水仍整体重建，带孔并集成本随边界增长，扩城需空间分块。地形仍平面、基础主河固定；房屋/道路冲突需要改路径。居民行程未保存，最近路段属于断开支路时的重寻路停行问题已记入PROJECT。

Git基线标签 `backup/pre-water-edit-20261014`，旧文档 `备份/水岸编辑前_20261014/` 保留。没有删除参考库、旧河谷或个人作品。
