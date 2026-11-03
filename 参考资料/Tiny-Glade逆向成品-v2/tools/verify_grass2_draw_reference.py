"""Small deterministic check for grass2_draw_reference."""
from __future__ import annotations

import json
import dataclasses
from pathlib import Path
import struct
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from grass2_runtime_reference import Clump  # noqa: E402
from grass2_draw_reference import GrassCard, build_draw_plan  # noqa: E402


def half2(a: float, b: float) -> int:
    return int.from_bytes(struct.pack("<2e", a, b), "little")


def main() -> int:
    clump = Clump.from_words([half2(0.0, 0.0), half2(0.0, 0.0), half2(1.0, 1.0), 0])
    bounds = ((0.0, 1.0), (0.0, 1.0), (0.0, 1.0))
    cards = [
        GrassCard(10, 3, clump, 0x80808080, 0, bounds),
        GrassCard(11, 1, clump, 0x80808080, 0, bounds),
        GrassCard(12, 3, clump, 0x80808080, 0, bounds),
    ]
    plan = build_draw_plan(cards, {1: 6, 3: 12})
    assert not plan.discarded
    assert [row.card.instance_id for row in plan.active] == [10, 11, 12]
    assert [(d.exemplar, d.index_count, d.instance_count, d.first_index, d.first_instance)
            for d in plan.draws] == [(3, 12, 2, 0, 0), (1, 6, 1, 12, 1)]
    removal = lambda uv: (1.0, 1.0, 0.0, 0.0)
    discard_plan = build_draw_plan(
        [GrassCard(13, 1, Clump.from_words([clump.center_xy, clump.center_z_wind,
                                             clump.scale_packed, 1 << 18]),
                   0x80808080, 0, bounds)], {1: 6}, removal_texture=removal)
    assert discard_plan.discarded == (13,) and not discard_plan.active
    payload = {"checks": 7, "passed": True,
               "active": len(plan.active), "draws": [dataclasses.asdict(d) for d in plan.draws],
               "discarded": list(discard_plan.discarded)}
    out = HERE.parent / "evidence" / "reconstruction_grass2" / "draw_reference_verification.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
