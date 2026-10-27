0000000141486f80  4156                     push     r14
0000000141486f82  56                       push     rsi
0000000141486f83  57                       push     rdi
0000000141486f84  53                       push     rbx
0000000141486f85  4881ecd8000000           sub      rsp, 0xd8
0000000141486f8c  440f29b424c0000000       movaps   xmmword ptr [rsp + 0xc0], xmm14
0000000141486f95  440f29ac24b0000000       movaps   xmmword ptr [rsp + 0xb0], xmm13
0000000141486f9e  440f29a424a0000000       movaps   xmmword ptr [rsp + 0xa0], xmm12
0000000141486fa7  440f299c2490000000       movaps   xmmword ptr [rsp + 0x90], xmm11
0000000141486fb0  440f29942480000000       movaps   xmmword ptr [rsp + 0x80], xmm10
0000000141486fb9  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
0000000141486fbf  440f29442460             movaps   xmmword ptr [rsp + 0x60], xmm8
0000000141486fc5  0f297c2450               movaps   xmmword ptr [rsp + 0x50], xmm7
0000000141486fca  0f29742440               movaps   xmmword ptr [rsp + 0x40], xmm6
0000000141486fcf  4889ce                   mov      rsi, rcx
0000000141486fd2  f30f10842420010000       movss    xmm0, dword ptr [rsp + 0x120]
0000000141486fdb  4983f801                 cmp      r8, 1
0000000141486fdf  0f8519010000             jne      0x1414870fe
0000000141486fe5  f6421c01                 test     byte ptr [rdx + 0x1c], 1
0000000141486fe9  0f840f010000             je       0x1414870fe
0000000141486fef  440f28e8                 movaps   xmm13, xmm0
0000000141486ff3  488b4230                 mov      rax, qword ptr [rdx + 0x30]
0000000141486ff7  4889442430               mov      qword ptr [rsp + 0x30], rax
0000000141486ffc  0f104220                 movups   xmm0, xmmword ptr [rdx + 0x20]
0000000141487000  0f29442420               movaps   xmmword ptr [rsp + 0x20], xmm0
0000000141487005  488d7c2420               lea      rdi, [rsp + 0x20]
000000014148700a  4889f9                   mov      rcx, rdi
000000014148700d  4989d6                   mov      r14, rdx
0000000141487010  31d2                     xor      edx, edx
0000000141487012  4c89cb                   mov      rbx, r9
0000000141487015  e8e69696ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
000000014148701a  0f28f0                   movaps   xmm6, xmm0
000000014148701d  f3450f10763c             movss    xmm14, dword ptr [r14 + 0x3c]
0000000141487023  ba01000000               mov      edx, 1
0000000141487028  4889f9                   mov      rcx, rdi
000000014148702b  e8d09696ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141487030  0f28f8                   movaps   xmm7, xmm0
0000000141487033  ba01000000               mov      edx, 1
0000000141487038  4889f9                   mov      rcx, rdi
000000014148703b  e8c09696ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141487040  440f28c0                 movaps   xmm8, xmm0
0000000141487044  ba02000000               mov      edx, 2
0000000141487049  4889f9                   mov      rcx, rdi
000000014148704c  e8af9696ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141487051  440f28d0                 movaps   xmm10, xmm0
0000000141487055  ba02000000               mov      edx, 2
000000014148705a  4889f9                   mov      rcx, rdi
000000014148705d  e89e9696ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141487062  440f28c8                 movaps   xmm9, xmm0
0000000141487066  ba03000000               mov      edx, 3
000000014148706b  4889f9                   mov      rcx, rdi
000000014148706e  e88d9696ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141487073  440f28d8                 movaps   xmm11, xmm0
0000000141487077  ba03000000               mov      edx, 3
000000014148707c  4889f9                   mov      rcx, rdi
000000014148707f  e87c9696ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141487084  440f28e0                 movaps   xmm12, xmm0
0000000141487088  ba04000000               mov      edx, 4
000000014148708d  4889f9                   mov      rcx, rdi
0000000141487090  e86b9696ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141487095  4889d9                   mov      rcx, rbx
0000000141487098  0f14f7                   unpcklps xmm6, xmm7
000000014148709b  450f14c2                 unpcklps xmm8, xmm10
000000014148709f  410f16f0                 movlhps  xmm6, xmm8
00000001414870a3  450fc6f600               shufps   xmm14, xmm14, 0
00000001414870a8  410f59f6                 mulps    xmm6, xmm14
00000001414870ac  0f29742420               movaps   xmmword ptr [rsp + 0x20], xmm6
00000001414870b1  450f14cb                 unpcklps xmm9, xmm11
00000001414870b5  440f14e0                 unpcklps xmm12, xmm0
00000001414870b9  450f16cc                 movlhps  xmm9, xmm12
00000001414870bd  450f59ce                 mulps    xmm9, xmm14
00000001414870c1  440f294c2430             movaps   xmmword ptr [rsp + 0x30], xmm9
00000001414870c7  4883fb03                 cmp      rbx, 3
00000001414870cb  0f87bf000000             ja       0x141487190
00000001414870d1  f30f1044cc20             movss    xmm0, dword ptr [rsp + rcx*8 + 0x20]
00000001414870d7  f30f104ccc24             movss    xmm1, dword ptr [rsp + rcx*8 + 0x24]
00000001414870dd  f3440f5ce8               subss    xmm13, xmm0
00000001414870e2  0f57d2                   xorps    xmm2, xmm2
00000001414870e5  f3440f5fea               maxss    xmm13, xmm2
00000001414870ea  f30f5cc8                 subss    xmm1, xmm0
00000001414870ee  f3440f112e               movss    dword ptr [rsi], xmm13
00000001414870f3  f30f114e04               movss    dword ptr [rsi + 4], xmm1
00000001414870f8  c6460801                 mov      byte ptr [rsi + 8], 1
00000001414870fc  eb3f                     jmp      0x14148713d
00000001414870fe  f30f10723c               movss    xmm6, dword ptr [rdx + 0x3c]
0000000141487103  0f28ce                   movaps   xmm1, xmm6
0000000141487106  e865b99a01               call     0x142e32a70 ; fmodf
000000014148710b  0f280dce069b01           movaps   xmm1, xmmword ptr [rip + 0x19b06ce]
0000000141487112  0f54ce                   andps    xmm1, xmm6
0000000141487115  f30f58c8                 addss    xmm1, xmm0
0000000141487119  0f57d2                   xorps    xmm2, xmm2
000000014148711c  0f28d8                   movaps   xmm3, xmm0
000000014148711f  f30fc2da01               cmpltss  xmm3, xmm2
0000000141487124  0f28d3                   movaps   xmm2, xmm3
0000000141487127  0f55d0                   andnps   xmm2, xmm0
000000014148712a  0f54d9                   andps    xmm3, xmm1
000000014148712d  0f56da                   orps     xmm3, xmm2
0000000141487130  f30f111e                 movss    dword ptr [rsi], xmm3
0000000141487134  f30f117604               movss    dword ptr [rsi + 4], xmm6
0000000141487139  c6460800                 mov      byte ptr [rsi + 8], 0
000000014148713d  4889f0                   mov      rax, rsi
0000000141487140  0f28742440               movaps   xmm6, xmmword ptr [rsp + 0x40]
0000000141487145  0f287c2450               movaps   xmm7, xmmword ptr [rsp + 0x50]
000000014148714a  440f28442460             movaps   xmm8, xmmword ptr [rsp + 0x60]
0000000141487150  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
0000000141487156  440f28942480000000       movaps   xmm10, xmmword ptr [rsp + 0x80]
000000014148715f  440f289c2490000000       movaps   xmm11, xmmword ptr [rsp + 0x90]
0000000141487168  440f28a424a0000000       movaps   xmm12, xmmword ptr [rsp + 0xa0]
0000000141487171  440f28ac24b0000000       movaps   xmm13, xmmword ptr [rsp + 0xb0]
000000014148717a  440f28b424c0000000       movaps   xmm14, xmmword ptr [rsp + 0xc0]
0000000141487183  4881c4d8000000           add      rsp, 0xd8
000000014148718a  5b                       pop      rbx
000000014148718b  5f                       pop      rdi
000000014148718c  5e                       pop      rsi
000000014148718d  415e                     pop      r14
000000014148718f  c3                       ret      
0000000141487190  4c8d05a960e801           lea      r8, [rip + 0x1e860a9]
0000000141487197  ba04000000               mov      edx, 4
000000014148719c  e851109401               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
00000001414871a1  cc                       int3     