"""CPU reference for Nani histogram prefix and sorted-instance staging."""
from __future__ import annotations

import dataclasses
from typing import Sequence

BUCKET_COUNT = 1024


def exclusive_prefix(counts: Sequence[int], base: int = 0) -> tuple[tuple[int, ...], int]:
    if base < 0 or any(int(count) < 0 for count in counts):
        raise ValueError("base and counts must be non-negative")
    cursor = int(base)
    offsets: list[int] = []
    for count in counts:
        offsets.append(cursor)
        cursor += int(count)
    return tuple(offsets), cursor


@dataclasses.dataclass(frozen=True)
class SortedInstanceResult:
    sorted_instances: tuple[int, ...]
    bucket_offsets: tuple[int, ...]
    bucket_counts: tuple[int, ...]
    mesh_instance_counts: tuple[int, ...]


def fill_unsorted_instance_list(
    filtered_instances: Sequence[int],
    filtered_mesh_indices: Sequence[int],
    bucket_offsets: Sequence[int],
    *,
    mesh_count: int = BUCKET_COUNT,
    list_instance_offset: int = 0,
) -> SortedInstanceResult:
    """Mirror ``fill_unsorted_instance_list`` with stable atomic allocation.

    The shader's raw filtered value is ``local_index * 1024 + bucket``.  The
    bucket prefix has already been produced from cull's output histogram;
    each atomic increment reserves a slot inside that bucket range and stores
    ``local_index * 1024 + atlas_mesh``.
    """
    if len(filtered_instances) != len(filtered_mesh_indices):
        raise ValueError("filtered instances and mesh metadata must have equal length")
    if len(bucket_offsets) != BUCKET_COUNT:
        raise ValueError("bucket_offsets must contain 1024 entries")
    if list_instance_offset < 0 or mesh_count <= 0:
        raise ValueError("invalid list offset or mesh count")
    counts = [0] * BUCKET_COUNT
    mesh_counts = [0] * mesh_count
    for raw, mesh in zip(filtered_instances, filtered_mesh_indices):
        bucket = int(raw) % BUCKET_COUNT
        mesh = int(mesh)
        if mesh < 0 or mesh >= mesh_count:
            raise ValueError("mesh index outside mesh_count")
        counts[bucket] += 1
        mesh_counts[mesh] += 1
    total = sum(counts)
    end = list_instance_offset + total
    sorted_values = [0] * end
    cursors = [int(value) for value in bucket_offsets]
    for raw, mesh in zip(filtered_instances, filtered_mesh_indices):
        bucket = int(raw) % BUCKET_COUNT
        destination = cursors[bucket]
        cursors[bucket] += 1
        if destination < list_instance_offset or destination >= end:
            raise ValueError("bucket offsets do not address the instance list")
        sorted_values[destination] = (int(raw) // BUCKET_COUNT) * BUCKET_COUNT + int(mesh)
    return SortedInstanceResult(tuple(sorted_values), tuple(int(v) for v in bucket_offsets),
                                tuple(counts), tuple(mesh_counts))


def fill_unsorted_instance_indirection(
    sorted_instances: Sequence[int],
    mesh_prefix: Sequence[int],
    *,
    instance_count: int,
    draw_list_index: int = 0,
    list_instance_offset: int = 0,
) -> tuple[int, ...]:
    """Mirror ``fill_unsorted_instance_indirection`` using stable writes."""
    if instance_count < 0 or list_instance_offset < 0:
        raise ValueError("instance_count and list_instance_offset must be non-negative")
    if instance_count > len(sorted_instances) - list_instance_offset:
        raise ValueError("instance_count exceeds sorted instance list")
    if len(mesh_prefix) != BUCKET_COUNT:
        raise ValueError("mesh_prefix must contain 1024 entries")
    destinations = [int(value) for value in mesh_prefix]
    total_end = max(destinations, default=0)
    for value in destinations:
        total_end = max(total_end, value)
    # Expand on demand as the shader writes instance indirection entries.
    output = [0] * total_end
    for index in range(instance_count):
        value = int(sorted_instances[list_instance_offset + index])
        mesh = value % BUCKET_COUNT
        destination = destinations[mesh]
        destinations[mesh] += 1
        if destination >= len(output):
            output.extend([0] * (destination + 1 - len(output)))
        output[destination] = value // BUCKET_COUNT
    return tuple(output)
