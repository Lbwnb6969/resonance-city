"""Build a readable index without altering canonical REA records."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
bundle_path = ROOT / 'outputs/townscaper_rea_evidence_v2.json'
bundle = json.loads(bundle_path.read_text(encoding='utf-8'))
metadata = json.loads((ROOT / 'work/reverse/il2cpp/script.json').read_text(encoding='utf-8-sig'))
aliases = {}
for method in metadata['ScriptMethod']:
    aliases.setdefault(method['Address'] + 0x10000000, set()).add(method['Name'])
names = {
    '0x103f7a90': 'WorldMaster.GetSaveString',
    '0x103f8420': 'WorldMaster.Load(string)',
    '0x10e6b480': 'Graph.ApplyAction',
    '0x10e73610': 'Graph.PaintVoxel',
}

def describe(procedure):
    matches = sorted(aliases.get(int(procedure['address'], 16), []))
    if len(matches) == 1:
        return matches[0]
    return procedure['name'] + (f'（元数据地址有 {len(matches)} 个别名，未消歧）' if matches else '')

records = sorted(bundle['records'], key=lambda r: int(r['parameters']['procedure'], 16))
assert len(records) == 4
assert all(r['subject']['digest']['sha256'] == '4aa99a8deaa9a322026094186ed283020a8b6d897f2777dbb330ebf0ca89532c' for r in records)
assert all(r['provider']['version'] == '12.1.4' for r in records)
assert all(r['normalized_result']['basic_blocks'] and r['normalized_result']['pseudocode'] for r in records)
out = ['# Townscaper REA 原生证据索引', '',
       'REA 6.4.0 / Ghidra 12.1.4 / Temurin JDK 21。完整记录保存在同目录的 `townscaper_rea_evidence_v2.json`，已通过 REA `inspect-evidence-bundle` 校验。', '',
       '目标 SHA-256：`4aa99a8deaa9a322026094186ed283020a8b6d897f2777dbb330ebf0ca89532c`。名称由独立的 IL2CPP 元数据按地址关联；本轮 REA 临时副本未加载发行包 PDB，因此原始 provider 名称仍为 `FUN_*`。', '',
       '| 方法 | 地址 | 函数体字节 | 基本块 | 调用者 | 被调用者 | 入/出引用 |',
       '|---|---|---:|---:|---:|---:|---:|']
for r in records:
    n = r['normalized_result']; p = n['procedure']; address = p['address']
    out.append(f"| {names[address]} | `{address}` | {p['body']['total_bytes']} | {len(n['basic_blocks'])} | {len(n['callers'])} | {len(n['callees'])} | {len(n['incoming_references'])}/{len(n['outgoing_references'])} |")
out += ['', '## 解释边界', '',
        '4 个 dossier 的 value flow 均未截断，已知省略的操作、输入和边均为 0。这只说明记录在当前分析模型中完整，不能推出运行时路径完整。', '',
        '每个函数体均有不连续范围。REA 记录把 `0x1018e950` 元数据初始化 thunk 标为 `hasNoReturn=true`，相应首次初始化分支的 fallthrough 被排除；这是 Ghidra 数据库的标记。独立原始字节校验确认该 thunk 跳到 `0x1015fca0`，其包装函数在 `0x1015fcb1` 有 RET 尾部；详见同目录的 `townscaper_initializer_return_check.json`（pefile/Capstone 观察，不是 REA Evidence）。这未实测嵌套调用是否返回，但不能把 no-return 标记当成实际永不返回的证明。发行包 PDB 支持的本地 Ghidra 输出保留了初始化后继续执行的伪代码。此差异必须保留，不能用 REA CFG 断言首次初始化分支实际终止。', '',
        '调用者数为 0 只表示当前模型未找到入站调用；共享地址别名不全部当成直接调用目标。函数内 def-use 不能替代跨函数内存别名或运行时接口分派证据。bundle 的 `unknowns` 为 0 表示没有注册残余条目，不表示调查不存在未知。']
for r in records:
    n = r['normalized_result']; address = n['procedure']['address']
    out += ['', '## '+names[address], '', '- Evidence：`'+r['evidence_id']+'`',
            '- 原始名称：`'+n['procedure']['name']+'`',
            '- 函数体范围：'+', '.join('`'+b['start']+'..'+b['end']+'`' for b in n['procedure']['body']['ranges']), '', '观察到的被调用函数：', '']
    for callee in n['callees']:
        out.append('- `'+callee['address']+'` — `'+describe(callee)+'`')
    out += ['', 'Provider 的基本块：', '', '| 开始 | 结束 | 后继 |', '|---|---|---|']
    for block in n['basic_blocks']:
        out.append('| `'+block['start']+'` | `'+block['end']+'` | '+', '.join('`'+v+'`' for v in block['successors'])+' |')
(ROOT / 'outputs/townscaper_native_evidence_summary.md').write_text('\n'.join(out)+'\n', encoding='utf-8')
print('Native evidence index: PASS, four target-bound records, pseudocode and CFG retained')
