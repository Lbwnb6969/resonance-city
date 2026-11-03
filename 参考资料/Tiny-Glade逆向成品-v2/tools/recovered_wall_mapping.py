"""World/curve/wallspace mapping and arch cutout reconstruction."""
from __future__ import annotations
import dataclasses
import math
import struct
import recovered_wall_stairs as r


def _f32(value):
    return r.f32(value)


@dataclasses.dataclass(frozen=True)
class BoardWallSpaceRecord:
    """68-byte output layout of `BoardWallSpace::new` (0x141483d90)."""
    original_shape_payload: bytes
    expanded_shape_payload: bytes
    wall_length: float
    expanded_length: float
    remap_offset: float = 0.125

    def __post_init__(self):
        if len(self.original_shape_payload) != 28:
            raise ValueError('original_shape_payload must be 28 bytes')
        if len(self.expanded_shape_payload) != 28:
            raise ValueError('expanded_shape_payload must be 28 bytes')

    def to_bytes(self) -> bytes:
        out = bytearray(68)
        out[0:28] = self.original_shape_payload
        out[28:56] = self.expanded_shape_payload
        struct.pack_into('<3f', out, 56, _f32(self.wall_length),
                         _f32(self.expanded_length), _f32(self.remap_offset))
        return bytes(out)

    @classmethod
    def from_bytes(cls, data: bytes) -> 'BoardWallSpaceRecord':
        if len(data) < 68:
            raise ValueError('BoardWallSpace record must be 68 bytes')
        wall_length, expanded_length, remap_offset = struct.unpack_from('<3f', data, 56)
        return cls(bytes(data[0:28]), bytes(data[28:56]),
                   wall_length, expanded_length, remap_offset)


def board_wall_space_record(
    original_shape_payload: bytes | None,
    expanded_shape_payload: bytes | None,
    wall_length: float,
    expanded_length: float,
    *,
    remap_offset: float = 0.125,
) -> BoardWallSpaceRecord:
    """Pack known `BoardWallSpace::new` fields without guessing shape expansion."""
    original = bytes(original_shape_payload or (b'\x00' * 28))
    expanded = bytes(expanded_shape_payload or (b'\x00' * 28))
    return BoardWallSpaceRecord(original, expanded, wall_length,
                                expanded_length, remap_offset)


def expand_shape_parameters(shape_payload: bytes, offset: float = 0.125) -> bytes:
    """Bit-ordered `ShapeParameters::expand` (0x140a85120).

    The native routine copies 28 bytes, then branches on discriminant u32 at
    offset zero. Rectangle tag 1 grows both dimensions at +0x14/+0x18 by
    `2*offset`; circle/freeform shapes grow the scalar at +0x0c by offset.
    """
    if len(shape_payload) != 28:
        raise ValueError('shape_payload must be 28 bytes')
    out = bytearray(shape_payload)
    delta = _f32(offset)
    if struct.unpack_from('<I', out, 0)[0] == 1:
        delta = _f32(delta + delta)
        for field_offset in (0x14, 0x18):
            value = struct.unpack_from('<f', out, field_offset)[0]
            struct.pack_into('<f', out, field_offset, _f32(value + delta))
    else:
        value = struct.unpack_from('<f', out, 0x0c)[0]
        struct.pack_into('<f', out, 0x0c, _f32(value + delta))
    return bytes(out)


def shape_curve_kind(shape_payload: bytes) -> str:
    """Return the native `ShapeParameters::as_curve2` dispatch kind."""
    if len(shape_payload) != 28:
        raise ValueError('shape_payload must be 28 bytes')
    return 'rectangle' if struct.unpack_from('<I', shape_payload, 0)[0] == 1 else 'circle'


def circle_sample_count(radius: float, tolerance: float = 0.2) -> int:
    """Recover `Circle2d::as_points2_ptcount` count selection."""
    circumference = _f32(_f32(radius) * _f32(6.2831854820251465))
    value = math.ceil(circumference / _f32(tolerance))
    return max(3, max(0, int(value)))


def circle_sample_points(center: tuple[float, float], radius: float,
                         tolerance: float = 0.2) -> tuple[tuple[float, float], ...]:
    """Deterministic point domain consumed by native Circle2d::as_curve2."""
    count = circle_sample_count(radius, tolerance)
    cx, cy = map(_f32, center)
    radius = _f32(radius)
    tau = _f32(6.2831854820251465)
    result = []
    for index in range(count):
        angle = _f32(_f32(index / count) * tau)
        result.append((_f32(cx + _f32(math.cos(angle) * radius)),
                       _f32(cy + _f32(math.sin(angle) * radius))))
    return tuple(result)


def rectangle_curve2_reference(rectangle: Rectangle2) -> Curve2:
    """Reconstruct the point-domain output of `Rectangle2d::as_curve2`."""
    corners = tuple(rectangle_point(rectangle, index) for index in range(4))
    points = corners + (corners[0],)
    return curve2_from_points(points)


def curve2_from_points(points: tuple[tuple[float, float], ...], *, closed: bool = False) -> Curve2:
    """Mirror the normal `Curve::try_new_from_points` cumulative-u path."""
    points = tuple(tuple(_f32(value) for value in point) for point in points)
    if len(points) < 2:
        raise ValueError('Curve2 requires at least two points')
    cumulative = [0.0]
    total = 0.0
    for start, end in zip(points, points[1:]):
        dx = _f32(end[0] - start[0])
        dy = _f32(end[1] - start[1])
        segment = _f32(math.sqrt(_f32(dx * dx + dy * dy)))
        total = _f32(total + segment)
        cumulative.append(total)
    if total == 0.0 or not math.isfinite(total):
        raise ValueError('Curve2 points must have finite non-zero length')
    u_values = tuple(_f32(value / total) for value in cumulative)
    return Curve2(points, u_values, total)

@dataclasses.dataclass(frozen=True)
class Curve2:
    points: tuple
    u_values: tuple
    length: float

@dataclasses.dataclass(frozen=True)
class Rectangle2:
    # Native layout: rotation cos/sin +0/+4; center x/z +8/+12; width/height +16/+20.
    rotation: tuple
    center: tuple
    dimensions: tuple

def rectangle_rotate(rectangle, local):
    c, s = map(r.f32, rectangle.rotation)
    x, z = map(r.f32, local)
    return r.f32(r.f32(x * c) + r.f32(z * -s)), r.f32(r.f32(x * s) + r.f32(z * c))

def rectangle_point(rectangle, corner):
    """0x140df3e10: corner sequence walks left/bottom -> left/top clockwise."""
    if corner == 4:
        corner = 0
    factors = [(-.5, -.5), (-.5, .5), (.5, .5), (.5, -.5)][corner]
    local = tuple(r.f32(r.f32(d) * factor) for d, factor in zip(rectangle.dimensions, factors))
    rotated = rectangle_rotate(rectangle, local)
    return tuple(r.f32(v + r.f32(c)) for v, c in zip(rotated, rectangle.center))

def rectangle_edge_normal(rectangle, edge):
    """0x140df1760: preserve signed zeros of the original lookup tables."""
    return rectangle_rotate(rectangle, [(-1.0, -0.0), (0.0, 1.0), (1.0, 0.0), (-0.0, -1.0)][edge])

def remap_x_rectangle(distance, original, expanded, original_length, expanded_length, offset=.125):
    """0x141483e90 rectangle branch: offset original edge, project to expanded edge."""
    original_length, expanded_length = r.f32(original_length), r.f32(expanded_length)
    distance = min(original_length, max(0.0, r.f32(distance)))
    corners = [r.f32(r.rectangle_point_u(*original.dimensions, i) * original_length) for i in range(5)]
    side = 0
    while side < 4 and r.f32(corners[side + 1] + r.f32(.0001)) < distance:
        side += 1
    if side == 4:
        return expanded_length
    local = min(r.f32(corners[side + 1] - corners[side]), max(0.0, r.f32(distance - corners[side])))
    a, b = rectangle_point(original, side), rectangle_point(original, side + 1)
    normal = rectangle_edge_normal(original, side)
    exa, exb = rectangle_point(expanded, side), rectangle_point(expanded, side + 1)
    delta = tuple(r.f32(y - x) for x, y in zip(a, b))
    square = r.f32(r.f32(delta[1] * delta[1]) + r.f32(delta[0] * delta[0]))
    inverse = r.f32(1.0 / r.f32(math.sqrt(square)))
    tangent = tuple(r.f32(v * inverse) for v in delta)
    position = tuple(r.f32(r.f32(r.f32(n * r.f32(offset)) + r.f32(r.f32(t * local) + v)) - e)
                     for n, t, v, e in zip(normal, tangent, a, exa))
    expanded_delta = tuple(r.f32(y - x) for x, y in zip(exa, exb))
    numerator = r.f32(r.f32(position[1] * expanded_delta[1]) + r.f32(position[0] * expanded_delta[0]))
    denominator = max(r.f32(r.f32(expanded_delta[1] * expanded_delta[1]) +
                             r.f32(expanded_delta[0] * expanded_delta[0])), r.f32(1e-20))
    weight = min(1.0, max(0.0, r.f32(numerator / denominator)))
    edge_length = r.f32(math.sqrt(r.f32(r.f32(expanded_delta[1] * expanded_delta[1]) +
                                           r.f32(expanded_delta[0] * expanded_delta[0]))))
    start = r.f32(r.rectangle_point_u(*expanded.dimensions, side) * expanded_length)
    return r.f32(r.f32(edge_length * weight) + start)

def nearest_curve_u(curve, position):
    """0x141e38fb0: closest line-segment point; first segment wins ties."""
    px, py = map(r.f32, position)
    points = [tuple(map(r.f32, v)) for v in curve.points]
    us = list(map(r.f32, curve.u_values))
    best_distance = math.inf
    selected, weight = 0, 0.0
    for i, (a, b) in enumerate(zip(points, points[1:])):
        dx, dy = r.f32(b[0] - a[0]), r.f32(b[1] - a[1])
        square = max(r.f32(r.f32(dy * dy) + r.f32(dx * dx)), r.f32(1e-8))
        dot = r.f32(r.f32(r.f32(py - a[1]) * dy) + r.f32(r.f32(px - a[0]) * dx))
        t = min(1.0, max(0.0, r.f32(dot / square)))
        complement = r.f32(1.0 - t)
        closest = tuple(r.f32(r.f32(t * end) + r.f32(complement * start)) for start, end in zip(a, b))
        ox, oy = r.f32(px - closest[0]), r.f32(py - closest[1])
        distance = r.f32(math.sqrt(r.f32(r.f32(oy * oy) + r.f32(ox * ox))))
        if distance < best_distance:
            best_distance, selected, weight = distance, i, t
    return r.f32(r.f32(weight * us[selected + 1]) + r.f32(r.f32(1.0 - weight) * us[selected]))

def world_to_wallspace(curve, position):
    """0x140dea520: ignores Y, clamps nearest u to [0,1], multiplies length."""
    value = nearest_curve_u(curve, (position[0], position[2]))
    return r.f32(min(1.0, max(0.0, value)) * r.f32(curve.length))

def arch_openings_to_aabb2(curve, openings, bottom_y, wall_length, freeform):
    """0x1414853f0: each opening is (height_offsets, XYZ positions).

    freeform=True models PublicWallState shape discriminant 2 (no perimeter
    wrapping). Other discriminants model an enclosed perimeter and split seam
    crossing bounds into intervals in [0,wall_length].
    """
    wall_length = r.f32(wall_length)
    bottom = r.f32(r.f32(bottom_y) + r.f32(-.2))
    result = []
    for offsets, positions in openings:
        count = min(len(offsets), len(positions))
        if count == 0:
            continue
        xmin, xmax, top = math.inf, -math.inf, -math.inf
        previous = None
        for offset, position in zip(offsets[:count], positions[:count]):
            x = world_to_wallspace(curve, position)
            if previous is not None and not freeform and x < previous:
                while x < previous:
                    x = r.f32(x + wall_length)
            y = r.f32(r.f32(position[1]) + r.f32(offset))
            xmin, xmax, top = min(xmin, x), max(xmax, x), max(top, y)
            previous = x
        if not all(math.isfinite(v) for v in (xmin, xmax, bottom, top)):
            continue
        if freeform:
            result.append((xmin, bottom, xmax, top))
        elif wall_length > r.f32(.01):
            if r.f32(wall_length + r.f32(-.0001)) <= r.f32(xmax - xmin):
                result.append((0.0, bottom, wall_length, top))
                continue
            end = r.f32(xmax + r.f32(-.0001))
            while xmin < end:
                start = r.f32(math.fmod(xmin, wall_length))
                if start < 0:
                    start = r.f32(abs(wall_length) + start)
                size = min(r.f32(xmax - xmin), r.f32(wall_length - start))
                if size <= r.f32(.0001):
                    break
                result.append((start, bottom, r.f32(start + size), top))
                xmin = r.f32(xmin + size)
    return result

def remap_x_linear(distance, original_length, expanded_length):
    """0x141483e90 when original/expanded shapes are not both rectangles."""
    original_length, expanded_length = r.f32(original_length), r.f32(expanded_length)
    distance = min(original_length, max(0.0, r.f32(distance)))
    return r.f32(r.f32(distance / original_length) * expanded_length)

def remap_cutouts_linear(cutouts, original_length, expanded_length):
    """Final loop of 0x141484310, for linear BoardWallSpace mapping."""
    original_length, expanded_length = r.f32(original_length), r.f32(expanded_length)
    result = []
    for x0, y0, x1, y1 in cutouts:
        x0, y0, x1, y1 = map(r.f32, (x0, y0, x1, y1))
        a = remap_x_linear(x0, original_length, expanded_length)
        b = remap_x_linear(x1, original_length, expanded_length)
        start = 0.0 if x0 <= r.f32(.0001) else min(a, b)
        end = expanded_length if x1 >= r.f32(original_length + r.f32(-.0001)) else max(a, b)
        result.append((start, y0, end, y1))
    return result

def remapped_wall_cutouts(curve, openings, holes, bottom_y, wall_length, freeform,
                         expanded_length, original_rectangle=None, expanded_rectangle=None, offset=.125):
    """0x141484310: filter 20-byte hole records, append arch cuts, remap ranges.

    holes=(rectangle, type_byte, origin_byte); type 0 is excluded by original
    machine code. Origin is not inspected in this provider. Rectangles are
    original wallspace coordinates, before BoardWallSpace expansion.
    """
    cuts = [tuple(map(r.f32, rect)) for rect, type_byte, origin in holes if type_byte]
    cuts += arch_openings_to_aabb2(curve, openings, bottom_y, wall_length, freeform)
    if original_rectangle is None or expanded_rectangle is None:
        return remap_cutouts_linear(cuts, wall_length, expanded_length)
    result = []
    wall_length, expanded_length = r.f32(wall_length), r.f32(expanded_length)
    for x0, y0, x1, y1 in cuts:
        a = remap_x_rectangle(x0, original_rectangle, expanded_rectangle, wall_length, expanded_length, offset)
        b = remap_x_rectangle(x1, original_rectangle, expanded_rectangle, wall_length, expanded_length, offset)
        start = 0.0 if x0 <= r.f32(.0001) else min(a, b)
        end = expanded_length if x1 >= r.f32(wall_length + r.f32(-.0001)) else max(a, b)
        result.append((start, y0, end, y1))
    return result

def plan_wall_boards_from_world(regions, spacing, horizontal, curve, openings, holes,
                                bottom_y, wall_length, freeform, expanded_length, samples=(), closed=False,
                                cap_y=1, original_rectangle=None, expanded_rectangle=None, offset=.125):
    import recovered_wall_planners as planner
    cuts = remapped_wall_cutouts(curve, openings, holes, bottom_y, wall_length, freeform,
                                expanded_length, original_rectangle, expanded_rectangle, offset)
    return planner.plan_wall_boards(regions, cuts, spacing, horizontal, samples, expanded_length, closed, cap_y)
