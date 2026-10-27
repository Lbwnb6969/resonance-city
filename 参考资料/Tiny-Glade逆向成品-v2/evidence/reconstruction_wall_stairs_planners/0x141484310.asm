0000000141484310  55                       push     rbp
0000000141484311  4157                     push     r15
0000000141484313  4156                     push     r14
0000000141484315  4154                     push     r12
0000000141484317  56                       push     rsi
0000000141484318  57                       push     rdi
0000000141484319  53                       push     rbx
000000014148431a  4881ecf0000000           sub      rsp, 0xf0
0000000141484321  488dac2480000000         lea      rbp, [rsp + 0x80]
0000000141484329  440f296d60               movaps   xmmword ptr [rbp + 0x60], xmm13
000000014148432e  440f296550               movaps   xmmword ptr [rbp + 0x50], xmm12
0000000141484333  440f295d40               movaps   xmmword ptr [rbp + 0x40], xmm11
0000000141484338  440f295530               movaps   xmmword ptr [rbp + 0x30], xmm10
000000014148433d  440f294d20               movaps   xmmword ptr [rbp + 0x20], xmm9
0000000141484342  440f294510               movaps   xmmword ptr [rbp + 0x10], xmm8
0000000141484347  0f297d00                 movaps   xmmword ptr [rbp], xmm7
000000014148434b  0f2975f0                 movaps   xmmword ptr [rbp - 0x10], xmm6
000000014148434f  48c745e8feffffff         mov      qword ptr [rbp - 0x18], 0xfffffffffffffffe
0000000141484357  4c89c7                   mov      rdi, r8
000000014148435a  4889ce                   mov      rsi, rcx
000000014148435d  488b9dd8000000           mov      rbx, qword ptr [rbp + 0xd8]
0000000141484364  4c8bb5d0000000           mov      r14, qword ptr [rbp + 0xd0]
000000014148436b  4d85c9                   test     r9, r9
000000014148436e  7425                     je       0x141484395
0000000141484370  4c89c9                   mov      rcx, r9
0000000141484373  4989d7                   mov      r15, rdx
0000000141484376  e845727aff               call     0x140c2b5c0 ; country_core::resources::walls::wall_holes::FinalizedWallHoles::holes_no_duplicates | _ZN12country_core9resources5walls10wall_holes18FinalizedWallHoles5holes17hd0fa4c53df94144cE
000000014148437b  4989d0                   mov      r8, rdx
000000014148437e  488d4da8                 lea      rcx, [rbp - 0x58]
0000000141484382  4889c2                   mov      rdx, rax
0000000141484385  e85679f6ff               call     0x1413ebce0 ; _ZN98_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$alloc..vec..spec_from_iter..SpecFromIter$LT$T$C$I$GT$$GT$9from_iter17h5fb40093a652553cE | alloc::vec::spec_from_iter::impl$0::from_iter<utils::geometry::aabb::Aabb2,core::iter::adapters::filter_map::FilterMap<core::iter::adapters::map::Map<core::slice::iter::Iter<tuple$<utils::geometry::aabb::Aabb2,country_core::resources::walls::wall_holes::HoleType,country_core::resources::walls::wall_holes::HoleOrigin> >,country_core::resources::walls::wall_holes::impl$1::holes::closure_env$0>,system_wall_constructor::construct_wooden_walls::construct_wall_boards::remapped_wall_cutouts::closure$0::closure_env$0> >
000000014148438a  4c89fa                   mov      rdx, r15
000000014148438d  31c0                     xor      eax, eax
000000014148438f  483b45a8                 cmp      rax, qword ptr [rbp - 0x58]
0000000141484393  711a                     jno      0x1414843af
0000000141484395  48c745d000000000         mov      qword ptr [rbp - 0x30], 0
000000014148439d  48c745d804000000         mov      qword ptr [rbp - 0x28], 4
00000001414843a5  48c745e000000000         mov      qword ptr [rbp - 0x20], 0
00000001414843ad  eb10                     jmp      0x1414843bf
00000001414843af  488b45b8                 mov      rax, qword ptr [rbp - 0x48]
00000001414843b3  488945e0                 mov      qword ptr [rbp - 0x20], rax
00000001414843b7  0f1045a8                 movups   xmm0, xmmword ptr [rbp - 0x58]
00000001414843bb  0f2945d0                 movaps   xmmword ptr [rbp - 0x30], xmm0
00000001414843bf  488d4da8                 lea      rcx, [rbp - 0x58]
00000001414843c3  4d89f0                   mov      r8, r14
00000001414843c6  4989d9                   mov      r9, rbx
00000001414843c9  e822100000               call     0x1414853f0 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::arch_openings_to_aabb2 | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards22arch_openings_to_aabb217h13452e9d133245ffE
00000001414843ce  90                       nop      
00000001414843cf  4c8b7da8                 mov      r15, qword ptr [rbp - 0x58]
00000001414843d3  4c8b65b0                 mov      r12, qword ptr [rbp - 0x50]
00000001414843d7  4c8b75b8                 mov      r14, qword ptr [rbp - 0x48]
00000001414843db  488b45d0                 mov      rax, qword ptr [rbp - 0x30]
00000001414843df  488b5de0                 mov      rbx, qword ptr [rbp - 0x20]
00000001414843e3  4829d8                   sub      rax, rbx
00000001414843e6  4939c6                   cmp      r14, rax
00000001414843e9  0f875c010000             ja       0x14148454b
00000001414843ef  4d85f6                   test     r14, r14
00000001414843f2  741a                     je       0x14148440e
00000001414843f4  4d89f0                   mov      r8, r14
00000001414843f7  49c1e004                 shl      r8, 4
00000001414843fb  4889d9                   mov      rcx, rbx
00000001414843fe  48c1e104                 shl      rcx, 4
0000000141484402  48034dd8                 add      rcx, qword ptr [rbp - 0x28]
0000000141484406  4c89e2                   mov      rdx, r12
0000000141484409  e852e39a01               call     0x142e32760 ; memcpy
000000014148440e  4c01f3                   add      rbx, r14
0000000141484411  48895de0                 mov      qword ptr [rbp - 0x20], rbx
0000000141484415  4d85ff                   test     r15, r15
0000000141484418  7415                     je       0x14148442f
000000014148441a  49c1e704                 shl      r15, 4
000000014148441e  41b804000000             mov      r8d, 4
0000000141484424  4c89e1                   mov      rcx, r12
0000000141484427  4c89fa                   mov      rdx, r15
000000014148442a  e8917622ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014148442f  4c8b75d8                 mov      r14, qword ptr [rbp - 0x28]
0000000141484433  48c1e304                 shl      rbx, 4
0000000141484437  4c01f3                   add      rbx, r14
000000014148443a  f3440f104f38             movss    xmm9, dword ptr [rdi + 0x38]
0000000141484440  f3440f10573c             movss    xmm10, dword ptr [rdi + 0x3c]
0000000141484446  f3440f580dd16cb801       addss    xmm9, dword ptr [rip + 0x1b86cd1]
000000014148444f  f3440f101d0c59b801       movss    xmm11, dword ptr [rip + 0x1b8590c]
0000000141484458  eb21                     jmp      0x14148447b
000000014148445a  660f1f440000             nop      word ptr [rax + rax]
0000000141484460  f3410f110e               movss    dword ptr [r14], xmm1
0000000141484465  f3450f116604             movss    dword ptr [r14 + 4], xmm12
000000014148446b  f3410f115e08             movss    dword ptr [r14 + 8], xmm3
0000000141484471  f3450f116e0c             movss    dword ptr [r14 + 0xc], xmm13
0000000141484477  4983c610                 add      r14, 0x10
000000014148447b  4939de                   cmp      r14, rbx
000000014148447e  0f8480000000             je       0x141484504
0000000141484484  f3450f1006               movss    xmm8, dword ptr [r14]
0000000141484489  f3450f106604             movss    xmm12, dword ptr [r14 + 4]
000000014148448f  f3410f107608             movss    xmm6, dword ptr [r14 + 8]
0000000141484495  f3450f106e0c             movss    xmm13, dword ptr [r14 + 0xc]
000000014148449b  4889f9                   mov      rcx, rdi
000000014148449e  410f28c8                 movaps   xmm1, xmm8
00000001414844a2  e8e9f9ffff               call     0x141483e90 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::BoardWallSpace::remap_x | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards14BoardWallSpace7remap_x17hac10aa8678e4b041E
00000001414844a7  90                       nop      
00000001414844a8  0f28f8                   movaps   xmm7, xmm0
00000001414844ab  4889f9                   mov      rcx, rdi
00000001414844ae  0f28ce                   movaps   xmm1, xmm6
00000001414844b1  e8daf9ffff               call     0x141483e90 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::BoardWallSpace::remap_x | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards14BoardWallSpace7remap_x17hac10aa8678e4b041E
00000001414844b6  90                       nop      
00000001414844b7  0f57c9                   xorps    xmm1, xmm1
00000001414844ba  450f2ed8                 ucomiss  xmm11, xmm8
00000001414844be  0f28d7                   movaps   xmm2, xmm7
00000001414844c1  f30fc2d703               cmpunordss xmm2, xmm7
00000001414844c6  7316                     jae      0x1414844de
00000001414844c8  0f28da                   movaps   xmm3, xmm2
00000001414844cb  0f54d8                   andps    xmm3, xmm0
00000001414844ce  0f28e0                   movaps   xmm4, xmm0
00000001414844d1  f30f5de7                 minss    xmm4, xmm7
00000001414844d5  0f28ca                   movaps   xmm1, xmm2
00000001414844d8  0f55cc                   andnps   xmm1, xmm4
00000001414844db  0f56cb                   orps     xmm1, xmm3
00000001414844de  410f2ef1                 ucomiss  xmm6, xmm9
00000001414844e2  410f28da                 movaps   xmm3, xmm10
00000001414844e6  0f8374ffffff             jae      0x141484460
00000001414844ec  0f28da                   movaps   xmm3, xmm2
00000001414844ef  0f54d8                   andps    xmm3, xmm0
00000001414844f2  f30f5fc7                 maxss    xmm0, xmm7
00000001414844f6  0f55d0                   andnps   xmm2, xmm0
00000001414844f9  0f56d3                   orps     xmm2, xmm3
00000001414844fc  0f28da                   movaps   xmm3, xmm2
00000001414844ff  e95cffffff               jmp      0x141484460
0000000141484504  488b45e0                 mov      rax, qword ptr [rbp - 0x20]
0000000141484508  48894610                 mov      qword ptr [rsi + 0x10], rax
000000014148450c  0f2845d0                 movaps   xmm0, xmmword ptr [rbp - 0x30]
0000000141484510  0f1106                   movups   xmmword ptr [rsi], xmm0
0000000141484513  0f2875f0                 movaps   xmm6, xmmword ptr [rbp - 0x10]
0000000141484517  0f287d00                 movaps   xmm7, xmmword ptr [rbp]
000000014148451b  440f284510               movaps   xmm8, xmmword ptr [rbp + 0x10]
0000000141484520  440f284d20               movaps   xmm9, xmmword ptr [rbp + 0x20]
0000000141484525  440f285530               movaps   xmm10, xmmword ptr [rbp + 0x30]
000000014148452a  440f285d40               movaps   xmm11, xmmword ptr [rbp + 0x40]
000000014148452f  440f286550               movaps   xmm12, xmmword ptr [rbp + 0x50]
0000000141484534  440f286d60               movaps   xmm13, xmmword ptr [rbp + 0x60]
0000000141484539  4881c4f0000000           add      rsp, 0xf0
0000000141484540  5b                       pop      rbx
0000000141484541  5f                       pop      rdi
0000000141484542  5e                       pop      rsi
0000000141484543  415c                     pop      r12
0000000141484545  415e                     pop      r14
0000000141484547  415f                     pop      r15
0000000141484549  5d                       pop      rbp
000000014148454a  c3                       ret      
000000014148454b  4c8965c0                 mov      qword ptr [rbp - 0x40], r12
000000014148454f  4c897dc8                 mov      qword ptr [rbp - 0x38], r15
0000000141484553  48c744242010000000       mov      qword ptr [rsp + 0x20], 0x10
000000014148455c  488d4dd0                 lea      rcx, [rbp - 0x30]
0000000141484560  41b904000000             mov      r9d, 4
0000000141484566  4889da                   mov      rdx, rbx
0000000141484569  4d89f0                   mov      r8, r14
000000014148456c  e83fac8f01               call     0x142d7f1b0 ; alloc::raw_vec::impl$4::reserve::do_reserve_and_handle<alloc::alloc::Global> | _ZN5alloc7raw_vec20RawVecInner$LT$A$GT$7reserve21do_reserve_and_handle17h0559268ff9d2f5acE
0000000141484571  90                       nop      
0000000141484572  488b5de0                 mov      rbx, qword ptr [rbp - 0x20]
0000000141484576  4c8b7dc8                 mov      r15, qword ptr [rbp - 0x38]
000000014148457a  4c8b65c0                 mov      r12, qword ptr [rbp - 0x40]
000000014148457e  e971feffff               jmp      0x1414843f4
0000000141484583  666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141484590  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141484595  55                       push     rbp
0000000141484596  4157                     push     r15
0000000141484598  4156                     push     r14
000000014148459a  4154                     push     r12
000000014148459c  56                       push     rsi
000000014148459d  57                       push     rdi
000000014148459e  53                       push     rbx
000000014148459f  4881ecb0000000           sub      rsp, 0xb0
00000001414845a6  488daa80000000           lea      rbp, [rdx + 0x80]
00000001414845ad  440f296c2420             movaps   xmmword ptr [rsp + 0x20], xmm13
00000001414845b3  440f29642430             movaps   xmmword ptr [rsp + 0x30], xmm12
00000001414845b9  440f295c2440             movaps   xmmword ptr [rsp + 0x40], xmm11
00000001414845bf  440f29542450             movaps   xmmword ptr [rsp + 0x50], xmm10
00000001414845c5  440f294c2460             movaps   xmmword ptr [rsp + 0x60], xmm9
00000001414845cb  440f29442470             movaps   xmmword ptr [rsp + 0x70], xmm8
00000001414845d1  0f29bc2480000000         movaps   xmmword ptr [rsp + 0x80], xmm7
00000001414845d9  0f29b42490000000         movaps   xmmword ptr [rsp + 0x90], xmm6
00000001414845e1  488b55d0                 mov      rdx, qword ptr [rbp - 0x30]
00000001414845e5  4885d2                   test     rdx, rdx
00000001414845e8  7413                     je       0x1414845fd
00000001414845ea  488b4dd8                 mov      rcx, qword ptr [rbp - 0x28]
00000001414845ee  48c1e204                 shl      rdx, 4
00000001414845f2  41b804000000             mov      r8d, 4
00000001414845f8  e8c37422ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001414845fd  0f28b42490000000         movaps   xmm6, xmmword ptr [rsp + 0x90]
0000000141484605  0f28bc2480000000         movaps   xmm7, xmmword ptr [rsp + 0x80]
000000014148460d  440f28442470             movaps   xmm8, xmmword ptr [rsp + 0x70]
0000000141484613  440f284c2460             movaps   xmm9, xmmword ptr [rsp + 0x60]
0000000141484619  440f28542450             movaps   xmm10, xmmword ptr [rsp + 0x50]
000000014148461f  440f285c2440             movaps   xmm11, xmmword ptr [rsp + 0x40]
0000000141484625  440f28642430             movaps   xmm12, xmmword ptr [rsp + 0x30]
000000014148462b  440f286c2420             movaps   xmm13, xmmword ptr [rsp + 0x20]
0000000141484631  4881c4b0000000           add      rsp, 0xb0
0000000141484638  5b                       pop      rbx
0000000141484639  5f                       pop      rdi
000000014148463a  5e                       pop      rsi
000000014148463b  415c                     pop      r12
000000014148463d  415e                     pop      r14
000000014148463f  415f                     pop      r15
0000000141484641  5d                       pop      rbp
0000000141484642  c3                       ret      
0000000141484643  666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141484650  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141484655  55                       push     rbp
0000000141484656  4157                     push     r15
0000000141484658  4156                     push     r14
000000014148465a  4154                     push     r12
000000014148465c  56                       push     rsi
000000014148465d  57                       push     rdi
000000014148465e  53                       push     rbx
000000014148465f  4881ecb0000000           sub      rsp, 0xb0
0000000141484666  488daa80000000           lea      rbp, [rdx + 0x80]
000000014148466d  440f296c2420             movaps   xmmword ptr [rsp + 0x20], xmm13
0000000141484673  440f29642430             movaps   xmmword ptr [rsp + 0x30], xmm12
0000000141484679  440f295c2440             movaps   xmmword ptr [rsp + 0x40], xmm11
000000014148467f  440f29542450             movaps   xmmword ptr [rsp + 0x50], xmm10
0000000141484685  440f294c2460             movaps   xmmword ptr [rsp + 0x60], xmm9
000000014148468b  440f29442470             movaps   xmmword ptr [rsp + 0x70], xmm8
0000000141484691  0f29bc2480000000         movaps   xmmword ptr [rsp + 0x80], xmm7
0000000141484699  0f29b42490000000         movaps   xmmword ptr [rsp + 0x90], xmm6
00000001414846a1  48837dc800               cmp      qword ptr [rbp - 0x38], 0
00000001414846a6  7417                     je       0x1414846bf
00000001414846a8  488b55c8                 mov      rdx, qword ptr [rbp - 0x38]
00000001414846ac  48c1e204                 shl      rdx, 4
00000001414846b0  41b804000000             mov      r8d, 4
00000001414846b6  488b4dc0                 mov      rcx, qword ptr [rbp - 0x40]
00000001414846ba  e8017422ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001414846bf  0f28b42490000000         movaps   xmm6, xmmword ptr [rsp + 0x90]
00000001414846c7  0f28bc2480000000         movaps   xmm7, xmmword ptr [rsp + 0x80]
00000001414846cf  440f28442470             movaps   xmm8, xmmword ptr [rsp + 0x70]
00000001414846d5  440f284c2460             movaps   xmm9, xmmword ptr [rsp + 0x60]
00000001414846db  440f28542450             movaps   xmm10, xmmword ptr [rsp + 0x50]
00000001414846e1  440f285c2440             movaps   xmm11, xmmword ptr [rsp + 0x40]
00000001414846e7  440f28642430             movaps   xmm12, xmmword ptr [rsp + 0x30]
00000001414846ed  440f286c2420             movaps   xmm13, xmmword ptr [rsp + 0x20]
00000001414846f3  4881c4b0000000           add      rsp, 0xb0
00000001414846fa  5b                       pop      rbx
00000001414846fb  5f                       pop      rdi
00000001414846fc  5e                       pop      rsi
00000001414846fd  415c                     pop      r12
00000001414846ff  415e                     pop      r14
0000000141484701  415f                     pop      r15
0000000141484703  5d                       pop      rbp
0000000141484704  c3                       ret      