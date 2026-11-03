# BoardWallSpace output ABI

新增 `tools/recovered_wall_mapping.py:BoardWallSpaceRecord`，按 `BoardWallSpace::new` (`0x141483d90`) 恢复 68-byte 输出布局：

- original shape payload：`+0x00..+0x1b`；
- expanded shape payload：`+0x1c..+0x37`；
- original wall length：`+0x38`；
- expanded wall length：`+0x3c`；
- remap offset：`+0x40 = 0.125`。

`board_wall_space_record` 接受已经由 `ShapeParameters::expand/as_curve2` 产生的两个 payload，因此不会猜测尚未闭合的 shape expansion 算法；该层先闭合 planner 依赖的内存布局和长度/offset 边界。

验证命令：

```powershell
python tools/verify_board_wall_space.py
```

8 项检查通过，结果写入 `evidence/reconstruction_wall_instances/verification-board-wall-space.json`。
