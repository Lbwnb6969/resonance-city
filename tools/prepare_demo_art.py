"""Build softer Demo images from the retained P0 palette slots, without editing sources."""
from pathlib import Path
import copy
import hashlib
import json

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / '资源/Demo城市'
PRODUCTION = ROOT / '资产/03_入库/Demo城市'
COLORS = ['#F4EEE8', '#C79083', '#9EADB8', '#A0B9A0', '#EBD6A9', '#DED6CD',
          '#B48279', '#BBC3C8', '#A5AFB5', '#CFD3D3', '#DECBB1', '#A67672',
          '#B8A494', '#7F8D98', '#8395A5', '#A7B3BE', '#CED7DC', '#809D8B',
          '#C2B19C', '#DCC5BD', '#C4D2BE', '#BDD0D6', '#BFB5C7', '#FAF4EB']


def rgb(color):
    return [int(color[i:i + 2], 16) for i in (1, 3, 5)]


def main():
    original = json.loads((ROOT / '资源/P0城市/manifest.json').read_text(encoding='utf-8'))
    old_palette = json.loads((ROOT / '资源/P0城市/palette.json').read_text(encoding='utf-8'))
    old_colors = np.array([rgb(item['hex']) for item in old_palette], dtype=np.float32)
    new_colors = np.array([rgb(color) for color in COLORS], dtype=np.float32)
    entries = []
    for original_entry in original['entries']:
        if original_entry['category'] not in ('residential', 'commercial', 'industrial', 'tree'):
            continue
        entry = copy.deepcopy(original_entry)
        source = ROOT / entry['texture']
        index_source = ROOT / entry['indexed_master']
        rgba = np.array(Image.open(source).convert('RGBA'))
        indexed = np.array(Image.open(index_source).convert('RGBA'))
        assert rgba.shape == indexed.shape
        slots = np.clip(np.rint((indexed[..., 0].astype(np.float32) - 8) / 10), 0, 23).astype(np.int32)
        before_luma = rgba[..., :3].astype(np.float32) @ np.array([.2126, .7152, .0722])
        base_luma = old_colors[slots] @ np.array([.2126, .7152, .0722])
        shade = .78 + .22 * np.clip(before_luma / np.maximum(base_luma, 1), 0, 1.3)
        rgba[..., :3] = np.clip(new_colors[slots] * shade[..., None], 0, 255).astype(np.uint8)
        rgba[rgba[..., 3] == 0, :3] = 0
        image = Image.fromarray(rgba)
        relative = '整图/' + entry['id'] + '.png'
        for directory in (RUNTIME, PRODUCTION):
            path = directory / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            image.save(path)
        entry['source_texture'] = entry['texture']
        entry['source_texture_sha256'] = hashlib.sha256(source.read_bytes()).hexdigest()
        entry['texture'] = '资源/Demo城市/' + relative
        entry['texture_sha256'] = hashlib.sha256((RUNTIME / relative).read_bytes()).hexdigest()
        entry['processing'] = 'P0 slot LUT -> Demo pastel palette; shade=0.78+0.22*source_shade; original alpha/origin retained'
        entry['availability'] = 'demo_style_candidate; user_visual_review_pending'
        entries.append(entry)
    manifest = {'schema_version': 1, 'camera': original['camera'], 'entries': entries,
                'palette': '资源/Demo城市/palette.json', 'human_art': 'PENDING',
                'source_manifest': '资源/P0城市/manifest.json'}
    palette = [dict(item, hex=COLORS[i]) for i, item in enumerate(old_palette)]
    for directory in (RUNTIME, PRODUCTION):
        (directory / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        (directory / 'palette.json').write_text(json.dumps(palette, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'DEMO_ART prepared {len(entries)} real images; P0 images and original models unchanged')


if __name__ == '__main__':
    main()
