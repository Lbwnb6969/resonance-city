# Round209 古典门洞与稀疏凹窗夜光

独立生成 32 张四向夜光 PNG 与 `资源/精制河湾/夜光/manifest.json`。原主 manifest 和 32 栋建筑的 PNG、SVG、阴影、接触阴影及对应 import 共 256 文件保持 Round208 哈希。生产 Catalog、子 Sprite、时代条件、听到之后的完整揭示与实窗验证由 Root 负责。

生成入口：`python -B tools/build_refined_valley_art.py --emission-only`。该参数在既有房屋/树生成之前返回，不重烘焙旧资产。新 manifest 以既有 id 对应，提供 `emission_texture`、`emission_origin`、`emission_pixels_per_world`、新旧 PNG SHA256、真实朝向与入口、可见部件计数。同尺寸/原点/ppu 与原 Sprite 重合，运行时挂在同一个建筑本地层级，不能用全局置顶画光。

独立小发光面放在原门洞木面或原凹窗面前方 0.0005 模型单位，四向使用同一真实旋转。候选凹窗必须与原生成几何的凹洞面逐顶点匹配，并经过独立最近三角射线判定；每栋最多选择一个可见真实凹窗。所有原建筑面作为不发光黑色不透明 BSP 遮挡，包括屋顶、翼墙、柱廊、窗框、百叶。只在 BSP 可见的小面内做柔和亮度下降，最后裁到原 PNG alpha。没有屋顶发光、外部光圈、现代玻璃网格或新造凹窗。

颜色为直通 alpha `#FFC982`；门峰值 0.56、商铺凹口 0.46、窗 0.30，字节量化最高 143/255。原门框、百叶与门的其余部分保留底图。生产再乘一次夜间强度和已听到的完整揭示值；父节点夜间 RGB 的补偿由 Root 子 Sprite 集成执行。全部新 PNG import 启用 mipmaps 与 alpha border fix，并已通过真实 Godot 资产导入。

32 个角度全部至少有一个真实可见凹窗，12 个角度还可见门洞；20 个背面或院落角度的原门被墙/翼墙遮住，保持暗。两种院落款四向都不强迫照亮院中遮住的门。单张亮区占原建筑不透明面积 0.343%–1.603%，离线预览在 `四向夜光接触表.png`，它是资产合成图，不是生产窗口，也不是用户审美验收。

命令与结果：

- 生成命令完成，32 masks；原主 manifest + 256 building files unchanged / PASS，细节在 `generation.json`。
- `D:/GODOT/Godot_v4.7.2-stable_win64_console.exe --headless --audio-driver Dummy --path . --editor --import --log-file 验证记录/round209_古典夜光资产/import_dummy.log` 退出 0，32 新 PNG 完成导入，无 SCRIPT ERROR、Parse Error 或 ERROR。
- `D:/GODOT/Godot_v4.7.2-stable_win64_console.exe --headless --audio-driver Dummy --path . --script res://tests/round209_emission_assets.gd --log-file 验证记录/round209_古典夜光资产/emission_dummy.log` 退出 0，10/10。一次性解码检查 28,812,288 像素，153,624 亮像素全部满足底图 alpha 边界和暖色/亮度上限；32 hash、原点、朝向、ppu、mipmaps 与旧 257 文件哈希通过，细节在 `asset_contract.json`。

生成时 147,965 个较亮像素使用独立三角深度复核，最小一致率 99.9868%；两张 gabled 朝向各有一个栅格边界采样差异，共 2 点，其余为 100%。该证据验证完整实际几何参与遮挡，允许 raster 边缘抗锯齿差异。Dummy 脚本对源码 PNG 做检查，因此 Godot 产生 64 条 raw image export 警告；生产通过已导入 Texture2D 加载，不使用这一检查脚本。

首版固定后窗选择导致院落角度无可见亮区的生成中止记录和 9 张旧尝试 PNG 已保留于根目录 `废弃/美术/round209_门洞夜光首版/`，不参与新 Catalog。最终生成改为从已有真实凹窗中选一个可见窗。原建筑基底从未重生或替换。

Root后续生产实窗21/22覆盖实际夜色与可听揭示，切城漏挂mask修复后受影响检查11/11，见 `验证记录/round209_古典夜景/README.md`。独立图审未见穿光/泛光/角度违和；当前文化馆侧背身份偏住宅、夜色灰暮与远景暖光偏轻仍待深化。这里的资产合同不替代实窗检查，不包含真人试玩结论。
