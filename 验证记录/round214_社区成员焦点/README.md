# 第214轮：真实社区成员占地焦点

生产代码：`scripts/visual/community_member_focus.gd`。Node2D 由 Demo 调用 `setup(self)`，在社区工作台更新后调用 `sync()`；由 Demo 设置 `z_index=21`。仅在工作台打开且不是黑屏时绘制。工作台状态使用 `id/member_ids`，可听帧使用真实 `clock.renderer.transport.audible_frame`。

只画已听见、实际属于当前社区的建筑占地，不虚构整片边界，不画未来建筑。本阶段没有公共设施或留地轮廓。轮廓为暖石底线和松绿细线，无面填充；镜头变换直接作用于保留的投影，线宽维持固定屏幕像素。缓存仅复制成员位置、占地与投影等值，不保留 World 引用。成员/地形不变时，不重新调用建筑占地或地形查询。

验证命令：

```powershell
& 'D:\GODOT\Godot_v4.7.2-stable_win64_console.exe' --headless --audio-driver Dummy --path . --script res://tests/round214_community_focus.gd --check-only
& 'D:\GODOT\Godot_v4.7.2-stable_win64_console.exe' --headless --audio-driver Dummy --path . --script res://tests/round214_community_focus.gd
```

类型检查退出0；最小独立合同16/16，退出0。使用真实 ContinuousWorld 首片开局、独立可写 World 与恢复分叉，UI/设备时钟由小 Dummy 壳提供，未加载 Demo。覆盖真实占地及地形投影、实际成员唯一归属、未来出生门控、相机不重建几何、等值分叉复用与地形变更失效、三个 World 的状态/RNG/pending只读、社区切换和黑屏/关闭/空社区清理。

首次类型检查失败：常量名 `Projection` 与 Godot 内建类型冲突；改为 `IsoProjection`。原日志保留在 `initial_parse.log`。首次合同15/16：夹具错误要求恢复 World 后占地查询计数为0，而恢复本身会派生占地；改为恢复后的计数基线。原15/16 JSON和日志保留在 `first_contract_fixture_queries.*`，生产helper未为此修改逻辑。最终证据为 `focus_contract.json` 和 `focus_contract.log`。

这些独立证据证明只读规则、投影和缓存行为。Root以z_index=21集成，唯一生产实窗中的成员占地边线和工作台已另行审图，见相邻`round214_社区工作台/README.md`。本独立合同没有GPU、设备PCM、真人审美或乐趣结论。
