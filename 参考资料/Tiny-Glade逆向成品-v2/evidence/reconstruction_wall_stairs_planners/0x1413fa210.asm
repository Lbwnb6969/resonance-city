00000001413fa210  4883ec78                 sub      rsp, 0x78
00000001413fa214  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
00000001413fa21a  440f294c2450             movaps   xmmword ptr [rsp + 0x50], xmm9
00000001413fa220  440f29442440             movaps   xmmword ptr [rsp + 0x40], xmm8
00000001413fa226  0f297c2430               movaps   xmmword ptr [rsp + 0x30], xmm7
00000001413fa22b  0f29742420               movaps   xmmword ptr [rsp + 0x20], xmm6
00000001413fa230  488b5110                 mov      rdx, qword ptr [rcx + 0x10]
00000001413fa234  31c0                     xor      eax, eax
00000001413fa236  0f57c0                   xorps    xmm0, xmm0
00000001413fa239  4883fa02                 cmp      rdx, 2
00000001413fa23d  0f82f5000000             jb       0x1413fa338
00000001413fa243  488b4908                 mov      rcx, qword ptr [rcx + 8]
00000001413fa247  f30f1039                 movss    xmm7, dword ptr [rcx]
00000001413fa24b  f30f105914               movss    xmm3, dword ptr [rcx + 0x14]
00000001413fa250  0f28c1                   movaps   xmm0, xmm1
00000001413fa253  f30f5cc7                 subss    xmm0, xmm7
00000001413fa257  f20f106908               movsd    xmm5, qword ptr [rcx + 8]
00000001413fa25c  f30f10610c               movss    xmm4, dword ptr [rcx + 0xc]
00000001413fa261  0f28f2                   movaps   xmm6, xmm2
00000001413fa264  f30f5cf5                 subss    xmm6, xmm5
00000001413fa268  f30f5ce7                 subss    xmm4, xmm7
00000001413fa26c  440f28c3                 movaps   xmm8, xmm3
00000001413fa270  f3440f5cc5               subss    xmm8, xmm5
00000001413fa275  f30f59c4                 mulss    xmm0, xmm4
00000001413fa279  f3410f59f0               mulss    xmm6, xmm8
00000001413fa27e  f30f58f0                 addss    xmm6, xmm0
00000001413fa282  f30f59e4                 mulss    xmm4, xmm4
00000001413fa286  f3450f59c0               mulss    xmm8, xmm8
00000001413fa28b  f3440f58c4               addss    xmm8, xmm4
00000001413fa290  f3440f5f058bcca301       maxss    xmm8, dword ptr [rip + 0x1a3cc8b]
00000001413fa299  f3410f5ef0               divss    xmm6, xmm8
00000001413fa29e  0f57c0                   xorps    xmm0, xmm0
00000001413fa2a1  450f57c0                 xorps    xmm8, xmm8
00000001413fa2a5  f3440f5fc6               maxss    xmm8, xmm6
00000001413fa2aa  f30f102576cca301         movss    xmm4, dword ptr [rip + 0x1a3cc76]
00000001413fa2b2  0f28f4                   movaps   xmm6, xmm4
00000001413fa2b5  f3410f5df0               minss    xmm6, xmm8
00000001413fa2ba  440f28c4                 movaps   xmm8, xmm4
00000001413fa2be  f3440f5cc6               subss    xmm8, xmm6
00000001413fa2c3  440f28cd                 movaps   xmm9, xmm5
00000001413fa2c7  440fc6cde1               shufps   xmm9, xmm5, 0xe1
00000001413fa2cc  f3440f10cf               movss    xmm9, xmm7
00000001413fa2d1  f3410f12f8               movsldup xmm7, xmm8
00000001413fa2d6  410f59f9                 mulps    xmm7, xmm9
00000001413fa2da  0fc6ddd4                 shufps   xmm3, xmm5, 0xd4
00000001413fa2de  440f28c3                 movaps   xmm8, xmm3
00000001413fa2e2  440fc6c5e2               shufps   xmm8, xmm5, 0xe2
00000001413fa2e7  f3440f12ce               movsldup xmm9, xmm6
00000001413fa2ec  450f59c8                 mulps    xmm9, xmm8
00000001413fa2f0  440f58cf                 addps    xmm9, xmm7
00000001413fa2f4  0f14ca                   unpcklps xmm1, xmm2
00000001413fa2f7  0f28d1                   movaps   xmm2, xmm1
00000001413fa2fa  410f5cd1                 subps    xmm2, xmm9
00000001413fa2fe  0f59d2                   mulps    xmm2, xmm2
00000001413fa301  f30f16fa                 movshdup xmm7, xmm2
00000001413fa305  f30f58fa                 addss    xmm7, xmm2
00000001413fa309  f30f51ff                 sqrtss   xmm7, xmm7
00000001413fa30d  f30f101527cca301         movss    xmm2, dword ptr [rip + 0x1a3cc27]
00000001413fa315  0f2ed7                   ucomiss  xmm2, xmm7
00000001413fa318  7618                     jbe      0x1413fa332
00000001413fa31a  0f2ef0                   ucomiss  xmm6, xmm0
00000001413fa31d  0f821d010000             jb       0x1413fa440
00000001413fa323  0f2ee6                   ucomiss  xmm4, xmm6
00000001413fa326  0f28d7                   movaps   xmm2, xmm7
00000001413fa329  0f28c6                   movaps   xmm0, xmm6
00000001413fa32c  0f820e010000             jb       0x1413fa440
00000001413fa332  4883fa02                 cmp      rdx, 2
00000001413fa336  7521                     jne      0x1413fa359
00000001413fa338  0f28742420               movaps   xmm6, xmmword ptr [rsp + 0x20]
00000001413fa33d  0f287c2430               movaps   xmm7, xmmword ptr [rsp + 0x30]
00000001413fa342  440f28442440             movaps   xmm8, xmmword ptr [rsp + 0x40]
00000001413fa348  440f284c2450             movaps   xmm9, xmmword ptr [rsp + 0x50]
00000001413fa34e  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
00000001413fa354  4883c478                 add      rsp, 0x78
00000001413fa358  c3                       ret      
00000001413fa359  488d0452                 lea      rax, [rdx + rdx*2]
00000001413fa35d  488d1481                 lea      rdx, [rcx + rax*4]
00000001413fa361  4883c118                 add      rcx, 0x18
00000001413fa365  0fc6ddf2                 shufps   xmm3, xmm5, 0xf2
00000001413fa369  41b801000000             mov      r8d, 1
00000001413fa36f  31c0                     xor      eax, eax
00000001413fa371  f30f102dabcba301         movss    xmm5, dword ptr [rip + 0x1a3cbab]
00000001413fa379  0f57f6                   xorps    xmm6, xmm6
00000001413fa37c  eb0e                     jmp      0x1413fa38c
00000001413fa37e  6690                     nop      
00000001413fa380  4883c10c                 add      rcx, 0xc
00000001413fa384  41ffc0                   inc      r8d
00000001413fa387  4839d1                   cmp      rcx, rdx
00000001413fa38a  74ac                     je       0x1413fa338
00000001413fa38c  0f28fb                   movaps   xmm7, xmm3
00000001413fa38f  440f28c1                 movaps   xmm8, xmm1
00000001413fa393  440f5cc3                 subps    xmm8, xmm3
00000001413fa397  f30f1019                 movss    xmm3, dword ptr [rcx]
00000001413fa39b  f3440f104908             movss    xmm9, dword ptr [rcx + 8]
00000001413fa3a1  410f14d9                 unpcklps xmm3, xmm9
00000001413fa3a5  440f28cb                 movaps   xmm9, xmm3
00000001413fa3a9  440f5ccf                 subps    xmm9, xmm7
00000001413fa3ad  450f59c1                 mulps    xmm8, xmm9
00000001413fa3b1  f3450f16d0               movshdup xmm10, xmm8
00000001413fa3b6  f3450f58d0               addss    xmm10, xmm8
00000001413fa3bb  450f59c9                 mulps    xmm9, xmm9
00000001413fa3bf  f3450f16c1               movshdup xmm8, xmm9
00000001413fa3c4  f3450f58c1               addss    xmm8, xmm9
00000001413fa3c9  f3440f5fc5               maxss    xmm8, xmm5
00000001413fa3ce  f3450f5ed0               divss    xmm10, xmm8
00000001413fa3d3  450f57c9                 xorps    xmm9, xmm9
00000001413fa3d7  f3450f5fca               maxss    xmm9, xmm10
00000001413fa3dc  440f28c4                 movaps   xmm8, xmm4
00000001413fa3e0  f3450f5dc1               minss    xmm8, xmm9
00000001413fa3e5  440f28cc                 movaps   xmm9, xmm4
00000001413fa3e9  f3450f5cc8               subss    xmm9, xmm8
00000001413fa3ee  f3450f12c9               movsldup xmm9, xmm9
00000001413fa3f3  440f59cf                 mulps    xmm9, xmm7
00000001413fa3f7  f3410f12f8               movsldup xmm7, xmm8
00000001413fa3fc  0f59fb                   mulps    xmm7, xmm3
00000001413fa3ff  410f58f9                 addps    xmm7, xmm9
00000001413fa403  440f28c9                 movaps   xmm9, xmm1
00000001413fa407  440f5ccf                 subps    xmm9, xmm7
00000001413fa40b  450f59c9                 mulps    xmm9, xmm9
00000001413fa40f  f3410f16f9               movshdup xmm7, xmm9
00000001413fa414  f3410f58f9               addss    xmm7, xmm9
00000001413fa419  f30f51ff                 sqrtss   xmm7, xmm7
00000001413fa41d  0f2ed7                   ucomiss  xmm2, xmm7
00000001413fa420  0f865affffff             jbe      0x1413fa380
00000001413fa426  440f2ec6                 ucomiss  xmm8, xmm6
00000001413fa42a  7214                     jb       0x1413fa440
00000001413fa42c  410f2ee0                 ucomiss  xmm4, xmm8
00000001413fa430  0f28d7                   movaps   xmm2, xmm7
00000001413fa433  410f28c0                 movaps   xmm0, xmm8
00000001413fa437  4489c0                   mov      eax, r8d
00000001413fa43a  0f8340ffffff             jae      0x1413fa380
00000001413fa440  488d0d09c5f001           lea      rcx, [rip + 0x1f0c509] ; 'assertion failed: (0.0..=1.0).contains(&t)'
00000001413fa447  4c8d05cac5f001           lea      r8, [rip + 0x1f0c5ca]
00000001413fa44e  ba2a000000               mov      edx, 0x2a
00000001413fa453  e858df9c01               call     0x142dc83b0 ; core::panicking::panic | _RNvNtCs8icZUrvfcq9_4core9panicking5panic
00000001413fa458  cc                       int3     