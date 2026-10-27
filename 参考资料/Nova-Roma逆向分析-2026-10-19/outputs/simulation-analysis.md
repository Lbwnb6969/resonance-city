# Nova Roma 城市模拟与经济系统静态分析

分析对象：`D:\SteamLibrary\steamapps\common\Nova Roma\NovaRoma_Data\Managed\Assembly-CSharp.dll` 的 ILSpy 反编译结果，并交叉使用 `outputs/resource-definition-summary.json`、`outputs/season-settings.json` 提取的实际序列化配置。本文 C# 路径均相对 `work/decompiled/main/`，行号指当前反编译文本，不能直接映射开发者原始源码。未启动游戏、未注入或修改程序集。证据为静态代码观察及已解析资产字段；行为发生仍取决于场景挂载、Resources/Prefab 数据、难度选项、调用时机和实际可达性。

## 1. 主结论与覆盖范围

城市模拟的实际枢纽是 `Player.Update()`，而不是仅凭命名直觉认定的 `World.Update()`。前者推进建筑 Tick、施工、库存统计、幸福度、人口、税收、疾病与村民行为；后者主要维护地形显示、寻路网格和线程同步。模拟按陆块分区，政治所有者可以持有多个陆块；实物资源按陆块/仓储存在，金币集中到所有者。住宅既消费库存又占用家务劳动力；幸福度影响移民，人口增加又提高宗教维护压力，从而形成扩张—消费—劳力—税收—宗教的反馈闭环。下述调用及公式支持这些结论，不以类名或本地化词条证明当前版本完整可玩。

| 问题 | 状态 | 静态证据边界 |
|---|---|---|
| 启动、时间、更新链 | 已回答 | 场景名、模式切换、Update 调用链；未验证实际帧序 |
| 地图、陆块、建筑生命周期 | 已回答主要结构 | 生成/归属/施工完成链；未穷举全部放置规则 |
| 人口、住宅、幸福、税收 | 已回答核心因果链 | 公式、移民限制、消费和死亡；住宅具体 Prefab 参数未提取 |
| 生产、工作分配、物流、贸易 | 已回答通用机制 | 通用生产器、运输状态机、商人交易；未构建完整资源配方表 |
| 神祇任务、惩罚、节庆 | 已回答核心机制 | 任务实例、进度/交付、怒气/惩罚；对话资源实际调用仍待运行确认 |
| 存档/Mod、水利细节、战斗平衡 | 不在本分报告范围 | 由其他分析覆盖 |

## 2. 启动与时间推进

1. `MainGameLoader.cs:33 Start()` 启动存档迁移扫描；`IsSceneReadyToLoad()`（104 起）等待迁移完成后异步加载 **`simulation`** 场景，再查找 `WorldLogic` 的 `World`，最后等待 `World.ReadyToBeSeen()`。这证明具体场景和世界入口，不证明每台机器的加载时长。
2. `GameState.cs:96 LoadPrefabsFromResources()` 用 `Resources.LoadAll<Building>("Placeables")` 注册建筑，并以 `UniqueName` 检查重复；`GameState.Update()`（245 起）首次更新进入主菜单/预载继续世界，随后调用 `CurrMode.UpdateManual(Time.unscaledDeltaTime)`。建筑参数很大一部分来自资源对象而非硬编码 C#。
3. `TimeManager.cs:22 playSpeeds` 数组为 `[0, 0.85, 1.2, 2, 10]`；已解析 `outputs/season-settings.json` 的实际 `level1:35793` 同样保存这5档。私有 `SetSpeed()`（110 起）直接设置 `UnityEngine.Time.timeScale`，因此普通档实际配置为约0.85时间缩放。`OnApplicationFocus()`（223 起）仅在游玩模式和相应设置开启时失焦暂停。
4. `SeasonManager.cs:225 DefaultPlanner()` 从 Resources 加载春、夏、秋、冬定义；`UpdateYearData()`（236）将各季 `duration` 相加作为一年。实际解析 `resources.assets:52638–52641` 为春100、夏125、秋100、冬125，共450个定义时长单位（见 `outputs/season-settings.json`）。`Update()`（247–287）累加 **Time.deltaTime** 并切季，第一年白天春季再乘0.5、夏季乘0.75，此外还受时间档位、暂停/hold影响。因此450是定义总时长，不能直接称作现实450秒一年。

`Player.cs:2324 Update()` 在 World 未初始化/正在加载时返回，随后调用 `Tickable.TickAll(deltaTime)`（2351）、`Building.UpdateBuildingConstruction(deltaTime)`（2365），并按陆块重新计数实物资源（2423–2434）。仅 `GameState.IsPlayMode()` 成立才调用饥饿、幸福、健康、完整性、衰朽、自燃、移民、随机事件、瘟疫、税收、寒冷、神祇和总督更新（2436–2450）。后面的村民 `UpdateMind()` 与老年/疾病死亡链（2465–2638）在该条件块之外；主菜单演示世界如何配置仍取决于运行场景。

## 3. 世界、所有权与建筑生命周期

`World.cs:2769 Generate()` 生成 GUID、重置 Player/AI，以选定或随机种子调用 `SRand.SetSeed()`、`GenLand()`，然后记录生成后地块状态、建立寻路成本、更新小地图（2825–2840）。同文件 `3473 GetLandmassOwner()` 查 `LandMassOwnerLookup`；`3516 GetVillagersForLandMass()` 查陆块人口数组。`LandmassOwner` 有 `ownedLandMasses`，支持一个所有者多陆块；`World.IsAILandmass()`（3506）以是否等于玩家所有者判定 AI 陆块。

建筑由 `Building` 提供占地、施工、工时、工作岗位、耐久及资源提供者接口，具体功能由 `Home`、`ProductionBuilding` 等附加组件实现。`ResidentialBuilding.cs:1` 本身只是空子类，实际住宅逻辑在 `Home`，因此不能把继承名称当作功能实现证据。

施工链为资源收集/工人施工 → `ConstructionForeman.UpdateBuildProgress()` → `Building.UpdateConstruction()` → `CompleteBuild()`：

- `ConstructionForeman.cs:315 ValidateResourceProgress()` 对每一种非金币材料计算 `collected/cost` 后取平均；`354 UpdateBuildProgress()` 每次调用增加 `dt / BuildTimeAtMaxStaff / jobs.Count`，并把施工进度限制到资源进度。其含义是工人调用次数与材料到场共同限制进展，不能把建筑全额成本当成瞬间完成。
- `Building.cs:2643 UpdateConstruction()` 在暂停施工时返回；进度达到 1 后清理工作、完成建筑并广播 `BuildingBuilt`（2695–2726）。创意模式有直接消费未付成本/置进度为 1 的路径（2658–2665）。
- `CompleteBuild()`（2847–2890）设置 `built=true`、发送 `OnBuilt` 消息、记录年份、注册资源提供者、更新玩家建筑登记、添加工作、重烘路径。由此生产器和住宅只有在“建成”后才参与其主要经济逻辑。
- `World.Update()`（3741–3799）调用 `pather.Update()`，处理待重烘地块并更新 `pathGridId`，随后等待线程寻路器。路径是影响工人到岗与运输可达性的独立约束。

## 4. 人口、住宅消费与幸福度

### 4.1 住宅库存和劳动力

`Home.cs:321 GetHappiness()` 将消费品 modifier、地块 modifier、饮食、水、污秽、诊疗健康、税负相加。饮食质量（389–399）为：

`dietQuality = clamp(sqrt(有库存的饮食槽位数 / diet.Length), 0, 1)`。

`GetHappinessFromDiet()`（427–434）取 `ceil(dietQuality × MaxHappinessFromHealth)`，字段默认上限 50（152）；特定科技与资源 ID 13 再加 3。注意这里按**家中库存**计算，城市总库存充足不直接等价于每户膳食改善。

`Home.Tick()`（998–1044）每 100 帧分摊一次消费逻辑，消费计时增加 `100 × dt × Residents.Count/MaxResidents × 难度倍率 × 总督倍率`。难度 foodConsumption 的 2/3/4 档分别乘 1.25/1.5/1.75。`TryEat()`（1717–1805）按饮食轮转优先补缺，先尝试主食类型，再尝试替代类型，最后扫描其他可吃库存；吃到后按 1 件扣减。食物消费关闭/创意选项存在免扣库存路径。缺餐累计两次以后，在相关创意选项允许且随机值 <40 时把住户放入饥饿死亡队列；`Player.ProcessStarvation()`（4413）只有该陆块人口 >5 才实际销毁该人并留尸体。

`Home.UpdateHomemakerAssignment()`（1579–1641）按入住量计算家务岗位所需人数，从住户中分配；必要时调用其 `QuitJob()` 再转入家务工作，消防志愿者、征召兵和病人被跳过。住宅配送因此与外部产业争用同一批居民劳力。`Home.Tick()`（1063–1066）周期性调用 `TrySwapInCloserWorker()` 优化住居通勤；未评估其大城实际收益。

### 4.2 城市幸福并非立即跳到目标

`Player.cs:1064 HappinessTimer` 默认 3 秒。`UpdateHappiness()`（3328–3390）每次触发对有建筑的陆块计算：

`target = clamp(有人居住房屋幸福的算术均值 + foodPenalty + leisure + homelessPenalty + corpsePenalty + timedMods, 0, 100)`。

每次仅把 `currHappiness` 向 `target` 增减 **1**，再将非 AI 陆块的当前幸福取等权平均得到 `KingdomHappiness`。这里住宅均值按**房屋**而非居民人数加权，王国均值按**陆块**而非陆块人口加权。空住宅不参与住宅均值；没有已入住住宅时住宅项为 50（3349–3367）。

其他负反馈有明确数值：

- `UpdateFood()`（4352–4366）：有缺餐住宅每次 −2，否则 +1；下限取人口规模插值（−25 至 −35）和 `−int(缺餐住宅数×0.5)` 的较大值，最终不超过 0。
- `UpdateHomelessHappiness()`（4369–4386）：无家人口 >2.5% 时每次 −2，否则 +1；下限 `clamp(−无家人数, −35, 0)`。
- `UpdateDeadBodyPenalty()`（4389–4401）：已提示、未被搬运、属于该陆块的尸体逐个计数，上限罚 15。
- 生存及更高难度中，`KingdomHappiness <35` 连续累计到 >500 模拟秒会切入失败菜单；回升到 ≥35 时失败计时每秒减 2（2387–2420）。

### 4.3 人口由到港结算，并受空房和社会状态约束

`Player.UpdatePersonArrival()`（3587–3671）先为无家者安置，每次最多安置一人；各陆块移民计时可受总督 SettlerShipRate 特质修正。所有者住宅容量至少 15 或已过第一年，且陆块有建筑才派移民船（3661）。候选人数（3712–3716）：

`max(3, Range(3,5) + int(min(本陆块人口×0.075, max(int(历史年度最大老死数×1.1),35))))`。

`SettlerShip.CalculateSettlerAmount()`（327–427）用“目的陆块当前幸福 + 玩家所有陆块总人口规模修正”计算吸引力。总人口 <25 加 30、25–49 加20、50–74 加10、75–299 加0、300–749 −3、750–999 −7、1000–1499 −10、≥1500 −13。袭击进行中或有 `vikingattack` modifier 时拒绝移入；吸引力 <35 会尝试带走 3–4 人；35–49 有随机流失；≥50 才按候选逐人随机接受，并被目的陆块可用住宅位数封顶。这个闭环支持“缺餐/税负/尸体 → 幸福下降 → 移民停滞/流失 → 劳力和生产受压”的设计判断。

人口也会老化：`Villager.Init()`（500–526）按一年长度随机初始化显示年龄和剩余寿命；`UpdateMind()`（1394–1416）每秒扣 `life -= dt × Lerp(1.2,0.8,health)`，健康越高寿命消耗越慢；`Player.Update()` 在 life≤0 后入老死队列（2469–2471），最终人口 >5 才执行老死（2606–2618）。未在本次已读链发现生育调用；不能据此声称整个程序集绝无生育系统。

## 5. 税收、生产与工作调配

### 5.1 税收是覆盖与用工驱动的住宅收入

实际建筑税率 UI 的 `BuildingTaxUI.cs:51 Awake()` 绑定每次 ±0.5，`AdjustTaxRate()`（260 起）将选中税务所 `TaxOffice.Rate` 限制在0–3；`RefreshVisuals()`（213）乘20显示为0–60%，每档10个百分点。`Home.GetTaxRate()`（791–807）取住宅占地中最大的税务覆盖。`TaxOfficeManager.GetTaxOfficeCoverageWithStaff()`（180–212）对覆盖税务所取 `Rate × GetWorkerPercent()` 的最大值，故税收受税务员工不足影响，重叠税务所不在这一步直接叠加。`Player` 另保留陆块税率数组及增减方法（4778–4814），且AI仍写入该数组；住宅当前收税路径读取的是税务所覆盖，不能用遗留陆块字段替代实际税收公式。

`Home.Tick()`（1243–1257）每默认 56.25 秒（216）累加：

`taxRev += effectiveRate × taxYield × 居民数/容量 × 总督税收倍率`。

当累计 ≥1 时 `RoundToInt` 入所有者金币。`GetHappinessFromTax()`（437–464）的区间罚值为 0、−3、−7、−15、−20、−35、−50。`LandmassOwner.Update()`（469–471）每帧把金币截到 `MaxGoldStorage`，金币上限和产业仓储上限分离。

### 5.2 通用加工生产器

`ProductionBuilding.OnEnableInternal()`（253–268）绑定 `YieldProducer.OnYieldResources`。`CheckProductionPipeline()`（238–240）在“输出堆 + 基础产量 > 堆容量”或输入不足时暂停。`OnYieldResources()`（160–180）实际扣输入 cost，输出添加到 GraphicalResourceStack，并登记生产/消费统计。

`YieldProducer.UpdateYield()`（140–188）每 8 帧分摊一次，把 `dt×8` 纳入生产，必须建筑开启、有员工、处于工时；普通进度为：

`YieldTimer += dt × WorkersAllocated/WorkersForFullYield`。

若要求一定人数到达，则再乘 `clamp(已到岗人数/requiredAtDestination,0,1)`。累计超过 `YieldInterval × YieldIntervalMod` 后 `DoYield()`（105–127）产生 `Yield + 占地内最大生产加成`，加成取最大而非全部半径加成求和。工具加成将间隔倍率设为 0.75，默认 100 秒后检查是否继续消耗工具（130–181）。

农业使用不同的 `YieldProducerSeason`：夏/春（季 ID 0/3）积累 `dt/(该季duration×2)×workerPercent`，秋季在默认 72% 季节时长后兑现 `int((YieldAmt+最大半径加成)×actualYieldPercentage)`（`YieldProducerSeason.cs:72–125`）。所以通用作坊的“工时每周期”与农业的“季节累计后收获”不能混为一套公式。

`JobSystem.Update()`（452–593）逐陆块、按优先级遍历工作类别，更新岗位分配、人数上限和员工行为；若高优先级缺人且没有自由劳力，每 0.1 非缩放秒的 assignmentTimer 触发后，从低优先级类别倒序释放一个非手动员工（543–570），袭击/敌对状态下保护战斗岗位。手动岗位和类别开关会影响自动调配。暂停时仍存在按 unscaledDeltaTime 触发的岗位重排机会，这是静态调用特征，未验证 UI 实际效果。

## 6. 物流与贸易

### 6.1 实物运输采用目标库存请求和路线状态机

`LogisticsManager.GetLogisticsForBuilding()`（310–355）为目标建筑建立资源请求量、来源建筑列表；`TryAddSourceToLogistic()`（359–366）添加来源并更新车辆路线。`ValidSourceBuildingForVehicle()`（200–210）将陆运限制在同陆块，船运另查允许的运输建筑。

`LogisticsVehicle.InternalCollection()`（269–321）只在两端建成、目标接受类型、请求量>0、来源公开存储该类型时取货：

`pickup = min(max(0,请求−目标现存), 目标空位, 来源现存, max(0,maxStorage−车内该类型现存))`。

默认 `maxStorage=50`（105），该限制在已读代码中是**每资源类型**计算，不能直接声称全车合计只能装 50。`GetCollectionForRoute()`（324–340）实际从来源扣除并加入车内。`Tick()`（400–471）状态从闲置→检查→前往取货→取货→前往卸货→卸货；检查阶段每120帧一次，卸货调用目标 `Deposit`，无法容纳的余量生成散落资源堆，再寻找下一条可供货路线。库存不瞬移，路线、载体与工人配送构成资源可达性约束。

### 6.2 商人交易具有手动与自动两条实际代码路径

`MerchantShip.StartSailing()`（95 起，142–179）按资源 ID 随机设买卖价格；`Tick()` 在靠港处理中调用 `MerchantOrdersManager.DoAutomatedOrders()`（337）。手动购买 `MerchantUI.OnCompleteBuyTransaction()`（400–463）从船舱扣货，优先存港口库存，余货每30件一堆卸在岸上，再计算科技折扣/扣金币；手动出售（511–535）从码头装货仓扣物资、加船舱、加金币和统计。

自动订单（`MerchantOrdersManager.cs:90–138`）不是“每次固定买/卖 N”：type 0 在码头现存低于目标时买差额，购买量取 `min(金币/单价,目标−现存)`；type 1 在现存高于目标时出售超额。自动购入在已读代码内直接生成资源堆，没有对应 `hold` 扣减；采购统计却写 `orderEntry.amount` 而非实际采购量（117），因此统计显示不等于实物变化。这些是候选缺陷线索，需要结合 IL/运行测试确认，不应把“自动补货可无限买”直接当成已验证玩法。

资源定义来自 `FreeResourceSystem.OnEnable()` 的 `Resources.Load<ResourceDefinitions>("ResourceDefinitionList")`（101–104）。实际 `resources.assets:52636` 已严格按托管序列化结构解析出21项（`outputs/resource-definition-summary.json`），ID映射如下。内部名是资产事实；中文为本文直译，未当作游戏本地化原文。

| ID | 内部名（中文释义） | ID | 内部名（中文释义） | ID | 内部名（中文释义） |
|---|---|---|---|---|---|
| 0 | wheat（小麦） | 7 | armaments（军备） | 14 | marble（大理石） |
| 1 | tree（木材资源） | 8 | fish（鱼） | 15 | clay（黏土） |
| 2 | stone（石材） | 9 | apples（苹果） | 16 | pottery（陶器） |
| 3 | charcoal（木炭） | 10 | ham（火腿） | 17 | dirt（土） |
| 4 | gold（金币） | 11 | bread（面包） | 18 | olives（橄榄） |
| 5 | iron（铁） | 12 | grapes（葡萄） | 19 | oliveoil（橄榄油） |
| 6 | tools（工具） | 13 | wine（葡萄酒） | 20 | salt（盐） |

资源的携带容量、是否次级资源、过期标记也已提取；各建筑 cost/Yield/diet 仍受其Prefab序列化数据支配，21项资源清单不等于完整配方和成本/产能平衡表。

## 7. 神祇、任务和风险事件

神祇数组有 9 个槽位（`GodManager.cs:420`），但不能据此声称9位都有完整任务。`Reset()`（518 起）显式构建各任务列表；例如 Jupiter 槽位2从人口20、建2座 temple、人口30、献10金币开始，继续人口50/75/100/200/500/1000/2000与建筑/献祭等任务（559–664）。Ceres 槽位5实际配置农田、粮仓、葡萄园、面包房与献祭任务（666–749）。这些实例比类名/神像更能证明任务内容。

任务链：`AcceptNextTask()`（1912–1932）设置当前序号、跳过可跳任务并调用 `AcceptTask()`；`PopulationTask.AcceptTask()`（22–25）把目标增加 `已完成任务数×5`，进度按玩家所有陆块人口总和/目标（33–45）。`GodManager.Update()`（1699–1716）只在进度≥1时显示可完成提示，**不会直接自动交付**；`GodUI` 收到 `GodTaskComplete` 对话结束才调用 `CompleteCurrTask()`（439–441）。献祭任务 `Complete()` 扣资源并登记消费（`OfferingTask.cs:98–104`）；`CompleteCurrTask()` 计数/里程碑并在该神任务耗尽后强制解锁 `unlockkey_temple2`（1864–1874）。奖励数值送入 DialogueLua `Var1`（`GodUI.cs:624`），`ShowFavorPointsGained()`（1030–1037）将其转为 `Player.GiveProsperityPoints`；此奖励方法何时由对话资源调用需再核对 Dialogue Database。

宗教压力随人口扩张：`Player.UpdateGodAnger()`（2940–3016）计算 temple/temple2/temple3 分别1/5/15荣誉，按所有者人口与已有崇拜神数量构建 angryGods。`GetHonorGoal()`（3060–3083）在 <300/<500/<1250/<3000/更高人口分档要求1/3/5/8/19荣誉。`UpdateGodHonor()`（3028–3055）在没有建造/模态打断时抽取怒神出现。

`SpawnGodAngerAtCam()`（2048–2118）受神怒难度、禁用标志、冷却、同神已出现、目标地块及距离约束；第一次 escalation=0 仅 Warning，后续变 Damage，并设置赎罪金币为 `int(25+目标陆块人口×0.5+Range(0,3)×5)`。静态惩罚路径（`GodMessage.Tick()`，247–389）包括 Jupiter 雷击起火（298–305）、Vulcan 起火（307–315）、Ceres 清空季节产量/腐烂并诅咒田地（317–344）、Apollo 在位置附近引发疾病（358–369）；Neptune 调用加水，细节由水利报告覆盖。实际触发频率和表现未运行观测。

`ThrowFestival()`（1587–1591）重置对应神 escalation、冷却 +600 秒、累计节庆次数；`GetFestivalCost()`（1594–1670）金币基础成本为 `人口/5 + 年份/5 + 同神已办次数×25`，再按神和人口档附加物资。这个函数给出的是成本计算，资源扣除和完整 UI 流程应结合节庆调用者进一步验证。

疾病与灾害也进入人口—幸福闭环：`Player.Update()`（2492–2555）累积病程，邻近3×3地块尝试感染，治疗达到阈值时随机治愈/死亡；瘟疫结束后施加60秒、每死者−2、最低−50幸福 modifier（2597）。`UpdateRandomEvents()`（3802–3869）40人口门槛、默认160秒计时、随机筛选后选择实际村民销毁并输出事故消息；不是只有叙事文本而无状态改变。

## 8. 值得继续核验的静态异常

这些结论是“当前反编译文本中的不一致”，没有宣称运行时 bug 已复现。

| 位置 | 观察 | 精确核验目标 |
|---|---|---|
| `Home.cs:452 GetHappinessFromTax()` | 用 `taxRate == 2f && taxRate <2.5f`，没有覆盖2–2.5之间所有浮点值；税务员比例确实可生成分数税率 | 在税率3、非满员税务所制造有效2.1等值，检查住房税罚；必要时对照IL排除反编译误差 |
| `MerchantOrdersManager.cs:117` | 自动买入统计记目标 amount，实买量却是金币限制后的 num3 | 目标100、现存90、只买10时对照生产统计 |
| 同文件 `109–124` | 自动购买读取 hold 却不在分支中扣 hold，且不按船舱余量夹限 | 对照同次靠港前后船舱、金币、岸上堆；确认设计是否故意把自动订单作为特殊供货 |
| `OfferingTask.cs:31–47 ResourceProgress()` | 把全部需求类型“现存总和/需求总和”作为进度，没有逐资源夹限 | 当前硬编码任务已读样本多为单类型；只有存在多类型献祭时才需验证能否用单一过量资源误报完成 |

## 9. 扩展功能覆盖：入口证据与可达性边界

下表只确认具体代码调用链存在。Unity 的 `Update` 方法是否挂在当前加载场景、功能是否被科技/场景关闭，需要资源或运行证据；它不等于对每项宣称“当前地图均可游玩”。

| 功能 | 已观察的入口与状态变化 | 当前结论与未知 |
|---|---|---|
| 神祇 | `Player.Update()`→`UpdateGodHonor()`→`SpawnGodAngerAtCam()`；任务由 `GodManager.Update()` 提示、`GodUI` 对话结束交付；详见前章 | 有实际任务实例、更新和数值/灾害效果，超出保留类名证据；9槽位不代表9套完整任务 |
| 战车赛 | `ChariotRaceTrack.cs:536 Tick()` 只在已建成后推进，Resting 且工时内/满员时进入 StartRace（546–548）；`SetStatus()`（461）生成名次与路径；`GenerateCharioteerFinishingPositions()`（995–1002）在开赛时按权重抽取4名次，再由路径曲线呈现 | 存在可运行状态机和投注/赞助 UI。`ChariotRaceTrackUI.cs:372–381 SetStatus(3)` 在完赛扣赞助金币，所选车手 `predictedFinishPos==0` 时实际发放 `GiveProsperityPoints(rewardAmt)`；862–898响应完赛并显示结果。名次是在开始时抽取，不是车辆物理碰撞实时决定的完整物理竞速 |
| 征战外交 | `DiplomacyUI.cs:379 DeclareWar()` 设置关系 Enemy，384 EndWar() 设 Neutral；`World.cs:5794 SetRelations()` 对称更新外交矩阵，通知AI宣战、清任务、降低关系并关闭双方码头（5818–5835）；`Intention_ManageInvasion.cs:92 Tick()` 在敌对关系时请求军队/弓手/投石车，满足后建立波次目标（96–114） | 存在从外交动作到贸易中断和军事建设/波次的状态链；没有仅凭 `ChamberOfWar` 类名推定完整征服流程。占城、胜负条件及全部玩家指挥UI未深入验证 |
| AI王国 | `AIKingdom.cs:961 Update()` 更新资源分配、布局；1103–1107推进单位控制及 `IntentionManager.Tick()`。`StartBaseIntentions()`（1119–1179）实际创建供粮、住宅、防火、医疗、幸福、储存、贸易、入侵、外交意图 | 有实际AI调度入口，非仅保留 `AIKingdom` 数据类。外交 `Intention_ManageDiplomacy.cs:328 Tick()` 75人口门槛、关系/性格和目标计时控制对话/访问/通商请求。是否当前配置启用了对手槽位与实际AI强度未运行确认 |
| 怪物/入侵 | `DragonSpawn.cs:188 Start()` 订阅季节广播；`OnSeasonChange()`（207–245）排除和平/禁用/已有龙条件，过人口阈值后实际实例化幼龙/母龙；`Update()`（269–310）移除结束龙并重设下次袭击年份/升级。`RaiderSystem.cs:822 Update()` 遍历入侵部队并更新目标，`Player.OnSeasonChanged()`（3686）每年调用 `RaiderSystem.OnNewYear()` | 龙和入侵者均有季节/Update入口与实体生命周期；仅证明这些已读怪物路径，不代表全部怪物类均启用。难度和创意选项控制可达性；没有对当前地图实际袭击做观察 |
| 灾害 | 神怒确实调用雷击、起火、田地诅咒和病疫；`Player.Update()`（2443–2446）调用自燃、随机事件、瘟疫。火山 `VolcanoManager.cs:135 Update()` 切换喷发/冷却并调用熔岩产量（156/179）；其 `TriggerEruption` 在整个反编译 C# 中检到的外部调用仅 `DemoScenario.cs:121 OnLineStart()` | 火灾/病疫有正常模拟入口；火山有真实实现及Demo场景触发链，但当前范围未找到通用随机火山调度，不能把 DemoScenario 的存在推定为所有自由地图上的可触发灾害 |

## 10. 验证记录与剩余未知

本分报告执行 `rg` 定位、PowerShell 按行读取并精读上述因果链，并读取并核对其他资产提取分工产出的资源和季节JSON；没有运行游戏、没有性能采样、没有自动化玩法测试，也未修改任何原始游戏文件。最小充分验证是将关键结论落实到实际调用方、分支条件、状态变化与数值公式，并以已解析资产校准资源ID和季节/时间档位；关于性能、任务对话资源回调、完整资源配方和异常复现仍明确保留未知。

适合后续的高价值验证依次为：读取已用 Prefab/ScriptableObject 序列化参数以还原真实经济表；仅对上表候选异常进行定点运行复现；再对大人口保存点做一次固定场景 CPU/GC/寻路等待采样。不能从本静态报告推导实际大城性能上限。
