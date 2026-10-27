"""Read-only original x86 evidence for wire pairing and ReturnProp paths."""
from pathlib import Path
import hashlib,json,re,sys,struct
BASE=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(BASE/'work/pydeps'))
import pefile
from capstone import Cs,CS_ARCH_X86,CS_MODE_32
target=Path(r'D:\SteamLibrary\steamapps\common\Townscaper\GameAssembly.dll')
data=target.read_bytes();pe=pefile.PE(data=data);base=pe.OPTIONAL_HEADER.ImageBase
graph=json.loads((BASE/'outputs/townscaper_native_graph.json').read_text(encoding='utf8'))
names={int(n['rva'],16)+base:n['pdb_name']for n in graph['nodes']}
for e in graph['edges']:names.setdefault(int(e['to'],16)+base,e['pdb_name'])
md=Cs(CS_ARCH_X86,CS_MODE_32)
windows=[];rows=[]
for start,end,label in [(0x760410,0x760a66,'ReturnProp including decompiler-removed wire block'),(0x758e50,0x759cee,'AddColliderToDict including anchor direction and prefab compatibility branch')]:
    code=data[pe.get_offset_from_rva(start):pe.get_offset_from_rva(end)]
    instructions=[];rows+=['',label]
    for i in md.disasm(code,base+start):
        name=''
        if i.mnemonic=='call' and re.fullmatch(r'0x[0-9a-f]+',i.op_str):name=names.get(int(i.op_str,16),'')
        instructions.append({'va':hex(i.address),'bytes':i.bytes.hex(),'mnemonic':i.mnemonic,'operands':i.op_str,'callee_name':name})
        rows.append(f'{i.address:08x} {i.bytes.hex():24s} {i.mnemonic:8s} {i.op_str}'+(' ; '+name if name else''))
    windows.append({'rva_start':hex(start),'rva_end_exclusive':hex(end),'label':label,'instructions':instructions})
result={'source':str(target),'sha256':hashlib.sha256(data).hexdigest(),'image_base':hex(base),'provenance':'Capstone linear decoding of original x86 bytes; Ghidra name annotations are aliases, not prototype truth; no new REA Evidence','windows':windows}
result['pairing_constants']=[{'va':hex(va),'bytes':data[pe.get_offset_from_rva(va-base):pe.get_offset_from_rva(va-base)+4].hex(),'float32':struct.unpack_from('<f',data,pe.get_offset_from_rva(va-base))[0]}for va in [0x111e1e48,0x111d3834]]
result['interpretation']={'pairing':'Different nodes, intersecting world bounds, no existing relations.Contains(other), compatible collider layer. Anchor layer3 requires d=normalize(otherCollider.position-currentCollider.position), dot(-d,current.right)>=0.3, dot(d,other.right)>=0.3, dot(-other.right,current.right)>=0.5 and Unity equality of srcWire. Accepted pair then passes OBB intersection and neither-transform-is-child-of-other, followed by reciprocal AddAnchor. Creation walks the anchor portion of relations; no additional wire duplicate search or explicit length limit occurs there. Spatial collider geometry bounds span.','return_prop_entry':'0x1076066c receives an address of stack out-variable (-8), tests AL and processes its node. 0x10760750 receives another out-variable (-12) with PropWireAnchor MethodInfo, tests AL and enters wire teardown. Shared PDB name/prototype GetComponentsInChildren(bool) is incompatible with these raw out-pointer arguments, which explains the dropped decompiler block.','wire_teardown_order':[{'va':'0x10760776','operation':'Read anchor.propWires.Count-1; iterate down to zero.'},{'va':'0x107607b9','operation':'Get wire PropNode; Get both anchor PropNodes at 0x107607d5 and 0x107607f2.'},{'va':'0x1076080b / 0x1076081f','operation':'Each anchor node removes wire child.'},{'va':'0x10760836 / 0x1076083f','operation':'Wire node removes both anchor parents.'},{'va':'0x10760865 / 0x1076088b','operation':'Remove wire from both anchor.propWires lists.'},{'va':'0x107608a2','operation':'Recursively ReturnProp(GetComponent<Prop>(wire)); pool return, no Object.Destroy.'},{'va':'0x107608bb / 0x107608d4','operation':'Wire node removes both wireConnectorNode motevees.'},{'va':'0x107608e2 / 0x107608e9','operation':'Clear wire.anchor0/anchor1; decrement loop index.'}],'reset_node_fields':'0x1076071f copies source priority (offset0xc), 0x10760730 copies motivations (offset0x18), 0x10760741 clears hasBeenTurnedOn (offset0x16), independently checked against shipped PDB PropNode layout.'}
(BASE/'outputs/townscaper_wire_raw.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf8',newline='\n')
(BASE/'outputs/townscaper_wire_raw.txt').write_text('\n'.join(row.rstrip() for row in rows)+'\n',encoding='utf8',newline='\n')
print(json.dumps({'raw_windows':len(windows),'instructions':sum(len(w['instructions'])for w in windows)}))
