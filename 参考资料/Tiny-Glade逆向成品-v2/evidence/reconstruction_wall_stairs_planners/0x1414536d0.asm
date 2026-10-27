00000001414536d0  55                       push     rbp
00000001414536d1  4157                     push     r15
00000001414536d3  4156                     push     r14
00000001414536d5  4155                     push     r13
00000001414536d7  4154                     push     r12
00000001414536d9  56                       push     rsi
00000001414536da  57                       push     rdi
00000001414536db  53                       push     rbx
00000001414536dc  4881ec28010000           sub      rsp, 0x128
00000001414536e3  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001414536eb  0f29bd90000000           movaps   xmmword ptr [rbp + 0x90], xmm7
00000001414536f2  0f29b580000000           movaps   xmmword ptr [rbp + 0x80], xmm6
00000001414536f9  48c74578feffffff         mov      qword ptr [rbp + 0x78], 0xfffffffffffffffe
0000000141453701  48894d30                 mov      qword ptr [rbp + 0x30], rcx
0000000141453705  48c7455800000000         mov      qword ptr [rbp + 0x58], 0
000000014145370d  48c7456008000000         mov      qword ptr [rbp + 0x60], 8
0000000141453715  48c7456800000000         mov      qword ptr [rbp + 0x68], 0
000000014145371d  488b02                   mov      rax, qword ptr [rdx]
0000000141453720  48894550                 mov      qword ptr [rbp + 0x50], rax
0000000141453724  488b4208                 mov      rax, qword ptr [rdx + 8]
0000000141453728  48894548                 mov      qword ptr [rbp + 0x48], rax
000000014145372c  488b4210                 mov      rax, qword ptr [rdx + 0x10]
0000000141453730  4885c0                   test     rax, rax
0000000141453733  0f8439010000             je       0x141453872
0000000141453739  4c89c7                   mov      rdi, r8
000000014145373c  f30f10b510010000         movss    xmm6, dword ptr [rbp + 0x110]
0000000141453744  488d0480                 lea      rax, [rax + rax*4]
0000000141453748  4c8b7548                 mov      r14, qword ptr [rbp + 0x48]
000000014145374c  498d34c6                 lea      rsi, [r14 + rax*8]
0000000141453750  4c8d7db0                 lea      r15, [rbp - 0x50]
0000000141453754  f3410f1039               movss    xmm7, dword ptr [r9]
0000000141453759  4889eb                   mov      rbx, rbp
000000014145375c  4c8d65e0                 lea      r12, [rbp - 0x20]
0000000141453760  498b06                   mov      rax, qword ptr [r14]
0000000141453763  4883f802                 cmp      rax, 2
0000000141453767  0f8405010000             je       0x141453872
000000014145376d  488945a8                 mov      qword ptr [rbp - 0x58], rax
0000000141453771  410f104608               movups   xmm0, xmmword ptr [r14 + 8]
0000000141453776  410f104e18               movups   xmm1, xmmword ptr [r14 + 0x18]
000000014145377b  410f114f10               movups   xmmword ptr [r15 + 0x10], xmm1
0000000141453780  410f1107                 movups   xmmword ptr [r15], xmm0
0000000141453784  410f104610               movups   xmm0, xmmword ptr [r14 + 0x10]
0000000141453789  0f2945d0                 movaps   xmmword ptr [rbp - 0x30], xmm0
000000014145378d  410f104610               movups   xmm0, xmmword ptr [r14 + 0x10]
0000000141453792  0f294500                 movaps   xmmword ptr [rbp], xmm0
0000000141453796  4889f9                   mov      rcx, rdi
0000000141453799  4889da                   mov      rdx, rbx
000000014145379c  0f28d7                   movaps   xmm2, xmm7
000000014145379f  e80c3a0300               call     0x1414871b0 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::classify_region_orientation | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards27classify_region_orientation17ha3620a8dc35da6cfE
00000001414537a4  90                       nop      
00000001414537a5  884576                   mov      byte ptr [rbp + 0x76], al
00000001414537a8  4889d9                   mov      rcx, rbx
00000001414537ab  488d55d0                 lea      rdx, [rbp - 0x30]
00000001414537af  4189c0                   mov      r8d, eax
00000001414537b2  0f28de                   movaps   xmm3, xmm6
00000001414537b5  e826500300               call     0x1414887e0 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::subdivide_region_into_planks | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards28subdivide_region_into_planks17h268688fde427737dE
00000001414537ba  90                       nop      
00000001414537bb  4c8b4500                 mov      r8, qword ptr [rbp]
00000001414537bf  488b4d08                 mov      rcx, qword ptr [rbp + 8]
00000001414537c3  4c8b6d10                 mov      r13, qword ptr [rbp + 0x10]
00000001414537c7  488b4558                 mov      rax, qword ptr [rbp + 0x58]
00000001414537cb  488b5568                 mov      rdx, qword ptr [rbp + 0x68]
00000001414537cf  4829d0                   sub      rax, rdx
00000001414537d2  4939c5                   cmp      r13, rax
00000001414537d5  48894d38                 mov      qword ptr [rbp + 0x38], rcx
00000001414537d9  4c894540                 mov      qword ptr [rbp + 0x40], r8
00000001414537dd  7762                     ja       0x141453841
00000001414537df  49c1e504                 shl      r13, 4
00000001414537e3  4901cd                   add      r13, rcx
00000001414537e6  488b4560                 mov      rax, qword ptr [rbp + 0x60]
00000001414537ea  48894de0                 mov      qword ptr [rbp - 0x20], rcx
00000001414537ee  48894de8                 mov      qword ptr [rbp - 0x18], rcx
00000001414537f2  4c8945f0                 mov      qword ptr [rbp - 0x10], r8
00000001414537f6  4c896df8                 mov      qword ptr [rbp - 8], r13
00000001414537fa  488d4d76                 lea      rcx, [rbp + 0x76]
00000001414537fe  48894d18                 mov      qword ptr [rbp + 0x18], rcx
0000000141453802  488d4da8                 lea      rcx, [rbp - 0x58]
0000000141453806  48894d20                 mov      qword ptr [rbp + 0x20], rcx
000000014145380a  488d4dc8                 lea      rcx, [rbp - 0x38]
000000014145380e  48894d28                 mov      qword ptr [rbp + 0x28], rcx
0000000141453812  488d4d68                 lea      rcx, [rbp + 0x68]
0000000141453816  48894d00                 mov      qword ptr [rbp], rcx
000000014145381a  48895508                 mov      qword ptr [rbp + 8], rdx
000000014145381e  48894510                 mov      qword ptr [rbp + 0x10], rax
0000000141453822  c6457701                 mov      byte ptr [rbp + 0x77], 1
0000000141453826  4c89e1                   mov      rcx, r12
0000000141453829  4889da                   mov      rdx, rbx
000000014145382c  e82f980501               call     0x1424ad060 ; _ZN103_$LT$alloc..vec..into_iter..IntoIter$LT$T$C$A$GT$$u20$as$u20$core..iter..traits..iterator..Iterator$GT$4fold17h552dee655d4672dfE | _ZN103_$LT$alloc..vec..into_iter..IntoIter$LT$T$C$A$GT$$u20$as$u20$core..iter..traits..iterator..Iterator$GT$4fold17hc4d42adb07f22cd8E
0000000141453831  90                       nop      
0000000141453832  4983c628                 add      r14, 0x28
0000000141453836  4939f6                   cmp      r14, rsi
0000000141453839  0f8521ffffff             jne      0x141453760
000000014145383f  eb31                     jmp      0x141453872
0000000141453841  c6457700                 mov      byte ptr [rbp + 0x77], 0
0000000141453845  48c744242028000000       mov      qword ptr [rsp + 0x20], 0x28
000000014145384e  41b908000000             mov      r9d, 8
0000000141453854  488d4d58                 lea      rcx, [rbp + 0x58]
0000000141453858  4d89e8                   mov      r8, r13
000000014145385b  e850b99201               call     0x142d7f1b0 ; alloc::raw_vec::impl$4::reserve::do_reserve_and_handle<alloc::alloc::Global> | _ZN5alloc7raw_vec20RawVecInner$LT$A$GT$7reserve21do_reserve_and_handle17h0559268ff9d2f5acE
0000000141453860  90                       nop      
0000000141453861  488b5568                 mov      rdx, qword ptr [rbp + 0x68]
0000000141453865  4c8b4540                 mov      r8, qword ptr [rbp + 0x40]
0000000141453869  488b4d38                 mov      rcx, qword ptr [rbp + 0x38]
000000014145386d  e96dffffff               jmp      0x1414537df
0000000141453872  488b4550                 mov      rax, qword ptr [rbp + 0x50]
0000000141453876  4885c0                   test     rax, rax
0000000141453879  7417                     je       0x141453892
000000014145387b  48c1e003                 shl      rax, 3
000000014145387f  488d1480                 lea      rdx, [rax + rax*4]
0000000141453883  41b808000000             mov      r8d, 8
0000000141453889  488b4d48                 mov      rcx, qword ptr [rbp + 0x48]
000000014145388d  e82e8225ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141453892  488b4d68                 mov      rcx, qword ptr [rbp + 0x68]
0000000141453896  488b4530                 mov      rax, qword ptr [rbp + 0x30]
000000014145389a  48894810                 mov      qword ptr [rax + 0x10], rcx
000000014145389e  0f104558                 movups   xmm0, xmmword ptr [rbp + 0x58]
00000001414538a2  0f1100                   movups   xmmword ptr [rax], xmm0
00000001414538a5  0f28b580000000           movaps   xmm6, xmmword ptr [rbp + 0x80]
00000001414538ac  0f28bd90000000           movaps   xmm7, xmmword ptr [rbp + 0x90]
00000001414538b3  4881c428010000           add      rsp, 0x128
00000001414538ba  5b                       pop      rbx
00000001414538bb  5f                       pop      rdi
00000001414538bc  5e                       pop      rsi
00000001414538bd  415c                     pop      r12
00000001414538bf  415d                     pop      r13
00000001414538c1  415e                     pop      r14
00000001414538c3  415f                     pop      r15
00000001414538c5  5d                       pop      rbp
00000001414538c6  c3                       ret      
00000001414538c7  660f1f840000000000       nop      word ptr [rax + rax]
00000001414538d0  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001414538d5  55                       push     rbp
00000001414538d6  4157                     push     r15
00000001414538d8  4156                     push     r14
00000001414538da  4155                     push     r13
00000001414538dc  4154                     push     r12
00000001414538de  56                       push     rsi
00000001414538df  57                       push     rdi
00000001414538e0  53                       push     rbx
00000001414538e1  4883ec48                 sub      rsp, 0x48
00000001414538e5  488daa80000000           lea      rbp, [rdx + 0x80]
00000001414538ec  0f297c2420               movaps   xmmword ptr [rsp + 0x20], xmm7
00000001414538f1  0f29742430               movaps   xmmword ptr [rsp + 0x30], xmm6
00000001414538f6  48837d5000               cmp      qword ptr [rbp + 0x50], 0
00000001414538fb  741b                     je       0x141453918
00000001414538fd  488b4550                 mov      rax, qword ptr [rbp + 0x50]
0000000141453901  48c1e003                 shl      rax, 3
0000000141453905  488d1480                 lea      rdx, [rax + rax*4]
0000000141453909  41b808000000             mov      r8d, 8
000000014145390f  488b4d48                 mov      rcx, qword ptr [rbp + 0x48]
0000000141453913  e8a88125ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141453918  488b4558                 mov      rax, qword ptr [rbp + 0x58]
000000014145391c  4885c0                   test     rax, rax
000000014145391f  7417                     je       0x141453938
0000000141453921  488b4d60                 mov      rcx, qword ptr [rbp + 0x60]
0000000141453925  48c1e003                 shl      rax, 3
0000000141453929  488d1480                 lea      rdx, [rax + rax*4]
000000014145392d  41b808000000             mov      r8d, 8
0000000141453933  e8888125ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141453938  0f28742430               movaps   xmm6, xmmword ptr [rsp + 0x30]
000000014145393d  0f287c2420               movaps   xmm7, xmmword ptr [rsp + 0x20]
0000000141453942  4883c448                 add      rsp, 0x48
0000000141453946  5b                       pop      rbx
0000000141453947  5f                       pop      rdi
0000000141453948  5e                       pop      rsi
0000000141453949  415c                     pop      r12
000000014145394b  415d                     pop      r13
000000014145394d  415e                     pop      r14
000000014145394f  415f                     pop      r15
0000000141453951  5d                       pop      rbp
0000000141453952  c3                       ret      
0000000141453953  666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141453960  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141453965  55                       push     rbp
0000000141453966  4157                     push     r15
0000000141453968  4156                     push     r14
000000014145396a  4155                     push     r13
000000014145396c  4154                     push     r12
000000014145396e  56                       push     rsi
000000014145396f  57                       push     rdi
0000000141453970  53                       push     rbx
0000000141453971  4883ec48                 sub      rsp, 0x48
0000000141453975  488daa80000000           lea      rbp, [rdx + 0x80]
000000014145397c  0f297c2420               movaps   xmmword ptr [rsp + 0x20], xmm7
0000000141453981  0f29742430               movaps   xmmword ptr [rsp + 0x30], xmm6
0000000141453986  488b4d38                 mov      rcx, qword ptr [rbp + 0x38]
000000014145398a  488b4540                 mov      rax, qword ptr [rbp + 0x40]
000000014145398e  4889c2                   mov      rdx, rax
0000000141453991  4885c0                   test     rax, rax
0000000141453994  0f94c0                   sete     al
0000000141453997  0a4577                   or       al, byte ptr [rbp + 0x77]
000000014145399a  a801                     test     al, 1
000000014145399c  750f                     jne      0x1414539ad
000000014145399e  48c1e204                 shl      rdx, 4
00000001414539a2  41b804000000             mov      r8d, 4
00000001414539a8  e8138125ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001414539ad  0f28742430               movaps   xmm6, xmmword ptr [rsp + 0x30]
00000001414539b2  0f287c2420               movaps   xmm7, xmmword ptr [rsp + 0x20]
00000001414539b7  4883c448                 add      rsp, 0x48
00000001414539bb  5b                       pop      rbx
00000001414539bc  5f                       pop      rdi
00000001414539bd  5e                       pop      rsi
00000001414539be  415c                     pop      r12
00000001414539c0  415d                     pop      r13
00000001414539c2  415e                     pop      r14
00000001414539c4  415f                     pop      r15
00000001414539c6  5d                       pop      rbp
00000001414539c7  c3                       ret      