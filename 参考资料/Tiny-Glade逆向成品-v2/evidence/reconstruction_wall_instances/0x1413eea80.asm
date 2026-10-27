00000001413eea80  55                       push     rbp
00000001413eea81  4157                     push     r15
00000001413eea83  4156                     push     r14
00000001413eea85  4155                     push     r13
00000001413eea87  4154                     push     r12
00000001413eea89  56                       push     rsi
00000001413eea8a  57                       push     rdi
00000001413eea8b  53                       push     rbx
00000001413eea8c  4881ec98000000           sub      rsp, 0x98
00000001413eea93  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001413eea9b  440f294500               movaps   xmmword ptr [rbp], xmm8
00000001413eeaa0  0f297df0                 movaps   xmmword ptr [rbp - 0x10], xmm7
00000001413eeaa4  0f2975e0                 movaps   xmmword ptr [rbp - 0x20], xmm6
00000001413eeaa8  48c745d8feffffff         mov      qword ptr [rbp - 0x28], 0xfffffffffffffffe
00000001413eeab0  4889ce                   mov      rsi, rcx
00000001413eeab3  4c8b7220                 mov      r14, qword ptr [rdx + 0x20]
00000001413eeab7  4c8b7a28                 mov      r15, qword ptr [rdx + 0x28]
00000001413eeabb  4d39fe                   cmp      r14, r15
00000001413eeabe  0f83ba000000             jae      0x1413eeb7e
00000001413eeac4  488b02                   mov      rax, qword ptr [rdx]
00000001413eeac7  488b4a08                 mov      rcx, qword ptr [rdx + 8]
00000001413eeacb  488945b0                 mov      qword ptr [rbp - 0x50], rax
00000001413eeacf  f30f1000                 movss    xmm0, dword ptr [rax]
00000001413eead3  48894db8                 mov      qword ptr [rbp - 0x48], rcx
00000001413eead7  f30f1009                 movss    xmm1, dword ptr [rcx]
00000001413eeadb  488b5a10                 mov      rbx, qword ptr [rdx + 0x10]
00000001413eeadf  488b03                   mov      rax, qword ptr [rbx]
00000001413eeae2  48ffc8                   dec      rax
00000001413eeae5  4c8b6218                 mov      r12, qword ptr [rdx + 0x18]
00000001413eeae9  f30f1035e38fa401         movss    xmm6, dword ptr [rip + 0x1a48fe3]
00000001413eeaf1  6666666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001413eeb00  4d85f6                   test     r14, r14
00000001413eeb03  780b                     js       0x1413eeb10
00000001413eeb05  0f57ff                   xorps    xmm7, xmm7
00000001413eeb08  f3490f2afe               cvtsi2ss xmm7, r14
00000001413eeb0d  eb1c                     jmp      0x1413eeb2b
00000001413eeb0f  90                       nop      
00000001413eeb10  4c89f1                   mov      rcx, r14
00000001413eeb13  48d1e9                   shr      rcx, 1
00000001413eeb16  4489f2                   mov      edx, r14d
00000001413eeb19  83e201                   and      edx, 1
00000001413eeb1c  4809ca                   or       rdx, rcx
00000001413eeb1f  0f57ff                   xorps    xmm7, xmm7
00000001413eeb22  f3480f2afa               cvtsi2ss xmm7, rdx
00000001413eeb27  f30f58ff                 addss    xmm7, xmm7
00000001413eeb2b  f30f59f9                 mulss    xmm7, xmm1
00000001413eeb2f  f30f58ff                 addss    xmm7, xmm7
00000001413eeb33  f30f58f8                 addss    xmm7, xmm0
00000001413eeb37  4c39f0                   cmp      rax, r14
00000001413eeb3a  7524                     jne      0x1413eeb60
00000001413eeb3c  f3450f100424             movss    xmm8, dword ptr [r12]
00000001413eeb42  410f28d0                 movaps   xmm2, xmm8
00000001413eeb46  f30f5cd7                 subss    xmm2, xmm7
00000001413eeb4a  0f2ed6                   ucomiss  xmm2, xmm6
00000001413eeb4d  7227                     jb       0x1413eeb76
00000001413eeb4f  eb49                     jmp      0x1413eeb9a
00000001413eeb51  6666666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001413eeb60  440f28c1                 movaps   xmm8, xmm1
00000001413eeb64  f3440f58c7               addss    xmm8, xmm7
00000001413eeb69  410f28d0                 movaps   xmm2, xmm8
00000001413eeb6d  f30f5cd7                 subss    xmm2, xmm7
00000001413eeb71  0f2ed6                   ucomiss  xmm2, xmm6
00000001413eeb74  7324                     jae      0x1413eeb9a
00000001413eeb76  49ffc6                   inc      r14
00000001413eeb79  4d39f7                   cmp      r15, r14
00000001413eeb7c  7582                     jne      0x1413eeb00
00000001413eeb7e  48c70600000000           mov      qword ptr [rsi], 0
00000001413eeb85  48c7460804000000         mov      qword ptr [rsi + 8], 4
00000001413eeb8d  48c7461000000000         mov      qword ptr [rsi + 0x10], 0
00000001413eeb95  e94d010000               jmp      0x1413eece7
00000001413eeb9a  e8c102c9fe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
00000001413eeb9f  b920000000               mov      ecx, 0x20
00000001413eeba4  ba04000000               mov      edx, 4
00000001413eeba9  e802cf2bff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
00000001413eebae  4885c0                   test     rax, rax
00000001413eebb1  0f8454010000             je       0x1413eed0b
00000001413eebb7  49ffc6                   inc      r14
00000001413eebba  f30f1138                 movss    dword ptr [rax], xmm7
00000001413eebbe  f3440f114004             movss    dword ptr [rax + 4], xmm8
00000001413eebc4  48c745c004000000         mov      qword ptr [rbp - 0x40], 4
00000001413eebcc  488945c8                 mov      qword ptr [rbp - 0x38], rax
00000001413eebd0  48c745d001000000         mov      qword ptr [rbp - 0x30], 1
00000001413eebd8  4d39fe                   cmp      r14, r15
00000001413eebdb  0f83ef000000             jae      0x1413eecd0
00000001413eebe1  bf01000000               mov      edi, 1
00000001413eebe6  4c8d55c0                 lea      r10, [rbp - 0x40]
00000001413eebea  488b4db0                 mov      rcx, qword ptr [rbp - 0x50]
00000001413eebee  f30f1001                 movss    xmm0, dword ptr [rcx]
00000001413eebf2  488b4db8                 mov      rcx, qword ptr [rbp - 0x48]
00000001413eebf6  f30f1009                 movss    xmm1, dword ptr [rcx]
00000001413eebfa  488b0b                   mov      rcx, qword ptr [rbx]
00000001413eebfd  48ffc9                   dec      rcx
00000001413eec00  4d85f6                   test     r14, r14
00000001413eec03  780b                     js       0x1413eec10
00000001413eec05  0f57ff                   xorps    xmm7, xmm7
00000001413eec08  f3490f2afe               cvtsi2ss xmm7, r14
00000001413eec0d  eb1d                     jmp      0x1413eec2c
00000001413eec0f  90                       nop      
00000001413eec10  4c89f2                   mov      rdx, r14
00000001413eec13  48d1ea                   shr      rdx, 1
00000001413eec16  4589f0                   mov      r8d, r14d
00000001413eec19  4183e001                 and      r8d, 1
00000001413eec1d  4909d0                   or       r8, rdx
00000001413eec20  0f57ff                   xorps    xmm7, xmm7
00000001413eec23  f3490f2af8               cvtsi2ss xmm7, r8
00000001413eec28  f30f58ff                 addss    xmm7, xmm7
00000001413eec2c  f30f59f9                 mulss    xmm7, xmm1
00000001413eec30  f30f58ff                 addss    xmm7, xmm7
00000001413eec34  f30f58f8                 addss    xmm7, xmm0
00000001413eec38  4c39f1                   cmp      rcx, r14
00000001413eec3b  7523                     jne      0x1413eec60
00000001413eec3d  f3450f100424             movss    xmm8, dword ptr [r12]
00000001413eec43  410f28d0                 movaps   xmm2, xmm8
00000001413eec47  f30f5cd7                 subss    xmm2, xmm7
00000001413eec4b  0f2ed6                   ucomiss  xmm2, xmm6
00000001413eec4e  7226                     jb       0x1413eec76
00000001413eec50  eb2e                     jmp      0x1413eec80
00000001413eec52  66666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001413eec60  440f28c1                 movaps   xmm8, xmm1
00000001413eec64  f3440f58c7               addss    xmm8, xmm7
00000001413eec69  410f28d0                 movaps   xmm2, xmm8
00000001413eec6d  f30f5cd7                 subss    xmm2, xmm7
00000001413eec71  0f2ed6                   ucomiss  xmm2, xmm6
00000001413eec74  730a                     jae      0x1413eec80
00000001413eec76  49ffc6                   inc      r14
00000001413eec79  4d39f7                   cmp      r15, r14
00000001413eec7c  7582                     jne      0x1413eec00
00000001413eec7e  eb50                     jmp      0x1413eecd0
00000001413eec80  483b7dc0                 cmp      rdi, qword ptr [rbp - 0x40]
00000001413eec84  752b                     jne      0x1413eecb1
00000001413eec86  48c744242008000000       mov      qword ptr [rsp + 0x20], 8
00000001413eec8f  41b801000000             mov      r8d, 1
00000001413eec95  41b904000000             mov      r9d, 4
00000001413eec9b  4d89d5                   mov      r13, r10
00000001413eec9e  4c89d1                   mov      rcx, r10
00000001413eeca1  4889fa                   mov      rdx, rdi
00000001413eeca4  e807059901               call     0x142d7f1b0 ; alloc::raw_vec::impl$4::reserve::do_reserve_and_handle<alloc::alloc::Global> | _ZN5alloc7raw_vec20RawVecInner$LT$A$GT$7reserve21do_reserve_and_handle17h0559268ff9d2f5acE
00000001413eeca9  90                       nop      
00000001413eecaa  488b45c8                 mov      rax, qword ptr [rbp - 0x38]
00000001413eecae  4d89ea                   mov      r10, r13
00000001413eecb1  49ffc6                   inc      r14
00000001413eecb4  f30f113cf8               movss    dword ptr [rax + rdi*8], xmm7
00000001413eecb9  f3440f1144f804           movss    dword ptr [rax + rdi*8 + 4], xmm8
00000001413eecc0  48ffc7                   inc      rdi
00000001413eecc3  48897dd0                 mov      qword ptr [rbp - 0x30], rdi
00000001413eecc7  4d39fe                   cmp      r14, r15
00000001413eecca  0f821affffff             jb       0x1413eebea
00000001413eecd0  488b45d0                 mov      rax, qword ptr [rbp - 0x30]
00000001413eecd4  48894610                 mov      qword ptr [rsi + 0x10], rax
00000001413eecd8  488b45c0                 mov      rax, qword ptr [rbp - 0x40]
00000001413eecdc  488906                   mov      qword ptr [rsi], rax
00000001413eecdf  488b45c8                 mov      rax, qword ptr [rbp - 0x38]
00000001413eece3  48894608                 mov      qword ptr [rsi + 8], rax
00000001413eece7  4889f0                   mov      rax, rsi
00000001413eecea  0f2875e0                 movaps   xmm6, xmmword ptr [rbp - 0x20]
00000001413eecee  0f287df0                 movaps   xmm7, xmmword ptr [rbp - 0x10]
00000001413eecf2  440f284500               movaps   xmm8, xmmword ptr [rbp]
00000001413eecf7  4881c498000000           add      rsp, 0x98
00000001413eecfe  5b                       pop      rbx
00000001413eecff  5f                       pop      rdi
00000001413eed00  5e                       pop      rsi
00000001413eed01  415c                     pop      r12
00000001413eed03  415d                     pop      r13
00000001413eed05  415e                     pop      r14
00000001413eed07  415f                     pop      r15
00000001413eed09  5d                       pop      rbp
00000001413eed0a  c3                       ret      
00000001413eed0b  b904000000               mov      ecx, 4
00000001413eed10  ba20000000               mov      edx, 0x20
00000001413eed15  e810919d01               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
00000001413eed1a  cc                       int3     
00000001413eed1b  0f1f440000               nop      dword ptr [rax + rax]
00000001413eed20  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001413eed25  55                       push     rbp
00000001413eed26  4157                     push     r15
00000001413eed28  4156                     push     r14
00000001413eed2a  4155                     push     r13
00000001413eed2c  4154                     push     r12
00000001413eed2e  56                       push     rsi
00000001413eed2f  57                       push     rdi
00000001413eed30  53                       push     rbx
00000001413eed31  4883ec58                 sub      rsp, 0x58
00000001413eed35  488daa80000000           lea      rbp, [rdx + 0x80]
00000001413eed3c  440f29442420             movaps   xmmword ptr [rsp + 0x20], xmm8
00000001413eed42  0f297c2430               movaps   xmmword ptr [rsp + 0x30], xmm7
00000001413eed47  0f29742440               movaps   xmmword ptr [rsp + 0x40], xmm6
00000001413eed4c  488b55c0                 mov      rdx, qword ptr [rbp - 0x40]
00000001413eed50  4885d2                   test     rdx, rdx
00000001413eed53  7413                     je       0x1413eed68
00000001413eed55  488b4dc8                 mov      rcx, qword ptr [rbp - 0x38]
00000001413eed59  48c1e203                 shl      rdx, 3
00000001413eed5d  41b804000000             mov      r8d, 4
00000001413eed63  e858cd2bff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413eed68  0f28742440               movaps   xmm6, xmmword ptr [rsp + 0x40]
00000001413eed6d  0f287c2430               movaps   xmm7, xmmword ptr [rsp + 0x30]
00000001413eed72  440f28442420             movaps   xmm8, xmmword ptr [rsp + 0x20]
00000001413eed78  4883c458                 add      rsp, 0x58
00000001413eed7c  5b                       pop      rbx
00000001413eed7d  5f                       pop      rdi
00000001413eed7e  5e                       pop      rsi
00000001413eed7f  415c                     pop      r12
00000001413eed81  415d                     pop      r13
00000001413eed83  415e                     pop      r14
00000001413eed85  415f                     pop      r15
00000001413eed87  5d                       pop      rbp
00000001413eed88  c3                       ret      