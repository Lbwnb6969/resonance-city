"""CPU reference for the deterministic Grass2 build-draws sampling stage.

The implementation follows the recovered `grass2/build_draws/000.comp`
constants and integer operations.  Texture reads are supplied by callers;
GPU atomics and workgroup scheduling remain outside this module.
"""
from __future__ import annotations

import dataclasses
import math
import struct
from typing import Callable, Iterable, Sequence

U32_MASK = 0xffffffff
LOCAL_COUNT = 14336
LARGE_COUNT = 30720
LOCAL_EXTENT = 130.0
LARGE_EXTENT = 190.0
INV_2_32 = 2.3283064365386962890625e-10


def u32(value: int) -> int:
    return int(value) & U32_MASK


def f32(value: float) -> float:
    return struct.unpack('<f', struct.pack('<f', float(value)))[0]


def reverse_bits32(value: int) -> int:
    value = u32(value)
    value = u32((value << 16) | (value >> 16))
    value = u32(((value & 0x55555555) << 1) | ((value & 0xaaaaaaaa) >> 1))
    value = u32(((value & 0x33333333) << 2) | ((value & 0xcccccccc) >> 2))
    value = u32(((value & 0x0f0f0f0f) << 4) | ((value & 0xf0f0f0f0) >> 4))
    return u32(((value & 0x00ff00ff) << 8) | ((value & 0xff00ff00) >> 8))


def hash_u32(seed: int) -> int:
    """The shader's final integer hash before float/modulo use."""
    value = u32(seed)
    value = u32(value + (value << 10))
    value ^= value >> 6
    value = u32(value + (value << 3))
    value ^= value >> 11
    value = u32(value + (value << 15))
    return value


def unit_hash(seed: int) -> float:
    """The shader's integer hash converted to [0,1)."""
    value = hash_u32(seed)
    bits = (value & 0x007fffff) | 0x3f800000
    return f32(struct.unpack('<f', struct.pack('<I', bits))[0] - 1.0)


def sample_position(global_id: int) -> tuple[float, float]:
    """Reproduce the two shader low-discrepancy point domains."""
    gid = u32(global_id)
    if gid < LOCAL_COUNT:
        sample = gid % LOCAL_COUNT + 1
        extent = LOCAL_EXTENT
        x = float(sample) * f32(6.975446740398183e-05) - 0.5
        y = float(reverse_bits32(sample)) * f32(INV_2_32) - 0.5
    else:
        sample = u32(gid - 57344) % LARGE_COUNT + 1
        extent = LARGE_EXTENT
        x = float(sample) * f32(3.2552085031056777e-05) - 0.5
        y = float(reverse_bits32(sample)) * f32(INV_2_32) - 0.5
    return f32(x * extent), f32(y * extent)


def sample_texel(position: Sequence[float]) -> tuple[int, int]:
    """Map world point to the 512² plant-sample texel used by the shader."""
    return tuple(min(511, max(0, int((float(v) / 130.0 + 0.5) * 512.0))) for v in position[:2])


def water_exemplar(values: Sequence[int], seaweed_plant_type: int, theme_id: int) -> int | None:
    count = sum(1 for value in values[:4] if int(value) != 0)
    if theme_id == 4 or count == 0:
        return None
    return (4 * int(seaweed_plant_type) + count - 1) & 0xff


@dataclasses.dataclass(frozen=True)
class LandRun:
    value: int
    count: int
    output_index: int
    attribute: int


def land_runs(values: Sequence[int], global_id: int, theme_id: int) -> tuple[LandRun, ...]:
    """Run-length encode four plant channels with the theme-4 zero skip."""
    values = tuple(int(v) & U32_MASK for v in values[:4])
    result = []
    cursor = 0
    group = 0
    while cursor < len(values):
        value = values[cursor]
        count = 1
        while cursor + count < len(values) and values[cursor + count] == value:
            count += 1
        skipped = theme_id == 4 and value == 0 and hash_u32(global_id) % 3 == 0
        if not skipped:
            output = u32(global_id + group * LOCAL_COUNT)
            result.append(LandRun(value, count, output, ((4 * value + count - 1) & 0xff) | 0xffff0000))
            group += 1
        cursor += count
    return tuple(result)


def terrain_height_ratio(terrain_height: float, max_y: float, scale_min: float,
                         scale_max: float, random_value: float) -> float:
    denominator = f32(max_y * f32(scale_min + (scale_max - scale_min) * f32(random_value * random_value)))
    if denominator == 0.0:
        return 0.0
    return max(0.0, min(1.0, f32((-0.1 - terrain_height) / denominator)))


def _smoothstep(edge0: float, edge1: float, value: float) -> float:
    t = max(0.0, min(1.0, f32((value - edge0) / (edge1 - edge0))))
    return f32(t * t * f32(3.0 - 2.0 * t))


@dataclasses.dataclass(frozen=True)
class LargeWorldGateResult:
    """Decision and intermediates for the 30-unit outer Grass2 sample ring."""

    global_id: int
    position: tuple[float, float]
    distance_to_inner_bounds: float
    distance_ratio: float
    displaced_position: tuple[float, float]
    displaced_path_position: tuple[float, float]
    path_uv: tuple[float, float]
    path_random: float
    path_threshold: float
    path_rejected: bool
    water_rejected: bool
    theme_rejected: bool
    exemplar_random: float
    exemplar: int
    accepted: bool
    packed_attribute: int | None


def large_world_gate(
    global_id: int,
    position: Sequence[float],
    theme_id: int,
    *,
    path_mask_sample: float = 0.0,
    water_footprint_ws: Sequence[float] | None = None,
    terrain_height_sample: float | None = None,
    path_mask: Callable[[tuple[float, float]], float] | None = None,
    terrain_height: Callable[[tuple[float, float]], float] | None = None,
) -> LargeWorldGateResult:
    """Reproduce the large-world branch of ``grass2/build_draws``.

    The shader invokes this branch for IDs 57344 and above.  ``position`` is
    the 130/190-unit sample point before the edge displacement.  Texture
    callbacks are optional; direct samples keep the reference deterministic
    and make branch tests independent of an image loader.
    """
    if len(position) < 2:
        raise ValueError("position must contain x and y")
    gid = u32(global_id)
    px, py = f32(position[0]), f32(position[1])
    clamped_x = max(-65.0, min(65.0, px))
    clamped_y = max(-65.0, min(65.0, py))
    dx = f32(px - clamped_x)
    dy = f32(py - clamped_y)
    distance = f32(math.sqrt(dx * dx + dy * dy))
    ratio = f32(distance * (1.0 / 30.0))

    # The shader exits for the inner square and for samples at/over 30 units.
    if distance <= 0.0 or distance >= 30.0:
        return LargeWorldGateResult(
            gid, (px, py), distance, ratio, (px, py), (px, py), (0.5, 0.5),
            unit_hash(gid + 83435), 0.0, False, False, False, 0.0, 0, False, None,
        )

    edge_amount = f32(5.0 * _smoothstep(0.0, 0.4, max(0.0, min(1.0, ratio))))
    displaced = (
        f32(px + math.sin(f32(py * 0.3490658700466156 + px * 0.15707963705062866)) * edge_amount),
        f32(py + math.sin(f32(px * 0.3490658700466156 + py * 0.15707963705062866)) * edge_amount),
    )
    path_clamp = (max(-53.0, min(53.0, displaced[0])),
                  max(-53.0, min(53.0, displaced[1])))
    path_dx = f32(displaced[0] - path_clamp[0])
    path_dy = f32(displaced[1] - path_clamp[1])
    path_distance = max(math.sqrt(path_dx * path_dx + path_dy * path_dy), 1.0e-4)
    path_scale = min(path_distance, 12.0) / path_distance
    path_position = (f32(path_clamp[0] + path_dx * path_scale),
                     f32(path_clamp[1] + path_dy * path_scale))
    path_uv = (f32(path_position[0] * (1.0 / 130.0) + 0.5),
               f32(path_position[1] * (1.0 / 130.0) + 0.5))
    if path_mask is not None:
        path_mask_sample = float(path_mask(path_uv))
    path_random = unit_hash(gid + 83435)
    path_threshold = _smoothstep(0.1, 0.2, path_mask_sample)
    path_rejected = path_random < path_threshold

    in_water_footprint = False
    water_rejected = False
    if water_footprint_ws is not None:
        if len(water_footprint_ws) != 4:
            raise ValueError("water_footprint_ws must be (min_x, min_y, max_x, max_y)")
        in_water_footprint = (
            px >= float(water_footprint_ws[0]) and py >= float(water_footprint_ws[1])
            and px <= float(water_footprint_ws[2]) and py <= float(water_footprint_ws[3])
        )
    if in_water_footprint:
        if terrain_height is not None:
            terrain_height_sample = float(terrain_height((f32(py * 0.001 + 0.5),
                                                          f32(1.0 - (px * 0.001 + 0.5)))))
        water_rejected = terrain_height_sample is not None and terrain_height_sample < 0.05
    theme_rejected = theme_id == 4 and hash_u32(gid) % 3 == 0

    exemplar_random = unit_hash(gid + 134719)
    exemplar = int(math.floor(f32((1.0 - ratio) * 4.0 + exemplar_random)))
    accepted = not (path_rejected or water_rejected or theme_rejected or exemplar == 0)
    packed_attribute = None if not accepted else u32(((min(exemplar, 4) - 1) & 0xff) | 0xffff0000)
    return LargeWorldGateResult(
        gid, (px, py), distance, ratio, displaced, path_position, path_uv,
        path_random, path_threshold, path_rejected, water_rejected, theme_rejected,
        exemplar_random, exemplar, accepted, packed_attribute,
    )

