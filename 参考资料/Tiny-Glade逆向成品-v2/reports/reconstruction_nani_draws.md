# Nani draw-list reference

新增 `tools/nani_draw_reference.py`，按 `nani/generate_draw_lists/000.comp` 的数据布局复现 merge-window 之后的 CPU 等价阶段：

- packed sorted instance 使用 `instance_index * 1024 + mesh_index` 编码；
- 每个 merge window 做 atlas entry histogram，并按 mesh entry 生成 `DrawIndexedIndirectCommand`；
- command 的 `index_count` / `first_index` 取自 atlas 元数据，`instance_count` 和 `first_instance` 与 indirection 分配一致；
- 第二遍按 mesh command 写出 instance indirection。

验证命令：

```powershell
python tools/verify_nani_draw_reference.py
```

7 项检查通过，结果写入 `evidence/reconstruction_nani/draw_reference_verification.json`。GPU workgroup/atomic 的 command 分配先后可能变化；CPU 参考固定按 window、mesh、输入顺序输出，便于复核计数、索引和 indirection 内容。
