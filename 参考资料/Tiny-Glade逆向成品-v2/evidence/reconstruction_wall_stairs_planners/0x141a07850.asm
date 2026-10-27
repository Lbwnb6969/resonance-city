0000000141a07850  56                       push     rsi
0000000141a07851  57                       push     rdi
0000000141a07852  4883ec28                 sub      rsp, 0x28
0000000141a07856  488b4110                 mov      rax, qword ptr [rcx + 0x10]
0000000141a0785a  4189d2                   mov      r10d, edx
0000000141a0785d  4c395010                 cmp      qword ptr [rax + 0x10], r10
0000000141a07861  0f86e6000000             jbe      0x141a0794d
0000000141a07867  488b7008                 mov      rsi, qword ptr [rax + 8]
0000000141a0786b  4b8d0452                 lea      rax, [r10 + r10*2]
0000000141a0786f  48c1e006                 shl      rax, 6
0000000141a07873  833c0601                 cmp      dword ptr [rsi + rax], 1
0000000141a07877  0f85d0000000             jne      0x141a0794d
0000000141a0787d  4801c6                   add      rsi, rax
0000000141a07880  44394604                 cmp      dword ptr [rsi + 4], r8d
0000000141a07884  0f85c3000000             jne      0x141a0794d
0000000141a0788a  4c8d5610                 lea      r10, [rsi + 0x10]
0000000141a0788e  488b4108                 mov      rax, qword ptr [rcx + 8]
0000000141a07892  4883c118                 add      rcx, 0x18
0000000141a07896  4c89542420               mov      qword ptr [rsp + 0x20], r10
0000000141a0789b  4189d2                   mov      r10d, edx
0000000141a0789e  4889c2                   mov      rdx, rax
0000000141a078a1  4489c0                   mov      eax, r8d
0000000141a078a4  4589d0                   mov      r8d, r10d
0000000141a078a7  4c89cf                   mov      rdi, r9
0000000141a078aa  4189c1                   mov      r9d, eax
0000000141a078ad  e8ae0a0000               call     0x141a08360 ; rapier3d::pipeline::query_pipeline::QueryFilter::test | _ZN8rapier3d8pipeline14query_pipeline11QueryFilter4test17h09f5b8b69af84fa4E.llvm.6907936326697837321
0000000141a078b2  84c0                     test     al, al
0000000141a078b4  0f8493000000             je       0x141a0794d
0000000141a078ba  488d5644                 lea      rdx, [rsi + 0x44]
0000000141a078be  488b4620                 mov      rax, qword ptr [rsi + 0x20]
0000000141a078c2  4c8b5628                 mov      r10, qword ptr [rsi + 0x28]
0000000141a078c6  498b4a10                 mov      rcx, qword ptr [r10 + 0x10]
0000000141a078ca  48ffc9                   dec      rcx
0000000141a078cd  4883e1f0                 and      rcx, 0xfffffffffffffff0
0000000141a078d1  4801c1                   add      rcx, rax
0000000141a078d4  4883c110                 add      rcx, 0x10
0000000141a078d8  4c8b07                   mov      r8, qword ptr [rdi]
0000000141a078db  488b4708                 mov      rax, qword ptr [rdi + 8]
0000000141a078df  f30f1018                 movss    xmm3, dword ptr [rax]
0000000141a078e3  488b4710                 mov      rax, qword ptr [rdi + 0x10]
0000000141a078e7  0fb600                   movzx    eax, byte ptr [rax]
0000000141a078ea  88442420                 mov      byte ptr [rsp + 0x20], al
0000000141a078ee  41ff5230                 call     qword ptr [r10 + 0x30]
0000000141a078f2  a801                     test     al, 1
0000000141a078f4  7457                     je       0x141a0794d
0000000141a078f6  4889fa                   mov      rdx, rdi
0000000141a078f9  488b4720                 mov      rax, qword ptr [rdi + 0x20]
0000000141a078fd  488b08                   mov      rcx, qword ptr [rax]
0000000141a07900  4883f903                 cmp      rcx, 3
0000000141a07904  774e                     ja       0x141a07954
0000000141a07906  4c8b4218                 mov      r8, qword ptr [rdx + 0x18]
0000000141a0790a  4c8b4a28                 mov      r9, qword ptr [rdx + 0x28]
0000000141a0790e  4d8b09                   mov      r9, qword ptr [r9]
0000000141a07911  48c1e104                 shl      rcx, 4
0000000141a07915  41c7040801000000         mov      dword ptr [r8 + rcx], 1
0000000141a0791d  4d894c0804               mov      qword ptr [r8 + rcx + 4], r9
0000000141a07922  f3410f1144080c           movss    dword ptr [r8 + rcx + 0xc], xmm0
0000000141a07929  488b08                   mov      rcx, qword ptr [rax]
0000000141a0792c  4883f904                 cmp      rcx, 4
0000000141a07930  7333                     jae      0x141a07965
0000000141a07932  4c8b4230                 mov      r8, qword ptr [rdx + 0x30]
0000000141a07936  41c6040801               mov      byte ptr [r8 + rcx], 1
0000000141a0793b  488b08                   mov      rcx, qword ptr [rax]
0000000141a0793e  4883f904                 cmp      rcx, 4
0000000141a07942  7332                     jae      0x141a07976
0000000141a07944  488b4238                 mov      rax, qword ptr [rdx + 0x38]
0000000141a07948  f30f110488               movss    dword ptr [rax + rcx*4], xmm0
0000000141a0794d  4883c428                 add      rsp, 0x28
0000000141a07951  5f                       pop      rdi
0000000141a07952  5e                       pop      rsi
0000000141a07953  c3                       ret      
0000000141a07954  4c8d05e5a49501           lea      r8, [rip + 0x195a4e5]
0000000141a0795b  ba04000000               mov      edx, 4
0000000141a07960  e88d083c01               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
0000000141a07965  4c8d05eca49501           lea      r8, [rip + 0x195a4ec]
0000000141a0796c  ba04000000               mov      edx, 4
0000000141a07971  e87c083c01               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
0000000141a07976  4c8d05f3a49501           lea      r8, [rip + 0x195a4f3]
0000000141a0797d  ba04000000               mov      edx, 4
0000000141a07982  e86b083c01               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
0000000141a07987  cc                       int3     