"""Read-only metadata coverage inventory and deduplicated native export manifests.

Image ownership comes from the TypeDefIndex ranges emitted by Il2CppDumper,
not from a name search. Empty-namespace nested types inherit their enclosing
type's namespace within that image. This is a metadata inventory, not a claim
that native bodies were all decompiled or behavior verified.
"""
from pathlib import Path
import bisect
import collections
import hashlib
import json
import re

BASE = Path(__file__).resolve().parent.parent
SRC = BASE / 'work/reverse/il2cpp'
OUT = BASE / 'outputs'
IMAGE_BASE = 0x10000000


def canonical(name):
    # Remove generic type arguments, preserving compiler-generated <Foo>d__.
    chars = []
    pos = 0
    while pos < len(name):
        if name[pos] == '<' and pos > 0 and (name[pos - 1].isalnum() or name[pos - 1] == '_'):
            depth = 1
            pos += 1
            while pos < len(name) and depth:
                depth += (name[pos] == '<') - (name[pos] == '>')
                pos += 1
        else:
            chars.append(name[pos])
            pos += 1
    return ''.join(chars).replace('/', '.')


def subsystem(name, category):
    if category == 'platform-sdk':
        return 'platform-sdk'
    if name.startswith('Os.Hex.'):
        return 'hex-math'
    if name.startswith('Os.Utils.'):
        return 'author-helpers'
    if name.startswith('Placemaker.Graphs.'):
        return 'graph-topology'
    if name.startswith(('Placemaker.Quads.', 'Placemaker.GridGenerator')):
        return 'grid-generation'
    if name.startswith('Placemaker.Modules.'):
        return 'module-mesh-generation'
    if name.startswith('Placemaker.Props.'):
        return 'props-decorations'
    if name.startswith('Placemaker.Life.'):
        return 'life-birds'
    if name.startswith('Placemaker.Ui.'):
        return 'ui'
    if name.startswith('Placemaker.Audio.') or name == 'Beatbox':
        return 'audio'
    if name.startswith('Placemaker.SceneProcessing.'):
        return 'scene-processing'
    if name.startswith(('Placemaker.ModuleBuilder', 'Placemaker.ModuleMath', 'Placemaker.WaveFunctionCollapse', 'Placemaker.ByteQube')):
        return 'module-mesh-generation'
    short = name.removeprefix('Placemaker.').split('.')[0]
    if re.search('Save|TextSave|Serialize', short):
        return 'save-storage-codec'
    if re.search('History|ActionStack|Undo', short):
        return 'history-undo'
    if re.search('Input|Click|Cursor|Hover|Camera|Drag|Touch|Maker', short):
        return 'input-camera-building'
    if name.startswith('Placemaker.WorldMaster'):
        return 'world-state'
    if name.startswith('Placemaker.'):
        return 'world-rendering-support'
    return 'application-integration-support'


def main():
    dump_path = SRC / 'dump.cs'
    script_path = SRC / 'script.json'
    raw = dump_path.read_bytes()
    lines = raw.decode('utf-8').splitlines()
    images = []
    types = []
    ns = ''
    for line_no, line in enumerate(lines, 1):
        image = re.match(r'// Image (\d+): (.+) - (\d+)$', line)
        if image:
            images.append({'index': int(image[1]), 'name': image[2], 'type_start': int(image[3])})
        if line.startswith('// Namespace: '):
            ns = line[len('// Namespace: '):]
        decl = re.match(r'^(.+) // TypeDefIndex: (\d+)$', line)
        if decl:
            name_match = re.search(r'\b(class|struct|enum|interface) (.+?)(?: : |$)', decl[1])
            if not name_match:
                raise ValueError(f'Unparsed type declaration at {line_no}: {line}')
            types.append({'type_index': int(decl[2]), 'namespace': ns,
                          'name': name_match[2], 'kind': name_match[1],
                          'declaration': decl[1], 'dump_line': line_no})
    assert [t['type_index'] for t in types] == list(range(len(types)))
    starts = [i['type_start'] for i in images]
    image_types = collections.defaultdict(list)
    for t in types:
        t['image'] = images[bisect.bisect_right(starts, t['type_index']) - 1]['name']
        image_types[t['image']].append(t)

    def fullname(t, seen=None):
        if 'full_name' in t:
            return t['full_name']
        if t['namespace']:
            result = t['namespace'] + '.' + t['name']
        elif '.' in t['name']:
            candidates = [p for p in image_types[t['image']]
                          if p != t and canonical(t['name']).startswith(canonical(p['name']) + '.')]
            if candidates:
                # Longest enclosing name first; nearest declaration disambiguates
                # repeated short parent names in unrelated namespaces.
                p = min(candidates, key=lambda x: (-len(x['name']), abs(x['type_index'] - t['type_index'])))
                result = fullname(p)[:-len(p['name'])] + t['name']
            else:
                result = t['name']
                t['namespace_resolution'] = 'unresolved-enclosing-type'
        else:
            result = t['name']
        t['full_name'] = result
        return result

    method_rvas = {}
    # These global-scope declarations live in the shipped application image;
    # authorship is unknown, so label application integration, not author-owned.
    for t in types:
        name = fullname(t)
        img = t['image']
        if img == 'Assembly-CSharp.dll':
            if name.startswith(('Placemaker.', 'Os.Hex.', 'Os.Utils.')):
                category = 'application'
            elif name.startswith(('Rewired.', 'I2.', 'SFB.', 'CielaSpike.')):
                category = 'bundled-third-party'
            elif name.startswith('ExampleScript'):
                category = 'bundled-example-provenance-unconfirmed'
            elif name.startswith(('<Module>', '<PrivateImplementationDetails>')):
                category = 'application-generated-support'
            else:
                category = 'application-integration'
        elif img.startswith('FuryStudios.'):
            category = 'platform-sdk'
        elif img.startswith(('UnityEngine', 'Unity.Mathematics', 'Unity.TextMeshPro')):
            category = 'unity-managed-runtime'
        elif img.startswith(('mscorlib', 'System', 'Mono.', 'Microsoft.')):
            category = 'dotnet-managed-runtime'
        else:
            category = 'bundled-third-party'
        t['category'] = category
        t['subsystem'] = subsystem(name, category) if category.startswith('application') or category == 'platform-sdk' else category
        end_line = types[t['type_index'] + 1]['dump_line'] - 1 if t['type_index'] + 1 < len(types) else len(lines)
        # Stop at the next namespace header rather than ingesting its attributes.
        body = lines[t['dump_line']:end_line]
        methods = []
        section = ''
        fields = []
        pending = None
        for offset, line in enumerate(body, t['dump_line'] + 1):
            stripped = line.strip()
            if stripped.startswith('// Namespace:'):
                break
            if stripped in ('// Fields', '// Properties', '// Methods'):
                section = stripped[3:]
            if section == 'Fields' and not stripped.startswith(('//', '[', '{', '}')) and stripped:
                fields.append({'declaration': stripped, 'dump_line': offset})
            rva_match = re.match(r'^// RVA: (0x[0-9A-Fa-f]+|-1) Offset:', stripped)
            if section == 'Methods' and rva_match:
                pending = rva_match[1]
            elif pending is not None and stripped and not stripped.startswith(('//', '[', '/*', '|')):
                if '(' not in stripped:
                    raise ValueError(f'Unparsed method declaration at {offset}: {stripped}')
                methods.append({'signature': stripped, 'dump_line': offset,
                                'rva': int(pending, 16) if pending != '-1' else None,
                                'abstract_or_interface': ' abstract ' in ' ' + stripped or t['kind'] == 'interface'})
                pending = None
        t['method_definitions'] = len(methods)
        t['methods_with_direct_rva'] = sum(m['rva'] is not None for m in methods)
        t['methods_without_direct_rva'] = sum(m['rva'] is None for m in methods)
        t['abstract_or_interface_methods'] = sum(m['abstract_or_interface'] for m in methods)
        method_rvas[t['type_index']] = {m['rva'] for m in methods if m['rva'] is not None}
        if category.startswith('application') or category == 'platform-sdk':
            t['fields'] = fields
            t['methods'] = methods

    index = collections.defaultdict(list)
    for t in types:
        index[canonical(t['full_name'])].append(t)
    script = json.loads(script_path.read_text(encoding='utf-8'))
    script_methods = script['ScriptMethod']
    native_by_rva = collections.defaultdict(list)
    selected = []
    script_categories = collections.Counter()
    unbound = []
    for m in script_methods:
        owner = m['Name'].split('$$', 1)[0]
        candidates = index.get(canonical(owner), [])
        if len(candidates) > 1:
            matched_rvas = [t for t in candidates if m['Address'] in method_rvas[t['type_index']]]
            if len(matched_rvas) == 1:
                candidates = matched_rvas
        if len(candidates) == 1:
            t = candidates[0]
            category = t['category']
            m['type_index'] = t['type_index']
            m['image'] = t['image']
            m['category'] = category
            m['subsystem'] = t['subsystem']
        else:
            categories = {t['category'] for t in candidates}
            category = next(iter(categories)) if len(categories) == 1 else 'unresolved-metadata-owner'
            m['category'] = category
            m['candidate_type_indices'] = [t['type_index'] for t in candidates]
            if category == 'platform-sdk':
                m['subsystem'] = 'platform-sdk'
            unbound.append({'name': m['Name'], 'rva': m['Address'], 'candidate_type_indices': [t['type_index'] for t in candidates]})
        script_categories[category] += 1
        native_by_rva[m['Address']].append(m)
        if category.startswith('application') or category == 'platform-sdk':
            selected.append(m)

    selected_rvas = {m['Address'] for m in selected if m['Address'] > 0}
    definition_only = collections.defaultdict(list)
    for t in types:
        if t['category'].startswith('application') or t['category'] == 'platform-sdk':
            for m in t['methods']:
                if m['rva'] is not None and m['rva'] > 0 and m['rva'] not in selected_rvas:
                    name = m['signature'].split('(', 1)[0].rsplit(' ', 1)[-1]
                    definition_only[m['rva']].append({'Name': t['full_name'] + '$$' + name,
                                                      'Address': m['rva'], 'Signature': m['signature'],
                                                      'type_index': t['type_index'], 'image': t['image'],
                                                      'category': t['category'], 'subsystem': t['subsystem'],
                                                      'alias_source': 'dump_definition', 'dump_line': m['dump_line']})
    selected_rvas = sorted(selected_rvas | set(definition_only))
    methods_by_subsystem = collections.defaultdict(list)
    for m in selected:
        methods_by_subsystem[m['subsystem']].append(m)
    subsystem_stats = []
    for name, ms in sorted(methods_by_subsystem.items()):
        subsystem_stats.append({'subsystem': name, 'script_method_aliases': len(ms),
                                'unique_nonzero_rvas': len({m['Address'] for m in ms if m['Address'] > 0}),
                                'types_with_native_aliases': len({i for m in ms for i in ([m['type_index']] if 'type_index' in m else m['candidate_type_indices'])})})
    category_stats = []
    for cat in sorted({t['category'] for t in types}):
        ts = [t for t in types if t['category'] == cat]
        ms = [m for m in script_methods if m['category'] == cat]
        category_stats.append({'category': cat, 'types': len(ts),
                               'method_definitions': sum(t['method_definitions'] for t in ts),
                               'methods_with_direct_rva': sum(t['methods_with_direct_rva'] for t in ts),
                               'methods_without_direct_rva': sum(t['methods_without_direct_rva'] for t in ts),
                               'abstract_or_interface_methods': sum(t['abstract_or_interface_methods'] for t in ts),
                               'script_method_aliases': len(ms),
                               'unique_nonzero_rvas': len({m['Address'] for m in ms if m['Address'] > 0})})
    native = []
    for rva in selected_rvas:
        aliases = native_by_rva[rva]
        picked = [m for m in aliases if m in selected] + definition_only.get(rva, [])
        native.append({'rva': rva, 'va': IMAGE_BASE + rva,
                       'selected_aliases': picked,
                       'global_alias_count': len(aliases),
                       'global_aliases': [{'name': m['Name'], 'category': m['category'], 'signature': m['Signature']} for m in aliases],
                       'cross_category_shared': len({m['category'] for m in aliases}) > 1})
    inventory = {'format_version': 1,
                 'sources': [{'path': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in (dump_path, script_path)],
                 'image_base': IMAGE_BASE, 'images': images,
                 'totals': {'types': len(types), 'method_definitions': sum(t['method_definitions'] for t in types),
                            'script_method_aliases': len(script_methods),
                            'unique_nonzero_script_rvas': len({m['Address'] for m in script_methods if m['Address'] > 0}),
                            'selected_script_aliases': len(selected), 'selected_unique_nonzero_rvas': len(selected_rvas),
                            'selected_definition_only_rvas': len(definition_only),
                            'selected_cross_category_shared_rvas': sum(n['cross_category_shared'] for n in native),
                            'unresolved_category_aliases': script_categories['unresolved-metadata-owner'],
                            'unresolved_script_owners': len(unbound)},
                 'category_stats': category_stats, 'subsystem_stats': subsystem_stats,
                 'types': types, 'selected_native_procedures': native, 'unresolved_script_owners': unbound,
                 'limitations': ['ScriptMethod aliases are not independent native bodies.',
                                 'Identical names across images are resolved with direct definition RVA when unique; otherwise owner candidates are retained.',
                                 'Category can still be determined when every ambiguous owner belongs to the same category.',
                                 'Definition-only selected procedures have alias_source=dump_definition and are not counted as ScriptMethod aliases.',
                                 'RVA -1 means no direct definition address; generic instantiations can still have ScriptMethod addresses.',
                                 'No direct address does not independently establish stripping, absence, abstract status or inlining.',
                                 'Definition ownership is recovered from image ranges and type declarations; original source authorship is not proven.',
                                 'Metadata coverage does not establish decompilation, dynamic dispatch, runtime reachability or behavioral coverage.',
                                 'Subsystem categories are an inventory navigation convention, not original module boundaries.']}
    OUT.mkdir(exist_ok=True)
    (OUT / 'townscaper_method_inventory.json').write_text(json.dumps(inventory, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    for manifest, predicate in [('townscaper_application_methods.tsv', lambda x: x['category'].startswith('application')),
                                ('townscaper_platform_methods.tsv', lambda x: x['category'] == 'platform-sdk'),
                                ('townscaper_selected_methods.tsv', lambda x: True)]:
        rows = ['va\trva\tsubsystem\talias\tglobal_alias_count']
        for n in native:
            chosen = [m for m in n['selected_aliases'] if predicate(m)]
            if chosen:
                m = chosen[0]
                rows.append(f"0x{n['va']:08x}\t0x{n['rva']:x}\t{m['subsystem']}\t{m['Name']}\t{n['global_alias_count']}")
        (OUT / manifest).write_text('\n'.join(rows) + '\n', encoding='utf-8')
    print(json.dumps({'totals': inventory['totals'], 'category_stats': category_stats, 'subsystem_stats': subsystem_stats}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
