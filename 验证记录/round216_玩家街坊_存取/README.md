# 玩家街坊作者记录与存取

生产入口为 `scripts/world/player_neighborhoods.gd` 与 `scripts/world/city_archive.gd`。字段合同先写入 `文档/19_城市生成管线.md` §8.2/8.5 与 `文档/01_执行规格/spec.run.md` R2b；本项没有修改 Demo、World、音频或其它设计正文。

`PlayerNeighborhoods` 提供 `reset/restore/snapshot/records/record/for_member/confirm`。作品级 `authorship` 使用 schema 1，逐栋成员为真实 `district_id`，去重排序并按可听出生帧核验，可跨内部 CID。编辑保留 ID、创建帧及当前失效的历史来源；有效成员按玩家的新选择增减。所有读取结果为深副本；恢复先完整校验，失败保留有效内存。它不写 World、动作序号、pending、随机流、声音事件或 PCM。

二进制作品保存完整 `city.authorship`；DNA 使用 `runtime.authorship` 恢复，顶层同名字段为一致的可读导出。旧档缺字段正规化为空容器；未知作者 schema、错误格式或 DNA 两份作者内容不一致时拒绝。旧作品版本和被拒绝的文件保留，latest 沿原机制查找上一完整版本。UI 集成应在确认后保存完整作品，不能等只观察 World 事件的生长检查点。

命令（只运行本项，无历史回归链）：

```powershell
& 'D:\GODOT\Godot_v4.7.2-stable_win64_console.exe' --headless --audio-driver Dummy --path . --script res://tests/round216_player_neighborhoods.gd
```

结果：`contract.json` 19/19，`dummy.log` 退出 0，无脚本/资源诊断。真实 24 栋开局选取少量跨 CID 成员，实际播种在 352800 帧出生第 25 栋；该房在可听边界之前不能新加入，出生也不自动扩张已确认记录。验证包括显式编辑、历史失效来源、返回值隔离、实际 `.city`/DNA 往返、旧档缺字段、未知 schema 拒绝及最新不支持版本的回退。所有存取样本只写本目录 `run_*`，没有访问用户作品。

选房/命名前后 512 帧同源 PCM 逐位一致，World/RNG/pending/完整音频状态不变。JSON 恢复与原模型继续的 512 帧最大绝对误差 `1.86264514923096e-9`，沿既有 `round153_audio_plan_replay.gd` 的 `1e-6` JSON 控制值量化合同；不把 JSON 恢复写成逐位相等。

初次脚本解析失败、18/19 的 JSON 逐位检查及随后误差诊断，连同对应测试/源码和当时输出保存在 `废弃/验证记录/round216_玩家街坊_存取/`。最终证据为本目录文件，历史原 JSON 未改写；归档中保存的当时运行路径是历史路径，样本实体随证据目录保留。

边界：本项只证明独立作者记录与存取。地图操作、中文命名输入、小窗布局与实际窗口由 Root 集成验证；未运行 GPU/真实设备，没有真人审美或玩法结论。自由空间边界、精确范围聆听、主题与批量调音仍未实现。
