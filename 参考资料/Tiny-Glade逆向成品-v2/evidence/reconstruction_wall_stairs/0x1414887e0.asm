00000001414887e0  55                       push     rbp
00000001414887e1  4157                     push     r15
00000001414887e3  4156                     push     r14
00000001414887e5  4155                     push     r13
00000001414887e7  4154                     push     r12
00000001414887e9  56                       push     rsi
00000001414887ea  57                       push     rdi
00000001414887eb  53                       push     rbx
00000001414887ec  4881ecc8000000           sub      rsp, 0xc8
00000001414887f3  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001414887fb  440f296d30               movaps   xmmword ptr [rbp + 0x30], xmm13
0000000141488800  440f296520               movaps   xmmword ptr [rbp + 0x20], xmm12
0000000141488805  440f295d10               movaps   xmmword ptr [rbp + 0x10], xmm11
000000014148880a  440f295500               movaps   xmmword ptr [rbp], xmm10
000000014148880f  440f294df0               movaps   xmmword ptr [rbp - 0x10], xmm9
0000000141488814  440f2945e0               movaps   xmmword ptr [rbp - 0x20], xmm8
0000000141488819  0f297dd0                 movaps   xmmword ptr [rbp - 0x30], xmm7
000000014148881d  0f2975c0                 movaps   xmmword ptr [rbp - 0x40], xmm6
0000000141488821  48c745b8feffffff         mov      qword ptr [rbp - 0x48], 0xfffffffffffffffe
0000000141488829  440f28c3                 movaps   xmm8, xmm3
000000014148882d  4489c3                   mov      ebx, r8d
0000000141488830  4889d7                   mov      rdi, rdx
0000000141488833  4889ce                   mov      rsi, rcx
0000000141488836  4889d1                   mov      rcx, rdx
0000000141488839  e8d26396ff               call     0x140deec10 ; utils::geometry::aabb::Aabb2::width | _ZN5utils8geometry4aabb5Aabb25width17he30e90b5e741e6fbE
000000014148883e  0f28f8                   movaps   xmm7, xmm0
0000000141488841  4889f9                   mov      rcx, rdi
0000000141488844  e8076496ff               call     0x140deec50 ; utils::geometry::aabb::Aabb2::height | _ZN5utils8geometry4aabb5Aabb26height17h160a2c40e4ab2359E
0000000141488849  0f28f0                   movaps   xmm6, xmm0
000000014148884c  84db                     test     bl, bl
000000014148884e  7503                     jne      0x141488853
0000000141488850  0f28c7                   movaps   xmm0, xmm7
0000000141488853  f3410f5ec0               divss    xmm0, xmm8
0000000141488858  e8a3a29a01               call     0x142e32b00 ; roundf
000000014148885d  f30f5f05c3e69a01         maxss    xmm0, dword ptr [rip + 0x19ae6c3]
0000000141488865  f3480f2cc0               cvttss2si rax, xmm0
000000014148886a  4889c1                   mov      rcx, rax
000000014148886d  48c1f93f                 sar      rcx, 0x3f
0000000141488871  0f28c8                   movaps   xmm1, xmm0
0000000141488874  f30f5c0db0e69a01         subss    xmm1, dword ptr [rip + 0x19ae6b0]
000000014148887c  f3480f2cd1               cvttss2si rdx, xmm1
0000000141488881  4821ca                   and      rdx, rcx
0000000141488884  4809c2                   or       rdx, rax
0000000141488887  4531f6                   xor      r14d, r14d
000000014148888a  0f57c9                   xorps    xmm1, xmm1
000000014148888d  0f2ec1                   ucomiss  xmm0, xmm1
0000000141488890  490f42d6                 cmovb    rdx, r14
0000000141488894  0f2e0595e69a01           ucomiss  xmm0, dword ptr [rip + 0x19ae695]
000000014148889b  49c7c4ffffffff           mov      r12, 0xffffffffffffffff
00000001414888a2  4c0f46e2                 cmovbe   r12, rdx
00000001414888a6  4d89e7                   mov      r15, r12
00000001414888a9  49c1e704                 shl      r15, 4
00000001414888ad  4c89e0                   mov      rax, r12
00000001414888b0  48c1e83c                 shr      rax, 0x3c
00000001414888b4  0f95c0                   setne    al
00000001414888b7  48b9fcffffffffffff7f     movabs   rcx, 0x7ffffffffffffffc
00000001414888c1  4939cf                   cmp      r15, rcx
00000001414888c4  0f97c1                   seta     cl
00000001414888c7  08c1                     or       cl, al
00000001414888c9  740b                     je       0x1414888d6
00000001414888cb  4c89f1                   mov      rcx, r14
00000001414888ce  4c89fa                   mov      rdx, r15
00000001414888d1  e854f59301               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
00000001414888d6  4d85ff                   test     r15, r15
00000001414888d9  7422                     je       0x1414888fd
00000001414888db  e88065bffe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
00000001414888e0  41be04000000             mov      r14d, 4
00000001414888e6  ba04000000               mov      edx, 4
00000001414888eb  4c89f9                   mov      rcx, r15
00000001414888ee  e8bd3122ff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
00000001414888f3  4885c0                   test     rax, rax
00000001414888f6  74d3                     je       0x1414888cb
00000001414888f8  4c89e1                   mov      rcx, r12
00000001414888fb  eb07                     jmp      0x141488904
00000001414888fd  b804000000               mov      eax, 4
0000000141488902  31c9                     xor      ecx, ecx
0000000141488904  48894da0                 mov      qword ptr [rbp - 0x60], rcx
0000000141488908  488945a8                 mov      qword ptr [rbp - 0x58], rax
000000014148890c  48c745b000000000         mov      qword ptr [rbp - 0x50], 0
0000000141488914  4d85e4                   test     r12, r12
0000000141488917  0f84a4010000             je       0x141488ac1
000000014148891d  450f57c0                 xorps    xmm8, xmm8
0000000141488921  f34d0f2ac4               cvtsi2ss xmm8, r12
0000000141488926  f30f12ff                 movsldup xmm7, xmm7
000000014148892a  f3450f12c8               movsldup xmm9, xmm8
000000014148892f  41bf0c000000             mov      r15d, 0xc
0000000141488935  31c0                     xor      eax, eax
0000000141488937  450f57d2                 xorps    xmm10, xmm10
000000014148893b  4c8d75a0                 lea      r14, [rbp - 0x60]
000000014148893f  eb47                     jmp      0x141488988
0000000141488941  6666666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141488950  488b45a8                 mov      rax, qword ptr [rbp - 0x58]
0000000141488954  f3460f116c38f4           movss    dword ptr [rax + r15 - 0xc], xmm13
000000014148895b  f3460f116438f8           movss    dword ptr [rax + r15 - 8], xmm12
0000000141488962  f3410f16c5               movshdup xmm0, xmm13
0000000141488967  f3420f114438fc           movss    dword ptr [rax + r15 - 4], xmm0
000000014148896e  f3460f111c38             movss    dword ptr [rax + r15], xmm11
0000000141488974  4c896db0                 mov      qword ptr [rbp - 0x50], r13
0000000141488978  4983c710                 add      r15, 0x10
000000014148897c  4c89e8                   mov      rax, r13
000000014148897f  4d39ec                   cmp      r12, r13
0000000141488982  0f8439010000             je       0x141488ac1
0000000141488988  4885c0                   test     rax, rax
000000014148898b  7823                     js       0x1414889b0
000000014148898d  0f57c0                   xorps    xmm0, xmm0
0000000141488990  f3480f2ac0               cvtsi2ss xmm0, rax
0000000141488995  4c8d6801                 lea      r13, [rax + 1]
0000000141488999  84db                     test     bl, bl
000000014148899b  7535                     jne      0x1414889d2
000000014148899d  4d85ed                   test     r13, r13
00000001414889a0  784e                     js       0x1414889f0
00000001414889a2  0f57c9                   xorps    xmm1, xmm1
00000001414889a5  f3490f2acd               cvtsi2ss xmm1, r13
00000001414889aa  eb5f                     jmp      0x141488a0b
00000001414889ac  0f1f4000                 nop      dword ptr [rax]
00000001414889b0  4889c1                   mov      rcx, rax
00000001414889b3  48d1e9                   shr      rcx, 1
00000001414889b6  89c2                     mov      edx, eax
00000001414889b8  83e201                   and      edx, 1
00000001414889bb  4809ca                   or       rdx, rcx
00000001414889be  0f57c0                   xorps    xmm0, xmm0
00000001414889c1  f3480f2ac2               cvtsi2ss xmm0, rdx
00000001414889c6  f30f58c0                 addss    xmm0, xmm0
00000001414889ca  4c8d6801                 lea      r13, [rax + 1]
00000001414889ce  84db                     test     bl, bl
00000001414889d0  74cb                     je       0x14148899d
00000001414889d2  4d85ed                   test     r13, r13
00000001414889d5  7879                     js       0x141488a50
00000001414889d7  450f57db                 xorps    xmm11, xmm11
00000001414889db  f34d0f2add               cvtsi2ss xmm11, r13
00000001414889e0  e988000000               jmp      0x141488a6d
00000001414889e5  66662e0f1f840000000000   nop      word ptr cs:[rax + rax]
00000001414889f0  4c89e9                   mov      rcx, r13
00000001414889f3  48d1e9                   shr      rcx, 1
00000001414889f6  4489ea                   mov      edx, r13d
00000001414889f9  83e201                   and      edx, 1
00000001414889fc  4809ca                   or       rdx, rcx
00000001414889ff  0f57c9                   xorps    xmm1, xmm1
0000000141488a02  f3480f2aca               cvtsi2ss xmm1, rdx
0000000141488a07  f30f58c9                 addss    xmm1, xmm1
0000000141488a0b  0f1017                   movups   xmm2, xmmword ptr [rdi]
0000000141488a0e  f3440f106704             movss    xmm12, dword ptr [rdi + 4]
0000000141488a14  0f14c1                   unpcklps xmm0, xmm1
0000000141488a17  0f59c7                   mulps    xmm0, xmm7
0000000141488a1a  410f5ec1                 divps    xmm0, xmm9
0000000141488a1e  f3440f12ea               movsldup xmm13, xmm2
0000000141488a23  440f58e8                 addps    xmm13, xmm0
0000000141488a27  f3440f105f0c             movss    xmm11, dword ptr [rdi + 0xc]
0000000141488a2d  483b45a0                 cmp      rax, qword ptr [rbp - 0x60]
0000000141488a31  0f8519ffffff             jne      0x141488950
0000000141488a37  4c89f1                   mov      rcx, r14
0000000141488a3a  e8f1648f01               call     0x142d7ef30 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h0a1121fd623a8175E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h23a8d3e913216895E
0000000141488a3f  90                       nop      
0000000141488a40  e90bffffff               jmp      0x141488950
0000000141488a45  66662e0f1f840000000000   nop      word ptr cs:[rax + rax]
0000000141488a50  4c89e9                   mov      rcx, r13
0000000141488a53  48d1e9                   shr      rcx, 1
0000000141488a56  4489ea                   mov      edx, r13d
0000000141488a59  83e201                   and      edx, 1
0000000141488a5c  4809ca                   or       rdx, rcx
0000000141488a5f  450f57db                 xorps    xmm11, xmm11
0000000141488a63  f34c0f2ada               cvtsi2ss xmm11, rdx
0000000141488a68  f3450f58db               addss    xmm11, xmm11
0000000141488a6d  f30f104f04               movss    xmm1, dword ptr [rdi + 4]
0000000141488a72  f30f59c6                 mulss    xmm0, xmm6
0000000141488a76  f3410f5ec0               divss    xmm0, xmm8
0000000141488a7b  f30f58c1                 addss    xmm0, xmm1
0000000141488a7f  440f28e0                 movaps   xmm12, xmm0
0000000141488a83  f3450f58e2               addss    xmm12, xmm10
0000000141488a88  0f1007                   movups   xmm0, xmmword ptr [rdi]
0000000141488a8b  f3440f59de               mulss    xmm11, xmm6
0000000141488a90  f3450f5ed8               divss    xmm11, xmm8
0000000141488a95  f3440f58d9               addss    xmm11, xmm1
0000000141488a9a  f3440f106f08             movss    xmm13, dword ptr [rdi + 8]
0000000141488aa0  440f16e8                 movlhps  xmm13, xmm0
0000000141488aa4  440fc6e8e2               shufps   xmm13, xmm0, 0xe2
0000000141488aa9  483b45a0                 cmp      rax, qword ptr [rbp - 0x60]
0000000141488aad  0f859dfeffff             jne      0x141488950
0000000141488ab3  4c89f1                   mov      rcx, r14
0000000141488ab6  e875648f01               call     0x142d7ef30 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h0a1121fd623a8175E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h23a8d3e913216895E
0000000141488abb  90                       nop      
0000000141488abc  e98ffeffff               jmp      0x141488950
0000000141488ac1  488b45b0                 mov      rax, qword ptr [rbp - 0x50]
0000000141488ac5  48894610                 mov      qword ptr [rsi + 0x10], rax
0000000141488ac9  488b45a0                 mov      rax, qword ptr [rbp - 0x60]
0000000141488acd  488906                   mov      qword ptr [rsi], rax
0000000141488ad0  488b45a8                 mov      rax, qword ptr [rbp - 0x58]
0000000141488ad4  48894608                 mov      qword ptr [rsi + 8], rax
0000000141488ad8  4889f0                   mov      rax, rsi
0000000141488adb  0f2875c0                 movaps   xmm6, xmmword ptr [rbp - 0x40]
0000000141488adf  0f287dd0                 movaps   xmm7, xmmword ptr [rbp - 0x30]
0000000141488ae3  440f2845e0               movaps   xmm8, xmmword ptr [rbp - 0x20]
0000000141488ae8  440f284df0               movaps   xmm9, xmmword ptr [rbp - 0x10]
0000000141488aed  440f285500               movaps   xmm10, xmmword ptr [rbp]
0000000141488af2  440f285d10               movaps   xmm11, xmmword ptr [rbp + 0x10]
0000000141488af7  440f286520               movaps   xmm12, xmmword ptr [rbp + 0x20]
0000000141488afc  440f286d30               movaps   xmm13, xmmword ptr [rbp + 0x30]
0000000141488b01  4881c4c8000000           add      rsp, 0xc8
0000000141488b08  5b                       pop      rbx
0000000141488b09  5f                       pop      rdi
0000000141488b0a  5e                       pop      rsi
0000000141488b0b  415c                     pop      r12
0000000141488b0d  415d                     pop      r13
0000000141488b0f  415e                     pop      r14
0000000141488b11  415f                     pop      r15
0000000141488b13  5d                       pop      rbp
0000000141488b14  c3                       ret      
0000000141488b15  66662e0f1f840000000000   nop      word ptr cs:[rax + rax]
0000000141488b20  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141488b25  55                       push     rbp
0000000141488b26  4157                     push     r15
0000000141488b28  4156                     push     r14
0000000141488b2a  4155                     push     r13
0000000141488b2c  4154                     push     r12
0000000141488b2e  56                       push     rsi
0000000141488b2f  57                       push     rdi
0000000141488b30  53                       push     rbx
0000000141488b31  4881eca8000000           sub      rsp, 0xa8
0000000141488b38  488daa80000000           lea      rbp, [rdx + 0x80]
0000000141488b3f  440f296c2420             movaps   xmmword ptr [rsp + 0x20], xmm13
0000000141488b45  440f29642430             movaps   xmmword ptr [rsp + 0x30], xmm12
0000000141488b4b  440f295c2440             movaps   xmmword ptr [rsp + 0x40], xmm11
0000000141488b51  440f29542450             movaps   xmmword ptr [rsp + 0x50], xmm10
0000000141488b57  440f294c2460             movaps   xmmword ptr [rsp + 0x60], xmm9
0000000141488b5d  440f29442470             movaps   xmmword ptr [rsp + 0x70], xmm8
0000000141488b63  0f29bc2480000000         movaps   xmmword ptr [rsp + 0x80], xmm7
0000000141488b6b  0f29b42490000000         movaps   xmmword ptr [rsp + 0x90], xmm6
0000000141488b73  488b55a0                 mov      rdx, qword ptr [rbp - 0x60]
0000000141488b77  4885d2                   test     rdx, rdx
0000000141488b7a  7413                     je       0x141488b8f
0000000141488b7c  488b4da8                 mov      rcx, qword ptr [rbp - 0x58]
0000000141488b80  48c1e204                 shl      rdx, 4
0000000141488b84  41b804000000             mov      r8d, 4
0000000141488b8a  e8312f22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141488b8f  0f28b42490000000         movaps   xmm6, xmmword ptr [rsp + 0x90]
0000000141488b97  0f28bc2480000000         movaps   xmm7, xmmword ptr [rsp + 0x80]
0000000141488b9f  440f28442470             movaps   xmm8, xmmword ptr [rsp + 0x70]
0000000141488ba5  440f284c2460             movaps   xmm9, xmmword ptr [rsp + 0x60]
0000000141488bab  440f28542450             movaps   xmm10, xmmword ptr [rsp + 0x50]
0000000141488bb1  440f285c2440             movaps   xmm11, xmmword ptr [rsp + 0x40]
0000000141488bb7  440f28642430             movaps   xmm12, xmmword ptr [rsp + 0x30]
0000000141488bbd  440f286c2420             movaps   xmm13, xmmword ptr [rsp + 0x20]
0000000141488bc3  4881c4a8000000           add      rsp, 0xa8
0000000141488bca  5b                       pop      rbx
0000000141488bcb  5f                       pop      rdi
0000000141488bcc  5e                       pop      rsi
0000000141488bcd  415c                     pop      r12
0000000141488bcf  415d                     pop      r13
0000000141488bd1  415e                     pop      r14
0000000141488bd3  415f                     pop      r15
0000000141488bd5  5d                       pop      rbp
0000000141488bd6  c3                       ret      