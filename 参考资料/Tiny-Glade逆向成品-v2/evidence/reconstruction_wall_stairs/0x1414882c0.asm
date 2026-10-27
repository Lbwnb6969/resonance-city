00000001414882c0  55                       push     rbp
00000001414882c1  4157                     push     r15
00000001414882c3  4156                     push     r14
00000001414882c5  4155                     push     r13
00000001414882c7  4154                     push     r12
00000001414882c9  56                       push     rsi
00000001414882ca  57                       push     rdi
00000001414882cb  53                       push     rbx
00000001414882cc  4881ec28010000           sub      rsp, 0x128
00000001414882d3  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001414882db  440f29bd90000000         movaps   xmmword ptr [rbp + 0x90], xmm15
00000001414882e3  440f29b580000000         movaps   xmmword ptr [rbp + 0x80], xmm14
00000001414882eb  66440f7f6d70             movdqa   xmmword ptr [rbp + 0x70], xmm13
00000001414882f1  66440f7f6560             movdqa   xmmword ptr [rbp + 0x60], xmm12
00000001414882f7  66440f7f5d50             movdqa   xmmword ptr [rbp + 0x50], xmm11
00000001414882fd  440f295540               movaps   xmmword ptr [rbp + 0x40], xmm10
0000000141488302  440f294d30               movaps   xmmword ptr [rbp + 0x30], xmm9
0000000141488307  440f294520               movaps   xmmword ptr [rbp + 0x20], xmm8
000000014148830c  0f297d10                 movaps   xmmword ptr [rbp + 0x10], xmm7
0000000141488310  0f297500                 movaps   xmmword ptr [rbp], xmm6
0000000141488314  48c745f8feffffff         mov      qword ptr [rbp - 8], 0xfffffffffffffffe
000000014148831c  4d89ce                   mov      r14, r9
000000014148831f  4c89c3                   mov      rbx, r8
0000000141488322  4889d7                   mov      rdi, rdx
0000000141488325  4889ce                   mov      rsi, rcx
0000000141488328  488b8518010000           mov      rax, qword ptr [rbp + 0x118]
000000014148832f  f3440f104810             movss    xmm9, dword ptr [rax + 0x10]
0000000141488335  f3440f105014             movss    xmm10, dword ptr [rax + 0x14]
000000014148833b  e8206bbffe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
0000000141488340  b910000000               mov      ecx, 0x10
0000000141488345  ba04000000               mov      edx, 4
000000014148834a  e8613722ff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
000000014148834f  4885c0                   test     rax, rax
0000000141488352  0f8471030000             je       0x1414886c9
0000000141488358  488975a0                 mov      qword ptr [rbp - 0x60], rsi
000000014148835c  0fb6b510010000           movzx    esi, byte ptr [rbp + 0x110]
0000000141488363  f30f100569f79a01         movss    xmm0, dword ptr [rip + 0x19af769]
000000014148836b  f3440f5fc8               maxss    xmm9, xmm0
0000000141488370  f3440f5fd0               maxss    xmm10, xmm0
0000000141488375  410f1006                 movups   xmm0, xmmword ptr [r14]
0000000141488379  0f1100                   movups   xmmword ptr [rax], xmm0
000000014148837c  48c745e001000000         mov      qword ptr [rbp - 0x20], 1
0000000141488384  488945e8                 mov      qword ptr [rbp - 0x18], rax
0000000141488388  48c745b800000000         mov      qword ptr [rbp - 0x48], 0
0000000141488390  48c745c004000000         mov      qword ptr [rbp - 0x40], 4
0000000141488398  48c745c800000000         mov      qword ptr [rbp - 0x38], 0
00000001414883a0  4c69eb43420f00           imul     r13, rbx, 0xf4243
00000001414883a7  41be01000000             mov      r14d, 1
00000001414883ad  488d5dd0                 lea      rbx, [rbp - 0x30]
00000001414883b1  4c8d65e0                 lea      r12, [rbp - 0x20]
00000001414883b5  f3440f103dcaf59a01       movss    xmm15, dword ptr [rip + 0x19af5ca]
00000001414883be  eb27                     jmp      0x1414883e7
00000001414883c0  488b45c0                 mov      rax, qword ptr [rbp - 0x40]
00000001414883c4  4c89f1                   mov      rcx, r14
00000001414883c7  48c1e104                 shl      rcx, 4
00000001414883cb  0f2845d0                 movaps   xmm0, xmmword ptr [rbp - 0x30]
00000001414883cf  0f110408                 movups   xmmword ptr [rax + rcx], xmm0
00000001414883d3  49ffc6                   inc      r14
00000001414883d6  4c8975c8                 mov      qword ptr [rbp - 0x38], r14
00000001414883da  4c8b75f0                 mov      r14, qword ptr [rbp - 0x10]
00000001414883de  4d85f6                   test     r14, r14
00000001414883e1  0f8466020000             je       0x14148864d
00000001414883e7  49ffce                   dec      r14
00000001414883ea  4c8975f0                 mov      qword ptr [rbp - 0x10], r14
00000001414883ee  488b45e8                 mov      rax, qword ptr [rbp - 0x18]
00000001414883f2  49c1e604                 shl      r14, 4
00000001414883f6  420f100430               movups   xmm0, xmmword ptr [rax + r14]
00000001414883fb  0f2945d0                 movaps   xmmword ptr [rbp - 0x30], xmm0
00000001414883ff  4084f6                   test     sil, sil
0000000141488402  0f84f8000000             je       0x141488500
0000000141488408  4889d9                   mov      rcx, rbx
000000014148840b  e8006896ff               call     0x140deec10 ; utils::geometry::aabb::Aabb2::width | _ZN5utils8geometry4aabb5Aabb25width17he30e90b5e741e6fbE
0000000141488410  90                       nop      
0000000141488411  0f28f0                   movaps   xmm6, xmm0
0000000141488414  440f2ed0                 ucomiss  xmm10, xmm0
0000000141488418  0f83f2010000             jae      0x141488610
000000014148841e  66440f6e65d0             movd     xmm12, dword ptr [rbp - 0x30]
0000000141488424  66440f6e5dd8             movd     xmm11, dword ptr [rbp - 0x28]
000000014148842a  48897db0                 mov      qword ptr [rbp - 0x50], rdi
000000014148842e  488d4db0                 lea      rcx, [rbp - 0x50]
0000000141488432  e839d5e8fe               call     0x140315970 ; motomoto::impl$0::as_tag | cmsPipelineGetPtrToFirstStage
0000000141488437  90                       nop      
0000000141488438  66440f7ee1               movd     ecx, xmm12
000000014148843d  4869c96f0c0100           imul     rcx, rcx, 0x10c6f
0000000141488444  66440f7eda               movd     edx, xmm11
0000000141488449  4869d2fb7c0100           imul     rdx, rdx, 0x17cfb
0000000141488450  4831ca                   xor      rdx, rcx
0000000141488453  4c31e8                   xor      rax, r13
0000000141488456  4831d0                   xor      rax, rdx
0000000141488459  488945a8                 mov      qword ptr [rbp - 0x58], rax
000000014148845d  488d4da8                 lea      rcx, [rbp - 0x58]
0000000141488461  e81aa497ff               call     0x140e02880 ; fastrand::Rng::f32 | _ZN8fastrand3Rng3f3217h74c3355474b41115E
0000000141488466  90                       nop      
0000000141488467  440f28c0                 movaps   xmm8, xmm0
000000014148846b  f3440f1035b4ea9a01       movss    xmm14, dword ptr [rip + 0x19aeab4]
0000000141488474  f3440f5cf0               subss    xmm14, xmm0
0000000141488479  f3440f593586419b01       mulss    xmm14, dword ptr [rip + 0x19b4186]
0000000141488482  f3440f5905858bb801       mulss    xmm8, dword ptr [rip + 0x1b88b85]
000000014148848b  66440f6e6dd4             movd     xmm13, dword ptr [rbp - 0x2c]
0000000141488491  f30f107ddc               movss    xmm7, dword ptr [rbp - 0x24]
0000000141488496  4c8b75f0                 mov      r14, qword ptr [rbp - 0x10]
000000014148849a  4c3b75e0                 cmp      r14, qword ptr [rbp - 0x20]
000000014148849e  7509                     jne      0x1414884a9
00000001414884a0  4c89e1                   mov      rcx, r12
00000001414884a3  e8886a8f01               call     0x142d7ef30 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h0a1121fd623a8175E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h23a8d3e913216895E
00000001414884a8  90                       nop      
00000001414884a9  f3450f58c6               addss    xmm8, xmm14
00000001414884ae  f3410f59f0               mulss    xmm6, xmm8
00000001414884b3  f3410f58f4               addss    xmm6, xmm12
00000001414884b8  488b45e8                 mov      rax, qword ptr [rbp - 0x18]
00000001414884bc  4c89f1                   mov      rcx, r14
00000001414884bf  48c1e104                 shl      rcx, 4
00000001414884c3  f30f113408               movss    dword ptr [rax + rcx], xmm6
00000001414884c8  66440f7e6c0804           movd     dword ptr [rax + rcx + 4], xmm13
00000001414884cf  66440f7e5c0808           movd     dword ptr [rax + rcx + 8], xmm11
00000001414884d6  f30f117c080c             movss    dword ptr [rax + rcx + 0xc], xmm7
00000001414884dc  4d8d7e01                 lea      r15, [r14 + 1]
00000001414884e0  4c897df0                 mov      qword ptr [rbp - 0x10], r15
00000001414884e4  4c3b7de0                 cmp      r15, qword ptr [rbp - 0x20]
00000001414884e8  0f85e6000000             jne      0x1414885d4
00000001414884ee  4c89e1                   mov      rcx, r12
00000001414884f1  e83a6a8f01               call     0x142d7ef30 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h0a1121fd623a8175E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h23a8d3e913216895E
00000001414884f6  90                       nop      
00000001414884f7  e9d8000000               jmp      0x1414885d4
00000001414884fc  0f1f4000                 nop      dword ptr [rax]
0000000141488500  4889d9                   mov      rcx, rbx
0000000141488503  e8486796ff               call     0x140deec50 ; utils::geometry::aabb::Aabb2::height | _ZN5utils8geometry4aabb5Aabb26height17h160a2c40e4ab2359E
0000000141488508  90                       nop      
0000000141488509  0f28f8                   movaps   xmm7, xmm0
000000014148850c  440f2ec8                 ucomiss  xmm9, xmm0
0000000141488510  0f831a010000             jae      0x141488630
0000000141488516  66440f6e6dd4             movd     xmm13, dword ptr [rbp - 0x2c]
000000014148851c  66440f6e5ddc             movd     xmm11, dword ptr [rbp - 0x24]
0000000141488522  48897db0                 mov      qword ptr [rbp - 0x50], rdi
0000000141488526  488d4db0                 lea      rcx, [rbp - 0x50]
000000014148852a  e841d4e8fe               call     0x140315970 ; motomoto::impl$0::as_tag | cmsPipelineGetPtrToFirstStage
000000014148852f  90                       nop      
0000000141488530  66440f7ee9               movd     ecx, xmm13
0000000141488535  4869c96f0c0100           imul     rcx, rcx, 0x10c6f
000000014148853c  66440f7eda               movd     edx, xmm11
0000000141488541  4869d2fb7c0100           imul     rdx, rdx, 0x17cfb
0000000141488548  4831ca                   xor      rdx, rcx
000000014148854b  4c31e8                   xor      rax, r13
000000014148854e  4831d0                   xor      rax, rdx
0000000141488551  488945a8                 mov      qword ptr [rbp - 0x58], rax
0000000141488555  488d4da8                 lea      rcx, [rbp - 0x58]
0000000141488559  e822a397ff               call     0x140e02880 ; fastrand::Rng::f32 | _ZN8fastrand3Rng3f3217h74c3355474b41115E
000000014148855e  90                       nop      
000000014148855f  440f28c0                 movaps   xmm8, xmm0
0000000141488563  f3440f590520f49a01       mulss    xmm8, dword ptr [rip + 0x19af420]
000000014148856c  f3450f58c7               addss    xmm8, xmm15
0000000141488571  66440f6e65d0             movd     xmm12, dword ptr [rbp - 0x30]
0000000141488577  f30f1075d8               movss    xmm6, dword ptr [rbp - 0x28]
000000014148857c  4c8b75f0                 mov      r14, qword ptr [rbp - 0x10]
0000000141488580  4c3b75e0                 cmp      r14, qword ptr [rbp - 0x20]
0000000141488584  7509                     jne      0x14148858f
0000000141488586  4c89e1                   mov      rcx, r12
0000000141488589  e8a2698f01               call     0x142d7ef30 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h0a1121fd623a8175E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h23a8d3e913216895E
000000014148858e  90                       nop      
000000014148858f  f3410f59f8               mulss    xmm7, xmm8
0000000141488594  f3410f58fd               addss    xmm7, xmm13
0000000141488599  488b45e8                 mov      rax, qword ptr [rbp - 0x18]
000000014148859d  4c89f1                   mov      rcx, r14
00000001414885a0  48c1e104                 shl      rcx, 4
00000001414885a4  66440f7e2408             movd     dword ptr [rax + rcx], xmm12
00000001414885aa  f30f117c0804             movss    dword ptr [rax + rcx + 4], xmm7
00000001414885b0  f30f11740808             movss    dword ptr [rax + rcx + 8], xmm6
00000001414885b6  66440f7e5c080c           movd     dword ptr [rax + rcx + 0xc], xmm11
00000001414885bd  4d8d7e01                 lea      r15, [r14 + 1]
00000001414885c1  4c897df0                 mov      qword ptr [rbp - 0x10], r15
00000001414885c5  4c3b7de0                 cmp      r15, qword ptr [rbp - 0x20]
00000001414885c9  7509                     jne      0x1414885d4
00000001414885cb  4c89e1                   mov      rcx, r12
00000001414885ce  e85d698f01               call     0x142d7ef30 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h0a1121fd623a8175E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h23a8d3e913216895E
00000001414885d3  90                       nop      
00000001414885d4  488b45e8                 mov      rax, qword ptr [rbp - 0x18]
00000001414885d8  49c1e704                 shl      r15, 4
00000001414885dc  66460f7e2438             movd     dword ptr [rax + r15], xmm12
00000001414885e2  f3460f116c3804           movss    dword ptr [rax + r15 + 4], xmm13
00000001414885e9  f3420f11743808           movss    dword ptr [rax + r15 + 8], xmm6
00000001414885f0  f3420f117c380c           movss    dword ptr [rax + r15 + 0xc], xmm7
00000001414885f7  4983c602                 add      r14, 2
00000001414885fb  4c8975f0                 mov      qword ptr [rbp - 0x10], r14
00000001414885ff  4d85f6                   test     r14, r14
0000000141488602  0f85dffdffff             jne      0x1414883e7
0000000141488608  eb43                     jmp      0x14148864d
000000014148860a  660f1f440000             nop      word ptr [rax + rax]
0000000141488610  4c8b75c8                 mov      r14, qword ptr [rbp - 0x38]
0000000141488614  4c3b75b8                 cmp      r14, qword ptr [rbp - 0x48]
0000000141488618  0f85a2fdffff             jne      0x1414883c0
000000014148861e  488d4db8                 lea      rcx, [rbp - 0x48]
0000000141488622  e809698f01               call     0x142d7ef30 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h0a1121fd623a8175E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h23a8d3e913216895E
0000000141488627  90                       nop      
0000000141488628  e993fdffff               jmp      0x1414883c0
000000014148862d  0f1f00                   nop      dword ptr [rax]
0000000141488630  4c8b75c8                 mov      r14, qword ptr [rbp - 0x38]
0000000141488634  4c3b75b8                 cmp      r14, qword ptr [rbp - 0x48]
0000000141488638  0f8582fdffff             jne      0x1414883c0
000000014148863e  488d4db8                 lea      rcx, [rbp - 0x48]
0000000141488642  e8e9688f01               call     0x142d7ef30 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h0a1121fd623a8175E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h23a8d3e913216895E
0000000141488647  90                       nop      
0000000141488648  e973fdffff               jmp      0x1414883c0
000000014148864d  488b45c8                 mov      rax, qword ptr [rbp - 0x38]
0000000141488651  488b75a0                 mov      rsi, qword ptr [rbp - 0x60]
0000000141488655  48894610                 mov      qword ptr [rsi + 0x10], rax
0000000141488659  0f1045b8                 movups   xmm0, xmmword ptr [rbp - 0x48]
000000014148865d  0f1106                   movups   xmmword ptr [rsi], xmm0
0000000141488660  488b55e0                 mov      rdx, qword ptr [rbp - 0x20]
0000000141488664  4885d2                   test     rdx, rdx
0000000141488667  7413                     je       0x14148867c
0000000141488669  488b4de8                 mov      rcx, qword ptr [rbp - 0x18]
000000014148866d  48c1e204                 shl      rdx, 4
0000000141488671  41b804000000             mov      r8d, 4
0000000141488677  e8443422ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148867c  4889f0                   mov      rax, rsi
000000014148867f  0f287500                 movaps   xmm6, xmmword ptr [rbp]
0000000141488683  0f287d10                 movaps   xmm7, xmmword ptr [rbp + 0x10]
0000000141488687  440f284520               movaps   xmm8, xmmword ptr [rbp + 0x20]
000000014148868c  440f284d30               movaps   xmm9, xmmword ptr [rbp + 0x30]
0000000141488691  440f285540               movaps   xmm10, xmmword ptr [rbp + 0x40]
0000000141488696  440f285d50               movaps   xmm11, xmmword ptr [rbp + 0x50]
000000014148869b  440f286560               movaps   xmm12, xmmword ptr [rbp + 0x60]
00000001414886a0  440f286d70               movaps   xmm13, xmmword ptr [rbp + 0x70]
00000001414886a5  440f28b580000000         movaps   xmm14, xmmword ptr [rbp + 0x80]
00000001414886ad  440f28bd90000000         movaps   xmm15, xmmword ptr [rbp + 0x90]
00000001414886b5  4881c428010000           add      rsp, 0x128
00000001414886bc  5b                       pop      rbx
00000001414886bd  5f                       pop      rdi
00000001414886be  5e                       pop      rsi
00000001414886bf  415c                     pop      r12
00000001414886c1  415d                     pop      r13
00000001414886c3  415e                     pop      r14
00000001414886c5  415f                     pop      r15
00000001414886c7  5d                       pop      rbp
00000001414886c8  c3                       ret      
00000001414886c9  b904000000               mov      ecx, 4
00000001414886ce  ba10000000               mov      edx, 0x10
00000001414886d3  e839f79301               call     0x142dc7e11 ; alloc::alloc::handle_alloc_error | _RNvNtCs1f2BdUxKfgg_5alloc5alloc18handle_alloc_error
00000001414886d8  cc                       int3     
00000001414886d9  0f1f8000000000           nop      dword ptr [rax]
00000001414886e0  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001414886e5  55                       push     rbp
00000001414886e6  4157                     push     r15
00000001414886e8  4156                     push     r14
00000001414886ea  4155                     push     r13
00000001414886ec  4154                     push     r12
00000001414886ee  56                       push     rsi
00000001414886ef  57                       push     rdi
00000001414886f0  53                       push     rbx
00000001414886f1  4881ecc8000000           sub      rsp, 0xc8
00000001414886f8  488daa80000000           lea      rbp, [rdx + 0x80]
00000001414886ff  440f297c2420             movaps   xmmword ptr [rsp + 0x20], xmm15
0000000141488705  440f29742430             movaps   xmmword ptr [rsp + 0x30], xmm14
000000014148870b  66440f7f6c2440           movdqa   xmmword ptr [rsp + 0x40], xmm13
0000000141488712  66440f7f642450           movdqa   xmmword ptr [rsp + 0x50], xmm12
0000000141488719  66440f7f5c2460           movdqa   xmmword ptr [rsp + 0x60], xmm11
0000000141488720  440f29542470             movaps   xmmword ptr [rsp + 0x70], xmm10
0000000141488726  440f298c2480000000       movaps   xmmword ptr [rsp + 0x80], xmm9
000000014148872f  440f29842490000000       movaps   xmmword ptr [rsp + 0x90], xmm8
0000000141488738  0f29bc24a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm7
0000000141488740  0f29b424b0000000         movaps   xmmword ptr [rsp + 0xb0], xmm6
0000000141488748  488b55b8                 mov      rdx, qword ptr [rbp - 0x48]
000000014148874c  4885d2                   test     rdx, rdx
000000014148874f  7413                     je       0x141488764
0000000141488751  488b4dc0                 mov      rcx, qword ptr [rbp - 0x40]
0000000141488755  48c1e204                 shl      rdx, 4
0000000141488759  41b804000000             mov      r8d, 4
000000014148875f  e85c3322ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141488764  488b55e0                 mov      rdx, qword ptr [rbp - 0x20]
0000000141488768  4885d2                   test     rdx, rdx
000000014148876b  7413                     je       0x141488780
000000014148876d  488b4de8                 mov      rcx, qword ptr [rbp - 0x18]
0000000141488771  48c1e204                 shl      rdx, 4
0000000141488775  41b804000000             mov      r8d, 4
000000014148877b  e8403322ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141488780  0f28b424b0000000         movaps   xmm6, xmmword ptr [rsp + 0xb0]
0000000141488788  0f28bc24a0000000         movaps   xmm7, xmmword ptr [rsp + 0xa0]
0000000141488790  440f28842490000000       movaps   xmm8, xmmword ptr [rsp + 0x90]
0000000141488799  440f288c2480000000       movaps   xmm9, xmmword ptr [rsp + 0x80]
00000001414887a2  440f28542470             movaps   xmm10, xmmword ptr [rsp + 0x70]
00000001414887a8  440f285c2460             movaps   xmm11, xmmword ptr [rsp + 0x60]
00000001414887ae  440f28642450             movaps   xmm12, xmmword ptr [rsp + 0x50]
00000001414887b4  440f286c2440             movaps   xmm13, xmmword ptr [rsp + 0x40]
00000001414887ba  440f28742430             movaps   xmm14, xmmword ptr [rsp + 0x30]
00000001414887c0  440f287c2420             movaps   xmm15, xmmword ptr [rsp + 0x20]
00000001414887c6  4881c4c8000000           add      rsp, 0xc8
00000001414887cd  5b                       pop      rbx
00000001414887ce  5f                       pop      rdi
00000001414887cf  5e                       pop      rsi
00000001414887d0  415c                     pop      r12
00000001414887d2  415d                     pop      r13
00000001414887d4  415e                     pop      r14
00000001414887d6  415f                     pop      r15
00000001414887d8  5d                       pop      rbp
00000001414887d9  c3                       ret      