00000001413ebce0  55                       push     rbp
00000001413ebce1  4157                     push     r15
00000001413ebce3  4156                     push     r14
00000001413ebce5  56                       push     rsi
00000001413ebce6  57                       push     rdi
00000001413ebce7  53                       push     rbx
00000001413ebce8  4883ec78                 sub      rsp, 0x78
00000001413ebcec  488d6c2470               lea      rbp, [rsp + 0x70]
00000001413ebcf1  48c74500feffffff         mov      qword ptr [rbp], 0xfffffffffffffffe
00000001413ebcf9  4889ce                   mov      rsi, rcx
00000001413ebcfc  4c39c2                   cmp      rdx, r8
00000001413ebcff  741e                     je       0x1413ebd1f
00000001413ebd01  4c89c7                   mov      rdi, r8
00000001413ebd04  4889d3                   mov      rbx, rdx
00000001413ebd07  660f1f840000000000       nop      word ptr [rax + rax]
00000001413ebd10  807b1000                 cmp      byte ptr [rbx + 0x10], 0
00000001413ebd14  7525                     jne      0x1413ebd3b
00000001413ebd16  4883c314                 add      rbx, 0x14
00000001413ebd1a  4839fb                   cmp      rbx, rdi
00000001413ebd1d  75f1                     jne      0x1413ebd10
00000001413ebd1f  48c70600000000           mov      qword ptr [rsi], 0
00000001413ebd26  48c7460804000000         mov      qword ptr [rsi + 8], 4
00000001413ebd2e  48c7461000000000         mov      qword ptr [rsi + 0x10], 0
00000001413ebd36  e9ce000000               jmp      0x1413ebe09
00000001413ebd3b  0f1003                   movups   xmm0, xmmword ptr [rbx]
00000001413ebd3e  0f2945d0                 movaps   xmmword ptr [rbp - 0x30], xmm0
00000001413ebd42  e81931c9fe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
00000001413ebd47  b940000000               mov      ecx, 0x40
00000001413ebd4c  ba04000000               mov      edx, 4
00000001413ebd51  e85afd2bff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
00000001413ebd56  4885c0                   test     rax, rax
00000001413ebd59  0f84ba000000             je       0x1413ebe19
00000001413ebd5f  4883c314                 add      rbx, 0x14
00000001413ebd63  0f2845d0                 movaps   xmm0, xmmword ptr [rbp - 0x30]
00000001413ebd67  0f1100                   movups   xmmword ptr [rax], xmm0
00000001413ebd6a  48c745e804000000         mov      qword ptr [rbp - 0x18], 4
00000001413ebd72  488945f0                 mov      qword ptr [rbp - 0x10], rax
00000001413ebd76  48c745f801000000         mov      qword ptr [rbp - 8], 1
00000001413ebd7e  4839fb                   cmp      rbx, rdi
00000001413ebd81  746f                     je       0x1413ebdf2
00000001413ebd83  41be01000000             mov      r14d, 1
00000001413ebd89  4c8d7de8                 lea      r15, [rbp - 0x18]
00000001413ebd8d  0f1f00                   nop      dword ptr [rax]
00000001413ebd90  807b1000                 cmp      byte ptr [rbx + 0x10], 0
00000001413ebd94  750b                     jne      0x1413ebda1
00000001413ebd96  4883c314                 add      rbx, 0x14
00000001413ebd9a  4839fb                   cmp      rbx, rdi
00000001413ebd9d  75f1                     jne      0x1413ebd90
00000001413ebd9f  eb51                     jmp      0x1413ebdf2
00000001413ebda1  0f1003                   movups   xmm0, xmmword ptr [rbx]
00000001413ebda4  0f2945c0                 movaps   xmmword ptr [rbp - 0x40], xmm0
00000001413ebda8  4c3b75e8                 cmp      r14, qword ptr [rbp - 0x18]
00000001413ebdac  7525                     jne      0x1413ebdd3
00000001413ebdae  48c744242010000000       mov      qword ptr [rsp + 0x20], 0x10
00000001413ebdb7  41b801000000             mov      r8d, 1
00000001413ebdbd  41b904000000             mov      r9d, 4
00000001413ebdc3  4c89f9                   mov      rcx, r15
00000001413ebdc6  4c89f2                   mov      rdx, r14
00000001413ebdc9  e8e2339901               call     0x142d7f1b0 ; alloc::raw_vec::impl$4::reserve::do_reserve_and_handle<alloc::alloc::Global> | _ZN5alloc7raw_vec20RawVecInner$LT$A$GT$7reserve21do_reserve_and_handle17h0559268ff9d2f5acE
00000001413ebdce  90                       nop      
00000001413ebdcf  488b45f0                 mov      rax, qword ptr [rbp - 0x10]
00000001413ebdd3  4883c314                 add      rbx, 0x14
00000001413ebdd7  4c89f1                   mov      rcx, r14
00000001413ebdda  48c1e104                 shl      rcx, 4
00000001413ebdde  0f2845c0                 movaps   xmm0, xmmword ptr [rbp - 0x40]
00000001413ebde2  0f110408                 movups   xmmword ptr [rax + rcx], xmm0
00000001413ebde6  49ffc6                   inc      r14
00000001413ebde9  4c8975f8                 mov      qword ptr [rbp - 8], r14
00000001413ebded  4839fb                   cmp      rbx, rdi
00000001413ebdf0  759e                     jne      0x1413ebd90
00000001413ebdf2  488b45f8                 mov      rax, qword ptr [rbp - 8]
00000001413ebdf6  48894610                 mov      qword ptr [rsi + 0x10], rax
00000001413ebdfa  488b45e8                 mov      rax, qword ptr [rbp - 0x18]
00000001413ebdfe  488906                   mov      qword ptr [rsi], rax
00000001413ebe01  488b45f0                 mov      rax, qword ptr [rbp - 0x10]
00000001413ebe05  48894608                 mov      qword ptr [rsi + 8], rax
00000001413ebe09  4889f0                   mov      rax, rsi
00000001413ebe0c  4883c478                 add      rsp, 0x78
00000001413ebe10  5b                       pop      rbx
00000001413ebe11  5f                       pop      rdi
00000001413ebe12  5e                       pop      rsi
00000001413ebe13  415e                     pop      r14
00000001413ebe15  415f                     pop      r15
00000001413ebe17  5d                       pop      rbp
00000001413ebe18  c3                       ret      
00000001413ebe19  b904000000               mov      ecx, 4
00000001413ebe1e  ba40000000               mov      edx, 0x40
00000001413ebe23  e802c09d01               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
00000001413ebe28  cc                       int3     
00000001413ebe29  0f1f8000000000           nop      dword ptr [rax]
00000001413ebe30  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001413ebe35  55                       push     rbp
00000001413ebe36  4157                     push     r15
00000001413ebe38  4156                     push     r14
00000001413ebe3a  56                       push     rsi
00000001413ebe3b  57                       push     rdi
00000001413ebe3c  53                       push     rbx
00000001413ebe3d  4883ec28                 sub      rsp, 0x28
00000001413ebe41  488d6a70                 lea      rbp, [rdx + 0x70]
00000001413ebe45  488b55e8                 mov      rdx, qword ptr [rbp - 0x18]
00000001413ebe49  4885d2                   test     rdx, rdx
00000001413ebe4c  7414                     je       0x1413ebe62
00000001413ebe4e  488b4df0                 mov      rcx, qword ptr [rbp - 0x10]
00000001413ebe52  48c1e204                 shl      rdx, 4
00000001413ebe56  41b804000000             mov      r8d, 4
00000001413ebe5c  e85ffc2bff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413ebe61  90                       nop      
00000001413ebe62  4883c428                 add      rsp, 0x28
00000001413ebe66  5b                       pop      rbx
00000001413ebe67  5f                       pop      rdi
00000001413ebe68  5e                       pop      rsi
00000001413ebe69  415e                     pop      r14
00000001413ebe6b  415f                     pop      r15
00000001413ebe6d  5d                       pop      rbp
00000001413ebe6e  c3                       ret      