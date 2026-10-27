"""Check the raw byte evidence behind REA's no-return warning."""
import hashlib, json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / 'pydeps'))
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

root = Path(__file__).resolve().parent.parent
target = Path(r'D:\SteamLibrary\steamapps\common\Townscaper\GameAssembly.dll')
digest = hashlib.sha256(target.read_bytes()).hexdigest()
assert digest == '4aa99a8deaa9a322026094186ed283020a8b6d897f2777dbb330ebf0ca89532c'
pe = pefile.PE(str(target))
cs = Cs(CS_ARCH_X86, CS_MODE_32)
parts = []
for rva, size in ((0x18e950, 5), (0x15fca0, 18)):
    code = pe.get_data(rva, size)
    parts.append({'rva':hex(rva), 'file_offset':pe.get_offset_from_rva(rva), 'bytes':code.hex(),
                  'instructions':[{'address':hex(i.address),'mnemonic':i.mnemonic,'operands':i.op_str} for i in cs.disasm(code,pe.OPTIONAL_HEADER.ImageBase+rva)]})
assert parts[0]['instructions'][0]['mnemonic'] == 'jmp'
assert parts[0]['instructions'][0]['operands'] == '0x1015fca0'
assert parts[1]['instructions'][-1]['mnemonic'] == 'ret'
result = {'source':'original PE bytes, pefile/Capstone; not REA Evidence','target_sha256':digest,
          'observations':parts,'conclusion':'Initializer thunk targets a wrapper with an explicit RET tail; this is insufficient to verify that its nested call returns, but prevents treating the Ghidra no-return flag as independent runtime proof.'}
(root / 'outputs/townscaper_initializer_return_check.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print('Initializer raw-byte check: PASS (JMP target and RET tail)')
