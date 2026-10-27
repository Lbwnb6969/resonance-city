"""Bind Sandbank stage3 discarded-value ambiguities to original PE calls."""
from pathlib import Path
import json,hashlib,sys,struct
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'work/pydeps'))
import pefile
from capstone import Cs,CS_ARCH_X86,CS_MODE_32
target=Path(r'D:\SteamLibrary\steamapps\common\Townscaper\GameAssembly.dll')
pe=pefile.PE(str(target));cs=Cs(CS_ARCH_X86,CS_MODE_32)
raw=pe.get_data(0x815c40,0x6000)
ins=list(cs.disasm(raw,0x10815c40))
script=json.loads((ROOT/'work/reverse/il2cpp/script.json').read_text('utf-8-sig'))
methods=script['ScriptMethod']
names={0x10000000+int(m['Address']):m['Name'] for m in methods}
result=[]
for j,i in enumerate(ins):
    if i.mnemonic!='call' or not i.op_str.startswith('0x'):continue
    n=names.get(int(i.op_str,16),'')
    if 'PerlinNoise' in n or 'LerpUnclamped' in n or 'get_magnitude' in n:
        if i.address < 0x10819900:continue
        items=ins[max(0,j-12):j+(210 if i.address >= 0x1081ba70 else 22)]
        result.append({'call':hex(i.address),'callee':n,'instructions':[{'va':hex(x.address),'bytes':x.bytes.hex(),'mnemonic':x.mnemonic,'operands':x.op_str} for x in items]})
record={'source':str(target),'source_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'rva':'0x815c40','range_bytes':len(raw),'range_sha256':hashlib.sha256(raw).hexdigest(),'call_windows':result,'stage4_constants':[{'va':hex(v),'raw_hex':pe.get_data(v-0x10000000,4).hex(),'float32':struct.unpack('<f',pe.get_data(v-0x10000000,4))[0]} for v in [0x111d26ec,0x111d3834]]}
(ROOT/'outputs/townscaper_sandbank_water_raw.json').write_text(json.dumps(record,indent=2),encoding='utf-8',newline='\n')
for r in result:
    print(r['call'],r['callee'])
    print('\n'.join(f"{x['va']} {x['mnemonic']} {x['operands']}" for x in r['instructions'][:34]))
