"""Recover Sandbanker stage-2 arithmetic from the original x86 PE bytes.

This is local raw-byte verification, not a newly produced REA Evidence record.
Only reads the installed binary; writes reproducible workspace evidence.
"""
from pathlib import Path
import hashlib
import json
import math
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'work/pydeps'))
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

TARGET = Path(r'D:\SteamLibrary\steamapps\common\Townscaper\GameAssembly.dll')
blob = TARGET.read_bytes()
pe = pefile.PE(data=blob)
base = pe.OPTIONAL_HEADER.ImageBase
decoder = Cs(CS_ARCH_X86, CS_MODE_32)


def instructions(start, end):
    return list(decoder.disasm(pe.get_data(start, end - start), base + start))


def f32(x):
    return struct.unpack('<f', struct.pack('<f', x))[0]


def record(start, end, meaning):
    data = pe.get_data(start, end - start)
    return {
        'rva_start': hex(start), 'rva_end_exclusive': hex(end),
        'meaning': meaning, 'sha256': hashlib.sha256(data).hexdigest(),
        'instructions': [{'va': hex(i.address), 'bytes': i.bytes.hex(),
                          'mnemonic': i.mnemonic, 'operands': i.op_str}
                         for i in instructions(start, end)]
    }


constants = []
for rva, expected, name in [
    (0x11d3834, 0x3f000000, 'edge half difference'),
    (0x11f1650, 0x3e3e76c9, 'odd vertex vertical lift'),
    (0x11e7950, 0x3727c5ac, 'normalization epsilon'),
    (0x11d26e4, 0x00000000, 'zero'),
    (0x11d26f8, 0x3f800000, 'Lerp clamp upper bound'),
]:
    data = pe.get_data(rva, 4)
    bits = struct.unpack('<I', data)[0]
    assert bits == expected, (name, hex(bits))
    constants.append({'name': name, 'rva': hex(rva), 'bytes': data.hex(),
                      'bits': hex(bits), 'float32': struct.unpack('<f', data)[0]})

sites = {
    0x81724a: ('fmul', 'dword ptr [0x111d3834]'),
    0x81747f: ('cmp', 'ecx, 3'),
    0x817482: ('jl', '0x108171b0'),
    0x817889: ('call', '0x10a43e90'),
    0x817952: ('add', 'edx, 2'),
    0x817a70: ('mulss', 'xmm0, xmm1'),
    0x817cdb: ('add', 'edx, 2'),
    0x817cf4: ('cmp', 'ecx, 6'),
    0x817cf7: ('jl', '0x10817970'),
    0x817cfd: ('mov', 'ecx, 1'),
    0x817d9a: ('movss', 'xmm3, dword ptr [0x111f1650]'),
}
stage = instructions(0x8170a2, 0x817e2a)
by_rva = {i.address - base: i for i in stage}
for rva, expected in sites.items():
    i = by_rva[rva]
    assert (i.mnemonic, i.op_str) == expected
assert not any(i.mnemonic.startswith(('cvtt', 'cvtss2si', 'fist')) for i in stage)
# The stage has index division by 2 (cdq/sub/sar), but no arithmetic divide.
assert not any(i.mnemonic in ('div', 'idiv', 'divss', 'divps', 'fdiv', 'fdivp') for i in stage)


def propagate(coverage, edges, rounds=3):
    c = [f32(x) for x in coverage]
    history = [c[:]]
    for _ in range(rounds):
        delta = [0.0] * len(c)
        for a, b in edges:
            # Original x87 fsub/fmul, then float32 store of the half difference.
            d = f32((c[b] - c[a]) * 0.5)
            delta[a] = f32(delta[a] + d)
            delta[b] = f32(delta[b] - d)
        c = [f32(x + d) for x, d in zip(c, delta)]
        history.append(c[:])
    return history


def smooth(positions, edges, rounds=6):
    p = [[f32(x) for x in v] for v in positions]
    history = [[v[:] for v in p]]
    for _ in range(rounds):
        delta = [[0.0, 0.0, 0.0] for _ in p]
        for a, b in edges:
            d = [f32(f32(p[b][k] - p[a][k]) * 0.5) for k in range(3)]
            for k in range(3):
                delta[a][k] = f32(delta[a][k] + d[k])
                delta[b][k] = f32(delta[b][k] - d[k])
        p = [[f32(x + d) for x, d in zip(v, dv)] for v, dv in zip(p, delta)]
        history.append([v[:] for v in p])
    return history


cycle = [(0, 1), (1, 2), (2, 3), (3, 0)]
coverage_cycle = propagate([1, 0, 0, 0], cycle)
coverage_star = propagate([1, 0, 0, 0], [(0, 1), (0, 2), (0, 3)])
position_cycle = smooth([(0, 0, 0), (2, 0, 0), (2, 0, 2), (0, 0, 2)], cycle)
assert coverage_cycle == [[1, 0, 0, 0], [0, 0.5, 0, 0.5],
                          [0.5, 0, 0.5, 0], [0, 0.5, 0, 0.5]]
assert coverage_star[1] == [-0.5, 0.5, 0.5, 0.5]
assert position_cycle[1] == [[1, 0, 1]] * 4
assert position_cycle[-1] == [[1, 0, 1]] * 4

result = {
    'source': str(TARGET), 'source_sha256': hashlib.sha256(blob).hexdigest(),
    'provenance': 'Local PE raw bytes / Capstone; no new REA Evidence ID.',
    'function_rva': '0x815c40', 'stage': 2,
    'constants': constants,
    'ranges': [
        record(0x8170a2, 0x8171a8, 'N=verts.Count/2; pooled capacity=verts.Count; append N zero Vector3 values to each scratch list'),
        record(0x8171a8, 0x817488, '3 synchronous coverage half-difference accumulation/application rounds; scratch reset per vertex'),
        record(0x817488, 0x817782, 'Each six-index strip contributes (-dz,0,dx) to both endpoint normal accumulators'),
        record(0x817782, 0x81796b, 'Even vertex offset by unnormalized accumulated normal * Lerp(.8,.2,coverage); then normalize scratch normal'),
        record(0x81796b, 0x817cfd, '6 synchronous even-vertex half-difference accumulation/application rounds; scratch reset per vertex'),
        record(0x817cfd, 0x817e2a, 'Odd indices 1,3,... receive fixed upward lift'),
        record(0xa43e90, 0xa43ed2, 'Actual Mathf.Lerp clamps t to [0,1] and uses float32 subtract/multiply/add'),
        record(0x674430, 0x674481, 'Vector3.normalized delegates to Normalize'),
        record(0x673cc0, 0x673dc9, 'Normalize float32 squared length -> float64 sqrt -> float32 length; divide only when length > epsilon'),
    ],
    'verification': {
        'instruction_sites_verified': len(sites), 'constant_sites_verified': len(constants),
        'stage_float_to_integer_conversions': 0, 'stage_arithmetic_divides': 0,
        'coverage_cycle_four': coverage_cycle,
        'coverage_degree_three_reference': coverage_star,
        'position_cycle_four': position_cycle,
        'reference_case_scope': 'Synthetic equation checks, not observed gameplay or proof actual shoreline contains degree-three vertices.'
    },
    'limits': ['This covers the specified stage-2 smoothing span, not stages 0/1/3 or later stage-2 triangle-height branches.',
               'Finite float32 input reference checks preserve operation order; they do not claim a full bitwise reimplementation under every x87 control word / NaN payload.']
}
(ROOT / 'outputs/townscaper_sandbank_smoothing_raw.json').write_text(
    json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
print(json.dumps(result['verification'], ensure_ascii=False))
