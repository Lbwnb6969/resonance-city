00000001413ee6c0  55                       push     rbp
00000001413ee6c1  4157                     push     r15
00000001413ee6c3  4156                     push     r14
00000001413ee6c5  4155                     push     r13
00000001413ee6c7  4154                     push     r12
00000001413ee6c9  56                       push     rsi
00000001413ee6ca  57                       push     rdi
00000001413ee6cb  53                       push     rbx
00000001413ee6cc  4881ec98000000           sub      rsp, 0x98
00000001413ee6d3  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001413ee6db  48c74510feffffff         mov      qword ptr [rbp + 0x10], 0xfffffffffffffffe
00000001413ee6e3  4c8b7220                 mov      r14, qword ptr [rdx + 0x20]
00000001413ee6e7  4c8b7a28                 mov      r15, qword ptr [rdx + 0x28]
00000001413ee6eb  4d89fc                   mov      r12, r15
00000001413ee6ee  4d29f4                   sub      r12, r14
00000001413ee6f1  4a8d04a500000000         lea      rax, [r12*4]
00000001413ee6f9  488d3c80                 lea      rdi, [rax + rax*4]
00000001413ee6fd  48b86666666666666606     movabs   rax, 0x666666666666666
00000001413ee707  4939c4                   cmp      r12, rax
00000001413ee70a  760d                     jbe      0x1413ee719
00000001413ee70c  31db                     xor      ebx, ebx
00000001413ee70e  4889d9                   mov      rcx, rbx
00000001413ee711  4889fa                   mov      rdx, rdi
00000001413ee714  e811979d01               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
00000001413ee719  4889ce                   mov      rsi, rcx
00000001413ee71c  4885ff                   test     rdi, rdi
00000001413ee71f  7424                     je       0x1413ee745
00000001413ee721  4989d5                   mov      r13, rdx
00000001413ee724  e83707c9fe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
00000001413ee729  bb04000000               mov      ebx, 4
00000001413ee72e  ba04000000               mov      edx, 4
00000001413ee733  4889f9                   mov      rcx, rdi
00000001413ee736  e875d32bff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
00000001413ee73b  4885c0                   test     rax, rax
00000001413ee73e  74ce                     je       0x1413ee70e
00000001413ee740  4c89ea                   mov      rdx, r13
00000001413ee743  eb08                     jmp      0x1413ee74d
00000001413ee745  b804000000               mov      eax, 4
00000001413ee74a  4531e4                   xor      r12d, r12d
00000001413ee74d  4c8965f8                 mov      qword ptr [rbp - 8], r12
00000001413ee751  48894500                 mov      qword ptr [rbp], rax
00000001413ee755  488d4d08                 lea      rcx, [rbp + 8]
00000001413ee759  48c7450800000000         mov      qword ptr [rbp + 8], 0
00000001413ee761  0f104230                 movups   xmm0, xmmword ptr [rdx + 0x30]
00000001413ee765  0f2945d0                 movaps   xmmword ptr [rbp - 0x30], xmm0
00000001413ee769  0f1002                   movups   xmm0, xmmword ptr [rdx]
00000001413ee76c  0f104a10                 movups   xmm1, xmmword ptr [rdx + 0x10]
00000001413ee770  0f2945a0                 movaps   xmmword ptr [rbp - 0x60], xmm0
00000001413ee774  0f294db0                 movaps   xmmword ptr [rbp - 0x50], xmm1
00000001413ee778  4c8975c0                 mov      qword ptr [rbp - 0x40], r14
00000001413ee77c  4c897dc8                 mov      qword ptr [rbp - 0x38], r15
00000001413ee780  48894de0                 mov      qword ptr [rbp - 0x20], rcx
00000001413ee784  48c745e800000000         mov      qword ptr [rbp - 0x18], 0
00000001413ee78c  488945f0                 mov      qword ptr [rbp - 0x10], rax
00000001413ee790  488d4da0                 lea      rcx, [rbp - 0x60]
00000001413ee794  488d55e0                 lea      rdx, [rbp - 0x20]
00000001413ee798  e8831b0300               call     0x141420320 ; _ZN102_$LT$core..iter..adapters..map..Map$LT$I$C$F$GT$$u20$as$u20$core..iter..traits..iterator..Iterator$GT$4fold17h3b83909b66b3233fE | core::iter::adapters::map::impl$2::fold<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSample,core::iter::adapters::zip::Zip<core::slice::iter::Iter<glam::f32::vec3::Vec3>,core::slice::iter::Iter<f32> >,system_wall_constructor::construct_wooden_walls::construct_wall_boards::impl$2::new::closure_env$0,tuple$<>,core::iter::traits::iterator::Iterator::for_each::call::closure_env$0<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSample,alloc::vec::impl$21::extend_trusted::closure_env$0<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSample,alloc::alloc::Global,core::iter::adapters::map::Map<core::iter::adapters::zip::Zip<core::slice::iter::Iter<glam::f32::vec3::Vec3>,core::slice::iter::Iter<f32> >,system_wall_constructor::construct_wooden_walls::construct_wall_boards::impl$2::new::closure_env$0> > > >
00000001413ee79d  90                       nop      
00000001413ee79e  488b4508                 mov      rax, qword ptr [rbp + 8]
00000001413ee7a2  48894610                 mov      qword ptr [rsi + 0x10], rax
00000001413ee7a6  0f1045f8                 movups   xmm0, xmmword ptr [rbp - 8]
00000001413ee7aa  0f1106                   movups   xmmword ptr [rsi], xmm0
00000001413ee7ad  4889f0                   mov      rax, rsi
00000001413ee7b0  4881c498000000           add      rsp, 0x98
00000001413ee7b7  5b                       pop      rbx
00000001413ee7b8  5f                       pop      rdi
00000001413ee7b9  5e                       pop      rsi
00000001413ee7ba  415c                     pop      r12
00000001413ee7bc  415d                     pop      r13
00000001413ee7be  415e                     pop      r14
00000001413ee7c0  415f                     pop      r15
00000001413ee7c2  5d                       pop      rbp
00000001413ee7c3  c3                       ret      
00000001413ee7c4  6666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001413ee7d0  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001413ee7d5  55                       push     rbp
00000001413ee7d6  4157                     push     r15
00000001413ee7d8  4156                     push     r14
00000001413ee7da  4155                     push     r13
00000001413ee7dc  4154                     push     r12
00000001413ee7de  56                       push     rsi
00000001413ee7df  57                       push     rdi
00000001413ee7e0  53                       push     rbx
00000001413ee7e1  4883ec28                 sub      rsp, 0x28
00000001413ee7e5  488daa80000000           lea      rbp, [rdx + 0x80]
00000001413ee7ec  488b45f8                 mov      rax, qword ptr [rbp - 8]
00000001413ee7f0  4885c0                   test     rax, rax
00000001413ee7f3  7418                     je       0x1413ee80d
00000001413ee7f5  488b4d00                 mov      rcx, qword ptr [rbp]
00000001413ee7f9  48c1e002                 shl      rax, 2
00000001413ee7fd  488d1480                 lea      rdx, [rax + rax*4]
00000001413ee801  41b804000000             mov      r8d, 4
00000001413ee807  e8b4d22bff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413ee80c  90                       nop      
00000001413ee80d  4883c428                 add      rsp, 0x28
00000001413ee811  5b                       pop      rbx
00000001413ee812  5f                       pop      rdi
00000001413ee813  5e                       pop      rsi
00000001413ee814  415c                     pop      r12
00000001413ee816  415d                     pop      r13
00000001413ee818  415e                     pop      r14
00000001413ee81a  415f                     pop      r15
00000001413ee81c  5d                       pop      rbp
00000001413ee81d  c3                       ret      