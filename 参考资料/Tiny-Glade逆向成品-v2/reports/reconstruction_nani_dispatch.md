# Nani indirect dispatch arguments

新增 `tools/nani_dispatch_reference.py`，按 `nani/generate_dispatch_args/000.comp` 和 `nani/draw_indexed_indirect_to_dispatch/000.comp` 复现：

- filtered-instance、merge-window、1024-entry prefix 三组 dispatch X 维度；
- `count >= merge_window * 2048` 的 two-pass 开关；
- 从 DrawIndexedIndirect 的 `instanceCount` 和 group size 生成 dispatch `(ceil(instanceCount/groupSize), 1, 1, instanceCount)`。

验证命令：

```powershell
python tools/verify_nani_dispatch_reference.py
```

8 项检查通过，结果写入 `evidence/reconstruction_nani/dispatch_reference_verification.json`。
