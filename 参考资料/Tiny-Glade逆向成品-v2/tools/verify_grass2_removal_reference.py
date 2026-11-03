"""Verify Grass2 removal mask and active dispatch reconstruction."""
from __future__ import annotations

import json
import math
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import grass2_removal_reference as g  # noqa: E402


def main() -> int:
    base = g.combine_grass_removal(g.RemovalInputs(
        path=0.15, water_y=0.5, foliage_exclusion_x=0.0,
        rocky=(0.0, 0.0, 0.0, 0.0), building_max=0.0, garden_max=0.0))
    assert base.removal == 1.0 and math.isclose(base.opacity, 0.65)
    rocky = g.combine_grass_removal(g.RemovalInputs(
        path=0.0, water_y=0.5, foliage_exclusion_x=0.0,
        rocky=(0.3, 0.0, 0.0, 0.0), building_max=0.0, garden_max=0.0))
    assert rocky.removal == 1.0 and math.isclose(rocky.opacity, 0.75)
    neigh = g.combine_grass_removal_texels(
        (4, 7), path_mask=lambda x, y: 0.0,
        water_mask=lambda x, y: (0.0, 0.0, 0.0, 0.0),
        foliage_exclusion_mask=lambda x, y: (0.0, 0.0, 0.0, 0.0),
        rocky_terrain=lambda x, y: (0.0, 0.0, 0.0, 0.0),
        building_mask=lambda x, y: 0.35 if (x, y) == (5, 8) else 0.0,
        garden_mask=lambda x, y: (0.0, 0.5, 0.0, 0.0) if (x, y) == (3, 6) else (0.0, 0.0, 0.0, 0.0))
    assert neigh.removal == 1.0 and math.isclose(neigh.opacity, 0.5)
    assert g.active_cull_dispatch_args(0, 64) == (0, 1, 1)
    assert g.active_cull_dispatch_args(65, 64) == (2, 1, 1)
    result = {"checks": 8, "passed": True,
              "base": base.__dict__, "rocky": rocky.__dict__,
              "neighborhood": neigh.__dict__,
              "dispatch_65_64": g.active_cull_dispatch_args(65, 64)}
    out = HERE.parent / "evidence" / "reconstruction_grass2" / "removal_reference_verification.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
