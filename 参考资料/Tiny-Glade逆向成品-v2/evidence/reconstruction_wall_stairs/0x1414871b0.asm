00000001414871b0  56                       push     rsi
00000001414871b1  57                       push     rdi
00000001414871b2  4881ecc8000000           sub      rsp, 0xc8
00000001414871b9  440f299c24b0000000       movaps   xmmword ptr [rsp + 0xb0], xmm11
00000001414871c2  440f299424a0000000       movaps   xmmword ptr [rsp + 0xa0], xmm10
00000001414871cb  440f298c2490000000       movaps   xmmword ptr [rsp + 0x90], xmm9
00000001414871d4  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
00000001414871dd  0f297c2470               movaps   xmmword ptr [rsp + 0x70], xmm7
00000001414871e2  0f29742460               movaps   xmmword ptr [rsp + 0x60], xmm6
00000001414871e7  440f28c2                 movaps   xmm8, xmm2
00000001414871eb  4889d6                   mov      rsi, rdx
00000001414871ee  4889cf                   mov      rdi, rcx
00000001414871f1  f30f1032                 movss    xmm6, dword ptr [rdx]
00000001414871f5  f3440f105a04             movss    xmm11, dword ptr [rdx + 4]
00000001414871fb  f30f107a08               movss    xmm7, dword ptr [rdx + 8]
0000000141487200  f3440f10520c             movss    xmm10, dword ptr [rdx + 0xc]
0000000141487206  488d4c2420               lea      rcx, [rsp + 0x20]
000000014148720b  4889fa                   mov      rdx, rdi
000000014148720e  0f28d6                   movaps   xmm2, xmm6
0000000141487211  e87abeffff               call     0x141483090 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSampler::sample_pair_at | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards11WallSampler14sample_pair_at17h3845de2e9feb8b12E.llvm.1951817906911489466
0000000141487216  807c242000               cmp      byte ptr [rsp + 0x20], 0
000000014148721b  744d                     je       0x14148726a
000000014148721d  f30f1044244c             movss    xmm0, dword ptr [rsp + 0x4c]
0000000141487223  f30f1015fdfc9a01         movss    xmm2, dword ptr [rip + 0x19afcfd]
000000014148722b  f30f5cd0                 subss    xmm2, xmm0
000000014148722f  f30f105c2430             movss    xmm3, dword ptr [rsp + 0x30]
0000000141487235  f30f59da                 mulss    xmm3, xmm2
0000000141487239  f30f104c2444             movss    xmm1, dword ptr [rsp + 0x44]
000000014148723f  f30f59c8                 mulss    xmm1, xmm0
0000000141487243  f30f59542434             mulss    xmm2, dword ptr [rsp + 0x34]
0000000141487249  f30f59442448             mulss    xmm0, dword ptr [rsp + 0x48]
000000014148724f  f30f58cb                 addss    xmm1, xmm3
0000000141487253  f30f58c2                 addss    xmm0, xmm2
0000000141487257  f30f580d75089b01         addss    xmm1, dword ptr [rip + 0x19b0875]
000000014148725f  410f2ecb                 ucomiss  xmm1, xmm11
0000000141487263  721f                     jb       0x141487284
0000000141487265  e924020000               jmp      0x14148748e
000000014148726a  f30f100d62089b01         movss    xmm1, dword ptr [rip + 0x19b0862]
0000000141487272  f30f1005aefc9a01         movss    xmm0, dword ptr [rip + 0x19afcae]
000000014148727a  410f2ecb                 ucomiss  xmm1, xmm11
000000014148727e  0f830a020000             jae      0x14148748e
0000000141487284  410f28c8                 movaps   xmm1, xmm8
0000000141487288  f30f5dc8                 minss    xmm1, xmm0
000000014148728c  f30fc2c003               cmpunordss xmm0, xmm0
0000000141487291  0f28d0                   movaps   xmm2, xmm0
0000000141487294  410f54d0                 andps    xmm2, xmm8
0000000141487298  0f55c1                   andnps   xmm0, xmm1
000000014148729b  0f56c2                   orps     xmm0, xmm2
000000014148729e  f30f58050212ae01         addss    xmm0, dword ptr [rip + 0x1ae1202]
00000001414872a6  440f2ed0                 ucomiss  xmm10, xmm0
00000001414872aa  0f83de010000             jae      0x14148748e
00000001414872b0  440f28ce                 movaps   xmm9, xmm6
00000001414872b4  f3440f58cf               addss    xmm9, xmm7
00000001414872b9  f3440f590d8efc9a01       mulss    xmm9, dword ptr [rip + 0x19afc8e]
00000001414872c2  488d4c2420               lea      rcx, [rsp + 0x20]
00000001414872c7  4889fa                   mov      rdx, rdi
00000001414872ca  410f28d1                 movaps   xmm2, xmm9
00000001414872ce  e8bdbdffff               call     0x141483090 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSampler::sample_pair_at | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards11WallSampler14sample_pair_at17h3845de2e9feb8b12E.llvm.1951817906911489466
00000001414872d3  807c242000               cmp      byte ptr [rsp + 0x20], 0
00000001414872d8  744d                     je       0x141487327
00000001414872da  f30f1044244c             movss    xmm0, dword ptr [rsp + 0x4c]
00000001414872e0  f30f101540fc9a01         movss    xmm2, dword ptr [rip + 0x19afc40]
00000001414872e8  f30f5cd0                 subss    xmm2, xmm0
00000001414872ec  f30f105c2430             movss    xmm3, dword ptr [rsp + 0x30]
00000001414872f2  f30f59da                 mulss    xmm3, xmm2
00000001414872f6  f30f104c2444             movss    xmm1, dword ptr [rsp + 0x44]
00000001414872fc  f30f59c8                 mulss    xmm1, xmm0
0000000141487300  f30f59542434             mulss    xmm2, dword ptr [rsp + 0x34]
0000000141487306  f30f59442448             mulss    xmm0, dword ptr [rsp + 0x48]
000000014148730c  f30f58cb                 addss    xmm1, xmm3
0000000141487310  f30f58c2                 addss    xmm0, xmm2
0000000141487314  f30f580db8079b01         addss    xmm1, dword ptr [rip + 0x19b07b8]
000000014148731c  410f2ecb                 ucomiss  xmm1, xmm11
0000000141487320  721f                     jb       0x141487341
0000000141487322  e967010000               jmp      0x14148748e
0000000141487327  f30f100da5079b01         movss    xmm1, dword ptr [rip + 0x19b07a5]
000000014148732f  f30f1005f1fb9a01         movss    xmm0, dword ptr [rip + 0x19afbf1]
0000000141487337  410f2ecb                 ucomiss  xmm1, xmm11
000000014148733b  0f834d010000             jae      0x14148748e
0000000141487341  410f28c8                 movaps   xmm1, xmm8
0000000141487345  f30f5dc8                 minss    xmm1, xmm0
0000000141487349  f30fc2c003               cmpunordss xmm0, xmm0
000000014148734e  0f28d0                   movaps   xmm2, xmm0
0000000141487351  410f54d0                 andps    xmm2, xmm8
0000000141487355  0f55c1                   andnps   xmm0, xmm1
0000000141487358  0f56c2                   orps     xmm0, xmm2
000000014148735b  f30f58054511ae01         addss    xmm0, dword ptr [rip + 0x1ae1145]
0000000141487363  440f2ed0                 ucomiss  xmm10, xmm0
0000000141487367  0f8321010000             jae      0x14148748e
000000014148736d  488d4c2420               lea      rcx, [rsp + 0x20]
0000000141487372  4889fa                   mov      rdx, rdi
0000000141487375  0f28d7                   movaps   xmm2, xmm7
0000000141487378  e813bdffff               call     0x141483090 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSampler::sample_pair_at | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards11WallSampler14sample_pair_at17h3845de2e9feb8b12E.llvm.1951817906911489466
000000014148737d  807c242000               cmp      byte ptr [rsp + 0x20], 0
0000000141487382  744e                     je       0x1414873d2
0000000141487384  f30f1044244c             movss    xmm0, dword ptr [rsp + 0x4c]
000000014148738a  f30f101596fb9a01         movss    xmm2, dword ptr [rip + 0x19afb96]
0000000141487392  f30f5cd0                 subss    xmm2, xmm0
0000000141487396  f30f105c2430             movss    xmm3, dword ptr [rsp + 0x30]
000000014148739c  f30f59da                 mulss    xmm3, xmm2
00000001414873a0  f30f104c2444             movss    xmm1, dword ptr [rsp + 0x44]
00000001414873a6  f30f59c8                 mulss    xmm1, xmm0
00000001414873aa  f30f59542434             mulss    xmm2, dword ptr [rsp + 0x34]
00000001414873b0  f30f59442448             mulss    xmm0, dword ptr [rsp + 0x48]
00000001414873b6  f30f58cb                 addss    xmm1, xmm3
00000001414873ba  f30f58c2                 addss    xmm0, xmm2
00000001414873be  f30f580d0e079b01         addss    xmm1, dword ptr [rip + 0x19b070e]
00000001414873c6  410f2ecb                 ucomiss  xmm1, xmm11
00000001414873ca  0f83be000000             jae      0x14148748e
00000001414873d0  eb1a                     jmp      0x1414873ec
00000001414873d2  f30f100dfa069b01         movss    xmm1, dword ptr [rip + 0x19b06fa]
00000001414873da  f30f100546fb9a01         movss    xmm0, dword ptr [rip + 0x19afb46]
00000001414873e2  410f2ecb                 ucomiss  xmm1, xmm11
00000001414873e6  0f83a2000000             jae      0x14148748e
00000001414873ec  0f28c8                   movaps   xmm1, xmm0
00000001414873ef  f30fc2c803               cmpunordss xmm1, xmm0
00000001414873f4  0f28d1                   movaps   xmm2, xmm1
00000001414873f7  410f54d0                 andps    xmm2, xmm8
00000001414873fb  f3440f5dc0               minss    xmm8, xmm0
0000000141487400  410f55c8                 andnps   xmm1, xmm8
0000000141487404  0f56ca                   orps     xmm1, xmm2
0000000141487407  f30f580d9910ae01         addss    xmm1, dword ptr [rip + 0x1ae1099]
000000014148740f  440f2ed1                 ucomiss  xmm10, xmm1
0000000141487413  7379                     jae      0x14148748e
0000000141487415  48c744243003000000       mov      qword ptr [rsp + 0x30], 3
000000014148741e  f30f11742438             movss    dword ptr [rsp + 0x38], xmm6
0000000141487424  f3440f114c243c           movss    dword ptr [rsp + 0x3c], xmm9
000000014148742b  f30f117c2440             movss    dword ptr [rsp + 0x40], xmm7
0000000141487431  48897c2420               mov      qword ptr [rsp + 0x20], rdi
0000000141487436  48c744242801000000       mov      qword ptr [rsp + 0x28], 1
000000014148743f  f30f1015f95db801         movss    xmm2, dword ptr [rip + 0x1b85df9]
0000000141487447  f30f58d6                 addss    xmm2, xmm6
000000014148744b  f30f5835f5039b01         addss    xmm6, dword ptr [rip + 0x19b03f5]
0000000141487453  488d4c2454               lea      rcx, [rsp + 0x54]
0000000141487458  4889fa                   mov      rdx, rdi
000000014148745b  0f28de                   movaps   xmm3, xmm6
000000014148745e  e8bdbeffff               call     0x141483320 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSampler::tangent_between | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards11WallSampler15tangent_between17h94037a3038e25e59E
0000000141487463  f30f10442454             movss    xmm0, dword ptr [rsp + 0x54]
0000000141487469  f30f104c245c             movss    xmm1, dword ptr [rsp + 0x5c]
000000014148746f  f30f11442454             movss    dword ptr [rsp + 0x54], xmm0
0000000141487475  f30f114c2458             movss    dword ptr [rsp + 0x58], xmm1
000000014148747b  488d4c2420               lea      rcx, [rsp + 0x20]
0000000141487480  488d542454               lea      rdx, [rsp + 0x54]
0000000141487485  e8c6a5f9ff               call     0x141421a50 ; _ZN102_$LT$core..iter..adapters..map..Map$LT$I$C$F$GT$$u20$as$u20$core..iter..traits..iterator..Iterator$GT$8try_fold17ha1aa4ba32826026bE | core::iter::adapters::map::impl$2::try_fold<glam::f32::vec2::Vec2,core::array::iter::IntoIter<f32,3>,system_wall_constructor::construct_wooden_walls::construct_wall_boards::region_is_straightish::closure_env$0,tuple$<>,core::iter::traits::iterator::Iterator::all::check::closure_env$0<glam::f32::vec2::Vec2,system_wall_constructor::construct_wooden_walls::construct_wall_boards::region_is_straightish::closure_env$1>,enum2$<core::ops::control_flow::ControlFlow<tuple$<>,tuple$<> > > >
000000014148748a  84c0                     test     al, al
000000014148748c  743a                     je       0x1414874c8
000000014148748e  31c0                     xor      eax, eax
0000000141487490  0f28742460               movaps   xmm6, xmmword ptr [rsp + 0x60]
0000000141487495  0f287c2470               movaps   xmm7, xmmword ptr [rsp + 0x70]
000000014148749a  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
00000001414874a3  440f288c2490000000       movaps   xmm9, xmmword ptr [rsp + 0x90]
00000001414874ac  440f289424a0000000       movaps   xmm10, xmmword ptr [rsp + 0xa0]
00000001414874b5  440f289c24b0000000       movaps   xmm11, xmmword ptr [rsp + 0xb0]
00000001414874be  4881c4c8000000           add      rsp, 0xc8
00000001414874c5  5f                       pop      rdi
00000001414874c6  5e                       pop      rsi
00000001414874c7  c3                       ret      
00000001414874c8  4889f1                   mov      rcx, rsi
00000001414874cb  e8407796ff               call     0x140deec10 ; utils::geometry::aabb::Aabb2::width | _ZN5utils8geometry4aabb5Aabb25width17he30e90b5e741e6fbE
00000001414874d0  0f28f0                   movaps   xmm6, xmm0
00000001414874d3  4889f1                   mov      rcx, rsi
00000001414874d6  e8757796ff               call     0x140deec50 ; utils::geometry::aabb::Aabb2::height | _ZN5utils8geometry4aabb5Aabb26height17h160a2c40e4ab2359E
00000001414874db  f30f5ef0                 divss    xmm6, xmm0
00000001414874df  0f2e356afa9a01           ucomiss  xmm6, dword ptr [rip + 0x19afa6a]
00000001414874e6  0f97c0                   seta     al
00000001414874e9  eba5                     jmp      0x141487490