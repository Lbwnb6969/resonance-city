"""CPU reference for Nani indirect dispatch argument generation."""
from __future__ import annotations

import dataclasses
from typing import Sequence


@dataclasses.dataclass(frozen=True)
class DispatchArgs:
    x: int
    y: int = 1
    z: int = 1
    w: int = 0


@dataclasses.dataclass(frozen=True)
class NaniDispatchResult:
    thread_counts: tuple[int, ...]
    filtered_dispatch: tuple[DispatchArgs, ...]
    merge_dispatch: tuple[DispatchArgs, ...]
    prefix_dispatch: tuple[DispatchArgs, ...]
    two_pass_dispatch: tuple[DispatchArgs, ...]


def _ceil_div(value: int, divisor: int) -> int:
    if divisor <= 0:
        raise ValueError("divisor must be positive")
    return (int(value) + divisor - 1) // divisor


def generate_dispatch_args(
    allocator_values: Sequence[int],
    instance_offsets: Sequence[int],
    merge_window_size: int,
) -> NaniDispatchResult:
    """Mirror all four dispatch argument arrays from ``generate_dispatch_args``."""
    if len(allocator_values) != len(instance_offsets):
        raise ValueError("allocator_values and instance_offsets must have equal length")
    if merge_window_size <= 0:
        raise ValueError("merge_window_size must be positive")
    counts = []
    filtered = []
    merged = []
    prefix = []
    two_pass = []
    for allocator, offset in zip(allocator_values, instance_offsets):
        count = int(allocator) - int(offset)
        if count < 0:
            raise ValueError("allocator value must be at least its list offset")
        counts.append(count)
        filtered.append(DispatchArgs(_ceil_div(count, 64)))
        merged.append(DispatchArgs(_ceil_div(count, merge_window_size)))
        prefix.append(DispatchArgs(_ceil_div(count, merge_window_size * 1024)))
        two_pass.append(DispatchArgs(1 if count >= merge_window_size * 2048 else 0))
    return NaniDispatchResult(tuple(counts), tuple(filtered), tuple(merged),
                              tuple(prefix), tuple(two_pass))


def draw_indexed_indirect_to_dispatch(instance_count: int, group_size: int) -> DispatchArgs:
    """Mirror ``draw_indexed_indirect_to_dispatch/000.comp`` output."""
    if instance_count < 0 or group_size <= 0:
        raise ValueError("instance_count must be non-negative and group_size positive")
    return DispatchArgs(_ceil_div(instance_count, group_size), 1, 1, int(instance_count))
