# 空间与身份执行规格

输入：世界位置、高程、占地、道路段、局部墙面锚点。输出：合法性、命中对象、连接候选与影响范围。

全局使用连续坐标；房屋局部单元通过本地变换映射到世界。不使用局部格索引作全城道路/声音邻接。房屋、道路、区域、作者记录都使用稳定 ID，几何缓存仅引用它们。

检查完整占地、入口、道路净空、水体和支撑；不以 R/V 或音程筛掉建造。道路接入用真实曲线和拓扑，旧声学耦合与可听声场分开计算。

验证：墙面/世界映射往返、转角/层高命中、连续道路不量化、跨河无桥无步行捷径、存档 ID 不随排序改变。

完整旧参数、公式和合约 ID 见 [迁移前 spec.space](../../废弃/文档/2026-10-14_综合优化前/文档/01_执行规格/spec.space.md)。

## 现有实现兼容参数

以下表仅用于复现当前代码/生成配置。保留数值不恢复旧玩法语义；新建造不受这些音乐/额度/自动生长参数限制。

## 表 SP8 · 运行配置键

| 键 | 值 | 说明 |
|---|---|---|
| schema_version | 2 | |
| world_min / world_max | -8 / 40 | |
| residential_radius | 0.45 | |
| base_coupling | 2.0 | A 的封顶 |
| distance_sigma | 1.8 | |
| gap_cutoff | 4.0 | |
| near_neighbour_count | 12 | 表 SP5 的 `N₁₂` |
| industrial_factor | 1.3 | |
| partial_occlusion | 0.7 | |
| forest_factor | 0.85 | |
| water_factor | 1.15 | |
| homogeneity_threshold | 0.40 | 表 SP4 的 occ 阈值 |
| homogeneity_M | 0.7 | 表 SP4 的 M 值 |
| homogeneity_dv_scale | 0.5 | ΔV 减半 |
| comparison_tolerance | 1e-6 | |
| community_min | 4 | |
| community_max | 40 | |
| projection_x / projection_y | 28 / 14 | |
| pan_divisor / pan_limit | 12 / 0.8 | |
| terrain_height_screen_scale | 14 | |
