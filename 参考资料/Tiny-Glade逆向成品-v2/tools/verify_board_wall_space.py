"""Verify the recovered BoardWallSpace output ABI."""
from __future__ import annotations

import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import recovered_wall_mapping as m  # noqa: E402


def main() -> int:
    original = bytes(range(28))
    expanded = bytes(range(28, 56))
    record = m.board_wall_space_record(original, expanded, 12.5, 13.25)
    packed = record.to_bytes()
    assert len(packed) == 68
    assert packed[:28] == original and packed[28:56] == expanded
    assert record.wall_length == m.r.f32(12.5)
    assert record.expanded_length == m.r.f32(13.25)
    assert record.remap_offset == m.r.f32(0.125)
    assert m.BoardWallSpaceRecord.from_bytes(packed) == record
    empty = m.board_wall_space_record(None, None, 0.0, 0.0)
    assert empty.original_shape_payload == bytes(28)
    assert empty.expanded_shape_payload == bytes(28)
    result = {"checks": 8, "passed": True, "record_bytes": len(packed),
              "wall_length": record.wall_length,
              "expanded_length": record.expanded_length,
              "remap_offset": record.remap_offset}
    out = HERE.parent / "evidence" / "reconstruction_wall_instances" / "verification-board-wall-space.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
