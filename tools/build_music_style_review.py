"""Make provisional scene/style recommendations from verified measurements.

These are editorial candidates, never generation provenance or listening approval.
"""
import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
META = ROOT / '数据/音乐制作'
LABELS = {'pastoral': '古典田园河湾', 'renaissance': '文艺复兴连拱城',
          'clockwork': '蒸汽钟表与花房', 'modern': '现代生态交响城',
          'mixed_reserve': '跨时代储备', 'special': '采样 / 环境素材'}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build():
    library = json.loads((META / '音乐库目录_20261103.json').read_text(encoding='utf-8'))
    prompts = {p['id']: p for p in json.loads((ROOT / library['prompt_index']).read_text(encoding='utf-8'))['prompts']}
    curation = json.loads((ROOT / library.get('reserve_curation', library['active_curation'])).read_text(encoding='utf-8'))
    reviews = json.loads((ROOT / library['user_reviews']).read_text(encoding='utf-8')) if library.get('user_reviews') else {'reviews': []}
    user_reviews = {s['source_id']: s for s in reviews['reviews']}
    stems = {s['source_sha256']: s for s in curation['songs']}
    handoff = json.loads((META / '游戏音乐施工包_20261103.json').read_text(encoding='utf-8'))
    kinds = {s['source_id']: s['kind'] for s in handoff['packs']}
    recommendations = []
    for song in library['originals']:
        metadata = song.get('analysis', {})
        summary_path = ROOT / metadata['path']
        if digest(summary_path) != metadata['sha256']:
            raise ValueError(f'Analysis changed: {summary_path}')
        summary = json.loads(summary_path.read_text(encoding='utf-8'))
        if summary['source_sha256'] != song['source_id'] or digest(ROOT / song['source']) != song['source_id']:
            raise ValueError(f'Source/analysis mismatch: {song["name"]}')
        lib, ess = summary['librosa'], summary['essentia']
        centroid = float(lib['spectral_centroid_hz']['mean'][0])
        onset = float(ess['onset_rate'])
        groups = stems.get(song['source_id'], {}).get('groups', {})
        ratios = {name: item['measurement']['relative_rms_db']
                  for name, item in groups.get('coarse_six', {}).get('kept', {}).items()}
        piano, guitar, drums, bass = (ratios.get(k, -100.) for k in ['piano', 'guitar', 'drums', 'bass'])
        era, confidence = 'mixed_reserve', '低：统计特征不能唯一识别历史风格'
        reasons = [f'频谱质心均值 {centroid:.0f} Hz；起音率估计 {onset:.2f}/秒']
        scenes = []
        if kinds.get(song['source_id'], 'music') != 'music':
            era, confidence = 'special', '沿用已登记的素材类别'
            scenes = ['专用素材储备，不进普通曲目自动池']
        elif song.get('prompt_assignment'):
            era, confidence = song['era'], '提示词来源由用户确认；实际听感适配仍待评'
            code = song['prompt_code'].split('-')[1]
            prompt = prompts[song['prompt_assignment']]
            scenes = prompt.get('scene_intents') or {'01': ['孤屋 / 简单城背景候选'], '02': ['轻营造背景候选'],
                      '03': ['围合庭院'], '04': ['水岸 / 曲路'],
                      '05': ['手作街区'], '06': ['高地 / 黄昏 / 广场']}.get(code, [prompt['section']])
            reasons.append('场景取自已确认编号对应的创作意图，未据此认定音频已达标')
        else:
            if piano > -9.:
                era, confidence = 'modern', '中低：钢琴型现代室内乐适配候选'
                reasons.append(f'钢琴模型槽相对母带 RMS {piano:.1f} dB；仅支持配器候选，不证明乐器纯净或生成来源')
            elif guitar > -9. and piano < guitar - 5.:
                era, confidence = 'pastoral', '中低：拨弦型田园适配候选，古乐仍需辨听'
                reasons.append(f'吉他模型槽 {guitar:.1f} dB、钢琴槽 {piano:.1f} dB；不能凭模型槽区分木吉他与鲁特琴')
            elif drums > -18. and bass > -15. and onset >= 2.5:
                era, confidence = 'clockwork', '低：起音 / 低音织体适合尝试钟表街区'
                reasons.append(f'打击起音模型槽 {drums:.1f} dB、低音槽 {bass:.1f} dB；不证明具有机械时代的作曲语言')
            else:
                reasons.append('其余器乐占比高或缺乏可区分证据，保留跨时代室内乐储备，不强塞进古乐时代')
            if onset >= 3.:
                scenes.append('流动水岸 / 曲路候选')
            elif centroid < 1100.:
                scenes.append('安静庭院 / 黄昏候选')
            else:
                scenes.append('开阔庭院 / 高地候选')
            if bass > -15.:
                scenes.append('围合暖院候选')
            if drums > -18.:
                scenes.append('手作街区候选')
            reasons.append('稀疏开局资格待查主奏与持续密度；未按低音量或慢速直接批准')
        if song.get('content_flags', {}).get('filename_voice_marker'):
            reasons.append('用户文件名明确标有with voice；保留原件，人声内容与可用伴奏仍待核，不进纯器乐背景默认')
            scenes.append('带人声标记版本，单独试听；不自动作为稀疏器乐背景')
        user = user_reviews.get(song['source_id'])
        if user:
            user_eras = {label: key for key, label in LABELS.items()}
            user_eras.update({'田园': 'pastoral', '机械': 'clockwork', '文艺复兴': 'renaissance', '现代': 'modern'})
            era = user_eras.get(user['era'], era)
            confidence = '用户原曲听评优先；分轨与运行适配独立待验'
            if user.get('density'):
                scenes = [user['density'] + '（用户听评）']
            reasons.insert(0, '用户听评：' + user.get('notes', '') + '；' + user.get('verdict', '待评'))
        recommendations.append({'source_id': song['source_id'], 'name': song['name'],
            'era': era, 'era_label': LABELS[era], 'scenes': scenes, 'confidence': confidence,
            'reasons': reasons, 'model_slot_relative_rms_db': ratios,
            'analysis': metadata['path'], 'analysis_sha256': metadata['sha256'],
            'user_review': user, 'full_mix_user_verdict': user.get('verdict') if user else None,
            'basis': 'verified offline measurements and explicitly confirmed provenance; no style recognition model or subjective listening',
            'listening_approved': False, 'automatic_runtime_adoption': False})
    output = META / '音乐分类建议_20261104.json'
    output.write_text(json.dumps({'schema': 'music_style_scene_review_v1', 'policy':
        'Provisional editorial fit, separate from exact prompt provenance. Retain every older original as reserve.',
        'counts': dict(Counter(s['era_label'] for s in recommendations)),
        'songs': recommendations}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    library['style_review'] = output.relative_to(ROOT).as_posix()
    (META / '音乐库目录_20261103.json').write_text(json.dumps(library, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'songs': len(recommendations), 'counts': dict(Counter(s['era_label'] for s in recommendations))}, ensure_ascii=False))


if __name__ == '__main__':
    build()
