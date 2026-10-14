# 给设计与实现 AI 的入口

先读 [PROJECT](PROJECT.md)，再读 [AGENTS](AGENTS.md)。PROJECT 是当前状态，文档是目标规格；验证记录证明其限定范围内的行为，不代表全目标完成。

## 阅读顺序

1. [设计意图](文档/00_设计意图.md)、[核心循环](文档/11_核心循环.md)、[声音](文档/12_声音架构.md)、[地形与自然](文档/13_地形与自然.md)、[美术](文档/17_美术规格.md)。
2. [新城实现边界](文档/21_新城创作切片.md)、[迁移接口](文档/20_开发接口与迁移.md)、[需求覆盖](文档/需求与旧稿覆盖.md)。完整连读可用 [文档合并稿](文档/共鸣之城_文档合并精简版.md)。
3. [参考索引](文档/参考索引.md)，按本次实际问题读三库资料：Tiny Glade 的墙/屋顶/资源/Grass2；Foundation 的建筑用途/需求/行为图；Townscaper 的邻接生成/拓扑/历史。
4. 实现入口：`scenes/city_creation.tscn` → `scripts/ui/city_creation_demo.gd`。真值 `scripts/world/city_creation_state.gd`；生活 `scripts/world/city_creation_life.gd`；音乐 `scripts/audio/city_creation_music.gd`；表现 `scripts/visual/city_creation_renderer.gd`。

## 三个研究库

- [Tiny Glade](参考资料/Tiny-Glade逆向成品-v2/README.md)：优先用于美术、自然、道路自由意图与接合；[Grass2](参考资料/Tiny-Glade逆向成品-v2/reports/reconstruction_grass2.md) 与 [资源语义](参考资料/Tiny-Glade逆向成品-v2/reports/reconstruction_resources.md)。
- [Foundation](参考资料/Foundation逆向成品-2026-10-13/DELIVERY_INDEX.md)：[玩法语义](参考资料/Foundation逆向成品-2026-10-13/outputs/foundation-game-systems/SEMANTIC_GUIDE.md)、建筑功能与真实抵达/驻留/完成需要。
- [Townscaper](参考资料/Townscaper逆向成品/README.md)：[完整调查入口](参考资料/Townscaper逆向成品/outputs/townscaper_complete_index.md)、[生成](参考资料/Townscaper逆向成品/outputs/townscaper_generation.md)、[历史](参考资料/Townscaper逆向成品/outputs/townscaper_state_save_history.md)。

没有入库的本地大文件见 [发布清单](AI资料/参考资料发布清单.json) 的 `local_only`。报告里的绝对安装路径是证据来源，不是克隆者必须安装的位置。不要为了读一个机制先全量解码资源或运行原游戏。

## 工作要求

优先完整、好玩、好看、好听的试玩，允许自主重构。Tiny Glade 美术与道路手感是明确要求，草地还未达到目标；房屋及社区/功能区必须参与音乐，融合和正反馈优先于发声数量。公共演出周边房屋应答/互动，音乐不成为建造资格。

保留 Git 备份和玩家作品；重要废弃内容移入 `废弃/`。验证选择最小充分范围，记录结果与剩余不确定性；只有下一位 AI 的行为需要改变时更新PROJECT。默认 Godot fixture 在初始化前关闭个人存档读写。
