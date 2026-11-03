# Nani cull-and-bucket reference

新增 `tools/nani_cull_reference.py`，按 `nani/cull_and_bucket/000.comp` 复现：

- 16-byte packed instance 的 float3 位置、低半精度 radius scale 和高 16-bit atlas mesh index 解码；
- 从 `view_to_clip` 构造 shader 使用的四个归一化侧面平面，以及 `(-view_z + radius) > view_to_clip[2].w` 深度门；
- 1024 深度桶：`clamp((32 - view_z) / 288 * 1024, 0, 1023)`；
- 上一帧 visibility bitmask → 当前帧 bitmask、filtered instance (`local_index * 1024 + bucket`)、mesh meta 和 draw-list histogram。

验证命令：

```powershell
python tools/verify_nani_cull_reference.py
```

9 项检查通过，结果写入 `evidence/reconstruction_nani/cull_reference_verification.json`。GPU `atomicOr` / `atomicAdd` 的并发追加顺序不被宣称为稳定；CPU 参考按 local index 顺序输出，计数、bitmask 和桶归属保持确定。
