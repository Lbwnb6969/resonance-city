# 连续城市工具执行规格

输入：道路样条、特殊建筑轮廓/朝向、功能区画笔/轮廓、公共空间和桥端点。输出：连续几何、真实入口/路口、区位权重和局部依赖变化。

道路端点与图节点一致；平面相交不自动构成不同高度道路的路口；桥有实际跨水几何。改路保留玩家指定大形状，系统补交叉口、路缘和门前过渡。

功能区影响后续生成材料和内容，自己不新增房屋。特殊建筑由玩家放置和编辑，后期能力改变工具机会；旧 27 地标目录为内容池，音乐觉醒条件与 R/V 奖励退出。

服务/车辆可复用已有路网与来源 ID，不把客流转成自动房屋扩张。验证道路接门/过水/高差、连续区域范围、公建移动/改用、局部缓存和存档。

完整旧参数、公式和合约 ID 见 [迁移前 spec.city](../../废弃/文档/2026-10-14_综合优化前/文档/01_执行规格/spec.city.md)。

## 现有实现兼容参数

以下表仅用于复现当前代码/生成配置。保留数值不恢复旧玩法语义；新建造不受这些音乐/额度/自动生长参数限制。

## 表 E7 · 可玩河谷的街坊、公共空间与公交

| 参数 | 值 |
|---|---|
| neighborhood_depth | 5.6 |
| garden_street_depth | 5.6 |
| garden_lot_rows | 7 |
| branch_road_half_width | 0.18 |
| park_half_width / park_half_length | 1.7 / 2.0 |
| civic_half_width / civic_half_length | 0.8 / 0.9 |
| service_walk_radius | 18 |
| carriage_speed | 0.95 |
| tram_speed | 2.2 |
| bus_speed | 1.8 |
| car_speed | 2.8 |
| bus_dwell_beats | 2 |
| starter_buildings_per_region | 6 |
| starter_region_count | 3 |
| growth_compact_neighbor_weight | 10000 |
