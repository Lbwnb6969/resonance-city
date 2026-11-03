"""Recovered Tiny Glade wooden wall instance records and top-rim layout.
Bound to SHA-256 Tiny Glade EXE; all scalar writes are IEEE f32.
"""
import math,struct,dataclasses
from typing import Iterable, Optional
EXE_SHA256='4627ec9f9a8abe03dd30751f6a8e22868e0dfddf9f40029a1b848a3773495fe5'
MASK64=(1<<64)-1
def f32(x): return struct.unpack('<f',struct.pack('<f',x))[0]


def hash_u32(value: int) -> int:
    value = int(value) & 0xffffffff
    value = (value + (value << 10)) & 0xffffffff
    value ^= value >> 6
    value = (value + (value << 3)) & 0xffffffff
    value ^= value >> 11
    value = (value + (value << 15)) & 0xffffffff
    return value & 0xffffffff


def unit_hash(value: int) -> float:
    bits = (hash_u32(value) & 0x007fffff) | 0x3f800000
    return f32(struct.unpack('<f', struct.pack('<I', bits))[0] - 1.0)


def fastrand_f32(seed: int) -> tuple[int, float]:
    """Exact `fastrand::Rng::f32` used by the wall constructor."""
    state = (int(seed) + 0xa0761d6478bd642f) & MASK64
    product = (state ^ 0xe7037ed1a0b428db) * state
    word = ((product >> 64) ^ product) & 0xffffffff
    bits = (word >> 9) | 0x3f800000
    return state, f32(struct.unpack('<f', struct.pack('<I', bits))[0] - 1.0)


@dataclasses.dataclass(frozen=True)
class WoodenPlankRandomFields:
    """Known random stream values observed before plank SSBO writes.

    The native constructor derives these seeds from the per-piece split seed
    and a stable source tag.  The final material/texture routing is still
    caller-specific, so this record does not silently write opaque fields.
    """
    seed_stone: int
    seed_surface: int
    seed_width: int
    stone_offset: float
    surface_value: float
    width_jitter: float
    width_adjusted: float


def wooden_plank_random_fields(source_tag: int, piece_seed: int, width: float) -> WoodenPlankRandomFields:
    """Reproduce the constructor's known seed formulas and scalar transforms.

    Evidence addresses: `0x14144ad01..0x14144ad37`, random calls at
    `0x14144b02c`, `0x14144b08f`, `0x14144b0d0`, and the alternate-width call
    at `0x14144b7da`.
    """
    tag = int(source_tag) & MASK64
    piece = int(piece_seed) & MASK64
    seed_stone = (tag * 0x10c6f + piece * 0xf4243 + 0x11) & MASK64
    seed_surface = (tag * 0xeb3b + piece * 0x101eb1 + 0x11) & MASK64
    seed_width = (tag * 0x184b + piece * 0x14b291 + 0x75) & MASK64
    _, random_stone = fastrand_f32(seed_stone)
    _, random_surface = fastrand_f32(seed_surface)
    _, random_width = fastrand_f32(seed_width)
    stone_offset = f32(random_stone * f32(0.2))
    surface_value = f32(
        f32(random_surface * f32(0.03))
        - f32(f32(1.0 - random_surface) * f32(0.03))
    )
    surface_value = f32(surface_value + f32(0.3199999928474426))
    width_jitter = f32(random_width * f32(0.05))
    width_adjusted = f32(float(width) - f32(f32(1.0 - random_width) * f32(0.05)))
    return WoodenPlankRandomFields(seed_stone, seed_surface, seed_width,
                                   stone_offset, surface_value, width_jitter,
                                   width_adjusted)


def pack_window_cut_list(base: int, count: int) -> int:
    """Bit-exact `roof_buffers::pack_window_cut_list` (0x140a78260)."""
    base = int(base) & 0xffffffff
    count = int(count) & 0xffffffff
    if count == 0 or base >= 0x1000000:
        return 0
    return (min(count, 0xff) << 24) | base
def curved_half_timber(position, base_radius, radial_width, style, start_angle, end_angle, scalar):
    """Reconstruct CurvedHalfTimberInstanceData::new_curved_xy (0x140aaa870).
    Record is 80 bytes: pos xyz/pad, inner/outer radii, angles, seed=0,
    scalar, style, segment exponent [2,5], and 28 bytes zero.
    """
    base_radius=f32(base_radius); radial_width=f32(radial_width)
    w=f32(radial_width*f32(.5)); outer=f32(base_radius+w); inner=f32(base_radius-w)
    seg=f32(f32(f32(abs(f32(f32(end_angle)-f32(start_angle))))*outer)+f32(1.0))
    seg=f32(seg/f32(.6))
    n=max(0,math.ceil(seg)); n+= [0,2,2,4][int(style)]
    if n<2: exp=2
    else: exp=(n-1).bit_length()
    exp=max(2,min(5,exp))
    out=bytearray(80)
    struct.pack_into('<3f',out,0,*map(f32,position)); struct.pack_into('<f',out,12,0)
    struct.pack_into('<4f',out,16,inner,outer,f32(start_angle),f32(end_angle))
    struct.pack_into('<QfIII',out,32,0,f32(scalar),int(style)&255,exp,0)
    return bytes(out)


def _pack_f32(out: bytearray, offset: int, value: float) -> None:
    struct.pack_into('<f', out, offset, f32(value))


def _pack_vec2(out: bytearray, offset: int, value) -> None:
    struct.pack_into('<2f', out, offset, f32(value[0]), f32(value[1]))


def _pack_u32(out: bytearray, offset: int, value: int) -> None:
    struct.pack_into('<I', out, offset, int(value) & 0xffffffff)


def _read_f32(record: bytes, offset: int) -> float:
    return struct.unpack_from('<f', record, offset)[0]


def _read_u32(record: bytes, offset: int) -> int:
    return struct.unpack_from('<I', record, offset)[0]


@dataclasses.dataclass(frozen=True)
class WoodenPlankRecord:
    """Structured 80-byte `WoodenPlank` shader record."""
    transform: tuple
    gate_seed: int = 0
    piece_seed: int = 0
    color_source: int = 0
    flags: int = 0
    window_cut_buffer_address: int = 0
    window_cut_list: int = 0
    pad0: int = 0

    def to_bytes(self) -> bytes:
        if len(self.transform) != 12:
            raise ValueError('WoodenPlank transform must contain 12 floats')
        out = bytearray(80)
        for index, value in enumerate(self.transform):
            _pack_f32(out, index * 4, value)
        _pack_u32(out, 0x30, self.gate_seed)
        _pack_u32(out, 0x34, self.piece_seed)
        _pack_u32(out, 0x38, self.color_source)
        _pack_u32(out, 0x3c, self.flags)
        struct.pack_into('<Q', out, 0x40, int(self.window_cut_buffer_address) & MASK64)
        _pack_u32(out, 0x48, self.window_cut_list)
        _pack_u32(out, 0x4c, self.pad0)
        return bytes(out)

    @classmethod
    def from_bytes(cls, record: bytes) -> 'WoodenPlankRecord':
        if len(record) < 80:
            raise ValueError('WoodenPlank record must be 80 bytes')
        return cls(
            tuple(_read_f32(record, index * 4) for index in range(12)),
            _read_u32(record, 0x30), _read_u32(record, 0x34),
            _read_u32(record, 0x38), _read_u32(record, 0x3c),
            struct.unpack_from('<Q', record, 0x40)[0],
            _read_u32(record, 0x48), _read_u32(record, 0x4c))


@dataclasses.dataclass(frozen=True)
class WoodenGablePlankRecord:
    """Structured 96-byte `WoodenGablePlank` shader record."""
    transform: tuple
    seed: int = 0
    color_source: int = 0
    flags: int = 0
    pad0: int = 0
    skew_min_y_left_01: float = 0.0
    skew_min_y_right_01: float = 0.0
    skew_max_y_left_01: float = 0.0
    skew_max_y_right_01: float = 0.0
    window_cut_buffer_address: int = 0
    window_cut_list: int = 0
    pad1: int = 0

    def to_bytes(self) -> bytes:
        if len(self.transform) != 12:
            raise ValueError('WoodenGablePlank transform must contain 12 floats')
        out = bytearray(96)
        for index, value in enumerate(self.transform):
            _pack_f32(out, index * 4, value)
        _pack_u32(out, 0x30, self.seed)
        _pack_u32(out, 0x34, self.color_source)
        _pack_u32(out, 0x38, self.flags)
        _pack_u32(out, 0x3c, self.pad0)
        for offset, value in ((0x40, self.skew_min_y_left_01),
                              (0x44, self.skew_min_y_right_01),
                              (0x48, self.skew_max_y_left_01),
                              (0x4c, self.skew_max_y_right_01)):
            _pack_f32(out, offset, value)
        struct.pack_into('<Q', out, 0x50, int(self.window_cut_buffer_address) & MASK64)
        _pack_u32(out, 0x58, self.window_cut_list)
        _pack_u32(out, 0x5c, self.pad1)
        return bytes(out)

    @classmethod
    def from_bytes(cls, record: bytes) -> 'WoodenGablePlankRecord':
        if len(record) < 96:
            raise ValueError('WoodenGablePlank record must be 96 bytes')
        return cls(
            tuple(_read_f32(record, index * 4) for index in range(12)),
            _read_u32(record, 0x30), _read_u32(record, 0x34),
            _read_u32(record, 0x38), _read_u32(record, 0x3c),
            _read_f32(record, 0x40), _read_f32(record, 0x44),
            _read_f32(record, 0x48), _read_f32(record, 0x4c),
            struct.unpack_from('<Q', record, 0x50)[0],
            _read_u32(record, 0x58), _read_u32(record, 0x5c))


def decode_wooden_plank_flags(flags: int) -> dict:
    """Decode the flag outputs exposed by `nani_wooden_plank` vertex shader."""
    flags = int(flags) & 0xffffffff
    return {
        'default_wood_color': bool(flags & 2),
        'is_less_snowy': bool(flags & 4),
        'no_highlight': bool(flags & 8),
        'source_is_color_id': bool(flags & 16),
        'is_freeform_wall': bool(flags & 32),
        'curved_end_a': bool(flags & 64),
        'curved_end_b': bool(flags & 128),
        'no_snow': bool(flags & 256),
    }


def decode_wooden_gable_flags(flags: int) -> dict:
    """Decode gable skew gates from `nani_wooden_gable_plank`."""
    flags = int(flags) & 0xffffffff
    return {'skew_min_y': bool(flags & 2), 'skew_max_y': bool(flags & 4)}


def gable_vertex_y(
    vertex_y: float,
    vertex_x: float,
    transform_y_scale: float,
    record: WoodenGablePlankRecord,
) -> float:
    """Reproduce `nani_wooden_gable_plank` normalized Y deformation."""
    y = f32(vertex_y)
    scale = f32(transform_y_scale)
    if scale <= f32(1.0e-4):
        remapped = y
    else:
        edge = min(f32(0.16), min(f32(0.08) / scale, f32(0.45)))
        if y < f32(0.16):
            remapped = f32((y * edge) * f32(6.25))
        elif y > f32(0.8400000333786011):
            remapped = f32(1.0 - (((f32(1.0) - y) * edge) * f32(6.25)))
        else:
            remapped = f32(edge + (((y - f32(0.16)) * f32(1.4705880880355835))
                                   * (f32(1.0) - f32(2.0) * edge)))
    u = max(0.0, min(1.0, f32(vertex_x) + f32(0.5)))
    flags = int(record.flags) & 0xffffffff
    if flags & 2:
        minimum = f32(record.skew_min_y_left_01
                      + (record.skew_min_y_right_01 - record.skew_min_y_left_01) * u)
        remapped = max(remapped, minimum)
    if flags & 4:
        maximum = f32(record.skew_max_y_left_01
                      + (record.skew_max_y_right_01 - record.skew_max_y_left_01) * u)
        remapped = min(remapped, maximum)
    return f32(remapped)


def wooden_shader_seed(record: WoodenPlankRecord | WoodenGablePlankRecord) -> int:
    """Vertex shader seed: `(gate_seed + piece_seed) + 45`, or `seed + 45`."""
    if isinstance(record, WoodenPlankRecord):
        return (int(record.gate_seed) + int(record.piece_seed) + 45) & 0xffffffff
    return (int(record.seed) + 45) & 0xffffffff


def wooden_shader_uv_jitter(record: WoodenPlankRecord | WoodenGablePlankRecord) -> tuple[float, float]:
    """The two deterministic UV jitter values used by both plank shaders."""
    seed = wooden_shader_seed(record)
    return (unit_hash(seed ^ 2340774), unit_hash(seed ^ 934565))


def pack_wooden_plank_fields(fields: Optional[dict] = None) -> bytes:
    """Pack raw 80-byte WoodenPlankSsbo offsets observed in the constructor."""
    fields = fields or {}
    out = bytearray(80)
    _pack_vec2(out, 0x00, fields.get('vec2_00', (0.0, 0.0)))
    for off in (0x08, 0x0c, 0x10, 0x14, 0x18, 0x1c, 0x20, 0x2c):
        _pack_f32(out, off, fields.get(f'f{off:02x}', 0.0))
    _pack_vec2(out, 0x24, fields.get('vec2_24', (0.0, 0.0)))
    for off in (0x30, 0x34, 0x38, 0x3c, 0x48, 0x4c):
        _pack_u32(out, off, fields.get(f'u32_{off:02x}', 0))
    struct.pack_into('<Q', out, 0x40, int(fields.get('u64_40', 0)) & 0xffffffffffffffff)
    return bytes(out)


def pack_wooden_gable_plank_fields(fields: Optional[dict] = None) -> bytes:
    """Pack raw 96-byte WoodenGablePlankSsbo offsets observed in the constructor."""
    fields = fields or {}
    out = bytearray(96)
    _pack_vec2(out, 0x00, fields.get('vec2_00', (0.0, 0.0)))
    for off in (0x08, 0x0c, 0x10, 0x14, 0x20, 0x2c):
        _pack_f32(out, off, fields.get(f'f{off:02x}', 0.0))
    _pack_vec2(out, 0x18, fields.get('vec2_18', (0.0, 0.0)))
    _pack_vec2(out, 0x24, fields.get('vec2_24', (0.0, 0.0)))
    for off in (0x30, 0x34, 0x38, 0x3c, 0x58, 0x5c):
        _pack_u32(out, off, fields.get(f'u32_{off:02x}', 0))
    _pack_u32(out, 0x40, fields.get('u32_40', 0))
    _pack_u32(out, 0x44, fields.get('u32_44', 0))
    struct.pack_into('<Q', out, 0x50, int(fields.get('u64_50', 0)) & 0xffffffffffffffff)
    return bytes(out)


def wooden_plank_default():
    return pack_wooden_plank_fields({'f00': 1.0, 'f10': 1.0, 'f20': 1.0, 'u32_3c': 1})
def wooden_gable_plank_default():
    out = bytearray(pack_wooden_gable_plank_fields({'f00': 1.0, 'f10': 1.0, 'f20': 1.0, 'u32_38': 1}))
    struct.pack_into('<2f', out, 72, 1.0, 1.0)
    return bytes(out)


def curved_with_seed(record: bytes, seed: int) -> bytes:
    """Native `with_seed` helper: writes u32 at record offset 0x34."""
    out = bytearray(record)
    struct.pack_into('<I', out, 52, int(seed) & 0xffffffff)
    return bytes(out)


def curved_with_flags(record: bytes, flags: int) -> bytes:
    """Native `with_flags` helper: ORs u32 into record offset 0x38."""
    out = bytearray(record)
    current = struct.unpack_from('<I', out, 56)[0]
    struct.pack_into('<I', out, 56, current | (int(flags) & 0xffffffff))
    return bytes(out)


def curved_with_window_cut_list(record: bytes, packed_list: int) -> bytes:
    """Native `with_window_cut_list` helper: writes u32 at offset 0x48."""
    out = bytearray(record)
    struct.pack_into('<I', out, 72, int(packed_list) & 0xffffffff)
    return bytes(out)
def top_rim_merlon_ranges(start,end,mode):
    """0x1414851c0: mode 0 regular, mode 1 alternating with fixed end."""
    start,end=f32(start),f32(end); span=f32(end-start)
    if span<=0:return []
    round_positive=lambda x: int(math.floor(x+.5))
    if mode==0:
        count=max(1,round_positive(f32(span/f32(1.9999998807907104))))
        step=f32(span/f32(count)); width=f32(step*f32(.5)); stride=1
    else:
        count=max(2,round_positive(f32(f32(f32(span/f32(.9999999403953552))+f32(1.0))*f32(.5))))
        step=f32(span/f32(count*2-1)); width=step; stride=2
    result=[]
    for i in range(count):
        off=f32(f32(i)*step)
        if mode:off=f32(off+off)
        lo=f32(off+start); hi=end if mode and i==count-1 else f32(lo+width)
        if f32(hi-lo)>=f32(.05):result.append((lo,hi))
    return result
@dataclasses.dataclass(frozen=True)
class InstanceLayout:
    plank_stride:int=80; gable_stride:int=96; curved_stride:int=80


@dataclasses.dataclass(frozen=True)
class WallCut:
    """Wall-space opening carried into one constructor submission."""
    x0: float
    y0: float
    x1: float
    y1: float
    kind: str = "window"

    def normalized(self) -> "WallCut":
        a, b, c, d = map(f32, (self.x0, self.y0, self.x1, self.y1))
        return WallCut(min(a, c), min(b, d), max(a, c), max(b, d), str(self.kind))


@dataclasses.dataclass(frozen=True)
class WallBoardPlacement:
    """Planner piece plus known instance bytes and source cut references."""
    piece: object
    orientation: str
    record_kind: str
    cuts: tuple
    record: bytes


@dataclasses.dataclass(frozen=True)
class WallConstruction:
    """Deterministic planner-to-instance handoff with explicit unknowns."""
    wall_tag: int
    placements: tuple
    merlons: tuple
    source_cuts: tuple
    window_results: tuple = ()
    unknowns: tuple = ("native material selection and final random-field routing",)


@dataclasses.dataclass
class WindowCutLists:
    """Semantic reconstruction of WindowCutLists::list_for_piece.

    Native evidence shows a linear scan of 16-byte Aabb2 records, a direct
    intersection test, and a second test against the record translated by the
    stored scalar at +0x40.  The native packed-list/hash return value is kept
    outside this class because its roof-buffer encoder is a separate ABI.
    """
    records: tuple
    translated_scalar: float = 0.0
    output_base: int = 0
    output_indices: list = dataclasses.field(default_factory=list)
    hash_state: int = 0
    call_counter: int = 0

    def list_for_piece(self, piece: object) -> tuple:
        rect = tuple(map(f32, piece.rectangle if hasattr(piece, "rectangle") else piece))
        if len(rect) != 4:
            raise ValueError("piece AABB must contain four values")
        result = []
        shift = f32(self.translated_scalar)
        for index, raw in enumerate(self.records):
            cut = tuple(map(f32, raw[:4]))
            if _aabb_intersects(cut, rect):
                result.append(index)
                continue
            shifted = tuple(f32(value + shift) for value in cut)
            if _aabb_intersects(shifted, rect):
                result.append(index)
        return tuple(result)

    def packed_for_piece(self, piece: object, output_base: int = 0) -> tuple:
        indices = self.list_for_piece(piece)
        return indices, pack_window_cut_list(output_base + (indices[0] if indices else 0), len(indices))

    def native_result_for_piece(self, piece: object) -> "WindowCutResult":
        """Mirror the native mutable return ABI of `list_for_piece`.

        Native layout facts from `0x1424bd0e0`: each selected source index is
        appended to an internal `u32` vector, EDX returns the number appended,
        and EAX packs `output_base + old_output_len` with that count.  The
        non-empty path updates the 64-bit state at +0x38 with the exact two
        SplitMix-style multiplications below, then increments the u32 counter
        at +0x44.  This method preserves those mutations across calls.
        """
        indices = self.list_for_piece(piece)
        old_output_len = len(self.output_indices)
        self.output_indices.extend(int(index) & 0xffffffff for index in indices)
        count = len(indices)
        if count:
            mixed = ((int(self.call_counter) & 0xffffffff) << 32) | (count & 0xffffffff)
            mixed ^= mixed >> 30
            mixed = (mixed * 0xbf58476d1ce4e5b9) & MASK64
            mixed ^= mixed >> 27
            mixed = (mixed * 0x94d049bb133111eb) & MASK64
            self.hash_state = (mixed ^ (mixed >> 31) ^ (int(self.hash_state) & MASK64)) & MASK64
        self.call_counter = (int(self.call_counter) + 1) & 0xffffffff
        packed = pack_window_cut_list(int(self.output_base) + old_output_len, count)
        return WindowCutResult(tuple(indices), packed, count,
                               old_output_len, self.hash_state, self.call_counter)


@dataclasses.dataclass(frozen=True)
class WindowCutResult:
    indices: tuple
    packed: int
    count: int
    old_output_len: int
    hash_state: int
    call_counter: int


def _aabb_intersects(a: tuple, b: tuple) -> bool:
    return a[0] <= b[2] and b[0] <= a[2] and a[1] <= b[3] and b[1] <= a[3]


def _cut_overlaps_piece(cut: WallCut, piece: object) -> bool:
    rect = tuple(map(float, piece.rectangle))
    c = cut.normalized()
    return c.x0 < rect[2] and rect[0] < c.x1 and c.y0 < rect[3] and rect[1] < c.y1


def assemble_wall_construction(
    pieces: Iterable[object], *, wall_tag: int = 0,
    cuts: Iterable[WallCut] = (), horizontal: bool = True,
    curved: Optional[dict] = None, radial_width: float = 0.2,
    merlon_mode: Optional[int] = None,
) -> WallConstruction:
    """Bridge verified planner pieces into one wall construction submission.

    Straight/gable records use only the verified default layouts.  A supplied
    curved descriptor additionally emits the bit-exact stage-3 curved record;
    opaque material/random fields remain explicit in ``unknowns``.
    """
    normalized_cuts = tuple(c.normalized() for c in cuts)
    cut_lists = WindowCutLists(tuple((c.x0, c.y0, c.x1, c.y1) for c in normalized_cuts))
    placements = []
    window_results = []
    for index, piece in enumerate(pieces):
        rect = tuple(map(f32, piece.rectangle))
        native_cut_result = cut_lists.native_result_for_piece(piece)
        overlaps = native_cut_result.indices
        window_results.append(native_cut_result)
        packed_cuts = native_cut_result.packed
        if curved is not None and horizontal:
            record = emit_curved_horizontal_wall_board_piece(
                wall_tag, index, curved["circle"], curved["circumference"],
                rect[0], rect[2], rect[1], rect[3] - rect[1], radial_width,
                window_cut_list=packed_cuts,
                window_count=len(overlaps)) or b""
            kind, orientation = "curved_horizontal", "horizontal"
        elif int(getattr(piece, "flag2", 0)):
            record = wooden_gable_plank_default()
            kind, orientation = "gable", "horizontal" if horizontal else "vertical"
        else:
            record = wooden_plank_default()
            kind, orientation = "straight", "horizontal" if horizontal else "vertical"
        placements.append(WallBoardPlacement(piece, orientation, kind, overlaps, record))
    merlons = ()
    if merlon_mode is not None and curved is not None:
        merlons = tuple(top_rim_merlon_ranges(
            f32(curved.get("start", 0.0)),
            f32(curved.get("end", curved["circumference"])), int(merlon_mode)))
    return WallConstruction(int(wall_tag) & 0xffffffff, tuple(placements),
                            tuple(merlons), normalized_cuts, tuple(window_results))


def rectangle_gable_wallspace_ranges(rectangle, expanded_length, gable_sides=()):
    """0x141489790: selected sides mapped to absolute perimeter distance."""
    import recovered_wall_stairs as r
    length=f32(expanded_length)
    return [(f32(r.rectangle_point_u(*rectangle.dimensions,i)*length),
             f32(r.rectangle_point_u(*rectangle.dimensions,i+1)*length)) for i in gable_sides]

def plan_rectangle_wallspace_regions(rectangle, expanded_length, bottom_y, top_y,
                                     wall_max_y, gable_sides=(), separate_gables=False):
    """0x141489480: produce side-tagged regions before board subdivision.
    rectangle=None is generic freeform region. bottom_y is resolved foundation
    top or wall bottom (foundation resolution is a separate public-state helper).
    """
    import recovered_wall_planners as p
    import recovered_wall_stairs as r
    bottom_y,top_y,wall_max_y=map(f32,(bottom_y,top_y,wall_max_y))
    if rectangle is None:
        return [p.Piece((0.0,bottom_y,f32(expanded_length),top_y))] if top_y>f32(bottom_y+f32(.05)) else []
    length=f32(expanded_length); result=[]
    for i in range(4):
        lo=f32(r.rectangle_point_u(*rectangle.dimensions,i)*length)
        hi=f32(r.rectangle_point_u(*rectangle.dimensions,i+1)*length)
        split=separate_gables and i in gable_sides and top_y>wall_max_y
        cap=wall_max_y if split else top_y
        if cap>f32(bottom_y+f32(.05)):result.append(p.Piece((lo,bottom_y,hi,cap),1,i,0))
        if split:result.append(p.Piece((lo,max(bottom_y,wall_max_y),hi,top_y),1,i,1))
    return result

def emit_curved_horizontal_wall_board_piece(wall_tag,piece_index,circle,
        circumference,start,end,bottom,height,radial_width,window_cut_list=0,window_count=0):
    """0x1414530c0: exact curved SSBO assembly; explicit window provider output.
    circle=(center_x,center_z,base_radius,angle_offset). Heights below .05 and
    circumference <= .01 emit no record. Provider returns packed list and count.
    """
    circumference,start,end,bottom,height,radial_width=map(f32,(circumference,start,end,bottom,height,radial_width))
    if circumference<=f32(.01) or height<f32(.05):return None
    circle=tuple(map(f32,circle));tau=f32(6.2831854820251465)
    wrap=lambda value,period: f32(f32(math.fmod(value,period))+period) if math.fmod(value,period)<0 else f32(math.fmod(value,period))
    a=f32(wrap(f32(start/circumference),f32(1))*circumference)
    b=f32(wrap(f32(end/circumference),f32(1))*circumference)
    offset=wrap(circle[3],tau);scale=f32(tau/circumference)
    angle_a=f32(f32(scale*a)-offset);angle_b=f32(f32(scale*b)-offset)
    if not angle_a<angle_b:angle_b=f32(angle_b+tau)
    out=bytearray(curved_half_timber((circle[0],bottom,circle[1]),circle[2],radial_width,3,angle_a,angle_b,height))
    out = curved_with_seed(bytes(out), (wall_tag ^ piece_index) + window_count * 10)
    out = curved_with_flags(out, 2)
    return curved_with_window_cut_list(out, window_cut_list)
