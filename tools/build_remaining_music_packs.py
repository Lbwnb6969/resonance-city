"""Build explicit per-source candidate recipes; complete masters stay manual-only."""
import json, time, wave
from pathlib import Path
import numpy as np
from build_sparse_music_pilot import ROOT, sha, save, local, read_pcm

RECIPE = ROOT/'数据/音乐制作/剩余新曲运行配方_20261106.json'
OUT = ROOT/'数据/音乐资产/游戏音乐包/20261106_remaining_v2'

def render(song, recipe, curation):
    frames = song['frames']; master = read_pcm(song['full_mix'], frames)
    folder = OUT/recipe['folder']; folder.mkdir()
    source = song['source_sha256']; complete = recipe['mode'] == 'complete_manual_only'
    common = {'source_id': source, 'kind': 'music', 'era': recipe['era'], 'frames': frames,
              'sample_rate': 44100, 'channels': 2, 'full_mix': {**song['full_mix'], 'path': local(song['full_mix']['path'])},
              'operations': {'loop_enabled': False, 'same_source_only': True},
              'source_curation': {'path': local(curation), 'sha256': sha(curation)},
              'recipe': {'path': local(RECIPE), 'sha256': sha(RECIPE), 'selection': recipe},
              'automatic_candidate': not complete, 'runtime_ready': False, 'listening_approved': False,
              'sparse_background_fit_confirmed': False}
    if complete:
        peak = float(np.max(np.abs(master))); assert peak < .82
        manifest = {**common, 'schema': 'city_adaptive_music_v1', 'name': song['name'][:-4]+' · 完整曲（仅手选）',
                    'common_gain': 1., 'layers': [{**common['full_mix'], 'id': 'core', 'min_gain': 1., 'max_gain': 1.}],
                    'manual_only_reason': '用户文件名标记含人声；未声明已去人声。' if song['name'].startswith('1-10') else '保留完整场景作品；未制作独立背景。',
                    'evidence': {'full_endpoint_max_error': 0., 'all_gain_combinations_peak_bound': peak}}
    else:
        group = song['groups'][recipe['group']]['kept']
        slots = recipe['background_slots']+[k for v in recipe['voices'] for k in v['slots']]
        assert len(slots) == len(set(slots))
        parts = [sum(read_pcm(group[k], frames) for k in recipe['background_slots'])]
        descriptions = [{'id': 'background', 'role': 'background', 'layer': 1, 'automatic_max': 1., 'control': 'none', 'label': '背景'}]
        labels = {'enclosure': '围合回应', 'flow': '流动回应', 'craft': '手作细节', 'highland': '高处回应'}
        for voice in recipe['voices']:
            parts.append(sum(read_pcm(group[k], frames) for k in voice['slots']))
            descriptions.append({'id': voice['id'], 'role': voice['role'], 'layer': voice['layer'],
                                 'automatic_max': voice['cap'], 'control': voice['control'], 'label': labels[voice['control']]})
        parts.append(master-sum(parts)); descriptions.append({'id': 'detail', 'role': 'unassigned', 'layer': 0,
                                                             'automatic_max': 0., 'control': 'none', 'label': '保留声部'})
        assert len(parts) <= 4
        bound = float(np.max(sum(np.abs(p) for p in parts))); gain = min(1., .72/max(bound, 1e-12))
        decoded, layers = [], []
        for data, description in zip(parts, descriptions):
            path = folder/(description['id']+'.wav'); values = np.clip(np.rint(data*gain*32768), -32768, 32767).astype('<i2')
            with wave.open(str(path), 'wb') as stream:
                stream.setparams((2, 2, 44100, frames, 'NONE', 'not compressed')); stream.writeframes(values.tobytes())
            layers.append({**description, 'source_id': source, 'path': local(path), 'sha256': sha(path)})
            decoded.append(values.astype(np.float32)/32768)
        error = float(np.max(np.abs(sum(decoded)-master*gain)))
        measured_bound = float(np.max(sum(np.abs(p) for p in decoded)))
        assert error <= (len(parts)+1)/32768 and measured_bound < .721
        rms = lambda data: float(np.sqrt(np.mean(data.astype(np.float64)**2)))
        manifest = {**common, 'schema': 'city_sparse_music_v2', 'name': song['name'][:-4]+' · 同源分层候选',
                    'common_gain': gain, 'layers': layers, 'source_group': recipe['group'],
                    'source_slots': {k: {'path': local(group[k]['path']), 'sha256': group[k]['sha256']} for k in slots},
                    'evidence': {'full_endpoint_max_error': error, 'all_gain_combinations_peak_bound': measured_bound,
                                 'background_to_master_rms': rms(parts[0])/rms(master)},
                    'assignments_listening_confirmed': False}
    save(folder/'bundle.json', manifest)
    return {'source_id': source, 'name': manifest['name'], 'kind': 'music', 'manifest': local(folder/'bundle.json'),
            'manifest_sha256': sha(folder/'bundle.json'), 'layer_count': len(manifest['layers']),
            'automatic_candidate': not complete}

def build():
    began = time.monotonic(); recipe = json.loads(RECIPE.read_text(encoding='utf-8'))
    curation = ROOT/recipe['curation'][6:]; songs = {s['source_sha256']: s for s in json.loads(curation.read_text(encoding='utf-8'))['songs']}
    parent = ROOT/recipe['parent_catalog'][6:]; packs = json.loads(parent.read_text(encoding='utf-8'))['packs'].copy()
    for row in recipe['songs']:
        if row['mode'] == 'sparse_candidate':
            keys = row['background_slots']+[k for v in row['voices'] for k in v['slots']]
            assert all(k in songs[row['source_id']]['groups'][row['group']]['kept'] for k in keys)
    OUT.mkdir(parents=True, exist_ok=False)
    for row in recipe['songs']:
        pack = render(songs[row['source_id']], row, curation); packs.append(pack); print(pack['name'], flush=True)
    save(OUT/'catalog.json', {'schema': 'city_adaptive_catalog_v1', 'packs': packs, 'runtime_ready': False, 'listening_approved': False,
                            'parent_catalog': local(parent), 'parent_catalog_sha256': sha(parent)})
    save(OUT/'production.json', {'seconds': time.monotonic()-began, 'new_packages': len(recipe['songs']), 'total_added_entries': len(packs)})
    print('COMPLETE', time.monotonic()-began, flush=True)

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--recipe', type=Path, default=RECIPE)
    parser.add_argument('--out', type=Path, default=OUT)
    args = parser.parse_args()
    RECIPE = args.recipe.resolve()
    OUT = args.out.resolve()
    build()
