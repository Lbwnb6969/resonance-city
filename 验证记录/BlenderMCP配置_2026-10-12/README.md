# Blender MCP 配置记录（2026-10-12）

## 采用方案

采用第三方 [MCP for Blender](https://github.com/ahujasid/mcp-for-blender)，没有同时启用官方 Blender Lab MCP。选择理由是当前项目使用 Codex 做“读取场景 → 小步修改 → 多角度检查 → Godot 对照”，社区版已有 Codex 插件、`get_scene_info`、`look` 和迭代反馈；官方方案保留为后备。两者都是可选会话桥接，批处理继续使用 Blender Python/CLI。

## 已完成配置

- Blender：`D:\SteamLibrary\steamapps\common\Blender\blender.exe`，5.2.2 LTS。
- 社区版 Blender addon：`C:\Users\Administrator\AppData\Roaming\Blender Foundation\Blender\5.2\scripts\addons\blender_mcp.py`。
- MCP Server：`C:\Users\Administrator\.local\bin\uvx.exe mcp-for-blender`。
- Codex MCP 条目：`blender`，本地端口 `9876`，工具超时 `600` 秒。
- Codex 插件：`mcp-for-blender` 2.1.1，来源 `C:\mcp-for-blender\integrations\codex`。
- 官方扩展包 `mcp` 已从 Blender 用户扩展仓库移除，避免两个服务同时监听。

## 验证

1. `codex mcp list` 显示 `blender` 为 enabled。
2. Blender 日志显示 `BlenderMCP server started on localhost:9876`。
3. `get_addon_status` 返回协议 13、addon 1.8、Blender 5.2.2，`telemetry_consent=false`。
4. `get_scene_info` 成功读取默认场景：1 相机、1 灯光、1 网格，Eevee，1920×1080。

## 日常工作流

先保存 `.blend` 工作副本；AI 先读取状态和场景，再只改一个建筑家族、材质组或公共空间。风格探索固定街坊、镜头和时间，输出 2–3 个候选；用户选定前不批量制作。每次修改后用 `look` 查看多角度结果，再导出到 Godot 检查接地、2.5D 朝向、遮挡、留白和分区可读性。接受的版本保存新文件，拒绝的版本回退或移入 `废弃/`。

## 权衡与限制

社区版提供更好的 Codex 视觉迭代，但不是 Blender 官方项目，并允许 AI 执行任意 Blender Python；连接保持在 `localhost`，不打开 Poly Haven、Sketchfab、Poly Pizza 或生成模型服务，除非之后明确启用。官方 Blender Lab MCP 更官方、更小，但不提供本项目需要的 Codex 侧工作流，因此暂不采用。
