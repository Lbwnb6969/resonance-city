"""Independently meter the round-60 fixed-gain PCM with FFmpeg and 400 ms RMS."""
from pathlib import Path
import hashlib
import json
import numpy as np
from analyze_loudness import measure

ROOT = Path(__file__).resolve().parents[1]
DIRECTORY = ROOT / '验证记录/Demo/AUDIO-008_第60轮'
RATE = 22050


def main():
    reports = {}
    for count in [27, 64]:
        name = f'main_{count}'
        path = DIRECTORY / f'{name}.f32'
        drone_path = DIRECTORY / f'{name}__drone.f32'
        report = measure(path, RATE)
        mix = np.fromfile(path, dtype='<f4').reshape(-1, 2).astype(np.float64)
        drone = np.fromfile(drone_path, dtype='<f4').reshape(-1, 2).astype(np.float64)
        assert mix.shape == drone.shape == (RATE * 16, 2)
        width, hop = round(RATE * .4), round(RATE * .01)
        starts = np.arange(0, len(mix) - width + 1, hop)
        energies = [np.r_[0., np.cumsum(np.sum(track ** 2, axis=1))]
                    for track in [mix, drone]]
        powers = [e[starts + width] - e[starts] for e in energies]
        ratios = np.sqrt(powers[1] / powers[0])
        report.update(pcm_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                      drone_sha256=hashlib.sha256(drone_path.read_bytes()).hexdigest(),
                      minimum_drone_rms_ratio=float(ratios.min()),
                      worst_window_seconds=float(starts[ratios.argmin()] / RATE),
                      window_count=len(starts), window_seconds=.4, hop_seconds=hop / RATE)
        report['passed'] = report['true_peak_dbtp'] <= -3 and report['minimum_drone_rms_ratio'] >= .25
        reports[name] = report
        print(name, 'LUFS', report['integrated_lufs'], 'dBTP', report['true_peak_dbtp'],
              'minimum drone RMS', report['minimum_drone_rms_ratio'])
    result = {'status': 'PASS' if all(x['passed'] for x in reports.values()) else 'FAIL',
              'measurements': reports,
              'scope': 'Actual grouped DSP: 27 original fixed gain; 64 prepared-city gain. '
                       '16 seconds, FFmpeg input meter and every full 400 ms window at 10 ms hop; '
                       'not future-era timbres or arbitrary player retuning.'}
    (DIRECTORY / '混音测量.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    assert result['status'] == 'PASS'


if __name__ == '__main__':
    main()
