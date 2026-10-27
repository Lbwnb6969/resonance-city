"""Program-level GPU coverage and recovered formula evidence, not original HLSL."""
from pathlib import Path
import json,re,collections
BASE=Path(__file__).resolve().parent.parent;OUT=BASE/'outputs'
manifest=json.loads((OUT/'townscaper_shader_programs/manifest.json').read_text(encoding='utf8'))
business=[s for s in manifest if s.get('name','').startswith(('Placemaker/','PlacemakerUi/','Hidden/Ao','Hidden/ShadowBaker','Hidden/MarchingSquares'))]
def asm(id,index=1):
    s=next(s for s in business if s['source']=='sharedassets1.assets' and s['path_id']==id)
    p=next(p for p in s['programs'] if p['index']==index)
    return '['+s['name']+' '+str(index)+']('+Path(p['assembly']).relative_to('outputs').as_posix()+')'
def table():
    rows=['| 业务 Shader | 程序/像素程序数 | 像素字节码与主要路径 |','|---|---:|---|']
    for s in business:
        ps=[]
        for p in s['programs']:
            code=(BASE/p['assembly']).read_text(encoding='utf8')
            p['stage']=re.search(r'([pv]s_\d_\d)',code).group(1)
            if p['stage'].startswith('ps'):ps.append((p,code))
        paths=[]
        for p,code in ps:
            ops=collections.Counter(line.strip().split()[0] for line in code.splitlines() if line and not line.startswith('//'))
            features=[]
            if any(k.startswith('sample') for k in ops):features.append('texture '+str(sum(n for k,n in ops.items() if k.startswith('sample')))+'采样指令')
            if 'deriv_rtx' in ops:features.append('屏幕导数')
            if 'discard_nz' in ops:features.append('discard')
            if 'loop' in ops:features.append('循环 '+str(ops['loop']))
            paths.append('['+str(p['index'])+']('+Path(p['assembly']).relative_to('outputs').as_posix()+') '+(' / '.join(features) or '常量/插值色'))
        rows.append(f"| {s['source']}:{s['path_id']} {s['name']} | {len(s['programs'])}/{len(ps)} | {'; '.join(paths)} |")
    return '\n'.join(rows)
text=f'''# GPU 发布程序、AO、阴影与材质像素算式

从 Unity Shader.compressedBlob 按平台 offsets/compressedLengths/decompressedLengths 做 LZ4 解压，读取 Unity 2020 程序目录，截出 DXBC header 指定总长度，使用本机 d3dcompiler_47.dll 的 D3DDisassemble 解释真实程序。94 个 Shader 对象中 88 个可读、525 个 DXBC 程序全部成功反汇编；6 个 unity default resources 对象读取失败属于 Unity 引擎边界（17、68、69、70、10101、10755）。{len(business)} 个 Placemaker/PlacemakerUi/业务 Hidden Shader 的全部 {sum(len(s['programs']) for s in business)} 个程序均已恢复。

[程序与哈希 manifest](townscaper_shader_programs/manifest.json) 保留 shader 对象地址、平台、program index、keyword/local keyword、DXBC 大小与 SHA256；每个 .asm 对应独立 .dxbc。每个 Shader 的 .parsed.json 保留 Pass、blend/depth/stencil/cull 状态和 Properties；.decompressed.bin 保留 Unity 程序尾部常量/纹理绑定数据。最初导出的 “shader disassembly not supported on DXBC” 是 UnityPy 转换器省略实现，实际游戏程序并未缺失。这里恢复的是发布 GPU 程序，不是原作者 HLSL 文本。

下面以 `C[n]` 表示当前程序 CB0[n]，`Tn` 表示纹理寄存器 tn，`Vn` 为该文件 input register vn；不同 shader 的寄存器绑定不能互换。`sat(x)=clamp(x,0,1)`，`fw(x)=abs(ddx(x))+abs(ddy(x))`。`sample` 的过滤/寻址服从实际 sampler state；`sample_l` 明确指定 LOD。这样公式可直接和真实指令逐项核对，未靠参数名字猜寄存器。

## 全部业务 GPU 程序

{table()}

## Marching squares 着色与 AO 图集

{asm(173)} 的像素公式非常短：`S=T0(uv)`；材质条目 `i=floor(17*S.r)`；取 `P=T1(((i+0.5)*C[15].x, 0.5*C[15].y), LOD0)`；令 `B=(0.8*P.rgb,0)`，输出 `B + S.a*(1-B)`。这是量化材质索引查色表，alpha 覆盖把结果推向白色，不是模糊操作。

{asm(167)}：输出 `1+C[41].w*(T0(uv)-1)`。覆盖值由顶点/常量提供，像素阶段对采样颜色做线性衰减。

{asm(156)}：局部切片 UV `q=V1.zw`，导数宽度 `d=fw(q)`，当 `C[29].z<1` 时 `a=min(sat((0.5*C[29].z-abs(q-0.5))/d))`，否则 a=1；a<0.01 discard；RGB=`1+C[41].w*(T0(V1.xy).rgb-1)`。alpha 的切片矩形边界用屏幕导数抗锯齿。

{asm(177)} 的真实循环是 i,j=-2..2 与 k=-1..1，合计75邻域。设切片 tile 大小 `s=C[2].xy`，横向 tile 数 `N=C[2].w`，世界到图集缩放 `p=C[2].z`，当前 slice=`floor(u/s.x)+N*floor(v/s.y)`。对每个偏移 `(i/2,k,j/2)`，权重 `w=1/(sqrt((i/2)^2+k^2+(j/2)^2)+0.03)`；在当前 tile 局部坐标加 `(i/2,j/2)*p` 后 clamp 到 [0,s]；slice 加 k，再按 `slice mod N, floor(slice/N)` 地址采样 T0。负切片用 `lerp(C[9],sample,sat(slice+1))` 退回 uncovered 色。最后 `A=sum(w*sample)/sum(w)`，输出 `(A.rgb*A.rgb,A.a)`。三重循环、反距离归一与 RGB 平方均有直接 DXBC 证据；不存在仅从 AoSpreader 名称推断。

## 方向阴影和水面

{asm(163)} 的第一像素 pass 直接写顶点颜色 V1；{asm(163,4)} 是第二像素 pass，输出 `rgb=1-V1.x*(V1.y<=(2,0.5,0.4))`、alpha=1。ShadowBaker 顶点程序3先乘 object-to-world 和 view-projection；阴影深度 `d=dot(worldPosition, C[30..33].z)`，法线遮挡分量 `n=dot(-worldNormal,C[4].xyz)`；输出颜色 `(1-d,1-n,0,0)`，对应像素按上述不同 pass 的写入/阈值路径执行。它烘焙编码后的深度/朝向，再由业务材质解释，不是普通黑白阴影截图。

{asm(176)} 从四个影图采样中分别逐通道判定 `sample.rgb>=0.999` 得到0/1，再以 frac(V2.xy) 的双线性权重插值。令该结果为 b，则 `h=dot(b,(0.3,0.3,0.4))`，输出 `h+(1-h)*V1`。阈值作用在每个采样点，随后混合阈值结果；把这段替换成普通纹理双线性过滤会改变阴影边缘。

{asm(170)}：令 `q=V0.y+V0.z-0.4*C[0].y`，`e=1-V0.x`，`b=1.4*(e+V3.a-0.9)`；`alpha=sat((2*abs(frac(q)-0.5)+b-1.1)/fw(2*q+b))`，alpha<0.01 discard；RGB=`lerp(V4.rgb,V3.rgb,0.8*e^4)`。时间项、周期三角波、四次距离权重与导数抗锯齿组成水面的条带/边缘算法，不存在像素阶段真实流体模拟。

## 建筑纹理、调色与屏幕边界

{asm(169,2)}、{asm(169,3)} 分别为基础和 `_PIXELSHADOWS` keyword 像素程序（关键词见 manifest）。基础 House 程序首先以 `V1.w+fw(V1.w)<0` discard 处理局部高度边界，再根据屏幕导数构造像素化采样坐标：对纹理像素坐标 X，令 `a=(X+1.5)/2,b=(X+0.5)/2`，两个邻域边界 `L=2*floor(a)-0.5,R=2*floor(b)+0.5`；`k=sat(abs(2*frac(a)-1)/clamp(length((ddx(X),ddy(X))),1e-5,1e5)-0.003/(fw(V1.x)+fw(V1.y))-0.5*(C[19].z-1))`；采样坐标 `lerp(L,R,k)` 再乘 texel size。这个共同算法也出现在 Door/Bird/Fence/Carnival/Plants/Window/Sandbank，具有像素保持和屏幕导数过渡。

House 取 type 纹理 g、main 纹理 m、材质条目色 `P=T2(((floor(abs(U.x))+0.5)*C[15].x,0.25),LOD0)`；`p=sat(P+1.4*g.y*(C[11].rgb-P))`；`x=max(p+dot(m.rgb,(0.2,0.7,0.1))-0.5,0)`；`p=lerp(p,x,m.a)` 后再 `p=lerp(p,m.rgb,m.a)`。随后 UV 边界遮蔽和 AO 输入 V1.z 共同形成乘子，局部高度的导数覆盖参与颜色混合。

多个业务材质末尾采用同一调色链，可从 House/Fence/Carnival/Plants/Bird 的实际寄存器重复序列核验：设 base 为已完成纹理/AO处理的 RGB，`a=0.7+C[29].x*(base-0.7)`；亮度函数 `L(c)=dot(c,(0.2,0.7,0.1))`；先以顶点 alpha 混合灰度和 a，再乘顶点 RGB，令结果 b；`b=b+0.1*(2*L(b)-0.6)`；`b=b+(0.6-b)*(-0.2,-0.05,0.2)`；最终用 C[29].y 在 a 与 b 间混合。Ground/Window 的色调链前端多出颜色通道乘积 `0.3*(r*g,g*b,b*r)` 与 `1.3*vertexColor`，不能直接与 House 视作同一函数。

{asm(179)} Border：采样 S=T0(V1.xy)，`alpha=C[40].w*V2.a*(1-min(abs(S.g-0.7)/fw(S.g),1))`；RGB 固定 C[40].rgb。{asm(180)} Shade：输出 C[42]。{asm(154)} Hole0：四通道均为0.5。{asm(153)} Debris 与 {asm(157)} Voxel：像素直接输出顶点色，主要算法在对应顶点程序。其它业务 shader 的全部像素指令、输入/输出签名和 variant 均在上表；因此短 shader 和复杂 shader 都有可复核的实际程序。

## 原版 D3D11 渲染实证

[最新原游戏运行记录](townscaper_runtime_grid.json)、[此前图形运行记录](townscaper_runtime_graphics.json) 与 [渲染核验记录](townscaper_runtime_render_verification.json) 记录了原版进程的完整城市渲染。Unity 日志明确为 Direct3D 11.0、feature level 11.1，GPU 为 NVIDIA GeForce RTX 5070 Ti Laptop GPU。通过原主线程 `UnityEngine.ScreenCapture.CaptureScreenshot` 保存建造前、建造后、撤销后与重做后四张 2560×1440 PNG，全部成功解码且非单色。核验记录保存每张图的 SHA256；画面包含建筑屋顶与窗户、装饰、鸟、水面与反射、沙洲、阴影及调色/设置UI。

[建造前](townscaper_runtime_render_before.png)、[建造后](townscaper_runtime_render_after.png)、[撤销后](townscaper_runtime_render_undone.png)、[重做后](townscaper_runtime_render_redone.png) 使用原游戏 Shader，恢复的84个 HLSL 程序没有替换原程序。该证据证明原版 D3D11 场景实际完成渲染；水面、鸟等随时间变化，四张图不作为撤销/重做像素一致性证据，也不证明重编译 HLSL 与原 DXBC 的逐像素等价。首次仅捕获启动标志的结果已保留在 `discarded/runtime-first-render-splash`。

## 验证边界

恢复验证为 DXBC 长度/平台/variant 枚举与 D3DDisassemble 成功，业务程序无缺项。进一步的 [全部业务算法报告](townscaper_shader_algorithms.md) 已覆盖34 Shader、84程序、5652执行指令：全部转换为寄存器显式HLSL并成功D3DCompile，包含天空、UI SDF、多通道UI、镜面、粒子和每个vertex/variant。452常量字段与纹理/sampler绑定均按Unity程序参数恢复；4039个立即数分量采用原DXBC token的精确32位模式，168组输入/输出接口与原程序逐项一致。每个程序另有紧凑代数表达式与完整可编译版本。GPU 像素输出、sampler state 与不同后端的最终画面尚未做同图等价比较；模块状态及原游戏截图不能证明重编译shader像素逐位相等。

命令：`python work/extract_shader_programs.py`、`python work/write_shader_report.py`。原 Steam 资产只读。上述均为独立格式解析与系统 shader disassembler 证据，未新增 REA Evidence。
'''
(OUT/'townscaper_shaders.md').write_text(text,encoding='utf8')
print(json.dumps({'business_shaders':len(business),'business_programs':sum(len(s['programs']) for s in business)}))
