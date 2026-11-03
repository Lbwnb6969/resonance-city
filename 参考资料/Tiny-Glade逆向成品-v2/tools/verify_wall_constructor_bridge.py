"""Verify the planner-to-instance wall constructor bridge.

This is a deterministic reconstruction check.  It validates the known stage-3
record layouts and cut-list routing; it does not claim the opaque native
material/random stream is recovered.
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import recovered_wall_instances as instances  # noqa: E402
from recovered_wall_planners import Piece  # noqa: E402


def main() -> int:
    pieces = (
        Piece((0.0, 0.0, 1.5, 2.4), tag=1, key=7, flag=1, flag2=0),
        Piece((1.5, 0.0, 3.0, 2.4), tag=1, key=7, flag=1, flag2=1),
    )
    cuts = (
        instances.WallCut(0.75, 0.5, 1.1, 1.8, "window"),
        instances.WallCut(1.8, 0.2, 2.2, 1.1, "arch"),
    )
    provider = instances.WindowCutLists(((0.0, 0.0, 0.2, 0.2), (2.0, 2.0, 2.2, 2.2)), 0.5)
    assert provider.list_for_piece(Piece((0.4, 0.4, 0.7, 0.7))) == (0,)
    assert provider.list_for_piece(Piece((1.5, 1.5, 1.7, 1.7))) == ()
    native_provider = instances.WindowCutLists(
        ((0.0, 0.0, 0.2, 0.2), (2.0, 2.0, 2.2, 2.2)), 0.5,
        output_base=7)
    native_first = native_provider.native_result_for_piece(Piece((0.4, 0.4, 0.7, 0.7)))
    assert native_first.indices == (0,) and native_first.count == 1
    assert native_first.old_output_len == 0 and native_first.packed == 0x01000007
    assert native_first.call_counter == 1 and native_first.hash_state != 0
    native_second = native_provider.native_result_for_piece(Piece((1.5, 1.5, 1.7, 1.7)))
    assert native_second.indices == () and native_second.count == 0
    assert native_second.old_output_len == 1 and native_second.packed == 0
    assert native_second.call_counter == 2 and native_second.hash_state == native_first.hash_state
    assert instances.pack_window_cut_list(7, 3) == 0x03000007
    assert instances.pack_window_cut_list(0x1000000, 1) == 0
    assert instances.pack_window_cut_list(4, 0x1000) == 0xFF000004
    result = instances.assemble_wall_construction(
        pieces, wall_tag=0x1234, cuts=cuts, horizontal=True,
        curved={"circle": (1.0, 0.0, 2.0, 0.3), "circumference": 12.0,
                 "start": 0.0, "end": 3.0}, radial_width=0.2, merlon_mode=1)
    assert result.wall_tag == 0x1234
    assert len(result.placements) == 2
    assert result.placements[0].record_kind == "curved_horizontal"
    assert result.placements[0].cuts == (0,)
    assert result.placements[1].cuts == (1,)
    assert tuple(row.packed for row in result.window_results) == (0x01000000, 0x01000001)
    assert [row.old_output_len for row in result.window_results] == [0, 1]
    assert result.window_results[0].call_counter == 1 and result.window_results[1].call_counter == 2
    assert all(len(row.record) == 80 for row in result.placements)
    assert int.from_bytes(result.placements[0].record[72:76], "little") == 0x01000000
    assert int.from_bytes(result.placements[1].record[72:76], "little") == 0x01000001
    base = instances.curved_half_timber((1.0, 0.0, 2.0), 2.0, 0.2, 3, 0.0, 1.0, 2.4)
    helper_record = instances.curved_with_window_cut_list(
        instances.curved_with_flags(instances.curved_with_seed(base, 17), 4), 9)
    assert int.from_bytes(helper_record[52:56], "little") == 17
    assert int.from_bytes(helper_record[56:60], "little") & 4 == 4
    assert int.from_bytes(helper_record[72:76], "little") == 9
    raw_plank = instances.pack_wooden_plank_fields({'vec2_00': (1.0, 2.0), 'f08': 3.0,
                                                     'u32_30': 4, 'u64_40': 5})
    assert len(raw_plank) == 80 and int.from_bytes(raw_plank[64:72], "little") == 5
    assert int.from_bytes(raw_plank[0x30:0x34], "little") == 4
    plank_record = instances.WoodenPlankRecord.from_bytes(raw_plank)
    assert plank_record.gate_seed == 4 and plank_record.window_cut_buffer_address == 5
    assert plank_record.to_bytes() == raw_plank
    assert instances.decode_wooden_plank_flags(2 | 8 | 256) == {
        'default_wood_color': True, 'is_less_snowy': False, 'no_highlight': True,
        'source_is_color_id': False, 'is_freeform_wall': False,
        'curved_end_a': False, 'curved_end_b': False, 'no_snow': True}
    assert instances.wooden_shader_seed(
        instances.WoodenPlankRecord((0.0,) * 12, gate_seed=4, piece_seed=5)) == 54
    assert all(0.0 <= value < 1.0 for value in instances.wooden_shader_uv_jitter(plank_record))
    raw_gable = instances.pack_wooden_gable_plank_fields({'vec2_18': (6.0, 7.0),
                                                           'u32_58': 8, 'u64_50': 9})
    assert len(raw_gable) == 96 and int.from_bytes(raw_gable[0x58:0x5c], "little") == 8
    gable_record = instances.WoodenGablePlankRecord.from_bytes(raw_gable)
    assert gable_record.window_cut_list == 8 and gable_record.window_cut_buffer_address == 9
    assert gable_record.to_bytes() == raw_gable
    assert instances.decode_wooden_gable_flags(6) == {'skew_min_y': True, 'skew_max_y': True}
    skew_record = instances.WoodenGablePlankRecord(
        (0.0,) * 12, flags=6,
        skew_min_y_left_01=0.2, skew_min_y_right_01=0.4,
        skew_max_y_left_01=0.8, skew_max_y_right_01=0.9)
    assert math.isclose(instances.gable_vertex_y(0.0, -0.5, 1.0, skew_record), 0.2, abs_tol=1e-6)
    assert math.isclose(instances.gable_vertex_y(1.0, 0.5, 1.0, skew_record), 0.9, abs_tol=1e-6)
    assert math.isclose(instances.gable_vertex_y(0.5, 0.0, 0.0, skew_record), 0.5, abs_tol=1e-6)
    random_fields = instances.wooden_plank_random_fields(0x1234, 7, 2.0)
    assert random_fields.seed_stone == (0x1234 * 0x10c6f + 7 * 0xf4243 + 0x11) & instances.MASK64
    assert random_fields.seed_surface == (0x1234 * 0xeb3b + 7 * 0x101eb1 + 0x11) & instances.MASK64
    assert random_fields.seed_width == (0x1234 * 0x184b + 7 * 0x14b291 + 0x75) & instances.MASK64
    assert 0.0 <= random_fields.stone_offset <= 0.2
    assert 0.29 <= random_fields.surface_value <= 0.35
    assert random_fields.width_adjusted == instances.f32(
        2.0 - instances.f32(0.05 - random_fields.width_jitter))
    assert result.merlons
    straight = instances.assemble_wall_construction(pieces, wall_tag=0x1234,
                                                     cuts=cuts, horizontal=True)
    assert [p.record_kind for p in straight.placements] == ["straight", "gable"]
    assert [len(p.record) for p in straight.placements] == [80, 96]
    # Repeating the same submission is byte/dictionary deterministic.
    again = instances.assemble_wall_construction(
        pieces, wall_tag=0x1234, cuts=cuts, horizontal=True,
        curved={"circle": (1.0, 0.0, 2.0, 0.3), "circumference": 12.0,
                 "start": 0.0, "end": 3.0}, radial_width=0.2, merlon_mode=1)
    assert result == again
    payload = {
        "exe_sha256": instances.EXE_SHA256,
        "checks": 50,
        "passed": True,
        "placements": [
            {"kind": p.record_kind, "cuts": list(p.cuts),
             "record_bytes": len(p.record),
             "record_sha256": hashlib.sha256(p.record).hexdigest()}
            for p in result.placements
        ],
        "window_results": [
            {"indices": list(row.indices), "packed": row.packed,
             "count": row.count, "old_output_len": row.old_output_len,
             "hash_state": row.hash_state, "call_counter": row.call_counter}
            for row in result.window_results
        ],
        "merlon_count": len(result.merlons),
        "source_cut_count": len(result.source_cuts),
        "unknowns": list(result.unknowns),
    }
    out = HERE.parent / "evidence" / "reconstruction_wall_instances" / "verification-constructor-bridge.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
