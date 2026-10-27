"""Read-only Unity object inventory and serialized component recovery."""
import collections
import hashlib
import json
from pathlib import Path
import sys

WORK = Path(__file__).resolve().parent
sys.path.insert(0, str(WORK / 'asset_pydeps'))
import UnityPy
from UnityPy.helpers.TypeTreeGenerator import TypeTreeGenerator
from UnityPy.helpers.TypeTreeNode import TypeTreeNode

ROOT = Path(r'D:\SteamLibrary\steamapps\common\Townscaper\Townscaper_Data')
OUT = WORK.parent / 'outputs'

class PlayerTypeTrees(TypeTreeGenerator):
    def get_nodes_up(self, assembly, fullname):
        key = assembly, fullname
        if key in self.cache:
            return self.cache[key]
        nodes = json.loads(self.get_nodes_as_json(assembly, fullname))
        # Generator 0.0.10 omits the 4-byte player alignment after base m_Enabled.
        # The UnityPy stock MonoBehaviour head establishes this alignment.
        for n in nodes:
            if n['m_Level'] == 1 and n['m_Name'] == 'm_Enabled':
                n['m_MetaFlag'] |= 16384
                break
        # Generator emits string[] as "string" containing Array<string>, while
        # UnityPy dispatches "string" as scalar before considering child arrays.
        # Preserve scalar string Array<char>, label only string[] as vector.
        for i, n in enumerate(nodes[:-3]):
            if n['m_Type'] == 'string' and nodes[i+1]['m_Type'] == 'Array' and nodes[i+3]['m_Type'] == 'string':
                n['m_Type'] = 'vector'
        node = TypeTreeNode.from_list(nodes)
        self.cache[key] = node
        return node

def digest(p):
    h = hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda: f.read(1048576), b''):
            h.update(b)
    return h.hexdigest()

def safe(v):
    if isinstance(v, bytes):
        return {'bytes': len(v), 'sha256': hashlib.sha256(v).hexdigest()}
    if isinstance(v, dict):
        return {str(k): ({'redacted': True, 'sha256': hashlib.sha256(str(val).encode()).hexdigest()} if k == 'm_AuthToken' else safe(val)) for k, val in v.items()}
    if isinstance(v, (list, tuple)):
        return [safe(val) for val in v]
    return v

def main():
    paths = sorted(p for p in ROOT.iterdir() if p.is_file() and (p.suffix == '.assets' or p.name.startswith('level') or p.name == 'globalgamemanagers'))
    paths += sorted(p for p in (ROOT/'Resources').iterdir() if p.is_file())
    env = UnityPy.load(*(str(p) for p in paths))
    trees = PlayerTypeTrees('2020.3.4f1')
    trees.load_local_dll_folder(str(WORK / 'reverse/il2cpp/DummyDll'))
    env.typetree_generator = trees
    records, components, failures = [], [], []
    serialized_files = []
    for f in env.files.values():
        if hasattr(f, 'externals'):
            serialized_files.append({'file': Path(f.name).name, 'version': f.unity_version, 'externals': [{'file_id': i+1, 'path': x.path} for i, x in enumerate(f.externals)]})
    counts = collections.Counter()
    for o in env.objects:
        f = Path(o.assets_file.name).name
        kind = o.type.name
        raw = o.get_raw_data()
        rec = {'file': f, 'path_id': o.path_id, 'type': kind, 'byte_offset': o.byte_start, 'byte_size': o.byte_size, 'raw_sha256': hashlib.sha256(raw).hexdigest()}
        counts[kind] += 1
        try:
            if kind == 'MonoBehaviour':
                head = o.parse_monobehaviour_head()
                script = head.m_Script.deref_parse_as_object()
                rec['script'] = {'namespace': script.m_Namespace, 'class': script.m_ClassName, 'assembly': script.m_AssemblyName}
                full = o.read_typetree()
                # Reject an offset-wrong schema even if it happens to consume all bytes.
                expected = {'m_FileID': head.m_Script.m_FileID, 'm_PathID': head.m_Script.m_PathID}
                if full.get('m_Script') != expected:
                    raise ValueError('Generated schema does not match validated MonoBehaviour head')
                rec['name'] = full.get('m_Name', '')
                rec['game_object'] = full.get('m_GameObject')
                rec['parsed'] = True
                components.append({'file': f, 'path_id': o.path_id, 'script': rec['script'], 'data': safe(full)})
            else:
                full = o.read_typetree()
                rec['name'] = full.get('m_Name', '')
                if kind in ('Shader',):
                    rec['name'] = full.get('m_ParsedForm', {}).get('m_Name', rec['name'])
                if kind in ('GameObject', 'Transform', 'RectTransform', 'MonoScript', 'PlayerSettings', 'BuildSettings', 'ResourceManager', 'TextAsset'):
                    rec['data'] = safe(full)
                elif kind == 'Texture2D':
                    rec['dimensions'] = [full.get('m_Width'), full.get('m_Height')]
                    rec['format'] = full.get('m_TextureFormat')
                elif kind == 'AudioClip':
                    rec['audio'] = {k: full.get(k) for k in ('m_Channels','m_Frequency','m_Length','m_CompressionFormat','m_Source')}
                elif kind == 'Mesh':
                    rec['mesh'] = {k: safe(full.get(k)) for k in ('m_SubMeshes','m_LocalAABB')}
                    rec['vertex_count'] = full.get('m_VertexData', {}).get('m_VertexCount')
                elif kind == 'Material':
                    rec['data'] = safe(full)
                elif kind not in ('Shader', 'Font', 'Sprite'):
                    rec['data'] = safe(full)
                rec['parsed'] = True
        except Exception as ex:
            rec['parsed'] = False
            rec['parse_error'] = str(ex)
            failures.append({'file': f, 'path_id': o.path_id, 'type': kind, 'script': rec.get('script'), 'error': str(ex)})
        records.append(rec)
    streams = sorted(p for p in ROOT.iterdir() if p.suffix in ('.resS','.resource'))
    report = {'target': str(ROOT), 'parser': 'UnityPy 1.25.4 + TypeTreeGeneratorAPI 0.0.10', 'typetree_source': 'Il2CppDumper DummyDll metadata; base m_Enabled aligned to player MonoBehaviour head; string[] root mapped to vector with original child nodes', 'input_files': [{'name': str(p.relative_to(ROOT)),'bytes':p.stat().st_size,'sha256':digest(p)} for p in paths], 'stream_files': [{'name': p.name, 'bytes':p.stat().st_size, 'sha256':digest(p)} for p in streams], 'serialized_files': serialized_files, 'objects': records, 'counts': dict(counts), 'component_count': len(components), 'parse_failures': failures, 'limitations': ['Static serialized values do not establish live SDK selection or executed behavior.', 'Recovered typetrees checked against consumed object bytes and MonoBehaviour header; original author source not recovered.']}
    (OUT/'townscaper_assets.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
    (OUT/'townscaper_asset_components.json').write_text(json.dumps(components, ensure_ascii=False, indent=2), encoding='utf8')
    default = next(x for x in components if x['file']=='sharedassets1.assets' and x['path_id']==1117)
    (OUT/'townscaper_default_save_asset.json').write_text(json.dumps(default, ensure_ascii=False, indent=2), encoding='utf8')
    print(json.dumps({'objects':len(records),'counts':dict(counts),'components':len(components),'failures':len(failures),'failure_types':dict(collections.Counter((r.get('script') or {}).get('class',r['type']) for r in failures))}, ensure_ascii=False))

if __name__ == '__main__':
    main()
