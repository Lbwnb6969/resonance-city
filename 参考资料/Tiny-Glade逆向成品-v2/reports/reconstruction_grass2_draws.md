# Grass2 CPU draw handoff

新增 `tools/grass2_draw_reference.py`，把已恢复的 `card_splats` 单卡变换接到一个确定性的 CPU handoff：先按原参考变换应用 removal/object-push/terrain/wind，再保留可见卡片，按 exemplar 稳定分组，输出标准间接绘制字段 `index_count / instance_count / first_index / vertex_offset / first_instance`。

验证命令：

```powershell
python tools/verify_grass2_draw_reference.py
```

7 项检查通过，包含两个 exemplar 分组和 removal discard。结果写入 `evidence/reconstruction_grass2/draw_reference_verification.json`。

这层闭合的是 CPU 可复现的数据交接，不宣称恢复 `card_splat_cull` 的 GPU subgroup scan、atomic/barrier 调度、深度/v-buffer 竞争或最终栅格像素；这些仍以已保存的 SPIR-V 与原生 render-graph 调度证据为准。
