00000001413e5580  55                       push     rbp
00000001413e5581  4157                     push     r15
00000001413e5583  4156                     push     r14
00000001413e5585  4155                     push     r13
00000001413e5587  4154                     push     r12
00000001413e5589  56                       push     rsi
00000001413e558a  57                       push     rdi
00000001413e558b  53                       push     rbx
00000001413e558c  4881ece8000000           sub      rsp, 0xe8
00000001413e5593  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001413e559b  440f295d50               movaps   xmmword ptr [rbp + 0x50], xmm11
00000001413e55a0  440f295540               movaps   xmmword ptr [rbp + 0x40], xmm10
00000001413e55a5  440f294d30               movaps   xmmword ptr [rbp + 0x30], xmm9
00000001413e55aa  440f294520               movaps   xmmword ptr [rbp + 0x20], xmm8
00000001413e55af  0f297d10                 movaps   xmmword ptr [rbp + 0x10], xmm7
00000001413e55b3  0f297500                 movaps   xmmword ptr [rbp], xmm6
00000001413e55b7  48c745f8feffffff         mov      qword ptr [rbp - 8], 0xfffffffffffffffe
00000001413e55bf  4889d7                   mov      rdi, rdx
00000001413e55c2  4889ce                   mov      rsi, rcx
00000001413e55c5  488b4260                 mov      rax, qword ptr [rdx + 0x60]
00000001413e55c9  4885c0                   test     rax, rax
00000001413e55cc  7446                     je       0x1413e5614
00000001413e55ce  488b4f68                 mov      rcx, qword ptr [rdi + 0x68]
00000001413e55d2  483b4f78                 cmp      rcx, qword ptr [rdi + 0x78]
00000001413e55d6  7415                     je       0x1413e55ed
00000001413e55d8  488d5128                 lea      rdx, [rcx + 0x28]
00000001413e55dc  48895768                 mov      qword ptr [rdi + 0x68], rdx
00000001413e55e0  488b11                   mov      rdx, qword ptr [rcx]
00000001413e55e3  4883fa02                 cmp      rdx, 2
00000001413e55e7  0f85c0040000             jne      0x1413e5aad
00000001413e55ed  488b4f70                 mov      rcx, qword ptr [rdi + 0x70]
00000001413e55f1  4885c9                   test     rcx, rcx
00000001413e55f4  7416                     je       0x1413e560c
00000001413e55f6  48c1e103                 shl      rcx, 3
00000001413e55fa  488d1489                 lea      rdx, [rcx + rcx*4]
00000001413e55fe  41b808000000             mov      r8d, 8
00000001413e5604  4889c1                   mov      rcx, rax
00000001413e5607  e8b4642cff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413e560c  48c7476000000000         mov      qword ptr [rdi + 0x60], 0
00000001413e5614  488975c0                 mov      qword ptr [rbp - 0x40], rsi
00000001413e5618  4c8b3f                   mov      r15, qword ptr [rdi]
00000001413e561b  4d85ff                   test     r15, r15
00000001413e561e  0f84c3010000             je       0x1413e57e7
00000001413e5624  488b4728                 mov      rax, qword ptr [rdi + 0x28]
00000001413e5628  488b4f30                 mov      rcx, qword ptr [rdi + 0x30]
00000001413e562c  48894da0                 mov      qword ptr [rbp - 0x60], rcx
00000001413e5630  4839c1                   cmp      rcx, rax
00000001413e5633  0f84ae010000             je       0x1413e57e7
00000001413e5639  488d7001                 lea      rsi, [rax + 1]
00000001413e563d  48897728                 mov      qword ptr [rdi + 0x28], rsi
00000001413e5641  f3440f1044c738           movss    xmm8, dword ptr [rdi + rax*8 + 0x38]
00000001413e5648  f30f107cc73c             movss    xmm7, dword ptr [rdi + rax*8 + 0x3c]
00000001413e564e  4c8b6758                 mov      r12, qword ptr [rdi + 0x58]
00000001413e5652  4d8d6c2401               lea      r13, [r12 + 1]
00000001413e5657  4c896f58                 mov      qword ptr [rdi + 0x58], r13
00000001413e565b  b001                     mov      al, 1
00000001413e565d  4d3927                   cmp      qword ptr [r15], r12
00000001413e5660  7407                     je       0x1413e5669
00000001413e5662  4d396708                 cmp      qword ptr [r15 + 8], r12
00000001413e5666  0f94c0                   sete     al
00000001413e5669  488b4f08                 mov      rcx, qword ptr [rdi + 8]
00000001413e566d  48894db0                 mov      qword ptr [rbp - 0x50], rcx
00000001413e5671  488b4f10                 mov      rcx, qword ptr [rdi + 0x10]
00000001413e5675  48894dc8                 mov      qword ptr [rbp - 0x38], rcx
00000001413e5679  84c0                     test     al, al
00000001413e567b  7432                     je       0x1413e56af
00000001413e567d  488b45b0                 mov      rax, qword ptr [rbp - 0x50]
00000001413e5681  803800                   cmp      byte ptr [rax], 0
00000001413e5684  7429                     je       0x1413e56af
00000001413e5686  488b45c8                 mov      rax, qword ptr [rbp - 0x38]
00000001413e568a  f30f1030                 movss    xmm6, dword ptr [rax]
00000001413e568e  488b5f18                 mov      rbx, qword ptr [rdi + 0x18]
00000001413e5692  4889d9                   mov      rcx, rbx
00000001413e5695  e8f6ac54ff               call     0x140930390 ; country_core::resources::walls::public_wall_state::PublicWallState::max_y | _ZN12country_core9resources5walls17public_wall_state15PublicWallState5max_y17h1995022105bcfb23E
00000001413e569a  0f2ef0                   ucomiss  xmm6, xmm0
00000001413e569d  7610                     jbe      0x1413e56af
00000001413e569f  4889d9                   mov      rcx, rbx
00000001413e56a2  e8e9ac54ff               call     0x140930390 ; country_core::resources::walls::public_wall_state::PublicWallState::max_y | _ZN12country_core9resources5walls17public_wall_state15PublicWallState5max_y17h1995022105bcfb23E
00000001413e56a7  0f28f0                   movaps   xmm6, xmm0
00000001413e56aa  41b601                   mov      r14b, 1
00000001413e56ad  eb0b                     jmp      0x1413e56ba
00000001413e56af  488b45c8                 mov      rax, qword ptr [rbp - 0x38]
00000001413e56b3  f30f1030                 movss    xmm6, dword ptr [rax]
00000001413e56b7  4531f6                   xor      r14d, r14d
00000001413e56ba  48c745d000000000         mov      qword ptr [rbp - 0x30], 0
00000001413e56c2  48c745d808000000         mov      qword ptr [rbp - 0x28], 8
00000001413e56ca  48c745e000000000         mov      qword ptr [rbp - 0x20], 0
00000001413e56d2  488b4720                 mov      rax, qword ptr [rdi + 0x20]
00000001413e56d6  488945b8                 mov      qword ptr [rbp - 0x48], rax
00000001413e56da  f3440f1008               movss    xmm9, dword ptr [rax]
00000001413e56df  f30f1005ed23a501         movss    xmm0, dword ptr [rip + 0x1a523ed]
00000001413e56e7  f3410f58c1               addss    xmm0, xmm9
00000001413e56ec  0f2ef0                   ucomiss  xmm6, xmm0
00000001413e56ef  765a                     jbe      0x1413e574b
00000001413e56f1  488d4dd0                 lea      rcx, [rbp - 0x30]
00000001413e56f5  e8e6969901               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
00000001413e56fa  90                       nop      
00000001413e56fb  488b45d8                 mov      rax, qword ptr [rbp - 0x28]
00000001413e56ff  48c70001000000           mov      qword ptr [rax], 1
00000001413e5706  4c896008                 mov      qword ptr [rax + 8], r12
00000001413e570a  f3440f114010             movss    dword ptr [rax + 0x10], xmm8
00000001413e5710  f3440f114814             movss    dword ptr [rax + 0x14], xmm9
00000001413e5716  f30f117818               movss    dword ptr [rax + 0x18], xmm7
00000001413e571b  f30f11701c               movss    dword ptr [rax + 0x1c], xmm6
00000001413e5720  c6402000                 mov      byte ptr [rax + 0x20], 0
00000001413e5724  48c745e001000000         mov      qword ptr [rbp - 0x20], 1
00000001413e572c  bb01000000               mov      ebx, 1
00000001413e5731  4584f6                   test     r14b, r14b
00000001413e5734  751c                     jne      0x1413e5752
00000001413e5736  488b45d0                 mov      rax, qword ptr [rbp - 0x30]
00000001413e573a  4889c1                   mov      rcx, rax
00000001413e573d  48f7d9                   neg      rcx
00000001413e5740  0f80a1000000             jo       0x1413e57e7
00000001413e5746  e92f010000               jmp      0x1413e587a
00000001413e574b  31db                     xor      ebx, ebx
00000001413e574d  4584f6                   test     r14b, r14b
00000001413e5750  74e4                     je       0x1413e5736
00000001413e5752  488b4f18                 mov      rcx, qword ptr [rdi + 0x18]
00000001413e5756  e835ac54ff               call     0x140930390 ; country_core::resources::walls::public_wall_state::PublicWallState::max_y | _ZN12country_core9resources5walls17public_wall_state15PublicWallState5max_y17h1995022105bcfb23E
00000001413e575b  90                       nop      
00000001413e575c  0f28f0                   movaps   xmm6, xmm0
00000001413e575f  488b45b8                 mov      rax, qword ptr [rbp - 0x48]
00000001413e5763  f3440f1010               movss    xmm10, dword ptr [rax]
00000001413e5768  488b45c8                 mov      rax, qword ptr [rbp - 0x38]
00000001413e576c  f3440f1008               movss    xmm9, dword ptr [rax]
00000001413e5771  488b5de0                 mov      rbx, qword ptr [rbp - 0x20]
00000001413e5775  483b5dd0                 cmp      rbx, qword ptr [rbp - 0x30]
00000001413e5779  750a                     jne      0x1413e5785
00000001413e577b  488d4dd0                 lea      rcx, [rbp - 0x30]
00000001413e577f  e85c969901               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
00000001413e5784  90                       nop      
00000001413e5785  0f28c6                   movaps   xmm0, xmm6
00000001413e5788  f30fc2c603               cmpunordss xmm0, xmm6
00000001413e578d  0f28c8                   movaps   xmm1, xmm0
00000001413e5790  410f54ca                 andps    xmm1, xmm10
00000001413e5794  f3440f5fd6               maxss    xmm10, xmm6
00000001413e5799  410f55c2                 andnps   xmm0, xmm10
00000001413e579d  0f56c1                   orps     xmm0, xmm1
00000001413e57a0  488b45d8                 mov      rax, qword ptr [rbp - 0x28]
00000001413e57a4  488d0c9b                 lea      rcx, [rbx + rbx*4]
00000001413e57a8  48c704c801000000         mov      qword ptr [rax + rcx*8], 1
00000001413e57b0  4c8964c808               mov      qword ptr [rax + rcx*8 + 8], r12
00000001413e57b5  f3440f1144c810           movss    dword ptr [rax + rcx*8 + 0x10], xmm8
00000001413e57bc  f30f1144c814             movss    dword ptr [rax + rcx*8 + 0x14], xmm0
00000001413e57c2  f30f117cc818             movss    dword ptr [rax + rcx*8 + 0x18], xmm7
00000001413e57c8  f3440f114cc81c           movss    dword ptr [rax + rcx*8 + 0x1c], xmm9
00000001413e57cf  c644c82001               mov      byte ptr [rax + rcx*8 + 0x20], 1
00000001413e57d4  48ffc3                   inc      rbx
00000001413e57d7  488b45d0                 mov      rax, qword ptr [rbp - 0x30]
00000001413e57db  4889c1                   mov      rcx, rax
00000001413e57de  48f7d9                   neg      rcx
00000001413e57e1  0f8193000000             jno      0x1413e587a
00000001413e57e7  488b8f80000000           mov      rcx, qword ptr [rdi + 0x80]
00000001413e57ee  4885c9                   test     rcx, rcx
00000001413e57f1  7477                     je       0x1413e586a
00000001413e57f3  488b9788000000           mov      rdx, qword ptr [rdi + 0x88]
00000001413e57fa  483b9798000000           cmp      rdx, qword ptr [rdi + 0x98]
00000001413e5801  488b75c0                 mov      rsi, qword ptr [rbp - 0x40]
00000001413e5805  7424                     je       0x1413e582b
00000001413e5807  488d4228                 lea      rax, [rdx + 0x28]
00000001413e580b  48898788000000           mov      qword ptr [rdi + 0x88], rax
00000001413e5812  488b02                   mov      rax, qword ptr [rdx]
00000001413e5815  0f104218                 movups   xmm0, xmmword ptr [rdx + 0x18]
00000001413e5819  0f2945e0                 movaps   xmmword ptr [rbp - 0x20], xmm0
00000001413e581d  0f104208                 movups   xmm0, xmmword ptr [rdx + 8]
00000001413e5821  0f2945d0                 movaps   xmmword ptr [rbp - 0x30], xmm0
00000001413e5825  4883f802                 cmp      rax, 2
00000001413e5829  752f                     jne      0x1413e585a
00000001413e582b  488b8790000000           mov      rax, qword ptr [rdi + 0x90]
00000001413e5832  4885c0                   test     rax, rax
00000001413e5835  7413                     je       0x1413e584a
00000001413e5837  48c1e003                 shl      rax, 3
00000001413e583b  488d1480                 lea      rdx, [rax + rax*4]
00000001413e583f  41b808000000             mov      r8d, 8
00000001413e5845  e876622cff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413e584a  48c7878000000000000000   mov      qword ptr [rdi + 0x80], 0
00000001413e5855  b802000000               mov      eax, 2
00000001413e585a  488906                   mov      qword ptr [rsi], rax
00000001413e585d  0f2845d0                 movaps   xmm0, xmmword ptr [rbp - 0x30]
00000001413e5861  0f284de0                 movaps   xmm1, xmmword ptr [rbp - 0x20]
00000001413e5865  e94e020000               jmp      0x1413e5ab8
00000001413e586a  488b45c0                 mov      rax, qword ptr [rbp - 0x40]
00000001413e586e  48c70002000000           mov      qword ptr [rax], 2
00000001413e5875  e946020000               jmp      0x1413e5ac0
00000001413e587a  488b4dd8                 mov      rcx, qword ptr [rbp - 0x28]
00000001413e587e  488d149b                 lea      rdx, [rbx + rbx*4]
00000001413e5882  488d14d1                 lea      rdx, [rcx + rdx*8]
00000001413e5886  4c8b4718                 mov      r8, qword ptr [rdi + 0x18]
00000001413e588a  4c8945a8                 mov      qword ptr [rbp - 0x58], r8
00000001413e588e  f30f103d3e22a501         movss    xmm7, dword ptr [rip + 0x1a5223e]
00000001413e5896  662e0f1f840000000000     nop      word ptr cs:[rax + rax]
00000001413e58a0  48894f60                 mov      qword ptr [rdi + 0x60], rcx
00000001413e58a4  48894f68                 mov      qword ptr [rdi + 0x68], rcx
00000001413e58a8  48894770                 mov      qword ptr [rdi + 0x70], rax
00000001413e58ac  48895778                 mov      qword ptr [rdi + 0x78], rdx
00000001413e58b0  4839d1                   cmp      rcx, rdx
00000001413e58b3  7415                     je       0x1413e58ca
00000001413e58b5  488d5128                 lea      rdx, [rcx + 0x28]
00000001413e58b9  48895768                 mov      qword ptr [rdi + 0x68], rdx
00000001413e58bd  488b11                   mov      rdx, qword ptr [rcx]
00000001413e58c0  4883fa02                 cmp      rdx, 2
00000001413e58c4  0f85df010000             jne      0x1413e5aa9
00000001413e58ca  4885c0                   test     rax, rax
00000001413e58cd  7413                     je       0x1413e58e2
00000001413e58cf  48c1e003                 shl      rax, 3
00000001413e58d3  488d1480                 lea      rdx, [rax + rax*4]
00000001413e58d7  41b808000000             mov      r8d, 8
00000001413e58dd  e8de612cff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413e58e2  48c7476000000000         mov      qword ptr [rdi + 0x60], 0
00000001413e58ea  483975a0                 cmp      qword ptr [rbp - 0x60], rsi
00000001413e58ee  0f84f3feffff             je       0x1413e57e7
00000001413e58f4  488d5e01                 lea      rbx, [rsi + 1]
00000001413e58f8  48895f28                 mov      qword ptr [rdi + 0x28], rbx
00000001413e58fc  f3440f104cf738           movss    xmm9, dword ptr [rdi + rsi*8 + 0x38]
00000001413e5903  f3440f1044f73c           movss    xmm8, dword ptr [rdi + rsi*8 + 0x3c]
00000001413e590a  498d7501                 lea      rsi, [r13 + 1]
00000001413e590e  48897758                 mov      qword ptr [rdi + 0x58], rsi
00000001413e5912  b001                     mov      al, 1
00000001413e5914  4d392f                   cmp      qword ptr [r15], r13
00000001413e5917  7407                     je       0x1413e5920
00000001413e5919  4d396f08                 cmp      qword ptr [r15 + 8], r13
00000001413e591d  0f94c0                   sete     al
00000001413e5920  488b4dc8                 mov      rcx, qword ptr [rbp - 0x38]
00000001413e5924  f30f1031                 movss    xmm6, dword ptr [rcx]
00000001413e5928  4531e4                   xor      r12d, r12d
00000001413e592b  84c0                     test     al, al
00000001413e592d  743c                     je       0x1413e596b
00000001413e592f  488b45b0                 mov      rax, qword ptr [rbp - 0x50]
00000001413e5933  803800                   cmp      byte ptr [rax], 0
00000001413e5936  4c8b75a8                 mov      r14, qword ptr [rbp - 0x58]
00000001413e593a  742f                     je       0x1413e596b
00000001413e593c  4c89f1                   mov      rcx, r14
00000001413e593f  e84caa54ff               call     0x140930390 ; country_core::resources::walls::public_wall_state::PublicWallState::max_y | _ZN12country_core9resources5walls17public_wall_state15PublicWallState5max_y17h1995022105bcfb23E
00000001413e5944  0f2ef0                   ucomiss  xmm6, xmm0
00000001413e5947  7617                     jbe      0x1413e5960
00000001413e5949  4c89f1                   mov      rcx, r14
00000001413e594c  e83faa54ff               call     0x140930390 ; country_core::resources::walls::public_wall_state::PublicWallState::max_y | _ZN12country_core9resources5walls17public_wall_state15PublicWallState5max_y17h1995022105bcfb23E
00000001413e5951  0f28f0                   movaps   xmm6, xmm0
00000001413e5954  41b401                   mov      r12b, 1
00000001413e5957  eb12                     jmp      0x1413e596b
00000001413e5959  0f1f8000000000           nop      dword ptr [rax]
00000001413e5960  488b45c8                 mov      rax, qword ptr [rbp - 0x38]
00000001413e5964  f30f1030                 movss    xmm6, dword ptr [rax]
00000001413e5968  4531e4                   xor      r12d, r12d
00000001413e596b  48c745d000000000         mov      qword ptr [rbp - 0x30], 0
00000001413e5973  48c745d808000000         mov      qword ptr [rbp - 0x28], 8
00000001413e597b  48c745e000000000         mov      qword ptr [rbp - 0x20], 0
00000001413e5983  488b45b8                 mov      rax, qword ptr [rbp - 0x48]
00000001413e5987  f3440f1010               movss    xmm10, dword ptr [rax]
00000001413e598c  410f28c2                 movaps   xmm0, xmm10
00000001413e5990  f30f58c7                 addss    xmm0, xmm7
00000001413e5994  0f2ef0                   ucomiss  xmm6, xmm0
00000001413e5997  7657                     jbe      0x1413e59f0
00000001413e5999  488d4dd0                 lea      rcx, [rbp - 0x30]
00000001413e599d  e83e949901               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
00000001413e59a2  90                       nop      
00000001413e59a3  488b45d8                 mov      rax, qword ptr [rbp - 0x28]
00000001413e59a7  48c70001000000           mov      qword ptr [rax], 1
00000001413e59ae  4c896808                 mov      qword ptr [rax + 8], r13
00000001413e59b2  f3440f114810             movss    dword ptr [rax + 0x10], xmm9
00000001413e59b8  f3440f115014             movss    dword ptr [rax + 0x14], xmm10
00000001413e59be  f3440f114018             movss    dword ptr [rax + 0x18], xmm8
00000001413e59c4  f30f11701c               movss    dword ptr [rax + 0x1c], xmm6
00000001413e59c9  c6402000                 mov      byte ptr [rax + 0x20], 0
00000001413e59cd  48c745e001000000         mov      qword ptr [rbp - 0x20], 1
00000001413e59d5  41be01000000             mov      r14d, 1
00000001413e59db  4584e4                   test     r12b, r12b
00000001413e59de  751c                     jne      0x1413e59fc
00000001413e59e0  e99d000000               jmp      0x1413e5a82
00000001413e59e5  66662e0f1f840000000000   nop      word ptr cs:[rax + rax]
00000001413e59f0  4531f6                   xor      r14d, r14d
00000001413e59f3  4584e4                   test     r12b, r12b
00000001413e59f6  0f8486000000             je       0x1413e5a82
00000001413e59fc  488b4da8                 mov      rcx, qword ptr [rbp - 0x58]
00000001413e5a00  e88ba954ff               call     0x140930390 ; country_core::resources::walls::public_wall_state::PublicWallState::max_y | _ZN12country_core9resources5walls17public_wall_state15PublicWallState5max_y17h1995022105bcfb23E
00000001413e5a05  90                       nop      
00000001413e5a06  0f28f0                   movaps   xmm6, xmm0
00000001413e5a09  488b45b8                 mov      rax, qword ptr [rbp - 0x48]
00000001413e5a0d  f3440f1018               movss    xmm11, dword ptr [rax]
00000001413e5a12  488b45c8                 mov      rax, qword ptr [rbp - 0x38]
00000001413e5a16  f3440f1010               movss    xmm10, dword ptr [rax]
00000001413e5a1b  4c8b75e0                 mov      r14, qword ptr [rbp - 0x20]
00000001413e5a1f  4c3b75d0                 cmp      r14, qword ptr [rbp - 0x30]
00000001413e5a23  750a                     jne      0x1413e5a2f
00000001413e5a25  488d4dd0                 lea      rcx, [rbp - 0x30]
00000001413e5a29  e8b2939901               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
00000001413e5a2e  90                       nop      
00000001413e5a2f  0f28c6                   movaps   xmm0, xmm6
00000001413e5a32  f30fc2c603               cmpunordss xmm0, xmm6
00000001413e5a37  0f28c8                   movaps   xmm1, xmm0
00000001413e5a3a  410f54cb                 andps    xmm1, xmm11
00000001413e5a3e  f3440f5fde               maxss    xmm11, xmm6
00000001413e5a43  410f55c3                 andnps   xmm0, xmm11
00000001413e5a47  0f56c1                   orps     xmm0, xmm1
00000001413e5a4a  488b45d8                 mov      rax, qword ptr [rbp - 0x28]
00000001413e5a4e  4b8d0cb6                 lea      rcx, [r14 + r14*4]
00000001413e5a52  48c704c801000000         mov      qword ptr [rax + rcx*8], 1
00000001413e5a5a  4c896cc808               mov      qword ptr [rax + rcx*8 + 8], r13
00000001413e5a5f  f3440f114cc810           movss    dword ptr [rax + rcx*8 + 0x10], xmm9
00000001413e5a66  f30f1144c814             movss    dword ptr [rax + rcx*8 + 0x14], xmm0
00000001413e5a6c  f3440f1144c818           movss    dword ptr [rax + rcx*8 + 0x18], xmm8
00000001413e5a73  f3440f1154c81c           movss    dword ptr [rax + rcx*8 + 0x1c], xmm10
00000001413e5a7a  c644c82001               mov      byte ptr [rax + rcx*8 + 0x20], 1
00000001413e5a7f  49ffc6                   inc      r14
00000001413e5a82  488b45d0                 mov      rax, qword ptr [rbp - 0x30]
00000001413e5a86  4889c1                   mov      rcx, rax
00000001413e5a89  48f7d9                   neg      rcx
00000001413e5a8c  0f8055fdffff             jo       0x1413e57e7
00000001413e5a92  488b4dd8                 mov      rcx, qword ptr [rbp - 0x28]
00000001413e5a96  4b8d14b6                 lea      rdx, [r14 + r14*4]
00000001413e5a9a  488d14d1                 lea      rdx, [rcx + rdx*8]
00000001413e5a9e  4989f5                   mov      r13, rsi
00000001413e5aa1  4889de                   mov      rsi, rbx
00000001413e5aa4  e9f7fdffff               jmp      0x1413e58a0
00000001413e5aa9  488b75c0                 mov      rsi, qword ptr [rbp - 0x40]
00000001413e5aad  488916                   mov      qword ptr [rsi], rdx
00000001413e5ab0  0f104108                 movups   xmm0, xmmword ptr [rcx + 8]
00000001413e5ab4  0f104918                 movups   xmm1, xmmword ptr [rcx + 0x18]
00000001413e5ab8  0f114608                 movups   xmmword ptr [rsi + 8], xmm0
00000001413e5abc  0f114e18                 movups   xmmword ptr [rsi + 0x18], xmm1
00000001413e5ac0  0f287500                 movaps   xmm6, xmmword ptr [rbp]
00000001413e5ac4  0f287d10                 movaps   xmm7, xmmword ptr [rbp + 0x10]
00000001413e5ac8  440f284520               movaps   xmm8, xmmword ptr [rbp + 0x20]
00000001413e5acd  440f284d30               movaps   xmm9, xmmword ptr [rbp + 0x30]
00000001413e5ad2  440f285540               movaps   xmm10, xmmword ptr [rbp + 0x40]
00000001413e5ad7  440f285d50               movaps   xmm11, xmmword ptr [rbp + 0x50]
00000001413e5adc  4881c4e8000000           add      rsp, 0xe8
00000001413e5ae3  5b                       pop      rbx
00000001413e5ae4  5f                       pop      rdi
00000001413e5ae5  5e                       pop      rsi
00000001413e5ae6  415c                     pop      r12
00000001413e5ae8  415d                     pop      r13
00000001413e5aea  415e                     pop      r14
00000001413e5aec  415f                     pop      r15
00000001413e5aee  5d                       pop      rbp
00000001413e5aef  c3                       ret      
00000001413e5af0  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001413e5af5  55                       push     rbp
00000001413e5af6  4157                     push     r15
00000001413e5af8  4156                     push     r14
00000001413e5afa  4155                     push     r13
00000001413e5afc  4154                     push     r12
00000001413e5afe  56                       push     rsi
00000001413e5aff  57                       push     rdi
00000001413e5b00  53                       push     rbx
00000001413e5b01  4881ec88000000           sub      rsp, 0x88
00000001413e5b08  488daa80000000           lea      rbp, [rdx + 0x80]
00000001413e5b0f  440f295c2420             movaps   xmmword ptr [rsp + 0x20], xmm11
00000001413e5b15  440f29542430             movaps   xmmword ptr [rsp + 0x30], xmm10
00000001413e5b1b  440f294c2440             movaps   xmmword ptr [rsp + 0x40], xmm9
00000001413e5b21  440f29442450             movaps   xmmword ptr [rsp + 0x50], xmm8
00000001413e5b27  0f297c2460               movaps   xmmword ptr [rsp + 0x60], xmm7
00000001413e5b2c  0f29742470               movaps   xmmword ptr [rsp + 0x70], xmm6
00000001413e5b31  488b45d0                 mov      rax, qword ptr [rbp - 0x30]
00000001413e5b35  4885c0                   test     rax, rax
00000001413e5b38  7417                     je       0x1413e5b51
00000001413e5b3a  488b4dd8                 mov      rcx, qword ptr [rbp - 0x28]
00000001413e5b3e  48c1e003                 shl      rax, 3
00000001413e5b42  488d1480                 lea      rdx, [rax + rax*4]
00000001413e5b46  41b808000000             mov      r8d, 8
00000001413e5b4c  e86f5f2cff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413e5b51  0f28742470               movaps   xmm6, xmmword ptr [rsp + 0x70]
00000001413e5b56  0f287c2460               movaps   xmm7, xmmword ptr [rsp + 0x60]
00000001413e5b5b  440f28442450             movaps   xmm8, xmmword ptr [rsp + 0x50]
00000001413e5b61  440f284c2440             movaps   xmm9, xmmword ptr [rsp + 0x40]
00000001413e5b67  440f28542430             movaps   xmm10, xmmword ptr [rsp + 0x30]
00000001413e5b6d  440f285c2420             movaps   xmm11, xmmword ptr [rsp + 0x20]
00000001413e5b73  4881c488000000           add      rsp, 0x88
00000001413e5b7a  5b                       pop      rbx
00000001413e5b7b  5f                       pop      rdi
00000001413e5b7c  5e                       pop      rsi
00000001413e5b7d  415c                     pop      r12
00000001413e5b7f  415d                     pop      r13
00000001413e5b81  415e                     pop      r14
00000001413e5b83  415f                     pop      r15
00000001413e5b85  5d                       pop      rbp
00000001413e5b86  c3                       ret      