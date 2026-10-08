# 本地工程工具

`tests/loudness_contract.gd`使用游戏内BS.1770初始校准，与`tools/analyze_loudness.py`调用的FFmpeg输入响度/真峰值独立对照。游戏不依赖Python/FFmpeg。开发机需Python+NumPy及PATH上的FFmpeg；本机开发工具安装在Git忽略的`.git/工具依赖/响度`，安装命令：`python -m pip install --target '.git/工具依赖/响度' --no-deps imageio-ffmpeg==0.6.0`。封装包来源[PyPI](https://pypi.org/project/imageio-ffmpeg/)，FFmpeg滤镜说明见spec.audio A9。脚本读取`input_i`/`input_tp`，不把滤镜修改后的输出当原始混音。

`python tools/build_spec_data.py`从权威规格表生成`数据/spec_values.json`。生成文件须提交；`--check`拒绝规格变化后未重新生成的陈旧配置，不使用私有默认值。

`node tools/godot_mcp.mjs <requests.json>`启动独立stdio MCP客户端，项目路径固定为本工具所在工程。请求文件为`[{"name":"script_write","arguments":{...}}]`数组；它使用已安装的`@npgamedev/godot-mcp-server`，不修改Codex全局连接（该连接进入时指向audio-game）。需本工程编辑器与插件运行；本会话编辑器PID和请求暂存`.git/任务备份/2026-10-08_P0/`。

Toolkit1.0.3从用户指定本地目录复制到`addons/godot_mcp_toolkit`，保留MIT/LICENSE与ATTRIBUTIONS。它是开发工具，不是游戏机制；导出剥离由插件提供，正式构建依赖审计尚未开始。

当前机器路径：Godot`D:/GODOT/Godot_v4.7.2-stable_win64.exe`；MCP npm库`C:/Users/Administrator/.codex/tools/godot-mcp-server/node_modules/`。换机器应在工具中配置新的安装路径。
