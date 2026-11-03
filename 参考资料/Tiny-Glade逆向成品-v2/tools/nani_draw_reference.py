"""CPU reference for Nani merge-window draw command generation."""
from __future__ import annotations

import dataclasses
from collections import Counter
from typing import Mapping, Sequence

ATLAS_ENTRY_COUNT = 1024


@dataclasses.dataclass(frozen=True)
class MeshAtlasPartInfo:
    first_index: int
    index_count: int
    bounding_sphere_radius: float = 0.0


@dataclasses.dataclass(frozen=True)
class DrawIndexedIndirectCommand:
    index_count: int
    instance_count: int
    first_index: int
    vertex_offset: int
    first_instance: int


@dataclasses.dataclass(frozen=True)
class NaniDrawResult:
    commands: tuple[DrawIndexedIndirectCommand, ...]
    instance_indirection: tuple[int, ...]
    window_command_counts: tuple[int, ...]
    window_command_offsets: tuple[int, ...]


def encode_sorted_instance(instance_index: int, mesh_index: int) -> int:
    if instance_index < 0 or mesh_index < 0 or mesh_index >= ATLAS_ENTRY_COUNT:
        raise ValueError("instance_index must be non-negative and mesh_index must fit 10 bits")
    return instance_index * ATLAS_ENTRY_COUNT + mesh_index


def decode_sorted_instance(value: int) -> tuple[int, int]:
    value = int(value)
    if value < 0:
        raise ValueError("sorted instance value must be non-negative")
    return value // ATLAS_ENTRY_COUNT, value % ATLAS_ENTRY_COUNT


def generate_draw_lists(
    sorted_instances: Sequence[int],
    merge_window_sizes: Sequence[int],
    mesh_info: Mapping[int, MeshAtlasPartInfo],
    *,
    instance_indirection_base: int = 0,
) -> NaniDrawResult:
    """Generate commands for the same merge windows as ``generate_draw_lists``.

    The shader's workgroups process one merge window and histogram mesh IDs
    from the sorted list.  Atlas entries are emitted in ascending mesh index,
    matching the shared histogram traversal.  The returned indirection list
    stores instance IDs (`sorted_value / 1024`) grouped by mesh command.
    """
    if instance_indirection_base < 0:
        raise ValueError("instance_indirection_base must be non-negative")
    commands: list[DrawIndexedIndirectCommand] = []
    indirection: list[int] = []
    counts: list[int] = []
    offsets: list[int] = []
    cursor = 0
    for window_size in merge_window_sizes:
        if window_size < 0:
            raise ValueError("merge window size must be non-negative")
        if cursor + window_size > len(sorted_instances):
            raise ValueError("merge windows exceed the sorted instance list")
        window = tuple(int(v) for v in sorted_instances[cursor:cursor + window_size])
        cursor += window_size
        histogram = Counter(decode_sorted_instance(value)[1] for value in window)
        counts.append(sum(1 for count in histogram.values() if count > 0))
        offsets.append(len(commands))
        for mesh_index in sorted(histogram):
            instance_count = histogram[mesh_index]
            info = mesh_info.get(mesh_index)
            if info is None:
                raise KeyError(f"missing mesh atlas entry {mesh_index}")
            first_instance = instance_indirection_base + len(indirection)
            commands.append(DrawIndexedIndirectCommand(
                index_count=int(info.index_count),
                instance_count=instance_count,
                first_index=int(info.first_index),
                vertex_offset=0,
                first_instance=first_instance,
            ))
            # The shader's second pass replays the merge-window entries and
            # atomically appends each instance into its mesh's command range.
            for value in window:
                instance_index, value_mesh = decode_sorted_instance(value)
                if value_mesh == mesh_index:
                    indirection.append(instance_index)
    if cursor < len(sorted_instances):
        raise ValueError("merge windows do not cover the sorted instance list")
    return NaniDrawResult(tuple(commands), tuple(indirection), tuple(counts), tuple(offsets))
