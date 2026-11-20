"""Write the original Doorstep Breeze score and render aligned SFZ stems."""
import argparse
import json
from pathlib import Path
import struct
import subprocess
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
BPM = 64
BEATS_PER_BAR = 3
TICKS = 480
RATE = 44100
TAIL_BEATS = 6
HARP_OPENING_RMS = .024
SAMPLES = ROOT / '数据/音乐资产/开放音源_20261101'
RENDERER = SAMPLES / '制作工具/sfizz-1.2.3-win64/bin/Release/sfizz_render.exe'

# Width of the voicing changes over the form. The top notes are passing colors,
# with the two returns pared back to the lower register near the final cadence.
VOICINGS = {
    'D': (50, 57, 62, 64), 'D6': (50, 57, 59, 66), 'Bm': (47, 54, 59, 62),
    'G': (43, 55, 59, 62), 'Gadd9': (43, 55, 57, 62), 'A': (45, 57, 61, 64),
    'Asus': (45, 57, 62, 64), 'Em': (52, 55, 59, 66), 'F#m': (42, 54, 57, 61),
    'D/F#': (42, 57, 62, 66), 'G/B': (47, 55, 59, 62),
}
FORM = (
    'D', 'D6', 'Bm', 'Gadd9', 'D/F#', 'Em', 'Asus', 'D',
    'Bm', 'G', 'D/F#', 'A', 'Bm', 'G/B', 'Em', 'Asus',
    'Gadd9', 'D', 'F#m', 'Bm', 'Em', 'G', 'Asus', 'A',
    'D6', 'Gadd9', 'Bm', 'D/F#', 'Em', 'Asus', 'D', 'D',
    'Gadd9', 'D/F#', 'Asus', 'D',
)


def score(forecourt_response=False):
    events = {'background': [], 'body': [], 'motion': []}
    if forecourt_response:
        events['detail'] = []

    def add(stem, bar, beat, duration, pitch, velocity):
        events[stem].append((bar * BEATS_PER_BAR + beat, duration, pitch, velocity))

    for bar, chord in enumerate(FORM):
        root, inner, high, color = VOICINGS[chord]
        if bar in (7, 15, 23, 31, 35):
            add('background', bar, .10, 1.75, root, 53)
            add('background', bar, .48, 1.35, inner, 45)
            if bar != 35:
                add('background', bar, .82, 1.20, high, 41)
        else:
            add('background', bar, .06 if bar % 2 == 0 else .23, 1.85, root, 48 + bar % 4)
            add('background', bar, .55, 1.20, inner, 44)
            add('background', bar, 1.04 if bar % 4 in (0, 3) else 1.65, .95, high, 39 + bar % 3)
            if bar in (2, 5, 9, 13, 16, 19, 22, 25, 28, 32):
                add('background', bar, 2.10, .68, color, 39)
        if bar in (1, 4, 6, 9, 11, 13, 14, 17, 19, 21, 22, 25, 27, 29, 32, 34):
            add('body', bar, .87, 2.54, root - 12 if root >= 48 else root, 41)
        if bar in (3, 5, 10, 12, 18, 20, 21, 26, 28, 30, 33):
            add('motion', bar, 1.42, .72, high - 12, 36)
            if bar in (5, 12, 20, 26, 30):
                add('motion', bar, 2.20, .53, inner, 33)
        if forecourt_response and bar in (2, 7, 8, 14, 15, 17, 23, 24, 27, 31, 34):
            add('detail', bar, 2.04, .66, high, 39)
            if bar in (8, 17, 24, 31):
                add('detail', bar, 2.82, .98, root + 12, 35)
    return events


def delta_ticks(value):
    blocks = [value & 127]
    while value := value >> 7:
        blocks.insert(0, (value & 127) | 128)
    return bytes(blocks)


def authored_harmony(source_id, frames):
    bars = []
    for index, chord in enumerate(FORM, 1):
        end = round(index * BEATS_PER_BAR * 60 * RATE / BPM)
        bars.append({'end_frame': min(end, frames),
                     'pitch_classes': sorted({note % 12 for note in VOICINGS[chord]})})
        if end >= frames:
            break
    return {'schema': 'authored_bar_chords_v1', 'source_id': source_id, 'bars': bars}


def write_midi(path, notes, length):
    tempo = round(60_000_000 / BPM)
    payload = b'\x00\xff\x51\x03' + tempo.to_bytes(3, 'big') + b'\x00\xff\x58\x04\x03\x02\x18\x08'
    events = []
    for beat, duration, pitch, velocity in notes:
        events.append((round(TICKS * beat), 0x90, pitch, velocity))
        events.append((round(TICKS * (beat + duration)), 0x80, pitch, 0))
    cursor = 0
    for tick, status, pitch, value in sorted(events):
        payload += delta_ticks(tick - cursor) + bytes((status, pitch, value))
        cursor = tick
    payload += delta_ticks(length * TICKS - cursor) + b'\xff\x2f\x00'
    path.write_bytes(b'MThd' + struct.pack('>IHHH', 6, 0, 1, TICKS) + b'MTrk' + struct.pack('>I', len(payload)) + payload)


def load_render(path):
    import numpy as np

    with wave.open(str(path), 'rb') as stream:
        assert (stream.getnchannels(), stream.getsampwidth(), stream.getframerate()) == (2, 2, RATE)
        return np.frombuffer(stream.readframes(stream.getnframes()), dtype='<i2').reshape(-1, 2).astype(np.float32) / 32768


def write_wave(path, values):
    from build_sparse_music_pilot import local, sha

    with wave.open(str(path), 'wb') as stream:
        stream.setparams((2, 2, RATE, len(values), 'NONE', 'not compressed'))
        stream.writeframes(values.astype('<i2').tobytes())
    return {'path': local(path), 'sha256': sha(path)}


def write_score(out, forecourt_response=False):
    out.mkdir(parents=True, exist_ok=False)
    notes = score(forecourt_response)
    length = len(FORM) * BEATS_PER_BAR + TAIL_BEATS
    score_path = out / 'score.json'
    document = {'title': '屋前的风', 'bpm': BPM, 'beats_per_bar': BEATS_PER_BAR,
                'tail_beats': TAIL_BEATS, 'form': FORM,
                'event_fields': ['beat', 'length_beats', 'midi_pitch', 'velocity'], 'stems': notes}
    score_path.write_text(json.dumps(document, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    for stem, events in notes.items():
        write_midi(out / (stem + '.mid'), events, length)
    return score_path


def render(out, forecourt_response=False):
    import numpy as np

    from build_sparse_music_pilot import local, save, sha

    instruments = {
        'background': ('VCSL/Chordophones/Composite Chordophones/Folk Harp.sfz', 'background', 1, 'none', 1., 1.),
        'body': ('VSCO-2-CE/CelloEnsSusVib-Quiet.sfz', 'response', 2, 'enclosure', .43, .83),
        'motion': ('SalamanderGrandPiano/Salamander Grand Piano V3.sfz', 'motion', 4, 'flow', .34, .77),
    }
    if forecourt_response:
        instruments['detail'] = ('VSCO-2-CE/ClarinetSus.sfz', 'response', 2, 'civic', .30, .72)
    score_path = write_score(out, forecourt_response)
    audio = {}
    provenance = {}
    for stem, (sfz, _role, _layer, _control, _cap, balance) in instruments.items():
        midi = out / (stem + '.mid')
        source = SAMPLES / '音源' / sfz
        folder = out / ('render_' + stem)
        with (out / (stem + '.log')).open('wb') as log:
            subprocess.run([sys.executable, '-X', 'utf8', str(ROOT / 'tools/render_open_sample_midi.py'),
                            '--renderer', str(RENDERER), '--sfz', str(source), '--midi', str(midi),
                            '--out-dir', str(folder), '--sample-rate', str(RATE)],
                           check=True, stdout=log, stderr=subprocess.STDOUT)
        audio[stem] = load_render(folder / 'render.wav') * balance
        provenance[stem] = {'sfz': local(source), 'sfz_sha256': sha(source), 'midi_sha256': sha(midi),
                            'source_frames': len(audio[stem]), 'mix_balance': balance}
    frames = max(map(len, audio.values()))
    for stem, values in audio.items():
        audio[stem] = np.pad(values, ((0, frames - len(values)), (0, 0)))
    bound = float(np.max(sum(np.abs(values) for values in audio.values())))
    opening_rms = float(np.sqrt(np.mean(audio['background'][:RATE * 5] ** 2)))
    gain = min(HARP_OPENING_RMS / opening_rms, .68 / bound)
    quantized = {stem: np.rint(values * gain * 32768).astype(np.int32) for stem, values in audio.items()}
    last_sample = max(np.flatnonzero(np.any(values, axis=1))[-1] for values in quantized.values())
    frames = min(frames, int(last_sample) + 1 + round(RATE * .35))
    quantized = {stem: values[:frames] for stem, values in quantized.items()}
    master = sum(quantized.values())
    actual_bound = int(np.max(sum(np.abs(values) for values in quantized.values()))) / 32768
    assert actual_bound < .681
    master_row = write_wave(out / 'master.wav', master)
    source_id = master_row['sha256']
    layers = []
    for stem, (_sfz, role, layer, control, cap, _balance) in instruments.items():
        row = write_wave(out / (stem + '.wav'), quantized[stem])
        layers.append({**row, 'id': stem, 'source_id': source_id, 'role': role, 'layer': layer,
                       'control': control, 'automatic_max': cap})
    if forecourt_response:
        layers[-1]['label'] = '前场回应 · 单簧管'
    manifest = {
        'schema': 'city_sparse_music_v2', 'kind': 'music', 'era': 'pastoral', 'name': '屋前的风 · 原创分层',
        'source_id': source_id, 'frames': frames, 'sample_rate': RATE, 'channels': 2, 'common_gain': gain,
        'operations': {'loop_enabled': False, 'same_source_only': True}, 'full_mix': master_row, 'layers': layers,
        'authored_harmony': authored_harmony(source_id, frames),
        'score': {'path': local(score_path), 'sha256': sha(score_path)}, 'render_sources': provenance,
        'attribution': local(SAMPLES / 'ATTRIBUTION.txt'), 'automatic_candidate': False,
        'runtime_ready': False, 'listening_approved': False, 'sparse_background_fit_confirmed': False,
        'evidence': {'full_endpoint_max_error': 0., 'all_gain_combinations_peak_bound': actual_bound,
                     'background_opening_rms': float(np.sqrt(np.mean((quantized['background'][:RATE * 5] / 32768) ** 2)))},
    }
    if forecourt_response:
        manifest['name'] = '屋前的风 · 礼乐前场'
    save(out / 'bundle.json', manifest)
    print(f'{manifest["name"]}: {frames / RATE:.3f}s, peak bound {actual_bound:.4f}, source {source_id}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--score-only', action='store_true', help='Write the score and MIDI tracks without samples.')
    parser.add_argument('--forecourt-response', action='store_true', help='Include the sparse clarinet response.')
    args = parser.parse_args()
    if args.score_only:
        print(write_score(args.out.resolve(), args.forecourt_response))
    else:
        render(args.out.resolve(), args.forecourt_response)
