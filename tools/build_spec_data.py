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
    return [float(value) for value in re.findall(r'(?<![0-9.])-?\d+(?:\.\d+)?', text.replace('−', '-'))]


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
    result = {
        'timing': {'bpm': musical[0], 'beats_per_bar': int(musical[1]),
                   'bars_per_phrase': int(musical[4]),
                   'preview_seconds': numbers(a2['试听长度'])[0],
                   'beat_assist_window_ms': abs(numbers(a2['副轨卡拍窗口'])[0]),
                   'sample_rate': int(numbers(a4['PCM采样率'])[0]),
                   'buffer_seconds': numbers(a4['生成缓冲长度'])[0]},
        'voices': voices,
        'frequencies': frequencies,
        'harmony': {'initial_vitality': float(re.search(r'初始值 V_0 = ([\d.]+)', harmony)[1])},
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
