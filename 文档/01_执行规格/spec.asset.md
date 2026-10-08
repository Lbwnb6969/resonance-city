# 资产、许可与加工执行规格

> 2026-10-08 · 已购转售包禁入库，只有白名单中的许可证据可用于成品。本次只写规格，未下载新素材或安装工具。

## 表 S1 · 人类评审来源表（原样保留）

| 级别 | 来源 | 内容 | 许可 | 用途 |
|---|---|---|---|---|
| **L1** | Kenney City Kit 系列（Roads / Commercial / Industrial / Suburban）<br>`kenney.nl/assets/city-kit-suburban` `.../city-kit-commercial` `.../city-kit-industrial` `.../city-kit-roads` | 低模建筑/道路/围栏/树 40+ 件/包，模块化，纯色，OBJ/FBX/GLTF | **CC0**（可商用、无需署名） | 建筑/道路/植被主力。2025-04 整包重做 |
| **L1** | Kenney Audio（interface-sounds 等） | UI 音、小采样 | **CC0** | UI 反馈音 |
| **L1** | **VCSL**（Versilian Community Sample Library）`github.com/sgossner/VCSL` | 木管/弦乐/键盘/打击真实采样，44.1kHz WAV | **CC0** | 声部音色取样底库（替代纯合成） |
| **L1** | **VSCO 2 Community Edition** `versilian-studios.com/vsco-community` | 管弦采样集 | **CC0** | 同上 |
| L2 | itch.io CC0 × isometric 标签、OpenGameArt（筛 CC0）、openclipart | 2D 等距零件/图标 | CC0 / CC-BY | 补缺口；CC-BY 需在 `资产/授权登记.md` 记署名 |
| L3 | AI 生成 | 仅限概念图、UI 图标、图鉴剪影 | — | 必须过色板收编后才可入库 |

事实适用说明：表 S1 中“40+件/包”“2025-04整包重做”“全部44.1kHz”不得替代实际包证据。官网当前 Suburban 2.0/40件、Commercial 2.1/50件、Industrial 2.0/40件、Roads 2.1/90件；CC0已核实，四包尚未下载，具体格式/采样率须看下载包。版本和授权登记见 `../../资产/授权登记.md`；调研链接见 `../事实核查-2026-10-08.md`。

## 表 S2 · 环境缺口（原样保留）

| 工具 | 用途 | 安装 | 验证命令 |
|---|---|---|---|
| **Ghostscript** | **EPS 解析（Inkscape 的硬依赖）** | `winget install ArtifexSoftware.GhostScript` | `gswin64c --version` |
| Inkscape | 矢量格式转换、拆件 | `winget install Inkscape.Inkscape` | `inkscape --version` |
| ImageMagick | PNG 批处理、晕边检查 | `winget install ImageMagick.ImageMagick` | `magick -version` |
| （若走 §1.3 离屏渲染）Blender | 低模 → 等距 PNG | `winget install BlenderFoundation.Blender` | `blender --version` |

Ghostscript是EPS导入依赖，不是CC0低模生产线的前置依赖。禁止因此重新启动已购EPS加工线。上述安装命令来自评审，winget包ID须在安装时核实；本轮未安装。前三条工具bin加入PATH后分别验证，选用Blender则增加第四条输出。Godot离线工具与Blender二选一；不要求两个都装。

## 表 S3 · 离线到运行时

| 阶段 | 规则 / 输出 |
|---|---|
| 原始 | `资产/01_原始素材/`只读；已购实际位于`资产/2.5D素材/`，仅参考，不迁移巨量原件 |
| 加工 | CC0副本在`资产/02_加工中/`离线模块组合 |
| 预览 | 相机方位45°、俯仰30°，unshaded，中性灰，PNG长边512px；`资产/04_预览索引/` |
| 主图 | 每建筑1张整图；按原质量红线长边≥2048px；颜色槽位/LUT编码待U11裁定 |
| 审核库 | `资产/03_入库/`，含manifest、来源、许可副本；不作为运行时res入口 |
| 运行时 | 审核后只部署获批成品到`资源/`，此目录在`资产/`之外；生成器只读manifest |
| 导入隔离 | P0创建`资产/.gdignore`；整棵资产树不参与Godot导入，不能让运行时从被忽略目录load() |
| 全城窗光 | 单独统一全屏additive层；不是每栋建筑叠加6个节点 |

## 表 S4 · P0选件与色板

| 项 | 数量 |
|---|---|
| 住宅 / 商业 / 工业 | 各3 |
| 地面 / 道路 / 树 / 装饰 | 2 / 3 / 2 / 4 |
| 基础色板 | 1张，24色；P0不做16张 |

总数为21件，评审的“约20件”保留为量级，不删其中1件凑整数。

## 表 S5 · manifest文档接口

| 字段 | 要求 |
|---|---|
| id / category / variant | 命名`{类别}_{子类}_{序号}_{变体}`；稳定唯一ID |
| texture / palette_slots | 单张整图引用与LUT槽位；中性灰须可区分槽位，编码见U11 |
| footprint_tiles / floor_height / origin | 占地、层高、底部中心基准 |
| voice_tag | residential/commercial/industrial；非街区件明确标为非声部 |
| source_url / package_version / downloaded_at | 实际来源、版本与下载日期，禁止假填已下载 |
| license / license_file / attribution | 可再查的许可与署名证据；已购不允许获批记录 |

### [ASSET-001] 来源白名单与禁止转售包

状态：已裁定。

意图：防止无商用许可素材进入任何构建。

规则：`资产/2.5D素材/`及其工作副本仅作画风参考，不得入库/打包。声明放`资产/01_原始素材/已购素材/README.md`，说明该目录是声明入口、原件未搬。CC0主粮逐包登记；CC-BY逐件记录署名；L3仅概念/UI/剪影并经收编，不允许AI直接整城生成。

数据：表 S1、S5；授权登记与禁入库声明。

验收：DOD ASSET-001：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/asset_contract.gd -- --case license`；未来构建依赖清单必须排除转售原件及派生图。

反例：不得把已购等同商用授权；不重新做744EPS的生产盘点；未下载包不得写“已入库”。

### [ASSET-002] 低模离屏与整图烘焙

状态：部分待裁定U11。

意图：使CC0低模成为可换色的2.5D词汇。

规则：取CC0 OBJ/GLTF，离线固定45°/30°相机→unshaded中性灰→512px预览→离线模块组合→高清主图+manifest。Blender仅是管线工具，不是运行时依赖；或用可CLI批处理的Godot离线场景。每建筑1精灵；mask生长在shader内，窗光统一层。

数据：表 S3、S4、S5；UI-004性能预算。

验收：DOD ASSET-002：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/asset_contract.gd -- --case baked_sprite`；索引逐件记录文件名/包/分类/包围盒/评级；三格测试。

反例：不能把512px预览当≥2048px主图；不能把离线六模块变成运行时六个节点；全灰抹掉槽位信息不算通过。

### [ASSET-003] 生产目录与运行时导入隔离

状态：已裁定。

意图：避免原始3.15GB素材被Godot导入，又保证成品可load。

规则：P0加资产/.gdignore，随后只把获批成品部署到资源/；两份manifest内容一致，生成器以运行时manifest为输入。授权登记与许可证在生产库留证，构建只引用白名单成品。

数据：表 S3、S5；P0任务0。

验收：DOD ASSET-003：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/asset_contract.gd -- --case import_scope`；Godot编辑器启动时不得生成原始jpg/eps导入记录，成品资源须可load。

反例：资产/.gdignore是Godot导入规则，不是Git忽略规则；不能说已创建而实际仍未创建；不能在其下放运行时依赖。

### [ASSET-004] 质量红线与只读来源

状态：已裁定。

意图：让批量生产保持风格与可恢复性。

规则：原质量红线逐字保留；原始素材只读，只加工副本；颜色白名单批处理仅动填充，每批抽检10%；不合风格者放废弃目录，不毁原件。

数据：下方保护条款；表S3。

验收：DOD ASSET-004：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/asset_contract.gd -- --case quality`；尺寸/alpha检测，加可数抽检与三格测试记录。

反例：自动尺寸通过不能代替三格观感；禁止直接改原始素材或删除重要资产。

## 原文保护条款：质量红线

- 入库 PNG 分辨率 ≥ 2048px 长边（高清屏缩放余量），Godot 内按需 mipmaps。
- 透明度边缘无白边（导出后 ImageMagick 检查 1px 晕边）。
- 每件入库必须过"三格测试"：与任意两件同库资产并排放置，观感像同一个游戏。

## 资产生产任务（原样保留）

- [ ] **A1 · 下载 CC0 主粮**：拉取 Kenney City Kit（Roads/Commercial/Industrial/Suburban）。记录版本号与下载日期到 `资产/授权登记.md`（**全部 CC0，无需署名，但要记录来源**）。
- [ ] **A2 · `资产/01_原始素材/已购素材/README.md`**：写一份声明——"本目录素材无商用授权，**仅作画风参考，不得入库、不得出现在任何构建产物中**"。并在 `执行交接-P0.md` 与 `执行方案v1` 中引用此声明。
- [ ] **A3 · 离屏渲染管线**：固定等距相机（方位角 45°、俯仰角 30°）把低模渲染成 PNG（长边 512 px），unshaded 材质，中性灰，输出到 `资产/04_预览索引/`，生成索引表（文件名/所属包/分类/包围盒/可用性评级）。
- [ ] **A4 · P0 选件**：约 20 件——住宅 ×3、商业 ×3、工业 ×3、地面 ×2、道路 ×3、树 ×2、装饰 ×4。烘焙为**单张整图 + `manifest.json`**（含 `声部标签: residential/commercial/industrial`）。
- [ ] **A5 · P0 色板**：只做 **1 张**基础色板（24 色）；先不做 16 张。
