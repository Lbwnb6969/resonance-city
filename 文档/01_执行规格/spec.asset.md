# 资产、许可与加工执行规格

> 2026-10-08 · 四包CC0已下载。用户本次明确授权资产/2.5D素材按需使用，覆盖旧禁入库限制；当前规则见ASSET-001及资产/使用授权说明-2.5D素材.md，现状见授权登记/PROJECT。

## 表 S1 · 人类评审来源表（原样保留）

| 级别 | 来源 | 内容 | 许可 | 用途 |
|---|---|---|---|---|
| **L1** | Kenney City Kit 系列（Roads / Commercial / Industrial / Suburban）<br>`kenney.nl/assets/city-kit-suburban` `.../city-kit-commercial` `.../city-kit-industrial` `.../city-kit-roads` | 低模建筑/道路/围栏/树 40+ 件/包，模块化，纯色，OBJ/FBX/GLTF | **CC0**（可商用、无需署名） | 建筑/道路/植被主力。2025-04 整包重做 |
| **L1** | Kenney Audio（interface-sounds 等） | UI 音、小采样 | **CC0** | UI 反馈音 |
| **L1** | **VCSL**（Versilian Community Sample Library）`github.com/sgossner/VCSL` | 木管/弦乐/键盘/打击真实采样，44.1kHz WAV | **CC0** | 声部音色取样底库（替代纯合成） |
| **L1** | **VSCO 2 Community Edition** `versilian-studios.com/vsco-community` | 管弦采样集 | **CC0** | 同上 |
| L2 | itch.io CC0 × isometric 标签、OpenGameArt（筛 CC0）、openclipart | 2D 等距零件/图标 | CC0 / CC-BY | 补缺口；CC-BY 需在 `资产/授权登记.md` 记署名 |
| L3 | AI 生成 | 仅限概念图、UI 图标、图鉴剪影 | — | 必须过色板收编后才可入库 |

事实适用说明：表 S1 中“40+件/包”“2025-04整包重做”“全部44.1kHz”不得替代实际包证据。官网当前 Suburban 2.0/40件、Commercial 2.1/50件、Industrial 2.0/40件、Roads 2.1/90件；四包CC0已实际下载，包内License版本与官网一致；四包均含GLB/OBJ/FBX，实际文件清单与SHA见许可记录。版本和授权登记见 `../../资产/授权登记.md`；调研链接见 `../事实核查-2026-10-08.md`。

## 表 S2 · 环境缺口（原样保留）

| 工具 | 用途 | 安装 | 验证命令 |
|---|---|---|---|
| **Ghostscript** | **EPS 解析（Inkscape 的硬依赖）** | `winget install ArtifexSoftware.GhostScript` | `gswin64c --version` |
| Inkscape | 矢量格式转换、拆件 | `winget install Inkscape.Inkscape` | `inkscape --version` |
| ImageMagick | PNG 批处理、晕边检查 | `winget install ImageMagick.ImageMagick` | `magick -version` |
| （若走 §1.3 离屏渲染）Blender | 低模 → 等距 PNG | `winget install BlenderFoundation.Blender` | `blender --version` |

Ghostscript是EPS导入依赖，不是CC0低模生产线的前置依赖。已授权EPS选件需要加工时再使用该工具，不因目录存在而全量加工。上述安装命令来自评审，winget包ID须在安装时核实；本轮未安装。前三条工具bin加入PATH后分别验证，选用Blender则增加第四条输出。Godot离线工具与Blender二选一；不要求两个都装。

## 表 S3 · 离线到运行时

| 阶段 | 规则 / 输出 |
|---|---|
| 原始 | `资产/01_原始素材/`只读；已购实际位于`资产/2.5D素材/`，用户已授权按需使用，不迁移巨量原件 |
| 加工 | CC0或已授权素材的副本在`资产/02_加工中/`离线加工/组合 |
| 预览 | 相机方位45°、俯仰30°，unshaded，中性灰，PNG长边512px；`资产/04_预览索引/` |
| 主图 | 每建筑1张整图；按原质量红线长边≥2048px；颜色槽位/LUT编码见已授权表S6 |
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
| texture / palette_slots | 单张整图引用与LUT槽位；中性灰须可区分槽位，编码见S6 |
| footprint_tiles / floor_height / origin | 占地、层高、底部中心基准 |
| voice_tag | residential/commercial/industrial；非街区件明确标为非声部 |
| source_url / package_version / downloaded_at | 实际来源、版本与下载日期，禁止假填已下载 |
| license / license_file / attribution | 可再查的许可、用户授权与署名证据；已购记录实际来源及使用授权说明，不标成CC0 |

### [ASSET-001] 来源登记与已授权素材

状态：已裁定；2026-10-08用户新增授权2.5D素材正常使用。

意图：使当前获准素材能够加工并用于Demo，同时保留真实来源。

规则：四包CC0逐包登记；CC-BY逐件记录署名；用户已授权`资产/2.5D素材/`及其加工成品按需入库/构建，替代旧仅参考限制。授权入口为`资产/使用授权说明-2.5D素材.md`，旧限制存废弃目录。原件保留，只加工副本，精选成品部署资源/；不全量导入3.15GB原素材。L3仅概念/UI/剪影并经收编，不允许AI直接整城生成。

数据：表 S1、S5；授权登记及2.5D素材使用授权说明。

验收：DOD ASSET-001：`& "D:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path . --script res://tests/asset_contract.gd -- --case license`；当前脚本核验既有四CC0包和授权入口，不代表未来新增加工成品已经核验；构建依赖仅含实际部署成品。

反例：不把已购素材标成CC0；不再用旧禁用声明阻塞本次授权；不重新做744EPS的生产盘点；未下载或未加工不写“已入库”。

### [ASSET-002] 低模离屏与整图烘焙

状态：U11的P0技术已获用户授权；S4总数笔误待确认，艺术验收待记录。

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
- [x] **A2 · 使用授权入口**：用户已确认2.5D素材可正常使用，记录在`资产/使用授权说明-2.5D素材.md`，旧禁用声明保存废弃目录。
- [ ] **A3 · 离屏渲染管线**：固定等距相机（方位角 45°、俯仰角 30°）把低模渲染成 PNG（长边 512 px），unshaded 材质，中性灰，输出到 `资产/04_预览索引/`，生成索引表（文件名/所属包/分类/包围盒/可用性评级）。
- [ ] **A4 · P0 选件**：约 20 件——住宅 ×3、商业 ×3、工业 ×3、地面 ×2、道路 ×3、树 ×2、装饰 ×4。烘焙为**单张整图 + `manifest.json`**（含 `声部标签: residential/commercial/industrial`）。
- [ ] **A5 · P0 色板**：只做 **1 张**基础色板（24 色）；先不做 16 张。

## 表 S6 · P0色板与索引技术（用户授权U11补齐）

保留原5主色，补齐24槽。仅一个基础色板；P0不实现昼夜16色板或运行时3D。源模型自带colormap的24组UV色块映射到本色板，保留组内明暗纹理。离线索引主图与运行时着色整图分别留存，运行时每件只用一个Sprite2D。

| 槽 | 名称 | sRGB |
|---|---|---|
| 0 | 墙 | #F2EDE4 |
| 1 | 陶土屋顶 | #D96B4F |
| 2 | 工业灰蓝 | #6B7B8C |
| 3 | 叶绿 | #7FB069 |
| 4 | 暖窗 | #FFD98A |
| 5 | 墙阴影 | #D8CFC0 |
| 6 | 砖红 | #B65D4D |
| 7 | 路面 | #454B55 |
| 8 | 钢灰 | #7E8792 |
| 9 | 混凝土 | #A9ADB0 |
| 10 | 沙土 | #D8B78D |
| 11 | 屋顶暗部 | #A64F3D |
| 12 | 木材 | #8E6752 |
| 13 | 深缝 | #333943 |
| 14 | 深钢灰 | #505B68 |
| 15 | 石板 | #8E98A5 |
| 16 | 浅石板 | #BCC5CE |
| 17 | 深叶 | #4F8264 |
| 18 | 土壤 | #A77D5E |
| 19 | 暖粉墙 | #E7BDA8 |
| 20 | 草地 | #A6BD83 |
| 21 | 淡蓝 | #A9C5D9 |
| 22 | 薰衣草 | #A496B6 |
| 23 | 暖白亮部 | #FFF5DE |

| 技术项 | 规则 |
|---|---|
| 索引主图 | 长边2048px；RGBA，中性灰R=G=B=8+10×槽号，alpha仅轮廓，不把颜色插值后的中间值当槽；单件整图 |
| 着色主图 | 同相机同几何离线套基础LUT，长边2048px；运行时部署这张单件整图并生成mipmaps，避免对索引图做mip混合造成槽位串色 |
| 换色边界 | 索引/LUT是离线可重烘接口；P0只使用基础24槽，不宣称P1运行时昼夜换色完成 |
| 预览 | 512px长边、中性灰、有源纹理明暗；独立于高清主图 |
| 透边 | 透明像素RGB=0，后续按预乘alpha处理缩放；运行时PNG导入fix_alpha_border，禁止白底裁图 |
| 相机 | 正交，方位45°、俯仰30°；每件以包围盒对齐并裁透明边，origin保存地面底部中心的像素坐标 |
| 选件 | 按S4类别先加工20件，正文21件冲突待用户裁定：住宅suburban a/b/c，商业commercial a/b/c，工业industrial a/b/c，roads tile-low/tile-high，road-straight/bend/crossroad，suburban tree-small/large，fence/planter，industrial water-tower，roads light-square |
| 原件与依赖 | 只从四CC0白名单复制选件到资产/02_加工中，GLTFDocument从文件读取副本；不生成原件import记录，不让运行时依赖GLB |

本轮选择Godot离线工具，批处理场景由工具构建；模型读取参考[GLTFDocument](https://docs.godotengine.org/en/stable/classes/class_gltfdocument.html)，离屏参考[SubViewport](https://docs.godotengine.org/en/stable/classes/class_subviewport.html)。三格观感需另存人工记录；自动尺寸/颜色/许可通过不等于艺术验收通过。

加工类别映射：住宅屋顶/窗使用槽1/4；工业主墙/结构使用槽2/14；树冠/树干使用槽3/12；花坛叶片也为槽3。仅工作纹理调整，不改源UV或原GLB。首次树冠灰色/工业沙色的输出存资产/废弃/2026-10-08_首次映射偏色。当前资源/候选仅用于技术与性能验证，人工三格获批状态仍PENDING。


## 表 S7 · 当前批次质量证据

当前明确类别项20件，数量正文21的冲突另待裁定。技术检查覆盖每件主图长边/预览区别、索引离散字节/alpha一致、透明RGB零、原件SHA/只读、许可SHA；透边用Pillow/NumPy像素检验与黑白底alpha加权缩放图，等价技术用途，无需EPS工具链。固定抽检住宅a和tree-small两件，占当前批次10%。运行时缩放导入设置由baked_sprite合约核验。

三格图逐件生成，目标与两件不同同库对照按相同世界单位缩放、地面origin对齐；记录在验证记录/P0/素材审查/三格人工记录.csv。每项保留主图SHA/同伴ID，人工填写approved或rejected、真实审查者与具体观察。未经填写或主图SHA已改变，quality结果必须PENDING；技术检查不能代替人工观感。艺术拒绝后修改工作副本，旧成品移废弃目录，原件不改。

## Demo加工补记（用户新风格要求）

用户明确要求柔和、轻松的背景/房屋和社区模板，并允许代码改造2D资产。本轮保留P0基础24色与20张原图，tools/prepare_demo_art.py仅读取原槽位与明暗，加工9张建筑Demo副本和新的柔和24色；尺寸/alpha/地面origin不改。实际成品/来源SHA在资源/Demo城市/manifest.json，生产副本在资产/03_入库/Demo城市；同系色相与明暗映射不靠全局白雾遮住细节。原许可仍CC0，模板组合后继续登记实际来源；已购授权也可按需加工。运行画面以当前副本为准，人工审美仍待用户反馈，不把新条件说成旧700栋固定fixture已经重测。
