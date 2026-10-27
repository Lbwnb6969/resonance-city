"""Bind final Sandbanker stage2 slope rules to raw x86 and branch fixtures."""
import hashlib
import json
import math
import struct
import sys
from pathlib import Path

root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'work/pydeps'))
import pefile
from capstone import Cs,CS_ARCH_X86,CS_MODE_32
target=Path(r'D:\SteamLibrary\steamapps\common\Townscaper\GameAssembly.dll')
pe=pefile.PE(str(target));cs=Cs(CS_ARCH_X86,CS_MODE_32)
raw=pe.get_data(0x819000,0xa00)
ins=list(cs.disasm(raw,0x10819000))
calls={i.address:int(i.op_str,16) for i in ins if i.mnemonic=='call' and i.op_str.startswith('0x')}
expected={0x1081936b:0x10673790,0x1081946c:0x10673790,0x1081954a:0x10674620,0x1081958c:0x10674620,0x10819734:0x10673720,0x1081975e:0x10674430,0x1081989e:0x10837090}
assert all(calls.get(site)==callee for site,callee in expected.items())
factor=struct.unpack('<f',pe.get_data(0x11d3830,4))[0]
assert pe.get_data(0x11d3830,4).hex()=='cdcccc3e'
normalize_epsilon=struct.unpack('<f',pe.get_data(0x11e7950,4))[0]
inequality_epsilon=struct.unpack('<f',pe.get_data(0x11d3a88,4))[0]
def sub(a,b):return [a[i]-b[i] for i in range(3)]
def norm(v):
    length=math.sqrt(sum(x*x for x in v))
    return [x/length for x in v] if length>normalize_epsilon else [0.0]*3
def neq(a,b):return not(sum(x*x for x in sub(a,b))<inequality_epsilon)
def cap_triangle(points):
    original=[list(p) for p in points];out=[list(p) for p in points];order=[0,1,2]
    zeros=sum(p[1]==0 for p in original)
    for rotated in range(3):
        ia,ib,ic=order;a,b,c=[original[i] for i in order]
        if zeros<2:
            accepted=a[1]==0
        else:
            accepted=a[1]==0 and b[1]==0 and c[1]>0 and neq(a,c) and neq(b,c)
        if accepted:break
        order=order[1:]+order[:1]
    else:return {'values':out,'branch':'skip','rotations':3}
    if zeros<2:
        for index,p in ((ib,b),(ic,c)):
            limit=factor*math.sqrt(sum(x*x for x in sub(a,p)))
            if limit<p[1]:out[index][1]=limit
        branch='one_zero_3d_distance'
    else:
        edge=sub(b,a);n=norm([edge[2],0,-edge[0]])
        limit=factor*sum(x*y for x,y in zip(sub(c,a),n))
        if limit<c[1]:out[ic][1]=limit
        branch='two_zero_signed_plane'
    return {'values':out,'branch':branch,'rotations':rotated}

cases=[
('no_zero',[[0,1,0],[1,2,0],[0,3,1]],'skip'),
('one_zero',[[0,0,0],[1,2,0],[0,2,1]],'one_zero_3d_distance'),
('one_zero_rotated',[[1,2,0],[0,2,1],[0,0,0]],'one_zero_3d_distance'),
('two_zero_positive',[[0,0,0],[1,0,0],[0,2,-1]],'two_zero_signed_plane'),
('two_zero_negative',[[0,0,0],[-1,0,0],[0,2,-1]],'two_zero_signed_plane'),
('all_zero',[[0,0,0],[1,0,0],[0,0,1]],'skip'),
('two_zero_negative_height',[[0,0,0],[1,0,0],[0,-1,-1]],'skip'),
('degenerate_zero_edge',[[0,0,0],[0,0,0],[0,2,-1]],'two_zero_signed_plane')]
tests=[]
for name,points,branch in cases:
    result=cap_triangle(points);assert result['branch']==branch
    if name=='one_zero':assert abs(result['values'][1][1]-factor*math.sqrt(5))<1e-12
    if name=='two_zero_positive':assert result['values'][2][1]==factor
    if name=='two_zero_negative':assert result['values'][2][1]==-factor
    if name=='degenerate_zero_edge':assert result['values'][2][1]==0
    tests.append({'name':name,'input':points,'result':result})
record={'target':str(target),'target_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'provenance':'Original PE bytes and PDB/IL2CPP identified primitive calls, plus independent mathematical branch fixtures. Not REA Evidence and not original runtime observations.','source':'outputs/native_application/815c40.c:3380','rva':'0x819000','bytes_read':len(raw),'raw_sha256':hashlib.sha256(raw).hexdigest(),'raw_hex':raw.hex(),'instructions':[{'va':hex(i.address),'bytes':i.bytes.hex(),'mnemonic':i.mnemonic,'operands':i.op_str}for i in ins],'primitive_calls_verified':[{'site':hex(a),'callee':hex(b)}for a,b in expected.items()],'slope_factor_float32':factor,'constants':[{'va':hex(0x10000000+r),'bytes':pe.get_data(r,4).hex(),'value':struct.unpack('<f',pe.get_data(r,4))[0]}for r in (0x11d3830,0x11e7950,0x11d3a88)],'fixtures':tests,'limits':'Reference fixtures exercise the recovered branch/sign logic in float64 arithmetic; they do not promise the target SSE/x87 ordering, Unity epsilon boundary bit patterns or complete shore mesh equivalence. The code reads local triangle copies before mutation; this order is preserved by cap_triangle.'}
(root/'outputs/townscaper_sandbank_slopes.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({'raw_bytes':len(raw),'primitive_call_sites':len(expected),'branch_fixtures':len(tests)}))
