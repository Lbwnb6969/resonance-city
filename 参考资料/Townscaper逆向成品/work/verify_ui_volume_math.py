"""Read-only binding of SoundButton log10 return to original x86 register flow."""
import hashlib
import json
from pathlib import Path
import struct
import sys
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'work' / 'pydeps'))
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

target = Path(r'D:\SteamLibrary\steamapps\common\Townscaper\GameAssembly.dll')
pe = pefile.PE(str(target))
raw = pe.get_data(0x2fa910, 0xf5)
insns = list(Cs(CS_ARCH_X86, CS_MODE_32).disasm(raw, 0x102fa910))
record = {'target': str(target), 'target_sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
          'source': 'Original PE + pefile/Capstone static evidence, not REA Evidence',
          'rva': '0x2fa910', 'raw_hex': raw.hex(), 'raw_sha256': hashlib.sha256(raw).hexdigest(),
          'instructions': [{'address':hex(i.address), 'bytes':i.bytes.hex(), 'mnemonic':i.mnemonic, 'operands':i.op_str} for i in insns],
          'constants': [{'rva':hex(r), 'raw_hex': pe.get_data(r, 4).hex(), 'float32': struct.unpack('<f', pe.get_data(r, 4))[0]} for r in [0x11d3ac4]],
          'finding': 'Lerp x87 return is spilled as double to [ebp-8], loaded into XMM0, passed through _libm_sse2_log10_precise(0x10196510), its XMM0 return is converted to float and multiplied by float32 20 (0x111d3ac4) before AudioMixer.SetFloat.'}
(ROOT / 'outputs' / 'townscaper_ui_volume_math.json').write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding='utf8', newline='\n')
for i in insns:
    if i.address >= 0x102fa990:
        print(f'{i.address:08x} {i.mnemonic} {i.op_str}')
