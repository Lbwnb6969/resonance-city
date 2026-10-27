0000000140aaa870  4156                     push     r14
0000000140aaa872  56                       push     rsi
0000000140aaa873  57                       push     rdi
0000000140aaa874  53                       push     rbx
0000000140aaa875  4883ec78                 sub      rsp, 0x78
0000000140aaa879  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
0000000140aaa87f  440f294c2450             movaps   xmmword ptr [rsp + 0x50], xmm9
0000000140aaa885  440f29442440             movaps   xmmword ptr [rsp + 0x40], xmm8
0000000140aaa88b  0f297c2430               movaps   xmmword ptr [rsp + 0x30], xmm7
0000000140aaa890  0f29742420               movaps   xmmword ptr [rsp + 0x20], xmm6
0000000140aaa895  0f28fb                   movaps   xmm7, xmm3
0000000140aaa898  0f28f2                   movaps   xmm6, xmm2
0000000140aaa89b  4889d7                   mov      rdi, rdx
0000000140aaa89e  4889ce                   mov      rsi, rcx
0000000140aaa8a1  0fb69c24d8000000         movzx    ebx, byte ptr [rsp + 0xd8]
0000000140aaa8a9  f3440f108424d0000000     movss    xmm8, dword ptr [rsp + 0xd0]
0000000140aaa8b3  f3440f108c24c8000000     movss    xmm9, dword ptr [rsp + 0xc8]
0000000140aaa8bd  f30f593d8bc63802         mulss    xmm7, dword ptr [rip + 0x238c68b]
0000000140aaa8c5  440f28d2                 movaps   xmm10, xmm2
0000000140aaa8c9  f3440f58d7               addss    xmm10, xmm7
0000000140aaa8ce  410f28c0                 movaps   xmm0, xmm8
0000000140aaa8d2  f3410f5cc1               subss    xmm0, xmm9
0000000140aaa8d7  0f540502cf3802           andps    xmm0, xmmword ptr [rip + 0x238cf02]
0000000140aaa8de  f3410f59c2               mulss    xmm0, xmm10
0000000140aaa8e3  4c8d354aea5902           lea      r14, [rip + 0x259ea4a]
0000000140aaa8ea  f30f580536c63802         addss    xmm0, dword ptr [rip + 0x238c636]
0000000140aaa8f2  f30f5e05c6d93802         divss    xmm0, dword ptr [rip + 0x238d9c6]
0000000140aaa8fa  e8c1803802               call     0x142e329c0 ; ceilf
0000000140aaa8ff  f3480f2cc0               cvttss2si rax, xmm0
0000000140aaa904  31c9                     xor      ecx, ecx
0000000140aaa906  0f57c9                   xorps    xmm1, xmm1
0000000140aaa909  0f2ec1                   ucomiss  xmm0, xmm1
0000000140aaa90c  0f43c8                   cmovae   ecx, eax
0000000140aaa90f  0f2e0532c13902           ucomiss  xmm0, dword ptr [rip + 0x239c132]
0000000140aaa916  b8ffffffff               mov      eax, 0xffffffff
0000000140aaa91b  0f47c8                   cmova    ecx, eax
0000000140aaa91e  41030c9e                 add      ecx, dword ptr [r14 + rbx*4]
0000000140aaa922  ba01000000               mov      edx, 1
0000000140aaa927  83f902                   cmp      ecx, 2
0000000140aaa92a  7213                     jb       0x140aaa93f
0000000140aaa92c  ffc9                     dec      ecx
0000000140aaa92e  0fbdc9                   bsr      ecx, ecx
0000000140aaa931  f7d1                     not      ecx
0000000140aaa933  d3e8                     shr      eax, cl
0000000140aaa935  ffc0                     inc      eax
0000000140aaa937  89c2                     mov      edx, eax
0000000140aaa939  0f849b000000             je       0x140aaa9da
0000000140aaa93f  f30f108424c0000000       movss    xmm0, dword ptr [rsp + 0xc0]
0000000140aaa948  0fb6c3                   movzx    eax, bl
0000000140aaa94b  f30f5cf7                 subss    xmm6, xmm7
0000000140aaa94f  f30fbcca                 tzcnt    ecx, edx
0000000140aaa953  83f903                   cmp      ecx, 3
0000000140aaa956  ba02000000               mov      edx, 2
0000000140aaa95b  0f43d1                   cmovae   edx, ecx
0000000140aaa95e  83fa05                   cmp      edx, 5
0000000140aaa961  b905000000               mov      ecx, 5
0000000140aaa966  0f42ca                   cmovb    ecx, edx
0000000140aaa969  8b5708                   mov      edx, dword ptr [rdi + 8]
0000000140aaa96c  895608                   mov      dword ptr [rsi + 8], edx
0000000140aaa96f  488b17                   mov      rdx, qword ptr [rdi]
0000000140aaa972  488916                   mov      qword ptr [rsi], rdx
0000000140aaa975  c7460c00000000           mov      dword ptr [rsi + 0xc], 0
0000000140aaa97c  f30f117610               movss    dword ptr [rsi + 0x10], xmm6
0000000140aaa981  f3440f115614             movss    dword ptr [rsi + 0x14], xmm10
0000000140aaa987  f3440f114e18             movss    dword ptr [rsi + 0x18], xmm9
0000000140aaa98d  f3440f11461c             movss    dword ptr [rsi + 0x1c], xmm8
0000000140aaa993  48c7462000000000         mov      qword ptr [rsi + 0x20], 0
0000000140aaa99b  f30f114628               movss    dword ptr [rsi + 0x28], xmm0
0000000140aaa9a0  89462c                   mov      dword ptr [rsi + 0x2c], eax
0000000140aaa9a3  894e30                   mov      dword ptr [rsi + 0x30], ecx
0000000140aaa9a6  0f57c0                   xorps    xmm0, xmm0
0000000140aaa9a9  0f114634                 movups   xmmword ptr [rsi + 0x34], xmm0
0000000140aaa9ad  0f114640                 movups   xmmword ptr [rsi + 0x40], xmm0
0000000140aaa9b1  4889f0                   mov      rax, rsi
0000000140aaa9b4  0f28742420               movaps   xmm6, xmmword ptr [rsp + 0x20]
0000000140aaa9b9  0f287c2430               movaps   xmm7, xmmword ptr [rsp + 0x30]
0000000140aaa9be  440f28442440             movaps   xmm8, xmmword ptr [rsp + 0x40]
0000000140aaa9c4  440f284c2450             movaps   xmm9, xmmword ptr [rsp + 0x50]
0000000140aaa9ca  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
0000000140aaa9d0  4883c478                 add      rsp, 0x78
0000000140aaa9d4  5b                       pop      rbx
0000000140aaa9d5  5f                       pop      rdi
0000000140aaa9d6  5e                       pop      rsi
0000000140aaa9d7  415e                     pop      r14
0000000140aaa9d9  c3                       ret      
0000000140aaa9da  488d0d7fe55902           lea      rcx, [rip + 0x259e57f]
0000000140aaa9e1  e81ada3102               call     0x142dc8400 ; core::num::int_log10::panic_for_nonpositive_argument | _RNvNtNtCs8icZUrvfcq9_4core3num9int_log1030panic_for_nonpositive_argument
0000000140aaa9e6  cc                       int3     