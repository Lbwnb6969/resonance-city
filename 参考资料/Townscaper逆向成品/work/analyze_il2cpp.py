import json, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "pydeps"))
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_32
from capstone.x86 import X86_OP_IMM

ROOT = Path(r"D:\SteamLibrary\steamapps\common\Townscaper")
BASE = Path(__file__).resolve().parent.parent
IL2CPP_DIR = BASE / "work" / "reverse" / "il2cpp"
OUT = BASE / "outputs"

def load_methods():
    data = json.loads((IL2CPP_DIR / "script.json").read_text(encoding="utf-8"))
    methods = data.get("ScriptMethod", [])
    by_rva = {}
    for m in methods:
        rva = int(m["Address"])
        by_rva.setdefault(rva, []).append({"name": m["Name"], "signature": m.get("Signature", ""), "type_signature": m.get("TypeSignature", "")})
    return data, by_rva

def wanted(name):
    keys = [
        "Placemaker.Graphs.Graph$$AddVoxel",
        "Placemaker.Graphs.Graph$$RemoveVoxel",
        "Placemaker.Graphs.Graph$$PaintVoxel",
        "Placemaker.Graphs.Graph$$IntegrateVoxel",
        "Placemaker.Graphs.Graph$$ApplyAction",
        "Placemaker.Graphs.Graph$$Save",
        "Placemaker.Graphs.Graph$$BeginLoad",
        "Placemaker.Graphs.Graph$$IterateLoad",
        "Placemaker.GridGenerator$$HexToPlane",
        "Placemaker.GridGenerator$$SceneProcessIteration",
        "Placemaker.GridGenerator$$GetQuad",
        "Placemaker.SaveSystem$$GetSaveFilePath",
        "Placemaker.SaveSystem$$LoadMetaSaveFromDisk",
        "Placemaker.SaveSystem$$SaveMetaSaveToDisk",
        "Placemaker.SaveSystem$$MaybeSaveCurrent",
        "Placemaker.SaveSystem$$LoadSave",
        "Placemaker.WorldMaster$$GetSaveString",
        "Placemaker.WorldMaster$$Load",
        "Placemaker.WorldMaster$$New",
        "Placemaker.Ui.UiMaster$$LoadMetaSave",
        "Placemaker.Ui.UiMaster$$StartNew",
        "Placemaker.Ui.UiMaster$$LoadString",
        "Placemaker.Ui.UiMaster$$DefaultPath",
    ]
    return any(name == k for k in keys)

def disassemble(pe, by_rva, rva):
    off = pe.get_offset_from_rva(rva)
    image = pe.get_memory_mapped_image() if False else None
    with (ROOT / "GameAssembly.dll").open("rb") as f:
        f.seek(off)
        code = f.read(0x800)
    md = Cs(CS_ARCH_X86, CS_MODE_32)
    md.detail = True
    va = pe.OPTIONAL_HEADER.ImageBase + rva
    insns=[]
    calls=[]
    for i in md.disasm(code, va):
        text=f"{i.mnemonic} {i.op_str}".strip()
        insns.append({"address":hex(i.address),"rva":hex(i.address-pe.OPTIONAL_HEADER.ImageBase),"bytes":i.bytes.hex(),"text":text})
        if i.mnemonic == "call" and i.operands and i.operands[0].type == X86_OP_IMM:
            target=i.operands[0].imm
            target_rva=target-pe.OPTIONAL_HEADER.ImageBase
            calls.append({"address":hex(i.address),"target":hex(target),"target_rva":hex(target_rva),"target_names":by_rva.get(target_rva,[])})
        if len(insns) >= 120:
            break
        if len(insns) >= 6 and i.mnemonic == "ret":
            break
    # Generic IL2CPP bodies can share one address, so keep a small, useful
    # summary alongside the raw call records instead of treating every name
    # attached to a shared RVA as a distinct edge.
    resolved = []
    for c in calls:
        for target in c.get("target_names", []):
            name = target.get("name", "")
            placemaker_edge = (name.startswith(("Placemaker.", "Os.Hex."))
                               and not name.endswith("$$.ctor")
                               and "GetComponent<" not in name
                               and "<>c" not in name
                               and ".<" not in name)
            unity_edge = (name.startswith("UnityEngine.")
                          and not name.endswith("$$.ctor")
                          and "GetComponent<" not in name)
            system_edge = name in {"System.String$$Format", "System.String$$Contains",
                                   "System.String$$Split", "System.Collections.ArrayList$$Clear"}
            if placemaker_edge or unity_edge or system_edge:
                resolved.append(name)
    return {"rva":hex(rva),"va":hex(va),"file_offset":off,"instructions":insns,
            "direct_calls":calls,"resolved_relevant_calls":list(dict.fromkeys(resolved))}

def dump_classes():
    lines=(IL2CPP_DIR/"dump.cs").read_text(encoding="utf-8",errors="replace").splitlines()
    targets=["Voxel","GridGenerator","Graph","MetaSave","SaveSystem","WorldMaster","BirdFlock","PaletteMenu","SaveCard","UiMaster"]
    out={}
    class_re=re.compile(r"^(?:public|private|internal|protected|sealed|abstract|static|unsafe|partial|readonly|struct|enum|interface|class|record|file|new|ref|out|in|\s)+class\s+([^ :{]+)")
    # Decompiler output uses top-level declarations without indentation. Capture the target declaration to the next declaration.
    starts=[]
    for idx,line in enumerate(lines):
        if line.startswith(" ") or line.startswith("\t"):
            continue
        m=class_re.match(line)
        if m: starts.append((idx,m.group(1),line))
    for pos,(idx,name,decl) in enumerate(starts):
        if name not in targets: continue
        end=starts[pos+1][0] if pos+1<len(starts) else len(lines)
        methods=[x.strip() for x in lines[idx:end] if re.match(r"\t(?:public|private|protected|internal|static|virtual|abstract|override|sealed|extern|readonly|unsafe|async|new).*\([^;]*\)\s*\{ \}",x)]
        fields=[x.strip() for x in lines[idx:end] if re.match(r"\t(?:public|private|protected|internal|static|readonly|const|volatile|unsafe).*;\s*(?://.*)?$",x) and "(" not in x]
        out.setdefault(name,{"declaration":decl,"line":idx+1,"methods":[],"fields":[]})["methods"].extend(methods)
        out[name]["fields"].extend(fields)
    for v in out.values():
        v["methods"]=list(dict.fromkeys(v["methods"]))
        v["fields"]=list(dict.fromkeys(v["fields"]))
    return out

def main():
    data, by_rva = load_methods()
    pe=pefile.PE(str(ROOT/"GameAssembly.dll"),fast_load=False)
    selected=[]
    for rva, entries in sorted(by_rva.items()):
        for e in entries:
            if wanted(e["name"]):
                selected.append({"rva":hex(rva),**e,**disassemble(pe,by_rva,rva)})
    report={
        "tool":"Perfare Il2CppDumper + capstone",
        "tool_source":"https://github.com/Perfare/Il2CppDumper",
        "target":str(ROOT/"GameAssembly.dll"),
        "target_sha256":"4aa99a8deaa9a322026094186ed283020a8b6d897f2777dbb330ebf0ca89532c",
        "metadata_version":27,
        "method_inventory_count":len(data.get("ScriptMethod",[])),
        "selected_method_count":len(selected),
        "selected_methods":selected,
        "class_inventory":dump_classes(),
        "limitations":[
            "Il2CppDumper restores metadata signatures and method RVAs; it does not produce original C# source.",
            "Capstone output is a bounded x86 disassembly slice ending at the first observed ret or 120 instructions.",
            "Direct-call resolution is limited to exact method RVAs present in script.json; indirect calls and runtime dispatch remain unresolved.",
            "No runtime execution was used in this artifact.",
        ],
    }
    (OUT/"townscaper_il2cpp_functions.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps({"output":str(OUT/"townscaper_il2cpp_functions.json"),"method_inventory_count":report["method_inventory_count"],"selected_method_count":len(selected),"classes":list(report["class_inventory"])},ensure_ascii=False,indent=2))

if __name__ == "__main__": main()
