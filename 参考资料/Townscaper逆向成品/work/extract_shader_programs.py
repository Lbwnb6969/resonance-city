"""Preserve and disassemble shipped shader DXBC; original game is read-only."""
from pathlib import Path
import sys, ctypes, json, re, hashlib, struct
BASE=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(BASE/'work/asset_pydeps'))
import UnityPy, attrs
from UnityPy.export.ShaderConverter import ShaderProgram
from UnityPy.helpers import CompressionHelper
from UnityPy.streams import EndianBinaryReader
ROOT=Path(r'D:\SteamLibrary\steamapps\common\Townscaper\Townscaper_Data')
OUT=BASE/'outputs/townscaper_shader_programs'; OUT.mkdir(exist_ok=True)
dll=ctypes.WinDLL('d3dcompiler_47.dll')
fn=dll.D3DDisassemble
fn.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_uint,ctypes.c_char_p,ctypes.POINTER(ctypes.c_void_p)]
fn.restype=ctypes.c_long
CALL=ctypes.WINFUNCTYPE
def disassemble(data):
    buf=ctypes.create_string_buffer(data); blob=ctypes.c_void_p()
    hr=fn(buf,len(data),0,None,ctypes.byref(blob))
    if hr<0: raise ValueError('D3DDisassemble HRESULT '+hex(hr&0xffffffff))
    vt=ctypes.cast(blob,ctypes.POINTER(ctypes.POINTER(ctypes.c_void_p))).contents
    pointer=CALL(ctypes.c_void_p,ctypes.c_void_p)(vt[3])(blob)
    size=CALL(ctypes.c_size_t,ctypes.c_void_p)(vt[4])(blob)
    text=ctypes.string_at(pointer,size).decode('utf8').rstrip('\x00')
    CALL(ctypes.c_uint,ctypes.c_void_p)(vt[2])(blob)
    return text
def entry(arr,i):
    v=arr[i]; return v[0] if isinstance(v,list) else v
env=UnityPy.load(*(str(p) for p in sorted(ROOT.glob('*.assets'))),str(ROOT/'Resources/unity_builtin_extra'),str(ROOT/'Resources/unity default resources'))
records=[]
for o in env.objects:
    if o.type.name!='Shader': continue
    source=Path(o.assets_file.name).name
    try: s=o.read()
    except Exception as e:
        records.append({'source':source,'path_id':o.path_id,'programs':[],'error':str(e)})
        continue
    shadername=s.m_ParsedForm.m_Name
    rec={'source':source,'path_id':o.path_id,'name':shadername,'programs':[]}
    name=re.sub('[^A-Za-z0-9_.-]','_',shadername)
    stem=source+'__'+str(o.path_id)+'__'+name
    rec['parsed_form']=str((OUT/(stem+'.parsed.json')).relative_to(BASE))
    (OUT/(stem+'.parsed.json')).write_text(json.dumps(attrs.asdict(s.m_ParsedForm),ensure_ascii=False,indent=2),encoding='utf8')
    for i,platform in enumerate(s.platforms):
        if i>=len(s.compressedLengths): break
        offset=entry(s.offsets,i); clen=entry(s.compressedLengths,i); dlen=entry(s.decompressedLengths,i)
        raw=CompressionHelper.decompress_lz4(bytes(s.compressedBlob)[offset:offset+clen],dlen)
        (OUT/(stem+'__p'+str(platform)+'.decompressed.bin')).write_bytes(raw)
        prog=ShaderProgram(EndianBinaryReader(raw,endian='<'),o.version)
        for k,p in enumerate(prog.m_SubPrograms):
            code=bytes(p.m_ProgramCode); sig=code.find(b'DXBC')
            r={'platform':int(platform),'index':k,'type':str(p.m_ProgramType),'keywords':p.m_Keywords,'local_keywords':p.m_LocalKeywords,'bytes':len(code)}
            dest=str(OUT/(stem+'__p'+str(platform)+'__'+str(k)))
            if sig>=0:
                size=struct.unpack_from('<I',code,sig+24)[0]; dxbc=code[sig:sig+size]
                Path(dest+'.dxbc').write_bytes(dxbc)
                r['dxbc_offset']=sig; r['dxbc_bytes']=len(dxbc); r['sha256']=hashlib.sha256(dxbc).hexdigest()
                try:
                    Path(dest+'.asm').write_text(disassemble(dxbc),encoding='utf8'); r['disassembled']=True
                    r['assembly']=str(Path(dest+'.asm').relative_to(BASE))
                except Exception as e: r['error']=str(e)
            else:
                Path(dest+'.program.bin').write_bytes(code)
                r['preserved']=str(Path(dest+'.program.bin').relative_to(BASE))
            rec['programs'].append(r)
    records.append(rec)
(OUT/'manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({'shaders':len(records),'programs':sum(len(x['programs']) for x in records),'disassembled':sum(p.get('disassembled',False) for x in records for p in x['programs'])}))
