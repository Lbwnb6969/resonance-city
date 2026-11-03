"""CPU reference for Grass2 ``combine_grass_removal`` and active dispatch."""
from __future__ import annotations

import dataclasses
import math
from typing import Callable, Sequence


def clamp(value: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, float(value)))


def smoothstep(edge0: float, edge1: float, value: float) -> float:
    t = clamp((float(value) - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


@dataclasses.dataclass(frozen=True)
class RemovalInputs:
    path: float
    water_y: float
    foliage_exclusion_x: float
    rocky: tuple[float, float, float, float]
    building_max: float
    garden_max: float


@dataclasses.dataclass(frozen=True)
class RemovalMask:
    removal: float
    opacity: float


def combine_grass_removal(values: RemovalInputs) -> RemovalMask:
    path_s = smoothstep(0.1, 0.2, values.path)
    water_s = smoothstep(0.12, 0.28, min(values.water_y, 1.0 - values.water_y))
    rocky_gate = float((values.rocky[0] + smoothstep(0.0, 0.5, values.rocky[1])
                        + values.rocky[2] * 0.4) > 0.2)
    removal = max(
        float(path_s > 0.9),
        float(values.foliage_exclusion_x > 0.0),
        water_s,
        rocky_gate,
        values.garden_max,
    )
    opacity = clamp(min(
        1.0 - path_s * 0.7,
        max(1.0 - smoothstep(0.3, 0.4, values.building_max),
            smoothstep(0.5, 0.7, values.building_max) * 0.4),
        1.0 - values.water_y * 0.5,
    ), 0.0, 1.0)
    return RemovalMask(clamp(removal, 0.0, 1.0), opacity)


def combine_grass_removal_texels(
    xy: tuple[int, int],
    *,
    path_mask: Callable[[int, int], float],
    water_mask: Callable[[int, int], Sequence[float]],
    foliage_exclusion_mask: Callable[[int, int], Sequence[float]],
    rocky_terrain: Callable[[int, int], Sequence[float]],
    building_mask: Callable[[int, int], float],
    garden_mask: Callable[[int, int], Sequence[float]],
) -> RemovalMask:
    """Sample the exact source texels, including the shader's 3×3 max pass."""
    x, y = int(xy[0]), int(xy[1])
    building_max = 0.0
    garden_max = 0.0
    for oy in range(-1, 2):
        for ox in range(-1, 2):
            building_max = max(building_max, float(building_mask(x + ox, y + oy)))
            garden_max = max(garden_max, float(float(garden_mask(x + ox, y + oy)[1]) > 0.402))
    water = water_mask(x, y)
    rocky = rocky_terrain(x, y)
    foliage = foliage_exclusion_mask(x, y)
    return combine_grass_removal(RemovalInputs(
        float(path_mask(x, y)), float(water[1]), float(foliage[0]),
        tuple(float(value) for value in rocky[:4]), building_max, garden_max))


def active_cull_dispatch_args(active_count: int, group_size: int) -> tuple[int, int, int]:
    """Mirror ``grass2/active_cull_dispatch_args`` uvec3 output."""
    if active_count < 0 or group_size <= 0:
        raise ValueError('active_count must be non-negative and group_size positive')
    return ((int(active_count) + int(group_size) - 1) // int(group_size), 1, 1)
