0000000141489790  4157                     push     r15
0000000141489792  4156                     push     r14
0000000141489794  56                       push     rsi
0000000141489795  57                       push     rdi
0000000141489796  53                       push     rbx
0000000141489797  4881ec90010000           sub      rsp, 0x190
000000014148979e  440f29ac2480010000       movaps   xmmword ptr [rsp + 0x180], xmm13
00000001414897a7  440f29a42470010000       movaps   xmmword ptr [rsp + 0x170], xmm12
00000001414897b0  440f299c2460010000       movaps   xmmword ptr [rsp + 0x160], xmm11
00000001414897b9  440f29942450010000       movaps   xmmword ptr [rsp + 0x150], xmm10
00000001414897c2  440f298c2440010000       movaps   xmmword ptr [rsp + 0x140], xmm9
00000001414897cb  440f29842430010000       movaps   xmmword ptr [rsp + 0x130], xmm8
00000001414897d4  0f29bc2420010000         movaps   xmmword ptr [rsp + 0x120], xmm7
00000001414897dc  0f29b42410010000         movaps   xmmword ptr [rsp + 0x110], xmm6
00000001414897e4  4889ce                   mov      rsi, rcx
00000001414897e7  f6421c01                 test     byte ptr [rdx + 0x1c], 1
00000001414897eb  0f8456010000             je       0x141489947
00000001414897f1  4c89c7                   mov      rdi, r8
00000001414897f4  488b4230                 mov      rax, qword ptr [rdx + 0x30]
00000001414897f8  4889442450               mov      qword ptr [rsp + 0x50], rax
00000001414897fd  0f104220                 movups   xmm0, xmmword ptr [rdx + 0x20]
0000000141489801  0f29442440               movaps   xmmword ptr [rsp + 0x40], xmm0
0000000141489806  4531f6                   xor      r14d, r14d
0000000141489809  488d5c2440               lea      rbx, [rsp + 0x40]
000000014148980e  4889d9                   mov      rcx, rbx
0000000141489811  4989d7                   mov      r15, rdx
0000000141489814  31d2                     xor      edx, edx
0000000141489816  e8e56e96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
000000014148981b  0f28f0                   movaps   xmm6, xmm0
000000014148981e  f3450f106f3c             movss    xmm13, dword ptr [r15 + 0x3c]
0000000141489824  ba01000000               mov      edx, 1
0000000141489829  4889d9                   mov      rcx, rbx
000000014148982c  e8cf6e96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141489831  0f28f8                   movaps   xmm7, xmm0
0000000141489834  ba01000000               mov      edx, 1
0000000141489839  4889d9                   mov      rcx, rbx
000000014148983c  e8bf6e96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141489841  440f28c0                 movaps   xmm8, xmm0
0000000141489845  ba02000000               mov      edx, 2
000000014148984a  4889d9                   mov      rcx, rbx
000000014148984d  e8ae6e96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141489852  440f28d0                 movaps   xmm10, xmm0
0000000141489856  ba02000000               mov      edx, 2
000000014148985b  4889d9                   mov      rcx, rbx
000000014148985e  e89d6e96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141489863  440f28c8                 movaps   xmm9, xmm0
0000000141489867  ba03000000               mov      edx, 3
000000014148986c  4889d9                   mov      rcx, rbx
000000014148986f  e88c6e96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141489874  440f28d8                 movaps   xmm11, xmm0
0000000141489878  ba03000000               mov      edx, 3
000000014148987d  4889d9                   mov      rcx, rbx
0000000141489880  e87b6e96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141489885  440f28e0                 movaps   xmm12, xmm0
0000000141489889  ba04000000               mov      edx, 4
000000014148988e  4889d9                   mov      rcx, rbx
0000000141489891  e86a6e96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141489896  0f14f7                   unpcklps xmm6, xmm7
0000000141489899  450f14c2                 unpcklps xmm8, xmm10
000000014148989d  410f16f0                 movlhps  xmm6, xmm8
00000001414898a1  450fc6ed00               shufps   xmm13, xmm13, 0
00000001414898a6  410f59f5                 mulps    xmm6, xmm13
00000001414898aa  0f29b424b0000000         movaps   xmmword ptr [rsp + 0xb0], xmm6
00000001414898b2  450f14cb                 unpcklps xmm9, xmm11
00000001414898b6  440f14e0                 unpcklps xmm12, xmm0
00000001414898ba  450f16cc                 movlhps  xmm9, xmm12
00000001414898be  450f59cd                 mulps    xmm9, xmm13
00000001414898c2  440f298c24c0000000       movaps   xmmword ptr [rsp + 0xc0], xmm9
00000001414898cb  488b4710                 mov      rax, qword ptr [rdi + 0x10]
00000001414898cf  4889842408010000         mov      qword ptr [rsp + 0x108], rax
00000001414898d7  0f1007                   movups   xmm0, xmmword ptr [rdi]
00000001414898da  0f118424f8000000         movups   xmmword ptr [rsp + 0xf8], xmm0
00000001414898e2  48c744244000000000       mov      qword ptr [rsp + 0x40], 0
00000001414898eb  48c744246800000000       mov      qword ptr [rsp + 0x68], 0
00000001414898f4  0f108c24d8000000         movups   xmm1, xmmword ptr [rsp + 0xd8]
00000001414898fc  0f109424e8000000         movups   xmm2, xmmword ptr [rsp + 0xe8]
0000000141489904  0f114c2470               movups   xmmword ptr [rsp + 0x70], xmm1
0000000141489909  0f11942480000000         movups   xmmword ptr [rsp + 0x80], xmm2
0000000141489911  0f11842490000000         movups   xmmword ptr [rsp + 0x90], xmm0
0000000141489919  48898424a0000000         mov      qword ptr [rsp + 0xa0], rax
0000000141489921  488d8424b0000000         lea      rax, [rsp + 0xb0]
0000000141489929  48898424a8000000         mov      qword ptr [rsp + 0xa8], rax
0000000141489931  488d4c2428               lea      rcx, [rsp + 0x28]
0000000141489936  488d542440               lea      rdx, [rsp + 0x40]
000000014148993b  e8a0f1f5ff               call     0x1413e8ae0 ; _ZN98_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$alloc..vec..spec_from_iter..SpecFromIter$LT$T$C$I$GT$$GT$9from_iter17h0c3e11a784b11587E | alloc::vec::spec_from_iter::impl$0::from_iter<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceXRange,core::iter::adapters::map::Map<core::iter::adapters::flatten::Flatten<core::option::IntoIter<array$<usize,2> > >,system_wall_constructor::construct_wooden_walls::construct_wall_boards::rectangle_gable_wallspace_ranges::closure$0::closure_env$0> >
0000000141489940  4c3b742428               cmp      r14, qword ptr [rsp + 0x28]
0000000141489945  7119                     jno      0x141489960
0000000141489947  48c70600000000           mov      qword ptr [rsi], 0
000000014148994e  48c7460804000000         mov      qword ptr [rsi + 8], 4
0000000141489956  48c7461000000000         mov      qword ptr [rsi + 0x10], 0
000000014148995e  eb11                     jmp      0x141489971
0000000141489960  488b442438               mov      rax, qword ptr [rsp + 0x38]
0000000141489965  48894610                 mov      qword ptr [rsi + 0x10], rax
0000000141489969  0f10442428               movups   xmm0, xmmword ptr [rsp + 0x28]
000000014148996e  0f1106                   movups   xmmword ptr [rsi], xmm0
0000000141489971  4889f0                   mov      rax, rsi
0000000141489974  0f28b42410010000         movaps   xmm6, xmmword ptr [rsp + 0x110]
000000014148997c  0f28bc2420010000         movaps   xmm7, xmmword ptr [rsp + 0x120]
0000000141489984  440f28842430010000       movaps   xmm8, xmmword ptr [rsp + 0x130]
000000014148998d  440f288c2440010000       movaps   xmm9, xmmword ptr [rsp + 0x140]
0000000141489996  440f28942450010000       movaps   xmm10, xmmword ptr [rsp + 0x150]
000000014148999f  440f289c2460010000       movaps   xmm11, xmmword ptr [rsp + 0x160]
00000001414899a8  440f28a42470010000       movaps   xmm12, xmmword ptr [rsp + 0x170]
00000001414899b1  440f28ac2480010000       movaps   xmm13, xmmword ptr [rsp + 0x180]
00000001414899ba  4881c490010000           add      rsp, 0x190
00000001414899c1  5b                       pop      rbx
00000001414899c2  5f                       pop      rdi
00000001414899c3  5e                       pop      rsi
00000001414899c4  415e                     pop      r14
00000001414899c6  415f                     pop      r15
00000001414899c8  c3                       ret      