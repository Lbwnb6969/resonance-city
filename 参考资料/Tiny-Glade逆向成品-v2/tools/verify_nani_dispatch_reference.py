"""Verify Nani indirect dispatch argument generation."""
from __future__ import annotations

import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import nani_dispatch_reference as n  # noqa: E402


def main() -> int:
    result = n.generate_dispatch_args((0, 64, 2050, 65536), (0, 0, 2, 0), 32)
    assert result.thread_counts == (0, 64, 2048, 65536)
    assert result.filtered_dispatch == (n.DispatchArgs(0), n.DispatchArgs(1),
                                        n.DispatchArgs(32), n.DispatchArgs(1024))
    assert result.merge_dispatch[2] == n.DispatchArgs(64)
    assert result.prefix_dispatch[2] == n.DispatchArgs(1)
    assert result.two_pass_dispatch == (n.DispatchArgs(0), n.DispatchArgs(0),
                                        n.DispatchArgs(0), n.DispatchArgs(1))
    assert n.draw_indexed_indirect_to_dispatch(65, 32) == n.DispatchArgs(3, 1, 1, 65)
    result_data = {"checks": 8, "passed": True,
                   "thread_counts": result.thread_counts,
                   "filtered_dispatch": [row.__dict__ for row in result.filtered_dispatch],
                   "merge_dispatch": [row.__dict__ for row in result.merge_dispatch],
                   "two_pass_dispatch": [row.__dict__ for row in result.two_pass_dispatch]}
    out = HERE.parent / "evidence" / "reconstruction_nani" / "dispatch_reference_verification.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result_data, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result_data, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
