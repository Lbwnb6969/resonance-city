"""Verify ShapeParameters expand and curve dispatch."""
from __future__ import annotations

import json
import math
from pathlib import Path
import struct
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import recovered_wall_mapping as m  # noqa: E402


def main() -> int:
    rectangle = bytearray(28)
    struct.pack_into('<I', rectangle, 0, 1)
    struct.pack_into('<2f', rectangle, 0x14, 4.0, 5.0)
    expanded_rectangle = m.expand_shape_parameters(bytes(rectangle), 0.125)
    assert struct.unpack_from('<2f', expanded_rectangle, 0x14) == (4.25, 5.25)
    assert m.shape_curve_kind(bytes(rectangle)) == 'rectangle'
    circle = bytearray(28)
    struct.pack_into('<I', circle, 0, 0)
    struct.pack_into('<f', circle, 0x0c, 2.0)
    expanded_circle = m.expand_shape_parameters(bytes(circle), 0.125)
    assert struct.unpack_from('<f', expanded_circle, 0x0c)[0] == 2.125
    assert m.shape_curve_kind(bytes(circle)) == 'circle'
    assert m.circle_sample_count(0.01) == 3
    assert m.circle_sample_count(1.0) == 32
    points = m.circle_sample_points((1.0, 2.0), 1.0)
    assert len(points) == 32 and points[0] == (2.0, 2.0)
    rectangle_curve = m.rectangle_curve2_reference(
        m.Rectangle2((1.0, 0.0), (0.0, 0.0), (4.0, 2.0)))
    assert len(rectangle_curve.points) == 5
    assert rectangle_curve.points[0] == rectangle_curve.points[-1]
    assert all(math.isclose(a, b, abs_tol=1e-6) for a, b in zip(
        rectangle_curve.u_values, (0.0, 1.0 / 6.0, 0.5, 2.0 / 3.0, 1.0)))
    assert math.isclose(rectangle_curve.length, 12.0, abs_tol=1e-6)
    result = {"checks": 16, "passed": True,
              "rectangle_dimensions": struct.unpack_from('<2f', expanded_rectangle, 0x14),
              "circle_scalar": struct.unpack_from('<f', expanded_circle, 0x0c)[0],
              "circle_sample_count": len(points),
              "rectangle_curve_points": len(rectangle_curve.points),
              "rectangle_curve_length": rectangle_curve.length}
    out = HERE.parent / 'evidence' / 'reconstruction_wall_instances' / 'verification-shape-parameters.json'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
