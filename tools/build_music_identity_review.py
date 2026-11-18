"""Build a local original-song/prompt review; never infer or publish assignments."""
import json
from pathlib import Path
from urllib.parse import quote

ROOT = Path(__file__).resolve().parents[1]


def build():
    library = json.loads((ROOT / '数据/音乐制作/音乐库目录_20261103.json').read_text(encoding='utf-8'))
    prompts = json.loads((ROOT / library['prompt_index']).read_text(encoding='utf-8'))['prompts']
    style = json.loads((ROOT / library['style_review']).read_text(encoding='utf-8')) if library.get('style_review') else {'songs': []}
    recommendations = {s['source_id']: s for s in style['songs']}
    songs = []
    for row in library['originals']:
        original = ROOT / row['source']
        if not original.is_file():
            raise FileNotFoundError(original)
        relative = original.relative_to(ROOT / '数据/音乐资产').as_posix()
        songs.append({'source_id': row['source_id'], 'name': row['name'],
                      'audio': '../' + quote(relative), 'prompt_assignment': row.get('prompt_assignment'),
                      'recommendation': recommendations.get(row['source_id'], {}),
                      'user_feedback': row.get('user_feedback'),
                      'stem_review': '../' + quote(row['stem_review']) if row.get('stem_review') else '../listening/listen.html',
                      'seconds': row.get('analysis', {}).get('duration_seconds')})
    data = json.dumps({'songs': songs, 'prompts': prompts}, ensure_ascii=False).replace('<', '\\u003c')
    destination = ROOT / '数据/音乐资产/identity/listen.html'
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(HTML.replace('__DATA__', data), encoding='utf-8')
    print(json.dumps({'page': str(destination), 'songs': len(songs), 'prompts': len(prompts),
                      'confirmed': sum(x['prompt_assignment'] is not None for x in songs)}, ensure_ascii=False))


HTML = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>原曲与提示词 · 听评对照</title>
<style>body{font:16px/1.7 system-ui;background:#eee9df;color:#293d36;max-width:1080px;margin:28px auto;padding:0 20px}section{background:#fffaf0;border:1px solid #bbc8b8;border-radius:14px;padding:20px;margin:18px 0}select,input,textarea,button{font:inherit;padding:9px;border:1px solid #a2af9e;border-radius:7px;background:#fffdf8;max-width:100%;box-sizing:border-box}select,textarea,audio{width:100%}label{display:block;margin:14px 0}button{cursor:pointer}small{color:#596e60}#prompt{white-space:pre-wrap}h1{font-size:28px}a{color:#315c49}</style>
<h1>原曲与提示词 · 听评对照</h1>
<p id="coverage"></p>
<p>先听原曲，再选择你认为对应的提示词。生成来源与适合的时代可以不同；无法确认时留空。记录保存在本浏览器，点“导出听评”下载后可交回工程。这里不修改原曲或游戏曲库。</p>
<section><label>按时代 / 用途初分<select id="group"><option value="">全部原曲</option></select></label><label>查找曲名<input id="search" placeholder="例如 2-01、4-05、Warm"></label>
<label>原曲<select id="song"></select></label><p id="identity"></p><audio id="audio" controls preload="none"></audio>
<p id="recommendation"></p><p id="feedback"></p>
<p><a id="original">直接打开原曲</a> · <a id="stem-link" href="../listening/listen.html">已有原始分轨试听</a> · <a href="../game/listen.html">现有 core / 颜色层对照</a></p>
<label>生成来源提示词（听评选择，尚非工程确认）<select id="assignment"></select></label>
<label>适合的时代 / 风貌<input id="era" placeholder="田园、文艺复兴、机械、现代、混合或不确定"></label>
<label>适用密度<select id="density"><option value="">待听评</option><option>空地 / 孤屋背景</option><option>丰富空间</option><option>前景聆听</option><option>专用采样 / 环境声</option><option>不适用</option></select></label>
<label>主观接受与否<select id="verdict"><option value="">待评</option><option>接受</option><option>不接受</option><option>需要再听</option></select></label>
<label>听感与分轨备注<textarea id="notes" rows="3" placeholder="例如：旋律太突出，不适合作开局；提示词身份暂不确定"></textarea></label>
<p id="saved"></p><button id="export">导出听评 JSON</button></section>
<section><h2>提示词原文</h2><label>浏览全部候选提示词<select id="browse"></select></label><p id="origin"></p><p id="prompt"></p>
<small>这是原索引中的历史提示词，不自动匹配，不用后来的精简提示词替换来源。多首曲可以来自同一提示词。</small></section>
<script>
const data=__DATA__, $=id=>document.getElementById(id), key='resonance-music-identity-review-v1';
$('coverage').textContent=`${data.songs.length} 份原始资产，${data.prompts.length} 条提示词；${data.songs.filter(s=>s.prompt_assignment).length} 份编号曲来源已由用户确认，其余来源待核。时代/场景初分是工程候选，不代表已听评或正式采用。旧曲全部保留为储备。`;
for(const label of [...new Set(data.songs.map(s=>s.recommendation.era_label).filter(Boolean))])$('group').append(option(label,label));
let reviews=Object.fromEntries(data.songs.filter(s=>s.recommendation.user_review).map(s=>[s.source_id,s.recommendation.user_review]));
try{const local=JSON.parse(localStorage.getItem(key)||'{}');for(const [id,entry] of Object.entries(local))if(!reviews[id]||(entry.updated_at||'')>=(reviews[id].updated_at||''))reviews[id]={...reviews[id],...entry}}catch(e){$('saved').textContent='浏览器记录读取失败；本次仍可导出。'}
function option(value,text){const o=document.createElement('option');o.value=value;o.textContent=text;return o}
for(const p of data.prompts){$('assignment').append(option(p.id,p.section+' ['+p.id+']'));$('browse').append(option(p.id,p.section+' ['+p.id+']'))}
$('assignment').prepend(option('','未确认 / 暂不归类'));
function showPrompt(id){const p=data.prompts.find(p=>p.id===id);$('origin').textContent=p?p.source+':'+p.line:'';$('prompt').textContent=p?.text||''}
function selected(){return data.songs.find(s=>s.source_id===$('song').value)}
function load(){const s=selected();$('audio').pause();if(!s){$('audio').removeAttribute('src');$('identity').textContent='没有匹配曲目';return}
 $('audio').src=s.audio;$('original').href=s.audio;$('stem-link').href=s.stem_review;$('identity').textContent='来源 ID：'+s.source_id+' · '+(s.seconds?s.seconds.toFixed(1)+' 秒':'时长待测')+' · '+(s.prompt_assignment?'生成提示词已由用户确认':'生成来源待确认');
 const rec=s.recommendation||{};$('recommendation').textContent=rec.era_label?`初分：${rec.era_label}；${(rec.scenes||[]).join('、')}。${rec.confidence}。依据：${(rec.reasons||[]).join('；')}`:'';
 $('feedback').textContent=s.user_feedback?'用户备注：'+s.user_feedback.quote:'';
 const r=reviews[s.source_id]||{};for(const id of ['assignment','era','density','verdict','notes'])$(id).value=r[id]??(id==='assignment'?s.prompt_assignment||'':id==='era'?rec.era_label||'':'');
 $('saved').textContent=r.updated_at?'已记录：'+r.updated_at:'尚无听评记录';const assigned=r.assignment??s.prompt_assignment;if(assigned){$('browse').value=assigned;showPrompt(assigned)}}
function filter(){const prior=$('song').value;$('song').replaceChildren();for(const s of data.songs.filter(s=>s.name.toLowerCase().includes($('search').value.toLowerCase())&&(!$('group').value||s.recommendation.era_label===$('group').value)))$('song').append(option(s.source_id,s.name));
 if([...$('song').options].some(o=>o.value===prior))$('song').value=prior;load()}
function save(){const s=selected();if(!s)return;const r={source_id:s.source_id,name:s.name,updated_at:new Date().toISOString(),status:'user_review_pending_engine_adoption'};
 for(const id of ['assignment','era','density','verdict','notes'])r[id]=$(id).value;reviews[s.source_id]=r;
 try{localStorage.setItem(key,JSON.stringify(reviews));$('saved').textContent='已保存到本浏览器，导出后可交回工程。'}catch(e){$('saved').textContent='浏览器存储不可用，请直接导出本次记录。'}}
for(const id of ['assignment','era','density','verdict','notes'])$(id).addEventListener('input',save);
$('assignment').addEventListener('change',()=>{if($('assignment').value){$('browse').value=$('assignment').value;showPrompt($('assignment').value)}});
$('browse').onchange=()=>showPrompt($('browse').value);$('song').onchange=load;$('search').oninput=filter;
$('group').onchange=filter;
$('export').onclick=()=>{const blob=new Blob([JSON.stringify({schema:'music_identity_listening_review_v1',reviews:Object.values(reviews)},null,2)],{type:'application/json'}),a=document.createElement('a'),u=URL.createObjectURL(blob);a.href=u;a.download='共鸣之城_音乐归属听评.json';a.click();setTimeout(()=>URL.revokeObjectURL(u),1000)};
filter();showPrompt($('browse').value);
</script></html>'''


if __name__ == '__main__':
    build()
