"""End-to-end deterministic CPU reference for the recovered Nani stages."""
from __future__ import annotations

import dataclasses
from typing import Mapping, Sequence

from nani_cull_reference import NaniCullResult, PackedInstance, cull_and_bucket
from nani_draw_reference import DrawIndexedIndirectCommand, MeshAtlasPartInfo, NaniDrawResult, generate_draw_lists
from nani_sort_reference import SortedInstanceResult, exclusive_prefix, fill_unsorted_instance_list


@dataclasses.dataclass(frozen=True)
class NaniPipelineResult:
    cull: NaniCullResult
    sorted_stage: SortedInstanceResult
    draw: NaniDrawResult


def run_nani_pipeline(
    instances: Sequence[PackedInstance],
    view_positions: Sequence[Sequence[float]],
    mesh_radii: Sequence[float],
    mesh_info: Mapping[int, MeshAtlasPartInfo],
    merge_window_sizes: Sequence[int],
    *,
    previous_visibility_words: Sequence[int],
    side_planes: Sequence[Sequence[float]],
    clip_z_w: float,
    draw_list_index: int = 0,
    global_instance_offset: int = 0,
    instance_indirection_base: int = 0,
) -> NaniPipelineResult:
    """Run cull, histogram prefix, sorted staging and draw-list generation."""
    cull = cull_and_bucket(
        instances, view_positions, mesh_radii,
        world_subset=0, draw_list_index_base=draw_list_index,
        global_instance_offset=global_instance_offset,
        previous_visibility_words=previous_visibility_words,
        side_planes=side_planes, clip_z_w=clip_z_w,
    )
    histogram_start = draw_list_index * 1024
    histogram_counts = cull.histogram[histogram_start:histogram_start + 1024]
    bucket_offsets, total = exclusive_prefix(histogram_counts)
    if total != len(cull.filtered_instances):
        raise ValueError("cull histogram total does not match filtered instance count")
    sorted_stage = fill_unsorted_instance_list(
        cull.filtered_instances, cull.filtered_mesh_indices, bucket_offsets)
    draw = generate_draw_lists(
        sorted_stage.sorted_instances, merge_window_sizes, mesh_info,
        instance_indirection_base=instance_indirection_base)
    return NaniPipelineResult(cull, sorted_stage, draw)
