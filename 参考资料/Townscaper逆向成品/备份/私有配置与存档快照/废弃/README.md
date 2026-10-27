# 废弃文件夹

Steam 原始文件保持原样。淘汰的工作区产物先移动到此目录，已有重要交付物保留 Git 历史。

- `ghidra_incomplete_20261013/`：不完整的工具下载，保留在磁盘，不纳入 Git。
- `rea_timeout_20261013/`：REA 默认330秒时限下的失败记录和空 Evidence bundle，不作为成功分析交付。
- `ida-license-before-*.log`：IDA 首次许可确认及许可证命名修正前的日志。
- `ida-free-unsupported-script-smoke.idc`：Free版不支持 `-S`，未执行成功的脚本探针。
- `ida-mcp.template.json`：此前误用于Free版的headless provider模板；Free没有IDAPython/IDAlib，不能启用此配置。

配置与许可证副本备份分别保存在 `work/tools/config-backups/`、`work/tools/license-backups/`，后者不纳入 Git。
