"""Immutable candidate revision: reuse two existing synchronized WAVs in new roles."""
import copy
import json
import time
from pathlib import Path

import numpy as np

from build_sparse_music_pilot import ROOT, local, read_pcm, save, sha

RECIPE = ROOT / '数据/音乐制作/钟表花房背景修订_20261108.json'


def path(value):
    return ROOT / value.removeprefix('res://')


def audio(row, frames):
    return read_pcm({**row, 'path': str(path(row['path']))}, frames)


def build():
    began = time.monotonic()
    recipe = json.loads(RECIPE.read_text(encoding='utf-8'))
    prior = path(recipe['prior_manifest'])
    catalog_path = path(recipe['prior_catalog'])
    assert sha(prior) == recipe['prior_manifest_sha256']
    assert sha(catalog_path) == recipe['prior_catalog_sha256']
    manifest = json.loads(prior.read_text(encoding='utf-8'))
    assert manifest['source_id'] == recipe['source_id']
    assert manifest['schema'] == 'city_sparse_music_v2'
    assert manifest['assignments']['background'] == recipe['body_slots']
    assert manifest['assignments']['body'] == recipe['background_slots']
    original = copy.deepcopy(manifest)
    old_background, old_body, residual = manifest['layers']
    old_background['path'], old_body['path'] = old_body['path'], old_background['path']
    old_background['sha256'], old_body['sha256'] = old_body['sha256'], old_background['sha256']
    old_body['automatic_max'] = recipe['body_cap']
    manifest['name'] = recipe['name']
    manifest['recipe'] = {'path': local(RECIPE), 'sha256': sha(RECIPE), 'selection': recipe}
    manifest['assignments'].update(background=recipe['background_slots'], body=recipe['body_slots'])
    parts = [audio(row, manifest['frames']) for row in manifest['layers']]
    master = audio(manifest['full_mix'], manifest['frames'])
    error = float(np.max(np.abs(sum(parts) - master * manifest['common_gain'])))
    bound = float(np.max(sum(np.abs(part) for part in parts)))
    assert error <= 4 / 32768 and bound < .721
    rms = lambda a: float(np.sqrt(np.mean(a.astype(np.float64) ** 2)))
    manifest['evidence'].update(full_endpoint_max_error=error, all_gain_combinations_peak_bound=bound,
                                background_to_master_rms=rms(parts[0]) / rms(master))
    manifest['prior_version'] = {'path': local(prior), 'sha256': sha(prior)}
    out = path(recipe['output'])
    out.mkdir(parents=True, exist_ok=False)
    save(out / 'bundle.json', manifest)
    catalog = json.loads(catalog_path.read_text(encoding='utf-8'))
    changed = 0
    for row in catalog['packs']:
        if row['manifest'] == recipe['prior_manifest']:
            row.update(name=manifest['name'], manifest=local(out / 'bundle.json'),
                       manifest_sha256=sha(out / 'bundle.json'))
            changed += 1
    assert changed == 1
    catalog['prior_catalog'] = {'path': local(catalog_path), 'sha256': sha(catalog_path)}
    save(out / 'catalog.json', catalog)
    save(out / 'production.json', {'seconds': time.monotonic() - began, 'reused_wave_files': 3,
                                  'new_audio_files': 0, 'packages_changed': changed,
                                  'old_manifest_unchanged': sha(prior) == recipe['prior_manifest_sha256'],
                                  'old_background_rms': rms(parts[1]), 'new_background_rms': rms(parts[0]),
                                  'full_endpoint_max_error': error, 'all_gain_combinations_peak_bound': bound,
                                  'listening_approved': False})
    print(json.dumps({'catalog': local(out / 'catalog.json'), 'catalog_sha256': sha(out / 'catalog.json'),
                      'old_manifest_unchanged': original == json.loads(prior.read_text(encoding='utf-8'))}, ensure_ascii=False))


if __name__ == '__main__':
    build()
