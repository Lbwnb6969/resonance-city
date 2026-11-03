# Nani end-to-end CPU pipeline

新增 `tools/nani_pipeline_reference.py`，把已恢复的 Nani 阶段串联：

`cull_and_bucket` → 1024 bucket histogram exclusive prefix → `fill_unsorted_instance_list` → merge-window `generate_draw_lists`。

验证命令：

```powershell
python tools/verify_nani_pipeline_reference.py
```

8 项检查通过，结果写入 `evidence/reconstruction_nani/pipeline_reference_verification.json`。该链验证 packed instance、visibility、bucket、mesh metadata、间接绘制命令和 instance indirection 的数据一致性；GPU atomic 竞争顺序和真实 command dispatch 时序仍由原 shader/原生调度约束。
