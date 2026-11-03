# Grass2 build-draws sampling reference

新增 `tools/grass2_sampling_reference.py`，按 `grass2/build_draws/000.comp` 的常量和整数运算复现：

- 32-bit bit reverse 与 130/190 世界域低差异采样点；
- 512² plant sample texel 映射；
- water sample 的 seaweed exemplar 选择；
- land sample 的四通道 run-length 分组、theme=4 零植被门控和 packed `clump_attrib`；
- terrain 高度比例公式；
- 大世界 57344+ sample 的 65-unit 内方形 / 30-unit 外圈门控、边缘正弦位移、路径概率剔除、水面高度剔除、theme=4 稀疏门和 exemplar 选择。

验证命令：

```powershell
python tools/verify_grass2_sampling_reference.py
```

15 项检查通过，结果写入 `evidence/reconstruction_grass2/sampling_reference_verification.json`。

`large_world_gate` 返回所有中间量（边界距离、位移点、路径 UV/阈值、各剔除原因、exemplar 和 packed 属性），可以直接接入纹理采样器。此层复现的是 build-draws 的确定性输入/分组阶段；GPU atomic、workgroup barrier、活跃列表竞争和最终栅格解析仍由原 SPIR-V/原生调度证据约束。
