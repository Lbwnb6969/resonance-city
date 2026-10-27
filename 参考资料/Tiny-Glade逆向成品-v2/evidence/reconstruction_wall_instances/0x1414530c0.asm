00000001414530c0  4157                     push     r15
00000001414530c2  4156                     push     r14
00000001414530c4  56                       push     rsi
00000001414530c5  57                       push     rdi
00000001414530c6  55                       push     rbp
00000001414530c7  53                       push     rbx
00000001414530c8  4881ecc8010000           sub      rsp, 0x1c8
00000001414530cf  440f29ac24b0010000       movaps   xmmword ptr [rsp + 0x1b0], xmm13
00000001414530d8  440f29a424a0010000       movaps   xmmword ptr [rsp + 0x1a0], xmm12
00000001414530e1  440f299c2490010000       movaps   xmmword ptr [rsp + 0x190], xmm11
00000001414530ea  440f29942480010000       movaps   xmmword ptr [rsp + 0x180], xmm10
00000001414530f3  440f298c2470010000       movaps   xmmword ptr [rsp + 0x170], xmm9
00000001414530fc  440f29842460010000       movaps   xmmword ptr [rsp + 0x160], xmm8
0000000141453105  0f29bc2450010000         movaps   xmmword ptr [rsp + 0x150], xmm7
000000014145310d  0f29b42440010000         movaps   xmmword ptr [rsp + 0x140], xmm6
0000000141453115  48894c2448               mov      qword ptr [rsp + 0x48], rcx
000000014145311a  f30f100526479e01         movss    xmm0, dword ptr [rip + 0x19e4726]
0000000141453122  0f2ec3                   ucomiss  xmm0, xmm3
0000000141453125  0f8370020000             jae      0x14145339b
000000014145312b  f3440f109c2438020000     movss    xmm11, dword ptr [rsp + 0x238]
0000000141453135  f30f100597499e01         movss    xmm0, dword ptr [rip + 0x19e4997]
000000014145313d  410f2ec3                 ucomiss  xmm0, xmm11
0000000141453141  0f8754020000             ja       0x14145339b
0000000141453147  f30f10842420020000       movss    xmm0, dword ptr [rsp + 0x220]
0000000141453150  f30f5ec3                 divss    xmm0, xmm3
0000000141453154  0f2ec0                   ucomiss  xmm0, xmm0
0000000141453157  0f8a94020000             jp       0x1414533f1
000000014145315d  f3440f10842428020000     movss    xmm8, dword ptr [rsp + 0x228]
0000000141453167  f3440f5ec3               divss    xmm8, xmm3
000000014145316c  450f2ec0                 ucomiss  xmm8, xmm8
0000000141453170  0f8a7b020000             jp       0x1414533f1
0000000141453176  4c89c3                   mov      rbx, r8
0000000141453179  4889d7                   mov      rdi, rdx
000000014145317c  488bb42450020000         mov      rsi, qword ptr [rsp + 0x250]
0000000141453184  4c8bb42448020000         mov      r14, qword ptr [rsp + 0x248]
000000014145318c  f30f10b42440020000       movss    xmm6, dword ptr [rsp + 0x240]
0000000141453195  f30f10bc2430020000       movss    xmm7, dword ptr [rsp + 0x230]
000000014145319e  f3440f102d254ab001       movss    xmm13, dword ptr [rip + 0x1b04a25]
00000001414531a7  f3440f5eeb               divss    xmm13, xmm3
00000001414531ac  f3440f100d733d9e01       movss    xmm9, dword ptr [rip + 0x19e3d73]
00000001414531b5  410f28c9                 movaps   xmm1, xmm9
00000001414531b9  440f28e3                 movaps   xmm12, xmm3
00000001414531bd  e8aef89d01               call     0x142e32a70 ; fmodf
00000001414531c2  440f28d0                 movaps   xmm10, xmm0
00000001414531c6  410f28c0                 movaps   xmm0, xmm8
00000001414531ca  410f28c9                 movaps   xmm1, xmm9
00000001414531ce  e89df89d01               call     0x142e32a70 ; fmodf
00000001414531d3  410f14c2                 unpcklps xmm0, xmm10
00000001414531d7  0f57c9                   xorps    xmm1, xmm1
00000001414531da  0f28d0                   movaps   xmm2, xmm0
00000001414531dd  0fc2d101                 cmpltps  xmm2, xmm1
00000001414531e1  0f28ca                   movaps   xmm1, xmm2
00000001414531e4  0f55c8                   andnps   xmm1, xmm0
00000001414531e7  0f580562479e01           addps    xmm0, xmmword ptr [rip + 0x19e4762]
00000001414531ee  0f54c2                   andps    xmm0, xmm2
00000001414531f1  0f56c1                   orps     xmm0, xmm1
00000001414531f4  f3450f12d4               movsldup xmm10, xmm12
00000001414531f9  440f59d0                 mulps    xmm10, xmm0
00000001414531fd  f3450f16ca               movshdup xmm9, xmm10
0000000141453202  4c8d7b0c                 lea      r15, [rbx + 0xc]
0000000141453206  4c89f9                   mov      rcx, r15
0000000141453209  e822d27e00               call     0x141c40430 ; utils::circular_f32::CircularF32::as_f32 | _ZN5utils12circular_f3211CircularF326as_f3217hdf249fd86cbb61c0E
000000014145320e  440f28c0                 movaps   xmm8, xmm0
0000000141453212  4c89f9                   mov      rcx, r15
0000000141453215  e816d27e00               call     0x141c40430 ; utils::circular_f32::CircularF32::as_f32 | _ZN5utils12circular_f3211CircularF326as_f3217hdf249fd86cbb61c0E
000000014145321a  f3410f12cd               movsldup xmm1, xmm13
000000014145321f  410f59ca                 mulps    xmm1, xmm10
0000000141453223  410f14c0                 unpcklps xmm0, xmm8
0000000141453227  0f5cc8                   subps    xmm1, xmm0
000000014145322a  f3440f16c1               movshdup xmm8, xmm1
000000014145322f  f30f10059549b001         movss    xmm0, dword ptr [rip + 0x1b04995]
0000000141453237  f30f58c1                 addss    xmm0, xmm1
000000014145323b  440f28e9                 movaps   xmm13, xmm1
000000014145323f  f3450fc2e806             cmpnless xmm13, xmm8
0000000141453245  410f54cd                 andps    xmm1, xmm13
0000000141453249  440f55e8                 andnps   xmm13, xmm0
000000014145324d  440f56e9                 orps     xmm13, xmm1
0000000141453251  f3450f58e2               addss    xmm12, xmm10
0000000141453256  410f28c2                 movaps   xmm0, xmm10
000000014145325a  f3410fc2c106             cmpnless xmm0, xmm9
0000000141453260  440f54d0                 andps    xmm10, xmm0
0000000141453264  410f55c4                 andnps   xmm0, xmm12
0000000141453268  410f56c2                 orps     xmm0, xmm10
000000014145326c  0f28cf                   movaps   xmm1, xmm7
000000014145326f  f3410f58cb               addss    xmm1, xmm11
0000000141453274  f3440f114c2450           movss    dword ptr [rsp + 0x50], xmm9
000000014145327b  f30f117c2454             movss    dword ptr [rsp + 0x54], xmm7
0000000141453281  f30f11442458             movss    dword ptr [rsp + 0x58], xmm0
0000000141453287  f30f114c245c             movss    dword ptr [rsp + 0x5c], xmm1
000000014145328d  488d542450               lea      rdx, [rsp + 0x50]
0000000141453292  4c89f1                   mov      rcx, r14
0000000141453295  e8469e0601               call     0x1424bd0e0 ; system_wall_constructor::construct_wooden_walls::window_cut_lists::WindowCutLists::list_for_piece | _ZN23system_wall_constructor22construct_wooden_walls16window_cut_lists14WindowCutLists14list_for_piece17h2d5ab5cb5be30598E
000000014145329a  89c5                     mov      ebp, eax
000000014145329c  4189d6                   mov      r14d, edx
000000014145329f  4c8dbc24f0000000         lea      r15, [rsp + 0xf0]
00000001414532a7  4c89f9                   mov      rcx, r15
00000001414532aa  4889da                   mov      rdx, rbx
00000001414532ad  0f28d7                   movaps   xmm2, xmm7
00000001414532b0  e88b129aff               call     0x140df4540 ; utils::swizzlers::impl$1::xvy | _ZN71_$LT$glam..f32..vec2..Vec2$u20$as$u20$utils..swizzlers..SwizzlerXVY$GT$3xvy17hcb9aa753d52e64e7E
00000001414532b5  f30f105308               movss    xmm2, dword ptr [rbx + 8]
00000001414532ba  f3440f116c2430           movss    dword ptr [rsp + 0x30], xmm13
00000001414532c1  f3440f11442428           movss    dword ptr [rsp + 0x28], xmm8
00000001414532c8  f3440f115c2420           movss    dword ptr [rsp + 0x20], xmm11
00000001414532cf  c644243803               mov      byte ptr [rsp + 0x38], 3
00000001414532d4  488d5c2450               lea      rbx, [rsp + 0x50]
00000001414532d9  4889d9                   mov      rcx, rbx
00000001414532dc  4c89fa                   mov      rdx, r15
00000001414532df  0f28de                   movaps   xmm3, xmm6
00000001414532e2  e8897565ff               call     0x140aaa870 ; country_core::render::nani::instance_data::CurvedHalfTimberInstanceData::new_curved_xy | _ZN12country_core6render4nani13instance_data28CurvedHalfTimberInstanceData13new_curved_xy17heece4dfe0f3290cfE
00000001414532e7  488d4c2448               lea      rcx, [rsp + 0x48]
00000001414532ec  e87f26ecfe               call     0x140315970 ; motomoto::impl$0::as_tag | cmsPipelineGetPtrToFirstStage
00000001414532f1  31f8                     xor      eax, edi
00000001414532f3  438d0cb6                 lea      ecx, [r14 + r14*4]
00000001414532f7  448d0448                 lea      r8d, [rax + rcx*2]
00000001414532fb  488dbc24f0000000         lea      rdi, [rsp + 0xf0]
0000000141453303  4889f9                   mov      rcx, rdi
0000000141453306  4889da                   mov      rdx, rbx
0000000141453309  e8327965ff               call     0x140aaac40 ; country_core::render::nani::instance_data::CurvedHalfTimberInstanceData::with_seed | _ZN12country_core6render4nani13instance_data28CurvedHalfTimberInstanceData9with_seed17h0d137f01648a4780E
000000014145330e  488d5c2450               lea      rbx, [rsp + 0x50]
0000000141453313  4889d9                   mov      rcx, rbx
0000000141453316  4889fa                   mov      rdx, rdi
0000000141453319  41b802000000             mov      r8d, 2
000000014145331f  e8ac7465ff               call     0x140aaa7d0 ; country_core::render::nani::instance_data::CurvedHalfTimberInstanceData::with_flags | _ZN12country_core6render4nani13instance_data28CurvedHalfTimberInstanceData10with_flags17h9dd4275b7c5d1223E
0000000141453324  488d8c24a0000000         lea      rcx, [rsp + 0xa0]
000000014145332c  4889da                   mov      rdx, rbx
000000014145332f  4189e8                   mov      r8d, ebp
0000000141453332  e8397865ff               call     0x140aaab70 ; country_core::render::nani::instance_data::CurvedHalfTimberInstanceData::with_window_cut_list | _ZN12country_core6render4nani13instance_data28CurvedHalfTimberInstanceData20with_window_cut_list17h6086e21bc4d605f4E
0000000141453337  488b7e10                 mov      rdi, qword ptr [rsi + 0x10]
000000014145333b  483b3e                   cmp      rdi, qword ptr [rsi]
000000014145333e  7508                     jne      0x141453348
0000000141453340  4889f1                   mov      rcx, rsi
0000000141453343  e8b8a79301               call     0x142d8db00 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17hc15e89e25ee7b463E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17hede96bbd5ceaa096E
0000000141453348  488b4608                 mov      rax, qword ptr [rsi + 8]
000000014145334c  488d0cbf                 lea      rcx, [rdi + rdi*4]
0000000141453350  48c1e104                 shl      rcx, 4
0000000141453354  0f108424e0000000         movups   xmm0, xmmword ptr [rsp + 0xe0]
000000014145335c  0f11440840               movups   xmmword ptr [rax + rcx + 0x40], xmm0
0000000141453361  0f108424a0000000         movups   xmm0, xmmword ptr [rsp + 0xa0]
0000000141453369  0f108c24b0000000         movups   xmm1, xmmword ptr [rsp + 0xb0]
0000000141453371  0f109424c0000000         movups   xmm2, xmmword ptr [rsp + 0xc0]
0000000141453379  0f109c24d0000000         movups   xmm3, xmmword ptr [rsp + 0xd0]
0000000141453381  0f115c0830               movups   xmmword ptr [rax + rcx + 0x30], xmm3
0000000141453386  0f11540820               movups   xmmword ptr [rax + rcx + 0x20], xmm2
000000014145338b  0f114c0810               movups   xmmword ptr [rax + rcx + 0x10], xmm1
0000000141453390  0f110408                 movups   xmmword ptr [rax + rcx], xmm0
0000000141453394  48ffc7                   inc      rdi
0000000141453397  48897e10                 mov      qword ptr [rsi + 0x10], rdi
000000014145339b  0f28b42440010000         movaps   xmm6, xmmword ptr [rsp + 0x140]
00000001414533a3  0f28bc2450010000         movaps   xmm7, xmmword ptr [rsp + 0x150]
00000001414533ab  440f28842460010000       movaps   xmm8, xmmword ptr [rsp + 0x160]
00000001414533b4  440f288c2470010000       movaps   xmm9, xmmword ptr [rsp + 0x170]
00000001414533bd  440f28942480010000       movaps   xmm10, xmmword ptr [rsp + 0x180]
00000001414533c6  440f289c2490010000       movaps   xmm11, xmmword ptr [rsp + 0x190]
00000001414533cf  440f28a424a0010000       movaps   xmm12, xmmword ptr [rsp + 0x1a0]
00000001414533d8  440f28ac24b0010000       movaps   xmm13, xmmword ptr [rsp + 0x1b0]
00000001414533e1  4881c4c8010000           add      rsp, 0x1c8
00000001414533e8  5b                       pop      rbx
00000001414533e9  5d                       pop      rbp
00000001414533ea  5f                       pop      rdi
00000001414533eb  5e                       pop      rsi
00000001414533ec  415e                     pop      r14
00000001414533ee  415f                     pop      r15
00000001414533f0  c3                       ret      
00000001414533f1  488d0d084beb01           lea      rcx, [rip + 0x1eb4b08] ; 'assertion failed: !u.is_nan()crates/utils/src/curve/curve_u_circular.rs'
00000001414533f8  4c8d05494beb01           lea      r8, [rip + 0x1eb4b49]
00000001414533ff  ba1d000000               mov      edx, 0x1d
0000000141453404  e8a74f9701               call     0x142dc83b0 ; core::panicking::panic | _RNvNtCs8icZUrvfcq9_4core9panicking5panic
0000000141453409  cc                       int3     