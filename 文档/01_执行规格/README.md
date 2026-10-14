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
| [harmony](spec.harmony.md) | 风格协调、调性/节拍适配与素材角色 |
| [run](spec.run.md) | 作品、存档、时代、能力与模式 |
| [ui](spec.ui.md) | 输入、镜头、反馈与可访问性 |
| [asset](spec.asset.md) | 模块、风格、资产生产与优化 |

详细对象字段、时钟/来源、公共空间和存档合同见 [开发接口与迁移](../20_开发接口与迁移.md)。旧数值解析输入独立在 [数据/兼容规格](../../数据/兼容规格/README.md)，保留当前运行值，不参与新玩法判定。每个 spec 的目标行为还需对应代码实现，完成状态只取 PROJECT。
