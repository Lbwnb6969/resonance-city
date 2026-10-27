"""Recover shipped quad patch topology and bind critical math to original x86 bytes."""
from pathlib import Path
import collections, hashlib, json, math, re, struct, sys

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT/'work/pydeps'))
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def f32(v): return struct.unpack('<f', struct.pack('<f',v))[0]
def u32(v): return v & 0xffffffff
def truncdiv(a,b): return int(a/b)
def cw(h): return (-h[2],-h[0],-h[1])
def ccw(h): return (-h[1],-h[2],-h[0])
def hexround(v):
    r=list(map(round,v)); d=[abs(a-b) for a,b in zip(r,v)]
    if d[0]>d[1] and d[0]>d[2]: r[0]=-r[1]-r[2]
    elif d[1]>d[2]: r[1]=-r[0]-r[2]
    else: r[2]=-r[0]-r[1]
    return tuple(r)
def patchhex(h):
    q=cw(h); r=hexround(tuple((a+b)/216 for a,b in zip(h,q)))
    s=tuple(a*216 for a in r); t=ccw(s)
    return tuple(truncdiv(a+b,3) for a,b in zip(s,t))
def centroid(h):
    v=(h[0],h[1]-2160,h[2]+2160); c=cw(v)
    v=tuple(truncdiv(a+b,3) for a,b in zip(v,c))
    r=[truncdiv(a+(1152 if a>0 else -1152),2304)*2304 for a in v]
    d=[abs(a-b) for a,b in zip(v,r)]
    if d[0]>d[1] and d[0]>d[2]: r[0]=-r[1]-r[2]
    elif d[1]>d[2]: r[1]=-r[0]-r[2]
    else: r[2]=-r[0]-r[1]
    t=ccw(r)
    return (r[0]+t[0],r[1]+t[1]+2160,r[2]+t[2]-2160)
def hash3(h): return u32(h[0]*0x4c7f6dd1+h[1]*0x4822a3e9-h[2]*0x553c3da3+0xd21d0945)
def nextstate(s):
    s=u32(s ^ u32(s<<13)); s=u32(s ^ (s>>17)); return u32(s ^ u32(s<<5))

source=ROOT/'outputs/townscaper_asset_components.json'
allc=json.loads(source.read_text(encoding='utf8'))
data={c['script']['class']:c for c in allc if c['script']['class'] in ['GridGenerator','GridBit','CustomGridLibrary','Graph']}
lib=data['CustomGridLibrary']['data']; patches=lib['allCustomPatches']; records=[]
def topology(p):
    n=len(p['verts']); ids=p['quads']; cut=p['quadTriCutoff']
    assert cut%3==0 and (len(ids)-cut)%4==0 and max(ids)<n
    faces=[ids[i:i+3] for i in range(0,cut,3)]+[ids[i:i+4] for i in range(cut,len(ids),4)]
    edges=collections.Counter(tuple(sorted((a,b))) for f in faces for a,b in zip(f,f[1:]+f[:1]))
    assert max(edges.values())<=2
    assert all(len(set(f))==len(f) for f in faces)
    used=set(ids)
    adjacent=collections.defaultdict(set);directed=collections.defaultdict(list)
    for f in faces:
        for a,b in zip(f,f[1:]+f[:1]):
            adjacent[a].add(b);adjacent[b].add(a);directed[tuple(sorted((a,b)))].append((a,b))
    seen=set();stack=[next(iter(used))]
    while stack:
        a=stack.pop()
        if a in seen:continue
        seen.add(a);stack.extend(adjacent[a]-seen)
    assert seen==used
    assert all(len(v)!=2 or v[0]==v[1][::-1] for v in directed.values())
    return {'vertex_count':n,'used_vertex_count':len(used),'triangle_count':cut//3,'quad_count':(len(ids)-cut)//4,'edge_count':len(edges),'boundary_edge_count':sum(v==1 for v in edges.values()),'euler_used_vertices_minus_edges_plus_faces':len(used)-len(edges)+len(faces),'maximum_edge_incidence':max(edges.values()),'all_indexes_valid':True,'all_faces_distinct_vertices':True,'connected':True,'internal_edge_winding_consistent':True}
for i,p in enumerate(patches):
    records.append({'index':i,'subdivisions':p['subdivisions'],'triangle_prefix_indexes':p['quadTriCutoff'],**topology(p)})
scene=data['GridGenerator']['data']['patches'][0]
sceneinfo=topology(scene)
sameverts=[i for i,p in enumerate(patches) if p['verts']==scene['verts']]
samefaces=[]
def polysets(p):
    n=p['quadTriCutoff'];ids=p['quads'];verts=p['verts']
    fs=[ids[i:i+3] for i in range(0,n,3)]+[ids[i:i+4] for i in range(n,len(ids),4)]
    return {tuple(sorted((verts[j]['x'],verts[j]['y']) for j in f)) for f in fs}
for i,p in enumerate(patches):
    if polysets(scene)==polysets(p):samefaces.append(i)

selectors={k:{'slots':len(lib[k]),'fallback_slots':lib[k].count(255),'weights':dict(collections.Counter(lib[k])),'indexes':lib[k]} for k in ['genericPatches','straightPatches','centroidPatches','centroidCurvePatches']}
result={'source':{'path':str(source),'sha256':sha(source),'file':data['CustomGridLibrary']['file'],'path_id':data['CustomGridLibrary']['path_id'],'provenance':'Strict UnityPy + recovered MonoBehaviour type trees; independent static artifact evidence, not REA Evidence'},'patches':patches,'statistics':records,'selectors':selectors,'scene_grid':{'file':'level1','grid_path_id':data['GridGenerator']['path_id'],'grid_bit_path_id':data['GridBit']['path_id'],'patch_summary':sceneinfo,'patch_state':scene['state'],'patch_subdivisions':scene['subdivisions'],'same_vertex_array_library_indexes':sameverts,'same_geometric_faces_library_indexes':samefaces,'relaxed_float_verts':data['GridBit']['data']['verts'],'integer_patch':scene},'validation':{'patches_validated':len(records),'disk_euler_all_1':all(x['euler_used_vertices_minus_edges_plus_faces']==1 for x in records),'no_nonmanifold_edges':True,'all_selectors_in_range_or_255':all(i==255 or 0<=i<len(patches) for k in selectors for i in lib[k])}}
(ROOT/'outputs/townscaper_grid_library.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')

target=Path(r'D:\SteamLibrary\steamapps\common\Townscaper\GameAssembly.dll');pe=pefile.PE(str(target));cs=Cs(CS_ARCH_X86,CS_MODE_32)
ranges={'HexMath.cctor_basis':(0x40e180,0x21c),'HexMath.RotateCW_int3':(0x40e0f0,0x1f),'HexMath.RotateCCW_int3':(0x40e070,0x1f),'int3.GetHashCode':(0x3e30b0,0x48),'GridGenerator.GetVertCost':(0xe12520,0x9b),'GridGenerator.HexToPlane_float2':(0xe13b80,0x7f),'GridGenerator.diagonal':(0xe1fc50,0x86),'CustomGridLibrary.GetRandom':(0x4c2390,0xb0),'GridGenerator.IteratePatch_seed':(0xe179e9,0x180),'Graph.GetMaxExtents':(0xe6bae0,0x174),'GridGenerator.Compose_bary_weights':(0xe15162,0x1f6),'ModuleMath.cctor_baryVectors':(0x3dcace,0x157)}
raw=[]
for name,(rva,count) in ranges.items():
    b=pe.get_data(rva,count);raw.append({'name':name,'rva':hex(rva),'size':len(b),'sha256':hashlib.sha256(b).hexdigest(),'bytes':b.hex(),'instructions':[{'va':hex(i.address),'mnemonic':i.mnemonic,'operands':i.op_str,'bytes':i.bytes.hex()} for i in cs.disasm(b,0x10000000+rva)]})
bits=['3df925fe','4103851f','3c37fe09','bea978d5','3fc66666','3ecccccd','43af0000','42480000','3f3504f3']
constants=[{'float_bits':'0x'+v,'float32':struct.unpack('<f',bytes.fromhex(v)[::-1])[0]} for v in bits]
degree=f32(math.pi/180); theta=f32(f32(120)*degree);co=f32(math.cos(theta));si=f32(math.sin(theta));r=f32(1/f32(math.sqrt(f32(f32(f32(1-co)**2)+f32(si*si)))))
basis=[]
for d in (0,120,240):
    th=f32(f32(d)*degree);basis.append((f32(r*f32(math.cos(th))),f32(r*f32(math.sin(th)))))
scale=f32(0.121654496)
samples=[]
for h in [(0,0,0),(9,0,-9),(0,9,-9),(9,-9,0),(72,-72,0),(2304,0,-2304)]:
    plane=tuple(f32(f32(f32(h[0]*basis[0][j])+f32(h[1]*basis[1][j])+f32(h[2]*basis[2][j]))*scale) for j in (0,1))
    s=nextstate(hash3(h));slots=len(lib['genericPatches']);index=(slots*s)>>32
    samples.append({'hex':h,'nominal_unrelaxed_world_xz_float32_model':plane,'nearest_patch':patchhex(h),'centroid':centroid(h),'int3_hash':hex(hash3(h)),'initialized_random_state':hex(s),'generic_slot':index,'generic_patch_index':lib['genericPatches'][index],'next_state':hex(nextstate(s))})
numeric={'target':str(target),'target_sha256':sha(target),'provenance':'Original x86 PE bytes/Capstone and independent arithmetic interpretation; no runtime invocation','ranges':raw,'constants':constants,'basis_float32_model':basis,'basis_radius_float32_model':r,'degree_constant_float32':degree,'samples':samples,'constraints':{'cube_sum_zero_all_samples':all(sum(s['hex'])==0 for s in samples),'cube_patch_sum_zero_all_samples':all(sum(s['nearest_patch'])==0 for s in samples),'cube_centroid_sum_zero_all_samples':all(sum(s['centroid'])==0 for s in samples)},'limitations':['Nominal plane samples model float32 basis/rotation; target libm exact rounding and x87 temporary precision not dynamically compared. Actual display vertices undergo 255 relaxation iterations and cluster seam composition.','Generic sample indexes demonstrate GetRandom only; category gates are described separately in the report.','No claim of complete generated mesh/runtime equivalence from library validation.']}
def plane_model(h):return tuple(sum(a*basis[i][j] for i,a in enumerate(h))*scale for j in (0,1))
offsets=[];h=(72,-72,0)
for i in range(6):offsets.append({'hex':h,'plane':plane_model(h)});h=cw(h)
bary=[]
for i in range(6):
    m=tuple((offsets[i]['plane'][j]+offsets[(i+1)%6]['plane'][j])/2 for j in (0,1));n=sum(a*a for a in m);bary.append(tuple(-a/n for a in m))
def dot(a,b):return sum(x*y for x,y in zip(a,b))
weight_samples=[]
for s in range(6):
    a=offsets[s]['plane'];b=offsets[(s+1)%6]['plane']
    for label,p,expected in [('origin',(0,0),(1,0,0)),('cluster_a',a,(0,1,0)),('cluster_b',b,(0,0,1)),('interior',tuple(.2*x+.3*y for x,y in zip(a,b)),(.5,.2,.3))]:
        weights=(dot(tuple(x-y for x,y in zip(p,a)),bary[s]),dot(tuple(x-y for x,y in zip(p,b)),bary[(s+2)%6]),dot(p,bary[(s+4)%6]))
        weight_samples.append({'sector':s,'point':label,'plane':p,'weights':weights,'sum':sum(weights),'expected_ideal_basis_weights':expected,'max_absolute_error':max(abs(x-y) for x,y in zip(weights,expected))})
assert max(q['max_absolute_error'] for q in weight_samples)<1e-6
numeric['compose']={'cluster_offsets':offsets,'baryVectors_model':bary,'weights_samples':weight_samples,'weight_model_verified_samples':len(weight_samples),'maximum_ideal_basis_weight_error':max(q['max_absolute_error'] for q in weight_samples),'formula':'out=P(bitHex)+dot(v-a,D[s])*bitRelax[i]+dot(v-b,D[(s+2)%6])*(clusterA.relaxedVerts[mapA]+a)+dot(v,D[(s+4)%6])*(clusterB.relaxedVerts[mapB]+b)','clamp_or_weight_renormalization':False,'cluster_patch_offset_selector':['z','y','x'],'limitations':'Independent affine model from float32 basis; runtime compose positions and intermediate bitRelax values not invoked or compared.'}
(ROOT/'outputs/townscaper_grid_math.json').write_text(json.dumps(numeric,ensure_ascii=False,indent=2),encoding='utf8')

# A compact visualization of the actual relaxed center, retaining its static source identity.
vv=data['GridBit']['data']['verts'];ids=scene['quads'];edges=set(tuple(sorted((ids[i+j],ids[i+(j+1)%4]))) for i in range(0,len(ids),4) for j in range(4))
xs=[v['x'] for v in vv];ys=[v['y'] for v in vv];extent=max(max(xs)-min(xs),max(ys)-min(ys));z=540/extent;cx=(min(xs)+max(xs))/2;cy=(min(ys)+max(ys))/2
def p(j):return (300+(vv[j]['x']-cx)*z,330-(vv[j]['y']-cy)*z)
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="600" height="660" viewBox="0 0 600 660"><rect width="600" height="660" fill="#faf9f6"/><text x="30" y="30" font-family="sans-serif" font-size="20">Townscaper: shipped relaxed center grid</text><text x="30" y="54" font-family="sans-serif" font-size="13">level1: GridGenerator 351 / GridBit 325; 217 verts, 192 quads</text>']
for a,b in sorted(edges):
    x,y=p(a);xx,yy=p(b);svg.append(f'<path d="M{x:.3f},{y:.3f} L{xx:.3f},{yy:.3f}" fill="none" stroke="#286069" stroke-width="1"/>')
svg.append('</svg>');(ROOT/'outputs/townscaper_grid_center.svg').write_text('\n'.join(svg),encoding='utf8')
print(json.dumps({'patch_count':len(patches),'triangles':sum(x['triangle_count'] for x in records),'quads':sum(x['quad_count'] for x in records),'validation':result['validation'],'scene':sceneinfo,'same_vertex_arrays':sameverts,'same_geometric_faces':samefaces,'basis':basis,'sample_first3':samples[:3]},ensure_ascii=False))
