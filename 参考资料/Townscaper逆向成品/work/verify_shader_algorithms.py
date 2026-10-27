"""Independent interface/literal/binding/coverage checks for all generated programs."""
from pathlib import Path
import json,re,struct,collections,ctypes
BASE=Path(__file__).resolve().parent.parent;ROOT=BASE/'outputs/townscaper_shader_algorithms'
meta=json.loads((ROOT/'manifest.json').read_text(encoding='utf8'));compiled=json.loads((ROOT/'compile_results.json').read_text(encoding='utf8'))
dll=ctypes.WinDLL('d3dcompiler_47.dll');fn=dll.D3DDisassemble
fn.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_uint,ctypes.c_char_p,ctypes.POINTER(ctypes.c_void_p)];fn.restype=ctypes.c_long
CALL=ctypes.WINFUNCTYPE
def dis(data):
 buf=ctypes.create_string_buffer(data);blob=ctypes.c_void_p();assert fn(buf,len(data),0,None,ctypes.byref(blob))>=0
 vt=ctypes.cast(blob,ctypes.POINTER(ctypes.POINTER(ctypes.c_void_p))).contents
 ptr=CALL(ctypes.c_void_p,ctypes.c_void_p)(vt[3])(blob);size=CALL(ctypes.c_size_t,ctypes.c_void_p)(vt[4])(blob)
 text=ctypes.string_at(ptr,size).decode('utf8').rstrip('\x00');CALL(ctypes.c_uint,ctypes.c_void_p)(vt[2])(blob);return text
def sig(code,which):
 area=code.split('// '+which+' signature:',1)[1]
 if which=='Input':area=area.split('// Output signature:',1)[0]
 else:area=area.split('\n'+re.search('[pv]s_4_0',code).group(),1)[0]
 entries=[]
 for l in area.splitlines():
  m=re.match(r'//\s+(\w+)\s+(\d+)\s+([xyzw]+)\s+(\d+)\s+(\w+)\s+(float|uint|sint)',l)
  if m:entries.append((m[1],m[2],len(m[3]),m[6]))
 return sorted(entries)
assert len(meta['programs'])==len(compiled['programs'])==84
assert all(p['success']for p in compiled['programs'])
literal_count=0;bindings=0;interfaces=0;line_count=0
for p in meta['programs']:
 original=(BASE/p['assembly']).read_text(encoding='utf8');hlsl=(BASE/p['hlsl']).read_text(encoding='utf8')
 raw_literals=collections.Counter(v for ins in p['raw_instruction_literals']for lit in ins['literals']for v in lit)
 # Scalar literal is replicated into uint4 by translator, hence count can increase but each value must be present.
 for v in raw_literals:assert hex(v)+'u'in hlsl,(p['shader'],p['program'],v)
 literal_count+=sum(raw_literals.values())
 for b in p['bindings']['buffers']:
  fs=[f for f in p['bindings']['fields']if f['buffer']==b['name']];assert len(fs)==b['declared_fields']
  for f in fs:assert f['slot']is not None and f['offset']+4*f['rows']*f['columns']<=b['bytes'];bindings+=1
 recompiled=dis((BASE/p['hlsl']).with_suffix('.recompiled.dxbc').read_bytes())
 for which in ('Input','Output'):
  assert sig(original,which)==sig(recompiled,which),(p['shader'],p['program'],which,sig(original,which),sig(recompiled,which))
  interfaces+=1
 code=[l.strip()for l in original.splitlines()if l.strip()and not l.strip().startswith('//')and not l.strip().startswith('dcl_')and l.strip()!=p['stage']]
 assert len(code)==p['instruction_count']==len(p['raw_instruction_literals']);line_count+=len(code)
 links=re.findall(r'\]\(([^)]+)\)',(BASE/'outputs/townscaper_shader_algorithms.md').read_text(encoding='utf8'))
for link in links:
 if link.startswith('http'):continue
 assert (BASE/'outputs'/link).exists(),link
result={'programs':84,'instructions':line_count,'literal_components':literal_count,'cbuffer_fields':bindings,'matching_original_recompiled_interfaces':interfaces,'report_local_links':len([l for l in links if not l.startswith('http')]),'limitations':'Interface matching and successful compilation do not prove GPU pixel equality or identical instruction rounding.'}
(ROOT/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8');print(json.dumps(result))
