# 第118轮优化前的全扫描实现

来源：Git `6affd27`，保留 `continuous_world.gd`、`fabric_relations.gd`、`city_road_network.gd`、`valley_terrain.gd` 的优化前行为。只移除全局类名，并把内部预加载和路网类型指向本目录，避免与正式类冲突。

替代实现：`scripts/world/` 对应文件。保留价值：`tests/round118_geometry_equivalence.gd` 用旧全扫描结果核对五种地形的落点、三句成长、公共容量、音乐规则和快照；不作为正式运行入口。无未吸收设计内容。已知旧实现建桥后到本句末才刷新物理路网，该缺陷由正式实现修复，不作为等价比较的基线。
