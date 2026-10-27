# Nova Roma 发行结构与资源分析

分析对象为 `D:\SteamLibrary\steamapps\common\Nova Roma`，只读检查日期 2026-10-18。此目录是 Windows 游戏发行包，不是 Unity 编辑器源工程；没有运行游戏、加载原生插件、操作存档或导出贴图/音频。本文证据标签 A01–A08 对应下面列出的本地成果，属于格式解析证据，不是 REA 会话 Evidence ID。

## 已确认的发行身份与布局

- **A01 文件清单**：全目录 313 个文件，970,352,298 字节（925.40 MiB）；每个文件均记录相对路径、长度、SHA-256，见 `file-inventory.csv` 和 `file-inventory-summary.json`。
- `build_version.txt` 为 **0.7.2963 / Built 2026-10-15 10:20:24 / Main / Release**；`app.info` 为 **LionShield / Nova Roma**。Unity 序列化文件版本及 `UnityPlayer.dll` 版本资源共同确认 **Unity 6000.2.10f1 (d3d30d158480)**。
- `NovaRoma.exe`、UnityPlayer、Mono runtime、x86_64 游戏插件均为 PE AMD64；EOSBootstrapper 为 PE x86。`MonoBleedingEdge`、独立 Managed DLL 和 `Assembly-CSharp.dll` 表明发行包使用 Mono 托管脚本布局，另有 Burst 原生编译代码。不是只有 IL2CPP native code 的布局。
- 游戏资源主体直接保存在 `resources.assets`、`sharedassets0/1.assets` 与对应 `.resS/.resource` 数据流中。此次全目录清单未发现独立 Addressables catalog 或外置 AssetBundle 文件；这只界定当前发行包，不能排除运行时网络下载或程序生成内容。
- `EOSBootstrapper.ini` 指向 NovaRoma.exe。`Nova Roma_BurstDebugInformation_DoNotShip/.../lib_burst_generated.txt` 随发行包存在，记录 Windows/X64_SSE2、burst-llvm-19、全局 safety checks Off、原构建机 `C:\Roma\Temp\BurstOutput` 路径。这是构建元数据，不能直接解释性能或崩溃。

## 资源与场景结构

**A02 Unity 对象清单**：UnityPy 1.25.4 成功打开全部 9 个序列化载体，枚举 **137,422** 个对象；载体级失败为 0。清单见 `unity-asset-summary.json`；完整对象元数据目录压缩为 `unity-object-catalog.json.gz`（原 JSON 约 18.8 MB，压缩约 709 KB）。记录 path ID、类型、可读取名称与部分纹理/音频属性，不含媒体像素或采样。

| 载体 | 对象数 | 主要职责证据 |
|---|---:|---|
| globalgamemanagers | 20 | Player/Build/Quality/Graphics/Resource 设置 |
| globalgamemanagers.assets | 4,764 | 4,688 MonoScript、70 Shader、预加载引用 |
| level0 | 88 | startup：18 GameObject、34 MonoBehaviour、启动画面与 MainGameLoader |
| level1 | 49,534 | simulation：11,652 GameObject、15,900 MonoBehaviour、主 UI 与模拟入口 |
| resources.assets | 54,397 | Resources 路径下资源、prefab、定义表、633 Mesh |
| sharedassets0.assets | 257 | 启动/共享图像、音频、混音器 |
| sharedassets1.assets | 28,231 | 主场景共享 prefab、网格、动画、文本资产 |
| unity default resources | 87 | Unity 内建资源，内嵌版本 6000.2.0b3 |
| unity_builtin_extra | 44 | 44 个内建 Shader |

`unity default resources` 的版本字段与主包不同；它是内建资源载体，不改变 Player 和主要资源均为 6000.2.10f1 的结论。

BuildSettings 的构建场景明确为 `Assets/startup.unity`、`Assets/simulation.unity`。它们是编译时保留的源工程路径，不表示这些 `.unity` 源文件随包存在。`StreamingAssets/EntityScenes/scene_info.bin` 只有 164 字节，当前目录没有独立 ECS subscene 内容文件；不能据此声称主要模拟在 ECS 子场景中。

合计枚举到 **779 Texture2D、824 Mesh、604 Sprite、508 Material、167 Shader、156 AnimationClip、62 AudioClip、11 Font**。这些是序列化对象数量，包含引擎/第三方/重复引用及备用内容，不能当成玩家可见物种或独立模型数量。纹理最常见尺寸为 512²（199）、256²（128）、128²（92），另有 1024²（29）。字体包含简繁中、日、韩 NotoSansCJK 字体，说明 CJK 字形资产随包存在；支持哪些语言、翻译是否完整不能仅由字体证明。

**A03 设置与 Resources 路径**：精选设置在 `unity-settings.json`，868 条资源路径映射在 `unity-resource-path-index.json`。路径包括 `i2languages`、`resourcedefinitionlist`、`scenarioworlds`、四季定义、placeables、terrainresources。868 条是 ResourceManager 容器项，允许同路径多对象及空指针，不等于 868 个唯一可加载 prefab。

GraphicsSettings.customRenderPipeline 为零引用，唯一质量档 `Fantastic` 的 customRenderPipeline 同样为空；这是随包使用内建渲染管线配置的静态证据。程序集包含 RenderPipelines 库不能推翻实际序列化设置。BuildSettings 图形 API 枚举为 `[2,18]`，对应 D3D11/D3D12；目录也附 D3D12Core.dll。运行时最终选用的 API 未观测。

## 场景挂载与实际配置值

**A04 场景引用**：`target-component-evidence.json` 使用标准 Unity MonoBehaviour 头部读取 m_Script 指针，追溯 GameObject/Transform 层级和 active 状态；不是只按类名猜测功能。以下对象都存在于构建场景：

| 类 | 载体:path ID | 序列化启用状态 |
|---|---|---|
| MainGameLoader | level0:86 | enabled，整条层级 active |
| GameState | level1:49184 | enabled，整条层级 active |
| DynamicWater | level1:33636 | enabled，整条层级 active |
| AqueductFlowDriver | level1:49194 | enabled，整条层级 active |
| GameWorkshopUI | level1:35944 | enabled，自身 GameObject inactive |
| TourismModalUI | level1:44447 | enabled，自身 GameObject inactive |
| TwitchIRC / StreamerUI | level1:44116 / 44184 | 自身 enabled/active，但祖先 VotingFeature[Start Off] inactive |

KCModHelper、ModLoader 未找到匹配 MonoScript；ModLoadBootstrapper、WorkshopUI 有 MonoScript 定义，但在此次检查的 level0/1、resources.assets、sharedassets0/1.assets 中没有对应 MonoBehaviour 挂载。以上只限定这些载体，运行时代码仍能创建组件；inactive UI 也可在运行时打开。

**A05 标量配置**：`focus-serialized-fields.json`、`resource-definition-summary.json`、`season-settings.json` 使用 TypeTreeGeneratorAPI 从本机 Managed DLL 生成字段 schema，再用 UnityPy 进行完整字节覆盖读取。生成器的基础 MonoBehaviour 头部对齐与 Unity 原格式有差异，已用 UnityPy 官方头部替换，复核 m_Script 指针恢复正确；交付文件保留精选标量及字段名，未输出 oauth/帐号等值。

- **DynamicWater 场景值**：SimulationTimeStep=0.1、TimeStep=0.1、width=height=351、jobInnerloopBatches=64、A=1、Gravity=10、L=1、Evaporation=0.005。场景 TimeStep 覆盖类默认值，分析运行设计时应优先用该序列化值。
- **TimeManager 场景值**（level1:35793）：playSpeeds=`[0,0.85,1.2,2,10]`。它们是内部时间倍率配置，不能直接用 UI 按钮文案替代。
- **SeasonDefinition**：春 duration=100 / transitionTime=10；夏125/10；秋100/40；冬125/30。只有春季 markNewYear=1。四季 duration 合计450个配置时间单位，现实秒数还受时间推进代码、暂停和速度倍率影响。
- **ResourceDefinitionList**（resources.assets:52636）：21项，ID0–20：wheat、tree、stone、charcoal、gold、iron、tools、armaments、fish、apples、ham、bread、grapes、wine、marble、clay、pottery、dirt、olives、oliveoil、salt。对应 carryCapacity、isSecondary、timeExpire、thoughtWhenMissing 已导成简表。这是当前定义列表，不将其扩大为所有运行时库存系统的穷尽结论。

`sharedassets1.assets` 中有两组 world/summary 与 JPEG cover/cover_low_res 的 TextAsset。`embedded-text-assets.json` 记录精确原始 payload 长度、SHA-256 与前32字节；world/summary 的头部符合 .NET 二进制序列化流，cover 头部为 JPEG。没有对这些数据进行 BinaryFormatter 反序列化，也未导出内容；它们支持“包内带世界数据及预览图”的结论，具体用途须结合调用代码。

## 音频与平台依赖

**A06 FMOD bank**：5个 bank 共149,908,696字节（约142.96 MiB）。`audio-bank-inventory.json` 验证 RIFF/FEV 容器与区段尺寸；全部 bank 的 RIFF声明长度与文件长度吻合。

| bank | 字节数 | 容器内容 |
|---|---:|---|
| Master.bank | 87,612,800 | FMT、LIST、SND |
| Music.bank | 52,093,920 | FMT、LIST、SND |
| Ambience.bank | 6,262,336 | FMT、LIST、SND |
| SFX.bank | 3,910,592 | FMT、LIST、SND |
| Master.strings.bank | 29,048 | FMT、LIST，无SND |

同时存在62个 Unity AudioClip，说明发行包并非全部音频只走 FMOD。此次没有加载 FMOD SDK、播放声音或解析 FMOD 内部事件字典；bank 文件名只表明分包命名，不能据此推断播放优先级、混音路由或所有事件数。

**A07 原生依赖**：`native-dependencies.json` 用 pefile 静态读取 PE machine、版本资源及导入 DLL。

| 组件 | 版本/证据 | 可支持的结论 |
|---|---|---|
| fmodstudio.dll | 2.3.11，x64及ARM64文件 | 音频中间件发行依赖 |
| EOSSDK-Win64-Shipping.dll | 1.17.1.3-44532354 | Epic Online Services SDK 随包 |
| Galaxy64/GalaxyCSharpGlue | 1.152.10.0 | GOG Galaxy 集成依赖随包 |
| steam_api64.dll | PE x64，配套Steamworks.NET | Steam 集成依赖随包 |
| Rewired_DirectInput/WindowsGamingInput | x64及ARM64文件 | 多输入后端插件 |
| resonanceaudio.dll、xaudio2_9redist.dll | PE x64 | 空间音频/Windows音频依赖 |
| lib_burst_generated.dll | PE x64 | Burst 编译产物 |
| D3D12Core.dll | 1.611.2 | D3D12 Agility 组件 |

ARM64 文件只出现在少量插件下，而主 EXE/Player/Mono 是 x64，因此该安装包不是可以直接作为完整 ARM64 Windows player 运行的证据。Steam/GOG/EOS 并存也不表示当前启动同时登录三个平台。

**A08 外部服务配置**：StreamingAssets 中 UnityServicesProjectConfiguration 指向 production，Unity Services Core版本1.14.0、Analytics版本6.1.0。EOS 产品配置含 Dev/Stage/Live环境及明文 clientSecret/encryptionKey 字段；报告只记录存在，不复制值，也未向服务发请求。字段存在不证明凭据有效、权限范围或可被利用。Unity BuildSettings 中的构建token已从输出脱敏。

## 验证与边界

问题清单中“完整文件与身份、Unity版本、资源分包、场景、平台原生依赖”已用格式解析回答；“场景指定组件与关键标量配置”已回答；“所有脚本的自定义序列化字段、语言翻译完整性、FMOD事件及实际播放/运行时行为”仍为部分或未回答。

初次通用 UnityPy 读取有21,436条对象级 metadata_error，主要是 MonoBehaviour 剥离 typetree 后只能读取32字节标准头部；PlayerSettings 的通用版本模板存在884/888字节尾部差异。完整对象数量来自对象表，不依赖这些字段解码成功。PlayerSettings仅选取已读前部字段并注明partial；目标脚本通过生成schema独立严格读取。I2.Loc.LanguageSourceAsset 尝试生成schema仍报 read_u8_array out of bounds，因此没有给出语言数量或缺译率。没有把解析失败解释为损坏或加密。

最小有效验证为：全目录文件长度/SHA-256清单、全部9个Unity载体对象表可读、PE版本与序列化Unity版本交叉印证、场景指针与MonoScript类名关联、指定配置完整字节读取、FMOD RIFF尺寸自洽。执行脚本保存在工作区 `work/analyze_assets.py`、`enrich_assets.py`、`target_components.py`、`read_focus_serialized.py`、`resource_values.py`、`package_asset_evidence.py`。大型中间对象目录、完整脱敏设置和资源值中间结构移到 `work/evidence/` 保留，未删除游戏或重要证据；解析依赖 `work/assets-tools/` 已排除Git。全局原件最终复核与Git备份由主调查统一执行。
