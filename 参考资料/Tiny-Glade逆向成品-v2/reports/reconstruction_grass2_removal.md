# Grass2 removal mask and active dispatch

新增 `tools/grass2_removal_reference.py`，按 `grass2/combine_grass_removal/000.comp` 和 `grass2/active_cull_dispatch_args/000.comp` 复现：

- path mask smoothstep、water/rocky/foliage exclusion 门控；
- building/garden 3×3 邻域最大值；
- RG8 removal/opacity 两个输出通道；
- active count 按 group size 的 indirect dispatch `(ceil(active/group), 1, 1)`。

验证命令：

```powershell
python tools/verify_grass2_removal_reference.py
```

8 项检查通过，结果写入 `evidence/reconstruction_grass2/removal_reference_verification.json`。该层闭合 removal mask 的确定性输入，card-splats 的 GPU 深度/visibility 原子竞争仍由原 shader 约束。
