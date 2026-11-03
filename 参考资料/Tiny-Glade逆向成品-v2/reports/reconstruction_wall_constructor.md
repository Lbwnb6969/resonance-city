# Tiny Glade 墙构造提交桥接层

本轮在已验证的 planner、world cut 映射和 stage-3 SSBO 发射之间补了一层可复现的构造提交接口：`tools/recovered_wall_instances.py:assemble_wall_construction`。

接口接收 planner 的 `Piece` 序列和已映射的 wall-space `WallCut`，由 `WindowCutLists.list_for_piece` 按原生线性 AABB 筛选逻辑为每个板片返回稳定 cut 索引；新增 `native_result_for_piece` 进一步按 `0x1424bd0e0` 恢复内部输出 vector、`EAX=pack_window_cut_list(base+old_len,count)`、`EDX=count`、非空列表 hash-state 更新和 call counter。`pack_window_cut_list` 已按 `0x140a78260` 的原始 43 字节代码实现：空列表或 base 超过 24 位返回 0，否则为 `min(count,255)<<24 | base`。弯墙路径直接调用已经逐位核对的 `emit_curved_horizontal_wall_board_piece`，并通过独立的 `curved_with_seed`、`curved_with_flags`、`curved_with_window_cut_list` 写入原生已知偏移；直墙/gable 新增原始偏移 packer，覆盖 80/96 字节构造器写入的标量、向量、flags、window-list 和尾部字段，默认布局由同一 packer 生成；可选的 merlon 区间调用已核对的 `top_rim_merlon_ranges`。输入被转为 f32 并保持排序/索引稳定，重复提交得到相同记录。

这层闭合的是“规划结果如何进入一次实例提交”的数据边界。新增 `fastrand_f32` 和 `wooden_plank_random_fields`，按 `0x140e02880` 及 `0x14144ad01..0x14144ad37` 恢复每个板片的三个 seed 公式、`.2/.03/.32/.05` 变换和宽度调整值；新增 `WoodenPlankRecord` / `WoodenGablePlankRecord`、shader flag 解码、`(gate_seed + piece_seed) + 45` / `(seed + 45)` shader seed、两个 UV jitter hash 和 gable 高度重映射/skew，字段语义与 `nani_wooden_*` vertex shader 逐项对齐。原生材质选择、随机值到直墙字段的完整路由仍未知，结果对象通过 `unknowns` 明确保留这一边界。该接口没有启动游戏，也没有修改安装目录。

直墙/gable 默认函数的原始 54/65 字节机器码也保存在 `evidence/reconstruction_wall_instances/0x140a77410.*` 与 `0x140a77450.*`；packers 的默认输出与这些常量写入逐字段一致。

验证命令：

```powershell
python tools/verify_wall_constructor_bridge.py
```

结果写入 `evidence/reconstruction_wall_instances/verification-constructor-bridge.json`：Tiny Glade EXE SHA-256 匹配，50 项检查通过；证据同时保存每次窗口列表调用的 indices、packed、count、旧输出长度、hash state 和 call counter。覆盖直接/平移 AABB 筛选、原生窗口列表返回 ABI 和状态更新、窗口列表打包边界、结构化 80/96 字节记录往返、shader flags/seed/jitter、gable 高度 remap/skew、三个原生 helper 字段偏移、直墙/gable 原始字段 packer、两个弯墙板片各绑定一个窗口 cut、2 段 merlon、以及随机 seed/变换。该证据证明桥接层的确定性和已知布局，不证明整墙画面或原生材质选择等价。
