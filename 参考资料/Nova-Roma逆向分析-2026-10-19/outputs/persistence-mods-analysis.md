# Nova Roma：存档、扩展与联网边界分析

本报告只读分析安装文件与本地 ILSpy 反编译结果；未启动游戏、迁移程序、Mod、网络请求或旧存档反序列化。主程序集身份沿用 REA Evidence `ev_47e1300ac96a840e61d30a965f7aa4307c97477b861065c1ad65cb6b771ed37a`；以下行为证据来自 `work/decompiled/main` 的具体方法。反编译行号属于分析副本，不是开发者原始源码。代码存在、场景挂载、实际执行是三个不同层级。

## 1. 存档的真实格式与数据流

当前主格式是 **ZIP 容器 + Odin Binary 对象序列化**，不是 JSON，也不是把全部 Unity 场景直接保存。`SaveSerializer.SerializeToStream` / `SerializeToBytes` 先写 `79`（十六进制 `4F`，字符 `O`），再调用 `Sirenix.Serialization.SerializationUtility.SerializeValue(..., DataFormat.Binary)`；策略为 `SerializationPolicies.Everything`。读取端只接受该标识，其他输入抛 `LegacyFormatException`。非 seekable ZIP entry 流会先完整复制至 MemoryStream。证据：`SaveSerializer.cs:8,19,30,36,54,62`。

`LoadSave.Save` 的实际管线（`LoadSave.cs:793`）：

1. 等待上一条 `world` 写入线程；清洗城市/地图名，仅保留 `\w . @ -`（`CleanInput:769`）。
2. 常规保存文件名为 `城市名-年-季节-本地时间.zip`；地图保存位于 `Saves/Maps`；自动存档包含世界 GUID，使用同 GUID 匹配清除前一份自动档（见风险段）。
3. ZIP 模式创建系统临时目录 `RomaZetaZipSave_<随机 GUID>`，在调用线程执行 `new LoadSaveContainer().Pack(null)`，把各系统状态抽成 DTO，再广播 `OnSaveEvent`（`Save:865–872`）。
4. 新 Thread 执行 `OutToFile`，将 DTO 写为 `world`；调用线程写 `summary`、自定义旗帜 PNG，调用截图系统生成 `cover_low_res`（640×360）和 `cover`（3840×2160）（`Save:891–929`）。
5. 世界截图完成回调进入 `Task.Run`，`FinalizeZipSave` 等待 world 线程后，把临时目录以 Fastest 压缩写入最终 ZIP，再清理临时目录（`FinalizeZipSave:534`）。

| ZIP 内成员 | 内容与来源 |
|---|---|
| `world` | 以 `4F` 开头的 Odin Binary `LoadSaveContainer` |
| `summary` | 同一序列化格式的 `WorldSummaryData`：城市名、UTC 日期、人口、年份、分享码、世界 GUID（`SaveWorldSummaryData:973`） |
| `cover` / `cover_low_res` | 截图文件；`LoadTextureFromSave` 读取字节并解码纹理 |
| `custombanner.png` | 仅使用自定义旗帜时保存的 PNG |

`LoadSaveContainer.Pack:87` 明确收集相机、玩家、世界、工作、自然资源、天气、火灾、船只、AI、单位、军团、动态水、季节、资源统计、神明、大坝、坍塌、商人、里程碑、难度、角斗士、物流等状态，并附带扩展字符串字典。由此可确定存档与游戏系统类型强耦合，但不能只靠文件头证明内部图完整有效。

加载兼容 ZIP 和旧目录布局，`GetSavePaths:1313` 同时枚举目录与 `.zip`。ZIP member 查找使用忽略大小写的路径后缀匹配（`FindZipEntry:300`），不要求一定处在 ZIP 根。`LoadAtPath:1326` 读取摘要和封面、显示加载界面，再调用 `LoadThreaded`。注意名称存在误导：`LoadThreaded:1367` **在该方法体中直接打开文件、反序列化并调用 `UnpackThreaded`，没有自行 new Thread**。后者把恢复操作排入主线程队列，`LoadSave.Update:1444` 每次取出一个 Action；顺序先清玩家/AI，再恢复世界、季节/动态水、玩家建筑、工作及其他系统，最后刷新可见性和 UI。成功/错误标记及完成事件也排入队列。

主菜单背景会预载最近存档：`GameState.Update:279` 调 `TryPreloadContinueWorld`；该方法同步反序列化并 `Unpack`，捕捉 Error/Exception/Assert 日志作为失败，成功保留 continueWorldReady，失败回退演示世界（`LoadSave.cs:1151,1446`）。这是主菜单有完整世界状态的代码依据，不是运行时观测。

## 2. 路径、设置、自动存档与扩展数据

`LoadSave.GetSaveDir:605` = `Application.persistentDataPath + "/Saves"`；`GetMapSaveDir:610` = `Saves/Maps`；错误日志为根目录 `errorlog.txt`。`Assets/Settings.SaveSettings:310` 把 `SettingsSaveData` 以同样 `4F + Odin Binary` 写到根目录无扩展名的 `settings`；`CrossGameData.Save:74` 把一个 `BeatSurvival` 布尔写到 `Saves/crossgamedata.dat`。

PlayerSettings 静态字段是 companyName=`LionShield`、productName=`Nova Roma`、bundleVersion=`0.7.2963`（`outputs/unity-settings.json`）。这支持 Windows Unity 默认路径候选 `%USERPROFILE%/AppData/LocalLow/LionShield/Nova Roma`；本次对当前账号该精确路径的只读存在性检查结果为 **不存在**，因此未验证真实玩家存档，也未把候选路径冒充运行时已创建目录。

设置保存音量、画面开关、滚动/缩放速度、UI 缩放、焦点丢失暂停/静音、键位字典及小地图状态（`Assets/Settings.cs:103`）。两处实际差异：`PostEffects` getter 恒为 true、setter 空（229）；`SettingsSaveData.Unpack:159` 强制 `ConsoleControls=false`。旧字段/属性保留不代表当前 UI 选项全部有效。旧格式设置读取失败回默认值，其他异常回默认值后重新抛出（`LoadSettings:318`）。

`AutoSave.OnSeasonChange:56` 支持关、每季、每年、5年、10年、半年；默认 type=6（半年），仅季节名为 Winter 或 Summer 时触发；在 LateUpdate 调 `RunAutoSave`，且仅 play mode 保存（`AutoSave.cs:28,41,98`）。间隔来自模拟季节，不是现实分钟定时器。

给 Mod 的持久化接口实际是字符串层：`SaveDataBuilding` key=`modName + building.guid`，`SaveDataGeneric` key=`modName + identifier`；value 是 UTF-8 的 Base64，`ReadData*` 还原（`LoadSave.cs:224–273`）。`LoadSaveContainer.Pack:129` 引用整个字典，加载恢复该字典（298）。这里的 Base64 是编码；key 没有分隔符/结构化命名空间，也没有单独的 Mod 存档版本协商。

## 3. 旧档迁移及数据完整性边界

迁移并非只有手动工具：`MainGameLoader.Start:33` 自动创建 `SaveMigrationProcess` 并 `Start(Application.persistentDataPath)`，后台线程调用 `SaveMigrationCLI.Run(convert:true)`（`SaveMigrationProcess.cs:55`）。`MainGameLoader.IsSceneReadyToLoad:102` 等 `migration.IsDone` 后才加载 `simulation`，**未以 migration.Success 作为继续条件**。另有 `SaveMigrationApp` GUI 路径，Start 扫描同一位置（136）。

扫描 `settings`、`crossgamedata.dat`、Saves 根的 ZIP 和旧档目录；判定主要看首字节是不是 79（`SaveMigrationCLI.Run:37` / `DetectFile:336`）。转换 `ToOdin:418` 实际调用 **BinaryFormatter.Deserialize** 读取旧类型，再写 Odin。普通加载端拒绝 BinaryFormatter，但启动迁移仍保留它；本次没有对外部或用户存档执行这一过程。

迁移采用临时文件与备份重命名：普通文件写 `.tmp`，旧文件移为 `.bak`，临时文件移回原名并保留时间戳（`AtomicWrite:437`）；ZIP 转换重写所有 entry，只转换 world/summary，其余复制，保留 entry/文件时间，之后旧 ZIP 移 `.bak`、新 ZIP 移原名（`TryConvertZip:478`）。`RecoverInterrupted:309` 清 `.tmp`，原文件缺失时从 `.bak` 移回；但 ZIP 的恢复枚举入口是 Saves 根的 `*.tmp`，所以某些仅剩 `.bak`、无 `.tmp` 的中断组合不会被该循环自动发现。

有四个可复核的完整性限制；均为静态条件风险，**未发现或制造玩家数据损坏**：

- **正常 ZIP 保存不是原子替换。** `FinalizeZipSave:548` 先删除现有目标 ZIP，559 才 CreateFromDirectory；如果删后压缩/写入失败，catch 记日志，但 finally 仍尝试删除 staging。删除旧 ZIP 本身失败会先记录并 return，finally 仍清 staging。`OutToFile:953` 的失败只记日志、不把失败状态传给 finalize；因此正常写入链不能据“回调结束”证明 world 已完整序列化。
- **自动存档先清旧档再收集新状态。** `Save:821–839` 用路径包含世界 GUID 为条件删除匹配目录/ZIP，随后才 Pack、截图、压缩。若后续出错，该世界前一份自动档已不在原路径；清理条件本身不额外核对 `autosave` 字样。代码如此，不等同于本机已发生丢档。
- **迁移备份只保留到浅校验后。** `CleanupBak:614` 验 `4F` 且长度≥2；`CleanupZipBak:582` 仅确认 world entry 存在且首字节 79，就删除 `.bak`，没有完整反序列化并恢复世界验证。
- **迁移处理清单也记失败。** `.migration_processed` 行如 `name|ERROR: ...` 的读取逻辑只取竖线之前的名称（Run:66–78），失败也写该清单（212,227,260）。后续自动扫描会跳过同名项，不能理解为会自动重试所有上次失败档。手动迁移 App 重新扫描不依赖这个清单。

`TryValidateSavePreview:464` 检查 world 存在、summary/封面非空并能读 summary；它不完整反序列化 world。`.zip` 完整、预览可见、世界能够加载应分别验证。

## 4. Mod / Workshop：保留的实现与启用条件

主程序集包含完整运行时 C# 编译代码，安装包也有 RoslynCSharp、Compiler 与 Trivial.CodeSecurity DLL。`KCModHelper.modVersion:373` 为 **2**。

`KCModHelper.ModLoader.Update:101` 仅在 Steam 已初始化时，第一次 SetupLogging→GetWorkshopMods→LoadLocalMods；本地路径是 **Application.dataPath/mods**，即安装包数据目录下 `NovaRoma_Data/mods`，遍历其一级子目录（112,130）。`info.json` 仅存 name/description，缺失不构成 LoadMod 的显式拒绝；实际是否可载由编译与入口判断决定。

`ModCompiler.LoadMod:14` 创建 `ModDomain`，把 `Application.dataPath/Managed` 中所有 DLL 加入编译引用，递归收集 Mod 路径下 `*.cs` 并 `CompileAndLoadFiles`。结果要求 assembly 非空、编译 Success、CodeSecurityReport.IsSecurityVerified 均为真（127,135），再找非静态 `OnScriptLoad` / `SceneLoaded` / `PreScriptLoad` / `Preload` 方法。报告代码没有给出禁用 namespace/member 的完整规则，故不能把 CodeSecurity 名称推导为已验证的强隔离沙箱。

`CreateModInstances:223` 再确认方法为无参或单个 KCModHelper 参数，创建 ScriptProxy，MonoBehaviour 先禁用；`SendScenePreloadSignal:282` 发 Preload/PreScriptLoad，`SendSceneLoadSignal:275` 发 SceneLoaded/OnScriptLoad 后激活 MonoBehaviour。Helper 还支持各平台目录的 AssetBundleManifest、依赖 Bundle、指定 Bundle 加载（`LoadAssetBundle:375`）。

Workshop 获取订阅列表时 creator app ID 硬编码 **1199380**、consumer app 使用当前 Steam app ID、tag=`kcmod`，只请求第1页；安装状态 bit4 成立才读安装目录；metadata JSON 的 version 必须等于2才能编译（`KCModHelper.cs:150–212`）。`WorkshopUI.Populate:436` 仍硬编码 creator=1199380 / consumer=569480；`GameWorkshopUI.Start:55` 打开的页面也是 app/569480。它们是旧 K&C 相关实现/常量保留的具体证据。

**当前构建未建立源码 Mod 启动链。** `ModLoadBootstrapper.Awake:5` 是空方法；在整个 main 反编译树进行调用引用搜索，`ReadyToMakeInstances` / `CreateModInstances` / `SendScene*Signal` 只有定义，没有外部 C# 调用；`ModLoader` 其余出现主要为静态列表读取。补充 Unity 格式感知解析证据 `outputs/target-component-evidence.json`：在 level0/level1、resources、sharedassets0/1 覆盖内，未找到 ModLoadBootstrapper 或 WorkshopUI 的 MonoBehaviour 挂载；KCModHelper/ModLoader 连匹配 MonoScript 都没有。GameWorkshopUI 则真实挂在 level1:35944 的 `MainMenuUI/MainMenu/GameWorkshopUI`，默认对象 inactive。结论是编译器/旧 API/UI 代码保留，但当前扫描没有将编译器接入实际启动流程的证据；不排除未覆盖的动态反射或外部扩展。

旗帜是独立 Workshop 流：`ChooseBannerUI:318` 枚举当前订阅已安装项目目录、读取旗帜，`UploadBanner:135` 用当前 AppID 开始更新、设置 banner tag、PNG 内容和 preview 后提交（147）。它和 kcmod 查询的 app ID 处理不同，不能合并视为同一个启用状态。

## 5. Steam、EOS、网络与“多人”边界

`SystemLoader.Awake:10` 走 `IntegrationManager.SetupIntegration:7` 选择 `SteamIntegration`；后者初始化触发 `SteamManager`。SteamManager 做 RestartAppIfNecessary、SteamAPI.Init、Update.RunCallbacks 与销毁 Shutdown（`SteamManager.cs:45,116,104`）。平台层实装 Steam 成就查询/写入并 StoreStats、DLC 检查（`SteamIntegration.cs:28,37,47,61`）；PersonaName 返回空字符串。另有 Steam Deck 检查与手柄文本输入。这个静态调用链比仅有 Steam DLL 更强，但本次未观测 SteamAPI 实际初始化结果。

安装目录存在 EOSBootstrapper.exe、EOSSDK-Win64-Shipping.dll、Epic/PlayEveryWare 的托管 DLL 和 EOS 配置；main 树未发现 EOS 登录/大厅/联网会话调用，只有 `Temple.cs` 引用 Common.Extensions。EOS 或 Unity Analytics/Services DLL 的存在只说明随包分发，不能据此宣称启用跨平台联机、遥测已发送或登录已执行。第三方 DLL 与场景自动生命周期不在本次 main 调用扫描覆盖内。

| 网络代码边界 | 真实调用/载荷 | 证明范围 |
|---|---|---|
| 存档分享仓库 | `SaveRepo.cs:11` 基址为明文 HTTP 的 saverepo.kingdomsandcastles.com；alive/checkcodeownership/checkcode/getnewcode/upload/retrieve/截图等接口。上传把 ZIP 与截图 Base64 放表单，附分享 code/editAuthCode；下载解 Base64、写 toLoad.zip、保存 return.zip、解包到 fromrepo 后载入（86,105,142）。 | TourismModalUI 有调用链（268,280,300,338,393），真实挂在 level1:44447，默认自身 inactive；MainMenuMode:730 可在分享状态调 SetupForMenuClick/SetupForGameClick。是否用户可达及服务存活未验证。`SendSave.OnClickSend:44` 空实现，不能把“发送存档按钮”推定为会上报。 |
| Twitch 投票 | `TwitchIRC.OnEnable:170`→StartIRC 建 TCP 到 irc.twitch.tv:6667，用 PASS/NICK 登录，收 PRIVMSG 入队，Update 解析并广播；StreamerUI 订阅后 ChatProcessor 消费（175）。 | level1:44116/44184 上组件自身 enabled，但共同祖先 `InGameUI/KeyboardMouseUICanvas/VotingFeature[Start Off]` inactive，故默认层级禁用。Settings.StreamerMode setter:272 会按选项激活 VotingFeature，属聊天互动/投票，不能证明城市多人同步。未记录 oauth 或昵称值。 |
| Workshop | SteamUGC 查订阅、上传；preview URL 用 WWW 下载（GameWorkshopUI:194 / WorkshopUI:473）。 | Steam UGC 与外部预览资源，不是局域网/互联网多人。 |
| 新闻、周边 | BlogViewer.ShowNews:15 用 WWW 请求可配置 blogSite；StoreInfo.OnEnable:36 请求 Shopify inventory，代码存在静态认证请求头。 | 未复制或验证头值，未发送请求。属于保留网络功能；场景绑定/激活另验。 |

存档分享 `PackageSave:637` 使用 CreateFromDirectory；这与分享界面的调用相吻合：`TourismModalUI.Show:229` 显式调用 `LoadSave.Save(Saves/upload)`，路径没有 `.zip`，因此此流程创建的是目录，Update:176 再把该目录设置为 uploadPath。不能因常规保存已改 ZIP，就直接认定分享流程存在目录/ZIP 不匹配。

针对 main 全树（排除生成 registry 与 Rewired 第三方 UI）搜索 SteamNetworking、SteamMatchmaking、NetworkServer/Client/Behaviour、Unity.Netcode、Photon、RPC、Multiplayer 等，没有发现城市同步、房间、主机/客户端或 RPC 实现。`MirrorVector` / `isMirrored` 是图形镜像词，不是 Mirror 网络库。**观察结论：主游戏逻辑中没有建立多人系统的证据；不能仅由 EOS/Steam 包装 DLL 推导出多人功能，也不能把有限静态扫描表述为“所有依赖都绝无联网”。**

## 6. 验证记录与覆盖限制

- 使用 `rg --files` 枚举和 `rg -n --glob '*.cs'` 交叉查调用者；重点逐行读 SaveSerializer、LoadSave、LoadSaveContainer、SaveMigration*、Settings、KCModHelper、ModCompiler、SteamIntegration/Manager、SaveRepo、TwitchIRC、TourismModalUI、StreamerUI 等。
- 验证安装包相关 DLL/配置文件存在；未运行 DLL、Mod 或游戏。当前 Windows 默认持久化目录候选的 Test-Path 返回 False，未读取玩家凭证或存档内容。
- 相关 scene MonoScript/MonoBehaviour/层级证据已补入 `outputs/target-component-evidence.json`；严格 DLL schema 解析字段覆盖见 `outputs/focus-serialized-fields.json`，后者只列字段名，未导出 oauth 等值。构建层级默认状态不代表运行时最终激活状态。
- 关键结论有方法体/数据流证据；外部服务活性、运行时激活、真正读写/崩溃表现、EOS/Analytics 第三方生命周期及 Odin 跨版本恢复完整性仍需另行验证。
- 这是分析交付，不是代码修改。没有修改或删除游戏目录、用户数据，没有执行迁移或自动存档。
