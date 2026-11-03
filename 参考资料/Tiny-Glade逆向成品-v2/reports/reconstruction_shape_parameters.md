# ShapeParameters expansion and curve dispatch

新增 `tools/recovered_wall_mapping.py:expand_shape_parameters`，按原生 `0x140a85120` 恢复：

- 复制 28-byte shape payload；
- tag `1` rectangle：`+0x14` 与 `+0x18` 各增加 `2 * offset`；
- 其他 shape：`+0x0c` 增加 `offset`；
- `shape_curve_kind` 对齐 `0x140a85190` 的 rectangle/circle dispatch；circle 曲线容差常量已从原 RIP 数据确认是 `0.2`；`circle_sample_count` 对齐 `ceil(radius * 2π / 0.2)` 并保留至少 3 个采样点，`circle_sample_points` 给出对应低层点域；`rectangle_curve2_reference` 生成 4 个角点加闭合第 5 点；`curve2_from_points` 按 `Curve::try_new_from_points` 原生路径累计二维弧长并归一化 `u_values`。

验证命令：

```powershell
python tools/verify_shape_parameters.py
```

16 项检查通过，结果写入 `evidence/reconstruction_wall_instances/verification-shape-parameters.json`。Rectangle2d/Circle2d 的低层点域和 Curve2 弧长缓存已恢复；Curve2 容器的 Rust 分配/错误路径仍保留原生证据，不猜测其内部所有元字段。
