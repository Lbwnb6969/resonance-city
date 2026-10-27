00000001424bd0e0  4157                     push     r15
00000001424bd0e2  4156                     push     r14
00000001424bd0e4  4155                     push     r13
00000001424bd0e6  4154                     push     r12
00000001424bd0e8  56                       push     rsi
00000001424bd0e9  57                       push     rdi
00000001424bd0ea  55                       push     rbp
00000001424bd0eb  53                       push     rbx
00000001424bd0ec  4881ec88000000           sub      rsp, 0x88
00000001424bd0f3  0f29742470               movaps   xmmword ptr [rsp + 0x70], xmm6
00000001424bd0f8  4889ce                   mov      rsi, rcx
00000001424bd0fb  f30f104140               movss    xmm0, dword ptr [rcx + 0x40]
00000001424bd100  f30f107140               movss    xmm6, dword ptr [rcx + 0x40]
00000001424bd105  0f100a                   movups   xmm1, xmmword ptr [rdx]
00000001424bd108  0f294c2440               movaps   xmmword ptr [rsp + 0x40], xmm1
00000001424bd10d  f30f11442450             movss    dword ptr [rsp + 0x50], xmm0
00000001424bd113  488b4128                 mov      rax, qword ptr [rcx + 0x28]
00000001424bd117  488b7908                 mov      rdi, qword ptr [rcx + 8]
00000001424bd11b  488b6910                 mov      rbp, qword ptr [rcx + 0x10]
00000001424bd11f  48c1e504                 shl      rbp, 4
00000001424bd123  4801fd                   add      rbp, rdi
00000001424bd126  0fc6f6c4                 shufps   xmm6, xmm6, 0xc4
00000001424bd12a  4531ed                   xor      r13d, r13d
00000001424bd12d  488d5c2440               lea      rbx, [rsp + 0x40]
00000001424bd132  4c8d7c2460               lea      r15, [rsp + 0x60]
00000001424bd137  4889442438               mov      qword ptr [rsp + 0x38], rax
00000001424bd13c  4889442430               mov      qword ptr [rsp + 0x30], rax
00000001424bd141  6666666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001424bd150  4839ef                   cmp      rdi, rbp
00000001424bd153  0f8494000000             je       0x1424bd1ed
00000001424bd159  4989fc                   mov      r12, rdi
00000001424bd15c  4589ee                   mov      r14d, r13d
00000001424bd15f  4889f9                   mov      rcx, rdi
00000001424bd162  4889da                   mov      rdx, rbx
00000001424bd165  e8c61893fe               call     0x140deea30 ; utils::geometry::aabb::Aabb2::intersects | _ZN5utils8geometry4aabb5Aabb210intersects17h3297ca0f8112fc38E
00000001424bd16a  84c0                     test     al, al
00000001424bd16c  754d                     jne      0x1424bd1bb
00000001424bd16e  498d7c2410               lea      rdi, [r12 + 0x10]
00000001424bd173  410f100424               movups   xmm0, xmmword ptr [r12]
00000001424bd178  0f58c6                   addps    xmm0, xmm6
00000001424bd17b  0f29442460               movaps   xmmword ptr [rsp + 0x60], xmm0
00000001424bd180  4c89f9                   mov      rcx, r15
00000001424bd183  4889da                   mov      rdx, rbx
00000001424bd186  e8a51893fe               call     0x140deea30 ; utils::geometry::aabb::Aabb2::intersects | _ZN5utils8geometry4aabb5Aabb210intersects17h3297ca0f8112fc38E
00000001424bd18b  458d6e01                 lea      r13d, [r14 + 1]
00000001424bd18f  84c0                     test     al, al
00000001424bd191  74bd                     je       0x1424bd150
00000001424bd193  488b7c2430               mov      rdi, qword ptr [rsp + 0x30]
00000001424bd198  483b7e18                 cmp      rdi, qword ptr [rsi + 0x18]
00000001424bd19c  742c                     je       0x1424bd1ca
00000001424bd19e  4983c410                 add      r12, 0x10
00000001424bd1a2  488b4620                 mov      rax, qword ptr [rsi + 0x20]
00000001424bd1a6  448934b8                 mov      dword ptr [rax + rdi*4], r14d
00000001424bd1aa  48ffc7                   inc      rdi
00000001424bd1ad  48897c2430               mov      qword ptr [rsp + 0x30], rdi
00000001424bd1b2  48897e28                 mov      qword ptr [rsi + 0x28], rdi
00000001424bd1b6  4c89e7                   mov      rdi, r12
00000001424bd1b9  eb95                     jmp      0x1424bd150
00000001424bd1bb  458d6e01                 lea      r13d, [r14 + 1]
00000001424bd1bf  488b7c2430               mov      rdi, qword ptr [rsp + 0x30]
00000001424bd1c4  483b7e18                 cmp      rdi, qword ptr [rsi + 0x18]
00000001424bd1c8  75d4                     jne      0x1424bd19e
00000001424bd1ca  48c744242004000000       mov      qword ptr [rsp + 0x20], 4
00000001424bd1d3  41b801000000             mov      r8d, 1
00000001424bd1d9  41b904000000             mov      r9d, 4
00000001424bd1df  488d4e18                 lea      rcx, [rsi + 0x18]
00000001424bd1e3  4889fa                   mov      rdx, rdi
00000001424bd1e6  e8c51f8c00               call     0x142d7f1b0 ; alloc::raw_vec::impl$4::reserve::do_reserve_and_handle<alloc::alloc::Global> | _ZN5alloc7raw_vec20RawVecInner$LT$A$GT$7reserve21do_reserve_and_handle17h0559268ff9d2f5acE
00000001424bd1eb  ebb1                     jmp      0x1424bd19e
00000001424bd1ed  488b5c2430               mov      rbx, qword ptr [rsp + 0x30]
00000001424bd1f2  488b7c2438               mov      rdi, qword ptr [rsp + 0x38]
00000001424bd1f7  4829fb                   sub      rbx, rdi
00000001424bd1fa  8b4644                   mov      eax, dword ptr [rsi + 0x44]
00000001424bd1fd  85db                     test     ebx, ebx
00000001424bd1ff  744e                     je       0x1424bd24f
00000001424bd201  4889c1                   mov      rcx, rax
00000001424bd204  48c1e120                 shl      rcx, 0x20
00000001424bd208  89da                     mov      edx, ebx
00000001424bd20a  4809ca                   or       rdx, rcx
00000001424bd20d  4889d1                   mov      rcx, rdx
00000001424bd210  48c1e91e                 shr      rcx, 0x1e
00000001424bd214  4831d1                   xor      rcx, rdx
00000001424bd217  48bab9e5e41c6d4758bf     movabs   rdx, 0xbf58476d1ce4e5b9
00000001424bd221  480fafd1                 imul     rdx, rcx
00000001424bd225  4889d1                   mov      rcx, rdx
00000001424bd228  48c1e91b                 shr      rcx, 0x1b
00000001424bd22c  4831d1                   xor      rcx, rdx
00000001424bd22f  48baeb113113bb49d094     movabs   rdx, 0x94d049bb133111eb
00000001424bd239  480fafd1                 imul     rdx, rcx
00000001424bd23d  4889d1                   mov      rcx, rdx
00000001424bd240  48c1e91f                 shr      rcx, 0x1f
00000001424bd244  48334e38                 xor      rcx, qword ptr [rsi + 0x38]
00000001424bd248  4831d1                   xor      rcx, rdx
00000001424bd24b  48894e38                 mov      qword ptr [rsi + 0x38], rcx
00000001424bd24f  ffc0                     inc      eax
00000001424bd251  894644                   mov      dword ptr [rsi + 0x44], eax
00000001424bd254  488b4e30                 mov      rcx, qword ptr [rsi + 0x30]
00000001424bd258  4801f9                   add      rcx, rdi
00000001424bd25b  b8ffffffff               mov      eax, 0xffffffff
00000001424bd260  4839c1                   cmp      rcx, rax
00000001424bd263  480f43c8                 cmovae   rcx, rax
00000001424bd267  89da                     mov      edx, ebx
00000001424bd269  e8f2af5bfe               call     0x140a78260 ; country_core::resources::roofs::roof_buffers::pack_window_cut_list | _ZN12country_core9resources5roofs12roof_buffers20pack_window_cut_list17h103d1f69623cb96dE
00000001424bd26e  85c0                     test     eax, eax
00000001424bd270  0f95c1                   setne    cl
00000001424bd273  48397c2430               cmp      qword ptr [rsp + 0x30], rdi
00000001424bd278  0f92c2                   setb     dl
00000001424bd27b  08ca                     or       dl, cl
00000001424bd27d  7504                     jne      0x1424bd283
00000001424bd27f  48897e28                 mov      qword ptr [rsi + 0x28], rdi
00000001424bd283  89da                     mov      edx, ebx
00000001424bd285  0f28742470               movaps   xmm6, xmmword ptr [rsp + 0x70]
00000001424bd28a  4881c488000000           add      rsp, 0x88
00000001424bd291  5b                       pop      rbx
00000001424bd292  5d                       pop      rbp
00000001424bd293  5f                       pop      rdi
00000001424bd294  5e                       pop      rsi
00000001424bd295  415c                     pop      r12
00000001424bd297  415d                     pop      r13
00000001424bd299  415e                     pop      r14
00000001424bd29b  415f                     pop      r15
00000001424bd29d  c3                       ret      