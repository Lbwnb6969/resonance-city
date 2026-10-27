0000000141453410  55                       push     rbp
0000000141453411  4157                     push     r15
0000000141453413  4156                     push     r14
0000000141453415  4155                     push     r13
0000000141453417  4154                     push     r12
0000000141453419  56                       push     rsi
000000014145341a  57                       push     rdi
000000014145341b  53                       push     rbx
000000014145341c  4881ec18010000           sub      rsp, 0x118
0000000141453423  488dac2480000000         lea      rbp, [rsp + 0x80]
000000014145342b  0f29b580000000           movaps   xmmword ptr [rbp + 0x80], xmm6
0000000141453432  48c74578feffffff         mov      qword ptr [rbp + 0x78], 0xfffffffffffffffe
000000014145343a  48894d30                 mov      qword ptr [rbp + 0x30], rcx
000000014145343e  48c7455800000000         mov      qword ptr [rbp + 0x58], 0
0000000141453446  48c7456008000000         mov      qword ptr [rbp + 0x60], 8
000000014145344e  48c7456800000000         mov      qword ptr [rbp + 0x68], 0
0000000141453456  488b02                   mov      rax, qword ptr [rdx]
0000000141453459  48894550                 mov      qword ptr [rbp + 0x50], rax
000000014145345d  488b4208                 mov      rax, qword ptr [rdx + 8]
0000000141453461  48894548                 mov      qword ptr [rbp + 0x48], rax
0000000141453465  488b4210                 mov      rax, qword ptr [rdx + 0x10]
0000000141453469  4885c0                   test     rax, rax
000000014145346c  0f8424010000             je       0x141453596
0000000141453472  0f28f2                   movaps   xmm6, xmm2
0000000141453475  488d0480                 lea      rax, [rax + rax*4]
0000000141453479  4c8b6d48                 mov      r13, qword ptr [rbp + 0x48]
000000014145347d  4c8d34c500000000         lea      r14, [rax*8]
0000000141453485  4d01ee                   add      r14, r13
0000000141453488  488d75b0                 lea      rsi, [rbp - 0x50]
000000014145348c  4889ef                   mov      rdi, rbp
000000014145348f  488d5da8                 lea      rbx, [rbp - 0x58]
0000000141453493  4c8d7de0                 lea      r15, [rbp - 0x20]
0000000141453497  660f1f840000000000       nop      word ptr [rax + rax]
00000001414534a0  498b4500                 mov      rax, qword ptr [r13]
00000001414534a4  4883f802                 cmp      rax, 2
00000001414534a8  0f84e8000000             je       0x141453596
00000001414534ae  488945a8                 mov      qword ptr [rbp - 0x58], rax
00000001414534b2  410f104508               movups   xmm0, xmmword ptr [r13 + 8]
00000001414534b7  410f104d18               movups   xmm1, xmmword ptr [r13 + 0x18]
00000001414534bc  0f114e10                 movups   xmmword ptr [rsi + 0x10], xmm1
00000001414534c0  0f1106                   movups   xmmword ptr [rsi], xmm0
00000001414534c3  410f104510               movups   xmm0, xmmword ptr [r13 + 0x10]
00000001414534c8  0f2945d0                 movaps   xmmword ptr [rbp - 0x30], xmm0
00000001414534cc  c6457601                 mov      byte ptr [rbp + 0x76], 1
00000001414534d0  4889f9                   mov      rcx, rdi
00000001414534d3  488d55d0                 lea      rdx, [rbp - 0x30]
00000001414534d7  41b001                   mov      r8b, 1
00000001414534da  0f28de                   movaps   xmm3, xmm6
00000001414534dd  e8fe520300               call     0x1414887e0 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::subdivide_region_into_planks | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards28subdivide_region_into_planks17h268688fde427737dE
00000001414534e2  90                       nop      
00000001414534e3  4c8b4500                 mov      r8, qword ptr [rbp]
00000001414534e7  488b4d08                 mov      rcx, qword ptr [rbp + 8]
00000001414534eb  4c8b6510                 mov      r12, qword ptr [rbp + 0x10]
00000001414534ef  488b4558                 mov      rax, qword ptr [rbp + 0x58]
00000001414534f3  488b5568                 mov      rdx, qword ptr [rbp + 0x68]
00000001414534f7  4829d0                   sub      rax, rdx
00000001414534fa  4939c4                   cmp      r12, rax
00000001414534fd  48894d38                 mov      qword ptr [rbp + 0x38], rcx
0000000141453501  4c894540                 mov      qword ptr [rbp + 0x40], r8
0000000141453505  775e                     ja       0x141453565
0000000141453507  49c1e404                 shl      r12, 4
000000014145350b  4901cc                   add      r12, rcx
000000014145350e  488b4560                 mov      rax, qword ptr [rbp + 0x60]
0000000141453512  48894de0                 mov      qword ptr [rbp - 0x20], rcx
0000000141453516  48894de8                 mov      qword ptr [rbp - 0x18], rcx
000000014145351a  4c8945f0                 mov      qword ptr [rbp - 0x10], r8
000000014145351e  4c8965f8                 mov      qword ptr [rbp - 8], r12
0000000141453522  488d4d76                 lea      rcx, [rbp + 0x76]
0000000141453526  48894d18                 mov      qword ptr [rbp + 0x18], rcx
000000014145352a  48895d20                 mov      qword ptr [rbp + 0x20], rbx
000000014145352e  488d4dc8                 lea      rcx, [rbp - 0x38]
0000000141453532  48894d28                 mov      qword ptr [rbp + 0x28], rcx
0000000141453536  488d4d68                 lea      rcx, [rbp + 0x68]
000000014145353a  48894d00                 mov      qword ptr [rbp], rcx
000000014145353e  48895508                 mov      qword ptr [rbp + 8], rdx
0000000141453542  48894510                 mov      qword ptr [rbp + 0x10], rax
0000000141453546  c6457701                 mov      byte ptr [rbp + 0x77], 1
000000014145354a  4c89f9                   mov      rcx, r15
000000014145354d  4889fa                   mov      rdx, rdi
0000000141453550  e80b9b0501               call     0x1424ad060 ; _ZN103_$LT$alloc..vec..into_iter..IntoIter$LT$T$C$A$GT$$u20$as$u20$core..iter..traits..iterator..Iterator$GT$4fold17h552dee655d4672dfE | _ZN103_$LT$alloc..vec..into_iter..IntoIter$LT$T$C$A$GT$$u20$as$u20$core..iter..traits..iterator..Iterator$GT$4fold17hc4d42adb07f22cd8E
0000000141453555  90                       nop      
0000000141453556  4983c528                 add      r13, 0x28
000000014145355a  4d39f5                   cmp      r13, r14
000000014145355d  0f853dffffff             jne      0x1414534a0
0000000141453563  eb31                     jmp      0x141453596
0000000141453565  c6457700                 mov      byte ptr [rbp + 0x77], 0
0000000141453569  48c744242028000000       mov      qword ptr [rsp + 0x20], 0x28
0000000141453572  41b908000000             mov      r9d, 8
0000000141453578  488d4d58                 lea      rcx, [rbp + 0x58]
000000014145357c  4d89e0                   mov      r8, r12
000000014145357f  e82cbc9201               call     0x142d7f1b0 ; alloc::raw_vec::impl$4::reserve::do_reserve_and_handle<alloc::alloc::Global> | _ZN5alloc7raw_vec20RawVecInner$LT$A$GT$7reserve21do_reserve_and_handle17h0559268ff9d2f5acE
0000000141453584  90                       nop      
0000000141453585  488b5568                 mov      rdx, qword ptr [rbp + 0x68]
0000000141453589  4c8b4540                 mov      r8, qword ptr [rbp + 0x40]
000000014145358d  488b4d38                 mov      rcx, qword ptr [rbp + 0x38]
0000000141453591  e971ffffff               jmp      0x141453507
0000000141453596  488b4550                 mov      rax, qword ptr [rbp + 0x50]
000000014145359a  4885c0                   test     rax, rax
000000014145359d  7417                     je       0x1414535b6
000000014145359f  48c1e003                 shl      rax, 3
00000001414535a3  488d1480                 lea      rdx, [rax + rax*4]
00000001414535a7  41b808000000             mov      r8d, 8
00000001414535ad  488b4d48                 mov      rcx, qword ptr [rbp + 0x48]
00000001414535b1  e80a8525ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001414535b6  488b4d68                 mov      rcx, qword ptr [rbp + 0x68]
00000001414535ba  488b4530                 mov      rax, qword ptr [rbp + 0x30]
00000001414535be  48894810                 mov      qword ptr [rax + 0x10], rcx
00000001414535c2  0f104558                 movups   xmm0, xmmword ptr [rbp + 0x58]
00000001414535c6  0f1100                   movups   xmmword ptr [rax], xmm0
00000001414535c9  0f28b580000000           movaps   xmm6, xmmword ptr [rbp + 0x80]
00000001414535d0  4881c418010000           add      rsp, 0x118
00000001414535d7  5b                       pop      rbx
00000001414535d8  5f                       pop      rdi
00000001414535d9  5e                       pop      rsi
00000001414535da  415c                     pop      r12
00000001414535dc  415d                     pop      r13
00000001414535de  415e                     pop      r14
00000001414535e0  415f                     pop      r15
00000001414535e2  5d                       pop      rbp
00000001414535e3  c3                       ret      
00000001414535e4  6666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001414535f0  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001414535f5  55                       push     rbp
00000001414535f6  4157                     push     r15
00000001414535f8  4156                     push     r14
00000001414535fa  4155                     push     r13
00000001414535fc  4154                     push     r12
00000001414535fe  56                       push     rsi
00000001414535ff  57                       push     rdi
0000000141453600  53                       push     rbx
0000000141453601  4883ec38                 sub      rsp, 0x38
0000000141453605  488daa80000000           lea      rbp, [rdx + 0x80]
000000014145360c  0f29742420               movaps   xmmword ptr [rsp + 0x20], xmm6
0000000141453611  48837d5000               cmp      qword ptr [rbp + 0x50], 0
0000000141453616  741b                     je       0x141453633
0000000141453618  488b4550                 mov      rax, qword ptr [rbp + 0x50]
000000014145361c  48c1e003                 shl      rax, 3
0000000141453620  488d1480                 lea      rdx, [rax + rax*4]
0000000141453624  41b808000000             mov      r8d, 8
000000014145362a  488b4d48                 mov      rcx, qword ptr [rbp + 0x48]
000000014145362e  e88d8425ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141453633  488b4558                 mov      rax, qword ptr [rbp + 0x58]
0000000141453637  4885c0                   test     rax, rax
000000014145363a  7417                     je       0x141453653
000000014145363c  488b4d60                 mov      rcx, qword ptr [rbp + 0x60]
0000000141453640  48c1e003                 shl      rax, 3
0000000141453644  488d1480                 lea      rdx, [rax + rax*4]
0000000141453648  41b808000000             mov      r8d, 8
000000014145364e  e86d8425ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141453653  0f28742420               movaps   xmm6, xmmword ptr [rsp + 0x20]
0000000141453658  4883c438                 add      rsp, 0x38
000000014145365c  5b                       pop      rbx
000000014145365d  5f                       pop      rdi
000000014145365e  5e                       pop      rsi
000000014145365f  415c                     pop      r12
0000000141453661  415d                     pop      r13
0000000141453663  415e                     pop      r14
0000000141453665  415f                     pop      r15
0000000141453667  5d                       pop      rbp
0000000141453668  c3                       ret      
0000000141453669  0f1f8000000000           nop      dword ptr [rax]
0000000141453670  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141453675  55                       push     rbp
0000000141453676  4157                     push     r15
0000000141453678  4156                     push     r14
000000014145367a  4155                     push     r13
000000014145367c  4154                     push     r12
000000014145367e  56                       push     rsi
000000014145367f  57                       push     rdi
0000000141453680  53                       push     rbx
0000000141453681  4883ec38                 sub      rsp, 0x38
0000000141453685  488daa80000000           lea      rbp, [rdx + 0x80]
000000014145368c  0f29742420               movaps   xmmword ptr [rsp + 0x20], xmm6
0000000141453691  488b4d38                 mov      rcx, qword ptr [rbp + 0x38]
0000000141453695  488b4540                 mov      rax, qword ptr [rbp + 0x40]
0000000141453699  4889c2                   mov      rdx, rax
000000014145369c  4885c0                   test     rax, rax
000000014145369f  0f94c0                   sete     al
00000001414536a2  0a4577                   or       al, byte ptr [rbp + 0x77]
00000001414536a5  a801                     test     al, 1
00000001414536a7  750f                     jne      0x1414536b8
00000001414536a9  48c1e204                 shl      rdx, 4
00000001414536ad  41b804000000             mov      r8d, 4
00000001414536b3  e8088425ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001414536b8  0f28742420               movaps   xmm6, xmmword ptr [rsp + 0x20]
00000001414536bd  4883c438                 add      rsp, 0x38
00000001414536c1  5b                       pop      rbx
00000001414536c2  5f                       pop      rdi
00000001414536c3  5e                       pop      rsi
00000001414536c4  415c                     pop      r12
00000001414536c6  415d                     pop      r13
00000001414536c8  415e                     pop      r14
00000001414536ca  415f                     pop      r15
00000001414536cc  5d                       pop      rbp
00000001414536cd  c3                       ret      