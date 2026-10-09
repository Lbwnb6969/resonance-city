"""Generate the runtime parameter file from the authoritative Markdown tables."""
from pathlib import Path
import argparse
import hashlib
import json
import math
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
    ui = read('spec.ui.md')
    harmony = read('spec.harmony.md')
    proposal = read('spec.proposal.md')
    a2 = dict(table(audio, '## 表 A2'))
    a4 = dict(table(audio, '## 表 A4'))
    a5_rows = table(audio, '## 表 A5')
    partials = {row[0]: {'partials': numbers(row[1]), 'rhythm_steps': [int(x) for x in numbers(row[2])]}
                for row in a5_rows if row[0] in ['residential', 'commercial', 'industrial']}
    a5 = {row[0]: row[1] for row in a5_rows if len(row) == 2}
    a6 = dict(table(audio, '## 表 A6'))
    a8 = dict(table(audio, '## 表 A8'))
    a9 = dict(table(audio, '## 表 A9'))
    a10 = dict(table(audio, '## 表 A10'))
    a11 = dict(table(audio, '## 表 A11'))
    a12 = dict(table(audio, '## 表 A12'))
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
    p4 = dict(table(proposal, '## 表 P4'))
    p2 = {row[0]: row[2] for row in table(proposal, '## 表 P2')}
    result['proposals'] = {
        'allowed_pitches': [int(x) for x in numbers(p4['目标音级白名单'])],
        'refresh_seconds': numbers(p4['提案刷新'])[0],
        'per_phrase': int(numbers(p4['每乐句介入'])[0]),
        'retune_cost': -abs(numbers(p2['retune'])[0]),
        'relocate_silent_phrases': int(numbers(p4['迁移静音'])[0]),
        'landing_bonus': numbers(a2['副轨卡拍窗口'])[-1],
    }
    result['mixing'] = {
        'duck_db': numbers(a2['ducking 白名单'])[0],
        'duck_release_seconds': numbers(a2['ducking 白名单'])[1] / 1000,
        'emphasis_db': numbers(a2['试听被改动声部强调'])[0],
        'target_lufs': numbers(a2['总混音'])[0],
        'peak_headroom_db': numbers(a2['总混音'])[1],
        'drone_ratio': numbers(a2['drone 技术下限'])[0] / 100,
    }
    result['acoustic_measurement'] = {
        # A8 parameters are kept separately from the standard acoustic path.
        'duration_seconds': numbers(a6['合成长度 / 稳态裁剪'])[0],
        'trim_seconds': numbers(a6['合成长度 / 稳态裁剪'])[1],
        'envelope_rate': numbers(a6['原PCM / 包络采样率'])[1],
        'rms_window_seconds': numbers(a6['RMS功率窗'])[0] / 1000,
        'lowpass_hz': numbers(a6['抗混叠滤波'])[0], 'kaiser_beta': numbers(a6['抗混叠滤波'])[1],
        'neighbor_inner_hz': numbers(a6['显著峰邻域'])[0], 'neighbor_outer_hz': numbers(a6['显著峰邻域'])[1],
        'amplitude_floor_ratio': numbers(a6['噪底'])[0],
        'target_hz': numbers(a6['小二目标'])[0], 'target_tolerance_hz': numbers(a6['小二目标'])[1],
        'minor_peak_db': numbers(a6['小二目标'])[2],
        'slow_low_hz': numbers(a6['无慢峰'])[0], 'slow_high_hz': numbers(a6['无慢峰'])[1],
        'no_peak_db': numbers(a6['无慢峰'])[2], 'consonant_variation_db': numbers(a6['协和RMS波动'])[-1],
        'energy_low_hz': numbers(a6['高频能量参考'])[1], 'energy_high_hz': numbers(a6['高频能量参考'])[2],
    }
    generation = dict(table(city, '## 表 D2'))
    protocol, seed = a11['协议版本 / 固定种子'].split('；',1)[0].split(' / ')
    cases = numbers(a11['题型与方位计数'])[:6]
    result['listening'] = {
        'version': protocol, 'seed': seed,
        'practice_count': int(numbers(a11['练习 / 正式 / 每题'])[0]),
        'formal_count': int(numbers(a11['练习 / 正式 / 每题'])[1]),
        'duration_seconds': numbers(a11['练习 / 正式 / 每题'])[3],
        'case_counts': {'minor': [int(x) for x in cases[:3]], 'tritone': [int(x) for x in cases[3:]]},
        'base_midi': int(numbers(a11['城市声部'])[2]),
        'minor_midi': int(numbers(a11['城市声部'])[4]),
        'tritone_midi': int(numbers(a11['城市声部'])[5]),
        'fade_beats': numbers(a11['进出淡化'])[0],
        'tester_count': int(numbers(a11['人数 / 判定'])[0]),
        'required_correct': int(numbers(a11['人数 / 判定'])[-2]),
    }
    result['gray_audio'] = {'lowpass_hz': numbers(a12['低通'])[1],
                            'hold_rate': numbers(a12['轻颗粒'])[0],
                            'wet': numbers(a12['完全灰态干湿'])[0]/100,
                            'transition_bars': int(numbers(a12['进入 / 退出'])[0])}
    result['rms_guard'] = {
        'window_seconds': numbers(a10['统计窗'])[0]/1000,
        'minimum_ratio': numbers(a10['最低比例 / 补偿目标'])[0]/100,
        'target_ratio': numbers(a10['最低比例 / 补偿目标'])[1]/100,
    }
    fc, q, g, exponent = numbers(a9['K-weighting高架'])
    k = math.tan(math.pi * fc / result['timing']['sample_rate'])
    vh = 10**(g/20); vb = vh**exponent; den = 1+k/q+k*k
    shelf = [(vh+vb*k/q+k*k)/den, 2*(k*k-vh)/den, (vh-vb*k/q+k*k)/den,
             2*(k*k-1)/den, (1-k/q+k*k)/den]
    fc, q = numbers(a9['K-weighting高通'])[:2]
    k = math.tan(math.pi * fc / result['timing']['sample_rate']); den = 1+k/q+k*k
    gate = numbers(a9['积分门控'])
    result['loudness'] = {
        'duration_seconds': numbers(a9['校准输入'])[0],
        'shelf': shelf, 'highpass': [1,-2,1,2*(k*k-1)/den,(1-k/q+k*k)/den],
        'block_seconds': gate[0]/1000, 'overlap': gate[1]/100,
        'absolute_gate_lufs': gate[2], 'relative_gate_lu': gate[3], 'offset': gate[4],
        'tolerance_lu': numbers(a9['独立验收'])[0],
    }
    result['assist'] = {
        'default_enabled': True, 'default_mode': 'standard',
        'level_db': numbers(a8['伴音'])[-1], 'depth': numbers(a8['调制深度'])[0],
        'minimum_difference_hz': numbers(a8['合法音对'])[-2],
        'maximum_difference_hz': numbers(a8['合法音对'])[-1],
        'octave_multiplier': numbers(a8['伴音'])[0],
    }
    result['city']['safe_cells'] = {}
    for kind, label in [('residential', '住宅'), ('commercial', '商业'), ('industrial', '工业')]:
        coords = numbers(generation['安全fixture' + label])
        result['city']['safe_cells'][kind] = [[int(coords[i]), int(coords[i+1])] for i in range(0, len(coords), 2)]
    growth = dict(table(city, '## 表 E ·'))
    result['growth'] = {
        'stage_phrases': [int(x) for x in numbers(growth['形态乐句'])],
        'embryo_score': numbers(growth['胚和声'])[1],
        'group_neighbors': int(numbers(growth['群和声与密度'])[0]),
        'group_score': numbers(growth['群和声与密度'])[1],
        'group_local_r': numbers(growth['群和声与密度'])[2],
        'group_radius': int(numbers(growth['群和声与密度'])[3]),
        'group_count': int(numbers(growth['群和声与密度'])[4]),
        'center_neighbors': int(numbers(growth['央和声与密度'])[0]),
        'center_score': numbers(growth['央和声与密度'])[1],
        'center_radius': int(numbers(growth['央和声与密度'])[4]),
        'center_count': int(numbers(growth['央和声与密度'])[5]),
        'chamber_neighbors': int(numbers(growth['腔和声'])[0]),
        'chamber_score': numbers(growth['腔和声'])[1],
        'freeze_score': numbers(growth['碴'])[0],
        'max_entities': int(numbers(growth['Demo声音预算'])[0]),
        'new_voice_level': numbers(growth['Demo声音预算'])[2],
        'tile_half_width': numbers(growth['Demo显示'])[2],
        'tile_half_height': numbers(growth['Demo显示'])[3],
        'plot_coverage': numbers(growth['地面占地与缩放'])[0],
    }
    gaps = dict(table(city, '## 表 E4 ·'))
    result['growth']['stall_phrases'] = int(numbers(gaps['停滞阈值'])[0])
    draft = dict(table(proposal, '## 表 P5 ·'))
    result['draft'] = {
        'maximum_bands': int(numbers(draft['同时上限'])[0]),
        'redraw_pause_phrases': int(numbers(draft['重划代价'])[0]),
        'allowed_biases': ['residential', 'commercial'],
    }
    tread = dict(table(proposal, '## 表 P6 ·'))
    result['tread'] = {'threshold': int(numbers(tread['成路阈值'])[0])}
    camera = dict(table(ui, '## 表 U7 ·'))
    result['camera'] = {
        'default_zoom': numbers(camera['缩放'])[0],
        'minimum_zoom': numbers(camera['缩放'])[1],
        'maximum_zoom': numbers(camera['缩放'])[2],
        'wheel_multiplier': numbers(camera['缩放'])[3],
        'header_height': numbers(camera['裁剪'])[0],
        'origin_y': numbers(camera['地图默认原点'])[0],
        'smooth_seconds': numbers(camera['镜头缓动'])[0]/1000,
        'focus_zoom': numbers(camera['聚焦倍率'])[0],
        'focus_margin': numbers(camera['聚焦留边'])[0],
    }
    atmosphere = dict(table(ui, '## 表 U8 ·'))
    def colors(text):
        return re.findall(r'#[0-9A-Fa-f]{6}', text)
    result['terrain'] = {
        'background_top': colors(atmosphere['背景渐变'])[0],
        'background_bottom': colors(atmosphere['背景渐变'])[1],
        'depth_px': numbers(atmosphere['岛台侧面'])[0],
        'side_light': colors(atmosphere['岛台侧面'])[0],
        'side_dark': colors(atmosphere['岛台侧面'])[1],
        'shadow_offset': numbers(atmosphere['岛台阴影'].split(';')[0].split('；')[0]),
        'shadow_color': colors(atmosphere['岛台阴影'])[0],
        'shadow_alpha': float(re.search(r'alpha([0-9.]+)', atmosphere['岛台阴影'])[1]),
        'rim_width_px': numbers(atmosphere['岛台边沿'])[0],
        'rim_color': colors(atmosphere['岛台边沿'])[0],
    }
    rebellion = dict(table(city, '## 表 C2 ·'))
    result['rebellion_fixture'] = {
        'pitch_offset': int(numbers(rebellion['音高偏移'])[0]),
        'minimum_deviation': numbers(rebellion['律动偏移'])[0]/100,
        'maximum_deviation': numbers(rebellion['律动偏移'])[1]/100,
    }
    landscape = dict(table(ui, '## 表 U13 ·'))
    result['landscape'] = {
        'per_family': int(numbers(landscape['数量'])[0]),
        'maximum': int(numbers(landscape['数量'])[1]),
        'minimum_spacing': int(numbers(landscape['间距'])[0]),
        'tree_heights_px': numbers(landscape['树高'])[:2],
        'ground_ratio': numbers(landscape['庭院'])[0],
        'ground_color': colors(landscape['庭院'])[0],
        'ground_alpha': float(re.search(r'alpha([0-9.]+)', landscape['庭院'])[1]),
    }
    lighting = dict(table(ui, '## 表 U14a ·'))
    sun = numbers(lighting['太阳方位与高度'])
    faces = numbers(lighting['三面明度'])
    mixes = numbers(re.sub(r'#[0-9A-Fa-f]{6}', '', lighting['冷暖混色']))
    alpha = numbers(re.sub(r'#[0-9A-Fa-f]{6}', '', lighting['投影层与接触层']))
    contact = numbers(lighting['接触范围'])
    result['lighting'] = {
        'sun_west_south_degrees': sun[0], 'sun_height_degrees': sun[1],
        'light_face_reduction': abs(faces[0]), 'dark_face_reduction': abs(faces[1]),
        'cold_tint': colors(lighting['冷暖混色'])[0], 'warm_tint': colors(lighting['冷暖混色'])[1],
        'cold_mix': mixes[0]/100, 'warm_mix': mixes[1]/100,
        'shadow_color': colors(lighting['投影层与接触层'])[0],
        'shadow_alpha': alpha[0], 'contact_alpha': alpha[1],
        'contact_expand_px': contact[0], 'contact_feather_px': contact[1],
        'mask_long_edge': int(numbers(lighting['遮罩输出'])[0]),
        'union_resolution': numbers(lighting['运行合成'])[0],
        'progress_steps': int(numbers(lighting['运行合成'])[-1]),
        'default_half_width': numbers(lighting['默认尺度'])[0],
        'default_plot_coverage': numbers(lighting['默认尺度'])[1],
        'compound_base': colors(lighting['基座顶色'])[0],
        'historic_stone': colors(lighting['基座顶色'])[1],
    }
    diagnosis = table(ui, '## 表 U10')
    result['visual_diagnosis'] = {key: (value if value.startswith('#') else numbers(value)[0])
                                  for key, value, _ in diagnosis}
    result['sources'] = {name: hashlib.sha256(read(name).encode()).hexdigest()
                         for name in ['spec.audio.md', 'spec.city.md', 'spec.harmony.md', 'spec.proposal.md', 'spec.ui.md']}
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
