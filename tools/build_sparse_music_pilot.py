"""Explicit same-source sparse candidate; source slots are not listening approval."""
import hashlib, json, time, wave
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'数据/音乐资产/游戏音乐包/20261106_sparse_v2/1_02'

def sha(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def save(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

def local(path):
    return 'res://'+Path(path).resolve().relative_to(ROOT).as_posix()

def read_pcm(row, frames):
    path = Path(row['path'])
    assert sha(path) == row['sha256']
    with wave.open(str(path), 'rb') as stream:
        assert (stream.getnchannels(), stream.getsampwidth(), stream.getframerate(), stream.getnframes()) == (2, 2, 44100, frames)
        return np.frombuffer(stream.readframes(frames), dtype='<i2').reshape(-1, 2).astype(np.float32)/32768

def build():
    began = time.monotonic()
    OUT.mkdir(parents=True, exist_ok=False)
    curation = ROOT/'数据/音乐资产/目录/20261105_reserve_v1/curation.json'
    song = next(s for s in json.loads(curation.read_text(encoding='utf-8'))['songs'] if s['name'] == '1-02.mp3')
    frames = song['frames']; group = song['groups']['coarse_six']['kept']
    master = read_pcm(song['full_mix'], frames)
    background = read_pcm(group['guitar'], frames)
    body = read_pcm(group['other'], frames)
    residual = master-background-body
    components = [background, body, residual]
    peak_bound = float(np.max(sum(np.abs(v) for v in components)))
    gain = min(1., .72/max(peak_bound, 1e-12))
    layers, decoded = [], []
    for index, (name, role, layer, automatic_max) in enumerate([
        ('background', 'background', 1, 1.), ('body', 'response', 2, .45), ('detail', 'unassigned', 0, 0.)]):
        path = OUT/(name+'.wav')
        pcm = np.clip(np.rint(components[index]*gain*32768), -32768, 32767).astype('<i2')
        with wave.open(str(path), 'wb') as stream:
            stream.setparams((2, 2, 44100, frames, 'NONE', 'not compressed')); stream.writeframes(pcm.tobytes())
        decoded.append(pcm.astype(np.float32)/32768)
        layers.append({'id': name, 'role': role, 'layer': layer, 'source_id': song['source_sha256'],
                       'path': local(path), 'sha256': sha(path), 'automatic_max': automatic_max})
    error = float(np.max(np.abs(sum(decoded)-master*gain)))
    measured_bound = float(np.max(sum(np.abs(v) for v in decoded)))
    assert error <= 4/32768 and measured_bound < .721
    manifest = {'schema': 'city_sparse_music_v2', 'source_id': song['source_sha256'], 'name': '1-02 · 同源背景分层候选',
                'kind': 'music', 'era': 'pastoral', 'frames': frames, 'sample_rate': 44100, 'channels': 2,
                'common_gain': gain, 'full_mix': {**song['full_mix'], 'path': local(song['full_mix']['path'])},
                'layers': layers, 'operations': {'loop_enabled': False, 'same_source_only': True},
                'source_curation': {'path': local(curation), 'sha256': sha(curation)},
                'assignments': {'background': 'coarse_six guitar model slot; independent candidate, musical sparseness/listening unconfirmed',
                                'body': 'coarse_six other model slot; candidate spatial response, not confirmed instrument',
                                'detail': 'master minus background/body; unclassified residual, never added automatically'},
                'evidence': {'full_endpoint_max_error': error, 'all_gain_combinations_peak_bound': measured_bound,
                             'background_source_sha256': group['guitar']['sha256'], 'body_source_sha256': group['other']['sha256']},
                'runtime_ready': False, 'listening_approved': False, 'sparse_background_fit_confirmed': False}
    save(OUT/'bundle.json', manifest)
    catalog = {'schema': 'city_adaptive_catalog_v1', 'runtime_ready': False, 'listening_approved': False,
               'packs': [{'source_id': manifest['source_id'], 'name': manifest['name'], 'kind': 'music',
                          'manifest': local(OUT/'bundle.json'), 'manifest_sha256': sha(OUT/'bundle.json'), 'layer_count': 3}]}
    save(OUT.parent/'catalog.json', catalog)
    save(OUT/'production.json', {'seconds': time.monotonic()-began, 'frames': frames, 'gain': gain, 'evidence': manifest['evidence']})
    print(json.dumps({'manifest': local(OUT/'bundle.json'), 'seconds': time.monotonic()-began, 'evidence': manifest['evidence']}))

if __name__ == '__main__':
    build()
