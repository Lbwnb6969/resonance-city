"""Verify Nani histogram/prefix and sorted-instance staging."""
from __future__ import annotations

import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import nani_sort_reference as n  # noqa: E402


def main() -> int:
    raw = (149, 1024 + 149, 2048 + 300)
    meshes = (2, 0, 2)
    counts = [0] * 1024
    counts[149] = 2
    counts[300] = 1
    offsets, total = n.exclusive_prefix(counts)
    assert offsets[149] == 0 and offsets[300] == 2 and total == 3
    result = n.fill_unsorted_instance_list(raw, meshes, offsets, mesh_count=8)
    assert result.sorted_instances == (2, 1024, 2050)
    assert result.bucket_counts[149] == 2 and result.bucket_counts[300] == 1
    assert result.mesh_instance_counts[:3] == (1, 0, 2)
    mesh_prefix = [0] * 1024
    mesh_prefix[0] = 50
    mesh_prefix[2] = 51
    indirection = n.fill_unsorted_instance_indirection(
        result.sorted_instances, mesh_prefix, instance_count=3)
    assert indirection[50:53] == (1, 0, 2)
    result_data = {"checks": 8, "passed": True,
                   "sorted_instances": result.sorted_instances,
                   "bucket_offsets": {"149": offsets[149], "300": offsets[300]},
                   "mesh_instance_counts": result.mesh_instance_counts[:3],
                   "indirection_slice": indirection[50:53]}
    out = HERE.parent / "evidence" / "reconstruction_nani" / "sort_reference_verification.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result_data, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result_data, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
