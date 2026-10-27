# 证据、复核与交付记录

分析目标是本机 `D:\SteamLibrary\steamapps\common\Nova Roma` 发行构建 0.7.2963。分析工作区为本文件上级工作区。证据类型分为：**文件字节/元数据观察**、**代码静态行为**、**场景序列化配置**、**隔离算法执行**和**分析推断**；静态分析没有观测真实游戏执行。

## REA 原始证据

完整会话证据已导出为 [rea-evidence.json](rea-evidence.json)，共 5 条记录。

| ID | 操作/目标 | 结果与边界 |
|---|---|---|
| `ev_47e1300ac96a840e61d30a965f7aa4307c97477b861065c1ad65cb6b771ed37a` | inspect_managed_artifact / Assembly-CSharp.dll | 元数据完整；Unity Mono、AnyCPU、CIL；2,620类型、19,365方法。不是 C# 反编译/执行证据 |
| `ev_43bb4d9cc10d9cf0cac5cc81cbdffcef881300f4086be5a1d04a6ee81e888f24` | inspect_managed_members / Assembly-CSharp.dll | **unavailable**；metadata.representation 超过67,108,864 bytes预算。返回空成员数组不能解释为程序集没有成员 |
| `ev_0ba21d291d2fce70935a4fac922da7736da173b63c6561e01e44dad578a0c42e` | inspect_managed_artifact / Roma.Aqueduct.dll | 元数据完整，7类型、38方法；仅 netstandard 引用 |
| `ev_7cb1bf6cf258044cf3ece0689b940d6d80aad9ace1f514199d8d74bc41d80fc2` | inspect_managed_members / Roma.Aqueduct.dll | 报告整体 **partial**；38方法 body=present，267 call edges，未报 instruction truncation。保留其声明的签名解析限制，不升级为完全覆盖 |
| `ev_267a1ea7cd1648941b32cfb185f366a0e81415d976ed47d2fb840105ca9dfdcc` | inspect_managed_artifact / Assembly-CSharp-firstpass.dll | 元数据完整；1,410类型、10,004方法；含基础库和第三方代码 |

先检查了 REA 会话，未打开原生反汇编数据库；本次没有需要结束的已打开原生会话。大主程序集成员调用达到预算限制后没有重复同一请求，改用独立 ILSpy 分析补足。REA 原始证据仍保留这次失败，未假称所有主方法已被 REA 验证。

## 命令与结果

命令从工作区执行，游戏目录只读。按依赖顺序运行，以下是便于复查的归并记录，不是全部 shell 输出的逐条转录。

| 操作 | 代表命令/工具 | 已取得结果 |
|---|---|---|
| 发行盘点 | `Get-ChildItem`；Python pathlib/csv/hashlib | 313个文件的相对路径、大小与SHA-256 |
| 本地分析 Git | `git init`、`git add`、`git commit` | 建立本地历史，备份报告、解析脚本和反编译副本；未对游戏安装目录建仓库 |
| C# 分析器 | `dotnet tool install ilspycmd --tool-path .\work\tools` | 本地工具目录安装 ILSpyCmd 11.1.0.9782；不修改游戏 |
| 主反编译 | `work\tools\ilspycmd.exe -p -o work\decompiled\main <Managed\Assembly-CSharp.dll>` | exit=0，错误输出文件0 bytes；1,320个C#文件 |
| firstpass 反编译 | 同命令，输入Assembly-CSharp-firstpass.dll，输出firstpass | exit=0，错误输出0 bytes；949个C#文件 |
| 渡槽反编译 | 同命令，输入Roma.Aqueduct.dll，输出aqueduct | exit=0，错误输出0 bytes；3个C#文件 |
| 调用链核对 | `rg --files` / `rg -n` + PowerShell逐行读取 | 具体入口、条件、状态修改和公式见3个代码专题；没有仅由字符串推导启用功能 |
| 资源分析 | `python work\analyze_assets.py` 等；UnityPy 1.25.4、pefile、TypeTreeGeneratorAPI | 文件哈希、原生PE导入、资源类型/路径、场景挂载与关键参数 |
| 代码清单 | `python work\build_code_index.py` | 2,272个重建C#文件，逐文件SHA-256与行数 |
| 算法实验 | `dotnet run --project work\solver-probe\solver-probe.csproj -c Release` | 原版Roma.Aqueduct DLL在.NET 10.0.2下4/4用例符合预期；见solver-cases.json |
| 原件/交付验证 | `python work\verify_analysis.py` | 313原文件重新核对SHA-256、JSON/gzip解析、代码清单与报告链接，结果见validation-results.json |
| Git 格式检查 | `git diff --cached --check -- .gitignore outputs 'work/*.py' work/solver-probe/Program.cs work/solver-probe/solver-probe.csproj` | 报告/分析脚本检查exit=0；仓库设置cr-at-eol保留Windows换行。ILSpy重建文本与归档原始证据自身含行尾空白，保留原样而不改变源索引哈希；诊断存于work/evidence |

“反编译进程没有错误”只表示工具完成这次转换，不保证重建文本是原始源码或项目能编译。没有运行成百上千个重复测试，也没有把静态扫描替代真实玩法验证。

## 可直接复用的证据文件

- [安装文件哈希清单](file-inventory.csv)：再次分析或 Steam 更新后比较版本的基线。
- [代码清单](code-index.json)：main/firstpass/aqueduct 的反编译文件索引、大小、行数和哈希；文件正文在工作区 work/decompiled。
- [Unity对象摘要](unity-asset-summary.json)、[压缩对象目录](unity-object-catalog.json.gz)、[Resources路径](unity-resource-path-index.json)：资源组织和定位依据；没有导出纹理/网格/音频本体。
- [场景组件证据](target-component-evidence.json)：MonoScript→MonoBehaviour→GameObject→祖先激活状态。
- [关键组件字段](focus-serialized-fields.json)：按交付程序集生成schema后读取DynamicWater等具体对象；仅保留选择字段值与字段名。
- [资源定义](resource-definition-summary.json)：21项ID/内部名与选定标量；[季节和倍速](season-settings.json)：实际序列化配置及本地化解析失败记录。
- [原生依赖](native-dependencies.json)、[音频bank清单](audio-bank-inventory.json)、[内嵌文本元数据](embedded-text-assets.json)。

原始大对象/设置 JSON 保留在 `work/evidence/`，对外报告使用精选摘要；服务认证命名字段仅记录存在，不展示或测试认证值。场景 oauth 等字段仅保留字段名。没有进行网络凭证有效性验证。

## 查找边界与剩余未知

1. 主逻辑精读范围以专题中具体文件/方法为准。没有对全部第三方/原生DLL逐函数反汇编，也没有穷举每个任务、建筑或UnityEvent。
2. MonoScript/场景搜索覆盖所列发行场景与资源容器；未找到引用表示该覆盖内未找到，不排除反射、动态加载或运行时生成。
3. PlayerSettings 有尾部布局覆盖限制；已解析的选定字段与其他证据交叉核对。自定义schema生成器的基础头部对齐差异已通过替换标准UnityPy头部修正，再次严格完整读取后关键标量一致；场景引用图也独立使用标准头部。该修正不代表所有自定义脚本均已解析。
4. I2本地化资源复杂schema解析失败，未产出完整中文本地化表；资源内部名不是用户界面中文名。
5. 对象数量是包中记录数，不是实际运行实例数；场景初始active状态也不是运行全过程状态。
6. 4个求解器实验只覆盖明确输入，未验证真实Unity/Mono集成、压力/循环图、性能或全部水量守恒性质。
7. 当前账号候选玩家数据目录不存在，未读取真实存档、执行迁移、测量帧率/GC、触发游戏后端或上传内容。存档失效窗口、经济分支不一致均按静态线索描述，没有宣称复现。

Git备份只存在本地，未推送远端。分析没有删除游戏、用户数据或重要分析证据。

最终复核：[validation-results.json](validation-results.json) 中7项全部通过；313个原文件SHA-256与初始清单完全一致，没有新增或缺失文件；2,272个重建C#副本与代码索引哈希一致；137,422条压缩资源目录可解析；报告文件链接存在；4/4算法用例通过。报告/脚本Git格式检查另行通过。原件哈希检查完成之后仅继续修改分析文档并写入本地Git。
