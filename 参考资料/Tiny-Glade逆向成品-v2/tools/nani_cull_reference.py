"""Deterministic CPU reference for Nani's ``cull_and_bucket`` shader.

The shipped shader reads packed 16-byte instances, performs a sphere test
against four normalized side planes plus a depth plane, carries visibility
through a previous-frame bitmask, and appends a 1024-bin depth bucket to the
filtered list while incrementing a draw-list histogram.  GPU atomic ordering
is intentionally represented by stable input order here.
"""
from __future__ import annotations

import dataclasses
import math
import struct
from typing import Sequence

U32_MASK = 0xFFFFFFFF
BUCKET_COUNT = 1024
BUCKET_SCALE = 0.0034722222480922937


def u32(value: int) -> int:
    return int(value) & U32_MASK


def unpack_half_low(word: int) -> float:
    return struct.unpack("<e", struct.pack("<H", int(word) & 0xFFFF))[0]


@dataclasses.dataclass(frozen=True)
class PackedInstance:
    position: tuple[float, float, float]
    radius_scale: float
    mesh_index: int

    @classmethod
    def from_words(cls, words: Sequence[int]) -> "PackedInstance":
        if len(words) != 4:
            raise ValueError("a Nani instance has four u32 words")
        return cls(
            tuple(struct.unpack("<3f", struct.pack("<3I", *(u32(v) for v in words[:3])))),
            unpack_half_low(words[3]),
            u32(words[3]) >> 16,
        )


@dataclasses.dataclass(frozen=True)
class NaniCullResult:
    visible_local_indices: tuple[int, ...]
    next_visibility_words: tuple[int, ...]
    filtered_instances: tuple[int, ...]
    filtered_mesh_indices: tuple[int, ...]
    histogram: tuple[int, ...]


def normalize_plane(plane: Sequence[float]) -> tuple[float, float, float, float]:
    if len(plane) != 4:
        raise ValueError("a plane has four coefficients")
    length = math.sqrt(sum(float(v) * float(v) for v in plane[:3]))
    if length == 0.0:
        raise ValueError("plane normal cannot be zero")
    return tuple(float(v) / length for v in plane)


def side_planes_from_view_to_clip(columns: Sequence[Sequence[float]]) -> tuple[tuple[float, float, float, float], ...]:
    """Build the four shader planes from a GLSL column-indexed mat4.

    ``columns`` uses the same indexing as ``view_to_clip[i][j]`` in the
    recovered GLSL, so this helper avoids guessing the host language's matrix
    row/column convention.
    """
    if len(columns) != 4 or any(len(column) != 4 for column in columns):
        raise ValueError("view_to_clip must contain four 4-element columns")
    c0, c1, c3 = columns[0], columns[1], columns[3]
    # The recovered shader explicitly constructs _771/_779/_784 instead of
    # adding the raw matrix columns.  In particular z is fixed to -1 and the
    # first helper negates only x.
    left = (c3[0] - c0[0], c3[1] + c0[1], -1.0, c3[3] + c0[3])
    right = (c3[0] + c0[0], c3[1] - c0[1], -1.0, c3[3] - c0[3])
    bottom = (c3[0] + c1[0], c3[1] + c1[1], -1.0, c3[3] + c1[3])
    top = (c3[0] - c1[0], c3[1] - c1[1], -1.0, c3[3] - c1[3])
    return tuple(normalize_plane(plane) for plane in (left, right, bottom, top))


def sphere_visible(
    view_position: Sequence[float],
    radius: float,
    side_planes: Sequence[Sequence[float]],
    clip_z_w: float,
) -> bool:
    """Mirror the shader's depth gate followed by four side-plane tests."""
    if len(view_position) != 3 or len(side_planes) != 4:
        raise ValueError("view_position must be xyz and side_planes must have four planes")
    z = float(view_position[2])
    if (-z + float(radius)) <= float(clip_z_w):
        return False
    point = (float(view_position[0]), float(view_position[1]), z, 1.0)
    return all(sum(point[i] * float(plane[i]) for i in range(4)) > -float(radius)
               for plane in side_planes)


def depth_bucket(view_z: float) -> int:
    value = max(0.0, min(1.0, (32.0 - float(view_z)) * BUCKET_SCALE))
    return max(0, min(BUCKET_COUNT - 1, int(value * BUCKET_COUNT)))


def cull_and_bucket(
    instances: Sequence[PackedInstance],
    view_positions: Sequence[Sequence[float]],
    mesh_radii: Sequence[float],
    *,
    world_subset: int,
    draw_list_index_base: int,
    global_instance_offset: int,
    previous_visibility_words: Sequence[int],
    side_planes: Sequence[Sequence[float]],
    clip_z_w: float,
) -> NaniCullResult:
    """Run a stable CPU equivalent of ``nani/cull_and_bucket``.

    ``instances`` and ``view_positions`` are parallel arrays.  The shader's
    atomic allocator determines GPU append order; this reference appends in
    local-index order and still returns the exact visibility and histogram
    decisions.
    """
    if len(instances) != len(view_positions):
        raise ValueError("instances and view_positions must have equal length")
    if world_subset < 0:
        raise ValueError("world_subset must be non-negative")
    next_words = [0] * len(previous_visibility_words)
    filtered: list[int] = []
    filtered_meshes: list[int] = []
    histogram = [0] * (BUCKET_COUNT * (draw_list_index_base + 1))
    visible: list[int] = []
    for local_index, (instance, view_position) in enumerate(zip(instances, view_positions)):
        mesh = int(instance.mesh_index)
        if mesh < 0 or mesh >= len(mesh_radii):
            raise ValueError("mesh_index is outside mesh_radii")
        radius = float(instance.radius_scale) * float(mesh_radii[mesh])
        global_index = int(global_instance_offset) + local_index
        word_index = global_index // 32
        bit = 1 << (global_index % 32)
        if word_index < 0 or word_index >= len(previous_visibility_words):
            continue
        if not sphere_visible(view_position, radius, side_planes, clip_z_w):
            continue
        if (u32(previous_visibility_words[word_index]) & bit) == 0:
            continue
        next_words[word_index] = u32(next_words[word_index] | bit)
        bucket = depth_bucket(float(view_position[2]))
        filtered.append(local_index * BUCKET_COUNT + bucket)
        filtered_meshes.append(mesh)
        histogram[draw_list_index_base * BUCKET_COUNT + bucket] += 1
        visible.append(local_index)
    return NaniCullResult(tuple(visible), tuple(next_words), tuple(filtered),
                          tuple(filtered_meshes), tuple(histogram))
