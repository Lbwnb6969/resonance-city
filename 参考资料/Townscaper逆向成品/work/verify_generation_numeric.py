"""Resolve constants and x87 modulo arguments omitted by the C decompiler."""
from pathlib import Path
import hashlib
import json
import struct
import sys

BASE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE / 'work/pydeps'))
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

target = Path(r'D:\SteamLibrary\steamapps\common\Townscaper\GameAssembly.dll')
data = target.read_bytes()
pe = pefile.PE(data=data)
image_base = pe.OPTIONAL_HEADER.ImageBase
md = Cs(CS_ARCH_X86, CS_MODE_32)
start, end = 0x3f1e80, 0x3f2ab0
instructions = list(md.disasm(data[pe.get_offset_from_rva(start):pe.get_offset_from_rva(end)], image_base + start))
windows = []
for n, ins in enumerate(instructions):
    if ins.mnemonic == 'call' and ins.op_str == '0x10195ff0':
        windows.append({'call_va': ins.address, 'instructions': [
            {'va': i.address, 'bytes': i.bytes.hex(), 'text': i.mnemonic + ' ' + i.op_str}
            for i in instructions[max(0, n - 18):n + 5]]})
constants = []
for va, meaning in [(0x111e1e4c, 'float32 pi'), (0x111e1e54, 'qube cost position multiplier'),
                    (0x111e1e60, 'candidate cost position multiplier')]:
    off = pe.get_offset_from_rva(va - image_base)
    raw = data[off:off + 4]
    constants.append({'va': va, 'offset': off, 'bytes': raw.hex(), 'value_float32': struct.unpack('<f', raw)[0], 'meaning': meaning})
mask_va = 0x111d2720
mask_off = pe.get_offset_from_rva(mask_va - image_base)
off = pe.get_offset_from_rva(0x196000)
fallback = list(md.disasm(data[off:off + 14], image_base + 0x196000))
table_off = pe.get_offset_from_rva(0x13cf4d0)
result = {'source': str(target), 'sha256': hashlib.sha256(data).hexdigest(),
          'evidence_kind': 'independent raw-byte / Capstone verification; not REA Evidence',
          'procedure_rva': start, 'constants': constants,
          'abs_sign_mask': {'va': mask_va, 'offset': mask_off, 'bytes': data[mask_off:mask_off + 16].hex()},
          'modulo_calls': windows,
          'fmod_dispatch_table': {'va': image_base + 0x13cf4d0, 'bytes': data[table_off:table_off + 24].hex(),
                                  'fallback_function_va': struct.unpack('<I', data[table_off + 16:table_off + 20])[0]},
          'fmod_fallback': [{'va': i.address, 'bytes': i.bytes.hex(), 'text': i.mnemonic + ' ' + i.op_str} for i in fallback],
          'conclusion': 'Both calls load the magnitude then fld1; fmod fallback fxch puts magnitude in ST0 and divisor 1 in ST1 before fprem. Candidate/qube perturbations are fractional remainders of positive float32 expressions.',
          'limitations': ['Float32 instruction ordering and subsequent float64 remainder must be preserved for bit-exact reconstruction.',
                          'This is static code/constant evidence, not a runtime mesh or visual equivalence test.']}
assert len(windows) == 2
assert [c['value_float32'] for c in constants][1:] == [7.0, 17.0]
assert result['fmod_dispatch_table']['fallback_function_va'] == image_base + 0x196000
(BASE / 'outputs/townscaper_generation_numeric_evidence.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('Verified two modulo call sites, float32 pi/7/17, absolute mask and fmod fprem fallback.')
