import hashlib, json, re, struct
from pathlib import Path

ROOT = Path(r"D:\SteamLibrary\steamapps\common\Townscaper")
OUT = Path(__file__).resolve().parent.parent / "outputs"
OUT.mkdir(parents=True, exist_ok=True)

KEY_FILES = [
    "Townscaper.exe", "GameAssembly.dll", "UnityPlayer.dll", "baselib.dll",
    "Townscaper_Data/globalgamemanagers", "Townscaper_Data/globalgamemanagers.assets",
    "Townscaper_Data/level0", "Townscaper_Data/level1", "Townscaper_Data/level2",
    "Townscaper_Data/resources.assets", "Townscaper_Data/sharedassets0.assets",
    "Townscaper_Data/sharedassets1.assets", "Townscaper_Data/sharedassets2.assets",
    "Townscaper_Data/il2cpp_data/Metadata/global-metadata.dat",
    "Townscaper_Data/ScriptingAssemblies.json", "Townscaper_Data/RuntimeInitializeOnLoads.json",
    "Townscaper_Data/boot.config", "Townscaper_Data/app.info",
]

def sha256(p):
    h = hashlib.sha256()
    with p.open("rb") as f:
        for b in iter(lambda: f.read(1024 * 1024), b""):
            h.update(b)
    return h.hexdigest()

def ascii_strings(data, min_len=5):
    return [m.group().decode("ascii", "ignore") for m in re.finditer(rb"[\x20-\x7e]{%d,}" % min_len, data)]

def utf16_strings(data, min_len=5):
    pat = rb"(?:[\x20-\x7e]\x00){%d,}" % min_len
    out = []
    for m in re.finditer(pat, data):
        try:
            out.append(m.group().decode("utf-16le", "ignore"))
        except UnicodeDecodeError:
            pass
    return out

def pe_summary(p):
    d = p.read_bytes()
    if d[:2] != b"MZ":
        return None
    peoff = struct.unpack_from("<I", d, 0x3c)[0]
    if d[peoff:peoff+4] != b"PE\0\0":
        return {"format": "MZ-invalid-PE"}
    machine, nsec, timestamp, _, _, opt_size, chars = struct.unpack_from("<HHIIIHH", d, peoff+4)
    opt = peoff + 24
    magic = struct.unpack_from("<H", d, opt)[0]
    entry_rva = struct.unpack_from("<I", d, opt+16)[0]
    image_base = struct.unpack_from("<I", d, opt+28)[0] if magic == 0x10B else struct.unpack_from("<Q", d, opt+24)[0]
    subsystem_off = opt + (68 if magic == 0x10B else 68)
    subsystem = struct.unpack_from("<H", d, subsystem_off)[0]
    section_base = opt + opt_size
    sections=[]
    for i in range(nsec):
        off=section_base+i*40
        name=d[off:off+8].rstrip(b"\0").decode("ascii","replace")
        vsize, va, rawsize, rawptr = struct.unpack_from("<IIII", d, off+8)
        sc=struct.unpack_from("<I",d,off+36)[0]
        sections.append({"name":name,"virtual_size":vsize,"virtual_address":hex(va),"raw_size":rawsize,"raw_offset":rawptr,"characteristics":hex(sc)})
    return {"format":"PE32" if magic==0x10B else "PE32+","machine":hex(machine),"sections":nsec,"timestamp":timestamp,"entry_rva":hex(entry_rva),"image_base":hex(image_base),"subsystem":subsystem,"characteristics":hex(chars),"section_table":sections}

def metadata_header(p):
    d=p.read_bytes()[:256]
    if len(d)<8: return None
    magic, version = struct.unpack_from("<II", d, 0)
    pairs=[]
    for i in range(2, min(35, len(d)//4), 2):
        off,count=struct.unpack_from("<II",d,i*4)
        pairs.append({"index":i//2,"offset":off,"count":count})
    return {"magic":hex(magic),"version":version,"header_bytes_examined":len(d),"pairs":pairs}

def metadata_string_table(p):
    d=p.read_bytes()
    if len(d)<24: return []
    magic, version = struct.unpack_from("<II", d, 0)
    # In v27 the third pair is stringOffset/stringCount in the metadata file.
    off, size = struct.unpack_from("<II", d, 8+2*8)
    if off < 0 or size < 0 or off+size > len(d): return []
    blob=d[off:off+size]
    return [x.decode("utf-8","replace") for x in blob.split(b"\0") if x]

def selected_strings(p, patterns, max_each=100):
    d=p.read_bytes()
    vals=ascii_strings(d)+utf16_strings(d)
    result={}
    for label, pat in patterns.items():
        rx=re.compile(pat,re.I)
        result[label]=sorted(set(v for v in vals if rx.search(v)))[:max_each]
    return result

def main():
    files=[]
    for rel in KEY_FILES:
        p=ROOT/rel
        if p.exists():
            files.append({"path":rel,"bytes":p.stat().st_size,"sha256":sha256(p)})
    report={"target":str(ROOT),"files":files}
    report["pe"]={}
    for rel in ["Townscaper.exe","GameAssembly.dll","UnityPlayer.dll","baselib.dll"]:
        p=ROOT/rel
        if p.exists(): report["pe"][rel]=pe_summary(p)
    md=ROOT/"Townscaper_Data/il2cpp_data/Metadata/global-metadata.dat"
    report["il2cpp_metadata"]={"file":str(md.relative_to(ROOT)),"sha256":sha256(md),"bytes":md.stat().st_size,"header":metadata_header(md)}
    mstrings=metadata_string_table(md)
    report["il2cpp_metadata"]["string_table"]={"count":len(mstrings),"sample_custom":sorted(set(x for x in mstrings if re.search(r"Town|Townscape|Placemaker|Voxel|House|Bird|Lighthouse|Grid|Water|Ground|Fence|Window|Door|Plant|Color|Palette|Save|Screenshot|LooseVoxels|Tile|Submesh|Mesh|World|Settings|Boot|UI",x,re.I)))[:2000]}
    patterns={
        "custom_system":r"Townscaper|Townscape|Placemaker|Voxel|House|Birdhouse|Lighthouse|Grid|Water|Ground|Fence|Window|Door|Plant|ColorPick|Palette|SaveFile|MetaSave|Screenshot|LooseVoxels|Tile|Submesh|Mesh|AreaFill|Rebuild|World|Settings",
        "integrations":r"Fury|Steam|Nintendo|Rewired|Crosstales|I2\\.Loc|TextMeshPro|Oskar|com\\.oskarstalberg",
        "unity":r"2020\\.3\\.4f1|UnityEngine|IL2CPP|PlayerPrefs|SceneManager|QualitySettings|Input|AudioMixer|Screen::|Application::",
    }
    report["strings"]={
        "GameAssembly.dll":selected_strings(ROOT/"GameAssembly.dll",patterns,300),
        "global-metadata.dat":selected_strings(md,patterns,500),
        "asset_strings":{}
    }
    for rel in ["Townscaper_Data/globalgamemanagers","Townscaper_Data/globalgamemanagers.assets","Townscaper_Data/level0","Townscaper_Data/level1","Townscaper_Data/level2","Townscaper_Data/resources.assets","Townscaper_Data/sharedassets0.assets","Townscaper_Data/sharedassets1.assets","Townscaper_Data/sharedassets2.assets"]:
        p=ROOT/rel
        if p.exists():
            vals=ascii_strings(p.read_bytes())+utf16_strings(p.read_bytes())
            report["strings"]["asset_strings"][rel]=sorted(set(v for v in vals if re.search(r"Assets/|Placemaker|Town|House|Bird|Water|Grid|UI|Boot|level|Save|Screenshot|Audio|chime|Oskar|com\\.oskar",v,re.I)))[:1000]
    try:
        report["config"]={
            "boot_config":(ROOT/"Townscaper_Data/boot.config").read_text(errors="replace"),
            "app_info":(ROOT/"Townscaper_Data/app.info").read_text(errors="replace"),
            "scripting_assemblies":json.loads((ROOT/"Townscaper_Data/ScriptingAssemblies.json").read_text()),
            "runtime_initialize":json.loads((ROOT/"Townscaper_Data/RuntimeInitializeOnLoads.json").read_text()),
        }
    except Exception as e:
        report["config_error"]=str(e)
    (OUT/"townscaper_static.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps({"output":str(OUT/"townscaper_static.json"),"files":len(files),"il2cpp_header":report["il2cpp_metadata"]["header"]},ensure_ascii=False,indent=2))

if __name__ == "__main__": main()
