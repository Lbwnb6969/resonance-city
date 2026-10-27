"""Human guide for every shader and exact per-program interface/binding/algorithm links."""
from pathlib import Path
import json,re,hashlib,collections,difflib
BASE=Path(__file__).resolve().parent.parent;ROOT=BASE/'outputs/townscaper_shader_algorithms'
meta=json.loads((ROOT/'manifest.json').read_text(encoding='utf8'));programs=meta['programs']
descriptions={
'PlacemakerUi/DistanceFieldUi':'''顶点将 object position 经 object-to-world 与 VP 变换；UV0 取 frac，UV1/UV2 的控制值偏移后传给像素，并保留局部 xy 作为 ClipRect 测试坐标。PALETTE 顶点分支在 UV0.x>=0 时以 floor(abs(UV0.x))+0.5 查 MaterialTex 第一材质行并乘 vertex color；UV0.x<0 时直接用 vertex color。其余三种顶点程序指令完全一致。

像素基于 _MainTex 的距离场，MONOCHROME 使用红通道 s，其余三种使用 alpha s。令 Y 投影方向修正为 -sign(_ProjectionParams.x)，分别计算 UV 和距离场的 x/y 屏幕梯度。各轴 texel 变化率乘1/16，按 |ddx(s)|/(|ddx(s)|+|ddy(s)|) 插值得到 edge width；零梯度分支显式选择0或1。归一梯度方向与固定向量(1.5,2)的点积、1.5倍方向偏移和0.5*max(abs(control),1)构造不同边缘阈值。共同覆盖算式为 Cover(s,t,w)=sat((s-max(t-w*t,0))/(min(t+w*(1-t),1)-max(t-w*t,0)))，每次调用的 t 由控制UV、_AaLineBoth 和 edge width 计算。多层 Cover 分别产生暗边、内填充和外亮边，混合固定黑/白、(0.02,0,0.08,0.2)及暗边(0.82,0.8,0.88)。ALPHA/MULTI/PALETTE 像素代码一致，填充含 sample.rgb*vertex.rgb；MONOCHROME 只以红通道作为距离，并用 vertex.rgb 构造填充。最后乘 vertex alpha，并按 localXY>=ClipRect.xy 和 localXY<=ClipRect.zw 的四条件乘矩形遮罩。每个 Cover 的真实参数顺序在对应 .hlsl 中完整展开。''',
'PlacemakerUi/MultiFieldUi':'''顶点通过 object-to-world 和 VP，传 frac(UV0)、控制UV+1、vertex RGBA。像素取 w=max(texelScaledGradientX,texelScaledGradientY)/32；三个距离阈值为 sat(1-vertex.rgb)，对采样 RGB 分别执行 Cover(sample.rgb,threshold,w)，取三个覆盖的最大值。第二组阈值加入 -w*max(abs(control),1)*_AaLineBoth.z 后再次取最大覆盖，乘 min(abs(control),1)。control 的正负决定基色黑或白，顶点控制的 alpha 参与两次覆盖混合，最终乘 vertex alpha。这是多通道联合距离场，不是三个普通颜色通道直接相加。''',
'Placemaker/Skybox':'''发布 Shader 有两个 Pass。Pass0 顶点方向D=(normal.x,normal.y-0.12,normal.z)，位置=相机位置+10*D后乘VP；背景色=_BgColor+0.5*D.y/length(D)*(1-_BgColor)，并由 _ShadingTexLightStack.y 混合默认(0.5,0.65,0.7)。像素取 q=abs(2*frac(UV.x+UV.y+0.003245*time)-1)，从背景纹理的两组随时间移动坐标采样，两次以三角波在纹理红/蓝通道之间插值；第一层扰动UV.x和UV.y，第二层颜色乘其高度控制。最终 lerp(vertexSkyRGB,grayTarget,layerWeight)，alpha=1。Pass1 顶点方向D=(normal.x,-0.12,normal.z)，背景系数=-0.06/length(D)，像素直接写顶点色。这里是预制噪声纹理+周期运动+背景渐变，没有物理大气散射求解。两组Pass无 keyword，不能按相同keyword合并。''',
'Placemaker/Debris':'''顶点把 tangent.xyz 和 position 分别乘 object-to-world，执行公共 Press 变形。tangent 的投影差在clip.xy上产生屏幕宽度偏移，强度由tangent.w、clip.w和_ScreenParams.y控制；法线+tangent的0.2倍偏移用于AO位置。顶点读取 AO、Shadow、Material 等绑定纹理产生RGBA，像素直接写 COLOR0。屏幕宽度、材质和阴影算法全在 vertex，不能只把短像素程序当完整实现。''',
'Placemaker/Hole0':'顶点执行发布矩阵坐标变换；像素固定输出(0.5,0.5,0.5,0.5)。实际遮挡作用还由Pass depth/stencil/blend状态决定，状态在parsed.json保留。',
'Placemaker/Grid':'''顶点计算 object-to-world/VP，以及两套六边格边界：分别对UV.x-minX、UV.y-minY、-UV.x-UV.y-minZ、maxX-UV.x、maxY-UV.y、maxZ+UV.x+UV.y取最小，再sat形成内外边界权重；normal.xy幅度和投影坐标传给像素。像素以fw导数构造 abs(UV.y-0.5)-0.02 线宽，分别对两组比值/control边界处理轮廓与填充，使用_Grid...实际字段绑定的x/z控制透明度；输出RGB为黑/白边界混合，alpha多层覆盖。完整六个平面距离和像素组合逐条保留。''',
'Placemaker/AoStack':'顶点将局部切片UV和图集UV输出，像素对矩形切片边界做导数抗锯齿，取MainTex颜色后执行1+coverage*(sample-1)。见核心公式报告。',
'Placemaker/Voxel':'顶点执行世界变换、AO体积atlas寻址、阴影/朝向及世界配色，输出COLOR0；像素直接写该RGBA。完整顶点步骤保留，体素显示的颜色不是常量。',
'Placemaker/Door':'''顶点执行公共 Press、法线/切线方向、AO切片与阴影照明；UV类型/层控制参与颜色输出。像素按公共像素保持坐标采MainTex/TypeTex，负采样x直接discard；主纹理乘(1-0.2*l,1-0.4*l,1-0.75*l)，alpha用于两层材质/纹理混合，TypeTex.z控制额外(1,0.8,0)*l亮度。顶点照明与l*(0.6,0.1,0)共同参与公共调色，alpha固定1。门的材质并不是House像素程序简单别名。''',
'Placemaker/Bird':'''顶点处理公共Press、AO/太阳阴影、羽翼/局部参数和normal/tangent空间；像素公共像素保持采纹理，乘1-sat(control)*_Dim.y，再公共调色。随后按controlV0.w在_BgColor与白色间插值，并按V0.z²将身体颜色混到背景辅助色；alpha=min(4*(1-sat(2*V0.z-1)),1)*(1-0.5*sat(-V1.z))。其alpha与颜色控制有明确的二次和分段函数。''',
'Placemaker/Mirror':'''顶点与Splash相同类的镜像路径：公共Press后以 world.y 反号构造镜像坐标；相机方向归一后对xz引入随time/空间的sin/cos位移，水面距离乘0.05限制波动；UV.x>=1选择镜像，否则保留原位置。之后执行AO体积插值、WorldToShadow投影、四点逐采样深度比较及太阳/阴影色配合。像素首先以局部高度+导数discard；公共像素保持坐标以固定LOD2采MainTex/TypeTex，再材质查色；TypeTex.x与height控制在纹理色/材质色间混合，并额外向灰度混合70%。随后公共调色、背景色反射混合，权重V1.z²；alpha=min(4*(1-sat(2*V1.z-1)),1)。镜像几何、波动和LOD2都不能由普通屏幕反射贴图代替。''',
'PlacemakerUi/VignetteOverlay':'''顶点传主/噪声UV与vertexAlpha。像素N=frac(T1(noiseUV).rgb+pi*u+3*pi*v)，noise=0.5*(N+dot(N,(0.2,0.7,0.1)))-0.5；C=T0(mainUV).rgb+0.05*noise；输出RGB=0.5+vertexAlpha*(0.55*C-0.5)，alpha=0.55*T0.a。两个纹理与固定色调/噪声合成均有公式，不只是径向暗角。''',
'Placemaker/NoAlphaBlit':'顶点传矩阵/UV；像素输出(MainTex(uv).rgb,1)。强制alpha=1。',
'Hidden/ShadowBaker':'''四个vertex/两个pixel按Pass和BlobIndex映射，不按keyword。顶点0对世界位置和法线编码阴影数据；像素1直接写COLOR0。顶点2额外处理几何/切线屏幕偏移及阈值辅助量，顶点3使用NORMAL，顶点5用更短输入路径但同阴影矩阵投影；像素4输出rgb=1-COLOR0.x*(COLOR0.y<=(2,0.5,0.4))，alpha=1。每个不同vertex的完整位置/法线算式在独立文件中；Pass progVertex/progFragment BlobIndex对应表列于下方。''',
'Placemaker/FlipVertically':'两个vertex的指令完全相同。无FLIP像素采(u,v)，FLIP像素采(u,1-v)；两者都强制alpha=1。翻转不在vertex。',
'Placemaker/Splash':'''顶点frac(UV0)，传Color0.x作为阈值，时间wrap后构造sin/cos；公共Press后 world.y镜像，worldXZ+0.05*abs(y)*(空间/时间sin和cos)为水面反射扰动，UV.x>=1选择该镜像。继续执行AO/照明并输出颜色/透明度。像素S=MainTex(UV).a、w=fw(S)、t=sat(1-vertexAlpha)、lo=max(t-w*t,0)、hi=min(t+w*(1-t),1)，a=sat((S-lo)/(hi-lo))，a<0.01 discard，RGB直接vertexRGB。波动在vertex，抗锯齿轮廓在pixel。''',
'Placemaker/HoverHightlight':'''顶点用HighlightBoundsUV.xy/z与局部位置构造四控制参数，再矩阵投影。像素a=V1.x-0.07,b=V1.y-0.07，min(a,b)<0 discard；d=min(a*b*V1.z*V1.w-0.005,V1.w-0.1)，q=d/fw(d)，输出RGB恒白，alpha=sat(q)+sat(q-1)*(0.2-sat(q))。两层alpha对应边缘/内部。''',
'Hidden/AoBaker':'顶点执行AO层布局所需矩阵与coverage输出，像素1+coverage*(MainTex-1)。AO atlas采用专用相机，实际配置见原生报告。',
'Placemaker/Dust':'''顶点UV取frac，MIP=4*(1-Color0.y^8)，两个纹理通道混合参数Color0.z。公共Press和AO/voxel图集采样产生照明RGB，alpha额外乘frac(12.5412*Color0.z)*Color0.w与UV.x<=1的门限。像素S=MainTex.SampleLevel(uv,mip)，alpha=lerp(S.g,S.r,V0.w)*vertexAlpha，RGB直接vertexRGB。片元未再次做世界光照。''',
'Placemaker/House':'''基础vertex0在CPU变形后的网格上做Press、tangent轮廓偏移、AO两个方向/高度插值、WorldToShadow与四点深度比较，把照明输出COLOR0。PIXELSHADOWS vertex1将太阳投影UV/深度/朝向辅助量留给pixel，仅执行AO和一部分照明，因此短于vertex0。基础pixel2使用材质/纹理/边缘覆盖及vertex照明；PIXELSHADOWS pixel3在共同材质路径后以ShadowTex四点采样分别sat(20*ShadowRange.x*(depth-sample.rgb))、双线性组合，再以dot(...,(0.35,0.35,0.3))求遮挡，结合朝向/太阳alpha构造太阳与阴影色，最后公共调色。两个variant不是仅keyword metadata改变。''',
'Placemaker/Water':'顶点产生岸线距离/周期条带控制和太阳/AO颜色；像素使用time*0.4、frac三角波、导数边缘与0.8*(1-distance)^4颜色混合，详细公式见核心报告。',
'Placemaker/Window':'''vertex根据position、normal与tangent.w变换门窗局部坐标，并沿法线/切线采AO；透光色通过顶点COLOR1传递。pixel有专用Window texel offset，公共像素保持采MainTex/TypeTex，主纹理alpha两倍先决定材质混合，sat(2*alpha-1)*COLOR1.a作为最终灯光/玻璃颜色权重。公共调色前加入RGB通道乘积，之后输出lerp(litMaterial,COLOR1,lightWeight)，alpha也参与这次RGBA混合。''',
'Placemaker/Fence':'''vertex公共Press和AO，位置偏移0.02用于相邻阴影样本。pixel公共像素保持坐标，但边缘排除项是V0.w/fw(V1.xy)，采MainTex alpha<0.01 discard。材质取floor(abs(V0.z))+0.5，按35%向_MaterialShineColor混合，再C=sample.r*material+sample.g；alpha=sample.a。最后公共顶点光照调色链。''',
'Hidden/MarchingSquaresColorBlit':'顶点UV直传；pixel按floor(17*MainTex.r)查材质颜色，先乘0.8，再按MainTex.a混向白色，见核心公式。',
'Placemaker/Sandbank':'''vertex保留世界/局部高度和WorldToShadow辅助量。pixel对四个ShadowTex采样分别sat(20*range*(depth-sample))再按tile内frac权重双线性混合，(0.35,0.35,0.3)合成阴影；太阳/阴影色与顶点RGB结合。公共像素保持纹理边界、localHeight导数覆盖与_AaLineBoth给出岸面边缘，再公共调色。像素阴影逻辑与House PIXELSHADOWS同族，但采样位置/高度和材质路径不同。''',
'Placemaker/Carnival':'''vertex公共Press、AO与影图照明，UV有纹理类型与边界宽度参数。pixel公共像素保持采MainTex，alpha<0.01 discard；floor(abs(V0.z))查材质，按0.35向材质高亮色混合，C=sample.r*material+sample.g；公共调色，alpha=sample.a。与Fence最大的边界差异是固定0.01/fw(V0.zw)而非V0.w/fw(V1.xy)，参数对应表与各程序保留。''',
'Placemaker/WaterShadow':'vertex传影图格内坐标和色值；pixel四点分别sample>=0.999后双线性混合，再dot(0.3,0.3,0.4)混向白色，见核心公式。',
'Hidden/AoSpreader':'vertex屏幕Blit坐标，pixel三重5×5×3循环进行75邻域反距离归一，RGB结果平方。循环索引、atlas寻址及边界地面色完整在HLSL。',
'Placemaker/Plants':'''vertex执行时间/位置sin/cos风摆、Press、AO与太阳照明。pixel在像素保持采样后，以V0.z/V0.w和距(1,1)的半径构造叶片形状，d=sample.g+shape-1.8，以max(fw(shape),0.0001)归一并对_AaLineBoth正/负半宽分别sat，alpha<0.01 discard。LOD0绿通道与选定MIP的绿通道差改变颜色，再乘_PlantColor及阴影/边缘乘子，公共调色；leaf cutout并非直接用纹理alpha。''',
'Placemaker/Border':'vertex投影/UV与alpha传递；pixel alpha=_Color.a*vertexAlpha*(1-min(abs(MainTex.g-0.7)/fw(MainTex.g),1))，RGB=_Color.rgb。',
'Placemaker/Shade':'vertex执行Press、保留局部shade mesh矩阵坐标；pixel输出_Color RGBA，不采样。',
'Placemaker/Ground':'''vertex先公共Press和AO/阴影采样，输出AO局部UV与边界距离；pixel采AO alpha，a=sat(1.1*AO.a)^4*(1-abs(V1.x))*(1-abs(V1.y))。主纹理采用导数过渡的像素采样，并sat(2*sample)，以a混向白色。颜色通道乘积0.3*(r*g,g*b,b*r)与1.3*vertex光照组合后公共亮度/冷暖调色；输出sat(1.12*RGBA)。''',
'Placemaker/ColorPick':'''vertex使用sincos构造局部选择片位置、世界矩阵/Press/AO照明并输出材质索引/颜色控制；pixel主纹理alpha使用Splash相同Cover轮廓，alpha<0.01 discard。floor(abs(V0.z))+0.5查材质行，以35%向材质高亮色偏移，再公共vertex lighting/调色。用于色块选择的三角/圆片几何在vertex程序，不能只复现palette纹理。''',
'PlacemakerUi/TownPreviewUi':'''vertex执行UI矩阵与颜色/控制UV输出。pixel令 q=2*UV-1，w=(1-q.x^8)*(1-q.y^8)，MIP bias=2*(1-w)-0.2；采MainTex.SampleBias，RGB乘(0.8+0.2*w,0.8+0.2*w,0.95+0.05*w)，按V1.y混向0.5灰色；再乘vertexRGBA，并把RGB额外乘最终alpha。它用八次边界衰减控制纹理LOD和色调，输出预乘alpha。''',
}
def rel(path):return Path(path).relative_to('outputs').as_posix()
rows=['# 全部业务 Shader 算法与可复编译表达式','', '34 个业务 Shader 的 84 个程序（43 vertex、41 pixel）已逐条恢复，包含5652条执行指令和49种opcode；每个程序都通过现有 Windows D3DCompile。原作者HLSL未知；这里是根据发布程序恢复的寄存器显式HLSL。每条立即数从原始DXBC token读取32位模式，避免反汇编文本小数截断；所有输入/输出semantic按真实register mask拆分，包括同一register中不同TEXCOORD的打包。','', '[全部程序与字段manifest](townscaper_shader_algorithms/manifest.json)、[84/84编译结果](townscaper_shader_algorithms/compile_results.json)、[核心生成/像素公式](townscaper_shaders.md)。编译验证语法、类型、stage兼容性；它没有证明原始字节码或所有GPU像素逐位相同。', '', '寄存器以uint4保存真实位，asfloat/asint仅重新解释；asuint在浮点结果后保存其位模式。比较返回0xffffffff/0，movc测试位是否非零，整数negate与float negate分别处理。每条指令先求完整RHS临时值，再按mask写目标，保留同时读取swizzle的语义。循环和if原样结构化。', '', '## 公共世界/轮廓/AO和照明路径', '', '发布顶点的位置已先由CPU ModuleBuilder四角变形。GPU再次执行 object-to-world：W=x*M[0]+y*M[1]+z*M[2]+w*M[3]；normal/tangent采用前三列变换，不加平移。公共Press：D=W.xyz-_PressPosAmount.xyz，f=max(1-dot(D,D),0)，D*=f；W.xz+=_PressPosAmount.w*D.xz，W.y=max(W.y+_PressPosAmount.w*D.y,0)。然后 clip=W.y*VP[1]+W.x*VP[0]+W.z*VP[2]+VP[3]。House/Debris等另将tangent投影差乘clip.w/_ScreenParams.y作屏幕轮廓偏移；所有系数各程序中保留。', '', '体积AO：localXZ=(sampleWorldXZ-_Tex3dWorldBounds.xy)*_Tex3dUvSize.z，再夹到_AoTex_TexelSize.xy与tileSize-texelSize；h=max(sampleWorldY-heightOffset,0)，i=floor(h)，t=frac(h)，N=round(_Tex3dUvSize.w)。slice i的atlas坐标=localXZ+(i%N,floor(i/N))*_Tex3dUvSize.xy；采i和i+1，以t插值；越出上边界的样本退到白色，再按sat(worldY+groundOffset)混入_GroundColor。不同shader用normal/tangent方向和不同heightOffset形成不同AO探针，两探针相乘或分别作为RGB/alpha使用。相应偏移在完整HLSL里，不被统一helper吞掉。', '', '阴影：S=WorldToShadow*worldPosition；常见四采样路径对每个channel先sat(20*_ShadowRange.x*(S.z-bias-sample.rgb))，随后按frac(S.xy*_ShadowTex_TexelSize.zw)双线性混合，dot(0.35,0.35,0.3)合成遮挡。朝向=dot(worldNormal,-_SunDir)，朝向限制与太阳alpha组合决定 SunColor/ShadowColor 和饱和度。House _PIXELSHADOWS在pixel执行该路径；普通House在vertex执行，插值行为有区别。', '', '按程序恢复的全部cbuffer字段见下表。字段偏移来自解压后的Unity参数描述符，浮点向量/矩阵的rows、columns和offset均保留；各buffer字段计数已与声明逐项核对，452字段全部有明确buffer slot。每个纹理包括tn/sampler sn绑定。', '']
groups=collections.defaultdict(list)
for p in programs:groups[p['shader']].append(p)
for name,ps in groups.items():
    assert name in descriptions,name
    rows+=['## '+name,'',descriptions[name],'','| Program/variant | Stage / 指令数 | 恢复HLSL / 原程序 |','|---|---|---|']
    for p in ps:
        key=' '.join(p['keywords']+p['local_keywords'])or'无keyword'
        rows.append(f"| {p['program']} `{key}` | {p['stage']} / {p['instruction_count']} | [完整表达式]({rel(p['hlsl'])}) / [原DXBC汇编]({rel(p['assembly'])}) |")
    parsed=json.loads((BASE/next(s['parsed_form']for s in json.loads((BASE/'outputs/townscaper_shader_programs/manifest.json').read_text(encoding='utf8'))if s.get('name')==name)).read_text(encoding='utf8'))
    rows+=['','Pass/BlobIndex：']
    for a,sub in enumerate(parsed['m_SubShaders']):
      for b,pa in enumerate(sub['m_Passes']):
        v=[sp['m_BlobIndex']for sp in pa['progVertex']['m_SubPrograms']];f=[sp['m_BlobIndex']for sp in pa['progFragment']['m_SubPrograms']]
        rows.append(f'- SubShader{a} Pass{b}: vertex={v}, pixel={f}, tags={pa["m_State"]["m_Tags"]["tags"]}。')
    for p in ps:
        rows+=['',f"### Program {p['program']} 输入输出、绑定与公式",'','输入：'+ '; '.join(f"v{k}.{v['mask']}={v['semantic']}"for k,vs in p['input'].items()for v in vs)+'。','输出：'+ '; '.join(f"o{k}.{v['mask']}={v['semantic']}"for k,vs in p['output'].items()for v in vs)+'。','','| 常量寄存器 | 字段名 | 类型/长度 | 字节偏移 |','|---|---|---|---:|']
        for f in p['bindings']['fields']:
            rows.append(f"| cb{f['slot']}[{f['register']}].{f['component']} | {f['buffer']}.{f['name']} | {f['rows']}×{f['columns']} {'matrix'if f['matrix']else'vector/scalar'} | {f['offset']} |")
        if not p['bindings']['fields']:rows.append('| — | 无使用的常量字段 | — | — |')
        rows+=['','纹理：'+('; '.join(f"t{t['texture']} / s{t['sampler']} = {t['name']}"for t in p['bindings']['textures'])or'无')+'。']
        # Compact algebra version keeps explicit bit-domain helpers and every instruction.
        h=(BASE/p['hlsl']).read_text(encoding='utf8');body=h.split('Output main(Input input) {',1)[1].rsplit('}',1)[0]
        compact=[];ls=body.splitlines();i=0
        while i<len(ls):
            l=ls[i];m=re.match(r'(\s*)uint4 (value_\w+) = (.*); // (.*)',l)
            if m and i+1<len(ls):
                write=re.fullmatch(r'\s*(\w+)\.([xyzw]+) = '+m[2]+r'\.([xyzw]+);',ls[i+1]);assert write
                expr=m[3].replace('asuint','BITS').replace('asfloat','FLOAT').replace('asint','INT').replace('uint4','BITS4')
                compact.append(m[1]+write[1]+'.'+write[2]+' = ('+expr+').'+write[3]+'; // '+m[4]);i+=2
            else:compact.append(l);i+=1
        pp=ROOT/(Path(p['hlsl']).stem+'.pseudo.txt');pp.write_text('// FLOAT/INT reinterpret bits; BITS stores float bits; BITS4 raw vector.\n'+ '\n'.join(compact)+'\n',encoding='utf8')
        rows+=['',f"[逐指令紧凑代数]({rel(str(pp.relative_to(BASE)))}) 去掉中间value变量，但保留所有目标mask、算式、位域转换、控制流与原指令注释；[可编译HLSL]({rel(p['hlsl'])}) 保留完整I/O和RHS临时值。"]
rows+=['','## 指令语义与验证','', '[Microsoft SM4指令规范](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-sm4-asm) 用于核对运算域；[eq](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/eq--sm4---asm-) 的结果是0xffffffff/0，[movc](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/movc--sm4---asm-)以原位非零选择，因此不能将布尔掩码简单转换成float1/0。','', '恢复脚本对84个program验证DXBC执行token数量等于汇编执行指令数量，每个literal operand的分量数与原token一致，所有字面量用原始32位hex，所有452个cbuffer字段数等于描述符声明数。D3DCompile在现有d3dcompiler_47.dll运行，成功84/84；未安装新工具、未写原游戏目录。','', '剩余差异属于重编译优化、浮点舍入/NaN/denormal的硬件行为、texture过滤/寻址状态、渲染Pass与场景驱动，不是仍未解释的shader指令。输出可用于算法理解/重建，不宣称恢复原作者源码或无条件GPU逐位等价。', '', '命令：python work/recover_shader_algorithms.py；python work/compile_recovered_shaders.py；python work/write_all_shader_algorithms.py。']
rows+=['','## 原版 GPU 场景验证','', '[原版 D3D11 渲染核验](townscaper_runtime_render_verification.json)、[最新运行记录](townscaper_runtime_grid.json) 与 [此前运行记录](townscaper_runtime_graphics.json) 已确认 Direct3D 11.0 / feature level11.1、NVIDIA GeForce RTX 5070 Ti Laptop GPU。原主线程 ScreenCapture 捕获建造前/后及撤销/重做四个完整城市场景，均为2560×1440、可解码且非单色PNG；SHA256与场景审阅记录随核验JSON保存。建筑、窗户、装饰、鸟、水面/反射、沙洲、阴影与UI在原版画面可见。','', '上述运行仍使用原游戏Shader；本报告恢复并编译的84个HLSL未替换原GPU程序。它验证原版渲染管线实际运行，不是重编译HLSL像素等效验证。动态水面与鸟阻止用四帧断言Undo/Redo像素逐位相同；生成模块快照与保存字符串另有状态一致性验证。']
(BASE/'outputs/townscaper_shader_algorithms.md').write_text('\n'.join(rows)+'\n',encoding='utf8')
print(json.dumps({'shaders':len(groups),'programs':len(programs),'compact_algebra_files':len(programs),'doc_lines':len(rows)}))
