# 地形与植被执行规格

输入：连续地形、修改范围、水路径、植被密度/风格与种子。输出：高程/水岸差量、植被意图/实例、占地依赖变化。

树群、草石避让真实道路、房屋入口、公共净空和留地。同次编辑重做恢复同分布；镜头改变不改变已保存自然意图。地形编辑可撤销，覆盖作品需明确替换范围。

现有河谷可直接使用；通用水文可保留填洼父图、流量累积和河宽采样。开局按可建空间和视觉判断，不依赖初始 R 分数。

验证影响范围、净空、重复种子、保存恢复和局部重建；风、水与昼夜不修改建筑拓扑。

完整旧参数、公式和合约 ID 见 [迁移前 spec.terrain](../../废弃/文档/2026-10-14_综合优化前/文档/01_执行规格/spec.terrain.md)。

## 现有实现兼容参数

以下表仅用于复现当前代码/生成配置。保留数值不恢复旧玩法语义；新建造不受这些音乐/额度/自动生长参数限制。

## 表 T6 · 首片河谷与采样配置

| 键 | 值 |
|---|---|
| noise_octaves | 4 |
| noise_gain | 0.5 |
| noise_lacunarity | 2.0 |
| noise_frequency | 0.065 |
| minimum_buildable_ratio | 0.45 |
| attempt_limit | 8 |
| template_land_min | -4 |
| template_land_max | 36 |
| template_river_center | 16 |
| template_river_base_half_width | 1.05 |
| template_river_widening | 0.025 |
| template_road_bank_offset | 3.6 |
| template_road_half_width | 0.25 |
| template_lot_road_offset | 1.2 |
| template_lot_half_width | 0.62 |
| template_lot_half_length | 0.64 |
| template_lot_spacing | 1.6 |
| template_bridge_y | 14 |
| template_slice_building_budget | 24 |
| template_building_max_grade | 0.577350269 |
| template_shore_buffer_ratio | 0.12 |
