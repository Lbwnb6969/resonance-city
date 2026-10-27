"""Check parent-owned original-runtime grid observations against static fixtures."""
from pathlib import Path
import collections, hashlib, json, math, struct

root=Path(__file__).resolve().parent.parent
source=root/'outputs/townscaper_runtime_grid.json'
raw=json.loads(source.read_text(encoding='utf8'));probe=raw['grid_probe']
library=json.loads((root/'outputs/townscaper_grid_library.json').read_text(encoding='utf8'))
numeric=json.loads((root/'outputs/townscaper_grid_math.json').read_text(encoding='utf8'))
def f32(x):return struct.unpack('<f',struct.pack('<f',x))[0]
def plane(h):
    h=tuple(h)+( -sum(h),) if len(h)==2 else h
    basis=numeric['basis_float32_model'];scale=f32(.121654496)
    return tuple(f32(f32(f32(f32(h[0]*basis[0][j])+f32(h[1]*basis[1][j]))+f32(h[2]*basis[2][j]))*scale) for j in (0,1))
def cw(h):return (-h[2],-h[0],-h[1])
def add(a,b):return tuple(x+y for x,y in zip(a,b))
def sub(a,b):return tuple(x-y for x,y in zip(a,b))
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def patchoffset(c):
    h=(c[0],c[1],-c[0]-c[1]);t=add(h,cw(h));y=round(t[1]/216);z=round(t[2]/216);r=(-(y+z)*216,y*216,z*216)
    ccw=(-r[1],-r[2],-r[0]);return tuple(int((a+b)/3)-c[i] for i,(a,b) in enumerate(zip(r,ccw)) if i<2)

math_checks=[]
for sample in probe['math']['result']:
    expected=plane(sample['hex']);actual=sample['plane'];assert list(expected)==actual,(sample,expected)
    math_checks.append({'hex':sample['hex'],'model_equals_original_float32':True})
bary=probe['math']['baryVectors'];bary_error=max(abs(x-y) for a,b in zip(bary,numeric['compose']['baryVectors_model']) for x,y in zip(a,b))
assert bary_error<1e-8

bit=probe['bits']['centralBit'];fixture=library['scene_grid']['relaxed_float_verts']
assert bit['state']==5 and bit['relaxationSteps']==255
assert len(bit['verts'])==len(fixture)==217
assert all(r==[s['x'],s['y']] for r,s in zip(bit['verts'],fixture))
patches={tuple(p['hex']):p for p in probe['bits']['patches']}
center=patches[(0,0)];assert center['verts']==[[v['x'],v['y']] for v in library['scene_grid']['integer_patch']['verts']]
assert center['indexes']==library['scene_grid']['integer_patch']['quads']

map_checks=[]
for c in probe['bits']['centralClusters']:
    assert c['done']==1 and c['relaxationSteps']==255
    h=tuple(c['hex']);o=patchoffset(h);seen={};segments=[]
    for j in range(3):
        phex=add(h,o);p=patches[phex];offset=c['patchVertOffsets'][j];n=len(p['verts']);indexes=c['vertIndexes'][offset:offset+n];assert len(indexes)==n
        for vertex,index in zip(p['verts'],indexes):
            assert 0<=index<len(c['relaxedVerts'])
            key=tuple(vertex)
            if key in seen:assert seen[key]==index,(h,key)
            seen[key]=index
        segments.append({'patch':phex,'offset':offset,'length':n})
        cube=(o[0],o[1],-sum(o));r=cw(cw(cube));o=r[:2]
    assert len(seen)==len(c['relaxedVerts'])
    map_checks.append({'cluster':h,'segments':segments,'all_mapped_indexes_valid':True,'shared_integer_vertices_have_same_index':True,'unique_integer_vertices':len(seen)})

stages=[];by_label={s['label']:s['graph'] for s in probe['snapshots']}
assert not by_label['before']['squares'] and not by_label['before']['voxels']
assert not by_label['ground_removed']['squares'] and not by_label['ground_removed']['voxels']
canonical={}
quad_owners={}
for p in patches.values():
    for j in range(p['cutoff'],len(p['indexes']),4):
        key=tuple(sorted(tuple(p['verts'][i]) for i in p['indexes'][j:j+4]));quad_owners[key]=p['hex']
for label in ['ground_added','house_added','house_removed']:
    g=by_label[label];assert g['state']==42 and len(g['squares'])==4
    assert sorted((v['height'],v['type']) for v in g['voxels'])==([(0,15),(1,3)] if label=='house_added' else [(0,15)])
    expected_coverage=collections.Counter(tuple(c['hex']) for s in g['squares'] for c in s['corners'])
    links=0;state=[];meshes=set();owners=[]
    for sq in g['squares']:
        owners.append(quad_owners[tuple(sorted(tuple(c['hex']) for c in sq['corners']))])
        selected=[i for i,c in enumerate(sq['corners']) if c['hex']==[72,-36]];assert len(selected)==1;i=selected[0]
        for c in sq['corners']:
            assert c['coverage']==expected_coverage[tuple(c['hex'])]
            if c['hex']==[72,-36]:assert c['angle']==360 and c['colliderMesh']!='0x0';meshes.add(c['colliderMesh'])
        for r in sq['relations']:
            if r['square']!='0x0':assert r['reciprocal'] is True;links+=1
        qs={round(q['localPosition'][1]):q for q in sq['qubes']};assert set(qs)==({0,1,2} if label=='house_added' else {0,1})
        for height,q in qs.items():
            expected=[18]*8
            if height==0:expected[:4]=[17]*4;expected[4+i]=15
            if height==1:expected[i]=15
            if label=='house_added' and height==1:expected[4+i]=3
            if label=='house_added' and height==2:expected[i]=3
            assert q['cornerValues']==expected
            mask=sum(1<<j for j,t in enumerate(expected) if t!=18);assert q['occupancyMask']==mask
            assert q['awaitingGraphUpdate']==0
        state.append({'corners':[c['hex'] for c in sq['corners']],'qubes':[{k:q[k] for k in ['localPosition','occupancyMask','cornerValues']} for q in sq['qubes']]})
    assert links==8 and len(meshes)==1
    assert sorted(owners)==[[0,0],[0,0],[144,-72],[144,-72]]
    canonical[label]=state
    stages.append({'label':label,'squares':len(g['squares']),'voxels':len(g['voxels']),'patch_owners':owners,'valid_reciprocal_directed_relations':links,'selected_corner_coverage':4,'stable_nonzero_corner_collider':next(iter(meshes)),'eight_corner_values_masks_coverage_verified':True})
assert canonical['ground_added']==canonical['house_removed']
assert probe['flowBefore']['allLoadedInstances']==probe['flowAfter']['allLoadedInstances']==0
assert probe['flowBefore']['updateCalls']==probe['flowAfter']['updateCalls']==0
result={'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'provenance':'Verification of original IL2CPP runtime observations supplied by parent; no new runtime invocation by this script','math_checks':math_checks,'maximum_bary_vector_model_absolute_error':bary_error,'center_vertex_count':217,'center_verts_equal_shipped_fixture_exactly':True,'center_integer_patch_equals_shipped_fixture_exactly':True,'cluster_mapping_checks':map_checks,'stages':stages,'adding_then_removing_house_restores_ground_qube_values_masks':True,'removing_ground_recycles_selected_topology':True,'flow_observation':{'before':probe['flowBefore'],'after':probe['flowAfter'],'scope':'This instrumented graphical startup and explicit cross-patch add/remove scenario only'},'limitations':['No capture of bitRelax before Compose, so this does not establish an independent end-to-end Compose reproduction.','Corner.colliderMesh pointer is observed, but Voxel MeshCollider.sharedMesh was not separately read by this helper.','The scenario used Ground type15 at h0; arbitrary stored h0 color preservation remains supported by static code, not tested by this scenario.']}
(root/'outputs/townscaper_runtime_grid_verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8',newline='\n')
print(json.dumps({k:v for k,v in result.items() if k!='cluster_mapping_checks'},ensure_ascii=False))
