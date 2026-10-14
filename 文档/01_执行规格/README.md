# 执行规格

只写能指导实现的输入、输出、边界和验证。玩法解释在 00/10–19；实际代码进度见 [PROJECT](../../PROJECT.md)。

| 文件 | 职责 |
|---|---|
| [space](spec.space.md) | 双层坐标、身份、空间查询 |
| [fabric](spec.fabric.md) | 墙格、房屋块/露台、连接语法 |
| [city](spec.city.md) | 连续道路、特殊建筑、功能区与服务 |
| [terrain](spec.terrain.md) | 高程、水体、地形编辑与植被 |
| [proposal](spec.proposal.md) | Intent、预览、提交与撤销 |
| [audio](spec.audio.md) | 视野声音、区域连接、混音和 PCM |
| [harmony](spec.harmony.md) | 音乐协调与旧声学参数兼容 |
| [run](spec.run.md) | 作品、存档、时代、能力与模式 |
| [ui](spec.ui.md) | 输入、镜头、反馈与可访问性 |
| [asset](spec.asset.md) | 模块、风格、资产生产与优化 |

各 spec 的兼容参数只是 `tools/build_spec_data.py` 当前读取的数值源，不代表新玩法恢复旧 R/V、额度或音程门槛。迁移代码时可显式更新参数与测试；单纯整理文字不得悄悄改运行数据。完整旧合同见 [原稿说明](../../废弃/文档/2026-10-14_综合优化前/README.md)。
