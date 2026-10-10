# Round151 真实 WASAPI 公共规划比较

命令：

`D:\GODOT\Godot_v4.7.2-stable_win64_console.exe --path . --script tests/round143_public_comparison.gd`

结果：`PUBLIC_COMPARISON PASS checks=35`。本次运行使用生产 `ContinuousValleyDemo`、三分支 3 秒 PCM 和正常成长边界；JSON 的 `live` 字段记录 `driver=WASAPI`、`skips=0`、`phrase=3`、`max_voices=18`。`不建.wav`、`公园.wav`、`文化馆.wav` 来自同一捕获快照；三分支仍需真人盲听确认审美差异。

测试夹具在 worker 等待期间固定地图指针，避免桌面鼠标漂移被生产逻辑正确判定为“已移到另一空地”。
