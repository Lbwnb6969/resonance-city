"""Bind critical UI/camera math claims to original x86 instructions."""
import hashlib
import json
from pathlib import Path
import struct
import sys

WORK=Path(__file__).resolve().parent
sys.path.insert(0,str(WORK/'pydeps'))
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

target=Path(r'D:\SteamLibrary\steamapps\common\Townscaper\GameAssembly.dll')
pe=pefile.PE(str(target))
cs=Cs(CS_ARCH_X86,CS_MODE_32)
ranges={'BirdFlock.CalculateOptimalLandings':(0x879180,0x140), 'OrbitalCamera.ScrollZoom':(0x74cf60,0x70), 'OrbitalCamera.GamepadZoom':(0x749590,0xa0), 'OrbitalCamera.RotateCamera':(0x74cd50,0x100), 'OrbitalCamera.Save':(0x74ce50,0x110), 'UiMaster.UpdateVSync':(0x3e6fa0,0x40)}
records=[]
for name,(rva,n) in ranges.items():
    raw=pe.get_data(rva,n)
    records.append({'name':name,'rva':hex(rva),'bytes_read':len(raw),'raw_sha256':hashlib.sha256(raw).hexdigest(),'raw_hex':raw.hex(),'instructions':[{'address':hex(i.address),'bytes':i.bytes.hex(),'mnemonic':i.mnemonic,'operands':i.op_str} for i in cs.disasm(raw,0x10000000+rva)]})
constants=[0x11e27a0,0x11d383c,0x11d3840,0x11d2708,0x11f1450,0x11d26e8,0x11f1444,0x11e1e68,0x11d26f8,0x11f1400,0x11e1d38]
result={'target':str(target),'target_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'source':'Original PE bytes + pefile/Capstone; independent local evidence, not REA Evidence','ranges':records,'float_constants':[{'rva':hex(r),'hex':pe.get_data(r,4).hex(),'float32':struct.unpack('<f',pe.get_data(r,4))[0]} for r in constants], 'double_constants':[{'rva':'0x11d3850','float64':struct.unpack('<d',pe.get_data(0x11d3850,8))[0]}],'findings':{'save_byte_conversion':'fnstcw / or 0xc00 / fldcw / fistp sets RC=11 (truncate toward zero), not nearest ROUND','bird_counts':'ideal=floor(F), min=int(max(0,0.9*F-2)), max=int(max(0,1.1*F+2)), F=clamp(float32(sqrt(float64(float32(landing_count))))-6,0,64)','scroll_zoom':'zoomTarget=InverseLerp(distMin,distMax,nonDollyDist*float32(pow(2,float64(float32(input*-4)))))','gamepad_zoom':'Exponent formed in float32 as float32(exp(-float64(unscaledDeltaTime)))*input*0.1*-4; pow base2; InverseLerp of nonDollyDist product','v_sync':'setne al; inc eax before tail jump to set_vSyncCount, therefore bool ->1 or2'},'limitations':['Sequential disassembly includes function-padding INT3 bytes up to next selected method boundary.', 'These are static instruction/dataflow observations, no runtime camera or animal-state execution asserted.']}
(WORK.parent/'outputs/townscaper_interaction_math.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({'ranges':len(records),'bytes':sum(r['bytes_read'] for r in records),'target_sha256':result['target_sha256']}))
