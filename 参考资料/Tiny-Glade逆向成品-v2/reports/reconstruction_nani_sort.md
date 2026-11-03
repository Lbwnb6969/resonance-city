# Nani histogram and sorted-instance staging

新增 `tools/nani_sort_reference.py`，接上 `nani/fill_unsorted_instance_list/000.comp`、`histogram_prefix_sum/000.comp` 和 `fill_unsorted_instance_indirection/000.comp`：

- 对 cull 输出的 1024 深度桶 histogram 做 exclusive prefix；
- 按 bucket prefix 稳定写出 `instance_index * 1024 + atlas_mesh_index`；
- 累计 mesh instance counts，供 draw command 初始化和 mesh prefix 使用；
- 按 mesh prefix 把 sorted instance 还原为 instance indirection。

验证命令：

```powershell
python tools/verify_nani_sort_reference.py
```

8 项检查通过，结果写入 `evidence/reconstruction_nani/sort_reference_verification.json`。原 shader 使用 atomicAdd，GPU 同一 bucket 内的追加顺序未宣称稳定；CPU 参考按输入顺序固定输出，bucket 范围、计数和 packed 值保持一致。
