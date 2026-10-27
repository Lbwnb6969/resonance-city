00000001413ef620  55                       push     rbp
00000001413ef621  4157                     push     r15
00000001413ef623  4156                     push     r14
00000001413ef625  4155                     push     r13
00000001413ef627  4154                     push     r12
00000001413ef629  56                       push     rsi
00000001413ef62a  57                       push     rdi
00000001413ef62b  53                       push     rbx
00000001413ef62c  4881ec68010000           sub      rsp, 0x168
00000001413ef633  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001413ef63b  48c785e0000000feffffff   mov      qword ptr [rbp + 0xe0], 0xfffffffffffffffe
00000001413ef646  4989ce                   mov      r14, rcx
00000001413ef649  c685df00000001           mov      byte ptr [rbp + 0xdf], 1
00000001413ef650  488d4d60                 lea      rcx, [rbp + 0x60]
00000001413ef654  488995d0000000           mov      qword ptr [rbp + 0xd0], rdx
00000001413ef65b  e8205fffff               call     0x1413e5580 ; core::iter::adapters::flatten::impl$3::next<core::iter::adapters::enumerate::Enumerate<core::array::iter::IntoIter<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceXRange,4> >,alloc::vec::Vec<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceRegion,alloc::alloc::Global>,system_wall_constructor::construct_wooden_walls::construct_wall_boards::plan_rectangle_wallspace_regions::closure_env$0>
00000001413ef660  90                       nop      
00000001413ef661  837d6002                 cmp      dword ptr [rbp + 0x60], 2
00000001413ef665  757b                     jne      0x1413ef6e2
00000001413ef667  49c70600000000           mov      qword ptr [r14], 0
00000001413ef66e  49c7460808000000         mov      qword ptr [r14 + 8], 8
00000001413ef676  49c7461000000000         mov      qword ptr [r14 + 0x10], 0
00000001413ef67e  488bb5d0000000           mov      rsi, qword ptr [rbp + 0xd0]
00000001413ef685  488b4e60                 mov      rcx, qword ptr [rsi + 0x60]
00000001413ef689  4885c9                   test     rcx, rcx
00000001413ef68c  741c                     je       0x1413ef6aa
00000001413ef68e  488b4670                 mov      rax, qword ptr [rsi + 0x70]
00000001413ef692  4885c0                   test     rax, rax
00000001413ef695  7413                     je       0x1413ef6aa
00000001413ef697  48c1e003                 shl      rax, 3
00000001413ef69b  488d1480                 lea      rdx, [rax + rax*4]
00000001413ef69f  41b808000000             mov      r8d, 8
00000001413ef6a5  e816c42bff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413ef6aa  488b8e80000000           mov      rcx, qword ptr [rsi + 0x80]
00000001413ef6b1  4885c9                   test     rcx, rcx
00000001413ef6b4  0f84e8020000             je       0x1413ef9a2
00000001413ef6ba  488b8690000000           mov      rax, qword ptr [rsi + 0x90]
00000001413ef6c1  4885c0                   test     rax, rax
00000001413ef6c4  0f84d8020000             je       0x1413ef9a2
00000001413ef6ca  48c1e003                 shl      rax, 3
00000001413ef6ce  488d1480                 lea      rdx, [rax + rax*4]
00000001413ef6d2  41b808000000             mov      r8d, 8
00000001413ef6d8  e8e3c32bff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413ef6dd  e9c0020000               jmp      0x1413ef9a2
00000001413ef6e2  4c8bbdd0000000           mov      r15, qword ptr [rbp + 0xd0]
00000001413ef6e9  49837f6000               cmp      qword ptr [r15 + 0x60], 0
00000001413ef6ee  49bdcdcccccccccccccc     movabs   r13, 0xcccccccccccccccd
00000001413ef6f8  743b                     je       0x1413ef735
00000001413ef6fa  498b4f78                 mov      rcx, qword ptr [r15 + 0x78]
00000001413ef6fe  492b4f68                 sub      rcx, qword ptr [r15 + 0x68]
00000001413ef702  48c1e903                 shr      rcx, 3
00000001413ef706  490fafcd                 imul     rcx, r13
00000001413ef70a  4983bf8000000000         cmp      qword ptr [r15 + 0x80], 0
00000001413ef712  742d                     je       0x1413ef741
00000001413ef714  498b8798000000           mov      rax, qword ptr [r15 + 0x98]
00000001413ef71b  492b8788000000           sub      rax, qword ptr [r15 + 0x88]
00000001413ef722  48c1e803                 shr      rax, 3
00000001413ef726  490fafc5                 imul     rax, r13
00000001413ef72a  4801c8                   add      rax, rcx
00000001413ef72d  49833f00                 cmp      qword ptr [r15], 0
00000001413ef731  7519                     jne      0x1413ef74c
00000001413ef733  eb21                     jmp      0x1413ef756
00000001413ef735  31c9                     xor      ecx, ecx
00000001413ef737  4983bf8000000000         cmp      qword ptr [r15 + 0x80], 0
00000001413ef73f  75d3                     jne      0x1413ef714
00000001413ef741  31c0                     xor      eax, eax
00000001413ef743  4801c8                   add      rax, rcx
00000001413ef746  49833f00                 cmp      qword ptr [r15], 0
00000001413ef74a  740a                     je       0x1413ef756
00000001413ef74c  498b4f30                 mov      rcx, qword ptr [r15 + 0x30]
00000001413ef750  493b4f28                 cmp      rcx, qword ptr [r15 + 0x28]
00000001413ef754  750c                     jne      0x1413ef762
00000001413ef756  488d8d88000000           lea      rcx, [rbp + 0x88]
00000001413ef75d  4889c2                   mov      rdx, rax
00000001413ef760  eb06                     jmp      0x1413ef768
00000001413ef762  488d4db0                 lea      rcx, [rbp - 0x50]
00000001413ef766  31d2                     xor      edx, edx
00000001413ef768  488911                   mov      qword ptr [rcx], rdx
00000001413ef76b  4883f804                 cmp      rax, 4
00000001413ef76f  be03000000               mov      esi, 3
00000001413ef774  480f43f0                 cmovae   rsi, rax
00000001413ef778  48b93233333333333303     movabs   rcx, 0x333333333333332
00000001413ef782  4839c8                   cmp      rax, rcx
00000001413ef785  7617                     jbe      0x1413ef79e
00000001413ef787  31db                     xor      ebx, ebx
00000001413ef789  c685df00000001           mov      byte ptr [rbp + 0xdf], 1
00000001413ef790  4889d9                   mov      rcx, rbx
00000001413ef793  4889fa                   mov      rdx, rdi
00000001413ef796  e88f869d01               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
00000001413ef79b  90                       nop      
00000001413ef79c  0f0b                     ud2      
00000001413ef79e  488d04f508000000         lea      rax, [rsi*8 + 8]
00000001413ef7a6  488d3c80                 lea      rdi, [rax + rax*4]
00000001413ef7aa  4885ff                   test     rdi, rdi
00000001413ef7ad  4c89b5b0000000           mov      qword ptr [rbp + 0xb0], r14
00000001413ef7b4  7424                     je       0x1413ef7da
00000001413ef7b6  e8a5f6c8fe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
00000001413ef7bb  bb08000000               mov      ebx, 8
00000001413ef7c0  ba08000000               mov      edx, 8
00000001413ef7c5  4889f9                   mov      rcx, rdi
00000001413ef7c8  e8e3c22bff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
00000001413ef7cd  4885c0                   test     rax, rax
00000001413ef7d0  74b7                     je       0x1413ef789
00000001413ef7d2  4989c4                   mov      r12, rax
00000001413ef7d5  48ffc6                   inc      rsi
00000001413ef7d8  eb08                     jmp      0x1413ef7e2
00000001413ef7da  41bc08000000             mov      r12d, 8
00000001413ef7e0  31f6                     xor      esi, esi
00000001413ef7e2  488b8580000000           mov      rax, qword ptr [rbp + 0x80]
00000001413ef7e9  4989442420               mov      qword ptr [r12 + 0x20], rax
00000001413ef7ee  0f104560                 movups   xmm0, xmmword ptr [rbp + 0x60]
00000001413ef7f2  0f104d70                 movups   xmm1, xmmword ptr [rbp + 0x70]
00000001413ef7f6  410f114c2410             movups   xmmword ptr [r12 + 0x10], xmm1
00000001413ef7fc  410f110424               movups   xmmword ptr [r12], xmm0
00000001413ef801  4889b5b8000000           mov      qword ptr [rbp + 0xb8], rsi
00000001413ef808  4c89a5c0000000           mov      qword ptr [rbp + 0xc0], r12
00000001413ef80f  48c785c800000001000000   mov      qword ptr [rbp + 0xc8], 1
00000001413ef81a  488d7db0                 lea      rdi, [rbp - 0x50]
00000001413ef81e  41b8a0000000             mov      r8d, 0xa0
00000001413ef824  4889f9                   mov      rcx, rdi
00000001413ef827  4c89fa                   mov      rdx, r15
00000001413ef82a  e8312fa401               call     0x142e32760 ; memcpy
00000001413ef82f  bb01000000               mov      ebx, 1
00000001413ef834  be28000000               mov      esi, 0x28
00000001413ef839  4c8db588000000           lea      r14, [rbp + 0x88]
00000001413ef840  4c8dbdb8000000           lea      r15, [rbp + 0xb8]
00000001413ef847  eb3a                     jmp      0x1413ef883
00000001413ef849  0f1f8000000000           nop      dword ptr [rax]
00000001413ef850  488b85a8000000           mov      rax, qword ptr [rbp + 0xa8]
00000001413ef857  4989443420               mov      qword ptr [r12 + rsi + 0x20], rax
00000001413ef85c  0f108588000000           movups   xmm0, xmmword ptr [rbp + 0x88]
00000001413ef863  0f108d98000000           movups   xmm1, xmmword ptr [rbp + 0x98]
00000001413ef86a  410f114c3410             movups   xmmword ptr [r12 + rsi + 0x10], xmm1
00000001413ef870  410f110434               movups   xmmword ptr [r12 + rsi], xmm0
00000001413ef875  48ffc3                   inc      rbx
00000001413ef878  48899dc8000000           mov      qword ptr [rbp + 0xc8], rbx
00000001413ef87f  4883c628                 add      rsi, 0x28
00000001413ef883  4c89f1                   mov      rcx, r14
00000001413ef886  4889fa                   mov      rdx, rdi
00000001413ef889  e8f25cffff               call     0x1413e5580 ; core::iter::adapters::flatten::impl$3::next<core::iter::adapters::enumerate::Enumerate<core::array::iter::IntoIter<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceXRange,4> >,alloc::vec::Vec<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceRegion,alloc::alloc::Global>,system_wall_constructor::construct_wooden_walls::construct_wall_boards::plan_rectangle_wallspace_regions::closure_env$0>
00000001413ef88e  90                       nop      
00000001413ef88f  83bd8800000002           cmp      dword ptr [rbp + 0x88], 2
00000001413ef896  0f849f000000             je       0x1413ef93b
00000001413ef89c  483b9db8000000           cmp      rbx, qword ptr [rbp + 0xb8]
00000001413ef8a3  75ab                     jne      0x1413ef850
00000001413ef8a5  48837d1000               cmp      qword ptr [rbp + 0x10], 0
00000001413ef8aa  7433                     je       0x1413ef8df
00000001413ef8ac  488b4528                 mov      rax, qword ptr [rbp + 0x28]
00000001413ef8b0  482b4518                 sub      rax, qword ptr [rbp + 0x18]
00000001413ef8b4  48c1e803                 shr      rax, 3
00000001413ef8b8  490fafc5                 imul     rax, r13
00000001413ef8bc  48837d3000               cmp      qword ptr [rbp + 0x30], 0
00000001413ef8c1  7425                     je       0x1413ef8e8
00000001413ef8c3  4c8b4548                 mov      r8, qword ptr [rbp + 0x48]
00000001413ef8c7  4c2b4538                 sub      r8, qword ptr [rbp + 0x38]
00000001413ef8cb  49c1e803                 shr      r8, 3
00000001413ef8cf  4d0fafc5                 imul     r8, r13
00000001413ef8d3  4901c0                   add      r8, rax
00000001413ef8d6  48837db000               cmp      qword ptr [rbp - 0x50], 0
00000001413ef8db  7518                     jne      0x1413ef8f5
00000001413ef8dd  eb20                     jmp      0x1413ef8ff
00000001413ef8df  31c0                     xor      eax, eax
00000001413ef8e1  48837d3000               cmp      qword ptr [rbp + 0x30], 0
00000001413ef8e6  75db                     jne      0x1413ef8c3
00000001413ef8e8  4531c0                   xor      r8d, r8d
00000001413ef8eb  4901c0                   add      r8, rax
00000001413ef8ee  48837db000               cmp      qword ptr [rbp - 0x50], 0
00000001413ef8f3  740a                     je       0x1413ef8ff
00000001413ef8f5  488b45e0                 mov      rax, qword ptr [rbp - 0x20]
00000001413ef8f9  483b45d8                 cmp      rax, qword ptr [rbp - 0x28]
00000001413ef8fd  7509                     jne      0x1413ef908
00000001413ef8ff  488d4558                 lea      rax, [rbp + 0x58]
00000001413ef903  4c89c1                   mov      rcx, r8
00000001413ef906  eb06                     jmp      0x1413ef90e
00000001413ef908  488d4550                 lea      rax, [rbp + 0x50]
00000001413ef90c  31c9                     xor      ecx, ecx
00000001413ef90e  488908                   mov      qword ptr [rax], rcx
00000001413ef911  49ffc0                   inc      r8
00000001413ef914  48c744242028000000       mov      qword ptr [rsp + 0x20], 0x28
00000001413ef91d  41b908000000             mov      r9d, 8
00000001413ef923  4c89f9                   mov      rcx, r15
00000001413ef926  4889da                   mov      rdx, rbx
00000001413ef929  e882f89801               call     0x142d7f1b0 ; alloc::raw_vec::impl$4::reserve::do_reserve_and_handle<alloc::alloc::Global> | _ZN5alloc7raw_vec20RawVecInner$LT$A$GT$7reserve21do_reserve_and_handle17h0559268ff9d2f5acE
00000001413ef92e  90                       nop      
00000001413ef92f  4c8ba5c0000000           mov      r12, qword ptr [rbp + 0xc0]
00000001413ef936  e915ffffff               jmp      0x1413ef850
00000001413ef93b  488b4d10                 mov      rcx, qword ptr [rbp + 0x10]
00000001413ef93f  4885c9                   test     rcx, rcx
00000001413ef942  741c                     je       0x1413ef960
00000001413ef944  488b4520                 mov      rax, qword ptr [rbp + 0x20]
00000001413ef948  4885c0                   test     rax, rax
00000001413ef94b  7413                     je       0x1413ef960
00000001413ef94d  48c1e003                 shl      rax, 3
00000001413ef951  488d1480                 lea      rdx, [rax + rax*4]
00000001413ef955  41b808000000             mov      r8d, 8
00000001413ef95b  e860c12bff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413ef960  488b4d30                 mov      rcx, qword ptr [rbp + 0x30]
00000001413ef964  4885c9                   test     rcx, rcx
00000001413ef967  4c8bb5b0000000           mov      r14, qword ptr [rbp + 0xb0]
00000001413ef96e  741c                     je       0x1413ef98c
00000001413ef970  488b4540                 mov      rax, qword ptr [rbp + 0x40]
00000001413ef974  4885c0                   test     rax, rax
00000001413ef977  7413                     je       0x1413ef98c
00000001413ef979  48c1e003                 shl      rax, 3
00000001413ef97d  488d1480                 lea      rdx, [rax + rax*4]
00000001413ef981  41b808000000             mov      r8d, 8
00000001413ef987  e834c12bff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413ef98c  488b85c8000000           mov      rax, qword ptr [rbp + 0xc8]
00000001413ef993  49894610                 mov      qword ptr [r14 + 0x10], rax
00000001413ef997  0f1085b8000000           movups   xmm0, xmmword ptr [rbp + 0xb8]
00000001413ef99e  410f1106                 movups   xmmword ptr [r14], xmm0
00000001413ef9a2  4c89f0                   mov      rax, r14
00000001413ef9a5  4881c468010000           add      rsp, 0x168
00000001413ef9ac  5b                       pop      rbx
00000001413ef9ad  5f                       pop      rdi
00000001413ef9ae  5e                       pop      rsi
00000001413ef9af  415c                     pop      r12
00000001413ef9b1  415d                     pop      r13
00000001413ef9b3  415e                     pop      r14
00000001413ef9b5  415f                     pop      r15
00000001413ef9b7  5d                       pop      rbp
00000001413ef9b8  c3                       ret      
00000001413ef9b9  0f1f8000000000           nop      dword ptr [rax]
00000001413ef9c0  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001413ef9c5  55                       push     rbp
00000001413ef9c6  4157                     push     r15
00000001413ef9c8  4156                     push     r14
00000001413ef9ca  4155                     push     r13
00000001413ef9cc  4154                     push     r12
00000001413ef9ce  56                       push     rsi
00000001413ef9cf  57                       push     rdi
00000001413ef9d0  53                       push     rbx
00000001413ef9d1  4883ec28                 sub      rsp, 0x28
00000001413ef9d5  488daa80000000           lea      rbp, [rdx + 0x80]
00000001413ef9dc  488b85b8000000           mov      rax, qword ptr [rbp + 0xb8]
00000001413ef9e3  4885c0                   test     rax, rax
00000001413ef9e6  741a                     je       0x1413efa02
00000001413ef9e8  488b8dc0000000           mov      rcx, qword ptr [rbp + 0xc0]
00000001413ef9ef  48c1e003                 shl      rax, 3
00000001413ef9f3  488d1480                 lea      rdx, [rax + rax*4]
00000001413ef9f7  41b808000000             mov      r8d, 8
00000001413ef9fd  e8bec02bff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413efa02  c685df00000000           mov      byte ptr [rbp + 0xdf], 0
00000001413efa09  4883c428                 add      rsp, 0x28
00000001413efa0d  5b                       pop      rbx
00000001413efa0e  5f                       pop      rdi
00000001413efa0f  5e                       pop      rsi
00000001413efa10  415c                     pop      r12
00000001413efa12  415d                     pop      r13
00000001413efa14  415e                     pop      r14
00000001413efa16  415f                     pop      r15
00000001413efa18  5d                       pop      rbp
00000001413efa19  c3                       ret      
00000001413efa1a  660f1f440000             nop      word ptr [rax + rax]
00000001413efa20  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001413efa25  55                       push     rbp
00000001413efa26  4157                     push     r15
00000001413efa28  4156                     push     r14
00000001413efa2a  4155                     push     r13
00000001413efa2c  4154                     push     r12
00000001413efa2e  56                       push     rsi
00000001413efa2f  57                       push     rdi
00000001413efa30  53                       push     rbx
00000001413efa31  4883ec28                 sub      rsp, 0x28
00000001413efa35  488daa80000000           lea      rbp, [rdx + 0x80]
00000001413efa3c  80bddf00000000           cmp      byte ptr [rbp + 0xdf], 0
00000001413efa43  7511                     jne      0x1413efa56
00000001413efa45  4883c428                 add      rsp, 0x28
00000001413efa49  5b                       pop      rbx
00000001413efa4a  5f                       pop      rdi
00000001413efa4b  5e                       pop      rsi
00000001413efa4c  415c                     pop      r12
00000001413efa4e  415d                     pop      r13
00000001413efa50  415e                     pop      r14
00000001413efa52  415f                     pop      r15
00000001413efa54  5d                       pop      rbp
00000001413efa55  c3                       ret      
00000001413efa56  488b8dd0000000           mov      rcx, qword ptr [rbp + 0xd0]
00000001413efa5d  e8ee040100               call     0x1413fff50 ; core::ptr::drop_in_place<core::iter::adapters::flatten::FlatMap<core::iter::adapters::enumerate::Enumerate<core::array::iter::IntoIter<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceXRange,4> >,alloc::vec::Vec<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceRegion,alloc::alloc::Global>,system_wall_constructor::construct_wooden_walls::construct_wall_boards::plan_rectangle_wallspace_regions::closure_env$0> > | _ZN4core3ptr498drop_in_place$LT$core..iter..adapters..flatten..FlatMap$LT$core..iter..adapters..enumerate..Enumerate$LT$core..array..iter..IntoIter$LT$system_wall_constructor..construct_wooden_walls..construct_wall_boards..WallspaceXRange$C$4_usize$GT$$GT$$C$alloc..vec..Vec$LT$system_wall_constructor..construct_wooden_walls..construct_wall_boards..WallspaceRegion$GT$$C$system_wall_constructor..construct_wooden_walls..construct_wall_boards..plan_rectangle_wallspace_regions..$u7b$$u7b$closure$u7d$$u7d$$GT$$GT$17h37a7ef41a792d377E
00000001413efa62  ebe1                     jmp      0x1413efa45
00000001413efa64  6666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001413efa70  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001413efa75  55                       push     rbp
00000001413efa76  4157                     push     r15
00000001413efa78  4156                     push     r14
00000001413efa7a  4155                     push     r13
00000001413efa7c  4154                     push     r12
00000001413efa7e  56                       push     rsi
00000001413efa7f  57                       push     rdi
00000001413efa80  53                       push     rbx
00000001413efa81  4883ec28                 sub      rsp, 0x28
00000001413efa85  488daa80000000           lea      rbp, [rdx + 0x80]
00000001413efa8c  488d4db0                 lea      rcx, [rbp - 0x50]
00000001413efa90  e8bb040100               call     0x1413fff50 ; core::ptr::drop_in_place<core::iter::adapters::flatten::FlatMap<core::iter::adapters::enumerate::Enumerate<core::array::iter::IntoIter<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceXRange,4> >,alloc::vec::Vec<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceRegion,alloc::alloc::Global>,system_wall_constructor::construct_wooden_walls::construct_wall_boards::plan_rectangle_wallspace_regions::closure_env$0> > | _ZN4core3ptr498drop_in_place$LT$core..iter..adapters..flatten..FlatMap$LT$core..iter..adapters..enumerate..Enumerate$LT$core..array..iter..IntoIter$LT$system_wall_constructor..construct_wooden_walls..construct_wall_boards..WallspaceXRange$C$4_usize$GT$$GT$$C$alloc..vec..Vec$LT$system_wall_constructor..construct_wooden_walls..construct_wall_boards..WallspaceRegion$GT$$C$system_wall_constructor..construct_wooden_walls..construct_wall_boards..plan_rectangle_wallspace_regions..$u7b$$u7b$closure$u7d$$u7d$$GT$$GT$17h37a7ef41a792d377E
00000001413efa95  90                       nop      
00000001413efa96  4883c428                 add      rsp, 0x28
00000001413efa9a  5b                       pop      rbx
00000001413efa9b  5f                       pop      rdi
00000001413efa9c  5e                       pop      rsi
00000001413efa9d  415c                     pop      r12
00000001413efa9f  415d                     pop      r13
00000001413efaa1  415e                     pop      r14
00000001413efaa3  415f                     pop      r15
00000001413efaa5  5d                       pop      rbp
00000001413efaa6  c3                       ret      