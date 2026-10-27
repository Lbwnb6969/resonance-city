"""Compile 84 recovered HLSL programs using existing Windows D3DCompiler, no installs."""
from pathlib import Path
import ctypes,json,re
BASE=Path(__file__).resolve().parent.parent
ROOT=BASE/'outputs/townscaper_shader_algorithms'
meta=json.loads((ROOT/'manifest.json').read_text(encoding='utf8'))
dll=ctypes.WinDLL('d3dcompiler_47.dll');fn=dll.D3DCompile
fn.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_void_p,ctypes.c_void_p,ctypes.c_char_p,ctypes.c_char_p,ctypes.c_uint,ctypes.c_uint,ctypes.POINTER(ctypes.c_void_p),ctypes.POINTER(ctypes.c_void_p)]
fn.restype=ctypes.c_long
CALL=ctypes.WINFUNCTYPE
def blob_data(blob):
 if not blob.value:return b''
 vt=ctypes.cast(blob,ctypes.POINTER(ctypes.POINTER(ctypes.c_void_p))).contents
 ptr=CALL(ctypes.c_void_p,ctypes.c_void_p)(vt[3])(blob);size=CALL(ctypes.c_size_t,ctypes.c_void_p)(vt[4])(blob)
 data=ctypes.string_at(ptr,size);CALL(ctypes.c_uint,ctypes.c_void_p)(vt[2])(blob);return data
results=[]
for p in meta['programs']:
 path=BASE/p['hlsl'];code=path.read_bytes();b=ctypes.create_string_buffer(code);out=ctypes.c_void_p();err=ctypes.c_void_p()
 hr=fn(b,len(code),path.name.encode(),None,None,b'main',p['stage'].encode(),1,0,ctypes.byref(out),ctypes.byref(err))
 dxbc=blob_data(out);errors=blob_data(err).decode('utf8',errors='replace').rstrip('\x00')
 r={'shader':p['shader'],'program':p['program'],'stage':p['stage'],'hlsl':p['hlsl'],'success':hr>=0,'hresult':hex(hr&0xffffffff),'diagnostics':errors,'compiled_bytes':len(dxbc)}
 if hr>=0:path.with_suffix('.recompiled.dxbc').write_bytes(dxbc)
 results.append(r)
(ROOT/'compile_results.json').write_text(json.dumps({'compiler':'Existing Windows d3dcompiler_47.dll D3DCompile strictness flag','limitations':['Compilation proves valid stage-compatible HLSL, not identical GPU pixels or DXBC bytes.'],'programs':results},ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({'successful':sum(r['success']for r in results),'total':len(results),'first_errors':[r for r in results if not r['success']][:3]}))
