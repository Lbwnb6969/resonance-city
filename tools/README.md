# 本地工程工具

`tests/loudness_contract.gd`使用游戏内BS.1770初始校准，与`tools/analyze_loudness.py`调用的FFmpeg输入响度/真峰值独立对照。游戏不依赖Python/FFmpeg。开发机需Python+NumPy及PATH上的FFmpeg；本机开发工具安装在Git忽略的`.git/工具依赖/响度`，安装命令：`python -m pip install --target '.git/工具依赖/响度' --no-deps imageio-ffmpeg==0.6.0`。封装包来源[PyPI](https://pypi.org/project/imageio-ffmpeg/)，FFmpeg滤镜说明见spec.audio A9。脚本读取`input_i`/`input_tp`，不把滤镜修改后的输出当原始混音。

`python tools/build_spec_data.py`从权威规格表生成`数据/spec_values.json`。生成文件须提交；`--check`拒绝规格变化后未重新生成的陈旧配置，不使用私有默认值。

`node tools/godot_mcp.mjs <requests.json>`启动独立stdio MCP客户端，项目路径固定为本工具所在工程。请求文件为`[{"name":"script_write","arguments":{...}}]`数组；它使用已安装的`@npgamedev/godot-mcp-server`，不修改Codex全局连接（该连接进入时指向audio-game）。需本工程编辑器与插件运行；本会话编辑器PID和请求暂存`.git/任务备份/2026-10-08_P0/`。

Toolkit1.0.3从用户指定本地目录复制到`addons/godot_mcp_toolkit`，保留MIT/LICENSE与ATTRIBUTIONS。它是开发工具，不是游戏机制；导出剥离由插件提供，正式构建依赖审计尚未开始。

当前机器路径：Godot`D:/GODOT/Godot_v4.7.2-stable_win64.exe`；MCP npm库`C:/Users/Administrator/.codex/tools/godot-mcp-server/node_modules/`。换机器应在工具中配置新的安装路径。


P0 City Kit烘焙：`python tools/prepare_city_bake.py`复制白名单模型/纹理并生成24槽；有画面运行Godot `--audio-driver Dummy --path . --script res://tools/city_sprite_baker.gd`，再`python tools/finalize_city_bake.py`恢复GPU索引字节、透边RGB与生成许可/接触表。原件树忽略，不作为运行时依赖。新PNG首次导入后，将资源/P0城市/整图下所有PNG导入设置mipmaps/generate=true，editor_refresh后用asset_contract baked_sprite证明实际ctex含mips。候选人工观感待审，不自动获批。


导出依赖审计：关闭本Agent临时MCP helper后运行Godot `--headless --path . --export-pack "P0依赖审计" .git/任务备份/2026-10-08_续作/P0依赖审计.zip`。然后`python tools/audit_export_zip.py <ZIP>`。空隔离目录挂载该ZIP，`--headless --path <空目录> --main-pack <绝对ZIP> --script <绝对tests/export_contract.gd> -- --result=<绝对结果JSON>`，26项实际资源/场景合约。出口成功不代表依赖完整，必须读取引擎错误日志和隔离结果。此preset为技术候选资源包审计；人工艺术与正式导出模板/EXE另验。

### 灰态声音（AUDIO-005）

`tests/mix_contract.gd -- --case signal_protection` 对照改前float32 PCM，验证诊断保护、灰态边界、进退/快照和补偿下mute；`tests/live_audio_contract.gd -- --case gray_stress` 必须用实际WASAPI，验证九声部九辅助供音。`tests/gray_baseline_probe.gd` 是改前基线捕获脚本，已有基线时拒绝覆盖，不能用新代码重造旧证据。

`tests/gray_listening_probe.gd` 生成同一初始gain的8秒九声部normal/gray PCM；`python tools/analyze_gray_audio.py` 独立测截止以上能量、降采样镜像与整城FFmpeg响度/真峰值，并生成未再归一化WAV。人工听评说明在`验证记录/P0/声音褪色/说明.md`。此技术PASS不等于作品听感或诊断遮蔽已获批准。

风格小景：`python tools/prepare_style_frame.py`从保留Demo/P0索引加工独立7件副本，读取明确SELECTED/manifest，不覆盖Demo manifest。PNG导入保持mipmaps/generate=true；`scenes/style_frame.tscn -- --capture-style-frame`用实际Compatibility生成有/无网格及推近图，当前只作候选艺术审阅。

历史SVG：`python tools/build_classical_svg.py`生成四件项目原创、可编辑SVG与独立manifest；依赖现有风格小景manifest中的两件树。运行图在资源/古典建筑候选，生产副本资产/03_入库/古典建筑候选；通过项目MCP刷新，SVG导入mipmaps/generate=true。`scenes/style_frame.tscn -- --classical-frame --capture-style-frame`实际GPU截图；不覆盖Demo或风格小景图片。
