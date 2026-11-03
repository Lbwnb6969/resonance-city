"""Verify Grass2 build-draws sampling constants and packed group outputs."""
from __future__ import annotations

import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import grass2_sampling_reference as g  # noqa: E402


def main() -> int:
    assert g.reverse_bits32(1) == 0x80000000
    assert g.reverse_bits32(0x80000000) == 1
    points = [g.sample_position(i) for i in (0, 1, 14335, 14336, 45055)]
    assert all(-95.0 <= p[0] <= 95.0 and -95.0 <= p[1] <= 95.0 for p in points)
    assert g.sample_texel((0.0, 0.0)) == (256, 256)
    assert g.water_exemplar((0, 2, 0, 7), 3, 0) == 13
    assert g.water_exemplar((0, 2, 0, 7), 3, 4) is None
    runs = g.land_runs((2, 2, 3, 3), 17, 0)
    assert [(row.value, row.count, row.output_index, row.attribute) for row in runs] == [
        (2, 2, 17, 0xffff0009), (3, 2, 14353, 0xffff000d)]
    assert g.terrain_height_ratio(-2.1, 1.0, .5, 1.0, .0) == 1.0
    inner = g.large_world_gate(57344, (65.0, 0.0), 0)
    assert not inner.accepted and inner.distance_to_inner_bounds == 0.0
    outer = g.large_world_gate(57344, (95.0, 0.0), 0)
    assert not outer.accepted and outer.distance_to_inner_bounds == 30.0
    accepted = g.large_world_gate(57344, (70.0, 0.0), 0, path_mask_sample=0.0)
    assert accepted.accepted and accepted.exemplar == 3
    assert accepted.packed_attribute == 0xffff0002
    path = g.large_world_gate(57344, (70.0, 0.0), 0, path_mask_sample=0.15)
    assert path.path_rejected and not path.accepted and path.path_threshold == 0.5
    water = g.large_world_gate(57344, (70.0, 0.0), 0,
                                water_footprint_ws=(-100.0, -100.0, 100.0, 100.0),
                                terrain_height_sample=0.0)
    assert water.water_rejected and not water.accepted
    theme = g.large_world_gate(57358, (70.0, 0.0), 4, path_mask_sample=0.0)
    assert theme.theme_rejected and not theme.accepted
    callback_uv = []
    callback = g.large_world_gate(57344, (70.0, 0.0), 0,
                                  path_mask=lambda uv: callback_uv.append(uv) or 0.0)
    assert callback.accepted and len(callback_uv) == 1 and callback_uv[0] == callback.path_uv
    result = {"checks": 15, "passed": True, "points": points,
              "runs": [row.__dict__ for row in runs]}
    out = HERE.parent / "evidence" / "reconstruction_grass2" / "sampling_reference_verification.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
