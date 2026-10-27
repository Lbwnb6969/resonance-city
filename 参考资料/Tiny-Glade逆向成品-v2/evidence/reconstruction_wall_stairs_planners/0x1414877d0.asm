00000001414877d0  55                       push     rbp
00000001414877d1  4157                     push     r15
00000001414877d3  4156                     push     r14
00000001414877d5  4155                     push     r13
00000001414877d7  4154                     push     r12
00000001414877d9  56                       push     rsi
00000001414877da  57                       push     rdi
00000001414877db  53                       push     rbx
00000001414877dc  4881ec58010000           sub      rsp, 0x158
00000001414877e3  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001414877eb  440f29adc0000000         movaps   xmmword ptr [rbp + 0xc0], xmm13
00000001414877f3  440f29a5b0000000         movaps   xmmword ptr [rbp + 0xb0], xmm12
00000001414877fb  440f299da0000000         movaps   xmmword ptr [rbp + 0xa0], xmm11
0000000141487803  440f299590000000         movaps   xmmword ptr [rbp + 0x90], xmm10
000000014148780b  440f298d80000000         movaps   xmmword ptr [rbp + 0x80], xmm9
0000000141487813  440f294570               movaps   xmmword ptr [rbp + 0x70], xmm8
0000000141487818  0f297d60                 movaps   xmmword ptr [rbp + 0x60], xmm7
000000014148781c  0f297550                 movaps   xmmword ptr [rbp + 0x50], xmm6
0000000141487820  48c74548feffffff         mov      qword ptr [rbp + 0x48], 0xfffffffffffffffe
0000000141487828  4c894d10                 mov      qword ptr [rbp + 0x10], r9
000000014148782c  48894db8                 mov      qword ptr [rbp - 0x48], rcx
0000000141487830  4c8b8d40010000           mov      r9, qword ptr [rbp + 0x140]
0000000141487837  0f108548010000           movups   xmm0, xmmword ptr [rbp + 0x148]
000000014148783e  c6454701                 mov      byte ptr [rbp + 0x47], 1
0000000141487842  0f11442420               movups   xmmword ptr [rsp + 0x20], xmm0
0000000141487847  488d4df0                 lea      rcx, [rbp - 0x10]
000000014148784b  e8c0caffff               call     0x141484310 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::remapped_wall_cutouts
0000000141487850  90                       nop      
0000000141487851  488b4df8                 mov      rcx, qword ptr [rbp - 8]
0000000141487855  488b5500                 mov      rdx, qword ptr [rbp]
0000000141487859  48894d38                 mov      qword ptr [rbp + 0x38], rcx
000000014148785d  4c8b4510                 mov      r8, qword ptr [rbp + 0x10]
0000000141487861  41b101                   mov      r9b, 1
0000000141487864  e8a7ceffff               call     0x141484710 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::subtract_wall_cutouts
0000000141487869  90                       nop      
000000014148786a  488b55f0                 mov      rdx, qword ptr [rbp - 0x10]
000000014148786e  4885d2                   test     rdx, rdx
0000000141487871  7413                     je       0x141487886
0000000141487873  48c1e204                 shl      rdx, 4
0000000141487877  41b804000000             mov      r8d, 4
000000014148787d  488b4d38                 mov      rcx, qword ptr [rbp + 0x38]
0000000141487881  e83a4222ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141487886  488b4510                 mov      rax, qword ptr [rbp + 0x10]
000000014148788a  488b08                   mov      rcx, qword ptr [rax]
000000014148788d  48894dd0                 mov      qword ptr [rbp - 0x30], rcx
0000000141487891  488b4808                 mov      rcx, qword ptr [rax + 8]
0000000141487895  48894dd8                 mov      qword ptr [rbp - 0x28], rcx
0000000141487899  488b5010                 mov      rdx, qword ptr [rax + 0x10]
000000014148789d  48c70000000000           mov      qword ptr [rax], 0
00000001414878a4  48c7400808000000         mov      qword ptr [rax + 8], 8
00000001414878ac  48c7401000000000         mov      qword ptr [rax + 0x10], 0
00000001414878b4  4885d2                   test     rdx, rdx
00000001414878b7  48895538                 mov      qword ptr [rbp + 0x38], rdx
00000001414878bb  7451                     je       0x14148790e
00000001414878bd  4889d7                   mov      rdi, rdx
00000001414878c0  e89b75bffe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
00000001414878c5  ba01000000               mov      edx, 1
00000001414878ca  4889f9                   mov      rcx, rdi
00000001414878cd  e80e4222ff               call     0x1406abae0 ; _RNvCsfLfy6EI15iL_7___rustc19___rust_alloc_zeroed
00000001414878d2  4885c0                   test     rax, rax
00000001414878d5  0f84d2040000             je       0x141487dad
00000001414878db  4889c3                   mov      rbx, rax
00000001414878de  488d04fd00000000         lea      rax, [rdi*8]
00000001414878e6  488d3c80                 lea      rdi, [rax + rax*4]
00000001414878ea  e87175bffe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
00000001414878ef  ba08000000               mov      edx, 8
00000001414878f4  4889f9                   mov      rcx, rdi
00000001414878f7  e8b44122ff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
00000001414878fc  4885c0                   test     rax, rax
00000001414878ff  0f84b8040000             je       0x141487dbd
0000000141487905  488b5538                 mov      rdx, qword ptr [rbp + 0x38]
0000000141487909  4989da                   mov      r10, rbx
000000014148790c  eb0b                     jmp      0x141487919
000000014148790e  b808000000               mov      eax, 8
0000000141487913  41ba01000000             mov      r10d, 1
0000000141487919  f30f10b558010000         movss    xmm6, dword ptr [rbp + 0x158]
0000000141487921  48895518                 mov      qword ptr [rbp + 0x18], rdx
0000000141487925  48894520                 mov      qword ptr [rbp + 0x20], rax
0000000141487929  48c7452800000000         mov      qword ptr [rbp + 0x28], 0
0000000141487931  488b45d8                 mov      rax, qword ptr [rbp - 0x28]
0000000141487935  4c8d40f9                 lea      r8, [rax - 7]
0000000141487939  4c8d7820                 lea      r15, [rax + 0x20]
000000014148793d  31db                     xor      ebx, ebx
000000014148793f  f30f103d29ff9a01         movss    xmm7, dword ptr [rip + 0x19aff29]
0000000141487947  440f280591fe9a01         movaps   xmm8, xmmword ptr [rip + 0x19afe91]
000000014148794f  f3440f100df0fe9a01       movss    xmm9, dword ptr [rip + 0x19afef0]
0000000141487958  488d7518                 lea      rsi, [rbp + 0x18]
000000014148795c  4531e4                   xor      r12d, r12d
000000014148795f  4c8955e0                 mov      qword ptr [rbp - 0x20], r10
0000000141487963  4b8d04a4                 lea      rax, [r12 + r12*4]
0000000141487967  498d04c0                 lea      rax, [r8 + rax*8]
000000014148796b  4c89e1                   mov      rcx, r12
000000014148796e  6690                     nop      
0000000141487970  4839d1                   cmp      rcx, rdx
0000000141487973  0f83d4020000             jae      0x141487c4d
0000000141487979  4c8d6101                 lea      r12, [rcx + 1]
000000014148797d  4883c028                 add      rax, 0x28
0000000141487981  41803c0a00               cmp      byte ptr [r10 + rcx], 0
0000000141487986  4c89e1                   mov      rcx, r12
0000000141487989  75e5                     jne      0x141487970
000000014148798b  4c8945c0                 mov      qword ptr [rbp - 0x40], r8
000000014148798f  43c64422ff01             mov      byte ptr [r10 + r12 - 1], 1
0000000141487995  4c8b68df                 mov      r13, qword ptr [rax - 0x21]
0000000141487999  488b78e7                 mov      rdi, qword ptr [rax - 0x19]
000000014148799d  f3440f1050ef             movss    xmm10, dword ptr [rax - 0x11]
00000001414879a3  f3440f1068f3             movss    xmm13, dword ptr [rax - 0xd]
00000001414879a9  f3440f1058f7             movss    xmm11, dword ptr [rax - 9]
00000001414879af  f3440f1060fb             movss    xmm12, dword ptr [rax - 5]
00000001414879b5  440fb670ff               movzx    r14d, byte ptr [rax - 1]
00000001414879ba  8b4803                   mov      ecx, dword ptr [rax + 3]
00000001414879bd  894deb                   mov      dword ptr [rbp - 0x15], ecx
00000001414879c0  8b00                     mov      eax, dword ptr [rax]
00000001414879c2  8945e8                   mov      dword ptr [rbp - 0x18], eax
00000001414879c5  31c0                     xor      eax, eax
00000001414879c7  31c9                     xor      ecx, ecx
00000001414879c9  41f6c501                 test     r13b, 1
00000001414879cd  0f851c010000             jne      0x141487aef
00000001414879d3  eb1a                     jmp      0x1414879ef
00000001414879d5  66662e0f1f840000000000   nop      word ptr cs:[rax + rax]
00000001414879e0  31c9                     xor      ecx, ecx
00000001414879e2  a801                     test     al, 1
00000001414879e4  b800000000               mov      eax, 0
00000001414879e9  0f84f1010000             je       0x141487be0
00000001414879ef  410f28c4                 movaps   xmm0, xmm12
00000001414879f3  f30f58c7                 addss    xmm0, xmm7
00000001414879f7  4c8d0489                 lea      r8, [rcx + rcx*4]
00000001414879fb  4f8d04c7                 lea      r8, [r15 + r8*8]
00000001414879ff  4989c9                   mov      r9, rcx
0000000141487a02  eb18                     jmp      0x141487a1c
0000000141487a04  6666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141487a10  49ffc1                   inc      r9
0000000141487a13  4983c028                 add      r8, 0x28
0000000141487a17  4939d1                   cmp      r9, rdx
0000000141487a1a  73c4                     jae      0x1414879e0
0000000141487a1c  4939d1                   cmp      r9, rdx
0000000141487a1f  0f8346030000             jae      0x141487d6b
0000000141487a25  43803c0a00               cmp      byte ptr [r10 + r9], 0
0000000141487a2a  75e4                     jne      0x141487a10
0000000141487a2c  41f640e001               test     byte ptr [r8 - 0x20], 1
0000000141487a31  75dd                     jne      0x141487a10
0000000141487a33  453830                   cmp      byte ptr [r8], r14b
0000000141487a36  75d8                     jne      0x141487a10
0000000141487a38  410f28ca                 movaps   xmm1, xmm10
0000000141487a3c  f3410f5c48f0             subss    xmm1, dword ptr [r8 - 0x10]
0000000141487a42  410f54c8                 andps    xmm1, xmm8
0000000141487a46  440f2ec9                 ucomiss  xmm9, xmm1
0000000141487a4a  72c4                     jb       0x141487a10
0000000141487a4c  410f28cb                 movaps   xmm1, xmm11
0000000141487a50  f3410f5c48f8             subss    xmm1, dword ptr [r8 - 8]
0000000141487a56  410f54c8                 andps    xmm1, xmm8
0000000141487a5a  440f2ec9                 ucomiss  xmm9, xmm1
0000000141487a5e  72b0                     jb       0x141487a10
0000000141487a60  f3410f1048fc             movss    xmm1, dword ptr [r8 - 4]
0000000141487a66  0f28d1                   movaps   xmm2, xmm1
0000000141487a69  f30f58d7                 addss    xmm2, xmm7
0000000141487a6d  410f2ed5                 ucomiss  xmm2, xmm13
0000000141487a71  729d                     jb       0x141487a10
0000000141487a73  f3410f1050f4             movss    xmm2, dword ptr [r8 - 0xc]
0000000141487a79  0f2ec2                   ucomiss  xmm0, xmm2
0000000141487a7c  7292                     jb       0x141487a10
0000000141487a7e  410f28c5                 movaps   xmm0, xmm13
0000000141487a82  f3410fc2c503             cmpunordss xmm0, xmm13
0000000141487a88  0f28d8                   movaps   xmm3, xmm0
0000000141487a8b  0f54da                   andps    xmm3, xmm2
0000000141487a8e  f3410f5dd5               minss    xmm2, xmm13
0000000141487a93  0f55c2                   andnps   xmm0, xmm2
0000000141487a96  0f56c3                   orps     xmm0, xmm3
0000000141487a99  410f28d4                 movaps   xmm2, xmm12
0000000141487a9d  f3410fc2d403             cmpunordss xmm2, xmm12
0000000141487aa3  0f28da                   movaps   xmm3, xmm2
0000000141487aa6  0f54d9                   andps    xmm3, xmm1
0000000141487aa9  f3410f5fcc               maxss    xmm1, xmm12
0000000141487aae  0f55d1                   andnps   xmm2, xmm1
0000000141487ab1  0f56d3                   orps     xmm2, xmm3
0000000141487ab4  43c6040a01               mov      byte ptr [r10 + r9], 1
0000000141487ab9  49ffc1                   inc      r9
0000000141487abc  b001                     mov      al, 1
0000000141487abe  4c89c9                   mov      rcx, r9
0000000141487ac1  440f28e8                 movaps   xmm13, xmm0
0000000141487ac5  440f28e2                 movaps   xmm12, xmm2
0000000141487ac9  4939d1                   cmp      r9, rdx
0000000141487acc  0f821dffffff             jb       0x1414879ef
0000000141487ad2  e909ffffff               jmp      0x1414879e0
0000000141487ad7  660f1f840000000000       nop      word ptr [rax + rax]
0000000141487ae0  31c9                     xor      ecx, ecx
0000000141487ae2  a801                     test     al, 1
0000000141487ae4  b800000000               mov      eax, 0
0000000141487ae9  0f84f1000000             je       0x141487be0
0000000141487aef  410f28c4                 movaps   xmm0, xmm12
0000000141487af3  f30f58c7                 addss    xmm0, xmm7
0000000141487af7  4c8d0489                 lea      r8, [rcx + rcx*4]
0000000141487afb  4f8d04c7                 lea      r8, [r15 + r8*8]
0000000141487aff  4989c9                   mov      r9, rcx
0000000141487b02  eb18                     jmp      0x141487b1c
0000000141487b04  6666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141487b10  49ffc1                   inc      r9
0000000141487b13  4983c028                 add      r8, 0x28
0000000141487b17  4939d1                   cmp      r9, rdx
0000000141487b1a  73c4                     jae      0x141487ae0
0000000141487b1c  4939d1                   cmp      r9, rdx
0000000141487b1f  0f8346020000             jae      0x141487d6b
0000000141487b25  43803c0a00               cmp      byte ptr [r10 + r9], 0
0000000141487b2a  75e4                     jne      0x141487b10
0000000141487b2c  498378e001               cmp      qword ptr [r8 - 0x20], 1
0000000141487b31  75dd                     jne      0x141487b10
0000000141487b33  493978e8                 cmp      qword ptr [r8 - 0x18], rdi
0000000141487b37  75d7                     jne      0x141487b10
0000000141487b39  453830                   cmp      byte ptr [r8], r14b
0000000141487b3c  75d2                     jne      0x141487b10
0000000141487b3e  410f28ca                 movaps   xmm1, xmm10
0000000141487b42  f3410f5c48f0             subss    xmm1, dword ptr [r8 - 0x10]
0000000141487b48  410f54c8                 andps    xmm1, xmm8
0000000141487b4c  440f2ec9                 ucomiss  xmm9, xmm1
0000000141487b50  72be                     jb       0x141487b10
0000000141487b52  410f28cb                 movaps   xmm1, xmm11
0000000141487b56  f3410f5c48f8             subss    xmm1, dword ptr [r8 - 8]
0000000141487b5c  410f54c8                 andps    xmm1, xmm8
0000000141487b60  440f2ec9                 ucomiss  xmm9, xmm1
0000000141487b64  72aa                     jb       0x141487b10
0000000141487b66  f3410f1048fc             movss    xmm1, dword ptr [r8 - 4]
0000000141487b6c  0f28d1                   movaps   xmm2, xmm1
0000000141487b6f  f30f58d7                 addss    xmm2, xmm7
0000000141487b73  410f2ed5                 ucomiss  xmm2, xmm13
0000000141487b77  7297                     jb       0x141487b10
0000000141487b79  f3410f1050f4             movss    xmm2, dword ptr [r8 - 0xc]
0000000141487b7f  0f2ec2                   ucomiss  xmm0, xmm2
0000000141487b82  728c                     jb       0x141487b10
0000000141487b84  410f28c5                 movaps   xmm0, xmm13
0000000141487b88  f3410fc2c503             cmpunordss xmm0, xmm13
0000000141487b8e  0f28d8                   movaps   xmm3, xmm0
0000000141487b91  0f54da                   andps    xmm3, xmm2
0000000141487b94  f3410f5dd5               minss    xmm2, xmm13
0000000141487b99  0f55c2                   andnps   xmm0, xmm2
0000000141487b9c  0f56c3                   orps     xmm0, xmm3
0000000141487b9f  410f28d4                 movaps   xmm2, xmm12
0000000141487ba3  f3410fc2d403             cmpunordss xmm2, xmm12
0000000141487ba9  0f28da                   movaps   xmm3, xmm2
0000000141487bac  0f54d9                   andps    xmm3, xmm1
0000000141487baf  f3410f5fcc               maxss    xmm1, xmm12
0000000141487bb4  0f55d1                   andnps   xmm2, xmm1
0000000141487bb7  0f56d3                   orps     xmm2, xmm3
0000000141487bba  43c6040a01               mov      byte ptr [r10 + r9], 1
0000000141487bbf  49ffc1                   inc      r9
0000000141487bc2  b001                     mov      al, 1
0000000141487bc4  4c89c9                   mov      rcx, r9
0000000141487bc7  440f28e8                 movaps   xmm13, xmm0
0000000141487bcb  440f28e2                 movaps   xmm12, xmm2
0000000141487bcf  4939d1                   cmp      r9, rdx
0000000141487bd2  0f8217ffffff             jb       0x141487aef
0000000141487bd8  e903ffffff               jmp      0x141487ae0
0000000141487bdd  0f1f00                   nop      dword ptr [rax]
0000000141487be0  488b5d28                 mov      rbx, qword ptr [rbp + 0x28]
0000000141487be4  483b5d18                 cmp      rbx, qword ptr [rbp + 0x18]
0000000141487be8  7509                     jne      0x141487bf3
0000000141487bea  4889f1                   mov      rcx, rsi
0000000141487bed  e8ee718f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
0000000141487bf2  90                       nop      
0000000141487bf3  488b4520                 mov      rax, qword ptr [rbp + 0x20]
0000000141487bf7  488d0c9b                 lea      rcx, [rbx + rbx*4]
0000000141487bfb  4c892cc8                 mov      qword ptr [rax + rcx*8], r13
0000000141487bff  48897cc808               mov      qword ptr [rax + rcx*8 + 8], rdi
0000000141487c04  f3440f1154c810           movss    dword ptr [rax + rcx*8 + 0x10], xmm10
0000000141487c0b  f3440f116cc814           movss    dword ptr [rax + rcx*8 + 0x14], xmm13
0000000141487c12  f3440f115cc818           movss    dword ptr [rax + rcx*8 + 0x18], xmm11
0000000141487c19  f3440f1164c81c           movss    dword ptr [rax + rcx*8 + 0x1c], xmm12
0000000141487c20  448874c820               mov      byte ptr [rax + rcx*8 + 0x20], r14b
0000000141487c25  8b55e8                   mov      edx, dword ptr [rbp - 0x18]
0000000141487c28  448b45eb                 mov      r8d, dword ptr [rbp - 0x15]
0000000141487c2c  8954c821                 mov      dword ptr [rax + rcx*8 + 0x21], edx
0000000141487c30  448944c824               mov      dword ptr [rax + rcx*8 + 0x24], r8d
0000000141487c35  48ffc3                   inc      rbx
0000000141487c38  48895d28                 mov      qword ptr [rbp + 0x28], rbx
0000000141487c3c  488b5538                 mov      rdx, qword ptr [rbp + 0x38]
0000000141487c40  4c8b55e0                 mov      r10, qword ptr [rbp - 0x20]
0000000141487c44  4c8b45c0                 mov      r8, qword ptr [rbp - 0x40]
0000000141487c48  e916fdffff               jmp      0x141487963
0000000141487c4d  488b7d20                 mov      rdi, qword ptr [rbp + 0x20]
0000000141487c51  488d4537                 lea      rax, [rbp + 0x37]
0000000141487c55  488945f0                 mov      qword ptr [rbp - 0x10], rax
0000000141487c59  4883fb02                 cmp      rbx, 2
0000000141487c5d  0f831e010000             jae      0x141487d81
0000000141487c63  488b4528                 mov      rax, qword ptr [rbp + 0x28]
0000000141487c67  48894500                 mov      qword ptr [rbp], rax
0000000141487c6b  0f104518                 movups   xmm0, xmmword ptr [rbp + 0x18]
0000000141487c6f  0f2945f0                 movaps   xmmword ptr [rbp - 0x10], xmm0
0000000141487c73  488b7d10                 mov      rdi, qword ptr [rbp + 0x10]
0000000141487c77  488b07                   mov      rax, qword ptr [rdi]
0000000141487c7a  4885c0                   test     rax, rax
0000000141487c7d  7417                     je       0x141487c96
0000000141487c7f  488b4f08                 mov      rcx, qword ptr [rdi + 8]
0000000141487c83  48c1e003                 shl      rax, 3
0000000141487c87  488d1480                 lea      rdx, [rax + rax*4]
0000000141487c8b  41b808000000             mov      r8d, 8
0000000141487c91  e82a3e22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141487c96  488b4500                 mov      rax, qword ptr [rbp]
0000000141487c9a  48894710                 mov      qword ptr [rdi + 0x10], rax
0000000141487c9e  0f2845f0                 movaps   xmm0, xmmword ptr [rbp - 0x10]
0000000141487ca2  0f1107                   movups   xmmword ptr [rdi], xmm0
0000000141487ca5  488b5538                 mov      rdx, qword ptr [rbp + 0x38]
0000000141487ca9  4885d2                   test     rdx, rdx
0000000141487cac  740f                     je       0x141487cbd
0000000141487cae  41b801000000             mov      r8d, 1
0000000141487cb4  488b4de0                 mov      rcx, qword ptr [rbp - 0x20]
0000000141487cb8  e8033e22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141487cbd  488b45d0                 mov      rax, qword ptr [rbp - 0x30]
0000000141487cc1  4885c0                   test     rax, rax
0000000141487cc4  7417                     je       0x141487cdd
0000000141487cc6  48c1e003                 shl      rax, 3
0000000141487cca  488d1480                 lea      rdx, [rax + rax*4]
0000000141487cce  41b808000000             mov      r8d, 8
0000000141487cd4  488b4dd8                 mov      rcx, qword ptr [rbp - 0x28]
0000000141487cd8  e8e33d22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141487cdd  488b4d10                 mov      rcx, qword ptr [rbp + 0x10]
0000000141487ce1  488b4110                 mov      rax, qword ptr [rcx + 0x10]
0000000141487ce5  48894500                 mov      qword ptr [rbp], rax
0000000141487ce9  0f1001                   movups   xmm0, xmmword ptr [rcx]
0000000141487cec  0f2945f0                 movaps   xmmword ptr [rbp - 0x10], xmm0
0000000141487cf0  c6454700                 mov      byte ptr [rbp + 0x47], 0
0000000141487cf4  488d4d18                 lea      rcx, [rbp + 0x18]
0000000141487cf8  488d55f0                 lea      rdx, [rbp - 0x10]
0000000141487cfc  0f28d6                   movaps   xmm2, xmm6
0000000141487cff  e80cb7fcff               call     0x141453410 ; _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards39subdivide_wallspace_regions_into_planks17h46e4b1346c15c37aE | system_wall_constructor::construct_wooden_walls::construct_wall_boards::subdivide_wallspace_regions_into_planks<system_wall_constructor::construct_wooden_walls::construct_wall_boards::plan_horizontal_wall_boards::closure_env$0>
0000000141487d04  90                       nop      
0000000141487d05  488d4d18                 lea      rcx, [rbp + 0x18]
0000000141487d09  e8d20e0000               call     0x141488be0 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::merge_narrow_planks_horizontal
0000000141487d0e  90                       nop      
0000000141487d0f  488b4d28                 mov      rcx, qword ptr [rbp + 0x28]
0000000141487d13  488b45b8                 mov      rax, qword ptr [rbp - 0x48]
0000000141487d17  48894810                 mov      qword ptr [rax + 0x10], rcx
0000000141487d1b  0f104518                 movups   xmm0, xmmword ptr [rbp + 0x18]
0000000141487d1f  0f1100                   movups   xmmword ptr [rax], xmm0
0000000141487d22  0f287550                 movaps   xmm6, xmmword ptr [rbp + 0x50]
0000000141487d26  0f287d60                 movaps   xmm7, xmmword ptr [rbp + 0x60]
0000000141487d2a  440f284570               movaps   xmm8, xmmword ptr [rbp + 0x70]
0000000141487d2f  440f288d80000000         movaps   xmm9, xmmword ptr [rbp + 0x80]
0000000141487d37  440f289590000000         movaps   xmm10, xmmword ptr [rbp + 0x90]
0000000141487d3f  440f289da0000000         movaps   xmm11, xmmword ptr [rbp + 0xa0]
0000000141487d47  440f28a5b0000000         movaps   xmm12, xmmword ptr [rbp + 0xb0]
0000000141487d4f  440f28adc0000000         movaps   xmm13, xmmword ptr [rbp + 0xc0]
0000000141487d57  4881c458010000           add      rsp, 0x158
0000000141487d5e  5b                       pop      rbx
0000000141487d5f  5f                       pop      rdi
0000000141487d60  5e                       pop      rsi
0000000141487d61  415c                     pop      r12
0000000141487d63  415d                     pop      r13
0000000141487d65  415e                     pop      r14
0000000141487d67  415f                     pop      r15
0000000141487d69  5d                       pop      rbp
0000000141487d6a  c3                       ret      
0000000141487d6b  4839d1                   cmp      rcx, rdx
0000000141487d6e  480f46ca                 cmovbe   rcx, rdx
0000000141487d72  4c8d05df54e801           lea      r8, [rip + 0x1e854df]
0000000141487d79  e874049401               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
0000000141487d7e  90                       nop      
0000000141487d7f  eb4e                     jmp      0x141487dcf
0000000141487d81  4883fb15                 cmp      rbx, 0x15
0000000141487d85  734a                     jae      0x141487dd1
0000000141487d87  488d049b                 lea      rax, [rbx + rbx*4]
0000000141487d8b  4c8d34c7                 lea      r14, [rdi + rax*8]
0000000141487d8f  488d5f28                 lea      rbx, [rdi + 0x28]
0000000141487d93  4889f9                   mov      rcx, rdi
0000000141487d96  4889da                   mov      rdx, rbx
0000000141487d99  e84233fdff               call     0x14145b0e0 ; _ZN4core5slice4sort6shared9smallsort11insert_tail17h5e16c08b2baa4f9bE.llvm.7236408601036147505 | _ZN4core5slice4sort6shared9smallsort11insert_tail17h7b700fd9418c4a76E.llvm.7236408601036147505
0000000141487d9e  90                       nop      
0000000141487d9f  4883c328                 add      rbx, 0x28
0000000141487da3  4c39f3                   cmp      rbx, r14
0000000141487da6  75eb                     jne      0x141487d93
0000000141487da8  e9b6feffff               jmp      0x141487c63
0000000141487dad  b901000000               mov      ecx, 1
0000000141487db2  4889fa                   mov      rdx, rdi
0000000141487db5  e870009401               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
0000000141487dba  90                       nop      
0000000141487dbb  eb12                     jmp      0x141487dcf
0000000141487dbd  48895dc8                 mov      qword ptr [rbp - 0x38], rbx
0000000141487dc1  b908000000               mov      ecx, 8
0000000141487dc6  4889fa                   mov      rdx, rdi
0000000141487dc9  e85c009401               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
0000000141487dce  90                       nop      
0000000141487dcf  0f0b                     ud2      
0000000141487dd1  4c8d45f0                 lea      r8, [rbp - 0x10]
0000000141487dd5  4889f9                   mov      rcx, rdi
0000000141487dd8  4889da                   mov      rdx, rbx
0000000141487ddb  e820d6fdff               call     0x141465400 ; _ZN4core5slice4sort6stable14driftsort_main17h05dedffe9a33190eE | _ZN4core5slice4sort6stable14driftsort_main17h6919b7a8be3b8545E
0000000141487de0  90                       nop      
0000000141487de1  e97dfeffff               jmp      0x141487c63
0000000141487de6  662e0f1f840000000000     nop      word ptr cs:[rax + rax]
0000000141487df0  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141487df5  55                       push     rbp
0000000141487df6  4157                     push     r15
0000000141487df8  4156                     push     r14
0000000141487dfa  4155                     push     r13
0000000141487dfc  4154                     push     r12
0000000141487dfe  56                       push     rsi
0000000141487dff  57                       push     rdi
0000000141487e00  53                       push     rbx
0000000141487e01  4881ecb8000000           sub      rsp, 0xb8
0000000141487e08  488daa80000000           lea      rbp, [rdx + 0x80]
0000000141487e0f  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
0000000141487e15  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
0000000141487e1b  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
0000000141487e21  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
0000000141487e27  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
0000000141487e2d  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
0000000141487e36  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
0000000141487e3e  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
0000000141487e46  488b55f0                 mov      rdx, qword ptr [rbp - 0x10]
0000000141487e4a  4885d2                   test     rdx, rdx
0000000141487e4d  7413                     je       0x141487e62
0000000141487e4f  48c1e204                 shl      rdx, 4
0000000141487e53  41b804000000             mov      r8d, 4
0000000141487e59  488b4d38                 mov      rcx, qword ptr [rbp + 0x38]
0000000141487e5d  e85e3c22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141487e62  c6454701                 mov      byte ptr [rbp + 0x47], 1
0000000141487e66  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
0000000141487e6e  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
0000000141487e76  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
0000000141487e7f  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
0000000141487e85  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
0000000141487e8b  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
0000000141487e91  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
0000000141487e97  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
0000000141487e9d  4881c4b8000000           add      rsp, 0xb8
0000000141487ea4  5b                       pop      rbx
0000000141487ea5  5f                       pop      rdi
0000000141487ea6  5e                       pop      rsi
0000000141487ea7  415c                     pop      r12
0000000141487ea9  415d                     pop      r13
0000000141487eab  415e                     pop      r14
0000000141487ead  415f                     pop      r15
0000000141487eaf  5d                       pop      rbp
0000000141487eb0  c3                       ret      
0000000141487eb1  6666666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141487ec0  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141487ec5  55                       push     rbp
0000000141487ec6  4157                     push     r15
0000000141487ec8  4156                     push     r14
0000000141487eca  4155                     push     r13
0000000141487ecc  4154                     push     r12
0000000141487ece  56                       push     rsi
0000000141487ecf  57                       push     rdi
0000000141487ed0  53                       push     rbx
0000000141487ed1  4881ecb8000000           sub      rsp, 0xb8
0000000141487ed8  488daa80000000           lea      rbp, [rdx + 0x80]
0000000141487edf  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
0000000141487ee5  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
0000000141487eeb  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
0000000141487ef1  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
0000000141487ef7  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
0000000141487efd  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
0000000141487f06  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
0000000141487f0e  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
0000000141487f16  488b45d0                 mov      rax, qword ptr [rbp - 0x30]
0000000141487f1a  4885c0                   test     rax, rax
0000000141487f1d  7417                     je       0x141487f36
0000000141487f1f  48c1e003                 shl      rax, 3
0000000141487f23  488d1480                 lea      rdx, [rax + rax*4]
0000000141487f27  41b808000000             mov      r8d, 8
0000000141487f2d  488b4dd8                 mov      rcx, qword ptr [rbp - 0x28]
0000000141487f31  e88a3b22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141487f36  c6454701                 mov      byte ptr [rbp + 0x47], 1
0000000141487f3a  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
0000000141487f42  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
0000000141487f4a  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
0000000141487f53  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
0000000141487f59  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
0000000141487f5f  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
0000000141487f65  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
0000000141487f6b  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
0000000141487f71  4881c4b8000000           add      rsp, 0xb8
0000000141487f78  5b                       pop      rbx
0000000141487f79  5f                       pop      rdi
0000000141487f7a  5e                       pop      rsi
0000000141487f7b  415c                     pop      r12
0000000141487f7d  415d                     pop      r13
0000000141487f7f  415e                     pop      r14
0000000141487f81  415f                     pop      r15
0000000141487f83  5d                       pop      rbp
0000000141487f84  c3                       ret      
0000000141487f85  66662e0f1f840000000000   nop      word ptr cs:[rax + rax]
0000000141487f90  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141487f95  55                       push     rbp
0000000141487f96  4157                     push     r15
0000000141487f98  4156                     push     r14
0000000141487f9a  4155                     push     r13
0000000141487f9c  4154                     push     r12
0000000141487f9e  56                       push     rsi
0000000141487f9f  57                       push     rdi
0000000141487fa0  53                       push     rbx
0000000141487fa1  4881ecb8000000           sub      rsp, 0xb8
0000000141487fa8  488daa80000000           lea      rbp, [rdx + 0x80]
0000000141487faf  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
0000000141487fb5  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
0000000141487fbb  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
0000000141487fc1  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
0000000141487fc7  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
0000000141487fcd  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
0000000141487fd6  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
0000000141487fde  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
0000000141487fe6  488b5538                 mov      rdx, qword ptr [rbp + 0x38]
0000000141487fea  4885d2                   test     rdx, rdx
0000000141487fed  740f                     je       0x141487ffe
0000000141487fef  488b4dc8                 mov      rcx, qword ptr [rbp - 0x38]
0000000141487ff3  41b801000000             mov      r8d, 1
0000000141487ff9  e8c23a22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141487ffe  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
0000000141488006  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
000000014148800e  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
0000000141488017  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
000000014148801d  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
0000000141488023  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
0000000141488029  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
000000014148802f  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
0000000141488035  4881c4b8000000           add      rsp, 0xb8
000000014148803c  5b                       pop      rbx
000000014148803d  5f                       pop      rdi
000000014148803e  5e                       pop      rsi
000000014148803f  415c                     pop      r12
0000000141488041  415d                     pop      r13
0000000141488043  415e                     pop      r14
0000000141488045  415f                     pop      r15
0000000141488047  5d                       pop      rbp
0000000141488048  c3                       ret      
0000000141488049  0f1f8000000000           nop      dword ptr [rax]
0000000141488050  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141488055  55                       push     rbp
0000000141488056  4157                     push     r15
0000000141488058  4156                     push     r14
000000014148805a  4155                     push     r13
000000014148805c  4154                     push     r12
000000014148805e  56                       push     rsi
000000014148805f  57                       push     rdi
0000000141488060  53                       push     rbx
0000000141488061  4881ecb8000000           sub      rsp, 0xb8
0000000141488068  488daa80000000           lea      rbp, [rdx + 0x80]
000000014148806f  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
0000000141488075  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
000000014148807b  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
0000000141488081  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
0000000141488087  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
000000014148808d  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
0000000141488096  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
000000014148809e  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
00000001414880a6  488b4518                 mov      rax, qword ptr [rbp + 0x18]
00000001414880aa  4885c0                   test     rax, rax
00000001414880ad  7417                     je       0x1414880c6
00000001414880af  488b4d20                 mov      rcx, qword ptr [rbp + 0x20]
00000001414880b3  48c1e003                 shl      rax, 3
00000001414880b7  488d1480                 lea      rdx, [rax + rax*4]
00000001414880bb  41b808000000             mov      r8d, 8
00000001414880c1  e8fa3922ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001414880c6  488b45e0                 mov      rax, qword ptr [rbp - 0x20]
00000001414880ca  488945c8                 mov      qword ptr [rbp - 0x38], rax
00000001414880ce  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
00000001414880d6  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
00000001414880de  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
00000001414880e7  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
00000001414880ed  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
00000001414880f3  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
00000001414880f9  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
00000001414880ff  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
0000000141488105  4881c4b8000000           add      rsp, 0xb8
000000014148810c  5b                       pop      rbx
000000014148810d  5f                       pop      rdi
000000014148810e  5e                       pop      rsi
000000014148810f  415c                     pop      r12
0000000141488111  415d                     pop      r13
0000000141488113  415e                     pop      r14
0000000141488115  415f                     pop      r15
0000000141488117  5d                       pop      rbp
0000000141488118  c3                       ret      
0000000141488119  0f1f8000000000           nop      dword ptr [rax]
0000000141488120  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141488125  55                       push     rbp
0000000141488126  4157                     push     r15
0000000141488128  4156                     push     r14
000000014148812a  4155                     push     r13
000000014148812c  4154                     push     r12
000000014148812e  56                       push     rsi
000000014148812f  57                       push     rdi
0000000141488130  53                       push     rbx
0000000141488131  4881ecb8000000           sub      rsp, 0xb8
0000000141488138  488daa80000000           lea      rbp, [rdx + 0x80]
000000014148813f  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
0000000141488145  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
000000014148814b  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
0000000141488151  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
0000000141488157  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
000000014148815d  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
0000000141488166  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
000000014148816e  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
0000000141488176  488b4518                 mov      rax, qword ptr [rbp + 0x18]
000000014148817a  4885c0                   test     rax, rax
000000014148817d  7417                     je       0x141488196
000000014148817f  488b4d20                 mov      rcx, qword ptr [rbp + 0x20]
0000000141488183  48c1e003                 shl      rax, 3
0000000141488187  488d1480                 lea      rdx, [rax + rax*4]
000000014148818b  41b808000000             mov      r8d, 8
0000000141488191  e82a3922ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141488196  c6454700                 mov      byte ptr [rbp + 0x47], 0
000000014148819a  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
00000001414881a2  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
00000001414881aa  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
00000001414881b3  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
00000001414881b9  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
00000001414881bf  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
00000001414881c5  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
00000001414881cb  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
00000001414881d1  4881c4b8000000           add      rsp, 0xb8
00000001414881d8  5b                       pop      rbx
00000001414881d9  5f                       pop      rdi
00000001414881da  5e                       pop      rsi
00000001414881db  415c                     pop      r12
00000001414881dd  415d                     pop      r13
00000001414881df  415e                     pop      r14
00000001414881e1  415f                     pop      r15
00000001414881e3  5d                       pop      rbp
00000001414881e4  c3                       ret      
00000001414881e5  66662e0f1f840000000000   nop      word ptr cs:[rax + rax]
00000001414881f0  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001414881f5  55                       push     rbp
00000001414881f6  4157                     push     r15
00000001414881f8  4156                     push     r14
00000001414881fa  4155                     push     r13
00000001414881fc  4154                     push     r12
00000001414881fe  56                       push     rsi
00000001414881ff  57                       push     rdi
0000000141488200  53                       push     rbx
0000000141488201  4881ecb8000000           sub      rsp, 0xb8
0000000141488208  488daa80000000           lea      rbp, [rdx + 0x80]
000000014148820f  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
0000000141488215  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
000000014148821b  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
0000000141488221  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
0000000141488227  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
000000014148822d  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
0000000141488236  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
000000014148823e  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
0000000141488246  807d4700                 cmp      byte ptr [rbp + 0x47], 0
000000014148824a  488b4d10                 mov      rcx, qword ptr [rbp + 0x10]
000000014148824e  741f                     je       0x14148826f
0000000141488250  488b01                   mov      rax, qword ptr [rcx]
0000000141488253  4885c0                   test     rax, rax
0000000141488256  7417                     je       0x14148826f
0000000141488258  488b4908                 mov      rcx, qword ptr [rcx + 8]
000000014148825c  48c1e003                 shl      rax, 3
0000000141488260  488d1480                 lea      rdx, [rax + rax*4]
0000000141488264  41b808000000             mov      r8d, 8
000000014148826a  e8513822ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148826f  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
0000000141488277  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
000000014148827f  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
0000000141488288  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
000000014148828e  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
0000000141488294  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
000000014148829a  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
00000001414882a0  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
00000001414882a6  4881c4b8000000           add      rsp, 0xb8
00000001414882ad  5b                       pop      rbx
00000001414882ae  5f                       pop      rdi
00000001414882af  5e                       pop      rsi
00000001414882b0  415c                     pop      r12
00000001414882b2  415d                     pop      r13
00000001414882b4  415e                     pop      r14
00000001414882b6  415f                     pop      r15
00000001414882b8  5d                       pop      rbp
00000001414882b9  c3                       ret      