# Round 215 · 玩家房屋的古典联合屋顶

## 目的

本切片把“社区”从固定行政标签退到后台：玩家看到的是实际房屋沿同一条道路贴合后形成的连续古典屋顶体块。联合体是从已听见的建筑几何派生的表现缓存，不创建新的建筑、社区、音级或存档对象。

## 现行规则来源

- `文档/01_执行规格/spec.fabric.md` FB2：共享山墙净间隙 ≤0.10，连排按同一街面且最多 6 栋；身份、音级、阶段、Solo/Mute 仍逐栋独立。
- `文档/17_美术规格.md` §3.0：用檐口线融合、山墙贴片或顶面合并表现联合体；不旋转贴图，不把房子切成一个实体。
- `文档/14_城市生长.md` §2.3：自动生长产生的真实共享山墙/连排只改外观。

## 实现范围

`scripts/visual/joined_classical_roofs.gd` 提供 `setup(owner)` / `sync(owner)`。它读取 Demo 的 `shown_world`、`building_geometry`、`sprites`、可听帧和 `fabric_cache.shared_walls`：

1. 只取第一时代、已出生且已完成显示的住宅/商业建筑；公共文化馆永不进入联合。
2. 对真实 `shared_walls` 再检查同一真实道路 `road_id:side`、四向朝向相同、道路/水体没有穿过接缝。
3. 按同一实际道路的弧长排序，真实相邻关系组成 2–6 栋一段；不使用同 CID 全并，也不使用旧 `rows` 的 ID 排序。
4. 在两屋外翼与窄缝处绘制跟随真实地形高度的宽屋顶连接体、两条连续檐口和低对比瓦脊，并按两屋较近的地脚深度排序。原 Sprite 继续独立命中、独立音级与独立屋型。
5. 相机平移/缩放只由父层变换处理；World、RNG、pending、音频和存档不写入。

## 最小验收

`tests/round215_joined_classical_roofs.gd` 使用真实 `build_first_composition_starter()`，Dummy/headless 验证真实首作成员、共享墙候选、同路同侧/朝向过滤、公共馆排除、2–6 段上限、未来出生过滤、道路/水体接缝过滤、相机复用和 World 快照不变。它只证明结构与几何合同，不能代替 Root 的 NVIDIA 实窗审图，也不等于真人“好看”结论。

## 已知限制

这是第一段可玩的联合表现：目前只做宽屋顶连接体与连续檐口，不做离线整排顶面烘焙或新山墙贴片；共享关系缓存仍由 World 全量刷新提供，后续大城再按脏区优化。商铺的生产 manifest 没有独立 `roof_half_extents`，脚本按原商铺几何的屋顶高度和实际 Sprite 的模型缩放计算连接高度；若实窗发现遮挡 taberna 招牌，保留原资产并调连接体高度/宽度，不改 World 关系。

## 当前验证

命令：`D:/GODOT/Godot_v4.7.2-stable_win64_console.exe --headless --audio-driver Dummy --path . --script res://tests/round215_joined_classical_roofs.gd`

最终结果：17/17，退出 0；原日志 `dummy.log` 与结构/几何数据 `roof_contract.json`。真实 24 栋首作产生 7 个 2–4 栋段、15 个外翼连接体；受控 7 栋链只连接前 6 栋并留下最后接缝，不把旧 CID 或建筑 ID 排序当作形态关系。

两个中间失败保留：`首版受控夹具数组类型/` 是 test roads Array 类型错误，`缓存水体签名API修正前/` 是 PackedVector2Array.hash API 错误；均已纠正后运行以上最终合同。保留失败源码/日志，不重写为通过。Root 最终可把这两份中间记录移动到项目统一废弃入口。

本轮未启动 GPU 游戏或真实音频设备，没有截图美术结论或真人体验结论。Root 负责接入当前 Demo 后实窗检查连续体块、屋内庭院净空、taberna 门面与遮挡排序。