# Blender 直接调用验证

2026-10-12，独立 factory-startup 后台进程，未操作用户打开的 Blender 会话、修改项目资产或安装 MCP。

命令（PowerShell，从项目根执行）：

```powershell
& "D:\SteamLibrary\steamapps\common\Blender\blender.exe" --background --factory-startup --python-exit-code 1 --python "D:\GODOT\GODOTPRO\共鸣之城\验证记录\Blender直接调用_2026-10-12\probe.py"
```

结果：退出码0，`BLENDER_CLI_PROBE PASS 5.2.2 LTS`；构建 `d13f752e3b9c`。修改出厂 Cube 的尺寸、创建材质，保存 probe.blend，导出选中物体 GLB，Cycles CPU 1 sample 渲染64×64 PNG。文件大小/SHA256和范围见 [result.json](result.json)，可复现脚本见 [probe.py](probe.py)。这些是工具连通性证据，不是正式建筑、Geometry Nodes 完整管线或风格签核。

[Blender 命令行官方参数](https://docs.blender.org/manual/en/5.2/advanced/command_line/arguments.html)支持后台 Python；[Blender Lab MCP](https://www.blender.org/lab/mcp-server/)另需插件、服务与客户端。仓库仅通过 git ls-remote 核对HEAD，本次未 clone 或配置 MCP。
