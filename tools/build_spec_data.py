"""Generate the runtime parameter file from the authoritative Markdown tables."""
from pathlib import Path
import argparse
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / '文档/01_执行规格'
OUTPUT = ROOT / '数据/spec_values.json'


def read(name):
    return (SPEC / name).read_text(encoding='utf-8-sig')


def table(text, heading):
    section = text.split(heading, 1)[1].split('\n## ', 1)[0].split('\n### ', 1)[0]
    rows = []
    for line in section.splitlines():
        if line.startswith('|') and not re.fullmatch(r'[| :\-]+', line):
            rows.append([re.sub(r'\*\*|`', '', cell.strip()) for cell in line.strip('|').split('|')])
    assert rows, f'Missing table: {heading}'
    return rows[1:]


def numbers(text):
    return [float(value) for value in re.findall(r'(?<![0-9.])-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?', text.replace('−', '-'))]


def generate():
    audio = read('spec.audio.md')
    city = read('spec.city.md')
    harmony = read('spec.harmony.md')
    a2 = dict(table(audio, '## 表 A2'))
    a4 = dict(table(audio, '## 表 A4'))
    a5_rows = table(audio, '## 表 A5')
    partials = {row[0]: {'partials': numbers(row[1]), 'rhythm_steps': [int(x) for x in numbers(row[2])]}
                for row in a5_rows if row[0] in ['residential', 'commercial', 'industrial']}
    a5 = {row[0]: row[1] for row in a5_rows if len(row) == 2}
    musical = numbers(a2['BPM / 拍号 / 小节 / 乐句'])
    assert len(musical) == 6, musical
    voices = {}
    frequencies = {}
    for row in table(city, '## 表 A ·'):
        match = re.search(r'\b(residential|commercial|industrial)\b', row[0])
        if match:
            voices[match[1]] = {
                'base_midi': int(row[2].split('=')[1].strip()),
                'frequency_hz': numbers(row[3])[0],
                'layers': ['drone', 'rhythm', 'ornament'],
                'drone_timbre': row[4], 'rhythm_signature': row[5],
            }
            voices[match[1]].update(partials[match[1]])
            frequencies[str(voices[match[1]]['base_midi'])] = voices[match[1]]['frequency_hz']
    note_classes = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}
    for row in table(harmony, '## 表 H2'):
        note = re.fullmatch(r'([A-G])(♯?)([0-9])', row[1])
        if note:
            midi = (int(note[3]) + 1) * 12 + note_classes[note[1]] + bool(note[2])
            frequencies[str(midi)] = numbers(row[2])[0]
    pan_numbers = numbers(a5['方位'])
    city_space = dict(table(city, '## 表 D'))
    def capture(pattern):
        return float(re.search(pattern, harmony)[1])
    intervals = {}
    interval_classes = [[0], [5, 7], [4, 9], [3, 8], [2, 10], [1, 11], [6]]
    for row, classes in zip(table(harmony, '## 表 B'), interval_classes, strict=True):
        for distance in classes:
            intervals[str(distance)] = {'score': numbers(row[2])[0], 'vitality_delta': numbers(row[3])[0], 'name': row[0], 'relation': row[1]}
    vitality_range = numbers(re.search(r'V_next = clamp\(([^\n]+)\)', harmony)[1])[-2:]
    result = {
        'timing': {'bpm': musical[0], 'beats_per_bar': int(musical[1]),
                   'bars_per_phrase': int(musical[4]),
                   'preview_seconds': numbers(a2['试听长度'])[0],
                   'beat_assist_window_ms': abs(numbers(a2['副轨卡拍窗口'])[0]),
                   'sample_rate': int(numbers(a4['PCM采样率'])[0]),
                   'buffer_seconds': numbers(a4['生成缓冲长度'])[0]},
        'voices': voices,
        'frequencies': frequencies,
        'city': {'width': int(numbers(city_space['P0 地图'])[0]), 'height': int(numbers(city_space['P0 地图'])[1]),
                 'empty_resonance': numbers(city_space['P0 无邻接 / 多边精度'])[0],
                 'comparison_tolerance': numbers(city_space['P0 无邻接 / 多边精度'])[-1],
                 'minimum_initial_resonance': numbers(city_space['初始 R 下限'])[0],
                 'resample_limit': int(numbers(city_space['局部重采样上限'])[0])},
        'harmony': {'initial_vitality': capture(r'初始值 V_0 = ([\d.]+)'),
                    'weight_base': capture(r'w_i = ([\d.]+) \+'), 'weight_increment': capture(r'\+ ([\d.]+) × \(n_i'),
                    'weight_cap': capture(r'min\(w_i, ([\d.]+)\)'), 'industrial_weight': capture(r'w_i × ([\d.]+)'),
                    'base_growth': capture(r'base_growth = \+([\d.]+)'), 'decay': capture(r'decay\s+= ([\d.]+)'),
                    'decay_threshold': capture(r'当 R < ([\d.]+)'), 'net_change_cap': capture(r'单乐句净变化上限 = ±([\d.]+)'),
                    'minimum_vitality': vitality_range[0], 'maximum_vitality': vitality_range[1],
                    'resonance_scale': capture(r'R = ([\d.]+) ×'),
                    'gray_entry': capture(r'进入：R < ([\d.]+)'), 'gray_exit': capture(r'退出：R > ([\d.]+)'),
                    'collapse_phrases': int(capture(r'连续 ([\d.]+) 个乐句')),
                    'intervals': intervals},
        'synthesis': {'wavetable_size': int(numbers(a5['波表大小'])[0]),
                      'drone_gain': numbers(a5['标准drone / rhythm增益'])[0],
                      'rhythm_gain': numbers(a5['标准drone / rhythm增益'])[1],
                      'rhythm_octave': int(numbers(a5['rhythm音高'])[0]),
                      'industrial_highpass_hz': numbers(a5['rhythm音高'])[1],
                      'rhythm_attack_seconds': numbers(a5['rhythm起振 / 尾音 / 衰减常数'])[0],
                      'rhythm_tail_seconds': numbers(a5['rhythm起振 / 尾音 / 衰减常数'])[1],
                      'rhythm_decay_seconds': numbers(a5['rhythm起振 / 尾音 / 衰减常数'])[2],
                      'pan_regions': [[int(pan_numbers[0]), int(pan_numbers[1]), pan_numbers[6]],
                                      [int(pan_numbers[2]), int(pan_numbers[3]), pan_numbers[7]],
                                      [int(pan_numbers[4]), int(pan_numbers[5]), pan_numbers[8]]]},
    }
    result['city']['initial_count'] = int(numbers(city_space['P0 初始街区数'])[0])
    generation = dict(table(city, '## 表 D2'))
    result['city']['safe_cells'] = {}
    for kind, label in [('residential', '住宅'), ('commercial', '商业'), ('industrial', '工业')]:
        coords = numbers(generation['安全fixture' + label])
        result['city']['safe_cells'][kind] = [[int(coords[i]), int(coords[i+1])] for i in range(0, len(coords), 2)]
    result['sources'] = {name: hashlib.sha256(read(name).encode()).hexdigest()
                         for name in ['spec.audio.md', 'spec.city.md', 'spec.harmony.md']}
    return json.dumps(result, ensure_ascii=False, indent=2) + '\n'


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    expected = generate()
    if args.check:
        assert OUTPUT.is_file() and OUTPUT.read_text(encoding='utf-8') == expected, 'Stale spec_values.json'
        print('SPEC_DATA PASS: runtime parameters match authoritative tables')
    else:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_text(expected, encoding='utf-8', newline='\n')
        print(f'Generated {OUTPUT.relative_to(ROOT)}')
