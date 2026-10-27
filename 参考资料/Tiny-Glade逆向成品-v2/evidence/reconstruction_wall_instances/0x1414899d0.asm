00000001414899d0  55                       push     rbp
00000001414899d1  4157                     push     r15
00000001414899d3  4156                     push     r14
00000001414899d5  4155                     push     r13
00000001414899d7  4154                     push     r12
00000001414899d9  56                       push     rsi
00000001414899da  57                       push     rdi
00000001414899db  53                       push     rbx
00000001414899dc  4881ece8010000           sub      rsp, 0x1e8
00000001414899e3  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001414899eb  440f29ad50010000         movaps   xmmword ptr [rbp + 0x150], xmm13
00000001414899f3  440f29a540010000         movaps   xmmword ptr [rbp + 0x140], xmm12
00000001414899fb  440f299d30010000         movaps   xmmword ptr [rbp + 0x130], xmm11
0000000141489a03  440f299520010000         movaps   xmmword ptr [rbp + 0x120], xmm10
0000000141489a0b  440f298d10010000         movaps   xmmword ptr [rbp + 0x110], xmm9
0000000141489a13  440f298500010000         movaps   xmmword ptr [rbp + 0x100], xmm8
0000000141489a1b  0f29bdf0000000           movaps   xmmword ptr [rbp + 0xf0], xmm7
0000000141489a22  0f29b5e0000000           movaps   xmmword ptr [rbp + 0xe0], xmm6
0000000141489a29  48c785d8000000feffffff   mov      qword ptr [rbp + 0xd8], 0xfffffffffffffffe
0000000141489a34  4c89cb                   mov      rbx, r9
0000000141489a37  4d89c6                   mov      r14, r8
0000000141489a3a  4989d4                   mov      r12, rdx
0000000141489a3d  4889ce                   mov      rsi, rcx
0000000141489a40  448abdf8010000           mov      r15b, byte ptr [rbp + 0x1f8]
0000000141489a47  4c8b8dd8010000           mov      r9, qword ptr [rbp + 0x1d8]
0000000141489a4e  0f2885e0010000           movaps   xmm0, xmmword ptr [rbp + 0x1e0]
0000000141489a55  0f11442420               movups   xmmword ptr [rsp + 0x20], xmm0
0000000141489a5a  488d4df8                 lea      rcx, [rbp - 8]
0000000141489a5e  4c89c2                   mov      rdx, r8
0000000141489a61  4989d8                   mov      r8, rbx
0000000141489a64  e8a7a8ffff               call     0x141484310 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::remapped_wall_cutouts
0000000141489a69  90                       nop      
0000000141489a6a  4c89f1                   mov      rcx, r14
0000000141489a6d  4489fa                   mov      edx, r15d
0000000141489a70  e81b674aff               call     0x140930190 ; country_core::resources::walls::public_wall_state::PublicWallState::wooden_stone_foundation_surface_top_y | _ZN12country_core9resources5walls17public_wall_state15PublicWallState37wooden_stone_foundation_surface_top_y17h6256acfd832f12b4E
0000000141489a75  90                       nop      
0000000141489a76  f30f108dd0010000         movss    xmm1, dword ptr [rbp + 0x1d0]
0000000141489a7e  a801                     test     al, 1
0000000141489a80  7509                     jne      0x141489a8b
0000000141489a82  f3410f108678020000       movss    xmm0, dword ptr [r14 + 0x278]
0000000141489a8b  f30f101541e09a01         movss    xmm2, dword ptr [rip + 0x19ae041]
0000000141489a93  f30f58d0                 addss    xmm2, xmm0
0000000141489a97  0f2ed1                   ucomiss  xmm2, xmm1
0000000141489a9a  0f83b1010000             jae      0x141489c51
0000000141489aa0  f30f109df0010000         movss    xmm3, dword ptr [rbp + 0x1f0]
0000000141489aa8  f30f107b3c               movss    xmm7, dword ptr [rbx + 0x3c]
0000000141489aad  c7451000000000           mov      dword ptr [rbp + 0x10], 0
0000000141489ab4  f30f114514               movss    dword ptr [rbp + 0x14], xmm0
0000000141489ab9  f30f117d18               movss    dword ptr [rbp + 0x18], xmm7
0000000141489abe  f30f114d1c               movss    dword ptr [rbp + 0x1c], xmm1
0000000141489ac3  488d4db8                 lea      rcx, [rbp - 0x48]
0000000141489ac7  488d5510                 lea      rdx, [rbp + 0x10]
0000000141489acb  41b001                   mov      r8b, 1
0000000141489ace  e80dedffff               call     0x1414887e0 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::subdivide_region_into_planks | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards28subdivide_region_into_planks17h268688fde427737dE
0000000141489ad3  90                       nop      
0000000141489ad4  488b45b8                 mov      rax, qword ptr [rbp - 0x48]
0000000141489ad8  488b4dc0                 mov      rcx, qword ptr [rbp - 0x40]
0000000141489adc  488b55c8                 mov      rdx, qword ptr [rbp - 0x38]
0000000141489ae0  48c1e204                 shl      rdx, 4
0000000141489ae4  4801ca                   add      rdx, rcx
0000000141489ae7  48894d40                 mov      qword ptr [rbp + 0x40], rcx
0000000141489aeb  48894d48                 mov      qword ptr [rbp + 0x48], rcx
0000000141489aef  48894550                 mov      qword ptr [rbp + 0x50], rax
0000000141489af3  48895558                 mov      qword ptr [rbp + 0x58], rdx
0000000141489af7  48895d60                 mov      qword ptr [rbp + 0x60], rbx
0000000141489afb  488d4de0                 lea      rcx, [rbp - 0x20]
0000000141489aff  488d5540                 lea      rdx, [rbp + 0x40]
0000000141489b03  e8f8c5f5ff               call     0x1413e6100 ; _ZN5alloc3vec16in_place_collect108_$LT$impl$u20$alloc..vec..spec_from_iter..SpecFromIter$LT$T$C$I$GT$$u20$for$u20$alloc..vec..Vec$LT$T$GT$$GT$9from_iter17h47b8232df6cf9a5dE | alloc::vec::in_place_collect::impl$1::from_iter<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceRegion,core::iter::adapters::map::Map<alloc::vec::into_iter::IntoIter<utils::geometry::aabb::Aabb2,alloc::alloc::Global>,system_wall_constructor::construct_wooden_walls::construct_wall_boards::plan_circle_horizontal_wall_boards::closure_env$0> >
0000000141489b08  90                       nop      
0000000141489b09  488b4d00                 mov      rcx, qword ptr [rbp]
0000000141489b0d  488b5508                 mov      rdx, qword ptr [rbp + 8]
0000000141489b11  c685d700000001           mov      byte ptr [rbp + 0xd7], 1
0000000141489b18  4c8d45e0                 lea      r8, [rbp - 0x20]
0000000141489b1c  41b101                   mov      r9b, 1
0000000141489b1f  e8ecabffff               call     0x141484710 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::subtract_wall_cutouts
0000000141489b24  90                       nop      
0000000141489b25  488b45e0                 mov      rax, qword ptr [rbp - 0x20]
0000000141489b29  488b4de8                 mov      rcx, qword ptr [rbp - 0x18]
0000000141489b2d  488b55f0                 mov      rdx, qword ptr [rbp - 0x10]
0000000141489b31  4885d2                   test     rdx, rdx
0000000141489b34  744c                     je       0x141489b82
0000000141489b36  4c8d4548                 lea      r8, [rbp + 0x48]
0000000141489b3a  4c8d4921                 lea      r9, [rcx + 0x21]
0000000141489b3e  4989d2                   mov      r10, rdx
0000000141489b41  6666666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141489b50  410f1041ef               movups   xmm0, xmmword ptr [r9 - 0x11]
0000000141489b55  410f1100                 movups   xmmword ptr [r8], xmm0
0000000141489b59  49c741df00000000         mov      qword ptr [r9 - 0x21], 0
0000000141489b61  0f104540                 movups   xmm0, xmmword ptr [rbp + 0x40]
0000000141489b65  410f1141e7               movups   xmmword ptr [r9 - 0x19], xmm0
0000000141489b6a  4c8b5d50                 mov      r11, qword ptr [rbp + 0x50]
0000000141489b6e  4d8959f7                 mov      qword ptr [r9 - 9], r11
0000000141489b72  6641c741ff0100           mov      word ptr [r9 - 1], 1
0000000141489b79  4983c128                 add      r9, 0x28
0000000141489b7d  49ffca                   dec      r10
0000000141489b80  75ce                     jne      0x141489b50
0000000141489b82  48894570                 mov      qword ptr [rbp + 0x70], rax
0000000141489b86  48894d78                 mov      qword ptr [rbp + 0x78], rcx
0000000141489b8a  48899580000000           mov      qword ptr [rbp + 0x80], rdx
0000000141489b91  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141489b95  e846f0ffff               call     0x141488be0 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::merge_narrow_planks_horizontal
0000000141489b9a  90                       nop      
0000000141489b9b  f30f1005a5dc9a01         movss    xmm0, dword ptr [rip + 0x19adca5]
0000000141489ba3  0f2ec7                   ucomiss  xmm0, xmm7
0000000141489ba6  0f838c060000             jae      0x14148a238
0000000141489bac  488b4570                 mov      rax, qword ptr [rbp + 0x70]
0000000141489bb0  48894568                 mov      qword ptr [rbp + 0x68], rax
0000000141489bb4  488b4578                 mov      rax, qword ptr [rbp + 0x78]
0000000141489bb8  488985c8000000           mov      qword ptr [rbp + 0xc8], rax
0000000141489bbf  488b8d80000000           mov      rcx, qword ptr [rbp + 0x80]
0000000141489bc6  48c7457000000000         mov      qword ptr [rbp + 0x70], 0
0000000141489bce  48c7457808000000         mov      qword ptr [rbp + 0x78], 8
0000000141489bd6  48c7858000000000000000   mov      qword ptr [rbp + 0x80], 0
0000000141489be1  4885c9                   test     rcx, rcx
0000000141489be4  48898db8000000           mov      qword ptr [rbp + 0xb8], rcx
0000000141489beb  488975d0                 mov      qword ptr [rbp - 0x30], rsi
0000000141489bef  4c8965d8                 mov      qword ptr [rbp - 0x28], r12
0000000141489bf3  0f84e0000000             je       0x141489cd9
0000000141489bf9  4889cf                   mov      rdi, rcx
0000000141489bfc  e85f52bffe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
0000000141489c01  ba01000000               mov      edx, 1
0000000141489c06  4889f9                   mov      rcx, rdi
0000000141489c09  e8d21e22ff               call     0x1406abae0 ; _RNvCsfLfy6EI15iL_7___rustc19___rust_alloc_zeroed
0000000141489c0e  488985b0000000           mov      qword ptr [rbp + 0xb0], rax
0000000141489c15  4885c0                   test     rax, rax
0000000141489c18  0f849d060000             je       0x14148a2bb
0000000141489c1e  488d04fd00000000         lea      rax, [rdi*8]
0000000141489c26  488d1c80                 lea      rbx, [rax + rax*4]
0000000141489c2a  e83152bffe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
0000000141489c2f  ba08000000               mov      edx, 8
0000000141489c34  4889d9                   mov      rcx, rbx
0000000141489c37  e8741e22ff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
0000000141489c3c  4885c0                   test     rax, rax
0000000141489c3f  0f848d060000             je       0x14148a2d2
0000000141489c45  488b8db8000000           mov      rcx, qword ptr [rbp + 0xb8]
0000000141489c4c  e99b000000               jmp      0x141489cec
0000000141489c51  48c70600000000           mov      qword ptr [rsi], 0
0000000141489c58  48c7460808000000         mov      qword ptr [rsi + 8], 8
0000000141489c60  48c7461000000000         mov      qword ptr [rsi + 0x10], 0
0000000141489c68  488b55f8                 mov      rdx, qword ptr [rbp - 8]
0000000141489c6c  4885d2                   test     rdx, rdx
0000000141489c6f  7413                     je       0x141489c84
0000000141489c71  488b4d00                 mov      rcx, qword ptr [rbp]
0000000141489c75  48c1e204                 shl      rdx, 4
0000000141489c79  41b804000000             mov      r8d, 4
0000000141489c7f  e83c1e22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141489c84  4889f0                   mov      rax, rsi
0000000141489c87  0f28b5e0000000           movaps   xmm6, xmmword ptr [rbp + 0xe0]
0000000141489c8e  0f28bdf0000000           movaps   xmm7, xmmword ptr [rbp + 0xf0]
0000000141489c95  440f288500010000         movaps   xmm8, xmmword ptr [rbp + 0x100]
0000000141489c9d  440f288d10010000         movaps   xmm9, xmmword ptr [rbp + 0x110]
0000000141489ca5  440f289520010000         movaps   xmm10, xmmword ptr [rbp + 0x120]
0000000141489cad  440f289d30010000         movaps   xmm11, xmmword ptr [rbp + 0x130]
0000000141489cb5  440f28a540010000         movaps   xmm12, xmmword ptr [rbp + 0x140]
0000000141489cbd  440f28ad50010000         movaps   xmm13, xmmword ptr [rbp + 0x150]
0000000141489cc5  4881c4e8010000           add      rsp, 0x1e8
0000000141489ccc  5b                       pop      rbx
0000000141489ccd  5f                       pop      rdi
0000000141489cce  5e                       pop      rsi
0000000141489ccf  415c                     pop      r12
0000000141489cd1  415d                     pop      r13
0000000141489cd3  415e                     pop      r14
0000000141489cd5  415f                     pop      r15
0000000141489cd7  5d                       pop      rbp
0000000141489cd8  c3                       ret      
0000000141489cd9  b808000000               mov      eax, 8
0000000141489cde  ba01000000               mov      edx, 1
0000000141489ce3  488995b0000000           mov      qword ptr [rbp + 0xb0], rdx
0000000141489cea  31db                     xor      ebx, ebx
0000000141489cec  48898d90000000           mov      qword ptr [rbp + 0x90], rcx
0000000141489cf3  48898598000000           mov      qword ptr [rbp + 0x98], rax
0000000141489cfa  48c785a000000000000000   mov      qword ptr [rbp + 0xa0], 0
0000000141489d05  f3440f10053edb9a01       movss    xmm8, dword ptr [rip + 0x19adb3e]
0000000141489d0e  f3440f58c7               addss    xmm8, xmm7
0000000141489d13  4531c0                   xor      r8d, r8d
0000000141489d16  f3440f100d51db9a01       movss    xmm9, dword ptr [rip + 0x19adb51]
0000000141489d1f  440f2815b9da9a01         movaps   xmm10, xmmword ptr [rip + 0x19adab9]
0000000141489d27  4531f6                   xor      r14d, r14d
0000000141489d2a  eb14                     jmp      0x141489d40
0000000141489d2c  488b8db8000000           mov      rcx, qword ptr [rbp + 0xb8]
0000000141489d33  666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141489d40  4939ce                   cmp      r14, rcx
0000000141489d43  0f9285c7000000           setb     byte ptr [rbp + 0xc7]
0000000141489d4a  0f8371030000             jae      0x14148a0c1
0000000141489d50  4d89f5                   mov      r13, r14
0000000141489d53  49ffc6                   inc      r14
0000000141489d56  488b85b0000000           mov      rax, qword ptr [rbp + 0xb0]
0000000141489d5d  42803c2800               cmp      byte ptr [rax + r13], 0
0000000141489d62  75dc                     jne      0x141489d40
0000000141489d64  4a8d04ad00000000         lea      rax, [r13*4]
0000000141489d6c  4c01e8                   add      rax, r13
0000000141489d6f  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489d76  4c8b3cc2                 mov      r15, qword ptr [rdx + rax*8]
0000000141489d7a  4c8b64c208               mov      r12, qword ptr [rdx + rax*8 + 8]
0000000141489d7f  f30f1044c210             movss    xmm0, dword ptr [rdx + rax*8 + 0x10]
0000000141489d85  f3440f105cc214           movss    xmm11, dword ptr [rdx + rax*8 + 0x14]
0000000141489d8c  f3440f106cc218           movss    xmm13, dword ptr [rdx + rax*8 + 0x18]
0000000141489d93  f3440f1064c21c           movss    xmm12, dword ptr [rdx + rax*8 + 0x1c]
0000000141489d9a  0fb67cc220               movzx    edi, byte ptr [rdx + rax*8 + 0x20]
0000000141489d9f  0fb674c221               movzx    esi, byte ptr [rdx + rax*8 + 0x21]
0000000141489da4  440f2ec8                 ucomiss  xmm9, xmm0
0000000141489da8  720a                     jb       0x141489db4
0000000141489daa  450f2ee8                 ucomiss  xmm13, xmm8
0000000141489dae  0f8340020000             jae      0x141489ff4
0000000141489db4  440f2ec8                 ucomiss  xmm9, xmm0
0000000141489db8  7286                     jb       0x141489d40
0000000141489dba  31c0                     xor      eax, eax
0000000141489dbc  31c9                     xor      ecx, ecx
0000000141489dbe  41f6c701                 test     r15b, 1
0000000141489dc2  751c                     jne      0x141489de0
0000000141489dc4  e9e7000000               jmp      0x141489eb0
0000000141489dc9  0f1f8000000000           nop      dword ptr [rax]
0000000141489dd0  48ffc1                   inc      rcx
0000000141489dd3  4883c028                 add      rax, 0x28
0000000141489dd7  4839c3                   cmp      rbx, rax
0000000141489dda  0f844cffffff             je       0x141489d2c
0000000141489de0  48398db8000000           cmp      qword ptr [rbp + 0xb8], rcx
0000000141489de7  0f849f040000             je       0x14148a28c
0000000141489ded  4939cd                   cmp      r13, rcx
0000000141489df0  74de                     je       0x141489dd0
0000000141489df2  488b95b0000000           mov      rdx, qword ptr [rbp + 0xb0]
0000000141489df9  803c0a00                 cmp      byte ptr [rdx + rcx], 0
0000000141489dfd  75d1                     jne      0x141489dd0
0000000141489dff  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489e06  f30f10440218             movss    xmm0, dword ptr [rdx + rax + 0x18]
0000000141489e0c  410f2ec0                 ucomiss  xmm0, xmm8
0000000141489e10  72be                     jb       0x141489dd0
0000000141489e12  410f28c3                 movaps   xmm0, xmm11
0000000141489e16  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489e1d  f30f5c440214             subss    xmm0, dword ptr [rdx + rax + 0x14]
0000000141489e23  410f54c2                 andps    xmm0, xmm10
0000000141489e27  440f2ec8                 ucomiss  xmm9, xmm0
0000000141489e2b  72a3                     jb       0x141489dd0
0000000141489e2d  410f28c4                 movaps   xmm0, xmm12
0000000141489e31  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489e38  f30f5c44021c             subss    xmm0, dword ptr [rdx + rax + 0x1c]
0000000141489e3e  410f54c2                 andps    xmm0, xmm10
0000000141489e42  440f2ec8                 ucomiss  xmm9, xmm0
0000000141489e46  7288                     jb       0x141489dd0
0000000141489e48  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489e4f  40387c0220               cmp      byte ptr [rdx + rax + 0x20], dil
0000000141489e54  0f8576ffffff             jne      0x141489dd0
0000000141489e5a  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489e61  833c0201                 cmp      dword ptr [rdx + rax], 1
0000000141489e65  0f8565ffffff             jne      0x141489dd0
0000000141489e6b  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489e72  4c39640208               cmp      qword ptr [rdx + rax + 8], r12
0000000141489e77  0f8553ffffff             jne      0x141489dd0
0000000141489e7d  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489e84  4038740221               cmp      byte ptr [rdx + rax + 0x21], sil
0000000141489e89  0f8541ffffff             jne      0x141489dd0
0000000141489e8f  e9b9000000               jmp      0x141489f4d
0000000141489e94  6666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141489ea0  48ffc1                   inc      rcx
0000000141489ea3  4883c028                 add      rax, 0x28
0000000141489ea7  4839c3                   cmp      rbx, rax
0000000141489eaa  0f8438010000             je       0x141489fe8
0000000141489eb0  48398db8000000           cmp      qword ptr [rbp + 0xb8], rcx
0000000141489eb7  0f84cf030000             je       0x14148a28c
0000000141489ebd  4939cd                   cmp      r13, rcx
0000000141489ec0  74de                     je       0x141489ea0
0000000141489ec2  488b95b0000000           mov      rdx, qword ptr [rbp + 0xb0]
0000000141489ec9  803c0a00                 cmp      byte ptr [rdx + rcx], 0
0000000141489ecd  75d1                     jne      0x141489ea0
0000000141489ecf  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489ed6  f30f10440218             movss    xmm0, dword ptr [rdx + rax + 0x18]
0000000141489edc  410f2ec0                 ucomiss  xmm0, xmm8
0000000141489ee0  72be                     jb       0x141489ea0
0000000141489ee2  410f28c3                 movaps   xmm0, xmm11
0000000141489ee6  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489eed  f30f5c440214             subss    xmm0, dword ptr [rdx + rax + 0x14]
0000000141489ef3  410f54c2                 andps    xmm0, xmm10
0000000141489ef7  440f2ec8                 ucomiss  xmm9, xmm0
0000000141489efb  72a3                     jb       0x141489ea0
0000000141489efd  410f28c4                 movaps   xmm0, xmm12
0000000141489f01  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489f08  f30f5c44021c             subss    xmm0, dword ptr [rdx + rax + 0x1c]
0000000141489f0e  410f54c2                 andps    xmm0, xmm10
0000000141489f12  440f2ec8                 ucomiss  xmm9, xmm0
0000000141489f16  7288                     jb       0x141489ea0
0000000141489f18  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489f1f  40387c0220               cmp      byte ptr [rdx + rax + 0x20], dil
0000000141489f24  0f8576ffffff             jne      0x141489ea0
0000000141489f2a  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489f31  803c0200                 cmp      byte ptr [rdx + rax], 0
0000000141489f35  0f8565ffffff             jne      0x141489ea0
0000000141489f3b  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489f42  4038740221               cmp      byte ptr [rdx + rax + 0x21], sil
0000000141489f47  0f8553ffffff             jne      0x141489ea0
0000000141489f4d  483b8db8000000           cmp      rcx, qword ptr [rbp + 0xb8]
0000000141489f54  0f83af030000             jae      0x14148a309
0000000141489f5a  488d0489                 lea      rax, [rcx + rcx*4]
0000000141489f5e  488b95c8000000           mov      rdx, qword ptr [rbp + 0xc8]
0000000141489f65  f30f1074c210             movss    xmm6, dword ptr [rdx + rax*8 + 0x10]
0000000141489f6b  f30f1044c214             movss    xmm0, dword ptr [rdx + rax*8 + 0x14]
0000000141489f71  f30f104cc21c             movss    xmm1, dword ptr [rdx + rax*8 + 0x1c]
0000000141489f77  488b85b0000000           mov      rax, qword ptr [rbp + 0xb0]
0000000141489f7e  42c6042801               mov      byte ptr [rax + r13], 1
0000000141489f83  c6040801                 mov      byte ptr [rax + rcx], 1
0000000141489f87  410f28d3                 movaps   xmm2, xmm11
0000000141489f8b  f3410fc2d303             cmpunordss xmm2, xmm11
0000000141489f91  0f28da                   movaps   xmm3, xmm2
0000000141489f94  0f54d8                   andps    xmm3, xmm0
0000000141489f97  f3410f5dc3               minss    xmm0, xmm11
0000000141489f9c  0f55d0                   andnps   xmm2, xmm0
0000000141489f9f  0f56d3                   orps     xmm2, xmm3
0000000141489fa2  440f28da                 movaps   xmm11, xmm2
0000000141489fa6  410f28c4                 movaps   xmm0, xmm12
0000000141489faa  f3410fc2c403             cmpunordss xmm0, xmm12
0000000141489fb0  0f28d0                   movaps   xmm2, xmm0
0000000141489fb3  0f54d1                   andps    xmm2, xmm1
0000000141489fb6  f3410f5fcc               maxss    xmm1, xmm12
0000000141489fbb  0f55c1                   andnps   xmm0, xmm1
0000000141489fbe  0f56c2                   orps     xmm0, xmm2
0000000141489fc1  440f28e0                 movaps   xmm12, xmm0
0000000141489fc5  4c8bada0000000           mov      r13, qword ptr [rbp + 0xa0]
0000000141489fcc  4c3bad90000000           cmp      r13, qword ptr [rbp + 0x90]
0000000141489fd3  0f858a000000             jne      0x14148a063
0000000141489fd9  488d8d90000000           lea      rcx, [rbp + 0x90]
0000000141489fe0  e8fb4d8f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
0000000141489fe5  90                       nop      
0000000141489fe6  eb7b                     jmp      0x14148a063
0000000141489fe8  488b8db8000000           mov      rcx, qword ptr [rbp + 0xb8]
0000000141489fef  e94cfdffff               jmp      0x141489d40
0000000141489ff4  488b85b0000000           mov      rax, qword ptr [rbp + 0xb0]
0000000141489ffb  42c6042801               mov      byte ptr [rax + r13], 1
000000014148a000  488b45d8                 mov      rax, qword ptr [rbp - 0x28]
000000014148a004  48894520                 mov      qword ptr [rbp + 0x20], rax
000000014148a008  488d4d20                 lea      rcx, [rbp + 0x20]
000000014148a00c  e85fb9e8fe               call     0x140315970 ; motomoto::impl$0::as_tag | cmsPipelineGetPtrToFirstStage
000000014148a011  90                       nop      
000000014148a012  4869c053640100           imul     rax, rax, 0x16453
000000014148a019  4969cd55f91300           imul     rcx, r13, 0x13f955
000000014148a020  4801c8                   add      rax, rcx
000000014148a023  4883c049                 add      rax, 0x49
000000014148a027  48894540                 mov      qword ptr [rbp + 0x40], rax
000000014148a02b  488d4d40                 lea      rcx, [rbp + 0x40]
000000014148a02f  e84c8897ff               call     0x140e02880 ; fastrand::Rng::f32 | _ZN8fastrand3Rng3f3217h74c3355474b41115E
000000014148a034  90                       nop      
000000014148a035  0f28f0                   movaps   xmm6, xmm0
000000014148a038  f30f59f7                 mulss    xmm6, xmm7
000000014148a03c  4c8bada0000000           mov      r13, qword ptr [rbp + 0xa0]
000000014148a043  4c3bad90000000           cmp      r13, qword ptr [rbp + 0x90]
000000014148a04a  7513                     jne      0x14148a05f
000000014148a04c  488d8d90000000           lea      rcx, [rbp + 0x90]
000000014148a053  e8884d8f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
000000014148a058  90                       nop      
000000014148a059  440f28ee                 movaps   xmm13, xmm6
000000014148a05d  eb04                     jmp      0x14148a063
000000014148a05f  440f28ee                 movaps   xmm13, xmm6
000000014148a063  f3440f58ef               addss    xmm13, xmm7
000000014148a068  488b8598000000           mov      rax, qword ptr [rbp + 0x98]
000000014148a06f  4a8d0cad00000000         lea      rcx, [r13*4]
000000014148a077  4c01e9                   add      rcx, r13
000000014148a07a  4c893cc8                 mov      qword ptr [rax + rcx*8], r15
000000014148a07e  4c8964c808               mov      qword ptr [rax + rcx*8 + 8], r12
000000014148a083  f30f1174c810             movss    dword ptr [rax + rcx*8 + 0x10], xmm6
000000014148a089  f3440f115cc814           movss    dword ptr [rax + rcx*8 + 0x14], xmm11
000000014148a090  f3440f116cc818           movss    dword ptr [rax + rcx*8 + 0x18], xmm13
000000014148a097  f3440f1164c81c           movss    dword ptr [rax + rcx*8 + 0x1c], xmm12
000000014148a09e  40887cc820               mov      byte ptr [rax + rcx*8 + 0x20], dil
000000014148a0a3  408874c821               mov      byte ptr [rax + rcx*8 + 0x21], sil
000000014148a0a8  49ffc5                   inc      r13
000000014148a0ab  4d89e8                   mov      r8, r13
000000014148a0ae  4c89ada0000000           mov      qword ptr [rbp + 0xa0], r13
000000014148a0b5  488b8db8000000           mov      rcx, qword ptr [rbp + 0xb8]
000000014148a0bc  e97ffcffff               jmp      0x141489d40
000000014148a0c1  488d0489                 lea      rax, [rcx + rcx*4]
000000014148a0c5  488b8dc8000000           mov      rcx, qword ptr [rbp + 0xc8]
000000014148a0cc  488d34c1                 lea      rsi, [rcx + rax*8]
000000014148a0d0  4531f6                   xor      r14d, r14d
000000014148a0d3  488dbd90000000           lea      rdi, [rbp + 0x90]
000000014148a0da  4889c8                   mov      rax, rcx
000000014148a0dd  4d89c4                   mov      r12, r8
000000014148a0e0  4c89f1                   mov      rcx, r14
000000014148a0e3  666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
000000014148a0f0  4839f0                   cmp      rax, rsi
000000014148a0f3  0f848a000000             je       0x14148a183
000000014148a0f9  4889c3                   mov      rbx, rax
000000014148a0fc  4c8b38                   mov      r15, qword ptr [rax]
000000014148a0ff  4983ff02                 cmp      r15, 2
000000014148a103  747e                     je       0x14148a183
000000014148a105  0f104308                 movups   xmm0, xmmword ptr [rbx + 8]
000000014148a109  0f104b18                 movups   xmm1, xmmword ptr [rbx + 0x18]
000000014148a10d  0f294d50                 movaps   xmmword ptr [rbp + 0x50], xmm1
000000014148a111  0f294540                 movaps   xmmword ptr [rbp + 0x40], xmm0
000000014148a115  483b8db8000000           cmp      rcx, qword ptr [rbp + 0xb8]
000000014148a11c  0f8383010000             jae      0x14148a2a5
000000014148a122  4c8d7101                 lea      r14, [rcx + 1]
000000014148a126  488d4328                 lea      rax, [rbx + 0x28]
000000014148a12a  488b95b0000000           mov      rdx, qword ptr [rbp + 0xb0]
000000014148a131  803c0a00                 cmp      byte ptr [rdx + rcx], 0
000000014148a135  4c89f1                   mov      rcx, r14
000000014148a138  75b6                     jne      0x14148a0f0
000000014148a13a  4c3ba590000000           cmp      r12, qword ptr [rbp + 0x90]
000000014148a141  7509                     jne      0x14148a14c
000000014148a143  4889f9                   mov      rcx, rdi
000000014148a146  e8954c8f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
000000014148a14b  90                       nop      
000000014148a14c  4883c328                 add      rbx, 0x28
000000014148a150  488b8598000000           mov      rax, qword ptr [rbp + 0x98]
000000014148a157  4b8d0ca4                 lea      rcx, [r12 + r12*4]
000000014148a15b  4c893cc8                 mov      qword ptr [rax + rcx*8], r15
000000014148a15f  0f284540                 movaps   xmm0, xmmword ptr [rbp + 0x40]
000000014148a163  0f284d50                 movaps   xmm1, xmmword ptr [rbp + 0x50]
000000014148a167  0f1144c808               movups   xmmword ptr [rax + rcx*8 + 8], xmm0
000000014148a16c  0f114cc818               movups   xmmword ptr [rax + rcx*8 + 0x18], xmm1
000000014148a171  49ffc4                   inc      r12
000000014148a174  4c89a5a0000000           mov      qword ptr [rbp + 0xa0], r12
000000014148a17b  4889d8                   mov      rax, rbx
000000014148a17e  e95dffffff               jmp      0x14148a0e0
000000014148a183  488b4568                 mov      rax, qword ptr [rbp + 0x68]
000000014148a187  4885c0                   test     rax, rax
000000014148a18a  7425                     je       0x14148a1b1
000000014148a18c  488d04c500000000         lea      rax, [rax*8]
000000014148a194  488d1480                 lea      rdx, [rax + rax*4]
000000014148a198  41b808000000             mov      r8d, 8
000000014148a19e  488b8dc8000000           mov      rcx, qword ptr [rbp + 0xc8]
000000014148a1a5  e8161922ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148a1aa  4c8ba5a0000000           mov      r12, qword ptr [rbp + 0xa0]
000000014148a1b1  488bbd98000000           mov      rdi, qword ptr [rbp + 0x98]
000000014148a1b8  488d85af000000           lea      rax, [rbp + 0xaf]
000000014148a1bf  48894520                 mov      qword ptr [rbp + 0x20], rax
000000014148a1c3  4983fc02                 cmp      r12, 2
000000014148a1c7  0f838f000000             jae      0x14148a25c
000000014148a1cd  488b85a0000000           mov      rax, qword ptr [rbp + 0xa0]
000000014148a1d4  48894530                 mov      qword ptr [rbp + 0x30], rax
000000014148a1d8  0f108590000000           movups   xmm0, xmmword ptr [rbp + 0x90]
000000014148a1df  0f294520                 movaps   xmmword ptr [rbp + 0x20], xmm0
000000014148a1e3  488b4570                 mov      rax, qword ptr [rbp + 0x70]
000000014148a1e7  4885c0                   test     rax, rax
000000014148a1ea  7417                     je       0x14148a203
000000014148a1ec  488b4d78                 mov      rcx, qword ptr [rbp + 0x78]
000000014148a1f0  48c1e003                 shl      rax, 3
000000014148a1f4  488d1480                 lea      rdx, [rax + rax*4]
000000014148a1f8  41b808000000             mov      r8d, 8
000000014148a1fe  e8bd1822ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148a203  488b4530                 mov      rax, qword ptr [rbp + 0x30]
000000014148a207  48898580000000           mov      qword ptr [rbp + 0x80], rax
000000014148a20e  0f284520                 movaps   xmm0, xmmword ptr [rbp + 0x20]
000000014148a212  0f294570                 movaps   xmmword ptr [rbp + 0x70], xmm0
000000014148a216  488b95b8000000           mov      rdx, qword ptr [rbp + 0xb8]
000000014148a21d  4885d2                   test     rdx, rdx
000000014148a220  488b75d0                 mov      rsi, qword ptr [rbp - 0x30]
000000014148a224  7412                     je       0x14148a238
000000014148a226  41b801000000             mov      r8d, 1
000000014148a22c  488b8db0000000           mov      rcx, qword ptr [rbp + 0xb0]
000000014148a233  e8881822ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148a238  488b8580000000           mov      rax, qword ptr [rbp + 0x80]
000000014148a23f  48894610                 mov      qword ptr [rsi + 0x10], rax
000000014148a243  0f284570                 movaps   xmm0, xmmword ptr [rbp + 0x70]
000000014148a247  0f1106                   movups   xmmword ptr [rsi], xmm0
000000014148a24a  488b55f8                 mov      rdx, qword ptr [rbp - 8]
000000014148a24e  4885d2                   test     rdx, rdx
000000014148a251  0f851afaffff             jne      0x141489c71
000000014148a257  e928faffff               jmp      0x141489c84
000000014148a25c  4983fc15                 cmp      r12, 0x15
000000014148a260  0f838e000000             jae      0x14148a2f4
000000014148a266  4b8d04a4                 lea      rax, [r12 + r12*4]
000000014148a26a  488d34c7                 lea      rsi, [rdi + rax*8]
000000014148a26e  488d5f28                 lea      rbx, [rdi + 0x28]
000000014148a272  4889f9                   mov      rcx, rdi
000000014148a275  4889da                   mov      rdx, rbx
000000014148a278  e8630efdff               call     0x14145b0e0 ; _ZN4core5slice4sort6shared9smallsort11insert_tail17h5e16c08b2baa4f9bE.llvm.7236408601036147505 | _ZN4core5slice4sort6shared9smallsort11insert_tail17h7b700fd9418c4a76E.llvm.7236408601036147505
000000014148a27d  90                       nop      
000000014148a27e  4883c328                 add      rbx, 0x28
000000014148a282  4839f3                   cmp      rbx, rsi
000000014148a285  75eb                     jne      0x14148a272
000000014148a287  e941ffffff               jmp      0x14148a1cd
000000014148a28c  4c8d058d30e801           lea      r8, [rip + 0x1e8308d]
000000014148a293  488b8db8000000           mov      rcx, qword ptr [rbp + 0xb8]
000000014148a29a  4889ca                   mov      rdx, rcx
000000014148a29d  e850df9301               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
000000014148a2a2  90                       nop      
000000014148a2a3  eb78                     jmp      0x14148a31d
000000014148a2a5  4c8d054430e801           lea      r8, [rip + 0x1e83044]
000000014148a2ac  488b95b8000000           mov      rdx, qword ptr [rbp + 0xb8]
000000014148a2b3  e83adf9301               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
000000014148a2b8  90                       nop      
000000014148a2b9  eb62                     jmp      0x14148a31d
000000014148a2bb  c685d600000001           mov      byte ptr [rbp + 0xd6], 1
000000014148a2c2  b901000000               mov      ecx, 1
000000014148a2c7  4889fa                   mov      rdx, rdi
000000014148a2ca  e85bdb9301               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
000000014148a2cf  90                       nop      
000000014148a2d0  eb4b                     jmp      0x14148a31d
000000014148a2d2  488b85b0000000           mov      rax, qword ptr [rbp + 0xb0]
000000014148a2d9  48894538                 mov      qword ptr [rbp + 0x38], rax
000000014148a2dd  c685d500000001           mov      byte ptr [rbp + 0xd5], 1
000000014148a2e4  b908000000               mov      ecx, 8
000000014148a2e9  4889da                   mov      rdx, rbx
000000014148a2ec  e839db9301               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
000000014148a2f1  90                       nop      
000000014148a2f2  eb29                     jmp      0x14148a31d
000000014148a2f4  4c8d4520                 lea      r8, [rbp + 0x20]
000000014148a2f8  4889f9                   mov      rcx, rdi
000000014148a2fb  4c89e2                   mov      rdx, r12
000000014148a2fe  e8fdb0fdff               call     0x141465400 ; _ZN4core5slice4sort6stable14driftsort_main17h05dedffe9a33190eE | _ZN4core5slice4sort6stable14driftsort_main17h6919b7a8be3b8545E
000000014148a303  90                       nop      
000000014148a304  e9c4feffff               jmp      0x14148a1cd
000000014148a309  4c8d05f82fe801           lea      r8, [rip + 0x1e82ff8]
000000014148a310  488b95b8000000           mov      rdx, qword ptr [rbp + 0xb8]
000000014148a317  e8d6de9301               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
000000014148a31c  90                       nop      
000000014148a31d  0f0b                     ud2      
000000014148a31f  90                       nop      
000000014148a320  4889542410               mov      qword ptr [rsp + 0x10], rdx
000000014148a325  55                       push     rbp
000000014148a326  4157                     push     r15
000000014148a328  4156                     push     r14
000000014148a32a  4155                     push     r13
000000014148a32c  4154                     push     r12
000000014148a32e  56                       push     rsi
000000014148a32f  57                       push     rdi
000000014148a330  53                       push     rbx
000000014148a331  4881ecb8000000           sub      rsp, 0xb8
000000014148a338  488daa80000000           lea      rbp, [rdx + 0x80]
000000014148a33f  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
000000014148a345  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
000000014148a34b  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
000000014148a351  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
000000014148a357  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
000000014148a35d  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
000000014148a366  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
000000014148a36e  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
000000014148a376  488b55f8                 mov      rdx, qword ptr [rbp - 8]
000000014148a37a  4885d2                   test     rdx, rdx
000000014148a37d  7413                     je       0x14148a392
000000014148a37f  488b4d00                 mov      rcx, qword ptr [rbp]
000000014148a383  48c1e204                 shl      rdx, 4
000000014148a387  41b804000000             mov      r8d, 4
000000014148a38d  e82e1722ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148a392  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
000000014148a39a  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
000000014148a3a2  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
000000014148a3ab  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
000000014148a3b1  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
000000014148a3b7  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
000000014148a3bd  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
000000014148a3c3  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
000000014148a3c9  4881c4b8000000           add      rsp, 0xb8
000000014148a3d0  5b                       pop      rbx
000000014148a3d1  5f                       pop      rdi
000000014148a3d2  5e                       pop      rsi
000000014148a3d3  415c                     pop      r12
000000014148a3d5  415d                     pop      r13
000000014148a3d7  415e                     pop      r14
000000014148a3d9  415f                     pop      r15
000000014148a3db  5d                       pop      rbp
000000014148a3dc  c3                       ret      
000000014148a3dd  0f1f00                   nop      dword ptr [rax]
000000014148a3e0  4889542410               mov      qword ptr [rsp + 0x10], rdx
000000014148a3e5  55                       push     rbp
000000014148a3e6  4157                     push     r15
000000014148a3e8  4156                     push     r14
000000014148a3ea  4155                     push     r13
000000014148a3ec  4154                     push     r12
000000014148a3ee  56                       push     rsi
000000014148a3ef  57                       push     rdi
000000014148a3f0  53                       push     rbx
000000014148a3f1  4881ecb8000000           sub      rsp, 0xb8
000000014148a3f8  488daa80000000           lea      rbp, [rdx + 0x80]
000000014148a3ff  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
000000014148a405  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
000000014148a40b  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
000000014148a411  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
000000014148a417  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
000000014148a41d  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
000000014148a426  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
000000014148a42e  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
000000014148a436  488b4570                 mov      rax, qword ptr [rbp + 0x70]
000000014148a43a  4885c0                   test     rax, rax
000000014148a43d  7417                     je       0x14148a456
000000014148a43f  488b4d78                 mov      rcx, qword ptr [rbp + 0x78]
000000014148a443  48c1e003                 shl      rax, 3
000000014148a447  488d1480                 lea      rdx, [rax + rax*4]
000000014148a44b  41b808000000             mov      r8d, 8
000000014148a451  e86a1622ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148a456  c685d700000000           mov      byte ptr [rbp + 0xd7], 0
000000014148a45d  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
000000014148a465  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
000000014148a46d  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
000000014148a476  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
000000014148a47c  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
000000014148a482  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
000000014148a488  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
000000014148a48e  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
000000014148a494  4881c4b8000000           add      rsp, 0xb8
000000014148a49b  5b                       pop      rbx
000000014148a49c  5f                       pop      rdi
000000014148a49d  5e                       pop      rsi
000000014148a49e  415c                     pop      r12
000000014148a4a0  415d                     pop      r13
000000014148a4a2  415e                     pop      r14
000000014148a4a4  415f                     pop      r15
000000014148a4a6  5d                       pop      rbp
000000014148a4a7  c3                       ret      
000000014148a4a8  0f1f840000000000         nop      dword ptr [rax + rax]
000000014148a4b0  4889542410               mov      qword ptr [rsp + 0x10], rdx
000000014148a4b5  55                       push     rbp
000000014148a4b6  4157                     push     r15
000000014148a4b8  4156                     push     r14
000000014148a4ba  4155                     push     r13
000000014148a4bc  4154                     push     r12
000000014148a4be  56                       push     rsi
000000014148a4bf  57                       push     rdi
000000014148a4c0  53                       push     rbx
000000014148a4c1  4881ecb8000000           sub      rsp, 0xb8
000000014148a4c8  488daa80000000           lea      rbp, [rdx + 0x80]
000000014148a4cf  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
000000014148a4d5  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
000000014148a4db  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
000000014148a4e1  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
000000014148a4e7  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
000000014148a4ed  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
000000014148a4f6  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
000000014148a4fe  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
000000014148a506  0fb69dd5000000           movzx    ebx, byte ptr [rbp + 0xd5]
000000014148a50d  4883bdb800000000         cmp      qword ptr [rbp + 0xb8], 0
000000014148a515  7416                     je       0x14148a52d
000000014148a517  488b4d38                 mov      rcx, qword ptr [rbp + 0x38]
000000014148a51b  41b801000000             mov      r8d, 1
000000014148a521  488b95b8000000           mov      rdx, qword ptr [rbp + 0xb8]
000000014148a528  e8931522ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148a52d  80e301                   and      bl, 1
000000014148a530  889dd6000000             mov      byte ptr [rbp + 0xd6], bl
000000014148a536  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
000000014148a53e  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
000000014148a546  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
000000014148a54f  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
000000014148a555  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
000000014148a55b  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
000000014148a561  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
000000014148a567  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
000000014148a56d  4881c4b8000000           add      rsp, 0xb8
000000014148a574  5b                       pop      rbx
000000014148a575  5f                       pop      rdi
000000014148a576  5e                       pop      rsi
000000014148a577  415c                     pop      r12
000000014148a579  415d                     pop      r13
000000014148a57b  415e                     pop      r14
000000014148a57d  415f                     pop      r15
000000014148a57f  5d                       pop      rbp
000000014148a580  c3                       ret      
000000014148a581  6666666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
000000014148a590  4889542410               mov      qword ptr [rsp + 0x10], rdx
000000014148a595  55                       push     rbp
000000014148a596  4157                     push     r15
000000014148a598  4156                     push     r14
000000014148a59a  4155                     push     r13
000000014148a59c  4154                     push     r12
000000014148a59e  56                       push     rsi
000000014148a59f  57                       push     rdi
000000014148a5a0  53                       push     rbx
000000014148a5a1  4881ecb8000000           sub      rsp, 0xb8
000000014148a5a8  488daa80000000           lea      rbp, [rdx + 0x80]
000000014148a5af  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
000000014148a5b5  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
000000014148a5bb  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
000000014148a5c1  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
000000014148a5c7  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
000000014148a5cd  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
000000014148a5d6  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
000000014148a5de  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
000000014148a5e6  48837d6800               cmp      qword ptr [rbp + 0x68], 0
000000014148a5eb  7422                     je       0x14148a60f
000000014148a5ed  488b4568                 mov      rax, qword ptr [rbp + 0x68]
000000014148a5f1  488d04c500000000         lea      rax, [rax*8]
000000014148a5f9  488d1480                 lea      rdx, [rax + rax*4]
000000014148a5fd  41b808000000             mov      r8d, 8
000000014148a603  488b8dc8000000           mov      rcx, qword ptr [rbp + 0xc8]
000000014148a60a  e8b11422ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148a60f  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
000000014148a617  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
000000014148a61f  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
000000014148a628  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
000000014148a62e  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
000000014148a634  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
000000014148a63a  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
000000014148a640  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
000000014148a646  4881c4b8000000           add      rsp, 0xb8
000000014148a64d  5b                       pop      rbx
000000014148a64e  5f                       pop      rdi
000000014148a64f  5e                       pop      rsi
000000014148a650  415c                     pop      r12
000000014148a652  415d                     pop      r13
000000014148a654  415e                     pop      r14
000000014148a656  415f                     pop      r15
000000014148a658  5d                       pop      rbp
000000014148a659  c3                       ret      
000000014148a65a  660f1f440000             nop      word ptr [rax + rax]
000000014148a660  4889542410               mov      qword ptr [rsp + 0x10], rdx
000000014148a665  55                       push     rbp
000000014148a666  4157                     push     r15
000000014148a668  4156                     push     r14
000000014148a66a  4155                     push     r13
000000014148a66c  4154                     push     r12
000000014148a66e  56                       push     rsi
000000014148a66f  57                       push     rdi
000000014148a670  53                       push     rbx
000000014148a671  4881ecb8000000           sub      rsp, 0xb8
000000014148a678  488daa80000000           lea      rbp, [rdx + 0x80]
000000014148a67f  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
000000014148a685  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
000000014148a68b  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
000000014148a691  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
000000014148a697  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
000000014148a69d  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
000000014148a6a6  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
000000014148a6ae  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
000000014148a6b6  488b8590000000           mov      rax, qword ptr [rbp + 0x90]
000000014148a6bd  4885c0                   test     rax, rax
000000014148a6c0  741a                     je       0x14148a6dc
000000014148a6c2  488b8d98000000           mov      rcx, qword ptr [rbp + 0x98]
000000014148a6c9  48c1e003                 shl      rax, 3
000000014148a6cd  488d1480                 lea      rdx, [rax + rax*4]
000000014148a6d1  41b808000000             mov      r8d, 8
000000014148a6d7  e8e41322ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148a6dc  488b85b0000000           mov      rax, qword ptr [rbp + 0xb0]
000000014148a6e3  48894538                 mov      qword ptr [rbp + 0x38], rax
000000014148a6e7  0fb685c7000000           movzx    eax, byte ptr [rbp + 0xc7]
000000014148a6ee  8885d5000000             mov      byte ptr [rbp + 0xd5], al
000000014148a6f4  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
000000014148a6fc  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
000000014148a704  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
000000014148a70d  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
000000014148a713  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
000000014148a719  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
000000014148a71f  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
000000014148a725  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
000000014148a72b  4881c4b8000000           add      rsp, 0xb8
000000014148a732  5b                       pop      rbx
000000014148a733  5f                       pop      rdi
000000014148a734  5e                       pop      rsi
000000014148a735  415c                     pop      r12
000000014148a737  415d                     pop      r13
000000014148a739  415e                     pop      r14
000000014148a73b  415f                     pop      r15
000000014148a73d  5d                       pop      rbp
000000014148a73e  c3                       ret      
000000014148a73f  90                       nop      
000000014148a740  4889542410               mov      qword ptr [rsp + 0x10], rdx
000000014148a745  55                       push     rbp
000000014148a746  4157                     push     r15
000000014148a748  4156                     push     r14
000000014148a74a  4155                     push     r13
000000014148a74c  4154                     push     r12
000000014148a74e  56                       push     rsi
000000014148a74f  57                       push     rdi
000000014148a750  53                       push     rbx
000000014148a751  4881ecb8000000           sub      rsp, 0xb8
000000014148a758  488daa80000000           lea      rbp, [rdx + 0x80]
000000014148a75f  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
000000014148a765  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
000000014148a76b  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
000000014148a771  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
000000014148a777  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
000000014148a77d  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
000000014148a786  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
000000014148a78e  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
000000014148a796  48837d6800               cmp      qword ptr [rbp + 0x68], 0
000000014148a79b  0f95c0                   setne    al
000000014148a79e  8485d6000000             test     byte ptr [rbp + 0xd6], al
000000014148a7a4  741e                     je       0x14148a7c4
000000014148a7a6  488b4568                 mov      rax, qword ptr [rbp + 0x68]
000000014148a7aa  48c1e003                 shl      rax, 3
000000014148a7ae  488d1480                 lea      rdx, [rax + rax*4]
000000014148a7b2  41b808000000             mov      r8d, 8
000000014148a7b8  488b8dc8000000           mov      rcx, qword ptr [rbp + 0xc8]
000000014148a7bf  e8fc1222ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148a7c4  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
000000014148a7cc  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
000000014148a7d4  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
000000014148a7dd  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
000000014148a7e3  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
000000014148a7e9  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
000000014148a7ef  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
000000014148a7f5  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
000000014148a7fb  4881c4b8000000           add      rsp, 0xb8
000000014148a802  5b                       pop      rbx
000000014148a803  5f                       pop      rdi
000000014148a804  5e                       pop      rsi
000000014148a805  415c                     pop      r12
000000014148a807  415d                     pop      r13
000000014148a809  415e                     pop      r14
000000014148a80b  415f                     pop      r15
000000014148a80d  5d                       pop      rbp
000000014148a80e  c3                       ret      
000000014148a80f  90                       nop      
000000014148a810  4889542410               mov      qword ptr [rsp + 0x10], rdx
000000014148a815  55                       push     rbp
000000014148a816  4157                     push     r15
000000014148a818  4156                     push     r14
000000014148a81a  4155                     push     r13
000000014148a81c  4154                     push     r12
000000014148a81e  56                       push     rsi
000000014148a81f  57                       push     rdi
000000014148a820  53                       push     rbx
000000014148a821  4881ecb8000000           sub      rsp, 0xb8
000000014148a828  488daa80000000           lea      rbp, [rdx + 0x80]
000000014148a82f  440f296c2430             movaps   xmmword ptr [rsp + 0x30], xmm13
000000014148a835  440f29642440             movaps   xmmword ptr [rsp + 0x40], xmm12
000000014148a83b  440f295c2450             movaps   xmmword ptr [rsp + 0x50], xmm11
000000014148a841  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
000000014148a847  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
000000014148a84d  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
000000014148a856  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
000000014148a85e  0f29b424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm6
000000014148a866  80bdd700000000           cmp      byte ptr [rbp + 0xd7], 0
000000014148a86d  746b                     je       0x14148a8da
000000014148a86f  488b45e0                 mov      rax, qword ptr [rbp - 0x20]
000000014148a873  4885c0                   test     rax, rax
000000014148a876  7417                     je       0x14148a88f
000000014148a878  488b4de8                 mov      rcx, qword ptr [rbp - 0x18]
000000014148a87c  48c1e003                 shl      rax, 3
000000014148a880  488d1480                 lea      rdx, [rax + rax*4]
000000014148a884  41b808000000             mov      r8d, 8
000000014148a88a  e8311222ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148a88f  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
000000014148a897  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
000000014148a89f  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
000000014148a8a8  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
000000014148a8ae  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
000000014148a8b4  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
000000014148a8ba  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
000000014148a8c0  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
000000014148a8c6  4881c4b8000000           add      rsp, 0xb8
000000014148a8cd  5b                       pop      rbx
000000014148a8ce  5f                       pop      rdi
000000014148a8cf  5e                       pop      rsi
000000014148a8d0  415c                     pop      r12
000000014148a8d2  415d                     pop      r13
000000014148a8d4  415e                     pop      r14
000000014148a8d6  415f                     pop      r15
000000014148a8d8  5d                       pop      rbp
000000014148a8d9  c3                       ret      
000000014148a8da  0f28b424a0000000         movaps   xmm6, xmmword ptr [rsp + 0xa0]
000000014148a8e2  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
000000014148a8ea  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
000000014148a8f3  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
000000014148a8f9  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
000000014148a8ff  440f285c2450             movaps   xmm11, xmmword ptr [rsp + 0x50]
000000014148a905  440f28642440             movaps   xmm12, xmmword ptr [rsp + 0x40]
000000014148a90b  440f286c2430             movaps   xmm13, xmmword ptr [rsp + 0x30]
000000014148a911  4881c4b8000000           add      rsp, 0xb8
000000014148a918  5b                       pop      rbx
000000014148a919  5f                       pop      rdi
000000014148a91a  5e                       pop      rsi
000000014148a91b  415c                     pop      r12
000000014148a91d  415d                     pop      r13
000000014148a91f  415e                     pop      r14
000000014148a921  415f                     pop      r15
000000014148a923  5d                       pop      rbp
000000014148a924  c3                       ret      