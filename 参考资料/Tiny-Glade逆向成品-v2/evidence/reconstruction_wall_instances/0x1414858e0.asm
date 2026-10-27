00000001414858e0  55                       push     rbp
00000001414858e1  4157                     push     r15
00000001414858e3  4156                     push     r14
00000001414858e5  56                       push     rsi
00000001414858e6  57                       push     rdi
00000001414858e7  53                       push     rbx
00000001414858e8  4881ecf8000000           sub      rsp, 0xf8
00000001414858ef  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001414858f7  440f296d60               movaps   xmmword ptr [rbp + 0x60], xmm13
00000001414858fc  440f296550               movaps   xmmword ptr [rbp + 0x50], xmm12
0000000141485901  440f295d40               movaps   xmmword ptr [rbp + 0x40], xmm11
0000000141485906  440f295530               movaps   xmmword ptr [rbp + 0x30], xmm10
000000014148590b  440f294d20               movaps   xmmword ptr [rbp + 0x20], xmm9
0000000141485910  440f294510               movaps   xmmword ptr [rbp + 0x10], xmm8
0000000141485915  0f297d00                 movaps   xmmword ptr [rbp], xmm7
0000000141485919  0f2975f0                 movaps   xmmword ptr [rbp - 0x10], xmm6
000000014148591d  48c745e8feffffff         mov      qword ptr [rbp - 0x18], 0xfffffffffffffffe
0000000141485925  4889ce                   mov      rsi, rcx
0000000141485928  f30f115ddc               movss    dword ptr [rbp - 0x24], xmm3
000000014148592d  4d85c0                   test     r8, r8
0000000141485930  7434                     je       0x141485966
0000000141485932  4889d7                   mov      rdi, rdx
0000000141485935  4c89c1                   mov      rcx, r8
0000000141485938  e8835c7aff               call     0x140c2b5c0 ; country_core::resources::walls::wall_holes::FinalizedWallHoles::holes_no_duplicates | _ZN12country_core9resources5walls10wall_holes18FinalizedWallHoles5holes17hd0fa4c53df94144cE
000000014148593d  488945a0                 mov      qword ptr [rbp - 0x60], rax
0000000141485941  488955a8                 mov      qword ptr [rbp - 0x58], rdx
0000000141485945  488d45dc                 lea      rax, [rbp - 0x24]
0000000141485949  488945b0                 mov      qword ptr [rbp - 0x50], rax
000000014148594d  488d4db8                 lea      rcx, [rbp - 0x48]
0000000141485951  488d55a0                 lea      rdx, [rbp - 0x60]
0000000141485955  e8262ff6ff               call     0x1413e8880 ; _ZN98_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$alloc..vec..spec_from_iter..SpecFromIter$LT$T$C$I$GT$$GT$9from_iter17h0b496f4c4b9dc2e3E | alloc::vec::spec_from_iter::impl$0::from_iter<utils::geometry::aabb::Aabb2,core::iter::adapters::filter_map::FilterMap<core::iter::adapters::map::Map<core::slice::iter::Iter<tuple$<utils::geometry::aabb::Aabb2,country_core::resources::walls::wall_holes::HoleType,country_core::resources::walls::wall_holes::HoleOrigin> >,country_core::resources::walls::wall_holes::impl$1::holes::closure_env$0>,system_wall_constructor::construct_wooden_walls::construct_wall_boards::remapped_top_rim_holes::closure$0::closure_env$0> >
000000014148595a  488b4db8                 mov      rcx, qword ptr [rbp - 0x48]
000000014148595e  4889c8                   mov      rax, rcx
0000000141485961  48f7d8                   neg      rax
0000000141485964  710f                     jno      0x141485975
0000000141485966  41bf04000000             mov      r15d, 4
000000014148596c  31db                     xor      ebx, ebx
000000014148596e  31c9                     xor      ecx, ecx
0000000141485970  e9fb000000               jmp      0x141485a70
0000000141485975  4c8b7dc0                 mov      r15, qword ptr [rbp - 0x40]
0000000141485979  488b5dc8                 mov      rbx, qword ptr [rbp - 0x38]
000000014148597d  4885db                   test     rbx, rbx
0000000141485980  0f84e8000000             je       0x141485a6e
0000000141485986  48894de0                 mov      qword ptr [rbp - 0x20], rcx
000000014148598a  4989de                   mov      r14, rbx
000000014148598d  49c1e604                 shl      r14, 4
0000000141485991  4d01fe                   add      r14, r15
0000000141485994  f3440f104f38             movss    xmm9, dword ptr [rdi + 0x38]
000000014148599a  f3440f10573c             movss    xmm10, dword ptr [rdi + 0x3c]
00000001414859a0  f3440f580d7757b801       addss    xmm9, dword ptr [rip + 0x1b85777]
00000001414859a9  f3440f101db243b801       movss    xmm11, dword ptr [rip + 0x1b843b2]
00000001414859b2  4c897dd0                 mov      qword ptr [rbp - 0x30], r15
00000001414859b6  eb2c                     jmp      0x1414859e4
00000001414859b8  0f1f840000000000         nop      dword ptr [rax + rax]
00000001414859c0  f3410f1117               movss    dword ptr [r15], xmm2
00000001414859c5  f3450f116704             movss    dword ptr [r15 + 4], xmm12
00000001414859cb  f3410f115f08             movss    dword ptr [r15 + 8], xmm3
00000001414859d1  f3450f116f0c             movss    dword ptr [r15 + 0xc], xmm13
00000001414859d7  4983c710                 add      r15, 0x10
00000001414859db  4d39f7                   cmp      r15, r14
00000001414859de  0f8480000000             je       0x141485a64
00000001414859e4  f3450f1007               movss    xmm8, dword ptr [r15]
00000001414859e9  f3450f106704             movss    xmm12, dword ptr [r15 + 4]
00000001414859ef  f3410f107708             movss    xmm6, dword ptr [r15 + 8]
00000001414859f5  f3450f106f0c             movss    xmm13, dword ptr [r15 + 0xc]
00000001414859fb  4889f9                   mov      rcx, rdi
00000001414859fe  410f28c8                 movaps   xmm1, xmm8
0000000141485a02  e889e4ffff               call     0x141483e90 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::BoardWallSpace::remap_x | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards14BoardWallSpace7remap_x17hac10aa8678e4b041E
0000000141485a07  90                       nop      
0000000141485a08  0f28f8                   movaps   xmm7, xmm0
0000000141485a0b  4889f9                   mov      rcx, rdi
0000000141485a0e  0f28ce                   movaps   xmm1, xmm6
0000000141485a11  e87ae4ffff               call     0x141483e90 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::BoardWallSpace::remap_x | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards14BoardWallSpace7remap_x17hac10aa8678e4b041E
0000000141485a16  90                       nop      
0000000141485a17  0f57d2                   xorps    xmm2, xmm2
0000000141485a1a  450f2ed8                 ucomiss  xmm11, xmm8
0000000141485a1e  0f28cf                   movaps   xmm1, xmm7
0000000141485a21  f30fc2cf03               cmpunordss xmm1, xmm7
0000000141485a26  7316                     jae      0x141485a3e
0000000141485a28  0f28d9                   movaps   xmm3, xmm1
0000000141485a2b  0f54d8                   andps    xmm3, xmm0
0000000141485a2e  0f28e0                   movaps   xmm4, xmm0
0000000141485a31  f30f5de7                 minss    xmm4, xmm7
0000000141485a35  0f28d1                   movaps   xmm2, xmm1
0000000141485a38  0f55d4                   andnps   xmm2, xmm4
0000000141485a3b  0f56d3                   orps     xmm2, xmm3
0000000141485a3e  410f2ef1                 ucomiss  xmm6, xmm9
0000000141485a42  410f28da                 movaps   xmm3, xmm10
0000000141485a46  0f8374ffffff             jae      0x1414859c0
0000000141485a4c  0f28d9                   movaps   xmm3, xmm1
0000000141485a4f  0f54d8                   andps    xmm3, xmm0
0000000141485a52  f30f5fc7                 maxss    xmm0, xmm7
0000000141485a56  0f55c8                   andnps   xmm1, xmm0
0000000141485a59  0f56cb                   orps     xmm1, xmm3
0000000141485a5c  0f28d9                   movaps   xmm3, xmm1
0000000141485a5f  e95cffffff               jmp      0x1414859c0
0000000141485a64  488b4de0                 mov      rcx, qword ptr [rbp - 0x20]
0000000141485a68  4c8b7dd0                 mov      r15, qword ptr [rbp - 0x30]
0000000141485a6c  eb02                     jmp      0x141485a70
0000000141485a6e  31db                     xor      ebx, ebx
0000000141485a70  48890e                   mov      qword ptr [rsi], rcx
0000000141485a73  4c897e08                 mov      qword ptr [rsi + 8], r15
0000000141485a77  48895e10                 mov      qword ptr [rsi + 0x10], rbx
0000000141485a7b  4889f0                   mov      rax, rsi
0000000141485a7e  0f2875f0                 movaps   xmm6, xmmword ptr [rbp - 0x10]
0000000141485a82  0f287d00                 movaps   xmm7, xmmword ptr [rbp]
0000000141485a86  440f284510               movaps   xmm8, xmmword ptr [rbp + 0x10]
0000000141485a8b  440f284d20               movaps   xmm9, xmmword ptr [rbp + 0x20]
0000000141485a90  440f285530               movaps   xmm10, xmmword ptr [rbp + 0x30]
0000000141485a95  440f285d40               movaps   xmm11, xmmword ptr [rbp + 0x40]
0000000141485a9a  440f286550               movaps   xmm12, xmmword ptr [rbp + 0x50]
0000000141485a9f  440f286d60               movaps   xmm13, xmmword ptr [rbp + 0x60]
0000000141485aa4  4881c4f8000000           add      rsp, 0xf8
0000000141485aab  5b                       pop      rbx
0000000141485aac  5f                       pop      rdi
0000000141485aad  5e                       pop      rsi
0000000141485aae  415e                     pop      r14
0000000141485ab0  415f                     pop      r15
0000000141485ab2  5d                       pop      rbp
0000000141485ab3  c3                       ret      
0000000141485ab4  6666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141485ac0  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141485ac5  55                       push     rbp
0000000141485ac6  4157                     push     r15
0000000141485ac8  4156                     push     r14
0000000141485aca  56                       push     rsi
0000000141485acb  57                       push     rdi
0000000141485acc  53                       push     rbx
0000000141485acd  4881eca8000000           sub      rsp, 0xa8
0000000141485ad4  488daa80000000           lea      rbp, [rdx + 0x80]
0000000141485adb  440f296c2420             movaps   xmmword ptr [rsp + 0x20], xmm13
0000000141485ae1  440f29642430             movaps   xmmword ptr [rsp + 0x30], xmm12
0000000141485ae7  440f295c2440             movaps   xmmword ptr [rsp + 0x40], xmm11
0000000141485aed  440f29542450             movaps   xmmword ptr [rsp + 0x50], xmm10
0000000141485af3  440f294c2460             movaps   xmmword ptr [rsp + 0x60], xmm9
0000000141485af9  440f29442470             movaps   xmmword ptr [rsp + 0x70], xmm8
0000000141485aff  0f29bc2480000000         movaps   xmmword ptr [rsp + 0x80], xmm7
0000000141485b07  0f29b42490000000         movaps   xmmword ptr [rsp + 0x90], xmm6
0000000141485b0f  48837de000               cmp      qword ptr [rbp - 0x20], 0
0000000141485b14  7417                     je       0x141485b2d
0000000141485b16  488b55e0                 mov      rdx, qword ptr [rbp - 0x20]
0000000141485b1a  48c1e204                 shl      rdx, 4
0000000141485b1e  41b804000000             mov      r8d, 4
0000000141485b24  488b4dd0                 mov      rcx, qword ptr [rbp - 0x30]
0000000141485b28  e8935f22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141485b2d  0f28b42490000000         movaps   xmm6, xmmword ptr [rsp + 0x90]
0000000141485b35  0f28bc2480000000         movaps   xmm7, xmmword ptr [rsp + 0x80]
0000000141485b3d  440f28442470             movaps   xmm8, xmmword ptr [rsp + 0x70]
0000000141485b43  440f284c2460             movaps   xmm9, xmmword ptr [rsp + 0x60]
0000000141485b49  440f28542450             movaps   xmm10, xmmword ptr [rsp + 0x50]
0000000141485b4f  440f285c2440             movaps   xmm11, xmmword ptr [rsp + 0x40]
0000000141485b55  440f28642430             movaps   xmm12, xmmword ptr [rsp + 0x30]
0000000141485b5b  440f286c2420             movaps   xmm13, xmmword ptr [rsp + 0x20]
0000000141485b61  4881c4a8000000           add      rsp, 0xa8
0000000141485b68  5b                       pop      rbx
0000000141485b69  5f                       pop      rdi
0000000141485b6a  5e                       pop      rsi
0000000141485b6b  415e                     pop      r14
0000000141485b6d  415f                     pop      r15
0000000141485b6f  5d                       pop      rbp
0000000141485b70  c3                       ret      