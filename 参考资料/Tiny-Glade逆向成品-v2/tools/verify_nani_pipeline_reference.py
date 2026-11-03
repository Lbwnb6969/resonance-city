"""Verify the end-to-end Nani CPU reference."""
from __future__ import annotations

import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import nani_pipeline_reference as p  # noqa: E402
from nani_cull_reference import normalize_plane, PackedInstance  # noqa: E402
from nani_draw_reference import MeshAtlasPartInfo  # noqa: E402


def main() -> int:
    planes = tuple(normalize_plane(plane) for plane in (
        (1.0, 0.0, 0.0, 10.0), (-1.0, 0.0, 0.0, 10.0),
        (0.0, 1.0, 0.0, 10.0), (0.0, -1.0, 0.0, 10.0)))
    instances = (
        PackedInstance((0.0, 0.0, 0.0), 1.0, 0),
        PackedInstance((0.0, 0.0, 0.0), 1.0, 1),
        PackedInstance((0.0, 0.0, 0.0), 1.0, 0),
    )
    result = p.run_nani_pipeline(
        instances, ((0.0, 0.0, -10.0), (0.0, 0.0, -12.0), (20.0, 0.0, -10.0)),
        (2.0, 3.0), {0: MeshAtlasPartInfo(100, 36), 1: MeshAtlasPartInfo(200, 12)},
        (2,), previous_visibility_words=(0b111,), side_planes=planes, clip_z_w=0.0,
        instance_indirection_base=40)
    assert result.cull.visible_local_indices == (0, 1)
    assert result.sorted_stage.sorted_instances == (0, 1025)
    assert result.draw.window_command_counts == (2,)
    assert result.draw.commands[0].first_index == 100
    assert result.draw.commands[1].first_index == 200
    assert result.draw.instance_indirection == (0, 1)
    result_data = {"checks": 8, "passed": True,
                   "visible_local_indices": result.cull.visible_local_indices,
                   "sorted_instances": result.sorted_stage.sorted_instances,
                   "draw_commands": [row.__dict__ for row in result.draw.commands],
                   "instance_indirection": result.draw.instance_indirection}
    out = HERE.parent / "evidence" / "reconstruction_nani" / "pipeline_reference_verification.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result_data, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result_data, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
