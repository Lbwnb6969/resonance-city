0000000140c014f0  4156                     push     r14
0000000140c014f2  56                       push     rsi
0000000140c014f3  57                       push     rdi
0000000140c014f4  53                       push     rbx
0000000140c014f5  4881ecd8000000           sub      rsp, 0xd8
0000000140c014fc  0f29b424c0000000         movaps   xmmword ptr [rsp + 0xc0], xmm6
0000000140c01504  488b4108                 mov      rax, qword ptr [rcx + 8]
0000000140c01508  488b5110                 mov      rdx, qword ptr [rcx + 0x10]
0000000140c0150c  4c8d04d0                 lea      r8, [rax + rdx*8]
0000000140c01510  4c8b4940                 mov      r9, qword ptr [rcx + 0x40]
0000000140c01514  488b4948                 mov      rcx, qword ptr [rcx + 0x48]
0000000140c01518  4d8d1489                 lea      r10, [r9 + rcx*4]
0000000140c0151c  4839d1                   cmp      rcx, rdx
0000000140c0151f  480f42d1                 cmovb    rdx, rcx
0000000140c01523  4889442430               mov      qword ptr [rsp + 0x30], rax
0000000140c01528  4c89442438               mov      qword ptr [rsp + 0x38], r8
0000000140c0152d  4c894c2440               mov      qword ptr [rsp + 0x40], r9
0000000140c01532  4c89542448               mov      qword ptr [rsp + 0x48], r10
0000000140c01537  4889542458               mov      qword ptr [rsp + 0x58], rdx
0000000140c0153c  c744246000000000         mov      dword ptr [rsp + 0x60], 0
0000000140c01544  0f57f6                   xorps    xmm6, xmm6
0000000140c01547  4885d2                   test     rdx, rdx
0000000140c0154a  0f8470010000             je       0x140c016c0
0000000140c01550  488d7c2460               lea      rdi, [rsp + 0x60]
0000000140c01555  488d742424               lea      rsi, [rsp + 0x24]
0000000140c0155a  48c744245001000000       mov      qword ptr [rsp + 0x50], 1
0000000140c01563  488b542430               mov      rdx, qword ptr [rsp + 0x30]
0000000140c01568  488b442440               mov      rax, qword ptr [rsp + 0x40]
0000000140c0156d  f30f1010                 movss    xmm2, dword ptr [rax]
0000000140c01571  4889f1                   mov      rcx, rsi
0000000140c01574  e8c72f1f00               call     0x140df4540 ; utils::swizzlers::impl$1::xvy | _ZN71_$LT$glam..f32..vec2..Vec2$u20$as$u20$utils..swizzlers..SwizzlerXVY$GT$3xvy17hcb9aa753d52e64e7E
0000000140c01579  c744242001000000         mov      dword ptr [rsp + 0x20], 1
0000000140c01581  8b442420                 mov      eax, dword ptr [rsp + 0x20]
0000000140c01585  89842480000000           mov      dword ptr [rsp + 0x80], eax
0000000140c0158c  488b442424               mov      rax, qword ptr [rsp + 0x24]
0000000140c01591  4889842484000000         mov      qword ptr [rsp + 0x84], rax
0000000140c01599  8b44242c                 mov      eax, dword ptr [rsp + 0x2c]
0000000140c0159d  8984248c000000           mov      dword ptr [rsp + 0x8c], eax
0000000140c015a4  488d442430               lea      rax, [rsp + 0x30]
0000000140c015a9  4889842490000000         mov      qword ptr [rsp + 0x90], rax
0000000140c015b1  488d8c24a4000000         lea      rcx, [rsp + 0xa4]
0000000140c015b9  488d942480000000         lea      rdx, [rsp + 0x80]
0000000140c015c1  e81ac10900               call     0x140c9d6e0 ; _ZN69_$LT$$LP$A$C$A$RP$$u20$as$u20$itertools..tuple_impl..TupleCollect$GT$24collect_from_iter_no_buf17h7ebaf824fdda5262E | _ZN69_$LT$$LP$A$C$A$RP$$u20$as$u20$itertools..tuple_impl..TupleCollect$GT$24collect_from_iter_no_buf17hece6372f41a8f828E
0000000140c015c6  0f108424a4000000         movups   xmm0, xmmword ptr [rsp + 0xa4]
0000000140c015ce  0f108c24b0000000         movups   xmm1, xmmword ptr [rsp + 0xb0]
0000000140c015d6  0f114f0c                 movups   xmmword ptr [rdi + 0xc], xmm1
0000000140c015da  0f1107                   movups   xmmword ptr [rdi], xmm0
0000000140c015dd  837c246001               cmp      dword ptr [rsp + 0x60], 1
0000000140c015e2  0f85d8000000             jne      0x140c016c0
0000000140c015e8  f30f10442464             movss    xmm0, dword ptr [rsp + 0x64]
0000000140c015ee  f20f104c2468             movsd    xmm1, qword ptr [rsp + 0x68]
0000000140c015f4  f20f10542474             movsd    xmm2, qword ptr [rsp + 0x74]
0000000140c015fa  0f5cca                   subps    xmm1, xmm2
0000000140c015fd  f30f5c442470             subss    xmm0, dword ptr [rsp + 0x70]
0000000140c01603  f30f59c0                 mulss    xmm0, xmm0
0000000140c01607  0f59c9                   mulps    xmm1, xmm1
0000000140c0160a  f30f58c1                 addss    xmm0, xmm1
0000000140c0160e  f30f16c9                 movshdup xmm1, xmm1
0000000140c01612  f30f58c8                 addss    xmm1, xmm0
0000000140c01616  0f57f6                   xorps    xmm6, xmm6
0000000140c01619  f30f51f1                 sqrtss   xmm6, xmm1
0000000140c0161d  488b442450               mov      rax, qword ptr [rsp + 0x50]
0000000140c01622  483b442458               cmp      rax, qword ptr [rsp + 0x58]
0000000140c01627  0f8393000000             jae      0x140c016c0
0000000140c0162d  488d7c2470               lea      rdi, [rsp + 0x70]
0000000140c01632  488b5c2430               mov      rbx, qword ptr [rsp + 0x30]
0000000140c01637  4c8b742440               mov      r14, qword ptr [rsp + 0x40]
0000000140c0163c  0f1f4000                 nop      dword ptr [rax]
0000000140c01640  488d4801                 lea      rcx, [rax + 1]
0000000140c01644  48894c2450               mov      qword ptr [rsp + 0x50], rcx
0000000140c01649  488d14c3                 lea      rdx, [rbx + rax*8]
0000000140c0164d  f3410f101486             movss    xmm2, dword ptr [r14 + rax*4]
0000000140c01653  4889f1                   mov      rcx, rsi
0000000140c01656  e8e52e1f00               call     0x140df4540 ; utils::swizzlers::impl$1::xvy | _ZN71_$LT$glam..f32..vec2..Vec2$u20$as$u20$utils..swizzlers..SwizzlerXVY$GT$3xvy17hcb9aa753d52e64e7E
0000000140c0165b  c744242001000000         mov      dword ptr [rsp + 0x20], 1
0000000140c01663  f30f10442470             movss    xmm0, dword ptr [rsp + 0x70]
0000000140c01669  f20f104c2474             movsd    xmm1, qword ptr [rsp + 0x74]
0000000140c0166f  8b4608                   mov      eax, dword ptr [rsi + 8]
0000000140c01672  894708                   mov      dword ptr [rdi + 8], eax
0000000140c01675  488b06                   mov      rax, qword ptr [rsi]
0000000140c01678  488907                   mov      qword ptr [rdi], rax
0000000140c0167b  f30f11442464             movss    dword ptr [rsp + 0x64], xmm0
0000000140c01681  f20f114c2468             movsd    qword ptr [rsp + 0x68], xmm1
0000000140c01687  f30f5c442424             subss    xmm0, dword ptr [rsp + 0x24]
0000000140c0168d  f20f10542428             movsd    xmm2, qword ptr [rsp + 0x28]
0000000140c01693  0f5cca                   subps    xmm1, xmm2
0000000140c01696  f30f59c0                 mulss    xmm0, xmm0
0000000140c0169a  0f59c9                   mulps    xmm1, xmm1
0000000140c0169d  f30f58c1                 addss    xmm0, xmm1
0000000140c016a1  f30f16c9                 movshdup xmm1, xmm1
0000000140c016a5  f30f58c8                 addss    xmm1, xmm0
0000000140c016a9  0f57c0                   xorps    xmm0, xmm0
0000000140c016ac  f30f51c1                 sqrtss   xmm0, xmm1
0000000140c016b0  f30f58f0                 addss    xmm6, xmm0
0000000140c016b4  488b442450               mov      rax, qword ptr [rsp + 0x50]
0000000140c016b9  483b442458               cmp      rax, qword ptr [rsp + 0x58]
0000000140c016be  7280                     jb       0x140c01640
0000000140c016c0  0f28c6                   movaps   xmm0, xmm6
0000000140c016c3  0f28b424c0000000         movaps   xmm6, xmmword ptr [rsp + 0xc0]
0000000140c016cb  4881c4d8000000           add      rsp, 0xd8
0000000140c016d2  5b                       pop      rbx
0000000140c016d3  5f                       pop      rdi
0000000140c016d4  5e                       pop      rsi
0000000140c016d5  415e                     pop      r14
0000000140c016d7  c3                       ret      