"""Verify Nani merge-window command generation."""
from __future__ import annotations

import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import nani_draw_reference as n  # noqa: E402


def main() -> int:
    packed = (
        n.encode_sorted_instance(10, 2),
        n.encode_sorted_instance(11, 0),
        n.encode_sorted_instance(12, 2),
        n.encode_sorted_instance(13, 1),
        n.encode_sorted_instance(14, 0),
    )
    result = n.generate_draw_lists(
        packed, (3, 2),
        {0: n.MeshAtlasPartInfo(100, 36),
         1: n.MeshAtlasPartInfo(200, 12),
         2: n.MeshAtlasPartInfo(300, 24)},
        instance_indirection_base=50,
    )
    assert result.window_command_counts == (2, 2)
    assert result.window_command_offsets == (0, 2)
    assert result.commands == (
        n.DrawIndexedIndirectCommand(36, 1, 100, 0, 50),
        n.DrawIndexedIndirectCommand(24, 2, 300, 0, 51),
        n.DrawIndexedIndirectCommand(36, 1, 100, 0, 53),
        n.DrawIndexedIndirectCommand(12, 1, 200, 0, 54),
    )
    assert result.instance_indirection == (11, 10, 12, 14, 13)
    assert n.decode_sorted_instance(n.encode_sorted_instance(123, 7)) == (123, 7)
    result_data = {"checks": 7, "passed": True,
                   "window_command_counts": result.window_command_counts,
                   "commands": [command.__dict__ for command in result.commands],
                   "instance_indirection": result.instance_indirection}
    out = HERE.parent / "evidence" / "reconstruction_nani" / "draw_reference_verification.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result_data, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result_data, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
