"""Deterministic CPU reference for the recovered Grass2 draw handoff.

This module composes the already recovered per-card transform with a stable
active-instance grouping pass.  It describes the data that must reach indirect
draw generation; it does not claim to reproduce GPU subgroup scheduling,
atomics, barriers, or raster results.
"""
from __future__ import annotations

import dataclasses
from collections import OrderedDict
from typing import Iterable, Mapping, Sequence

from grass2_runtime_reference import Clump, Texture, TransformResult, transform_card


@dataclasses.dataclass(frozen=True)
class GrassCard:
    instance_id: int
    exemplar: int
    clump: Clump
    position_word: int
    plant_offset_word: int
    bounds: tuple


@dataclasses.dataclass(frozen=True)
class ActiveCard:
    active_index: int
    card: GrassCard
    transform: TransformResult


@dataclasses.dataclass(frozen=True)
class IndirectDraw:
    exemplar: int
    index_count: int
    instance_count: int
    first_index: int
    vertex_offset: int
    first_instance: int


@dataclasses.dataclass(frozen=True)
class GrassDrawPlan:
    active: tuple
    discarded: tuple
    draws: tuple
    unknowns: tuple = (
        "GPU workgroup scans, atomics/barriers and final raster resolve",
    )


def build_draw_plan(
    cards: Iterable[GrassCard],
    index_counts: Mapping[int, int],
    *,
    removal_texture: Texture | None = None,
    object_push_texture: Texture | None = None,
    terrain_height_texture=None,
    terrain_height_texture_large=None,
    flat_terrain_height: float = 0.0,
) -> GrassDrawPlan:
    """Transform cards, retain visible entries, and build stable draw groups."""
    active = []
    discarded = []
    groups: "OrderedDict[int, list]" = OrderedDict()
    for card in cards:
        transformed = transform_card(
            card.clump, card.position_word, card.plant_offset_word, card.bounds,
            removal_texture=removal_texture,
            object_push_texture=object_push_texture,
            terrain_height_texture=terrain_height_texture,
            terrain_height_texture_large=terrain_height_texture_large,
            flat_terrain_height=flat_terrain_height,
        )
        if transformed.discard_by_removal:
            discarded.append(card.instance_id)
            continue
        row = ActiveCard(len(active), card, transformed)
        active.append(row)
        groups.setdefault(int(card.exemplar), []).append(row)
    draws = []
    first_index = 0
    for exemplar, rows in groups.items():
        count = int(index_counts.get(exemplar, 0))
        if count < 0:
            raise ValueError("index count must be non-negative")
        draws.append(IndirectDraw(exemplar, count, len(rows), first_index, 0,
                                  rows[0].active_index))
        first_index += count
    return GrassDrawPlan(tuple(active), tuple(discarded), tuple(draws))

