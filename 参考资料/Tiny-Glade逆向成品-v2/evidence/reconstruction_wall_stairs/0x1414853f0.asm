00000001414853f0  55                       push     rbp
00000001414853f1  4157                     push     r15
00000001414853f3  4156                     push     r14
00000001414853f5  4155                     push     r13
00000001414853f7  4154                     push     r12
00000001414853f9  56                       push     rsi
00000001414853fa  57                       push     rdi
00000001414853fb  53                       push     rbx
00000001414853fc  4881ec08010000           sub      rsp, 0x108
0000000141485403  488dac2480000000         lea      rbp, [rsp + 0x80]
000000014148540b  440f297d70               movaps   xmmword ptr [rbp + 0x70], xmm15
0000000141485410  440f297560               movaps   xmmword ptr [rbp + 0x60], xmm14
0000000141485415  440f296d50               movaps   xmmword ptr [rbp + 0x50], xmm13
000000014148541a  440f296540               movaps   xmmword ptr [rbp + 0x40], xmm12
000000014148541f  440f295d30               movaps   xmmword ptr [rbp + 0x30], xmm11
0000000141485424  440f295520               movaps   xmmword ptr [rbp + 0x20], xmm10
0000000141485429  440f294d10               movaps   xmmword ptr [rbp + 0x10], xmm9
000000014148542e  440f294500               movaps   xmmword ptr [rbp], xmm8
0000000141485433  0f297df0                 movaps   xmmword ptr [rbp - 0x10], xmm7
0000000141485437  0f2975e0                 movaps   xmmword ptr [rbp - 0x20], xmm6
000000014148543b  48c745d8feffffff         mov      qword ptr [rbp - 0x28], 0xfffffffffffffffe
0000000141485443  48894da8                 mov      qword ptr [rbp - 0x58], rcx
0000000141485447  48c745c000000000         mov      qword ptr [rbp - 0x40], 0
000000014148544f  48c745c804000000         mov      qword ptr [rbp - 0x38], 4
0000000141485457  48c745d000000000         mov      qword ptr [rbp - 0x30], 0
000000014148545f  4d85c9                   test     r9, r9
0000000141485462  0f8436030000             je       0x14148579e
0000000141485468  4c89c7                   mov      rdi, r8
000000014148546b  4889d3                   mov      rbx, rdx
000000014148546e  496bc168                 imul     rax, r9, 0x68
0000000141485472  4c01c0                   add      rax, r8
0000000141485475  488945a0                 mov      qword ptr [rbp - 0x60], rax
0000000141485479  f3440f10052ee8bc01       movss    xmm8, dword ptr [rip + 0x1bce82e]
0000000141485482  eb40                     jmp      0x1414854c4
0000000141485484  6666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141485490  410f28c3                 movaps   xmm0, xmm11
0000000141485494  410f16c7                 movlhps  xmm0, xmm15
0000000141485498  0fc6c824                 shufps   xmm1, xmm0, 0x24
000000014148549c  0f540d3d239b01           andps    xmm1, xmmword ptr [rip + 0x19b233d]
00000001414854a3  660f660db555bb01         pcmpgtd  xmm1, xmmword ptr [rip + 0x1bb55b5]
00000001414854ab  0f50c1                   movmskps eax, xmm1
00000001414854ae  85c0                     test     eax, eax
00000001414854b0  0f8449010000             je       0x1414855ff
00000001414854b6  4883c768                 add      rdi, 0x68
00000001414854ba  483b7da0                 cmp      rdi, qword ptr [rbp - 0x60]
00000001414854be  0f84da020000             je       0x14148579e
00000001414854c4  4c8b6f28                 mov      r13, qword ptr [rdi + 0x28]
00000001414854c8  4d85ed                   test     r13, r13
00000001414854cb  74e9                     je       0x1414854b6
00000001414854cd  488b4710                 mov      rax, qword ptr [rdi + 0x10]
00000001414854d1  4885c0                   test     rax, rax
00000001414854d4  74e0                     je       0x1414854b6
00000001414854d6  f3440f10bb78020000       movss    xmm15, dword ptr [rbx + 0x278]
00000001414854df  f3440f583d04bbad01       addss    xmm15, dword ptr [rip + 0x1adbb04]
00000001414854e8  4c8b7f08                 mov      r15, qword ptr [rdi + 8]
00000001414854ec  488b7720                 mov      rsi, qword ptr [rdi + 0x20]
00000001414854f0  4c39e8                   cmp      rax, r13
00000001414854f3  4c0f42e8                 cmovb    r13, rax
00000001414854f7  4531e4                   xor      r12d, r12d
00000001414854fa  4531f6                   xor      r14d, r14d
00000001414854fd  450f28f0                 movaps   xmm14, xmm8
0000000141485501  f30f1035731eaf01         movss    xmm6, dword ptr [rip + 0x1af1e73]
0000000141485509  450f28d8                 movaps   xmm11, xmm8
000000014148550d  f20f100ddb7ae801         movsd    xmm1, qword ptr [rip + 0x1e87adb]
0000000141485515  eb74                     jmp      0x14148558b
0000000141485517  660f1f840000000000       nop      word ptr [rax + rax]
0000000141485520  f3430f583ca7             addss    xmm7, dword ptr [r15 + r12*4]
0000000141485526  49ffc4                   inc      r12
0000000141485529  0f28c8                   movaps   xmm1, xmm0
000000014148552c  f30f5dce                 minss    xmm1, xmm6
0000000141485530  f30fc2f603               cmpunordss xmm6, xmm6
0000000141485535  0f28d6                   movaps   xmm2, xmm6
0000000141485538  0f54d0                   andps    xmm2, xmm0
000000014148553b  0f55f1                   andnps   xmm6, xmm1
000000014148553e  0f56f2                   orps     xmm6, xmm2
0000000141485541  0f28c8                   movaps   xmm1, xmm0
0000000141485544  f3410f5fce               maxss    xmm1, xmm14
0000000141485549  f3450fc2f603             cmpunordss xmm14, xmm14
000000014148554f  410f28d6                 movaps   xmm2, xmm14
0000000141485553  0f54d0                   andps    xmm2, xmm0
0000000141485556  440f55f1                 andnps   xmm14, xmm1
000000014148555a  440f56f2                 orps     xmm14, xmm2
000000014148555e  410f28d3                 movaps   xmm2, xmm11
0000000141485562  f3410fc2d303             cmpunordss xmm2, xmm11
0000000141485568  0f28ca                   movaps   xmm1, xmm2
000000014148556b  0f54cf                   andps    xmm1, xmm7
000000014148556e  f3410f5ffb               maxss    xmm7, xmm11
0000000141485573  0f55d7                   andnps   xmm2, xmm7
0000000141485576  0f56d1                   orps     xmm2, xmm1
0000000141485579  410f28ce                 movaps   xmm1, xmm14
000000014148557d  0f14ce                   unpcklps xmm1, xmm6
0000000141485580  41b601                   mov      r14b, 1
0000000141485583  440f28da                 movaps   xmm11, xmm2
0000000141485587  440f28c8                 movaps   xmm9, xmm0
000000014148558b  4d39ec                   cmp      r12, r13
000000014148558e  0f83fcfeffff             jae      0x141485490
0000000141485594  4b8d0464                 lea      rax, [r12 + r12*2]
0000000141485598  8b0c86                   mov      ecx, dword ptr [rsi + rax*4]
000000014148559b  f30f107c8604             movss    xmm7, dword ptr [rsi + rax*4 + 4]
00000001414855a1  8b448608                 mov      eax, dword ptr [rsi + rax*4 + 8]
00000001414855a5  894db4                   mov      dword ptr [rbp - 0x4c], ecx
00000001414855a8  f30f117db8               movss    dword ptr [rbp - 0x48], xmm7
00000001414855ad  8945bc                   mov      dword ptr [rbp - 0x44], eax
00000001414855b0  488d4db4                 lea      rcx, [rbp - 0x4c]
00000001414855b4  4889da                   mov      rdx, rbx
00000001414855b7  e8644f96ff               call     0x140dea520 ; utils::wall_space::WallSpaceCoord::from_world_space | _ZN5utils10wall_space14WallSpaceCoord16from_world_space17hd8792f152ea4f085E
00000001414855bc  90                       nop      
00000001414855bd  83bb5802000002           cmp      dword ptr [rbx + 0x258], 2
00000001414855c4  0f94c0                   sete     al
00000001414855c7  41f6d6                   not      r14b
00000001414855ca  4108c6                   or       r14b, al
00000001414855cd  41f6c601                 test     r14b, 1
00000001414855d1  0f8549ffffff             jne      0x141485520
00000001414855d7  440f2ec8                 ucomiss  xmm9, xmm0
00000001414855db  0f863fffffff             jbe      0x141485520
00000001414855e1  f30f108b90020000         movss    xmm1, dword ptr [rbx + 0x290]
00000001414855e9  0f1f8000000000           nop      dword ptr [rax]
00000001414855f0  f30f58c1                 addss    xmm0, xmm1
00000001414855f4  440f2ec8                 ucomiss  xmm9, xmm0
00000001414855f8  77f6                     ja       0x1414855f0
00000001414855fa  e921ffffff               jmp      0x141485520
00000001414855ff  83bb5802000002           cmp      dword ptr [rbx + 0x258], 2
0000000141485606  751d                     jne      0x141485625
0000000141485608  488b75d0                 mov      rsi, qword ptr [rbp - 0x30]
000000014148560c  483b75c0                 cmp      rsi, qword ptr [rbp - 0x40]
0000000141485610  0f8557010000             jne      0x14148576d
0000000141485616  488d4dc0                 lea      rcx, [rbp - 0x40]
000000014148561a  e811998f01               call     0x142d7ef30 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h0a1121fd623a8175E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h23a8d3e913216895E
000000014148561f  90                       nop      
0000000141485620  e948010000               jmp      0x14148576d
0000000141485625  f30f10bb90020000         movss    xmm7, dword ptr [rbx + 0x290]
000000014148562d  f30f100513229b01         movss    xmm0, dword ptr [rip + 0x19b2213]
0000000141485635  0f2ec7                   ucomiss  xmm0, xmm7
0000000141485638  0f8378feffff             jae      0x1414854b6
000000014148563e  410f28c6                 movaps   xmm0, xmm14
0000000141485642  f30f5cc6                 subss    xmm0, xmm6
0000000141485646  0f28cf                   movaps   xmm1, xmm7
0000000141485649  f30f1015cf5ab801         movss    xmm2, dword ptr [rip + 0x1b85acf]
0000000141485651  f30f58ca                 addss    xmm1, xmm2
0000000141485655  0f2ec1                   ucomiss  xmm0, xmm1
0000000141485658  0f83ee000000             jae      0x14148574c
000000014148565e  450f28ce                 movaps   xmm9, xmm14
0000000141485662  f3440f58ca               addss    xmm9, xmm2
0000000141485667  440f2ece                 ucomiss  xmm9, xmm6
000000014148566b  0f8645feffff             jbe      0x1414854b6
0000000141485671  440f28d7                 movaps   xmm10, xmm7
0000000141485675  440f541563219b01         andps    xmm10, xmmword ptr [rip + 0x19b2163]
000000014148567d  eb45                     jmp      0x1414856c4
000000014148567f  90                       nop      
0000000141485680  410f28c5                 movaps   xmm0, xmm13
0000000141485684  f3450f58ec               addss    xmm13, xmm12
0000000141485689  488b45c8                 mov      rax, qword ptr [rbp - 0x38]
000000014148568d  4889f1                   mov      rcx, rsi
0000000141485690  48c1e104                 shl      rcx, 4
0000000141485694  f30f110408               movss    dword ptr [rax + rcx], xmm0
0000000141485699  f3440f117c0804           movss    dword ptr [rax + rcx + 4], xmm15
00000001414856a0  f3440f116c0808           movss    dword ptr [rax + rcx + 8], xmm13
00000001414856a7  f3440f115c080c           movss    dword ptr [rax + rcx + 0xc], xmm11
00000001414856ae  48ffc6                   inc      rsi
00000001414856b1  488975d0                 mov      qword ptr [rbp - 0x30], rsi
00000001414856b5  f3410f58f4               addss    xmm6, xmm12
00000001414856ba  440f2ece                 ucomiss  xmm9, xmm6
00000001414856be  0f86f2fdffff             jbe      0x1414854b6
00000001414856c4  0f28c6                   movaps   xmm0, xmm6
00000001414856c7  0f28cf                   movaps   xmm1, xmm7
00000001414856ca  e8a1d39a01               call     0x142e32a70 ; fmodf
00000001414856cf  410f28ca                 movaps   xmm1, xmm10
00000001414856d3  f30f58c8                 addss    xmm1, xmm0
00000001414856d7  440f28e8                 movaps   xmm13, xmm0
00000001414856db  0f57d2                   xorps    xmm2, xmm2
00000001414856de  f3440fc2ea01             cmpltss  xmm13, xmm2
00000001414856e4  410f54cd                 andps    xmm1, xmm13
00000001414856e8  440f55e8                 andnps   xmm13, xmm0
00000001414856ec  440f56e9                 orps     xmm13, xmm1
00000001414856f0  410f28c6                 movaps   xmm0, xmm14
00000001414856f4  f30f5cc6                 subss    xmm0, xmm6
00000001414856f8  0f28cf                   movaps   xmm1, xmm7
00000001414856fb  f3410f5ccd               subss    xmm1, xmm13
0000000141485700  440f28e0                 movaps   xmm12, xmm0
0000000141485704  f3440fc2e003             cmpunordss xmm12, xmm0
000000014148570a  410f28d4                 movaps   xmm2, xmm12
000000014148570e  0f54d1                   andps    xmm2, xmm1
0000000141485711  f30f5dc8                 minss    xmm1, xmm0
0000000141485715  440f55e1                 andnps   xmm12, xmm1
0000000141485719  440f56e2                 orps     xmm12, xmm2
000000014148571d  f30f10053f46b801         movss    xmm0, dword ptr [rip + 0x1b8463f]
0000000141485725  410f2ec4                 ucomiss  xmm0, xmm12
0000000141485729  0f8387fdffff             jae      0x1414854b6
000000014148572f  488b75d0                 mov      rsi, qword ptr [rbp - 0x30]
0000000141485733  483b75c0                 cmp      rsi, qword ptr [rbp - 0x40]
0000000141485737  0f8543ffffff             jne      0x141485680
000000014148573d  488d4dc0                 lea      rcx, [rbp - 0x40]
0000000141485741  e8ea978f01               call     0x142d7ef30 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h0a1121fd623a8175E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h23a8d3e913216895E
0000000141485746  90                       nop      
0000000141485747  e934ffffff               jmp      0x141485680
000000014148574c  488b75d0                 mov      rsi, qword ptr [rbp - 0x30]
0000000141485750  0f57f6                   xorps    xmm6, xmm6
0000000141485753  483b75c0                 cmp      rsi, qword ptr [rbp - 0x40]
0000000141485757  7510                     jne      0x141485769
0000000141485759  488d4dc0                 lea      rcx, [rbp - 0x40]
000000014148575d  e8ce978f01               call     0x142d7ef30 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h0a1121fd623a8175E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h23a8d3e913216895E
0000000141485762  90                       nop      
0000000141485763  440f28f7                 movaps   xmm14, xmm7
0000000141485767  eb04                     jmp      0x14148576d
0000000141485769  440f28f7                 movaps   xmm14, xmm7
000000014148576d  488b45c8                 mov      rax, qword ptr [rbp - 0x38]
0000000141485771  4889f1                   mov      rcx, rsi
0000000141485774  48c1e104                 shl      rcx, 4
0000000141485778  f30f113408               movss    dword ptr [rax + rcx], xmm6
000000014148577d  f3440f117c0804           movss    dword ptr [rax + rcx + 4], xmm15
0000000141485784  f3440f11740808           movss    dword ptr [rax + rcx + 8], xmm14
000000014148578b  f3440f115c080c           movss    dword ptr [rax + rcx + 0xc], xmm11
0000000141485792  48ffc6                   inc      rsi
0000000141485795  488975d0                 mov      qword ptr [rbp - 0x30], rsi
0000000141485799  e918fdffff               jmp      0x1414854b6
000000014148579e  488b4dd0                 mov      rcx, qword ptr [rbp - 0x30]
00000001414857a2  488b45a8                 mov      rax, qword ptr [rbp - 0x58]
00000001414857a6  48894810                 mov      qword ptr [rax + 0x10], rcx
00000001414857aa  488b4dc0                 mov      rcx, qword ptr [rbp - 0x40]
00000001414857ae  488908                   mov      qword ptr [rax], rcx
00000001414857b1  488b4dc8                 mov      rcx, qword ptr [rbp - 0x38]
00000001414857b5  48894808                 mov      qword ptr [rax + 8], rcx
00000001414857b9  0f2875e0                 movaps   xmm6, xmmword ptr [rbp - 0x20]
00000001414857bd  0f287df0                 movaps   xmm7, xmmword ptr [rbp - 0x10]
00000001414857c1  440f284500               movaps   xmm8, xmmword ptr [rbp]
00000001414857c6  440f284d10               movaps   xmm9, xmmword ptr [rbp + 0x10]
00000001414857cb  440f285520               movaps   xmm10, xmmword ptr [rbp + 0x20]
00000001414857d0  440f285d30               movaps   xmm11, xmmword ptr [rbp + 0x30]
00000001414857d5  440f286540               movaps   xmm12, xmmword ptr [rbp + 0x40]
00000001414857da  440f286d50               movaps   xmm13, xmmword ptr [rbp + 0x50]
00000001414857df  440f287560               movaps   xmm14, xmmword ptr [rbp + 0x60]
00000001414857e4  440f287d70               movaps   xmm15, xmmword ptr [rbp + 0x70]
00000001414857e9  4881c408010000           add      rsp, 0x108
00000001414857f0  5b                       pop      rbx
00000001414857f1  5f                       pop      rdi
00000001414857f2  5e                       pop      rsi
00000001414857f3  415c                     pop      r12
00000001414857f5  415d                     pop      r13
00000001414857f7  415e                     pop      r14
00000001414857f9  415f                     pop      r15
00000001414857fb  5d                       pop      rbp
00000001414857fc  c3                       ret      
00000001414857fd  0f1f00                   nop      dword ptr [rax]
0000000141485800  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141485805  55                       push     rbp
0000000141485806  4157                     push     r15
0000000141485808  4156                     push     r14
000000014148580a  4155                     push     r13
000000014148580c  4154                     push     r12
000000014148580e  56                       push     rsi
000000014148580f  57                       push     rdi
0000000141485810  53                       push     rbx
0000000141485811  4881ecc8000000           sub      rsp, 0xc8
0000000141485818  488daa80000000           lea      rbp, [rdx + 0x80]
000000014148581f  440f297c2420             movaps   xmmword ptr [rsp + 0x20], xmm15
0000000141485825  440f29742430             movaps   xmmword ptr [rsp + 0x30], xmm14
000000014148582b  440f296c2440             movaps   xmmword ptr [rsp + 0x40], xmm13
0000000141485831  440f29642450             movaps   xmmword ptr [rsp + 0x50], xmm12
0000000141485837  440f295c2460             movaps   xmmword ptr [rsp + 0x60], xmm11
000000014148583d  440f29542470             movaps   xmmword ptr [rsp + 0x70], xmm10
0000000141485843  440f298c2480000000       movaps   xmmword ptr [rsp + 0x80], xmm9
000000014148584c  440f29842490000000       movaps   xmmword ptr [rsp + 0x90], xmm8
0000000141485855  0f29bc24a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm7
000000014148585d  0f29b424b0000000         movaps   xmmword ptr [rsp + 0xb0], xmm6
0000000141485865  488b55c0                 mov      rdx, qword ptr [rbp - 0x40]
0000000141485869  4885d2                   test     rdx, rdx
000000014148586c  7413                     je       0x141485881
000000014148586e  488b4dc8                 mov      rcx, qword ptr [rbp - 0x38]
0000000141485872  48c1e204                 shl      rdx, 4
0000000141485876  41b804000000             mov      r8d, 4
000000014148587c  e83f6222ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141485881  0f28b424b0000000         movaps   xmm6, xmmword ptr [rsp + 0xb0]
0000000141485889  0f28bc24a0000000         movaps   xmm7, xmmword ptr [rsp + 0xa0]
0000000141485891  440f28842490000000       movaps   xmm8, xmmword ptr [rsp + 0x90]
000000014148589a  440f288c2480000000       movaps   xmm9, xmmword ptr [rsp + 0x80]
00000001414858a3  440f28542470             movaps   xmm10, xmmword ptr [rsp + 0x70]
00000001414858a9  440f285c2460             movaps   xmm11, xmmword ptr [rsp + 0x60]
00000001414858af  440f28642450             movaps   xmm12, xmmword ptr [rsp + 0x50]
00000001414858b5  440f286c2440             movaps   xmm13, xmmword ptr [rsp + 0x40]
00000001414858bb  440f28742430             movaps   xmm14, xmmword ptr [rsp + 0x30]
00000001414858c1  440f287c2420             movaps   xmm15, xmmword ptr [rsp + 0x20]
00000001414858c7  4881c4c8000000           add      rsp, 0xc8
00000001414858ce  5b                       pop      rbx
00000001414858cf  5f                       pop      rdi
00000001414858d0  5e                       pop      rsi
00000001414858d1  415c                     pop      r12
00000001414858d3  415d                     pop      r13
00000001414858d5  415e                     pop      r14
00000001414858d7  415f                     pop      r15
00000001414858d9  5d                       pop      rbp
00000001414858da  c3                       ret      