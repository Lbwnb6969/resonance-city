0000000141483090  4157                     push     r15
0000000141483092  4156                     push     r14
0000000141483094  56                       push     rsi
0000000141483095  57                       push     rdi
0000000141483096  53                       push     rbx
0000000141483097  4883ec60                 sub      rsp, 0x60
000000014148309b  0f29742450               movaps   xmmword ptr [rsp + 0x50], xmm6
00000001414830a0  488b7210                 mov      rsi, qword ptr [rdx + 0x10]
00000001414830a4  4885f6                   test     rsi, rsi
00000001414830a7  7476                     je       0x14148311f
00000001414830a9  488b7a08                 mov      rdi, qword ptr [rdx + 8]
00000001414830ad  488d04b6                 lea      rax, [rsi + rsi*4]
00000001414830b1  4c8d3487                 lea      r14, [rdi + rax*4]
00000001414830b5  4c89f3                   mov      rbx, r14
00000001414830b8  4883c3ec                 add      rbx, -0x14
00000001414830bc  0f846f010000             je       0x141483231
00000001414830c2  f30f107218               movss    xmm6, dword ptr [rdx + 0x18]
00000001414830c7  807a1c00                 cmp      byte ptr [rdx + 0x1c], 0
00000001414830cb  745d                     je       0x14148312a
00000001414830cd  4989cf                   mov      r15, rcx
00000001414830d0  0f28c2                   movaps   xmm0, xmm2
00000001414830d3  0f28ce                   movaps   xmm1, xmm6
00000001414830d6  e895f99a01               call     0x142e32a70 ; fmodf
00000001414830db  0f2815fe469b01           movaps   xmm2, xmmword ptr [rip + 0x19b46fe]
00000001414830e2  0f54d6                   andps    xmm2, xmm6
00000001414830e5  f30f58d0                 addss    xmm2, xmm0
00000001414830e9  0f57db                   xorps    xmm3, xmm3
00000001414830ec  0f28c8                   movaps   xmm1, xmm0
00000001414830ef  f30fc2cb01               cmpltss  xmm1, xmm3
00000001414830f4  0f28d9                   movaps   xmm3, xmm1
00000001414830f7  0f55d8                   andnps   xmm3, xmm0
00000001414830fa  0f54ca                   andps    xmm1, xmm2
00000001414830fd  0f56cb                   orps     xmm1, xmm3
0000000141483100  f30f104708               movss    xmm0, dword ptr [rdi + 8]
0000000141483105  0f2ec1                   ucomiss  xmm0, xmm1
0000000141483108  0f8617010000             jbe      0x141483225
000000014148310e  f30f58ce                 addss    xmm1, xmm6
0000000141483112  4c89f9                   mov      rcx, r15
0000000141483115  0f2ec1                   ucomiss  xmm0, xmm1
0000000141483118  7235                     jb       0x14148314f
000000014148311a  e912010000               jmp      0x141483231
000000014148311f  c70100000000             mov      dword ptr [rcx], 0
0000000141483125  e956010000               jmp      0x141483280
000000014148312a  0f57c0                   xorps    xmm0, xmm0
000000014148312d  0f2ef0                   ucomiss  xmm6, xmm0
0000000141483130  0f8276010000             jb       0x1414832ac
0000000141483136  f30f5fc2                 maxss    xmm0, xmm2
000000014148313a  f30f5df0                 minss    xmm6, xmm0
000000014148313e  f30f104708               movss    xmm0, dword ptr [rdi + 8]
0000000141483143  0f28ce                   movaps   xmm1, xmm6
0000000141483146  0f2ec1                   ucomiss  xmm0, xmm1
0000000141483149  0f83e2000000             jae      0x141483231
000000014148314f  410f2e4ef4               ucomiss  xmm1, dword ptr [r14 - 0xc]
0000000141483154  0f8337010000             jae      0x141483291
000000014148315a  31c0                     xor      eax, eax
000000014148315c  4883fe01                 cmp      rsi, 1
0000000141483160  7431                     je       0x141483193
0000000141483162  4889f2                   mov      rdx, rsi
0000000141483165  66662e0f1f840000000000   nop      word ptr cs:[rax + rax]
0000000141483170  4989c0                   mov      r8, rax
0000000141483173  4989d1                   mov      r9, rdx
0000000141483176  49d1e9                   shr      r9, 1
0000000141483179  4c01c8                   add      rax, r9
000000014148317c  4c8d1480                 lea      r10, [rax + rax*4]
0000000141483180  420f2e4c9708             ucomiss  xmm1, dword ptr [rdi + r10*4 + 8]
0000000141483186  490f46c0                 cmovbe   rax, r8
000000014148318a  4c29ca                   sub      rdx, r9
000000014148318d  4883fa01                 cmp      rdx, 1
0000000141483191  77dd                     ja       0x141483170
0000000141483193  488d1480                 lea      rdx, [rax + rax*4]
0000000141483197  4531c0                   xor      r8d, r8d
000000014148319a  0f2e4c9708               ucomiss  xmm1, dword ptr [rdi + rdx*4 + 8]
000000014148319f  410f97c0                 seta     r8b
00000001414831a3  4a8d1400                 lea      rdx, [rax + r8]
00000001414831a7  48ffca                   dec      rdx
00000001414831aa  4839f2                   cmp      rdx, rsi
00000001414831ad  0f8344010000             jae      0x1414832f7
00000001414831b3  4c01c0                   add      rax, r8
00000001414831b6  4839f0                   cmp      rax, rsi
00000001414831b9  0f834a010000             jae      0x141483309
00000001414831bf  488d1492                 lea      rdx, [rdx + rdx*4]
00000001414831c3  f30f10449708             movss    xmm0, dword ptr [rdi + rdx*4 + 8]
00000001414831c9  4c8b0497                 mov      r8, qword ptr [rdi + rdx*4]
00000001414831cd  488d0480                 lea      rax, [rax + rax*4]
00000001414831d1  f30f10548708             movss    xmm2, dword ptr [rdi + rax*4 + 8]
00000001414831d7  488b44870c               mov      rax, qword ptr [rdi + rax*4 + 0xc]
00000001414831dc  f30f5cc8                 subss    xmm1, xmm0
00000001414831e0  4c894104                 mov      qword ptr [rcx + 4], r8
00000001414831e4  f30f11410c               movss    dword ptr [rcx + 0xc], xmm0
00000001414831e9  0f105c970c               movups   xmm3, xmmword ptr [rdi + rdx*4 + 0xc]
00000001414831ee  0f115910                 movups   xmmword ptr [rcx + 0x10], xmm3
00000001414831f2  f30f115120               movss    dword ptr [rcx + 0x20], xmm2
00000001414831f7  f30f5cd0                 subss    xmm2, xmm0
00000001414831fb  f30f5f15616bb801         maxss    xmm2, dword ptr [rip + 0x1b86b61]
0000000141483203  f30f5eca                 divss    xmm1, xmm2
0000000141483207  0f57c0                   xorps    xmm0, xmm0
000000014148320a  f30f5fc1                 maxss    xmm0, xmm1
000000014148320e  f30f100d123d9b01         movss    xmm1, dword ptr [rip + 0x19b3d12]
0000000141483216  f30f5dc8                 minss    xmm1, xmm0
000000014148321a  48894124                 mov      qword ptr [rcx + 0x24], rax
000000014148321e  f30f11492c               movss    dword ptr [rcx + 0x2c], xmm1
0000000141483223  eb55                     jmp      0x14148327a
0000000141483225  4c89f9                   mov      rcx, r15
0000000141483228  0f2ec1                   ucomiss  xmm0, xmm1
000000014148322b  0f821effffff             jb       0x14148314f
0000000141483231  8b4710                   mov      eax, dword ptr [rdi + 0x10]
0000000141483234  89442444                 mov      dword ptr [rsp + 0x44], eax
0000000141483238  0f1007                   movups   xmm0, xmmword ptr [rdi]
000000014148323b  0f11442434               movups   xmmword ptr [rsp + 0x34], xmm0
0000000141483240  8b4710                   mov      eax, dword ptr [rdi + 0x10]
0000000141483243  89442430                 mov      dword ptr [rsp + 0x30], eax
0000000141483247  0f1007                   movups   xmm0, xmmword ptr [rdi]
000000014148324a  0f29442420               movaps   xmmword ptr [rsp + 0x20], xmm0
000000014148324f  488b442440               mov      rax, qword ptr [rsp + 0x40]
0000000141483254  48894124                 mov      qword ptr [rcx + 0x24], rax
0000000141483258  0f114104                 movups   xmmword ptr [rcx + 4], xmm0
000000014148325c  8b442430                 mov      eax, dword ptr [rsp + 0x30]
0000000141483260  894114                   mov      dword ptr [rcx + 0x14], eax
0000000141483263  488b442434               mov      rax, qword ptr [rsp + 0x34]
0000000141483268  48894118                 mov      qword ptr [rcx + 0x18], rax
000000014148326c  8b44243c                 mov      eax, dword ptr [rsp + 0x3c]
0000000141483270  894120                   mov      dword ptr [rcx + 0x20], eax
0000000141483273  c7412c00000000           mov      dword ptr [rcx + 0x2c], 0
000000014148327a  c70101000000             mov      dword ptr [rcx], 1
0000000141483280  0f28742450               movaps   xmm6, xmmword ptr [rsp + 0x50]
0000000141483285  4883c460                 add      rsp, 0x60
0000000141483289  5b                       pop      rbx
000000014148328a  5f                       pop      rdi
000000014148328b  5e                       pop      rsi
000000014148328c  415e                     pop      r14
000000014148328e  415f                     pop      r15
0000000141483290  c3                       ret      
0000000141483291  8b4310                   mov      eax, dword ptr [rbx + 0x10]
0000000141483294  89442444                 mov      dword ptr [rsp + 0x44], eax
0000000141483298  0f1003                   movups   xmm0, xmmword ptr [rbx]
000000014148329b  0f11442434               movups   xmmword ptr [rsp + 0x34], xmm0
00000001414832a0  8b4310                   mov      eax, dword ptr [rbx + 0x10]
00000001414832a3  89442430                 mov      dword ptr [rsp + 0x30], eax
00000001414832a7  0f1003                   movups   xmm0, xmmword ptr [rbx]
00000001414832aa  eb9e                     jmp      0x14148324a
00000001414832ac  c744244800000000         mov      dword ptr [rsp + 0x48], 0
00000001414832b4  f30f1174244c             movss    dword ptr [rsp + 0x4c], xmm6
00000001414832ba  488d442448               lea      rax, [rsp + 0x48]
00000001414832bf  4889442420               mov      qword ptr [rsp + 0x20], rax
00000001414832c4  488d0505d3aeff           lea      rax, [rip - 0x512cfb]
00000001414832cb  4889442428               mov      qword ptr [rsp + 0x28], rax
00000001414832d0  488d4c244c               lea      rcx, [rsp + 0x4c]
00000001414832d5  48894c2430               mov      qword ptr [rsp + 0x30], rcx
00000001414832da  4889442438               mov      qword ptr [rsp + 0x38], rax
00000001414832df  488d0d1a9de801           lea      rcx, [rip + 0x1e89d1a]
00000001414832e6  4c8d05b39de801           lea      r8, [rip + 0x1e89db3]
00000001414832ed  488d542420               lea      rdx, [rsp + 0x20]
00000001414832f2  e8d9509401               call     0x142dc83d0 ; core::panicking::panic_fmt | _RNvNtCs8icZUrvfcq9_4core9panicking9panic_fmt
00000001414832f7  4c8d05129ee801           lea      r8, [rip + 0x1e89e12]
00000001414832fe  4889d1                   mov      rcx, rdx
0000000141483301  4889f2                   mov      rdx, rsi
0000000141483304  e8e94e9401               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
0000000141483309  4c8d05189ee801           lea      r8, [rip + 0x1e89e18]
0000000141483310  4889c1                   mov      rcx, rax
0000000141483313  4889f2                   mov      rdx, rsi
0000000141483316  e8d74e9401               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
000000014148331b  cc                       int3     