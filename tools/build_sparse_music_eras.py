"""Explicit editorial recipes from one source/group each, with immutable outputs."""
import json, time, wave
from pathlib import Path
import numpy as np
from build_sparse_music_pilot import ROOT, sha, save, local, read_pcm

RECIPE = ROOT/'数据/音乐制作/稀疏四时代代表_20261106.json'
OUT = ROOT/'数据/音乐资产/游戏音乐包/20261106_sparse_eras_v2'

def render(song, recipe, curation):
    folder = OUT/recipe['folder']; folder.mkdir()
    frames = song['frames']; group = song['groups'][recipe['group']]['kept']
    assert not set(recipe['background_slots']) & set(recipe['body_slots'])
    source_rows = {k: group[k] for k in recipe['background_slots']+recipe['body_slots']}
    master = read_pcm(song['full_mix'], frames)
    background = sum(read_pcm(group[k], frames) for k in recipe['background_slots'])
    body = sum(read_pcm(group[k], frames) for k in recipe['body_slots'])
    parts = [background, body, master-background-body]
    bound = float(np.max(sum(np.abs(p) for p in parts)))
    gain = min(1., .72/max(bound, 1e-12)); layers = []; decoded = []
    for i, (key, role, layer, cap) in enumerate([
        ('background', 'background', 1, 1.), ('body', 'response', 2, recipe['body_cap']), ('detail', 'unassigned', 0, 0.)]):
        path = folder/(key+'.wav'); values = np.clip(np.rint(parts[i]*gain*32768), -32768, 32767).astype('<i2')
        with wave.open(str(path), 'wb') as stream:
            stream.setparams((2, 2, 44100, frames, 'NONE', 'not compressed')); stream.writeframes(values.tobytes())
        decoded.append(values.astype(np.float32)/32768)
        layers.append({'id': key, 'role': role, 'layer': layer, 'source_id': song['source_sha256'],
                       'path': local(path), 'sha256': sha(path), 'automatic_max': cap})
    error = float(np.max(np.abs(sum(decoded)-master*gain)))
    actual_bound = float(np.max(sum(np.abs(p) for p in decoded)))
    assert error <= 4/32768 and actual_bound < .721
    rms = lambda pcm: float(np.sqrt(np.mean(pcm.astype(np.float64)**2)))
    manifest = {'schema': 'city_sparse_music_v2', 'source_id': song['source_sha256'], 'name': recipe['label'],
        'kind': 'music', 'era': recipe['era'], 'frames': frames, 'sample_rate': 44100, 'channels': 2, 'common_gain': gain,
        'full_mix': {**song['full_mix'], 'path': local(song['full_mix']['path'])}, 'layers': layers,
        'operations': {'loop_enabled': False, 'same_source_only': True}, 'source_group': recipe['group'],
        'recipe': {'path': local(RECIPE), 'sha256': sha(RECIPE), 'selection': recipe},
        'source_curation': {'path': local(curation), 'sha256': sha(curation)},
        'source_slots': {k: {'path': local(v['path']), 'sha256': v['sha256']} for k, v in source_rows.items()},
        'evidence': {'full_endpoint_max_error': error, 'all_gain_combinations_peak_bound': actual_bound,
                     'background_to_master_rms': rms(background)/rms(master)},
        'assignments': {'background': recipe['background_slots'], 'body': recipe['body_slots'],
                        'detail': 'unclassified same-source residual, never added automatically', 'listening_confirmed': False},
        'runtime_ready': False, 'listening_approved': False, 'sparse_background_fit_confirmed': False}
    save(folder/'bundle.json', manifest)
    return {'source_id': song['source_sha256'], 'name': recipe['label'], 'kind': 'music',
            'manifest': local(folder/'bundle.json'), 'manifest_sha256': sha(folder/'bundle.json'), 'layer_count': 3}

def build():
    began = time.monotonic(); recipes = json.loads(RECIPE.read_text(encoding='utf-8'))
    curation = ROOT/recipes['curation'][6:]; songs = {s['source_sha256']: s for s in json.loads(curation.read_text(encoding='utf-8'))['songs']}
    OUT.mkdir(parents=True, exist_ok=False)
    pilot = ROOT/'数据/音乐资产/游戏音乐包/20261106_sparse_v2/catalog.json'
    packs = json.loads(pilot.read_text(encoding='utf-8'))['packs'].copy()
    for recipe in recipes['songs']:
        row = render(songs[recipe['source_id']], recipe, curation); packs.append(row); print(row['name'], flush=True)
    save(OUT/'catalog.json', {'schema': 'city_adaptive_catalog_v1', 'packs': packs, 'runtime_ready': False, 'listening_approved': False,
                            'pilot_catalog': local(pilot), 'pilot_catalog_sha256': sha(pilot)})
    save(OUT/'production.json', {'seconds': time.monotonic()-began, 'new_packages': 3, 'total_sparse_candidates': 4})
    print('COMPLETE', time.monotonic()-began, flush=True)

if __name__ == '__main__':
    build()
