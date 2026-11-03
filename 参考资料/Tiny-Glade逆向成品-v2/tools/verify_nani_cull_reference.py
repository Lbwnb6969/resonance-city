"""Verify the recovered Nani cull-and-bucket decisions."""
from __future__ import annotations

import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import nani_cull_reference as n  # noqa: E402


def main() -> int:
    # Four side planes for a unit orthographic box: x/y in [-10, 10].
    planes = tuple(n.normalize_plane(plane) for plane in (
        (1.0, 0.0, 0.0, 10.0), (-1.0, 0.0, 0.0, 10.0),
        (0.0, 1.0, 0.0, 10.0), (0.0, -1.0, 0.0, 10.0)))
    matrix_planes = n.side_planes_from_view_to_clip(
        ((-1.0, 0.0, 0.0, 0.0), (0.0, 1.0, 0.0, 0.0),
         (0.0, 0.0, 0.0, 0.0), (0.0, 0.0, -1.0, 10.0)))
    assert matrix_planes == tuple(n.normalize_plane(plane) for plane in (
        (1.0, 0.0, -1.0, 10.0), (-1.0, 0.0, -1.0, 10.0),
        (0.0, 1.0, -1.0, 10.0), (0.0, -1.0, -1.0, 10.0)))
    instances = (
        n.PackedInstance((0.0, 0.0, 0.0), 1.0, 0),
        n.PackedInstance((0.0, 0.0, 0.0), 0.5, 1),
        n.PackedInstance((0.0, 0.0, 0.0), 1.0, 0),
    )
    views = ((0.0, 0.0, -10.0), (20.0, 0.0, -10.0), (20.0, 0.0, -40.0))
    # Keep previous visibility for local indices 0 and 2 only.
    result = n.cull_and_bucket(
        instances, views, (2.0, 4.0), world_subset=0,
        draw_list_index_base=1, global_instance_offset=0,
        previous_visibility_words=(0b101,), side_planes=planes, clip_z_w=0.0,
    )
    assert result.visible_local_indices == (0,)
    assert result.next_visibility_words == (1,)
    assert result.filtered_instances == (0 * 1024 + n.depth_bucket(-10.0),)
    assert result.filtered_mesh_indices == (0,)
    assert result.histogram[1024 + n.depth_bucket(-10.0)] == 1
    assert n.depth_bucket(32.0) == 0
    assert n.depth_bucket(-256.0) == 1023
    packed = n.PackedInstance.from_words((0x3F800000, 0x00000000, 0xC0000000, (2 << 16) | 0x3C00))
    assert packed.position == (1.0, 0.0, -2.0) and packed.radius_scale == 1.0 and packed.mesh_index == 2
    result_data = {"checks": 9, "passed": True,
                   "visible_local_indices": result.visible_local_indices,
                   "filtered_instances": result.filtered_instances,
                   "histogram_bucket": n.depth_bucket(-10.0)}
    out = HERE.parent / "evidence" / "reconstruction_nani" / "cull_reference_verification.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result_data, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result_data, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
