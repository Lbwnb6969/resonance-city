00000001413e8ae0  55                       push     rbp
00000001413e8ae1  4157                     push     r15
00000001413e8ae3  4156                     push     r14
00000001413e8ae5  56                       push     rsi
00000001413e8ae6  57                       push     rdi
00000001413e8ae7  53                       push     rbx
00000001413e8ae8  4881ecd8000000           sub      rsp, 0xd8
00000001413e8aef  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001413e8af7  48c74550feffffff         mov      qword ptr [rbp + 0x50], 0xfffffffffffffffe
00000001413e8aff  4889d7                   mov      rdi, rdx
00000001413e8b02  488b5210                 mov      rdx, qword ptr [rdx + 0x10]
00000001413e8b06  482b5708                 sub      rdx, qword ptr [rdi + 8]
00000001413e8b0a  488b4738                 mov      rax, qword ptr [rdi + 0x38]
00000001413e8b0e  4531c0                   xor      r8d, r8d
00000001413e8b11  803f00                   cmp      byte ptr [rdi], 0
00000001413e8b14  490f44d0                 cmove    rdx, r8
00000001413e8b18  482b4730                 sub      rax, qword ptr [rdi + 0x30]
00000001413e8b1c  807f2800                 cmp      byte ptr [rdi + 0x28], 0
00000001413e8b20  490f44c0                 cmove    rax, r8
00000001413e8b24  4889ce                   mov      rsi, rcx
00000001413e8b27  488b4f50                 mov      rcx, qword ptr [rdi + 0x50]
00000001413e8b2b  488d1c09                 lea      rbx, [rcx + rcx]
00000001413e8b2f  4883f902                 cmp      rcx, 2
00000001413e8b33  490f44d8                 cmove    rbx, r8
00000001413e8b37  4801d0                   add      rax, rdx
00000001413e8b3a  4839d0                   cmp      rax, rdx
00000001413e8b3d  0f8217010000             jb       0x1413e8c5a
00000001413e8b43  4801c3                   add      rbx, rax
00000001413e8b46  4839c3                   cmp      rbx, rax
00000001413e8b49  0f820b010000             jb       0x1413e8c5a
00000001413e8b4f  4c8d34dd00000000         lea      r14, [rbx*8]
00000001413e8b57  4889d8                   mov      rax, rbx
00000001413e8b5a  48c1e83d                 shr      rax, 0x3d
00000001413e8b5e  0f95c0                   setne    al
00000001413e8b61  48b9fcffffffffffff7f     movabs   rcx, 0x7ffffffffffffffc
00000001413e8b6b  4939ce                   cmp      r14, rcx
00000001413e8b6e  0f97c1                   seta     cl
00000001413e8b71  08c1                     or       cl, al
00000001413e8b73  740e                     je       0x1413e8b83
00000001413e8b75  4531ff                   xor      r15d, r15d
00000001413e8b78  4c89f9                   mov      rcx, r15
00000001413e8b7b  4c89f2                   mov      rdx, r14
00000001413e8b7e  e8a7f29d01               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
00000001413e8b83  4d85f6                   test     r14, r14
00000001413e8b86  7433                     je       0x1413e8bbb
00000001413e8b88  e8d362c9fe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
00000001413e8b8d  41bf04000000             mov      r15d, 4
00000001413e8b93  ba04000000               mov      edx, 4
00000001413e8b98  4c89f1                   mov      rcx, r14
00000001413e8b9b  e8102f2cff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
00000001413e8ba0  4885c0                   test     rax, rax
00000001413e8ba3  74d3                     je       0x1413e8b78
00000001413e8ba5  48895d38                 mov      qword ptr [rbp + 0x38], rbx
00000001413e8ba9  48894540                 mov      qword ptr [rbp + 0x40], rax
00000001413e8bad  4c8d7548                 lea      r14, [rbp + 0x48]
00000001413e8bb1  48c7454800000000         mov      qword ptr [rbp + 0x48], 0
00000001413e8bb9  eb2a                     jmp      0x1413e8be5
00000001413e8bbb  48c7453800000000         mov      qword ptr [rbp + 0x38], 0
00000001413e8bc3  48c7454004000000         mov      qword ptr [rbp + 0x40], 4
00000001413e8bcb  4c8d7548                 lea      r14, [rbp + 0x48]
00000001413e8bcf  48c7454800000000         mov      qword ptr [rbp + 0x48], 0
00000001413e8bd7  4885db                   test     rbx, rbx
00000001413e8bda  0f8593000000             jne      0x1413e8c73
00000001413e8be0  b804000000               mov      eax, 4
00000001413e8be5  31c9                     xor      ecx, ecx
00000001413e8be7  0f104760                 movups   xmm0, xmmword ptr [rdi + 0x60]
00000001413e8beb  0f294510                 movaps   xmmword ptr [rbp + 0x10], xmm0
00000001413e8bef  0f104750                 movups   xmm0, xmmword ptr [rdi + 0x50]
00000001413e8bf3  0f294500                 movaps   xmmword ptr [rbp], xmm0
00000001413e8bf7  0f104740                 movups   xmm0, xmmword ptr [rdi + 0x40]
00000001413e8bfb  0f2945f0                 movaps   xmmword ptr [rbp - 0x10], xmm0
00000001413e8bff  0f1007                   movups   xmm0, xmmword ptr [rdi]
00000001413e8c02  0f104f10                 movups   xmm1, xmmword ptr [rdi + 0x10]
00000001413e8c06  0f105720                 movups   xmm2, xmmword ptr [rdi + 0x20]
00000001413e8c0a  0f105f30                 movups   xmm3, xmmword ptr [rdi + 0x30]
00000001413e8c0e  0f295de0                 movaps   xmmword ptr [rbp - 0x20], xmm3
00000001413e8c12  0f2955d0                 movaps   xmmword ptr [rbp - 0x30], xmm2
00000001413e8c16  0f294dc0                 movaps   xmmword ptr [rbp - 0x40], xmm1
00000001413e8c1a  0f2945b0                 movaps   xmmword ptr [rbp - 0x50], xmm0
00000001413e8c1e  4c897520                 mov      qword ptr [rbp + 0x20], r14
00000001413e8c22  48894d28                 mov      qword ptr [rbp + 0x28], rcx
00000001413e8c26  48894530                 mov      qword ptr [rbp + 0x30], rax
00000001413e8c2a  488d4db0                 lea      rcx, [rbp - 0x50]
00000001413e8c2e  488d5520                 lea      rdx, [rbp + 0x20]
00000001413e8c32  e809830300               call     0x141420f40 ; _ZN102_$LT$core..iter..adapters..map..Map$LT$I$C$F$GT$$u20$as$u20$core..iter..traits..iterator..Iterator$GT$4fold17hadd28ae26176fe36E | core::iter::adapters::map::impl$2::fold<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceXRange,core::iter::adapters::flatten::Flatten<core::option::IntoIter<array$<usize,2> > >,system_wall_constructor::construct_wooden_walls::construct_wall_boards::rectangle_gable_wallspace_ranges::closure$0::closure_env$0,tuple$<>,core::iter::traits::iterator::Iterator::for_each::call::closure_env$0<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceXRange,alloc::vec::impl$21::extend_trusted::closure_env$0<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceXRange,alloc::alloc::Global,core::iter::adapters::map::Map<core::iter::adapters::flatten::Flatten<core::option::IntoIter<array$<usize,2> > >,system_wall_constructor::construct_wooden_walls::construct_wall_boards::rectangle_gable_wallspace_ranges::closure$0::closure_env$0> > > >
00000001413e8c37  90                       nop      
00000001413e8c38  488b4548                 mov      rax, qword ptr [rbp + 0x48]
00000001413e8c3c  48894610                 mov      qword ptr [rsi + 0x10], rax
00000001413e8c40  0f104538                 movups   xmm0, xmmword ptr [rbp + 0x38]
00000001413e8c44  0f1106                   movups   xmmword ptr [rsi], xmm0
00000001413e8c47  4889f0                   mov      rax, rsi
00000001413e8c4a  4881c4d8000000           add      rsp, 0xd8
00000001413e8c51  5b                       pop      rbx
00000001413e8c52  5f                       pop      rdi
00000001413e8c53  5e                       pop      rsi
00000001413e8c54  415e                     pop      r14
00000001413e8c56  415f                     pop      r15
00000001413e8c58  5d                       pop      rbp
00000001413e8c59  c3                       ret      
00000001413e8c5a  488d0d3fcbf101           lea      rcx, [rip + 0x1f1cb3f] ; 'capacity overflow/home/h3/.rustup/toolchains/1.95-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/'
00000001413e8c61  4c8d05c8cbf101           lea      r8, [rip + 0x1f1cbc8]
00000001413e8c68  ba23000000               mov      edx, 0x23
00000001413e8c6d  e85ef79d01               call     0x142dc83d0 ; core::panicking::panic_fmt | _RNvNtCs8icZUrvfcq9_4core9panicking9panic_fmt
00000001413e8c72  90                       nop      
00000001413e8c73  48c744242008000000       mov      qword ptr [rsp + 0x20], 8
00000001413e8c7c  488d4d38                 lea      rcx, [rbp + 0x38]
00000001413e8c80  41b904000000             mov      r9d, 4
00000001413e8c86  31d2                     xor      edx, edx
00000001413e8c88  4989d8                   mov      r8, rbx
00000001413e8c8b  e820659901               call     0x142d7f1b0 ; alloc::raw_vec::impl$4::reserve::do_reserve_and_handle<alloc::alloc::Global> | _ZN5alloc7raw_vec20RawVecInner$LT$A$GT$7reserve21do_reserve_and_handle17h0559268ff9d2f5acE
00000001413e8c90  90                       nop      
00000001413e8c91  488b4540                 mov      rax, qword ptr [rbp + 0x40]
00000001413e8c95  488b4d48                 mov      rcx, qword ptr [rbp + 0x48]
00000001413e8c99  e949ffffff               jmp      0x1413e8be7
00000001413e8c9e  6690                     nop      
00000001413e8ca0  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001413e8ca5  55                       push     rbp
00000001413e8ca6  4157                     push     r15
00000001413e8ca8  4156                     push     r14
00000001413e8caa  56                       push     rsi
00000001413e8cab  57                       push     rdi
00000001413e8cac  53                       push     rbx
00000001413e8cad  4883ec28                 sub      rsp, 0x28
00000001413e8cb1  488daa80000000           lea      rbp, [rdx + 0x80]
00000001413e8cb8  488b5538                 mov      rdx, qword ptr [rbp + 0x38]
00000001413e8cbc  4885d2                   test     rdx, rdx
00000001413e8cbf  7414                     je       0x1413e8cd5
00000001413e8cc1  488b4d40                 mov      rcx, qword ptr [rbp + 0x40]
00000001413e8cc5  48c1e203                 shl      rdx, 3
00000001413e8cc9  41b804000000             mov      r8d, 4
00000001413e8ccf  e8ec2d2cff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413e8cd4  90                       nop      
00000001413e8cd5  4883c428                 add      rsp, 0x28
00000001413e8cd9  5b                       pop      rbx
00000001413e8cda  5f                       pop      rdi
00000001413e8cdb  5e                       pop      rsi
00000001413e8cdc  415e                     pop      r14
00000001413e8cde  415f                     pop      r15
00000001413e8ce0  5d                       pop      rbp
00000001413e8ce1  c3                       ret      