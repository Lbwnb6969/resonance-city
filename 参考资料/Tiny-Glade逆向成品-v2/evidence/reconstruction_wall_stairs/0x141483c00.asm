0000000141483c00  56                       push     rsi
0000000141483c01  57                       push     rdi
0000000141483c02  53                       push     rbx
0000000141483c03  4881ecc0000000           sub      rsp, 0xc0
0000000141483c0a  440f29ac24b0000000       movaps   xmmword ptr [rsp + 0xb0], xmm13
0000000141483c13  440f29a424a0000000       movaps   xmmword ptr [rsp + 0xa0], xmm12
0000000141483c1c  440f299c2490000000       movaps   xmmword ptr [rsp + 0x90], xmm11
0000000141483c25  440f29942480000000       movaps   xmmword ptr [rsp + 0x80], xmm10
0000000141483c2e  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
0000000141483c34  440f29442460             movaps   xmmword ptr [rsp + 0x60], xmm8
0000000141483c3a  0f297c2450               movaps   xmmword ptr [rsp + 0x50], xmm7
0000000141483c3f  0f29742440               movaps   xmmword ptr [rsp + 0x40], xmm6
0000000141483c44  4889c8                   mov      rax, rcx
0000000141483c47  8b4a1c                   mov      ecx, dword ptr [rdx + 0x1c]
0000000141483c4a  83f902                   cmp      ecx, 2
0000000141483c4d  0f84e6000000             je       0x141483d39
0000000141483c53  f6c101                   test     cl, 1
0000000141483c56  0f84dd000000             je       0x141483d39
0000000141483c5c  488d4a20                 lea      rcx, [rdx + 0x20]
0000000141483c60  4c8b4110                 mov      r8, qword ptr [rcx + 0x10]
0000000141483c64  4c89442430               mov      qword ptr [rsp + 0x30], r8
0000000141483c69  0f1001                   movups   xmm0, xmmword ptr [rcx]
0000000141483c6c  0f29442420               movaps   xmmword ptr [rsp + 0x20], xmm0
0000000141483c71  488d742420               lea      rsi, [rsp + 0x20]
0000000141483c76  4889f1                   mov      rcx, rsi
0000000141483c79  4889d3                   mov      rbx, rdx
0000000141483c7c  31d2                     xor      edx, edx
0000000141483c7e  4889c7                   mov      rdi, rax
0000000141483c81  e87aca96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483c86  0f28f0                   movaps   xmm6, xmm0
0000000141483c89  f3440f106b3c             movss    xmm13, dword ptr [rbx + 0x3c]
0000000141483c8f  ba01000000               mov      edx, 1
0000000141483c94  4889f1                   mov      rcx, rsi
0000000141483c97  e864ca96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483c9c  0f28f8                   movaps   xmm7, xmm0
0000000141483c9f  ba01000000               mov      edx, 1
0000000141483ca4  4889f1                   mov      rcx, rsi
0000000141483ca7  e854ca96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483cac  440f28c0                 movaps   xmm8, xmm0
0000000141483cb0  ba02000000               mov      edx, 2
0000000141483cb5  4889f1                   mov      rcx, rsi
0000000141483cb8  e843ca96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483cbd  440f28d0                 movaps   xmm10, xmm0
0000000141483cc1  ba02000000               mov      edx, 2
0000000141483cc6  4889f1                   mov      rcx, rsi
0000000141483cc9  e832ca96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483cce  440f28c8                 movaps   xmm9, xmm0
0000000141483cd2  ba03000000               mov      edx, 3
0000000141483cd7  4889f1                   mov      rcx, rsi
0000000141483cda  e821ca96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483cdf  440f28d8                 movaps   xmm11, xmm0
0000000141483ce3  ba03000000               mov      edx, 3
0000000141483ce8  4889f1                   mov      rcx, rsi
0000000141483ceb  e810ca96ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483cf0  440f28e0                 movaps   xmm12, xmm0
0000000141483cf4  ba04000000               mov      edx, 4
0000000141483cf9  4889f1                   mov      rcx, rsi
0000000141483cfc  e8ffc996ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483d01  4889f8                   mov      rax, rdi
0000000141483d04  0f14f7                   unpcklps xmm6, xmm7
0000000141483d07  450f14c2                 unpcklps xmm8, xmm10
0000000141483d0b  410f16f0                 movlhps  xmm6, xmm8
0000000141483d0f  450fc6ed00               shufps   xmm13, xmm13, 0
0000000141483d14  410f59f5                 mulps    xmm6, xmm13
0000000141483d18  0f117704                 movups   xmmword ptr [rdi + 4], xmm6
0000000141483d1c  450f14cb                 unpcklps xmm9, xmm11
0000000141483d20  440f14e0                 unpcklps xmm12, xmm0
0000000141483d24  450f16cc                 movlhps  xmm9, xmm12
0000000141483d28  450f59cd                 mulps    xmm9, xmm13
0000000141483d2c  440f114f14               movups   xmmword ptr [rdi + 0x14], xmm9
0000000141483d31  c70701000000             mov      dword ptr [rdi], 1
0000000141483d37  eb06                     jmp      0x141483d3f
0000000141483d39  c70000000000             mov      dword ptr [rax], 0
0000000141483d3f  0f28742440               movaps   xmm6, xmmword ptr [rsp + 0x40]
0000000141483d44  0f287c2450               movaps   xmm7, xmmword ptr [rsp + 0x50]
0000000141483d49  440f28442460             movaps   xmm8, xmmword ptr [rsp + 0x60]
0000000141483d4f  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
0000000141483d55  440f28942480000000       movaps   xmm10, xmmword ptr [rsp + 0x80]
0000000141483d5e  440f289c2490000000       movaps   xmm11, xmmword ptr [rsp + 0x90]
0000000141483d67  440f28a424a0000000       movaps   xmm12, xmmword ptr [rsp + 0xa0]
0000000141483d70  440f28ac24b0000000       movaps   xmm13, xmmword ptr [rsp + 0xb0]
0000000141483d79  4881c4c0000000           add      rsp, 0xc0
0000000141483d80  5b                       pop      rbx
0000000141483d81  5f                       pop      rdi
0000000141483d82  5e                       pop      rsi
0000000141483d83  c3                       ret      