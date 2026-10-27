"""Read-only codec checks; private save geometry is not written to outputs."""
import argparse
import hashlib
import importlib.util
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("codec", ROOT / "outputs/townscaper_codec.py")
codec = importlib.util.module_from_spec(spec)
spec.loader.exec_module(codec)


def verify(path):
    raw = path.read_bytes()
    tree = ET.fromstring(raw)
    data = {key: [{field: int(item.findtext(field)) for field in fields} for item in tree.findall(key + "/" + tag)]
            for key, tag, fields in (("corners", "C", ("x", "y", "count")), ("voxels", "V", ("t", "h")))}
    reconstructed = codec.encode(data)
    stored = tree.findtext("saveString")
    decoded = codec.decode(reconstructed)
    existing = codec.decode(stored) if stored else None
    return {"save_file_sha256": hashlib.sha256(raw).hexdigest(), "save_file_size": len(raw),
            "corner_count": len(data["corners"]), "voxel_count": len(data["voxels"]),
            "generated_text_length": len(reconstructed), "stored_text_length": len(stored or ""),
            "geometry_roundtrip": decoded == data, "stored_text_matches_current_xml_geometry": stored == reconstructed,
            "stored_text_geometry_equals_xml_geometry": existing == data,
            "stored_text_canonical_roundtrip": codec.encode(existing) == stored if existing else None,
            "private_geometry_written": False,
            "evidence": "Original game-produced XML read only; reconstructed encoder/decoder executed independently"}


def fixtures():
    cases = [
        ("empty", {"corners": [{"x": 0, "y": 0, "count": 0}], "voxels": []}),
        ("ground", {"corners": [{"x": 0, "y": 0, "count": 1}], "voxels": [{"t": 15, "h": 0}]}),
        ("color", {"corners": [{"x": 0, "y": 0, "count": 1}], "voxels": [{"t": 0, "h": 1}]}),
        ("ground_color", {"corners": [{"x": 0, "y": 0, "count": 2}], "voxels": [{"t": 15, "h": 0}, {"t": 0, "h": 1}]}),
        ("sparse_maxheight", {"corners": [{"x": -3, "y": 8, "count": 0}, {"x": -3, "y": -7, "count": 1},
                                         {"x": 9, "y": 2, "count": 3}],
                              "voxels": [{"t": 1, "h": 255}, {"t": 15, "h": 0}, {"t": 8, "h": 3}, {"t": 4, "h": 255}]}),
        ("all_colors", {"corners": [{"x": -17, "y": -31, "count": 15}],
                        "voxels": [{"t": t, "h": t + 1} for t in range(15)]}),
    ]
    return [{"name": name, "text": codec.encode(data), "data": data} for name, data in cases]


parser = argparse.ArgumentParser()
parser.add_argument("save", nargs="?")
parser.add_argument("--asset", action="store_true")
args = parser.parse_args()
if args.asset:
    path = ROOT / "outputs/townscaper_default_save_asset.json"
    artifact = json.loads(path.read_text(encoding="utf-8"))
    source = artifact["data"]["defaultSaveData"]
    data = {key: source[key] for key in ("corners", "voxels")}
    result = {"asset_file": artifact["file"], "path_id": artifact["path_id"],
              "export_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
              "corner_count": len(data["corners"]), "voxel_count": len(data["voxels"]),
              "encode_exact_match": codec.encode(data) == source["saveString"],
              "decode_exact_match": codec.decode(source["saveString"]) == data,
              "evidence": "Shipped DefaultSaveData asset independently parsed and compared"}
    (ROOT / "outputs/townscaper_codec_asset_verification.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
elif args.save:
    result = verify(Path(args.save))
    (ROOT / "outputs/townscaper_codec_verification.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
else:
    result = fixtures()
    (ROOT / "outputs/townscaper_codec_fixtures.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"fixtures": len(result), "path": "outputs/townscaper_codec_fixtures.json"}))
