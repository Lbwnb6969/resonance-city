# 规划键盘最小合同

当前结果：19/19，exit 0。Godot 4.7.2 的 headless / Dummy，实际生产 Guide、World、章程与公共空间提交接口；原生焦点和 Input.parse_input_event 输入。没有开启 GPU 或声音设备。

入口：`Godot_v4.7.2-stable_win64_console.exe --headless --path . --audio-driver Dummy --script tests/round213_planning_keyboard.gd`。结果见 `keyboard_contract.json`，原始输出见 `keyboard_after_types.log`。

Tab 在可见规划工具中移动原生焦点，不提交城市独听；自由分块的 Tab 收束仍走原路径。Enter 选择当前章程/变化卡、确认真实社区范围和实际指针公园；未选社区不提交。Space 在章程/变化卡不误选，在公共步骤只请求一次比较，包含按键重复，不二次激活聚焦按钮。实际队列保留选中的变化卡引用，公园只排入一次。

测试使用继承生产 Demo 的最小输入适配器；公共试听方法仅计数，未在此渲染 PCM。Root 已把同一桥接入生产 Demo，并负责完整实窗 / WASAPI 规划链与真实声音验证。本合同不构成真人可用性或喜好结论。

首次依赖编译失败保存在 `../../废弃/验证记录/round213_规划键盘/首次夹具编译/`。审查误用旧 141 入口的本次输出保存在 `../../废弃/验证记录/round213_规划审查/旧141入口失败/`，它覆盖的五份历史记录已逐字节恢复 Git HEAD。
